"""LLM 配置构建测试（不实际调用 API）。"""
from app.agent.retriever import EmptyRetriever
from app.agent.llm import get_model


def test_model_can_be_built():
    m = get_model()
    # 仅验证对象可构造，不发起网络请求
    assert m is not None


async def test_empty_retriever_returns_empty():
    r = EmptyRetriever()
    assert await r.retrieve("任意查询") == []
