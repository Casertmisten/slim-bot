"""安卓 OTA API：版本检查 + apk 上传。"""
from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import verify_token
from app.db import get_db
from app.exceptions import NotFoundError
from app.service import app_release_service

router = APIRouter(tags=["APP 发布"])


@router.get("/app/version")
async def check_version(db: AsyncSession = Depends(get_db)) -> dict:
    """APP 检查更新（无需鉴权，启动时调用）。"""
    rel = await app_release_service.get_latest_release(db)
    if rel is None:
        raise NotFoundError("暂无发布版本")
    return {
        "version": rel.version,
        "version_code": rel.version_code,
        "url": f"/api/v1/app/download/{rel.id}",
        "force_update": rel.force_update,
        "changelog": rel.changelog,
    }


@router.post("/app/upload", dependencies=[Depends(verify_token)])
async def upload_apk(
    version: str = Form(...),
    version_code: int = Form(...),
    changelog: str = Form(""),
    force_update: bool = Form(False),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """上传新 apk（仅教练 Token）。"""
    rel = await app_release_service.upload_apk(
        db, version, version_code, changelog, force_update, file
    )
    return {"id": rel.id, "version": rel.version}
