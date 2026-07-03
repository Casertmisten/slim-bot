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


async def test_cascade_delete_removes_weights(prepare_db):
    """验证 SQLite 外键级联生效：删除学员应级联删除其体重记录。"""
    from sqlalchemy import select, delete
    from app.db import async_session_factory

    async with async_session_factory() as session:
        s = Student(name="小王", gender="male", age=30, height_cm=175.0,
                    target_weight_kg=70.0, start_date=date(2026, 7, 1))
        session.add(s)
        await session.flush()
        session.add(WeightRecord(student_id=s.id, record_date=date(2026, 7, 1), weight_kg=80.0))
        await session.commit()
        sid = s.id
        # 删除学员
        await session.execute(delete(Student).where(Student.id == sid))
        await session.commit()

    # 新连接查询：体重记录应被级联删除
    async with async_session_factory() as session:
        leftover = (await session.execute(
            select(WeightRecord).where(WeightRecord.student_id == sid)
        )).scalars().all()
        assert leftover == [], "外键级联未生效，删除学员后仍残留体重记录"
