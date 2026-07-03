"""数据库建表测试。"""
from datetime import date

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import engine
from app.model.base import Base
from app.model.student import Student
from app.model.record import WeightRecord


@pytest.fixture
async def prepare_db():
    """每个测试前重建表。"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield


async def test_create_student(prepare_db):
    from sqlalchemy import select
    from app.db import async_session_factory

    async with async_session_factory() as session:  # type: AsyncSession
        s = Student(name="小王", gender="male", age=30, height_cm=175.0,
                    target_weight_kg=70.0, start_date=date(2026, 7, 1))
        session.add(s)
        await session.commit()

        result = await session.execute(select(Student).where(Student.name == "小王"))
        found = result.scalar_one()
        assert found.age == 30
