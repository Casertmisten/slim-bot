"""APP 发布服务：保存上传的 apk、查询最新版本。"""
import shutil
from pathlib import Path
from fastapi import UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.config import settings
from app.exceptions import ValidationError
from app.model.app_release import AppRelease


async def upload_apk(
    db: AsyncSession,
    version: str,
    version_code: int,
    changelog: str,
    force_update: bool,
    file: UploadFile,
) -> AppRelease:
    """保存上传的 apk 到 uploads/，并记录版本。"""
    if not file.filename or not file.filename.endswith(".apk"):
        raise ValidationError("请上传 .apk 文件")
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(parents=True, exist_ok=True)
    save_name = f"slim_bot-{version}-{version_code}.apk"
    save_path = upload_dir / save_name
    with save_path.open("wb") as f:
        shutil.copyfileobj(file.file, f)
    release = AppRelease(
        version=version, version_code=version_code,
        apk_path=str(save_path), changelog=changelog, force_update=force_update,
    )
    db.add(release)
    await db.commit()
    await db.refresh(release)
    return release


async def get_latest_release(db: AsyncSession) -> AppRelease | None:
    """查询最新版本。"""
    stmt = select(AppRelease).order_by(AppRelease.version_code.desc()).limit(1)
    return (await db.execute(stmt)).scalar_one_or_none()
