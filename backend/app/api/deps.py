"""FastAPI 依赖注入：Token 鉴权。"""
import secrets
from fastapi import Header, HTTPException, status
from app.config import settings


async def verify_token(authorization: str | None = Header(default=None)) -> None:
    """校验 Bearer Token，与 settings.app_token 比对。"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "UNAUTHORIZED", "message": "缺少或格式错误的 Token"},
        )
    token = authorization.removeprefix("Bearer ").strip()
    # secrets.compare_digest 防止计时攻击
    if not secrets.compare_digest(token, settings.app_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_TOKEN", "message": "Token 无效"},
        )
