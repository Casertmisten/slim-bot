"""构建 AgentScope 使用的 LLM 模型实例（OpenAI 兼容 API）。

模块级单例：避免每次对话重建 credential/model。空 key 也能正常构造
（仅在实际调用 API 时才会校验），因此无 .env 的测试环境导入不会报错。
"""
from app.config import settings
from agentscope.credential import OpenAICredential
from agentscope.model import OpenAIChatModel

# 复用的 credential 与 model（模块级单例，避免每次对话重建）
_credential = OpenAICredential(api_key=settings.llm_api_key)
_model = OpenAIChatModel(
    credential=_credential,
    model=settings.llm_model,
    client_kwargs={"base_url": settings.llm_base_url},
    stream=True,
)


def get_model() -> OpenAIChatModel:
    """获取共享的 LLM 模型实例。"""
    return _model
