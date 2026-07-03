"""学员 API 测试。"""
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import engine
from app.model.base import Base

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


@pytest.fixture(autouse=True)
def reset_db():
    import asyncio
    async def _reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_reset())
    yield


def _payload(name="小王"):
    return {"name": name, "gender": "male", "age": 30, "height_cm": 175.0,
            "target_weight_kg": 70.0, "start_date": "2026-07-01", "notes": ""}


def test_create_student():
    r = client.post("/api/v1/students", json=_payload(), headers=AUTH)
    assert r.status_code == 201
    assert r.json()["name"] == "小王"


def test_create_student_no_auth_401():
    r = client.post("/api/v1/students", json=_payload())
    assert r.status_code == 401


def test_list_and_search():
    for n in ["小王", "小李"]:
        client.post("/api/v1/students", json=_payload(n), headers=AUTH)
    r = client.get("/api/v1/students", headers=AUTH)
    assert r.json()["total"] == 2
    r = client.get("/api/v1/students?search=王", headers=AUTH)
    assert r.json()["total"] == 1


def test_get_update_delete():
    sid = client.post("/api/v1/students", json=_payload(), headers=AUTH).json()["id"]
    assert client.get(f"/api/v1/students/{sid}", headers=AUTH).status_code == 200
    assert client.put(f"/api/v1/students/{sid}", json={"age": 31}, headers=AUTH).json()["age"] == 31
    assert client.delete(f"/api/v1/students/{sid}", headers=AUTH).status_code == 204
    assert client.get(f"/api/v1/students/{sid}", headers=AUTH).status_code == 404
