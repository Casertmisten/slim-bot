"""RAG 检索抽象接口。MVP 给空实现；后期接向量库时只需实现 Retriever，
不改动 chat_service 上层逻辑。"""
from abc import ABC, abstractmethod


class Retriever(ABC):
    """RAG 检索接口。"""

    @abstractmethod
    async def retrieve(self, query: str, top_k: int = 3) -> list[str]:
        """返回相关文档片段列表。无 RAG 时返回空列表。"""
        ...


class EmptyRetriever(Retriever):
    """MVP 空实现：直接返回空上下文。"""

    async def retrieve(self, query: str, top_k: int = 3) -> list[str]:
        return []


# 根据 config 选择 retriever（MVP 永远是空实现）
retriever: Retriever = EmptyRetriever()
