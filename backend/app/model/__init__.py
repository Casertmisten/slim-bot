"""ORM 模型聚合导入。

所有模型在此统一导入，确保 SQLAlchemy 的映射器注册表与 Base.metadata
在任何只引用单个模型的场景下也能完整初始化（字符串关系解析、create_all 建全表）。
"""
from app.model.base import Base, TimestampMixin
from app.model.student import Student
from app.model.record import WeightRecord, BodyMetricRecord, DailyLog
from app.model.chat_history import ChatSession, ChatMessage
from app.model.app_release import AppRelease

__all__ = [
    "Base",
    "TimestampMixin",
    "Student",
    "WeightRecord",
    "BodyMetricRecord",
    "DailyLog",
    "ChatSession",
    "ChatMessage",
    "AppRelease",
]
