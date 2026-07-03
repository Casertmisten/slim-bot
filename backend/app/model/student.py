"""学员档案 ORM。"""
from datetime import date
from sqlalchemy import String, Float, Integer, Date, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.model.base import Base, TimestampMixin


class Student(Base, TimestampMixin):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50))
    gender: Mapped[str] = mapped_column(String(10))  # male/female/other
    age: Mapped[int] = mapped_column(Integer)
    height_cm: Mapped[float] = mapped_column(Float)
    target_weight_kg: Mapped[float] = mapped_column(Float)
    start_date: Mapped[date] = mapped_column(Date)
    notes: Mapped[str] = mapped_column(Text, default="")

    # 关联记录（懒加载）
    weights = relationship("WeightRecord", back_populates="student", cascade="all, delete-orphan")
    body_metrics = relationship("BodyMetricRecord", back_populates="student", cascade="all, delete-orphan")
    daily_logs = relationship("DailyLog", back_populates="student", cascade="all, delete-orphan")
