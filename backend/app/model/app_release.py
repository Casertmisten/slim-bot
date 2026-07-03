"""APP 版本发布 ORM。"""
from sqlalchemy import String, Integer, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.model.base import Base, TimestampMixin


class AppRelease(Base, TimestampMixin):
    __tablename__ = "app_releases"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    version: Mapped[str] = mapped_column(String(30))           # 如 1.0.1
    version_code: Mapped[int] = mapped_column(Integer)         # 递增 build 号
    apk_path: Mapped[str] = mapped_column(String(255))         # uploads/xxx.apk
    changelog: Mapped[str] = mapped_column(String(1000), default="")
    force_update: Mapped[bool] = mapped_column(Boolean, default=False)
