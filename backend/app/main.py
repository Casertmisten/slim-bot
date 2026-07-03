"""FastAPI 应用入口。"""
from fastapi import FastAPI

app = FastAPI(title="减肥教练助手", version="0.1.0")


@app.get("/api/health")
async def health() -> dict:
    """健康检查端点（无需鉴权）。"""
    return {"status": "ok"}
