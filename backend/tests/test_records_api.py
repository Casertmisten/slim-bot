"""数据记录 API 测试。"""
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


@pytest.fixture
def student_id():
    r = client.post("/api/v1/students", json={
        "name": "小王", "gender": "male", "age": 30, "height_cm": 175.0,
        "target_weight_kg": 70.0, "start_date": "2026-07-01", "notes": "",
    }, headers=AUTH)
    return r.json()["id"]


def test_weight_upsert_and_list(student_id):
    # 同日两次录入，第二次覆盖
    client.post(f"/api/v1/students/{student_id}/weights",
                json={"record_date": "2026-07-01", "weight_kg": 80.0, "note": ""}, headers=AUTH)
    r2 = client.post(f"/api/v1/students/{student_id}/weights",
                     json={"record_date": "2026-07-01", "weight_kg": 79.5, "note": "更新"}, headers=AUTH)
    assert r2.json()["weight_kg"] == 79.5
    r = client.get(f"/api/v1/students/{student_id}/weights", headers=AUTH)
    assert len(r.json()) == 1  # 覆盖，非新增


def test_weight_list_by_range(student_id):
    for d, w in [("2026-07-01", 80), ("2026-07-02", 79.5), ("2026-07-03", 79)]:
        client.post(f"/api/v1/students/{student_id}/weights",
                    json={"record_date": d, "weight_kg": w, "note": ""}, headers=AUTH)
    r = client.get(f"/api/v1/students/{student_id}/weights?start=2026-07-02&end=2026-07-03", headers=AUTH)
    assert len(r.json()) == 2


def test_body_metric_crud(student_id):
    r = client.post(f"/api/v1/students/{student_id}/body-metrics",
                    json={"record_date": "2026-07-01", "metric_type": "腰围", "value": 90.0, "unit": "cm"}, headers=AUTH)
    assert r.status_code == 201
    assert client.get(f"/api/v1/students/{student_id}/body-metrics", headers=AUTH).json()[0]["metric_type"] == "腰围"


def test_daily_log_crud(student_id):
    r = client.post(f"/api/v1/students/{student_id}/daily-logs",
                    json={"log_date": "2026-07-01", "log_type": "breakfast", "content": "鸡蛋+牛奶", "calories": 300}, headers=AUTH)
    assert r.status_code == 201
    logs = client.get(f"/api/v1/students/{student_id}/daily-logs", headers=AUTH).json()
    assert len(logs) == 1
    assert logs[0]["content"] == "鸡蛋+牛奶"


def test_records_require_student(student_id):
    # 不存在的学员
    assert client.post("/api/v1/students/9999/weights",
                       json={"record_date": "2026-07-01", "weight_kg": 80.0, "note": ""}, headers=AUTH).status_code == 404
