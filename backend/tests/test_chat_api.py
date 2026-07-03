"""对话 API 测试（mock LLM，不实际调用）。"""
import pytest
from unittest.mock import patch
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


def _make_session(student_id=None):
    r = client.post("/api/v1/chat/sessions", json={"student_id": student_id, "title": "测试"},
                    headers=AUTH)
    return r.json()["id"]


def test_create_list_session():
    sid = _make_session()
    assert sid is not None
    r = client.get("/api/v1/chat/sessions", headers=AUTH)
    assert len(r.json()) == 1


def test_send_message_sse_stream():
    """mock stream_reply，验证 SSE 格式。"""
    sid = _make_session()

    async def fake_stream(system_prompt, history, user_text):
        for chunk in ["你好", "教练"]:
            yield chunk

    with patch("app.service.chat_service.stream_reply", fake_stream):
        with client.stream("POST", f"/api/v1/chat/sessions/{sid}/messages",
                           json={"content": "在吗"}, headers=AUTH) as r:
            assert r.status_code == 200
            # iter_lines 在新版 httpx 返回 str，旧版返回 bytes，兼容处理
            body = "".join(
                line.decode() if isinstance(line, bytes) else line
                for line in r.iter_lines()
            )
            assert "chunk" in body
            assert "done" in body
            # 验证消息已持久化
            msgs = client.get(f"/api/v1/chat/sessions/{sid}/messages", headers=AUTH).json()
            assert len(msgs) == 2  # user + assistant
