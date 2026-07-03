"""教练对话 Agent（基于 AgentScope）。

职责：接收组装好的 system prompt（含学员上下文）+ 历史消息，
用 reply_stream 流式输出回复。Agent 层只管对话，不关心业务数据获取。
"""
from collections.abc import AsyncGenerator
from agentscope.agent import Agent
from agentscope.tool import Toolkit
from agentscope.message import Msg, UserMsg
from app.agent.llm import get_model


def build_coach_agent(system_prompt: str) -> Agent:
    """构建一个带指定 system prompt 的教练 Agent。"""
    return Agent(
        name="SlimCoach",
        system_prompt=system_prompt,
        model=get_model(),
        toolkit=Toolkit(),  # MVP 不带工具；预留工具扩展
    )


async def stream_reply(
    system_prompt: str, history: list[Msg], user_text: str
) -> AsyncGenerator[str, None]:
    """流式生成回复，逐块 yield 文本增量。

    - system_prompt: 含学员数据的系统提示
    - history: 历史对话消息
    - user_text: 本次用户输入
    """
    agent = build_coach_agent(system_prompt)
    # 把历史灌入 agent state
    agent.state.context.extend(history)
    user_msg = UserMsg("coach", user_text)
    async for event in agent.reply_stream(user_msg):
        # 只关心文本增量事件
        if event.type == "TEXT_BLOCK_DELTA" and getattr(event, "delta", None):
            yield event.delta
