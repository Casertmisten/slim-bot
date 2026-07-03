"""鉴权依赖测试。"""
import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from app.api.deps import verify_token

app = FastAPI()


@app.get("/protected")
async def protected(_: None = Depends(verify_token)) -> dict:
    return {"ok": True}


@pytest.fixture
def client():
    return TestClient(app)


def test_no_token_returns_401(client):
    r = client.get("/protected")
    assert r.status_code == 401


def test_wrong_token_returns_401(client):
    r = client.get("/protected", headers={"Authorization": "Bearer wrong"})
    assert r.status_code == 401


def test_right_token_passes(client, monkeypatch):
    monkeypatch.setattr("app.api.deps.settings.app_token", "secret")
    r = client.get("/protected", headers={"Authorization": "Bearer secret"})
    assert r.status_code == 200
    assert r.json() == {"ok": True}
