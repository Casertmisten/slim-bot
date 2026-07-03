"""数据记录业务逻辑：体重、围度体脂、饮食运动。"""
from datetime import date
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.exceptions import NotFoundError
from app.model.record import WeightRecord, BodyMetricRecord, DailyLog
from app.service.student_service import get_student
from app.schemas.record import WeightCreate, BodyMetricCreate, DailyLogCreate


async def _check_student(db: AsyncSession, student_id: int) -> None:
    """校验学员存在（不存在抛 NotFoundError）。"""
    await get_student(db, student_id)


# ============ 体重 ============
async def list_weights(
    db: AsyncSession, student_id: int, start: date | None = None, end: date | None = None
) -> list[WeightRecord]:
    await _check_student(db, student_id)
    stmt = select(WeightRecord).where(WeightRecord.student_id == student_id)
    if start:
        stmt = stmt.where(WeightRecord.record_date >= start)
    if end:
        stmt = stmt.where(WeightRecord.record_date <= end)
    stmt = stmt.order_by(WeightRecord.record_date.asc())
    return list((await db.execute(stmt)).scalars().all())


async def upsert_weight(
    db: AsyncSession, student_id: int, data: WeightCreate
) -> WeightRecord:
    """录入体重（日期重复则覆盖）。依赖唯一约束。"""
    await _check_student(db, student_id)
    existing = (
        await db.execute(
            select(WeightRecord).where(
                WeightRecord.student_id == student_id,
                WeightRecord.record_date == data.record_date,
            )
        )
    ).scalar_one_or_none()
    if existing:
        existing.weight_kg = data.weight_kg
        existing.note = data.note
        await db.commit()
        await db.refresh(existing)
        return existing
    rec = WeightRecord(student_id=student_id, **data.model_dump())
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec


async def delete_weight(db: AsyncSession, student_id: int, record_id: int) -> None:
    rec = (
        await db.execute(
            select(WeightRecord).where(
                WeightRecord.id == record_id, WeightRecord.student_id == student_id
            )
        )
    ).scalar_one_or_none()
    if rec is None:
        raise NotFoundError("记录不存在")
    await db.delete(rec)
    await db.commit()


# ============ 围度 / 体脂 ============
async def list_body_metrics(
    db: AsyncSession, student_id: int, start: date | None = None, end: date | None = None
) -> list[BodyMetricRecord]:
    await _check_student(db, student_id)
    stmt = select(BodyMetricRecord).where(BodyMetricRecord.student_id == student_id)
    if start:
        stmt = stmt.where(BodyMetricRecord.record_date >= start)
    if end:
        stmt = stmt.where(BodyMetricRecord.record_date <= end)
    stmt = stmt.order_by(BodyMetricRecord.record_date.asc())
    return list((await db.execute(stmt)).scalars().all())


async def create_body_metric(
    db: AsyncSession, student_id: int, data: BodyMetricCreate
) -> BodyMetricRecord:
    await _check_student(db, student_id)
    rec = BodyMetricRecord(student_id=student_id, **data.model_dump())
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec


async def delete_body_metric(db: AsyncSession, student_id: int, record_id: int) -> None:
    rec = (
        await db.execute(
            select(BodyMetricRecord).where(
                BodyMetricRecord.id == record_id, BodyMetricRecord.student_id == student_id
            )
        )
    ).scalar_one_or_none()
    if rec is None:
        raise NotFoundError("记录不存在")
    await db.delete(rec)
    await db.commit()


# ============ 饮食 / 运动 ============
async def list_daily_logs(
    db: AsyncSession, student_id: int, log_date: date | None = None
) -> list[DailyLog]:
    await _check_student(db, student_id)
    stmt = select(DailyLog).where(DailyLog.student_id == student_id)
    if log_date:
        stmt = stmt.where(DailyLog.log_date == log_date)
    stmt = stmt.order_by(DailyLog.log_date.desc(), DailyLog.created_at.asc())
    return list((await db.execute(stmt)).scalars().all())


async def create_daily_log(
    db: AsyncSession, student_id: int, data: DailyLogCreate
) -> DailyLog:
    await _check_student(db, student_id)
    rec = DailyLog(student_id=student_id, **data.model_dump())
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec


async def delete_daily_log(db: AsyncSession, student_id: int, record_id: int) -> None:
    rec = (
        await db.execute(
            select(DailyLog).where(
                DailyLog.id == record_id, DailyLog.student_id == student_id
            )
        )
    ).scalar_one_or_none()
    if rec is None:
        raise NotFoundError("记录不存在")
    await db.delete(rec)
    await db.commit()
