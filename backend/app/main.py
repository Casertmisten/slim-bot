"""FastAPI 应用入口。"""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.exceptions import AppError

app = FastAPI(title="减肥教练助手", version="0.1.0")


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
