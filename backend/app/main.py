"""FastAPI 应用入口。"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.db import engine
from app.exceptions import AppError
from app.model.base import Base
# 导入所有 model，确保 Base.metadata 注册全部表
from app.model import (  # noqa: F401
    student, record, chat_history, app_release,
)
from app.api import students, records, chat, admin, app_release


@asynccontextmanager
async def lifespan(app: FastAPI):
    """启动时自动建表（SQLite 个人项目足够；生产可用 Alembic）。"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title="减肥教练助手", version="0.1.0", lifespan=lifespan)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    """统一业务异常响应。"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"code": exc.code, "message": exc.message, "detail": exc.detail},
    )


@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Pydantic 校验错误也走统一格式。"""
    return JSONResponse(
        status_code=422,
        content={
            "code": "VALIDATION_ERROR",
            "message": "参数校验失败",
            "detail": exc.errors(),
        },
    )


@app.get("/api/health")
async def health() -> dict:
    """健康检查（无需鉴权）。"""
    return {"status": "ok"}


# 业务路由（统一 /api/v1 前缀）
app.include_router(students.router, prefix="/api/v1")
app.include_router(records.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(app_release.router, prefix="/api/v1")

# 托管 Flutter Web 产物（构建后放到 backend/static/）。
# 必须放在所有 API 路由之后，用 / 挂载（html=True 支持 SPA 回退 index.html）。
_web_dist = Path(__file__).parent.parent / "static"
if _web_dist.exists():
    app.mount("/", StaticFiles(directory=str(_web_dist), html=True), name="web")
