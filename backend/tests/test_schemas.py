"""Schema 冒烟测试。"""
from datetime import date
import pytest
from pydantic import ValidationError
from app.schemas.student import StudentCreate
from app.schemas.record import WeightCreate
from app.schemas.record import BodyMetricCreate
from app.schemas.chat import ChatSessionCreate


def test_student_create_serializes():
    s = StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date=date(2026, 7, 1), notes="",
    )
    assert s.model_dump()["name"] == "小王"


def test_weight_create():
    w = WeightCreate(record_date=date(2026, 7, 1), weight_kg=80.5, note="")
    assert w.weight_kg == 80.5


def test_chat_session_create_no_student():
    c = ChatSessionCreate()
    assert c.student_id is None


def test_invalid_gender_rejected():
    """校验：非法 gender 被拒绝。"""
    with pytest.raises(ValidationError):
        StudentCreate(
            name="x", gender="unknown", age=30, height_cm=175.0,
            target_weight_kg=70.0, start_date=date(2026, 7, 1), notes="",
        )


def test_negative_body_metric_value_rejected():
    """校验：负数围度值被拒绝。"""
    with pytest.raises(ValidationError):
        BodyMetricCreate(record_date=date(2026, 7, 1), metric_type="腰围", value=-1.0, unit="cm")
