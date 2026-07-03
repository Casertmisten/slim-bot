"""学员档案 Schema。"""
from datetime import date, datetime
from pydantic import BaseModel, Field


class StudentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    gender: str = Field(..., pattern="^(male|female|other)$")
    age: int = Field(..., ge=1, le=150)
    height_cm: float = Field(..., gt=0)
    target_weight_kg: float = Field(..., gt=0)
    start_date: date
    notes: str = ""


class StudentCreate(StudentBase):
    """新建学员请求体。"""
    pass


class StudentUpdate(BaseModel):
    """更新学员（全部可选，PATCH 语义）。"""
    name: str | None = Field(None, min_length=1, max_length=50)
    gender: str | None = Field(None, pattern="^(male|female|other)$")
    age: int | None = Field(None, ge=1, le=150)
    height_cm: float | None = Field(None, gt=0)
    target_weight_kg: float | None = Field(None, gt=0)
    start_date: date | None = None
    notes: str | None = None


class StudentOut(StudentBase):
    """学员响应体。"""
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
