"""对话上下文组装测试（不实际调用 LLM）。"""
import pytest
from datetime import date
from app.db import async_session_factory, engine
from app.model.base import Base
from app.model.student import Student
from app.model.record import WeightRecord, BodyMetricRecord
from app.service.chat_service import _build_context_prompt


@pytest.fixture
async def db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        yield session


async def test_context_contains_student_data(db):
    s = Student(name="小王", gender="male", age=30, height_cm=175.0,
                target_weight_kg=70.0, start_date=date(2026, 7, 1))
    db.add(s)
    await db.flush()
    today = date.today()
    db.add(WeightRecord(student_id=s.id, record_date=today, weight_kg=80.0))
    db.add(BodyMetricRecord(student_id=s.id, record_date=today, metric_type="腰围", value=90.0, unit="cm"))
    await db.commit()

    prompt = await _build_context_prompt(db, s.id)
    assert "小王" in prompt
    assert "近7天体重" in prompt
    assert "腰围" in prompt


async def test_context_no_student_returns_base(db):
    """学员不存在时返回基础 prompt，不报错。"""
    prompt = await _build_context_prompt(db, 9999)
    assert "减肥教练" in prompt
