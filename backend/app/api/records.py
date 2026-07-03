"""数据记录 API 路由。"""
from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import verify_token
from app.db import get_db
from app.schemas.record import (
    WeightCreate, WeightOut, BodyMetricCreate, BodyMetricOut,
    DailyLogCreate, DailyLogOut,
)
from app.service import record_service

router = APIRouter(prefix="/students/{student_id}", tags=["数据记录"], dependencies=[Depends(verify_token)])


# ===== 体重 =====
@router.get("/weights", response_model=list[WeightOut])
async def list_weights(
    student_id: int,
    start: date | None = Query(None),
    end: date | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    return await record_service.list_weights(db, student_id, start, end)


@router.post("/weights", response_model=WeightOut, status_code=201)
async def upsert_weight(
    student_id: int, data: WeightCreate, db: AsyncSession = Depends(get_db)
):
    return await record_service.upsert_weight(db, student_id, data)


@router.delete("/weights/{record_id}", status_code=204)
async def delete_weight(student_id: int, record_id: int, db: AsyncSession = Depends(get_db)):
    await record_service.delete_weight(db, student_id, record_id)


# ===== 围度 / 体脂 =====
@router.get("/body-metrics", response_model=list[BodyMetricOut])
async def list_body_metrics(
    student_id: int,
    start: date | None = Query(None),
    end: date | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    return await record_service.list_body_metrics(db, student_id, start, end)


@router.post("/body-metrics", response_model=BodyMetricOut, status_code=201)
async def create_body_metric(
    student_id: int, data: BodyMetricCreate, db: AsyncSession = Depends(get_db)
):
    return await record_service.create_body_metric(db, student_id, data)


@router.delete("/body-metrics/{record_id}", status_code=204)
async def delete_body_metric(student_id: int, record_id: int, db: AsyncSession = Depends(get_db)):
    await record_service.delete_body_metric(db, student_id, record_id)


# ===== 饮食 / 运动 =====
@router.get("/daily-logs", response_model=list[DailyLogOut])
async def list_daily_logs(
    student_id: int, date: date | None = Query(None), db: AsyncSession = Depends(get_db)
):
    return await record_service.list_daily_logs(db, student_id, date)


@router.post("/daily-logs", response_model=DailyLogOut, status_code=201)
async def create_daily_log(
    student_id: int, data: DailyLogCreate, db: AsyncSession = Depends(get_db)
):
    return await record_service.create_daily_log(db, student_id, data)


@router.delete("/daily-logs/{record_id}", status_code=204)
async def delete_daily_log(student_id: int, record_id: int, db: AsyncSession = Depends(get_db)):
    await record_service.delete_daily_log(db, student_id, record_id)
