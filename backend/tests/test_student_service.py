"""学员 Service 测试。"""
import pytest
from app.db import async_session_factory, engine
from app.model.base import Base
from app.service import student_service
from app.schemas.student import StudentCreate, StudentUpdate
from app.exceptions import NotFoundError


@pytest.fixture
async def db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        yield session


async def test_create_and_get(db):
    data = StudentCreate(name="小王", gender="male", age=30, height_cm=175.0,
                         target_weight_kg=70.0, start_date="2026-07-01")
    s = await student_service.create_student(db, data)
    assert s.id is not None
    got = await student_service.get_student(db, s.id)
    assert got.name == "小王"


async def test_get_not_found(db):
    with pytest.raises(NotFoundError):
        await student_service.get_student(db, 9999)


async def test_list_with_search(db):
    for name in ["小王", "小李", "大王"]:
        await student_service.create_student(db, StudentCreate(
            name=name, gender="male", age=30, height_cm=175.0,
            target_weight_kg=70.0, start_date="2026-07-01"))
    items, total = await student_service.list_students(db, search="王")
    assert total == 2
    assert {i.name for i in items} == {"小王", "大王"}


async def test_update(db):
    s = await student_service.create_student(db, StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date="2026-07-01"))
    updated = await student_service.update_student(db, s.id, StudentUpdate(age=31))
    assert updated.age == 31


async def test_delete(db):
    s = await student_service.create_student(db, StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date="2026-07-01"))
    await student_service.delete_student(db, s.id)
    with pytest.raises(NotFoundError):
        await student_service.get_student(db, s.id)
