"""数据记录 ORM（体重 / 围度体脂 / 饮食运动）。"""
from datetime import date
from sqlalchemy import String, Float, Integer, Date, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.model.base import Base, TimestampMixin


class WeightRecord(Base, TimestampMixin):
    __tablename__ = "weight_records"
    __table_args__ = (
        UniqueConstraint("student_id", "record_date", name="uq_weight_student_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    record_date: Mapped[date] = mapped_column(Date)
    weight_kg: Mapped[float] = mapped_column(Float)
    note: Mapped[str] = mapped_column(String(200), default="")

    student = relationship("Student", back_populates="weights")


class BodyMetricRecord(Base, TimestampMixin):
    __tablename__ = "body_metric_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    record_date: Mapped[date] = mapped_column(Date)
    metric_type: Mapped[str] = mapped_column(String(30))  # 腰围/臀围/体脂率...
    value: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(10))  # cm/%

    student = relationship("Student", back_populates="body_metrics")


class DailyLog(Base, TimestampMixin):
    __tablename__ = "daily_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    log_date: Mapped[date] = mapped_column(Date)
    log_type: Mapped[str] = mapped_column(String(20))  # breakfast/lunch/...
    content: Mapped[str] = mapped_column(Text)
    calories: Mapped[float | None] = mapped_column(Float, nullable=True)

    student = relationship("Student", back_populates="daily_logs")
