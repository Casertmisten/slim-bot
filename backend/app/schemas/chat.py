"""对话 Schema。"""
from datetime import datetime
from pydantic import BaseModel


class ChatSessionCreate(BaseModel):
    """新建会话。student_id 可空（不绑定学员）。"""
    student_id: int | None = None
    title: str | None = None


class ChatSessionOut(BaseModel):
    id: int
    student_id: int | None
    title: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatMessageOut(BaseModel):
    id: int
    session_id: int
    role: str  # user / assistant
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatSendIn(BaseModel):
    """发送对话消息请求体。"""
    content: str
