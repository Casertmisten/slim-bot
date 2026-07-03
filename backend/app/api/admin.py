"""运维 API：后端更新、版本查询。"""
from fastapi import APIRouter, Depends
from app.api.deps import verify_token
from app.exceptions import AppError
from app.service.update_service import run_update
from app.version import get_version_info

router = APIRouter(prefix="/admin", tags=["运维"], dependencies=[Depends(verify_token)])


@router.get("/version")
async def version() -> dict:
    """当前后端版本（git commit + 时间）。"""
    return get_version_info()


@router.post("/update")
async def update() -> dict:
    """触发后端自更新（git pull + uv sync）。systemd 随后重启。"""
    result = await run_update()
    return result
