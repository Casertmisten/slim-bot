"""通用 Schema：分页、统一错误响应。"""
from typing import Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """分页响应。"""
    items: list[T]
    total: int
    page: int
    page_size: int


class ErrorResponse(BaseModel):
    """统一错误响应。"""
    code: str
    message: str
    detail: dict | None = None
