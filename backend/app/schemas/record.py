"""数据记录 Schema（体重 / 围度体脂 / 饮食运动）。"""
from datetime import date, datetime
from pydantic import BaseModel, Field


# ===== 体重 =====
class WeightCreate(BaseModel):
    record_date: date
    weight_kg: float = Field(..., gt=0)
    note: str = ""


class WeightOut(BaseModel):
    id: int
    student_id: int
    record_date: date
    weight_kg: float
    note: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ===== 围度 / 体脂 =====
class BodyMetricCreate(BaseModel):
    record_date: date
    metric_type: str = Field(..., min_length=1, max_length=30)
    value: float
    unit: str = Field(..., max_length=10)


class BodyMetricOut(BaseModel):
    id: int
    student_id: int
    record_date: date
    metric_type: str
    value: float
    unit: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ===== 饮食 / 运动 =====
class DailyLogCreate(BaseModel):
    log_date: date
    log_type: str = Field(..., pattern="^(breakfast|lunch|dinner|snack|exercise)$")
    content: str = Field(..., min_length=1)
    calories: float | None = None


class DailyLogOut(BaseModel):
    id: int
    student_id: int
    log_date: date
    log_type: str
    content: str
    calories: float | None
    created_at: datetime

    model_config = {"from_attributes": True}
