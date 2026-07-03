"""学员档案 API 路由。"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import verify_token
from app.db import get_db
from app.schemas.common import Page
from app.schemas.student import StudentCreate, StudentUpdate, StudentOut
from app.service import student_service

router = APIRouter(prefix="/students", tags=["学员"], dependencies=[Depends(verify_token)])


@router.get("", response_model=Page[StudentOut])
async def list_students(
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    items, total = await student_service.list_students(db, search, page, page_size)
    return Page(items=items, total=total, page=page, page_size=page_size)


@router.post("", response_model=StudentOut, status_code=201)
async def create_student(data: StudentCreate, db: AsyncSession = Depends(get_db)):
    return await student_service.create_student(db, data)


@router.get("/{student_id}", response_model=StudentOut)
async def get_student(student_id: int, db: AsyncSession = Depends(get_db)):
    return await student_service.get_student(db, student_id)


@router.put("/{student_id}", response_model=StudentOut)
async def update_student(
    student_id: int, data: StudentUpdate, db: AsyncSession = Depends(get_db)
):
    return await student_service.update_student(db, student_id, data)


@router.delete("/{student_id}", status_code=204)
async def delete_student(student_id: int, db: AsyncSession = Depends(get_db)):
    await student_service.delete_student(db, student_id)
