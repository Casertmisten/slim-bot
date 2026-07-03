"""运维 API 测试。"""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


def test_version_endpoint():
    r = client.get("/api/v1/admin/version", headers=AUTH)
    assert r.status_code == 200
    assert "commit" in r.json()


def test_version_requires_auth():
    assert client.get("/api/v1/admin/version").status_code == 401
