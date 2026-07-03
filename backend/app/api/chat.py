"""对话 API 路由（含 SSE 流式）。"""
import json
from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import verify_token
from app.db import async_session_factory, get_db
from app.exceptions import NotFoundError
from app.schemas.chat import ChatSessionCreate, ChatSessionOut, ChatMessageOut, ChatSendIn
from app.service import chat_service

router = APIRouter(prefix="/chat", tags=["对话"], dependencies=[Depends(verify_token)])


@router.post("/sessions", response_model=ChatSessionOut, status_code=201)
async def create_session(data: ChatSessionCreate, db: AsyncSession = Depends(get_db)):
    return await chat_service.create_session(db, data)


@router.get("/sessions", response_model=list[ChatSessionOut])
async def list_sessions(student_id: int | None = None, db: AsyncSession = Depends(get_db)):
    return await chat_service.list_sessions(db, student_id)


@router.get("/sessions/{session_id}/messages", response_model=list[ChatMessageOut])
async def list_messages(session_id: int, db: AsyncSession = Depends(get_db)):
    return await chat_service.list_messages(db, session_id)


@router.delete("/sessions/{session_id}", status_code=204)
async def delete_session(session_id: int, db: AsyncSession = Depends(get_db)):
    await chat_service.delete_session(db, session_id)


@router.post("/sessions/{session_id}/messages")
async def send_message(
    session_id: int, data: ChatSendIn, request: Request
) -> StreamingResponse:
    """发送消息 → SSE 流式返回。

    对话是长任务，用独立 session 避免与请求生命周期耦合。
    SSE 格式：data: {"type":"chunk","content":"..."} / data: {"type":"done"}
    """

    async def event_generator():
        # 独立 session（流式期间保持连接）
        async with async_session_factory() as db:
            try:
                async for chunk in chat_service.chat_stream(db, session_id, data.content):
                    if await request.is_disconnected():
                        break
                    yield f"data: {json.dumps({'type': 'chunk', 'content': chunk}, ensure_ascii=False)}\n\n"
                yield "data: {\"type\":\"done\"}\n\n"
            except NotFoundError as e:
                yield f"data: {json.dumps({'type': 'error', 'message': e.message}, ensure_ascii=False)}\n\n"
            except Exception:
                # LLM 或其他异常 → SSE error
                yield 'data: {"type":"error","message":"AI 服务暂时不可用"}\n\n'

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
