"""APP 发布 API 测试。"""
import io
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


def test_check_version_no_release():
    assert client.get("/api/v1/app/version").status_code == 404


def test_upload_and_check():
    apk = io.BytesIO(b"fake apk content")
    r = client.post(
        "/api/v1/app/upload",
        data={"version": "1.0.1", "version_code": 2, "changelog": "修复", "force_update": "false"},
        files={"file": ("app.apk", apk, "application/octet-stream")},
        headers=AUTH,
    )
    assert r.status_code == 200
    assert r.json()["version"] == "1.0.1"
    # 检查版本
    v = client.get("/api/v1/app/version").json()
    assert v["version"] == "1.0.1"
    assert v["force_update"] is False
