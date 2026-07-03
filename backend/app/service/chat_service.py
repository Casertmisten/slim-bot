"""对话业务逻辑：会话管理 + 上下文组装 + 调 Agent。

上下文注入规则（设计文档 5.3）：会话绑定 student_id 时，
自动拉取该学员近 7 天体重 + 最近围度 + 最近饮食运动摘要，
作为 system prompt 注入。
"""
from datetime import date, timedelta
from collections.abc import AsyncGenerator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from agentscope.message import UserMsg, AssistantMsg
from app.exceptions import NotFoundError
from app.model.chat_history import ChatSession, ChatMessage
from app.model.record import WeightRecord, BodyMetricRecord, DailyLog
from app.model.student import Student
from app.agent.coach_agent import stream_reply
from app.agent.retriever import retriever
from app.schemas.chat import ChatSessionCreate


BASE_SYSTEM_PROMPT = (
    "你是一位专业的减肥教练助手，为教练提供基于学员数据的针对性指导建议。"
    "回答要具体、可操作，结合学员的实际数据。语气专业、鼓励。"
)


async def create_session(
    db: AsyncSession, data: ChatSessionCreate
) -> ChatSession:
    """新建对话会话（可选绑定学员）。"""
    session = ChatSession(
        student_id=data.student_id,
        title=data.title or "新会话",
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def list_sessions(
    db: AsyncSession, student_id: int | None = None
) -> list[ChatSession]:
    """会话列表。"""
    stmt = select(ChatSession).order_by(ChatSession.created_at.desc())
    if student_id is not None:
        stmt = stmt.where(ChatSession.student_id == student_id)
    return list((await db.execute(stmt)).scalars().all())


async def list_messages(db: AsyncSession, session_id: int) -> list[ChatMessage]:
    """历史消息。"""
    stmt = select(ChatMessage).where(
        ChatMessage.session_id == session_id
    ).order_by(ChatMessage.created_at.asc())
    return list((await db.execute(stmt)).scalars().all())


async def delete_session(db: AsyncSession, session_id: int) -> None:
    s = (
        await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    ).scalar_one_or_none()
    if s is None:
        raise NotFoundError("会话不存在")
    await db.delete(s)
    await db.commit()


async def _build_context_prompt(db: AsyncSession, student_id: int) -> str:
    """组装学员上下文 system prompt。"""
    student = (
        await db.execute(select(Student).where(Student.id == student_id))
    ).scalar_one_or_none()
    if student is None:
        return BASE_SYSTEM_PROMPT

    since = date.today() - timedelta(days=7)
    weights = list((
        await db.execute(
            select(WeightRecord)
            .where(WeightRecord.student_id == student_id, WeightRecord.record_date >= since)
            .order_by(WeightRecord.record_date.asc())
        )
    ).scalars().all())
    metrics = list((
        await db.execute(
            select(BodyMetricRecord)
            .where(BodyMetricRecord.student_id == student_id)
            .order_by(BodyMetricRecord.record_date.desc())
            .limit(5)
        )
    ).scalars().all())
    logs = list((
        await db.execute(
            select(DailyLog)
            .where(DailyLog.student_id == student_id)
            .order_by(DailyLog.log_date.desc())
            .limit(10)
        )
    ).scalars().all())

    parts = [BASE_SYSTEM_PROMPT, "", f"【当前学员】{student.name}，{student.gender}，{student.age}岁，身高 {student.height_cm}cm，目标体重 {student.target_weight_kg}kg。"]
    if weights:
        w_text = "，".join(
            f"{w.record_date.isoformat()}={w.weight_kg}kg" for w in weights
        )
        parts.append(f"【近7天体重】{w_text}")
        parts.append(f"体重变化：{weights[0].weight_kg}kg → {weights[-1].weight_kg}kg")
    if metrics:
        m_text = "，".join(f"{m.metric_type}={m.value}{m.unit}({m.record_date.isoformat()})" for m in metrics)
        parts.append(f"【最近围度/体脂】{m_text}")
    if logs:
        l_text = "；".join(f"{l.log_date.isoformat()}{l.log_type}:{l.content}" for l in logs)
        parts.append(f"【最近饮食/运动】{l_text}")
    return "\n".join(parts)


async def chat_stream(
    db: AsyncSession, session_id: int, content: str
) -> AsyncGenerator[str, None]:
    """发送消息并流式返回回复。同时持久化 user/assistant 消息。"""
    session = (
        await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    ).scalar_one_or_none()
    if session is None:
        raise NotFoundError("会话不存在")

    # 1. 持久化用户消息
    user_msg = ChatMessage(session_id=session_id, role="user", content=content)
    db.add(user_msg)
    await db.commit()

    # 2. 组装 system prompt（含学员上下文）
    student_id = session.student_id
    system_prompt = (
        await _build_context_prompt(db, student_id) if student_id else BASE_SYSTEM_PROMPT
    )
    # 注入 RAG（MVP 空实现）
    rag_docs = await retriever.retrieve(content)
    if rag_docs:
        system_prompt += "\n\n【参考资料】\n" + "\n".join(rag_docs)

    # 3. 拉历史，转成 AgentScope Msg
    history_orm = await list_messages(db, session_id)
    # 排除刚存的 user_msg（reply_stream 内部会接收 user_text）
    prior = history_orm[:-1]
    history_msgs: list = []
    for m in prior:
        if m.role == "user":
            history_msgs.append(UserMsg("coach", m.content))
        else:
            history_msgs.append(AssistantMsg("SlimCoach", m.content))

    # 4. 流式生成 + 累积
    full_reply = []
    async for chunk in stream_reply(system_prompt, history_msgs, content):
        full_reply.append(chunk)
        yield chunk

    # 5. 持久化 assistant 消息
    assistant_msg = ChatMessage(
        session_id=session_id, role="assistant", content="".join(full_reply)
    )
    db.add(assistant_msg)
    await db.commit()
