"""Schema 冒烟测试。"""
from datetime import date
from app.schemas.student import StudentCreate
from app.schemas.record import WeightCreate
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
