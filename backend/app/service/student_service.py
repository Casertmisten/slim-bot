"""学员业务逻辑。"""
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.exceptions import NotFoundError
from app.model.student import Student
from app.schemas.student import StudentCreate, StudentUpdate


async def list_students(
    db: AsyncSession, search: str | None = None, page: int = 1, page_size: int = 20
) -> tuple[list[Student], int]:
    """学员列表（支持姓名搜索 + 分页）。返回 (items, total)。"""
    stmt = select(Student)
    if search:
        stmt = stmt.where(Student.name.like(f"%{search}%"))
    # 总数
    count_stmt = select(func.count()).select_from(stmt.order_by(None).subquery())
    total = (await db.execute(count_stmt)).scalar_one()
    # 分页
    stmt = stmt.order_by(Student.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    items = list((await db.execute(stmt)).scalars().all())
    return items, total


async def get_student(db: AsyncSession, student_id: int) -> Student:
    """获取单个学员，不存在抛 NotFoundError。"""
    s = (await db.execute(select(Student).where(Student.id == student_id))).scalar_one_or_none()
    if s is None:
        raise NotFoundError("学员不存在", detail={"student_id": student_id})
    return s


async def create_student(db: AsyncSession, data: StudentCreate) -> Student:
    """新建学员。"""
    s = Student(**data.model_dump())
    db.add(s)
    await db.commit()
    await db.refresh(s)
    return s


async def update_student(db: AsyncSession, student_id: int, data: StudentUpdate) -> Student:
    """更新学员（仅非 None 字段）。"""
    s = await get_student(db, student_id)
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(s, k, v)
    await db.commit()
    await db.refresh(s)
    return s


async def delete_student(db: AsyncSession, student_id: int) -> None:
    """删除学员（级联删除其记录）。"""
    s = await get_student(db, student_id)
    await db.delete(s)
    await db.commit()
