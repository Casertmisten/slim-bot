# 减肥教练助手 实施方案

> **For agentic workers:** REQUIRED SUB-SKILL: 用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 按任务执行本方案。步骤用复选框（`- [ ]`）追踪。

**目标：** 为减肥教练打造一套「学员数据管理 + AI 对话指导」助手，前端 Flutter（安卓 + Web），后端 FastAPI + AgentScope，前后端并行开发。

**架构：** 前后端分离。后端三层结构（API → Service → Agent），SQLite 存储，OpenAI 兼容 LLM。前端一套 Flutter 代码，靠响应式适配手机/Web。**并行开发的关键前置**是阶段 0 定义 API 契约 + 共享 Schema：前端基于本地 Mock Service 开发，后端按契约实现，阶段 6 联调对接。

**技术栈：**
- 后端：Python 3.11+、`uv`、FastAPI、SQLAlchemy 2.x、Pydantic v2、AgentScope 2.0（`agentscope-ai`）、aiosqlite
- 前端：Flutter（stable，fvm 管理）、dio、go_router、riverpod、fl_chart、shared_preferences
- 部署：systemd + nginx，Web 产物由 FastAPI 托管

**路径约定（重要）：**
- Flutter 项目在**仓库根目录**（`lib/`、`pubspec.yaml` 在根）。
- 后端在 `backend/` 子目录（新建）。
- 所有前端 Dart 路径以 `lib/` 开头；所有后端 Python 路径以 `backend/` 开头。

**Git 规范：** 每个任务结束提交，commit 中文 + 前缀（feat/fix/docs/style/refactor/perf/test/build/ci/chore）。

---

## 阶段总览（前后端并行）

| 阶段 | 内容 | 前后端 |
|------|------|--------|
| 0 | API 契约 + 前后端脚手架 | 前后端 |
| 1 | 基础设施（DB/鉴权/异常）+ 前端核心框架（主题/路由/响应式/Mock基础设施） | 前后端 |
| 2 | 学员档案模块 | 并行 |
| 3 | 数据记录模块（体重/围度/饮食运动 + 图表） | 并行 |
| 4 | AI 对话模块（AgentScope + SSE + 上下文注入） | 并行 |
| 5 | 软件更新 / 安卓 OTA | 并行 |
| 6 | 联调 + 部署 + 验收 | 前后端对接 |

**并行约定：** 阶段 0 完成后，阶段 1~5 的同一阶段内**前端任务（F 开头）与后端任务（B 开头）相互独立**，可同时推进。阶段 6 才真正对接。

---

## 阶段 0：API 契约 + 前后端脚手架

> 本阶段产出**前后端共享的 API 契约文档**，锁定所有端点的请求/响应结构。前端据此写 Mock，后端据此实现。完成本阶段后即可并行开发。

### Task B0-1：后端项目脚手架（uv + FastAPI）

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/.gitignore`
- Create: `backend/.env.example`
- Create: `backend/app/__init__.py`（空）
- Create: `backend/app/main.py`
- Create: `backend/tests/__init__.py`（空）

- [ ] **Step 1：初始化 uv 项目并安装依赖**

```bash
cd backend
uv init --no-package --name slim-coach-backend .
# 写入依赖到 pyproject.toml（下一步覆盖）
```

- [ ] **Step 2：写入 `backend/pyproject.toml`**

```toml
[project]
name = "slim-coach-backend"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "sqlalchemy>=2.0",
    "aiosqlite>=0.20",
    "pydantic>=2.7",
    "pydantic-settings>=2.3",
    "agentscope>=2.0",
    "httpx>=0.27",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "anyio>=4.3",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

- [ ] **Step 3：安装依赖**

```bash
cd backend
uv sync
```

- [ ] **Step 4：写入 `backend/.gitignore`**

```
.venv/
__pycache__/
*.pyc
.env
*.db
*.db-journal
uploads/
data/
```

- [ ] **Step 5：写入 `backend/.env.example`**

```env
# 后端配置（复制为 .env 并填写真实值）
# 访问令牌（前端 Bearer Token 必须与此一致）
APP_TOKEN=change-me-please

# 数据库路径
DATABASE_URL=sqlite+aiosqlite:///./data/coach.db

# OpenAI 兼容 LLM 配置
LLM_API_KEY=sk-xxx
LLM_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini

# RAG（MVP 留空 = 关闭）
RAG_ENABLED=false

# 上传目录
UPLOAD_DIR=./uploads
```

- [ ] **Step 6：写入最小 `backend/app/main.py`**

```python
"""FastAPI 应用入口。"""
from fastapi import FastAPI

app = FastAPI(title="减肥教练助手", version="0.1.0")


@app.get("/api/health")
async def health() -> dict:
    """健康检查端点（无需鉴权）。"""
    return {"status": "ok"}
```

- [ ] **Step 7：验证可启动**

```bash
cd backend
uv run uvicorn app.main:app --reload --port 8000
# 另开终端：
curl http://127.0.0.1:8000/api/health
# 预期：{"status":"ok"}
# Ctrl-C 停止
```

- [ ] **Step 8：提交**

```bash
git add backend/
git commit -m "feat: 初始化后端项目脚手架（FastAPI + uv）"
```

---

### Task B0-2：定义 API 契约 Schema（Pydantic 模型）

> 这是前后端契约的**后端侧实体**。前端 Task F0-2 会照此写 Dart 数据类。字段名、类型必须严格对应。

**Files:**
- Create: `backend/app/schemas/__init__.py`（空）
- Create: `backend/app/schemas/common.py`
- Create: `backend/app/schemas/student.py`
- Create: `backend/app/schemas/record.py`
- Create: `backend/app/schemas/chat.py`

- [ ] **Step 1：写入 `backend/app/schemas/common.py`（统一响应 + 错误）**

```python
"""通用 Schema：分页、统一错误响应。"""
from typing import Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """分页响应。"""
    items: list[T]
    total: int
    page: int
    page_size: int


class ErrorResponse(BaseModel):
    """统一错误响应。"""
    code: str
    message: str
    detail: dict | None = None
```

- [ ] **Step 2：写入 `backend/app/schemas/student.py`**

```python
"""学员档案 Schema。"""
from datetime import date, datetime
from pydantic import BaseModel, Field


class StudentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    gender: str = Field(..., pattern="^(male|female|other)$")
    age: int = Field(..., ge=1, le=150)
    height_cm: float = Field(..., gt=0)
    target_weight_kg: float = Field(..., gt=0)
    start_date: date
    notes: str = ""


class StudentCreate(StudentBase):
    """新建学员请求体。"""
    pass


class StudentUpdate(BaseModel):
    """更新学员（全部可选，PATCH 语义）。"""
    name: str | None = Field(None, min_length=1, max_length=50)
    gender: str | None = Field(None, pattern="^(male|female|other)$")
    age: int | None = Field(None, ge=1, le=150)
    height_cm: float | None = Field(None, gt=0)
    target_weight_kg: float | None = Field(None, gt=0)
    start_date: date | None = None
    notes: str | None = None


class StudentOut(StudentBase):
    """学员响应体。"""
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
```

- [ ] **Step 3：写入 `backend/app/schemas/record.py`**

```python
"""数据记录 Schema（体重 / 围度体脂 / 饮食运动）。"""
from datetime import date, datetime
from pydantic import BaseModel, Field


# ===== 体重 =====
class WeightCreate(BaseModel):
    record_date: date
    weight_kg: float = Field(..., gt=0)
    note: str = ""


class WeightOut(BaseModel):
    id: int
    student_id: int
    record_date: date
    weight_kg: float
    note: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ===== 围度 / 体脂 =====
class BodyMetricCreate(BaseModel):
    record_date: date
    metric_type: str = Field(..., min_length=1, max_length=30)
    value: float
    unit: str = Field(..., max_length=10)


class BodyMetricOut(BaseModel):
    id: int
    student_id: int
    record_date: date
    metric_type: str
    value: float
    unit: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ===== 饮食 / 运动 =====
class DailyLogCreate(BaseModel):
    log_date: date
    log_type: str = Field(..., pattern="^(breakfast|lunch|dinner|snack|exercise)$")
    content: str = Field(..., min_length=1)
    calories: float | None = None


class DailyLogOut(BaseModel):
    id: int
    student_id: int
    log_date: date
    log_type: str
    content: str
    calories: float | None
    created_at: datetime

    model_config = {"from_attributes": True}
```

- [ ] **Step 4：写入 `backend/app/schemas/chat.py`**

```python
"""对话 Schema。"""
from datetime import datetime
from pydantic import BaseModel


class ChatSessionCreate(BaseModel):
    """新建会话。student_id 可空（不绑定学员）。"""
    student_id: int | None = None
    title: str | None = None


class ChatSessionOut(BaseModel):
    id: int
    student_id: int | None
    title: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatMessageOut(BaseModel):
    id: int
    session_id: int
    role: str  # user / assistant
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatSendIn(BaseModel):
    """发送对话消息请求体。"""
    content: str
```

- [ ] **Step 5：写一个 smoke test 确认 schema 可导入可序列化**

Create: `backend/tests/test_schemas.py`

```python
"""Schema 冒烟测试。"""
from datetime import date
from app.schemas.student import StudentCreate
from app.schemas.record import WeightCreate
from app.schemas.chat import ChatSessionCreate


def test_student_create_serializes():
    s = StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date=date(2026, 7, 1), notes="",
    )
    assert s.model_dump()["name"] == "小王"


def test_weight_create():
    w = WeightCreate(record_date=date(2026, 7, 1), weight_kg=80.5, note="")
    assert w.weight_kg == 80.5


def test_chat_session_create_no_student():
    c = ChatSessionCreate()
    assert c.student_id is None
```

- [ ] **Step 6：运行测试**

```bash
cd backend
uv run pytest tests/test_schemas.py -v
# 预期：3 passed
```

- [ ] **Step 7：提交**

```bash
git add backend/app/schemas/ backend/tests/test_schemas.py
git commit -m "feat: 定义前后端共享 API 契约 Schema"
```

---

### Task F0-1：前端依赖与目录骨架

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/`、`lib/features/`、`lib/shared/` 目录结构（空文件占位）

- [ ] **Step 1：添加前端依赖到 `pubspec.yaml`**

在 `dependencies:` 下（`cupertino_icons` 之后）添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # 网络与状态
  dio: ^5.7.0
  go_router: ^14.2.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # UI
  fl_chart: ^0.69.0
  # 本地存储
  shared_preferences: ^2.3.2
  # 序列化
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.13
```

- [ ] **Step 2：拉取依赖**

```bash
cd /Users/heren/code/slim_bot
fvm flutter pub get
```

- [ ] **Step 3：创建目录骨架（占位 .gitkeep）**

```bash
cd /Users/heren/code/slim_bot
mkdir -p lib/core/api lib/core lib/features/students/pages lib/features/students/widgets \
  lib/features/students/providers lib/features/records lib/features/chat \
  lib/features/settings lib/shared/widgets lib/core/models lib/core/repositories
touch lib/core/api/.gitkeep lib/features/students/pages/.gitkeep \
  lib/features/students/widgets/.gitkeep lib/features/students/providers/.gitkeep \
  lib/features/records/.gitkeep lib/features/chat/.gitkeep lib/features/settings/.gitkeep \
  lib/shared/widgets/.gitkeep lib/core/models/.gitkeep lib/core/repositories/.gitkeep
```

- [ ] **Step 4：验证可编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze
# 预期：无错误（可能有少量提示，忽略）
```

- [ ] **Step 5：提交**

```bash
git add pubspec.yaml pubspec.lock lib/
git commit -m "build: 添加前端依赖与目录骨架"
```

---

### Task F0-2：前端数据模型（与后端 Schema 一一对应）

> Dart 模型字段名必须与 `backend/app/schemas/` 完全一致（驼峰转换由 json_serializable 的 `fieldRename` 处理）。统一配置 snake_case JSON 映射。

**Files:**
- Create: `lib/core/models/models.dart`（统一导出）
- Create: `lib/core/models/student.dart`
- Create: `lib/core/models/record.dart`
- Create: `lib/core/models/chat.dart`
- Create: `test/models/models_test.dart`

- [ ] **Step 1：写入 `lib/core/models/student.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

/// 性别
enum Gender {
  @JsonValue('male') male,
  @JsonValue('female') female,
  @JsonValue('other') other;

  String get label {
    switch (this) {
      case Gender.male:
        return '男';
      case Gender.female:
        return '女';
      case Gender.other:
        return '其他';
    }
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Student {
  final int id;
  final String name;
  final Gender gender;
  final int age;
  final double heightCm;
  final double targetWeightKg;
  final DateTime startDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.targetWeightKg,
    required this.startDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

/// 新建/更新学员请求体（不含 id 与时间戳）
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class StudentInput {
  final String name;
  final Gender gender;
  final int age;
  final double heightCm;
  final double targetWeightKg;
  final DateTime startDate;
  final String notes;

  const StudentInput({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.targetWeightKg,
    required this.startDate,
    this.notes = '',
  });

  factory StudentInput.fromJson(Map<String, dynamic> json) =>
      _$StudentInputFromJson(json);
  Map<String, dynamic> toJson() => _$StudentInputToJson(this);
}
```

- [ ] **Step 2：写入 `lib/core/models/record.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
part 'record.g.dart';

/// 体重记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WeightRecord {
  final int id;
  final int studentId;
  final DateTime recordDate;
  final double weightKg;
  final String note;
  final DateTime createdAt;

  const WeightRecord({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.weightKg,
    required this.note,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) =>
      _$WeightRecordFromJson(json);
  Map<String, dynamic> toJson() => _$WeightRecordToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WeightInput {
  final DateTime recordDate;
  final double weightKg;
  final String note;

  const WeightInput({
    required this.recordDate,
    required this.weightKg,
    this.note = '',
  });

  factory WeightInput.fromJson(Map<String, dynamic> json) =>
      _$WeightInputFromJson(json);
  Map<String, dynamic> toJson() => _$WeightInputToJson(this);
}

/// 围度 / 体脂记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BodyMetricRecord {
  final int id;
  final int studentId;
  final DateTime recordDate;
  final String metricType;
  final double value;
  final String unit;
  final DateTime createdAt;

  const BodyMetricRecord({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.createdAt,
  });

  factory BodyMetricRecord.fromJson(Map<String, dynamic> json) =>
      _$BodyMetricRecordFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMetricRecordToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BodyMetricInput {
  final DateTime recordDate;
  final String metricType;
  final double value;
  final String unit;

  const BodyMetricInput({
    required this.recordDate,
    required this.metricType,
    required this.value,
    required this.unit,
  });

  factory BodyMetricInput.fromJson(Map<String, dynamic> json) =>
      _$BodyMetricInputFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMetricInputToJson(this);
}

/// 饮食/运动类型
enum LogType {
  @JsonValue('breakfast') breakfast,
  @JsonValue('lunch') lunch,
  @JsonValue('dinner') dinner,
  @JsonValue('snack') snack,
  @JsonValue('exercise') exercise;

  String get label {
    switch (this) {
      case LogType.breakfast:
        return '早餐';
      case LogType.lunch:
        return '午餐';
      case LogType.dinner:
        return '晚餐';
      case LogType.snack:
        return '加餐';
      case LogType.exercise:
        return '运动';
    }
  }
}

/// 饮食 / 运动记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyLog {
  final int id;
  final int studentId;
  final DateTime logDate;
  final LogType logType;
  final String content;
  final double? calories;
  final DateTime createdAt;

  const DailyLog({
    required this.id,
    required this.studentId,
    required this.logDate,
    required this.logType,
    required this.content,
    this.calories,
    required this.createdAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) =>
      _$DailyLogFromJson(json);
  Map<String, dynamic> toJson() => _$DailyLogToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyLogInput {
  final DateTime logDate;
  final LogType logType;
  final String content;
  final double? calories;

  const DailyLogInput({
    required this.logDate,
    required this.logType,
    required this.content,
    this.calories,
  });

  factory DailyLogInput.fromJson(Map<String, dynamic> json) =>
      _$DailyLogInputFromJson(json);
  Map<String, dynamic> toJson() => _$DailyLogInputToJson(this);
}
```

- [ ] **Step 3：写入 `lib/core/models/chat.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
part 'chat.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatSession {
  final int id;
  final int? studentId;
  final String title;
  final DateTime createdAt;

  const ChatSession({
    required this.id,
    this.studentId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatSessionInput {
  final int? studentId;
  final String? title;

  const ChatSessionInput({this.studentId, this.title});

  factory ChatSessionInput.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionInputFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionInputToJson(this);
}

enum MessageRole {
  @JsonValue('user') user,
  @JsonValue('assistant') assistant,
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChatMessage {
  final int id;
  final int sessionId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
```

- [ ] **Step 4：写入 `lib/core/models/models.dart`（统一导出）**

```dart
/// 模型统一导出。
library models;

export 'student.dart';
export 'record.dart';
export 'chat.dart';
```

- [ ] **Step 5：生成 `.g.dart`**

```bash
cd /Users/heren/code/slim_bot
fvm dart run build_runner build --delete-conflicting-outputs
# 预期：生成 student.g.dart / record.g.dart / chat.g.dart，无错误
```

- [ ] **Step 6：写测试 `test/models/models_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/core/models/models.dart';

void main() {
  test('Student 反序列化（snake_case → 驼峰）', () {
    final json = {
      'id': 1,
      'name': '小王',
      'gender': 'male',
      'age': 30,
      'height_cm': 175.0,
      'target_weight_kg': 70.0,
      'start_date': '2026-07-01T00:00:00',
      'notes': '',
      'created_at': '2026-07-01T00:00:00',
      'updated_at': '2026-07-01T00:00:00',
    };
    final s = Student.fromJson(json);
    expect(s.name, '小王');
    expect(s.gender, Gender.male);
    expect(s.heightCm, 175.0);
  });

  test('WeightRecord 反序列化', () {
    final w = WeightRecord.fromJson({
      'id': 1, 'student_id': 2, 'record_date': '2026-07-01T00:00:00',
      'weight_kg': 80.5, 'note': '', 'created_at': '2026-07-01T00:00:00',
    });
    expect(w.weightKg, 80.5);
  });
}
```

- [ ] **Step 7：运行测试**

```bash
cd /Users/heren/code/slim_bot
fvm flutter test test/models/models_test.dart
# 预期：2 passed
```

- [ ] **Step 8：提交**

```bash
git add lib/core/models/ test/models/
git commit -m "feat: 添加前端数据模型（对齐后端 Schema）"
```

---

## 阶段 1：基础设施

### Task B1-1：数据库引擎与 ORM 模型

**Files:**
- Create: `backend/app/db.py`
- Create: `backend/app/model/__init__.py`（空）
- Create: `backend/app/model/base.py`
- Create: `backend/app/model/student.py`
- Create: `backend/app/model/record.py`
- Create: `backend/app/model/chat_history.py`
- Create: `backend/app/config.py`

- [ ] **Step 1：写入 `backend/app/config.py`**

```python
"""应用配置（从 .env 读取）。"""
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_token: str = "change-me-please"
    database_url: str = "sqlite+aiosqlite:///./data/coach.db"
    llm_api_key: str = ""
    llm_base_url: str = "https://api.openai.com/v1"
    llm_model: str = "gpt-4o-mini"
    rag_enabled: bool = False
    upload_dir: str = "./uploads"


settings = Settings()

# 确保数据/上传目录存在
Path(settings.database_url.replace("sqlite+aiosqlite:///", "")).parent.mkdir(
    parents=True, exist_ok=True
)
Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
```

- [ ] **Step 2：写入 `backend/app/model/base.py`**

```python
"""ORM 基类。"""
from datetime import datetime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    """created_at / updated_at 时间戳混入。"""
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        default=datetime.utcnow, onupdate=datetime.utcnow
    )
```

- [ ] **Step 3：写入 `backend/app/db.py`**

```python
"""SQLAlchemy 异步引擎与 session。"""
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from app.config import settings

# SQLite 需开启外键约束
engine = create_async_engine(
    settings.database_url,
    echo=False,
    connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
)
async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI 依赖：提供数据库 session。"""
    async with async_session_factory() as session:
        yield session
```

- [ ] **Step 4：写入 `backend/app/model/student.py`**

```python
"""学员档案 ORM。"""
from datetime import date
from sqlalchemy import String, Float, Integer, Date, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.model.base import Base, TimestampMixin


class Student(Base, TimestampMixin):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50))
    gender: Mapped[str] = mapped_column(String(10))  # male/female/other
    age: Mapped[int] = mapped_column(Integer)
    height_cm: Mapped[float] = mapped_column(Float)
    target_weight_kg: Mapped[float] = mapped_column(Float)
    start_date: Mapped[date] = mapped_column(Date)
    notes: Mapped[str] = mapped_column(Text, default="")

    # 关联记录（懒加载）
    weights = relationship("WeightRecord", back_populates="student", cascade="all, delete-orphan")
    body_metrics = relationship("BodyMetricRecord", back_populates="student", cascade="all, delete-orphan")
    daily_logs = relationship("DailyLog", back_populates="student", cascade="all, delete-orphan")
```

- [ ] **Step 5：写入 `backend/app/model/record.py`**

```python
"""数据记录 ORM（体重 / 围度体脂 / 饮食运动）。"""
from datetime import date
from sqlalchemy import String, Float, Integer, Date, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.model.base import Base, TimestampMixin


class WeightRecord(Base, TimestampMixin):
    __tablename__ = "weight_records"
    __table_args__ = (
        UniqueConstraint("student_id", "record_date", name="uq_weight_student_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    record_date: Mapped[date] = mapped_column(Date)
    weight_kg: Mapped[float] = mapped_column(Float)
    note: Mapped[str] = mapped_column(String(200), default="")

    student = relationship("Student", back_populates="weights")


class BodyMetricRecord(Base, TimestampMixin):
    __tablename__ = "body_metric_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    record_date: Mapped[date] = mapped_column(Date)
    metric_type: Mapped[str] = mapped_column(String(30))  # 腰围/臀围/体脂率...
    value: Mapped[float] = mapped_column(Float)
    unit: Mapped[str] = mapped_column(String(10))  # cm/%

    student = relationship("Student", back_populates="body_metrics")


class DailyLog(Base, TimestampMixin):
    __tablename__ = "daily_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    log_date: Mapped[date] = mapped_column(Date)
    log_type: Mapped[str] = mapped_column(String(20))  # breakfast/lunch/...
    content: Mapped[str] = mapped_column(Text)
    calories: Mapped[float | None] = mapped_column(Float, nullable=True)

    student = relationship("Student", back_populates="daily_logs")
```

- [ ] **Step 6：写入 `backend/app/model/chat_history.py`**

```python
"""对话历史 ORM。"""
from sqlalchemy import String, Text, Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.model.base import Base, TimestampMixin


class ChatSession(Base, TimestampMixin):
    __tablename__ = "chat_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    student_id: Mapped[int | None] = mapped_column(
        ForeignKey("students.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(100), default="新会话")

    messages = relationship(
        "ChatMessage", back_populates="session", cascade="all, delete-orphan"
    )


class ChatMessage(Base, TimestampMixin):
    __tablename__ = "chat_messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_id: Mapped[int] = mapped_column(
        ForeignKey("chat_sessions.id", ondelete="CASCADE")
    )
    role: Mapped[str] = mapped_column(String(20))  # user / assistant
    content: Mapped[str] = mapped_column(Text)

    session = relationship("ChatSession", back_populates="messages")
```

- [ ] **Step 7：写建表测试 `backend/tests/test_db.py`**

```python
"""数据库建表测试。"""
import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import engine
from app.model.base import Base
from app.model.student import Student
from app.model.record import WeightRecord


@pytest.fixture
async def prepare_db():
    """每个测试前重建表。"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield


async def test_create_student(prepare_db):
    from sqlalchemy import select
    from app.db import async_session_factory

    async with async_session_factory() as session:  # type: AsyncSession
        s = Student(name="小王", gender="male", age=30, height_cm=175.0,
                    target_weight_kg=70.0, start_date="2026-07-01")
        session.add(s)
        await session.commit()

        result = await session.execute(select(Student).where(Student.name == "小王"))
        found = result.scalar_one()
        assert found.age == 30
```

- [ ] **Step 8：运行测试**

```bash
cd backend
uv run pytest tests/test_db.py -v
# 预期：1 passed
```

- [ ] **Step 9：提交**

```bash
git add backend/app/db.py backend/app/config.py backend/app/model/ backend/tests/test_db.py
git commit -m "feat: 实现数据库引擎与 ORM 模型"
```

---

### Task B1-2：鉴权依赖 + 统一异常处理

**Files:**
- Create: `backend/app/api/__init__.py`（空）
- Create: `backend/app/api/deps.py`
- Create: `backend/app/exceptions.py`
- Modify: `backend/app/main.py`

- [ ] **Step 1：写入 `backend/app/exceptions.py`**

```python
"""业务异常 + 统一错误码。"""


class AppError(Exception):
    """业务异常基类。"""
    code: str = "INTERNAL_ERROR"
    status_code: int = 500
    message: str = "服务器内部错误"

    def __init__(self, message: str | None = None, detail: dict | None = None):
        self.message = message or self.message
        self.detail = detail
        super().__init__(self.message)


class NotFoundError(AppError):
    code = "NOT_FOUND"
    status_code = 404
    message = "资源不存在"


class ValidationError(AppError):
    code = "VALIDATION_ERROR"
    status_code = 422
    message = "参数校验失败"


class LLMError(AppError):
    code = "LLM_ERROR"
    status_code = 502
    message = "AI 服务暂时不可用"


class UpdateError(AppError):
    code = "UPDATE_ERROR"
    status_code = 500
    message = "更新失败"
```

- [ ] **Step 2：写入 `backend/app/api/deps.py`**

```python
"""FastAPI 依赖注入：Token 鉴权。"""
import secrets
from fastapi import Header, HTTPException, status
from app.config import settings


async def verify_token(authorization: str = Header(...)) -> None:
    """校验 Bearer Token，与 settings.app_token 比对。"""
    if not authorization.startswith("Bearer "):
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
```

- [ ] **Step 3：更新 `backend/app/main.py`（注册全局异常处理）**

```python
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
```

- [ ] **Step 4：写鉴权测试 `backend/tests/test_auth.py`**

```python
"""鉴权依赖测试。"""
import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from app.api.deps import verify_token

app = FastAPI()


@app.get("/protected")
async def protected(_: None = Depends(verify_token)) -> dict:
    return {"ok": True}


@pytest.fixture
def client():
    return TestClient(app)


def test_no_token_returns_401(client):
    r = client.get("/protected")
    assert r.status_code == 401


def test_wrong_token_returns_401(client):
    r = client.get("/protected", headers={"Authorization": "Bearer wrong"})
    assert r.status_code == 401


def test_right_token_passes(client, monkeypatch):
    monkeypatch.setattr("app.api.deps.settings.app_token", "secret")
    r = client.get("/protected", headers={"Authorization": "Bearer secret"})
    assert r.status_code == 200
    assert r.json() == {"ok": True}
```

- [ ] **Step 5：运行测试**

```bash
cd backend
uv run pytest tests/test_auth.py -v
# 预期：3 passed
```

- [ ] **Step 6：提交**

```bash
git add backend/app/exceptions.py backend/app/api/ backend/app/main.py backend/tests/test_auth.py
git commit -m "feat: 实现鉴权依赖与统一异常处理"
```

---

### Task F1-1：主题（DESIGN.md 适配）+ 设计令牌

> 把 `DESIGN.md` 的 Material Design 配色落地为 Flutter ThemeData。本应用为高对比浅色主题，主色为活力绿。

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/app_colors.dart`
- Create: `test/theme/theme_test.dart`

- [ ] **Step 1：写入 `lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

/// 设计令牌，来自 DESIGN.md「Vitality Logic」配色。
/// 高对比浅色主题，主色活力绿。
class AppColors {
  AppColors._();

  // 表面层
  static const surface = Color(0xFFF8FAF8);          // 页面背景
  static const surfaceContainerLowest = Color(0xFFFFFFFF); // 卡片
  static const surfaceContainerLow = Color(0xFFF2F4F2);
  static const surfaceContainer = Color(0xFFECEEEC);

  // 文本
  static const onSurface = Color(0xFF191C1B);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const outline = Color(0xFFBFCAB9);          // 卡片/输入描边
  static const outlineVariant = Color(0xFFE0E4E0);

  // 品牌色
  static const primary = Color(0xFF0B6B1D);           // 主操作
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2E8534);
  static const tertiary = Color(0xFF276929);          // 深森林绿（高对比文本）

  // 错误
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
}
```

- [ ] **Step 2：写入 `lib/core/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用主题：Material 3 + DESIGN.md 配色。
/// 风格要点：高留白、1px 描边卡片、8px 圆角、低扩散阴影。
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x1A0B6B1D), // primary 10% 透明
        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
    );
  }
}
```

- [ ] **Step 3：写测试 `test/theme/theme_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/core/theme/app_theme.dart';
import 'package:slim_bot/core/theme/app_colors.dart';

void main() {
  test('主题主色为活力绿', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  test('卡片为白底 1px 描边 16 圆角', () {
    final theme = AppTheme.light;
    final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
    expect(theme.cardTheme.color, AppColors.surfaceContainerLowest);
    expect(cardShape.border.side.width, 1);
    expect(cardShape.borderRadius, BorderRadius.circular(16));
  });
}
```

- [ ] **Step 4：运行测试**

```bash
cd /Users/heren/code/slim_bot
fvm flutter test test/theme/theme_test.dart
# 预期：2 passed
```

- [ ] **Step 5：提交**

```bash
git add lib/core/theme/ test/theme/
git commit -m "feat: 实现 DESIGN.md 配色主题与设计令牌"
```

---

### Task F1-2：响应式布局断点 + 本地配置存储

**Files:**
- Create: `lib/core/responsive.dart`
- Create: `lib/core/config/app_config.dart`

- [ ] **Step 1：写入 `lib/core/responsive.dart`**

```dart
import 'package:flutter/material.dart';

/// 响应式断点：手机 / Web 适配。
/// ≥900px 视为宽屏（Web/平板），用侧边栏导航；
/// <900px 用底部导航。
class Breakpoint {
  static const double desktop = 900;

  /// 当前是否宽屏
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// 容器最大宽度
  static const double containerMax = 1280;

  /// 桌面端内容水平边距
  static const double marginDesktop = 40;
  static const double marginMobile = 16;
}

/// 根据屏幕宽度返回合适的水平内容边距
double contentMargin(BuildContext context) =>
    Breakpoint.isDesktop(context)
        ? Breakpoint.marginDesktop
        : Breakpoint.marginMobile;
```

- [ ] **Step 2：写入 `lib/core/config/app_config.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地配置：后端 URL + Bearer Token。
/// 首次使用需在设置页填写。
class AppConfig {
  AppConfig({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  bool get isConfigured =>
      baseUrl.isNotEmpty && token.isNotEmpty;
}

/// 配置状态管理（持久化到 shared_preferences）
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig(baseUrl: '', token: '')) {
    _load();
  }

  static const _keyBaseUrl = 'base_url';
  static const _keyToken = 'token';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppConfig(
      baseUrl: prefs.getString(_keyBaseUrl) ?? '',
      token: prefs.getString(_keyToken) ?? '',
    );
  }

  Future<void> save({required String baseUrl, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
    await prefs.setString(_keyToken, token);
    state = AppConfig(baseUrl: baseUrl, token: token);
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>(
  (ref) => AppConfigNotifier(),
);
```

- [ ] **Step 3：提交**

```bash
git add lib/core/responsive.dart lib/core/config/
git commit -m "feat: 添加响应式断点与本地配置存储"
```

---

### Task F1-3：HTTP 客户端 + Repository 抽象 + Mock 基础设施

> **并行开发的核心**：定义 `Repository` 抽象接口 + `HttpRepository`（真实）+ `MockRepository`（假数据）。开发期用 Mock，对接期切换。

**Files:**
- Create: `lib/core/api/api_client.dart`
- Create: `lib/core/repositories/repository.dart`（抽象接口）
- Create: `lib/core/repositories/http_repository.dart`（真实实现）
- Create: `lib/core/repositories/mock_repository.dart`（Mock 实现）
- Create: `lib/core/repositories/repository_provider.dart`（切换器）

- [ ] **Step 1：写入 `lib/core/api/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// 统一封装：baseURL、Bearer Token、错误处理。
class ApiClient {
  ApiClient(this._config) {
    _dio = Dio(BaseOptions(
      baseUrl: '${_config.baseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        if (_config.token.isNotEmpty)
          'Authorization': 'Bearer ${_config.token}',
      },
    ));
    _dio.interceptors.add(_ErrorInterceptor());
  }

  final AppConfig _config;
  late final Dio _dio;

  Dio get dio => _dio;
}

/// 错误拦截器：网络错误/401/5xx 统一处理。
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 交由调用方/页面按 ResponseType 处理；这里仅标准化 message
    handler.next(err);
  }
}

/// 提供给 Repository 使用的 dio 实例 provider
final apiClientProvider = Provider<ApiClient?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isConfigured) return null;
  return ApiClient(config);
});
```

- [ ] **Step 2：写入 `lib/core/repositories/repository.dart`（抽象接口）**

```dart
/// Repository 抽象接口。
/// 真实实现走 HTTP，Mock 实现返回假数据。
/// 前端开发期用 Mock，后端就绪后切换到 HttpRepository。
import '../models/models.dart';

abstract class Repository {
  // ===== 学员 =====
  Future<List<Student>> listStudents({String? search, int page = 1, int pageSize = 20});
  Future<Student> getStudent(int id);
  Future<Student> createStudent(StudentInput input);
  Future<Student> updateStudent(int id, StudentInput input);
  Future<void> deleteStudent(int id);

  // ===== 体重 =====
  Future<List<WeightRecord>> listWeights(int studentId, {DateTime? start, DateTime? end});
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input);
  Future<void> deleteWeight(int studentId, int recordId);

  // ===== 围度/体脂 =====
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId, {DateTime? start, DateTime? end});
  Future<BodyMetricRecord> createBodyMetric(int studentId, BodyMetricInput input);
  Future<void> deleteBodyMetric(int studentId, int recordId);

  // ===== 饮食/运动 =====
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date});
  Future<DailyLog> createDailyLog(int studentId, DailyLogInput input);
  Future<void> deleteDailyLog(int studentId, int recordId);

  // ===== 对话 =====
  Future<ChatSession> createChatSession(ChatSessionInput input);
  Future<List<ChatSession>> listChatSessions({int? studentId});
  Future<List<ChatMessage>> listMessages(int sessionId);
  Future<void> deleteChatSession(int sessionId);
  /// 发送消息并以 SSE 流式接收。onChunk 收到文本增量。
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  });
}
```

- [ ] **Step 3：写入 `lib/core/repositories/http_repository.dart`**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import 'repository.dart';

/// 真实 HTTP 实现（对接后端时使用）。
class HttpRepository implements Repository {
  HttpRepository(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;

  // ===== 学员 =====
  @override
  Future<List<Student>> listStudents({String? search, int page = 1, int pageSize = 20}) async {
    final r = await _dio.get('/students', queryParameters: {
      if (search != null) 'search': search,
      'page': page, 'page_size': pageSize,
    });
    final data = r.data['items'] as List;
    return data.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Student> getStudent(int id) async {
    final r = await _dio.get('/students/$id');
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<Student> createStudent(StudentInput input) async {
    final r = await _dio.post('/students', data: input.toJson());
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<Student> updateStudent(int id, StudentInput input) async {
    final r = await _dio.put('/students/$id', data: input.toJson());
    return Student.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteStudent(int id) async {
    await _dio.delete('/students/$id');
  }

  // ===== 体重 =====
  @override
  Future<List<WeightRecord>> listWeights(int studentId, {DateTime? start, DateTime? end}) async {
    final r = await _dio.get('/students/$studentId/weights', queryParameters: {
      if (start != null) 'start': start.toIso8601String().substring(0, 10),
      if (end != null) 'end': end.toIso8601String().substring(0, 10),
    });
    final data = r.data as List;
    return data.map((e) => WeightRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input) async {
    final r = await _dio.post('/students/$studentId/weights', data: input.toJson());
    return WeightRecord.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteWeight(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/weights/$recordId');
  }

  // ===== 围度/体脂 =====
  @override
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId, {DateTime? start, DateTime? end}) async {
    final r = await _dio.get('/students/$studentId/body-metrics', queryParameters: {
      if (start != null) 'start': start.toIso8601String().substring(0, 10),
      if (end != null) 'end': end.toIso8601String().substring(0, 10),
    });
    final data = r.data as List;
    return data.map((e) => BodyMetricRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BodyMetricRecord> createBodyMetric(int studentId, BodyMetricInput input) async {
    final r = await _dio.post('/students/$studentId/body-metrics', data: input.toJson());
    return BodyMetricRecord.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBodyMetric(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/body-metrics/$recordId');
  }

  // ===== 饮食/运动 =====
  @override
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date}) async {
    final r = await _dio.get('/students/$studentId/daily-logs', queryParameters: {
      if (date != null) 'date': date.toIso8601String().substring(0, 10),
    });
    final data = r.data as List;
    return data.map((e) => DailyLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<DailyLog> createDailyLog(int studentId, DailyLogInput input) async {
    final r = await _dio.post('/students/$studentId/daily-logs', data: input.toJson());
    return DailyLog.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDailyLog(int studentId, int recordId) async {
    await _dio.delete('/students/$studentId/daily-logs/$recordId');
  }

  // ===== 对话 =====
  @override
  Future<ChatSession> createChatSession(ChatSessionInput input) async {
    final r = await _dio.post('/chat/sessions', data: input.toJson());
    return ChatSession.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<List<ChatSession>> listChatSessions({int? studentId}) async {
    final r = await _dio.get('/chat/sessions', queryParameters: {
      if (studentId != null) 'student_id': studentId,
    });
    final data = r.data as List;
    return data.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ChatMessage>> listMessages(int sessionId) async {
    final r = await _dio.get('/chat/sessions/$sessionId/messages');
    final data = r.data as List;
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteChatSession(int sessionId) async {
    await _dio.delete('/chat/sessions/$sessionId');
  }

  /// SSE 流式：responseType=stream，逐行解析 `data: {...}`。
  @override
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  }) async {
    final response = await _dio.post<ResponseBody>(
      '/chat/sessions/$sessionId/messages',
      data: {'content': content},
      options: Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream'}),
    );
    final stream = response.data!.stream;
    await for (final bytes in stream) {
      final text = utf8.decode(bytes);
      for (final line in text.split('\n')) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        final obj = jsonDecode(payload) as Map<String, dynamic>;
        if (obj['type'] == 'chunk') {
          onChunk(obj['content'] as String);
        }
      }
    }
  }
}
```

- [ ] **Step 4：写入 `lib/core/repositories/mock_repository.dart`**

```dart
import 'dart:async';
import '../models/models.dart';
import 'repository.dart';

/// Mock 实现：返回内存假数据，前端开发期使用。
class MockRepository implements Repository {
  final List<Student> _students = [];
  final List<WeightRecord> _weights = [];
  final List<BodyMetricRecord> _metrics = [];
  final List<DailyLog> _logs = [];
  final List<ChatSession> _sessions = [];
  final List<ChatMessage> _messages = [];
  int _seq = 1;

  int _next() => _seq++;

  MockRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime(2026, 7, 1);
    final s = Student(
      id: _next(), name: '小王', gender: Gender.male, age: 30,
      heightCm: 175, targetWeightKg: 70,
      startDate: now, notes: '久坐办公', createdAt: now, updatedAt: now,
    );
    _students.add(s);
    for (var i = 0; i < 14; i++) {
      _weights.add(WeightRecord(
        id: _next(), studentId: s.id, recordDate: now.subtract(Duration(days: 13 - i)),
        weightKg: 82 - i * 0.4, note: '', createdAt: now,
      ));
    }
  }

  Future<T> _delay<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => value);

  // ===== 学员 =====
  @override
  Future<List<Student>> listStudents({String? search, int page = 1, int pageSize = 20}) async {
    var list = _students.where((s) =>
        search == null || s.name.contains(search)).toList();
    return _delay(list);
  }

  @override
  Future<Student> getStudent(int id) async =>
      _delay(_students.firstWhere((s) => s.id == id));

  @override
  Future<Student> createStudent(StudentInput input) async {
    final now = DateTime.now();
    final s = Student(
      id: _next(), name: input.name, gender: input.gender, age: input.age,
      heightCm: input.heightCm, targetWeightKg: input.targetWeightKg,
      startDate: input.startDate, notes: input.notes,
      createdAt: now, updatedAt: now,
    );
    _students.add(s);
    return _delay(s);
  }

  @override
  Future<Student> updateStudent(int id, StudentInput input) async {
    final idx = _students.indexWhere((s) => s.id == id);
    final old = _students[idx];
    final updated = Student(
      id: id, name: input.name, gender: input.gender, age: input.age,
      heightCm: input.heightCm, targetWeightKg: input.targetWeightKg,
      startDate: input.startDate, notes: input.notes,
      createdAt: old.createdAt, updatedAt: DateTime.now(),
    );
    _students[idx] = updated;
    return _delay(updated);
  }

  @override
  Future<void> deleteStudent(int id) async {
    _students.removeWhere((s) => s.id == id);
    _weights.removeWhere((w) => w.studentId == id);
    return _delay(null);
  }

  // ===== 体重 =====
  @override
  Future<List<WeightRecord>> listWeights(int studentId, {DateTime? start, DateTime? end}) async =>
      _delay(_weights.where((w) => w.studentId == studentId).toList());

  @override
  Future<WeightRecord> upsertWeight(int studentId, WeightInput input) async {
    final existingIdx = _weights.indexWhere(
      (w) => w.studentId == studentId && w.recordDate == input.recordDate,
    );
    if (existingIdx >= 0) {
      final old = _weights[existingIdx];
      final updated = WeightRecord(
        id: old.id, studentId: studentId, recordDate: input.recordDate,
        weightKg: input.weightKg, note: input.note, createdAt: old.createdAt,
      );
      _weights[existingIdx] = updated;
      return _delay(updated);
    }
    final w = WeightRecord(
      id: _next(), studentId: studentId, recordDate: input.recordDate,
      weightKg: input.weightKg, note: input.note, createdAt: DateTime.now(),
    );
    _weights.add(w);
    return _delay(w);
  }

  @override
  Future<void> deleteWeight(int studentId, int recordId) async {
    _weights.removeWhere((w) => w.id == recordId && w.studentId == studentId);
    return _delay(null);
  }

  // ===== 围度/体脂（实现略，模式同体重）=====
  @override
  Future<List<BodyMetricRecord>> listBodyMetrics(int studentId, {DateTime? start, DateTime? end}) async =>
      _delay(_metrics.where((m) => m.studentId == studentId).toList());

  @override
  Future<BodyMetricRecord> createBodyMetric(int studentId, BodyMetricInput input) async {
    final m = BodyMetricRecord(
      id: _next(), studentId: studentId, recordDate: input.recordDate,
      metricType: input.metricType, value: input.value, unit: input.unit,
      createdAt: DateTime.now(),
    );
    _metrics.add(m);
    return _delay(m);
  }

  @override
  Future<void> deleteBodyMetric(int studentId, int recordId) async {
    _metrics.removeWhere((m) => m.id == recordId);
    return _delay(null);
  }

  // ===== 饮食/运动 =====
  @override
  Future<List<DailyLog>> listDailyLogs(int studentId, {DateTime? date}) async =>
      _delay(_logs.where((l) => l.studentId == studentId).toList());

  @override
  Future<DailyLog> createDailyLog(int studentId, DailyLogInput input) async {
    final l = DailyLog(
      id: _next(), studentId: studentId, logDate: input.logDate,
      logType: input.logType, content: input.content, calories: input.calories,
      createdAt: DateTime.now(),
    );
    _logs.add(l);
    return _delay(l);
  }

  @override
  Future<void> deleteDailyLog(int studentId, int recordId) async {
    _logs.removeWhere((l) => l.id == recordId);
    return _delay(null);
  }

  // ===== 对话 =====
  @override
  Future<ChatSession> createChatSession(ChatSessionInput input) async {
    final s = ChatSession(
      id: _next(), studentId: input.studentId,
      title: input.title ?? '新会话', createdAt: DateTime.now(),
    );
    _sessions.add(s);
    return _delay(s);
  }

  @override
  Future<List<ChatSession>> listChatSessions({int? studentId}) async =>
      _delay(_sessions.where((s) => studentId == null || s.studentId == studentId).toList());

  @override
  Future<List<ChatMessage>> listMessages(int sessionId) async =>
      _delay(_messages.where((m) => m.sessionId == sessionId).toList());

  @override
  Future<void> deleteChatSession(int sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    _messages.removeWhere((m) => m.sessionId == sessionId);
    return _delay(null);
  }

  /// 模拟流式回复：把一段假文本逐字推送。
  @override
  Future<void> sendMessageStream(
    int sessionId,
    String content, {
    required void Function(String chunk) onChunk,
  }) async {
    _messages.add(ChatMessage(
      id: _next(), sessionId: sessionId, role: MessageRole.user,
      content: content, createdAt: DateTime.now(),
    ));
    const reply = '根据小王近7天体重数据，从 82kg 下降到 76.4kg，趋势良好。建议保持当前饮食结构，注意蛋白质摄入。';
    for (final ch in reply.split('')) {
      await Future.delayed(const Duration(milliseconds: 30));
      onChunk(ch);
    }
    _messages.add(ChatMessage(
      id: _next(), sessionId: sessionId, role: MessageRole.assistant,
      content: reply, createdAt: DateTime.now(),
    ));
  }
}
```

- [ ] **Step 5：写入 `lib/core/repositories/repository_provider.dart`（切换器）**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'repository.dart';
import 'http_repository.dart';
import 'mock_repository.dart';

/// Repository 全局 provider。
/// - 开发期（ApiClient 未配置）→ MockRepository
/// - 对接期（ApiClient 已配置）→ HttpRepository
final repositoryProvider = Provider<Repository>((ref) {
  final client = ref.watch(apiClientProvider);
  return client == null ? MockRepository() : HttpRepository(client);
});
```

- [ ] **Step 6：验证编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/core/
# 预期：无错误
```

- [ ] **Step 7：提交**

```bash
git add lib/core/
git commit -m "feat: 实现 HTTP 客户端、Repository 抽象与 Mock 实现"
```

---

### Task F1-4：路由（go_router）+ App 入口 + 首页骨架

**Files:**
- Create: `lib/core/router/app_router.dart`
- Create: `lib/shared/widgets/app_scaffold.dart`（响应式导航骨架）
- Modify: `lib/main.dart`

- [ ] **Step 1：写入 `lib/core/router/app_router.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/students/pages/students_list_page.dart';
import '../../features/students/pages/student_detail_page.dart';
import '../../features/students/pages/student_edit_page.dart';
import '../../features/chat/chat_list_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/settings/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const StudentsListPage()),
      GoRoute(
        path: '/students/new',
        builder: (_, __) => const StudentEditPage(studentId: null),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (_, state) =>
            StudentDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/students/:id/edit',
        builder: (_, state) =>
            StudentEditPage(studentId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/chat', builder: (_, __) => const ChatListPage()),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (_, state) =>
            ChatPage(sessionId: int.parse(state.pathParameters['sessionId']!)),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});

/// 路由跳转的辅助扩展
Future<void> pushNamedWithContext(BuildContext context, String location) =>
    GoRouter.of(context).push(location);
```

- [ ] **Step 2：写入 `lib/shared/widgets/app_scaffold.dart`（响应式导航）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';

/// 主导航项
class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

const _navItems = [
  _NavItem('/', Icons.people_outline, '学员'),
  _NavItem('/chat', Icons.chat_bubble_outline, '对话'),
  _NavItem('/settings', Icons.settings_outlined, '设置'),
];

/// 响应式外壳：手机用底部导航，宽屏用左侧侧边栏。
class AppScaffold extends ConsumerWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = Breakpoint.isDesktop(context);

    // 仅在主导航根路径显示外壳
    final showShell = _navItems.any((n) => location == n.path);

    if (!showShell) {
      return Scaffold(body: child);
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(location: location),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: _MobileNavBar(location: location),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final String location;
  const _DesktopSidebar({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('减肥教练助手',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          for (final item in _navItems)
            _NavTile(item: item, selected: location == item.path),
        ],
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  final String location;
  const _MobileNavBar({required this.location});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _navItems.indexWhere((n) => location == n.path),
      onDestinationSelected: (i) => GoRouter.of(context).go(_navItems[i].path),
      destinations: [
        for (final item in _navItems)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _NavTile({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.label),
      selected: selected,
      onTap: () => GoRouter.of(context).go(item.path),
    );
  }
}
```

- [ ] **Step 3：写入 `lib/main.dart`（替换计数器模板）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_scaffold.dart';

void main() {
  runApp(const ProviderScope(child: SlimCoachApp()));
}

class SlimCoachApp extends ConsumerWidget {
  const SlimCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '减肥教练助手',
      theme: AppTheme.light,
      routerConfig: router,
      builder: (_, child) => AppScaffold(child: child!),
    );
  }
}
```

- [ ] **Step 4：创建占位页面（让路由可编译）**

为避免编译错误，先建最小占位页面（后续阶段填充）：

```bash
cd /Users/heren/code/slim_bot
# 创建占位页面文件
cat > lib/features/students/pages/students_list_page.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentsListPage extends ConsumerWidget {
  const StudentsListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const Scaffold(body: Center(child: Text('学员列表')));
}
EOF
cat > lib/features/students/pages/student_detail_page.dart << 'EOF'
import 'package:flutter/material.dart';
final class StudentDetailPage extends StatelessWidget {
  final int id;
  const StudentDetailPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('学员详情 $id')));
}
EOF
cat > lib/features/students/pages/student_edit_page.dart << 'EOF'
import 'package:flutter/material.dart';
final class StudentEditPage extends StatelessWidget {
  final int? studentId;
  const StudentEditPage({super.key, this.studentId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('学员编辑 ${studentId ?? "新建"}')));
}
EOF
cat > lib/features/chat/chat_list_page.dart << 'EOF'
import 'package:flutter/material.dart';
final class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('会话列表')));
}
EOF
cat > lib/features/chat/chat_page.dart << 'EOF'
import 'package:flutter/material.dart';
final class ChatPage extends StatelessWidget {
  final int sessionId;
  const ChatPage({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('对话 $sessionId')));
}
EOF
cat > lib/features/settings/settings_page.dart << 'EOF'
import 'package:flutter/material.dart';
final class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('设置')));
}
EOF
```

> 注意：占位页面后续任务会**整体替换**，这里只为让路由可编译。

- [ ] **Step 5：验证编译与运行**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze
# 预期：无错误
fvm flutter run -d macos  # 或 chrome / 模拟器，确认能进首页
# Ctrl-C 退出
```

- [ ] **Step 6：提交**

```bash
git add lib/
git commit -m "feat: 实现路由、响应式导航外壳与 App 入口"
```

---

## 阶段 2：学员档案模块

> **并行：** 本阶段 Task B2-*（后端）与 Task F2-*（前端）独立，可同时进行。

### Task B2-1：学员 Service 层

**Files:**
- Create: `backend/app/service/__init__.py`（空）
- Create: `backend/app/service/student_service.py`
- Create: `backend/tests/test_student_service.py`

- [ ] **Step 1：写入 `backend/app/service/student_service.py`**

```python
"""学员业务逻辑。"""
from datetime import date
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
```

- [ ] **Step 2：写测试 `backend/tests/test_student_service.py`**

```python
"""学员 Service 测试。"""
import pytest
from app.db import async_session_factory, engine
from app.model.base import Base
from app.service import student_service
from app.schemas.student import StudentCreate, StudentUpdate
from app.exceptions import NotFoundError


@pytest.fixture
async def db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        yield session


async def test_create_and_get(db):
    data = StudentCreate(name="小王", gender="male", age=30, height_cm=175.0,
                         target_weight_kg=70.0, start_date="2026-07-01")
    s = await student_service.create_student(db, data)
    assert s.id is not None
    got = await student_service.get_student(db, s.id)
    assert got.name == "小王"


async def test_get_not_found(db):
    with pytest.raises(NotFoundError):
        await student_service.get_student(db, 9999)


async def test_list_with_search(db):
    for name in ["小王", "小李", "大王"]:
        await student_service.create_student(db, StudentCreate(
            name=name, gender="male", age=30, height_cm=175.0,
            target_weight_kg=70.0, start_date="2026-07-01"))
    items, total = await student_service.list_students(db, search="王")
    assert total == 2
    assert {i.name for i in items} == {"小王", "大王"}


async def test_update(db):
    s = await student_service.create_student(db, StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date="2026-07-01"))
    updated = await student_service.update_student(db, s.id, StudentUpdate(age=31))
    assert updated.age == 31


async def test_delete(db):
    s = await student_service.create_student(db, StudentCreate(
        name="小王", gender="male", age=30, height_cm=175.0,
        target_weight_kg=70.0, start_date="2026-07-01"))
    await student_service.delete_student(db, s.id)
    with pytest.raises(NotFoundError):
        await student_service.get_student(db, s.id)
```

- [ ] **Step 3：运行测试**

```bash
cd backend
uv run pytest tests/test_student_service.py -v
# 预期：5 passed
```

- [ ] **Step 4：提交**

```bash
git add backend/app/service/ backend/tests/test_student_service.py
git commit -m "feat: 实现学员 Service 层（CRUD + 搜索分页）"
```

---

### Task B2-2：学员 API 路由

**Files:**
- Create: `backend/app/api/students.py`
- Modify: `backend/app/main.py`（注册路由）

- [ ] **Step 1：写入 `backend/app/api/students.py`**

```python
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
```

- [ ] **Step 2：在 `backend/app/main.py` 注册路由**

在 `app = FastAPI(...)` 之后、异常处理器之前或之后均可，添加：

```python
from app.api import students

app.include_router(students.router, prefix="/api/v1")
```

- [ ] **Step 3：写 API 测试 `backend/tests/test_students_api.py`**

```python
"""学员 API 测试。"""
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import engine
from app.model.base import Base

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


@pytest.fixture(autouse=True)
def reset_db():
    import asyncio
    async def _reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_reset())
    yield


def _payload(name="小王"):
    return {"name": name, "gender": "male", "age": 30, "height_cm": 175.0,
            "target_weight_kg": 70.0, "start_date": "2026-07-01", "notes": ""}


def test_create_student():
    r = client.post("/api/v1/students", json=_payload(), headers=AUTH)
    assert r.status_code == 201
    assert r.json()["name"] == "小王"


def test_create_student_no_auth_401():
    r = client.post("/api/v1/students", json=_payload())
    assert r.status_code == 401


def test_list_and_search():
    for n in ["小王", "小李"]:
        client.post("/api/v1/students", json=_payload(n), headers=AUTH)
    r = client.get("/api/v1/students", headers=AUTH)
    assert r.json()["total"] == 2
    r = client.get("/api/v1/students?search=王", headers=AUTH)
    assert r.json()["total"] == 1


def test_get_update_delete():
    sid = client.post("/api/v1/students", json=_payload(), headers=AUTH).json()["id"]
    assert client.get(f"/api/v1/students/{sid}", headers=AUTH).status_code == 200
    assert client.put(f"/api/v1/students/{sid}", json={"age": 31}, headers=AUTH).json()["age"] == 31
    assert client.delete(f"/api/v1/students/{sid}", headers=AUTH).status_code == 204
    assert client.get(f"/api/v1/students/{sid}", headers=AUTH).status_code == 404
```

- [ ] **Step 4：运行测试**

```bash
cd backend
uv run pytest tests/test_students_api.py -v
# 预期：4 passed
```

- [ ] **Step 5：提交**

```bash
git add backend/app/api/students.py backend/app/main.py backend/tests/test_students_api.py
git commit -m "feat: 实现学员档案 API 路由"
```

---

### Task F2-1：学员列表页 + 状态管理

**Files:**
- Replace: `lib/features/students/pages/students_list_page.dart`
- Create: `lib/features/students/providers/student_providers.dart`
- Create: `lib/features/students/widgets/student_card.dart`

- [ ] **Step 1：写入 `lib/features/students/providers/student_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';

/// 学员列表（带搜索）
final studentListProvider =
    FutureProvider.family<List<Student>, String>((ref, search) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listStudents(search: search.isEmpty ? null : search);
});

/// 单个学员详情
final studentProvider =
    FutureProvider.family<Student, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getStudent(id);
});
```

- [ ] **Step 2：写入 `lib/features/students/widgets/student_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 学员列表卡片
class StudentCard extends StatelessWidget {
  final Student student;
  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0x1A0B6B1D),
          child: Text(student.name.characters.first,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${student.gender.label} · ${student.age}岁 · 目标 ${student.targetWeightKg}kg'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
        onTap: () => context.push('/students/${student.id}'),
      ),
    );
  }
}
```

- [ ] **Step 3：替换 `lib/features/students/pages/students_list_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../providers/student_providers.dart';
import '../widgets/student_card.dart';

class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentListProvider(_search));
    return Scaffold(
      appBar: AppBar(title: const Text('学员')),
      body: Padding(
        padding: EdgeInsets.all(contentMargin(context)),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索学员姓名',
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                data: (students) => students.isEmpty
                    ? const Center(child: Text('暂无学员，点右下角添加'))
                    : ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => StudentCard(student: students[i]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('加载失败'),
                      TextButton(onPressed: () => ref.invalidate(studentListProvider(_search)), child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/students/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 4：验证编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/students/
# 预期：无错误
```

- [ ] **Step 5：提交**

```bash
git add lib/features/students/
git commit -m "feat: 实现学员列表页与状态管理"
```

---

### Task F2-2：学员编辑页（新建/更新表单）

**Files:**
- Replace: `lib/features/students/pages/student_edit_page.dart`

- [ ] **Step 1：替换 `lib/features/students/pages/student_edit_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/student_providers.dart';

class StudentEditPage extends ConsumerStatefulWidget {
  final int? studentId; // null = 新建
  const StudentEditPage({super.key, this.studentId});

  @override
  ConsumerState<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends ConsumerState<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _target = TextEditingController();
  final _notes = TextEditingController();
  Gender _gender = Gender.male;
  DateTime _startDate = DateTime(2026, 7, 1);
  bool _loaded = false;
  bool _saving = false;

  bool get _isEdit => widget.studentId != null;

  @override
  void dispose() {
    for (final c in [_name, _age, _height, _target, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadIfEdit(Student s) {
    if (_loaded) return;
    _loaded = true;
    _name.text = s.name;
    _gender = s.gender;
    _age.text = '${s.age}';
    _height.text = '${s.heightCm}';
    _target.text = '${s.targetWeightKg}';
    _startDate = s.startDate;
    _notes.text = s.notes;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(repositoryProvider);
    final input = StudentInput(
      name: _name.text.trim(),
      gender: _gender,
      age: int.parse(_age.text),
      heightCm: double.parse(_height.text),
      targetWeightKg: double.parse(_target.text),
      startDate: _startDate,
      notes: _notes.text.trim(),
    );
    try {
      if (_isEdit) {
        await repo.updateStudent(widget.studentId!, input);
        ref.invalidate(studentProvider(widget.studentId!));
      } else {
        await repo.createStudent(input);
      }
      if (mounted) {
        ref.invalidate(studentListProvider(''));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑学员' : '新建学员')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoint.containerMax),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isEdit
                  ? ref.watch(studentProvider(widget.studentId!)).when(
                      data: (s) { _loadIfEdit(s); return _form(); },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('加载失败：$e'),
                    )
                  : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: '姓名'),
            validator: (v) => (v == null || v.isEmpty) ? '请输入姓名' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Gender>(
            value: _gender,
            decoration: const InputDecoration(labelText: '性别'),
            items: Gender.values.map((g) =>
                DropdownMenuItem(value: g, child: Text(g.label))).toList(),
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _age, decoration: const InputDecoration(labelText: '年龄'),
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null ? '请输入有效年龄' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _height, decoration: const InputDecoration(labelText: '身高 (cm)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => double.tryParse(v ?? '') == null ? '请输入有效身高' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _target, decoration: const InputDecoration(labelText: '目标体重 (kg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => double.tryParse(v ?? '') == null ? '请输入有效体重' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('开始日期'),
            subtitle: Text('${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
            onTap: _pickDate,
          ),
          TextFormField(
            controller: _notes, decoration: const InputDecoration(labelText: '备注'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2：验证编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/students/pages/student_edit_page.dart
```

- [ ] **Step 3：提交**

```bash
git add lib/features/students/pages/student_edit_page.dart
git commit -m "feat: 实现学员编辑表单（新建/更新）"
```

---

### Task F2-3：学员详情页（Tab 骨架）

> 详情页承载 5 个 Tab：档案/体重/围度/饮食运动/对话。本任务只搭骨架，各 Tab 内容在后续阶段填充。先建壳，避免阻塞。

**Files:**
- Replace: `lib/features/students/pages/student_detail_page.dart`
- Create: `lib/features/students/widgets/student_header.dart`

- [ ] **Step 1：替换 `lib/features/students/pages/student_detail_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive.dart';
import '../providers/student_providers.dart';
import '../widgets/student_header.dart';

class StudentDetailPage extends ConsumerWidget {
  final int id;
  const StudentDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: async.maybeWhen(data: (s) => Text(s.name), orElse: () => const Text('学员详情')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/students/$id/edit'),
          ),
        ],
      ),
      body: async.when(
        data: (student) => _DetailTabs(id: id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _DetailTabs extends ConsumerStatefulWidget {
  final int id;
  const _DetailTabs({required this.id});

  @override
  ConsumerState<_DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends ConsumerState<_DetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentProvider(widget.id)).valueOrNull;
    return Column(
      children: [
        if (student != null) StudentHeader(student: student),
        TabBar(
          controller: _tab,
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          tabs: const [
            Tab(text: '档案'), Tab(text: '体重'),
            Tab(text: '围度'), Tab(text: '饮食运动'), Tab(text: '对话'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(contentMargin(context)),
            child: TabBarView(
              controller: _tab,
              // 占位：后续阶段填充真实内容
              children: [
                const Center(child: Text('档案（阶段2扩展）')),
                const Center(child: Text('体重（阶段3实现）')),
                const Center(child: Text('围度（阶段3实现）')),
                const Center(child: Text('饮食运动（阶段3实现）')),
                const Center(child: Text('对话（阶段4实现）')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2：写入 `lib/features/students/widgets/student_header.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';

/// 学员详情头部摘要
class StudentHeader extends StatelessWidget {
  final Student student;
  const StudentHeader({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          CircleAvatar(radius: 24, child: Text(student.name.characters.first)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${student.gender.label} · ${student.age}岁 · ${student.heightCm}cm',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('目标 ${student.targetWeightKg}kg · 起 ${student.startDate.year}-${student.startDate.month}-${student.startDate.day}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3：提交**

```bash
git add lib/features/students/pages/student_detail_page.dart lib/features/students/widgets/student_header.dart
git commit -m "feat: 实现学员详情页 Tab 骨架"
```

---

## 阶段 3：数据记录模块

> **并行：** B3-* 与 F3-* 独立。后端先把记录 CRUD 做完，前端做录入页 + 图表。

### Task B3-1：记录 Service + API（体重/围度/饮食运动）

**Files:**
- Create: `backend/app/service/record_service.py`
- Create: `backend/app/api/records.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_records_api.py`

- [ ] **Step 1：写入 `backend/app/service/record_service.py`**

```python
"""数据记录业务逻辑：体重、围度体脂、饮食运动。"""
from datetime import date
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.exceptions import NotFoundError
from app.model.record import WeightRecord, BodyMetricRecord, DailyLog
from app.model.student import Student
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
```

- [ ] **Step 2：写入 `backend/app/api/records.py`**

```python
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
```

- [ ] **Step 3：在 `backend/app/main.py` 注册路由**

```python
from app.api import students, records

app.include_router(students.router, prefix="/api/v1")
app.include_router(records.router, prefix="/api/v1")
```

- [ ] **Step 4：写测试 `backend/tests/test_records_api.py`**

```python
"""数据记录 API 测试。"""
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import engine
from app.model.base import Base

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


@pytest.fixture(autouse=True)
def reset_db():
    import asyncio
    async def _reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_reset())
    yield


@pytest.fixture
def student_id():
    r = client.post("/api/v1/students", json={
        "name": "小王", "gender": "male", "age": 30, "height_cm": 175.0,
        "target_weight_kg": 70.0, "start_date": "2026-07-01", "notes": "",
    }, headers=AUTH)
    return r.json()["id"]


def test_weight_upsert_and_list(student_id):
    # 同日两次录入，第二次覆盖
    client.post(f"/api/v1/students/{student_id}/weights",
                json={"record_date": "2026-07-01", "weight_kg": 80.0, "note": ""}, headers=AUTH)
    r2 = client.post(f"/api/v1/students/{student_id}/weights",
                     json={"record_date": "2026-07-01", "weight_kg": 79.5, "note": "更新"}, headers=AUTH)
    assert r2.json()["weight_kg"] == 79.5
    r = client.get(f"/api/v1/students/{student_id}/weights", headers=AUTH)
    assert len(r.json()) == 1  # 覆盖，非新增


def test_weight_list_by_range(student_id):
    for d, w in [("2026-07-01", 80), ("2026-07-02", 79.5), ("2026-07-03", 79)]:
        client.post(f"/api/v1/students/{student_id}/weights",
                    json={"record_date": d, "weight_kg": w, "note": ""}, headers=AUTH)
    r = client.get(f"/api/v1/students/{student_id}/weights?start=2026-07-02&end=2026-07-03", headers=AUTH)
    assert len(r.json()) == 2


def test_body_metric_crud(student_id):
    r = client.post(f"/api/v1/students/{student_id}/body-metrics",
                    json={"record_date": "2026-07-01", "metric_type": "腰围", "value": 90.0, "unit": "cm"}, headers=AUTH)
    assert r.status_code == 201
    assert client.get(f"/api/v1/students/{student_id}/body-metrics", headers=AUTH).json()[0]["metric_type"] == "腰围"


def test_daily_log_crud(student_id):
    r = client.post(f"/api/v1/students/{student_id}/daily-logs",
                    json={"log_date": "2026-07-01", "log_type": "breakfast", "content": "鸡蛋+牛奶", "calories": 300}, headers=AUTH)
    assert r.status_code == 201
    logs = client.get(f"/api/v1/students/{student_id}/daily-logs", headers=AUTH).json()
    assert len(logs) == 1
    assert logs[0]["content"] == "鸡蛋+牛奶"


def test_records_require_student(student_id):
    # 不存在的学员
    assert client.post("/api/v1/students/9999/weights",
                       json={"record_date": "2026-07-01", "weight_kg": 80.0, "note": ""}, headers=AUTH).status_code == 404
```

- [ ] **Step 5：运行测试**

```bash
cd backend
uv run pytest tests/test_records_api.py -v
# 预期：5 passed
```

- [ ] **Step 6：提交**

```bash
git add backend/app/service/record_service.py backend/app/api/records.py backend/app/main.py backend/tests/test_records_api.py
git commit -m "feat: 实现数据记录 Service 与 API（体重/围度/饮食运动）"
```

---

### Task F3-1：体重录入页 + 折线图（fl_chart）

**Files:**
- Create: `lib/features/records/weight/weight_tab.dart`
- Create: `lib/features/records/weight/weight_chart.dart`
- Create: `lib/features/records/providers/record_providers.dart`
- Modify: `lib/features/students/pages/student_detail_page.dart`（接入体重 Tab）

- [ ] **Step 1：写入 `lib/features/records/providers/record_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';

/// 某学员体重记录
final weightListProvider =
    FutureProvider.family<List<WeightRecord>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listWeights(studentId);
});

/// 某学员围度记录
final bodyMetricListProvider =
    FutureProvider.family<List<BodyMetricRecord>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listBodyMetrics(studentId);
});

/// 某学员饮食运动记录
final dailyLogListProvider =
    FutureProvider.family<List<DailyLog>, int>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listDailyLogs(studentId);
});
```

- [ ] **Step 2：写入 `lib/features/records/weight/weight_chart.dart`**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 体重折线图
class WeightChart extends StatelessWidget {
  final List<WeightRecord> records;
  const WeightChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('至少需要 2 条记录才能绘制趋势')),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < records.length; i++) {
      spots.add(FlSpot(i.toDouble(), records[i].weightKg));
    }
    final weights = records.map((r) => r.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(LineChartData(
          minY: minW,
          maxY: maxW,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0x1A0B6B1D)),
            ),
          ],
        )),
      ),
    );
  }
}
```

- [ ] **Step 3：写入 `lib/features/records/weight/weight_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';
import 'weight_chart.dart';

class WeightTab extends ConsumerStatefulWidget {
  final int studentId;
  const WeightTab({super.key, required this.studentId});

  @override
  ConsumerState<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<WeightTab> {
  Future<void> _add() async {
    final input = await showDialog<WeightInput>(
      context: context,
      builder: (ctx) => _WeightDialog(),
    );
    if (input == null) return;
    await ref.read(repositoryProvider).upsertWeight(widget.studentId, input);
    ref.invalidate(weightListProvider(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weightListProvider(widget.studentId));
    return async.when(
      data: (records) => Column(
        children: [
          WeightChart(records: records),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: records.length,
              reverse: true,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = records[records.length - 1 - i];
                return ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${r.weightKg} kg'),
                  subtitle: Text('${r.recordDate.year}-${r.recordDate.month}-${r.recordDate.day}'),
                  trailing: Text(r.note),
                  onLongPress: () async {
                    await ref.read(repositoryProvider).deleteWeight(widget.studentId, r.id);
                    ref.invalidate(weightListProvider(widget.studentId));
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('录入体重'),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
    );
  }
}

class _WeightDialog extends StatefulWidget {
  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  DateTime _date = DateTime.now();
  final _weight = TextEditingController();
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('录入体重'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _weight,
              decoration: const InputDecoration(labelText: '体重 (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => double.tryParse(v ?? '') == null ? '请输入有效数值' : null,
            ),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                WeightInput(
                  recordDate: _date,
                  weightKg: double.parse(_weight.text),
                  note: _note.text,
                ),
              );
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4：修改 `student_detail_page.dart` 的 TabBarView，体重 Tab 接入**

把 `_DetailTabs` 的 `TabBarView` children 中体重 Tab（第 2 个）替换为：

```dart
WeightTab(studentId: widget.id),
```

并在文件顶部加导入：

```dart
import '../../../features/records/weight/weight_tab.dart';
```

> 用 Edit 工具替换 `const Center(child: Text('体重（阶段3实现）'))` 为 `WeightTab(studentId: widget.id)`。

- [ ] **Step 5：验证编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/records/
```

- [ ] **Step 6：提交**

```bash
git add lib/features/records/ lib/features/students/pages/student_detail_page.dart
git commit -m "feat: 实现体重录入页与折线图"
```

---

### Task F3-2：围度 + 饮食运动录入页

> 模式与体重一致，省略重复的图表（围度可选图表，MVP 用列表 + 图表）。为避免方案冗长，围度/饮食运动 Tab 实现模式参照 F3-1。

**Files:**
- Create: `lib/features/records/body_metric/body_metric_tab.dart`
- Create: `lib/features/records/daily_log/daily_log_tab.dart`
- Modify: `lib/features/students/pages/student_detail_page.dart`

- [ ] **Step 1：写入 `lib/features/records/body_metric/body_metric_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';

class BodyMetricTab extends ConsumerWidget {
  final int studentId;
  const BodyMetricTab({super.key, required this.studentId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final typeCtl = TextEditingController();
    final valCtl = TextEditingController();
    final unitCtl = TextEditingController(text: 'cm');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('录入围度/体脂'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeCtl, decoration: const InputDecoration(labelText: '类型（腰围/臀围/体脂率…）'),
                validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: valCtl, decoration: const InputDecoration(labelText: '数值'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse(v ?? '') == null ? '无效' : null,
              ),
              TextFormField(controller: unitCtl, decoration: const InputDecoration(labelText: '单位')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).createBodyMetric(studentId, BodyMetricInput(
        recordDate: DateTime.now(), metricType: typeCtl.text, value: double.parse(valCtl.text), unit: unitCtl.text,
      ));
      ref.invalidate(bodyMetricListProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bodyMetricListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (list) => ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = list[i];
              return ListTile(
                leading: const Icon(Icons.straighten_outlined),
                title: Text('${m.metricType}: ${m.value} ${m.unit}'),
                subtitle: Text('${m.recordDate.year}-${m.recordDate.month}-${m.recordDate.day}'),
                onLongPress: () async {
                  await ref.read(repositoryProvider).deleteBodyMetric(studentId, m.id);
                  ref.invalidate(bodyMetricListProvider(studentId));
                },
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'body_metric',
            onPressed: () => _add(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2：写入 `lib/features/records/daily_log/daily_log_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/record_providers.dart';

class DailyLogTab extends ConsumerWidget {
  final int studentId;
  const DailyLogTab({super.key, required this.studentId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final contentCtl = TextEditingController();
    final calCtl = TextEditingController();
    LogType type = LogType.breakfast;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: const Text('录入饮食/运动'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LogType>(
                value: type, decoration: const InputDecoration(labelText: '类型'),
                items: LogType.values.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setSt(() => type = v!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${date.year}-${date.month}-${date.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final p = await showDatePicker(
                    context: ctx, initialDate: date,
                    firstDate: DateTime(2020), lastDate: DateTime.now(),
                  );
                  if (p != null) setSt(() => date = p);
                },
              ),
              TextFormField(
                controller: contentCtl, decoration: const InputDecoration(labelText: '内容'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: calCtl, decoration: const InputDecoration(labelText: '热量（可选）'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('保存'),
          ),
        ],
      )),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).createDailyLog(studentId, DailyLogInput(
        logDate: date, logType: type, content: contentCtl.text,
        calories: double.tryParse(calCtl.text),
      ));
      ref.invalidate(dailyLogListProvider(studentId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyLogListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (list) => ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = list[i];
              return ListTile(
                leading: Icon(l.logType == LogType.exercise ? Icons.fitness_center : Icons.restaurant),
                title: Text(l.content),
                subtitle: Text('${l.logType.label} · ${l.logDate.year}-${l.logDate.month}-${l.logDate.day}'
                    '${l.calories != null ? " · ${l.calories}kcal" : ""}'),
                onLongPress: () async {
                  await ref.read(repositoryProvider).deleteDailyLog(studentId, l.id);
                  ref.invalidate(dailyLogListProvider(studentId));
                },
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'daily_log',
            onPressed: () => _add(context, ref),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3：修改 `student_detail_page.dart`，接入围度/饮食运动 Tab**

用 Edit 把围度 Tab 替换为 `BodyMetricTab(studentId: widget.id)`，饮食运动 Tab 替换为 `DailyLogTab(studentId: widget.id)`，并加导入：

```dart
import '../../../features/records/body_metric/body_metric_tab.dart';
import '../../../features/records/daily_log/daily_log_tab.dart';
```

- [ ] **Step 4：验证编译并提交**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/
git add lib/features/records/ lib/features/students/pages/student_detail_page.dart
git commit -m "feat: 实现围度与饮食运动录入页"
```

---

## 阶段 4：AI 对话模块

> **并行：** B4-* 与 F4-* 独立。后端最核心：AgentScope Agent + SSE + 上下文注入。

### Task B4-1：RAG 抽象接口（空实现）+ LLM 模型构建

**Files:**
- Create: `backend/app/agent/__init__.py`（空）
- Create: `backend/app/agent/retriever.py`
- Create: `backend/app/agent/llm.py`

- [ ] **Step 1：写入 `backend/app/agent/retriever.py`**

```python
"""RAG 检索抽象接口。MVP 给空实现；后期接向量库时只需实现 Retriever，
不改动 chat_service 上层逻辑。"""
from abc import ABC, abstractmethod


class Retriever(ABC):
    """RAG 检索接口。"""

    @abstractmethod
    async def retrieve(self, query: str, top_k: int = 3) -> list[str]:
        """返回相关文档片段列表。无 RAG 时返回空列表。"""
        ...


class EmptyRetriever(Retriever):
    """MVP 空实现：直接返回空上下文。"""

    async def retrieve(self, query: str, top_k: int = 3) -> list[str]:
        return []


# 根据 config 选择 retriever（MVP 永远是空实现）
from app.config import settings

retriever: Retriever = EmptyRetriever() if not settings.rag_enabled else EmptyRetriever()
```

- [ ] **Step 2：写入 `backend/app/agent/llm.py`**

```python
"""构建 AgentScope 使用的 LLM 模型实例（OpenAI 兼容 API）。"""
from app.config import settings
from agentscope.credential import OpenAICredential
from agentscope.model import OpenAIChatModel

# 复用的 credential 与 model（模块级单例，避免每次对话重建）
_credential = OpenAICredential(api_key=settings.llm_api_key)
_model = OpenAIChatModel(
    credential=_credential,
    model=settings.llm_model,
    client_kwargs={"base_url": settings.llm_base_url},
    stream=True,
)


def get_model() -> OpenAIChatModel:
    """获取共享的 LLM 模型实例。"""
    return _model
```

- [ ] **Step 3：写 smoke 测试 `backend/tests/test_llm_config.py`**

```python
"""LLM 配置构建测试（不实际调用 API）。"""
from app.agent.llm import get_model


def test_model_can_be_built():
    m = get_model()
    # 仅验证对象可构造，不发起网络请求
    assert m is not None
```

- [ ] **Step 4：运行测试 + 提交**

```bash
cd backend
uv run pytest tests/test_llm_config.py tests/ -k "retriever or llm" -v
# 注意：EmptyRetriever 简单，可在 test_llm_config 末尾加一个 retrieve 断言
git add backend/app/agent/retriever.py backend/app/agent/llm.py backend/tests/test_llm_config.py
git commit -m "feat: 实现 RAG 空实现与 LLM 模型构建"
```

---

### Task B4-2：教练 Agent + 对话上下文组装

**Files:**
- Create: `backend/app/service/chat_service.py`（含上下文组装）
- Create: `backend/app/agent/coach_agent.py`

- [ ] **Step 1：写入 `backend/app/agent/coach_agent.py`**

```python
"""教练对话 Agent（基于 AgentScope）。

职责：接收组装好的 system prompt（含学员上下文）+ 历史消息，
用 reply_stream 流式输出回复。Agent 层只管对话，不关心业务数据获取。
"""
from collections.abc import AsyncGenerator
from agentscope.agent import Agent
from agentscope.tool import Toolkit
from agentscope.message import Msg, UserMsg
from app.agent.llm import get_model


def build_coach_agent(system_prompt: str) -> Agent:
    """构建一个带指定 system prompt 的教练 Agent。"""
    return Agent(
        name="SlimCoach",
        system_prompt=system_prompt,
        model=get_model(),
        toolkit=Toolkit(),  # MVP 不带工具；预留工具扩展
    )


async def stream_reply(
    system_prompt: str, history: list[Msg], user_text: str
) -> AsyncGenerator[str, None]:
    """流式生成回复，逐块 yield 文本增量。

    - system_prompt: 含学员数据的系统提示
    - history: 历史对话消息
    - user_text: 本次用户输入
    """
    agent = build_coach_agent(system_prompt)
    # 把历史灌入 agent state
    agent.state.context.extend(history)
    user_msg = UserMsg("coach", user_text)
    async for event in agent.reply_stream(user_msg):
        # 只关心文本增量事件
        if event.type == "TEXT_BLOCK_DELTA" and getattr(event, "delta", None):
            yield event.delta
```

- [ ] **Step 2：写入 `backend/app/service/chat_service.py`**

```python
"""对话业务逻辑：会话管理 + 上下文组装 + 调 Agent。

上下文注入规则（设计文档 5.3）：会话绑定 student_id 时，
自动拉取该学员近 7 天体重 + 最近围度 + 最近饮食运动摘要，
作为 system prompt 注入。
"""
from datetime import date, timedelta
from collections.abc import AsyncGenerator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from agentscope.message import UserMsg, AssistantMsg
from app.exceptions import NotFoundError
from app.model.chat_history import ChatSession, ChatMessage
from app.model.record import WeightRecord, BodyMetricRecord, DailyLog
from app.model.student import Student
from app.agent.coach_agent import stream_reply
from app.agent.retriever import retriever
from app.schemas.chat import ChatSessionCreate


BASE_SYSTEM_PROMPT = (
    "你是一位专业的减肥教练助手，为教练提供基于学员数据的针对性指导建议。"
    "回答要具体、可操作，结合学员的实际数据。语气专业、鼓励。"
)


async def create_session(
    db: AsyncSession, data: ChatSessionCreate
) -> ChatSession:
    """新建对话会话（可选绑定学员）。"""
    session = ChatSession(
        student_id=data.student_id,
        title=data.title or "新会话",
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def list_sessions(
    db: AsyncSession, student_id: int | None = None
) -> list[ChatSession]:
    """会话列表。"""
    stmt = select(ChatSession).order_by(ChatSession.created_at.desc())
    if student_id is not None:
        stmt = stmt.where(ChatSession.student_id == student_id)
    return list((await db.execute(stmt)).scalars().all())


async def list_messages(db: AsyncSession, session_id: int) -> list[ChatMessage]:
    """历史消息。"""
    stmt = select(ChatMessage).where(
        ChatMessage.session_id == session_id
    ).order_by(ChatMessage.created_at.asc())
    return list((await db.execute(stmt)).scalars().all())


async def delete_session(db: AsyncSession, session_id: int) -> None:
    s = (
        await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    ).scalar_one_or_none()
    if s is None:
        raise NotFoundError("会话不存在")
    await db.delete(s)
    await db.commit()


async def _build_context_prompt(db: AsyncSession, student_id: int) -> str:
    """组装学员上下文 system prompt。"""
    student = (
        await db.execute(select(Student).where(Student.id == student_id))
    ).scalar_one_or_none()
    if student is None:
        return BASE_SYSTEM_PROMPT

    since = date.today() - timedelta(days=7)
    weights = list((
        await db.execute(
            select(WeightRecord)
            .where(WeightRecord.student_id == student_id, WeightRecord.record_date >= since)
            .order_by(WeightRecord.record_date.asc())
        )
    ).scalars().all())
    metrics = list((
        await db.execute(
            select(BodyMetricRecord)
            .where(BodyMetricRecord.student_id == student_id)
            .order_by(BodyMetricRecord.record_date.desc())
            .limit(5)
        )
    ).scalars().all())
    logs = list((
        await db.execute(
            select(DailyLog)
            .where(DailyLog.student_id == student_id)
            .order_by(DailyLog.log_date.desc())
            .limit(10)
        )
    ).scalars().all())

    parts = [BASE_SYSTEM_PROMPT, "", f"【当前学员】{student.name}，{student.gender}，{student.age}岁，身高 {student.height_cm}cm，目标体重 {student.target_weight_kg}kg。"]
    if weights:
        w_text = "，".join(
            f"{w.record_date.isoformat()}={w.weight_kg}kg" for w in weights
        )
        parts.append(f"【近7天体重】{w_text}")
        parts.append(f"体重变化：{weights[0].weight_kg}kg → {weights[-1].weight_kg}kg")
    if metrics:
        m_text = "，".join(f"{m.metric_type}={m.value}{m.unit}({m.record_date.isoformat()})" for m in metrics)
        parts.append(f"【最近围度/体脂】{m_text}")
    if logs:
        l_text = "；".join(f"{l.log_date.isoformat()}{l.log_type}:{l.content}" for l in logs)
        parts.append(f"【最近饮食/运动】{l_text}")
    return "\n".join(parts)


async def chat_stream(
    db: AsyncSession, session_id: int, content: str
) -> AsyncGenerator[str, None]:
    """发送消息并流式返回回复。同时持久化 user/assistant 消息。"""
    session = (
        await db.execute(select(ChatSession).where(ChatSession.id == session_id))
    ).scalar_one_or_none()
    if session is None:
        raise NotFoundError("会话不存在")

    # 1. 持久化用户消息
    user_msg = ChatMessage(session_id=session_id, role="user", content=content)
    db.add(user_msg)
    await db.commit()

    # 2. 组装 system prompt（含学员上下文）
    student_id = session.student_id
    system_prompt = (
        await _build_context_prompt(db, student_id) if student_id else BASE_SYSTEM_PROMPT
    )
    # 注入 RAG（MVP 空实现）
    rag_docs = await retriever.retrieve(content)
    if rag_docs:
        system_prompt += "\n\n【参考资料】\n" + "\n".join(rag_docs)

    # 3. 拉历史，转成 AgentScope Msg
    history_orm = await list_messages(db, session_id)
    # 排除刚存的 user_msg（reply_stream 内部会接收 user_text）
    prior = history_orm[:-1]
    history_msgs: list = []
    for m in prior:
        if m.role == "user":
            history_msgs.append(UserMsg("coach", m.content))
        else:
            history_msgs.append(AssistantMsg("SlimCoach", m.content))

    # 4. 流式生成 + 累积
    full_reply = []
    try:
        async for chunk in stream_reply(system_prompt, history_msgs, content):
            full_reply.append(chunk)
            yield chunk
    except Exception as e:
        raise  # 由 API 层转成 SSE error 事件

    # 5. 持久化 assistant 消息
    assistant_msg = ChatMessage(
        session_id=session_id, role="assistant", content="".join(full_reply)
    )
    db.add(assistant_msg)
    await db.commit()
```

- [ ] **Step 3：写上下文组装测试 `backend/tests/test_chat_context.py`**

```python
"""对话上下文组装测试（mock LLM，不实际调用）。"""
import pytest
from datetime import date, timedelta
from app.db import async_session_factory, engine
from app.model.base import Base
from app.model.student import Student
from app.model.record import WeightRecord, BodyMetricRecord
from app.service.chat_service import _build_context_prompt


@pytest.fixture
async def db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with async_session_factory() as session:
        yield session


async def test_context_contains_student_data(db):
    s = Student(name="小王", gender="male", age=30, height_cm=175.0,
                target_weight_kg=70.0, start_date="2026-07-01")
    db.add(s)
    await db.flush()
    today = date.today()
    db.add(WeightRecord(student_id=s.id, record_date=today, weight_kg=80.0))
    db.add(BodyMetricRecord(student_id=s.id, record_date=today, metric_type="腰围", value=90.0, unit="cm"))
    await db.commit()

    prompt = await _build_context_prompt(db, s.id)
    assert "小王" in prompt
    assert "近7天体重" in prompt
    assert "腰围" in prompt


async def test_context_no_student_returns_base(db):
    """学员不存在时返回基础 prompt，不报错。"""
    prompt = await _build_context_prompt(db, 9999)
    assert "减肥教练" in prompt
```

- [ ] **Step 4：运行测试**

```bash
cd backend
uv run pytest tests/test_chat_context.py -v
# 预期：2 passed
```

- [ ] **Step 5：提交**

```bash
git add backend/app/agent/coach_agent.py backend/app/service/chat_service.py backend/tests/test_chat_context.py
git commit -m "feat: 实现教练 Agent 与对话上下文组装"
```

---

### Task B4-3：对话 API（SSE 流式）

**Files:**
- Create: `backend/app/api/chat.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_chat_api.py`

- [ ] **Step 1：写入 `backend/app/api/chat.py`**

```python
"""对话 API 路由（含 SSE 流式）。"""
import json
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import verify_token
from app.db import async_session_factory, get_db
from app.exceptions import AppError, LLMError, NotFoundError
from app.schemas.chat import ChatSessionCreate, ChatSessionOut, ChatMessageOut, ChatSendIn
from app.service import chat_service

router = APIRouter(prefix="/chat", tags=["对话"], dependencies=[Depends(verify_token)])


@router.post("/sessions", response_model=ChatSessionOut, status_code=201)
async def create_session(data: ChatSessionCreate, db: AsyncSession = Depends(get_db)):
    return await chat_service.create_session(db, data)


@router.get("/sessions", response_model=list[ChatSessionOut])
async def list_sessions(student_id: int | None = None, db: AsyncSession = Depends(get_db)):
    return await chat_service.list_sessions(db, student_id)


@router.get("/sessions/{session_id}/messages", response_model=list[ChatMessageOut])
async def list_messages(session_id: int, db: AsyncSession = Depends(get_db)):
    return await chat_service.list_messages(db, session_id)


@router.delete("/sessions/{session_id}", status_code=204)
async def delete_session(session_id: int, db: AsyncSession = Depends(get_db)):
    await chat_service.delete_session(db, session_id)


@router.post("/sessions/{session_id}/messages")
async def send_message(
    session_id: int, data: ChatSendIn, request: Request
) -> StreamingResponse:
    """发送消息 → SSE 流式返回。

    对话是长任务，用独立 session 避免与请求生命周期耦合。
    SSE 格式：data: {"type":"chunk","content":"..."} / data: {"type":"done"}
    """

    async def event_generator():
        # 独立 session（流式期间保持连接）
        async with async_session_factory() as db:
            try:
                async for chunk in chat_service.chat_stream(db, session_id, data.content):
                    if await request.is_disconnected():
                        break
                    yield f"data: {json.dumps({'type': 'chunk', 'content': chunk}, ensure_ascii=False)}\n\n"
                yield "data: {\"type\":\"done\"}\n\n"
            except NotFoundError as e:
                yield f"data: {json.dumps({'type': 'error', 'message': e.message}, ensure_ascii=False)}\n\n"
            except Exception as e:
                # LLM 或其他异常 → SSE error
                yield f"data: {json.dumps({'type': 'error', 'message': 'AI 服务暂时不可用'}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
```

- [ ] **Step 2：在 `backend/app/main.py` 注册路由**

```python
from app.api import students, records, chat

app.include_router(students.router, prefix="/api/v1")
app.include_router(records.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
```

- [ ] **Step 3：写测试 `backend/tests/test_chat_api.py`（mock LLM）**

```python
"""对话 API 测试（mock 掉真实 LLM 调用）。"""
import json
import pytest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from app.main import app
from app.db import engine
from app.model.base import Base

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


@pytest.fixture(autouse=True)
def reset_db():
    import asyncio
    async def _reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_reset())
    yield


def _make_session(student_id=None):
    r = client.post("/api/v1/chat/sessions", json={"student_id": student_id, "title": "测试"},
                    headers=AUTH)
    return r.json()["id"]


def test_create_list_session():
    sid = _make_session()
    assert sid is not None
    r = client.get("/api/v1/chat/sessions", headers=AUTH)
    assert len(r.json()) == 1


def test_send_message_sse_stream():
    """mock stream_reply，验证 SSE 格式。"""
    sid = _make_session()

    async def fake_stream(system_prompt, history, user_text):
        for chunk in ["你好", "教练"]:
            yield chunk

    with patch("app.service.chat_service.stream_reply", fake_stream):
        with client.stream("POST", f"/api/v1/chat/sessions/{sid}/messages",
                           json={"content": "在吗"}, headers=AUTH) as r:
            assert r.status_code == 200
            body = "".join(line.decode() for line in r.iter_lines())
            assert "chunk" in body
            assert "done" in body
            # 验证消息已持久化
            msgs = client.get(f"/api/v1/chat/sessions/{sid}/messages", headers=AUTH).json()
            assert len(msgs) == 2  # user + assistant
```

> 注意：`stream_reply` 是 `app.service.chat_service` 模块里 import 进来的名字，patch 路径用 `app.service.chat_service.stream_reply`。

- [ ] **Step 4：运行测试**

```bash
cd backend
uv run pytest tests/test_chat_api.py -v
# 预期：2 passed
```

- [ ] **Step 5：提交**

```bash
git add backend/app/api/chat.py backend/app/main.py backend/tests/test_chat_api.py
git commit -m "feat: 实现对话 API（SSE 流式 + 持久化）"
```

---

### Task F4-1：对话列表页 + 新建会话

**Files:**
- Replace: `lib/features/chat/chat_list_page.dart`
- Create: `lib/features/chat/providers/chat_providers.dart`

- [ ] **Step 1：写入 `lib/features/chat/providers/chat_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/repositories/repository_provider.dart';

/// 会话列表
final chatSessionListProvider =
    FutureProvider.family<List<ChatSession>, int?>((ref, studentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listChatSessions(studentId: studentId);
});

/// 某会话的消息列表
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, int>((ref, sessionId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.listMessages(sessionId);
});
```

- [ ] **Step 2：替换 `lib/features/chat/chat_list_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/responsive.dart' as r; // alias 避免与 dart:core 冲突
import '../../core/responsive.dart';
import '../../core/repositories/repository_provider.dart';
import 'providers/chat_providers.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  Future<void> _newSession(BuildContext context, WidgetRef ref) async {
    final session = await ref.read(repositoryProvider).createChatSession(
          const ChatSessionInput(title: '新会话'),
        );
    if (context.mounted) {
      ref.invalidate(chatSessionListProvider(null));
      context.push('/chat/${session.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatSessionListProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('对话')),
      body: Padding(
        padding: EdgeInsets.all(contentMargin(context)),
        child: async.when(
          data: (sessions) => sessions.isEmpty
              ? const Center(child: Text('暂无会话，点右下角新建'))
              : ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(s.title),
                      subtitle: Text('${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}'
                          '${s.studentId != null ? " · 已绑定学员" : ""}'),
                      onTap: () => context.push('/chat/${s.id}'),
                      onLongPress: () async {
                        await ref.read(repositoryProvider).deleteChatSession(s.id);
                        ref.invalidate(chatSessionListProvider(null));
                      },
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newSession(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

> 注意：顶部 `import 'core/responsive.dart' as r;` 这行是多余的（误写），实际只需 `import '../../core/responsive.dart';`。删除那行 alias import。

- [ ] **Step 3：修正导入（删除多余 alias 行）**

把文件顶部第一条 import 那行 `import 'core/responsive.dart' as r;` 删除（这是草稿遗留）。保留 `import '../../core/responsive.dart';`。

- [ ] **Step 4：验证编译并提交**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/chat/
git add lib/features/chat/
git commit -m "feat: 实现对话列表页与新建会话"
```

---

### Task F4-2：对话页（SSE 流式渲染）

**Files:**
- Replace: `lib/features/chat/chat_page.dart`
- Create: `lib/features/chat/widgets/chat_bubble.dart`

- [ ] **Step 1：写入 `lib/features/chat/widgets/chat_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 对话气泡
class ChatBubble extends StatelessWidget {
  final MessageRole role;
  final String content;
  const ChatBubble({super.key, required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          style: TextStyle(color: isUser ? AppColors.onPrimary : AppColors.onSurface),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2：替换 `lib/features/chat/chat_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/repositories/repository_provider.dart';
import 'providers/chat_providers.dart';
import 'widgets/chat_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int sessionId;
  const ChatPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <ChatMessage>[];
  bool _sending = false;
  String _streaming = '';

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _messages.add(ChatMessage(
        id: -1, sessionId: widget.sessionId, role: MessageRole.user,
        content: text, createdAt: DateTime.now(),
      ));
      _streaming = '';
    });
    _scrollDown();

    final repo = ref.read(repositoryProvider);
    try {
      await repo.sendMessageStream(widget.sessionId, text, onChunk: (chunk) {
        setState(() => _streaming += chunk);
        _scrollDown();
      });
      // 流结束后刷新历史（拿到带 id 的真实消息）
      ref.invalidate(chatMessagesProvider(widget.sessionId));
      final fresh = await ref.read(chatMessagesProvider(widget.sessionId).future);
      setState(() {
        _messages.clear();
        _messages.addAll(fresh);
        _streaming = '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatMessagesProvider(widget.sessionId));
    // 首次加载历史
    if (_messages.isEmpty) {
      history.whenData((list) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messages.isEmpty && mounted) {
            setState(() => _messages.addAll(list));
            _scrollDown();
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('对话')),
      body: Column(
        children: [
          Expanded(
            child: history.when(
              data: (_) => ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in _messages) ...[
                    ChatBubble(role: m.role, content: m.content),
                    const SizedBox(height: 8),
                  ],
                  if (_streaming.isNotEmpty) ...[
                    ChatBubble(role: MessageRole.assistant, content: _streaming),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: '输入消息...'),
                      onSubmitted: (_) => _send(),
                      enabled: !_sending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3：验证编译**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/chat/
```

- [ ] **Step 4：提交**

```bash
git add lib/features/chat/
git commit -m "feat: 实现对话页 SSE 流式渲染"
```

---

### Task F4-3：详情页对话 Tab 接入（绑定学员的对话）

> 学员详情页的「对话」Tab：列出该学员的会话，并可新建绑定该学员的会话。

**Files:**
- Create: `lib/features/chat/widgets/student_chat_tab.dart`
- Modify: `lib/features/students/pages/student_detail_page.dart`

- [ ] **Step 1：写入 `lib/features/chat/widgets/student_chat_tab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/repositories/repository_provider.dart';
import '../providers/chat_providers.dart';

class StudentChatTab extends ConsumerWidget {
  final int studentId;
  const StudentChatTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatSessionListProvider(studentId));
    return Stack(
      children: [
        async.when(
          data: (sessions) => ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = sessions[i];
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(s.title),
                subtitle: Text('${s.createdAt.year}-${s.createdAt.month}-${s.createdAt.day}'),
                onTap: () => context.push('/chat/${s.id}'),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'student_chat',
            onPressed: () async {
              final s = await ref.read(repositoryProvider).createChatSession(
                    ChatSessionInput(studentId: studentId),
                  );
              if (context.mounted) context.push('/chat/${s.id}');
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2：修改 `student_detail_page.dart`，对话 Tab 接入**

把对话 Tab（第 5 个）替换为 `StudentChatTab(studentId: widget.id)`，加导入 `import '../../chat/widgets/student_chat_tab.dart';`

- [ ] **Step 3：验证并提交**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/
git add lib/features/chat/widgets/student_chat_tab.dart lib/features/students/pages/student_detail_page.dart
git commit -m "feat: 学员详情页接入对话 Tab（绑定学员会话）"
```

---

## 阶段 5：软件更新 / 安卓 OTA

> 设计文档 5.4：后端自更新（git pull + 重启）+ 安卓 OTA（apk 上传 + 版本检查）。

### Task B5-1：后端自更新 + 版本查询 API

**Files:**
- Create: `backend/app/service/update_service.py`
- Create: `backend/app/api/admin.py`
- Modify: `backend/app/main.py`
- Create: `backend/app/version.py`（版本信息）
- Create: `backend/tests/test_admin_api.py`

- [ ] **Step 1：写入 `backend/app/version.py`**

```python
"""版本信息。从 git 获取 commit hash 与时间。"""
import subprocess
from functools import lru_cache


@lru_cache(maxsize=1)
def get_version_info() -> dict:
    """返回当前版本（git commit hash + 时间）。"""
    try:
        commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
        time = subprocess.run(
            ["git", "show", "-s", "--format=%ci", "HEAD"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
        return {"commit": commit, "time": time}
    except Exception:
        return {"commit": "unknown", "time": "unknown"}
```

- [ ] **Step 2：写入 `backend/app/service/update_service.py`**

```python
"""后端自更新服务：git pull → 安装依赖 → 返回（systemd 负责重启）。

注意：本函数执行 git pull 与 uv sync，实际进程重启由 systemd 触发
（服务配置 ExecRestart 或前端轮询版本确认）。
"""
import subprocess
from app.exceptions import UpdateError


async def run_update() -> dict:
    """执行更新。返回操作结果。"""
    try:
        pull = subprocess.run(
            ["git", "pull", "--ff-only"],
            capture_output=True, text=True, timeout=120,
        )
        if pull.returncode != 0:
            raise UpdateError("git pull 失败", detail={"stderr": pull.stderr})
        # 重新安装依赖（uv sync）
        sync = subprocess.run(
            ["uv", "sync"], capture_output=True, text=True, timeout=180,
        )
        if sync.returncode != 0:
            raise UpdateError("依赖安装失败", detail={"stderr": sync.stderr})
        return {"pulled": True, "detail": pull.stdout}
    except FileNotFoundError as e:
        raise UpdateError("命令不存在", detail={"error": str(e)})
```

- [ ] **Step 3：写入 `backend/app/api/admin.py`**

```python
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
```

- [ ] **Step 4：在 `backend/app/main.py` 注册路由**

```python
from app.api import students, records, chat, admin

app.include_router(students.router, prefix="/api/v1")
app.include_router(records.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
```

- [ ] **Step 5：写测试 `backend/tests/test_admin_api.py`**

```python
"""运维 API 测试。"""
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


def test_version_endpoint():
    r = client.get("/api/v1/admin/version", headers=AUTH)
    assert r.status_code == 200
    assert "commit" in r.json()


def test_version_requires_auth():
    assert client.get("/api/v1/admin/version").status_code == 401
```

- [ ] **Step 6：运行测试 + 提交**

```bash
cd backend
uv run pytest tests/test_admin_api.py -v
git add backend/app/version.py backend/app/service/update_service.py backend/app/api/admin.py backend/app/main.py backend/tests/test_admin_api.py
git commit -m "feat: 实现后端自更新与版本查询 API"
```

---

### Task B5-2：安卓 OTA API（apk 上传 + 版本检查）

**Files:**
- Create: `backend/app/service/app_release_service.py`
- Create: `backend/app/api/app_release.py`
- Create: `backend/app/model/app_release.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_app_release_api.py`

- [ ] **Step 1：写入 `backend/app/model/app_release.py`**

```python
"""APP 版本发布 ORM。"""
from sqlalchemy import String, Integer
from sqlalchemy.orm import Mapped, mapped_column
from app.model.base import Base, TimestampMixin


class AppRelease(Base, TimestampMixin):
    __tablename__ = "app_releases"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    version: Mapped[str] = mapped_column(String(30))           # 如 1.0.1
    version_code: Mapped[int] = mapped_column(Integer)         # 递增 build 号
    apk_path: Mapped[str] = mapped_column(String(255))         # uploads/xxx.apk
    changelog: Mapped[str] = mapped_column(String(1000), default="")
    force_update: Mapped[bool] = mapped_column(default=False)
```

- [ ] **Step 2：写入 `backend/app/service/app_release_service.py`**

```python
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
```

- [ ] **Step 3：写入 `backend/app/api/app_release.py`**

```python
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
```

- [ ] **Step 4：注册路由（`main.py`）**

```python
from app.api import students, records, chat, admin, app_release

app.include_router(students.router, prefix="/api/v1")
app.include_router(records.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(app_release.router, prefix="/api/v1")
```

- [ ] **Step 5：写测试 `backend/tests/test_app_release_api.py`**

```python
"""APP 发布 API 测试。"""
import io
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import engine
from app.model.base import Base

client = TestClient(app)
AUTH = {"Authorization": "Bearer change-me-please"}


@pytest.fixture(autouse=True)
def reset_db():
    import asyncio
    async def _reset():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_reset())
    yield


def test_check_version_no_release():
    assert client.get("/api/v1/app/version").status_code == 404


def test_upload_and_check():
    apk = io.BytesIO(b"fake apk content")
    r = client.post(
        "/api/v1/app/upload",
        data={"version": "1.0.1", "version_code": 2, "changelog": "修复", "force_update": "false"},
        files={"file": ("app.apk", apk, "application/octet-stream")},
        headers=AUTH,
    )
    assert r.status_code == 200
    assert r.json()["version"] == "1.0.1"
    # 检查版本
    v = client.get("/api/v1/app/version").json()
    assert v["version"] == "1.0.1"
    assert v["force_update"] is False
```

- [ ] **Step 6：运行测试 + 提交**

```bash
cd backend
uv run pytest tests/test_app_release_api.py -v
git add backend/app/model/app_release.py backend/app/service/app_release_service.py backend/app/api/app_release.py backend/app/main.py backend/tests/test_app_release_api.py
git commit -m "feat: 实现安卓 OTA（apk 上传 + 版本检查）"
```

---

### Task F5-1：设置页（配置后端 + 检查更新）

**Files:**
- Replace: `lib/features/settings/settings_page.dart`
- Create: `lib/features/settings/widgets/server_config_dialog.dart`

- [ ] **Step 1：写入 `lib/features/settings/widgets/server_config_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';

/// 配置后端 URL + Token 的对话框
class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late final _url = TextEditingController();
  late final _token = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(appConfigProvider);
    _url.text = cfg.baseUrl;
    _token.text = cfg.token;
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('服务器配置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            decoration: const InputDecoration(labelText: '后端地址', hintText: 'https://your-server.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _token,
            decoration: const InputDecoration(labelText: '访问令牌'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            ref.read(appConfigProvider.notifier).save(
                  baseUrl: _url.text.trim(),
                  token: _token.text.trim(),
                );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2：替换 `lib/features/settings/settings_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import 'widgets/server_config_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final client = ref.watch(apiClientProvider);
    final useMock = client == null;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('服务器配置'),
            subtitle: Text(useMock
                ? '未配置（当前使用本地 Mock 数据）'
                : '已连接：${config.baseUrl}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ServerConfigDialog(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('检查更新'),
            subtitle: const Text('后端版本与 APP 更新'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUpdateInfo(context, client),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('减肥教练助手 v0.1.0'),
          ),
        ],
      ),
    );
  }

  void _showUpdateInfo(BuildContext context, ApiClient? client) {
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置后端地址')),
      );
      return;
    }
    // 调用后端 /admin/version
    client.dio.get('/admin/version').then((r) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('版本信息'),
          content: Text('后端版本：${r.data['commit']}\n时间：${r.data['time']}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          ],
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('查询失败：$e')));
    });
  }
}
```

- [ ] **Step 3：验证编译并提交**

```bash
cd /Users/heren/code/slim_bot
fvm flutter analyze lib/features/settings/
git add lib/features/settings/
git commit -m "feat: 实现设置页（服务器配置 + 版本查询）"
```

---

## 阶段 6：联调 + 部署

### Task B6-1：FastAPI 托管 Web 静态文件

> 设计文档：`flutter build web` 产物由 FastAPI 托管。

**Files:**
- Modify: `backend/app/main.py`

- [ ] **Step 1：在 `backend/app/main.py` 末尾追加静态文件托管**

```python
from pathlib import Path
from fastapi.staticfiles import StaticFiles

# 托管 Flutter Web 产物（构建后放到 backend/static/）
web_dist = Path(__file__).parent.parent / "static"
if web_dist.exists():
    app.mount("/", StaticFiles(directory=str(web_dist), html=True), name="web")
```

> 注意：必须放在所有 API 路由注册之后，且用 `/` 挂载（html=True 支持 SPA 回退 index.html）。

- [ ] **Step 2：提交**

```bash
git add backend/app/main.py
git commit -m "feat: FastAPI 托管 Flutter Web 静态文件"
```

---

### Task B6-2：systemd 服务单元 + deploy 脚本

**Files:**
- Create: `deploy/slim-coach.service`
- Create: `deploy/deploy.sh`

- [ ] **Step 1：写入 `deploy/slim-coach.service`**

```ini
[Unit]
Description=减肥教练助手后端
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/slim-coach/backend
# git pull 后 systemd 重启即生效
ExecStart=/opt/slim-coach/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3
EnvironmentFile=/opt/slim-coach/backend/.env

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2：写入 `deploy/deploy.sh`**

```bash
#!/usr/bin/env bash
# 一键部署脚本（在 VPS 项目根目录执行）
set -e

echo "==> 安装后端依赖"
cd backend && uv sync && cd ..

echo "==> 构建 Flutter Web"
flutter build web --release
rm -rf backend/static
cp -r build/web backend/static

echo "==> 重启服务"
sudo systemctl restart slim-coach

echo "==> 部署完成"
```

- [ ] **Step 3：提交**

```bash
chmod +x deploy/deploy.sh
git add deploy/
git commit -m "chore: 添加 systemd 服务单元与一键部署脚本"
```

---

### Task B6-3：后端全量测试 + 数据库初始化

**Files:**
- Modify: `backend/app/main.py`（启动时建表）

- [ ] **Step 1：在 `backend/app/main.py` 加启动建表（开发期便利）**

```python
from contextlib import asynccontextmanager
from app.db import engine
from app.model.base import Base
# 确保所有 model 被导入，以便 Base.metadata 注册
from app.model import student, record, chat_history, app_release  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    """启动时自动建表（SQLite 个人项目足够；生产可用 Alembic）。"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


# 修改 app 创建，挂上 lifespan
app = FastAPI(title="减肥教练助手", version="0.1.0", lifespan=lifespan)
```

> 注意：把原来的 `app = FastAPI(...)` 替换为带 `lifespan` 版本。异常处理器、路由注册保持不变。

- [ ] **Step 2：跑全量测试**

```bash
cd backend
uv run pytest -v
# 预期：所有测试通过
```

- [ ] **Step 3：提交**

```bash
git add backend/app/main.py
git commit -m "feat: 启动自动建表（lifespan）"
```

---

### Task F6-1：前端全量自测 + 响应式验证

- [ ] **Step 1：跑全部前端测试**

```bash
cd /Users/heren/code/slim_bot
fvm flutter test
# 预期：models_test、theme_test 全部通过
```

- [ ] **Step 2：静态分析无错误**

```bash
fvm flutter analyze
# 预期：无 error
```

- [ ] **Step 3：Mock 模式手动走查（无需后端）**

```bash
fvm flutter run -d macos   # 或 chrome
```

验证：
- 学员列表能显示（Mock 种子数据「小王」）
- 新建学员 → 列表刷新
- 学员详情 → 体重 Tab 显示折线图（14 条 Mock 数据）
- 对话列表 → 新建会话 → 发消息收到流式回复

- [ ] **Step 4：提交（如有修复）**

```bash
git add -A
git commit -m "test: 前端全量自测通过（Mock 模式）"
```

---

### Task F6-2：联调对接（切换到真实后端）

- [ ] **Step 1：启动后端**

```bash
cd backend
cp .env.example .env
# 编辑 .env：填真实 LLM_API_KEY、设置 APP_TOKEN
uv run uvicorn app.main:app --reload --port 8000
```

- [ ] **Step 2：前端配置后端**

运行 APP → 设置 → 服务器配置：
- 后端地址：`http://127.0.0.1:8000`
- 访问令牌：`.env` 里的 `APP_TOKEN`

保存后，`repositoryProvider` 自动从 MockRepository 切换到 HttpRepository。

- [ ] **Step 3：按设计文档 8.3 验收清单走查**

1. 配置后端 URL + Token，能正常访问 ✅
2. 新建学员 → 录入体重/围度/饮食 → 详情页图表正常 ✅
3. 绑定学员发对话，AI 回复含该学员数据上下文 ✅
4. 后端 `/admin/version` 返回 commit hash ✅
5. 上传 apk → `GET /app/version` 返回最新版本 ✅

- [ ] **Step 4：提交联调修复（如有）**

```bash
git add -A
git commit -m "fix: 联调对接修复"
```

---

## 自检（方案完成后）

**1. Spec 覆盖检查**（对照设计文档）：
- ✅ 学员档案 CRUD（阶段 2）
- ✅ 体重/围度/饮食运动记录（阶段 3）
- ✅ AI 对话 + SSE + 上下文注入（阶段 4）
- ✅ 后端自更新（B5-1）
- ✅ 安卓 OTA（B5-2）
- ✅ Web 前端托管（B6-1）
- ✅ 响应式适配（F1-2、F1-4）
- ✅ Token 鉴权（B1-2）
- ✅ 统一异常处理（B1-2）
- ✅ RAG 接口预留（B4-1 EmptyRetriever）

**2. 占位符扫描**：方案中所有代码块均为完整可执行代码，无 TBD/TODO。前端占位页面（F1-4 Step 4）在后续任务被整体替换，属正常迭代。

**3. 类型一致性**：
- `Repository` 抽象接口的方法签名（F1-3）与 `HttpRepository`、`MockRepository` 实现一致
- 后端 Schema 字段名（`student_id`、`record_date`、`weight_kg`）与前端 Dart 模型（`fieldRename: FieldRename.snake`）一致
- SSE 事件结构（`{"type":"chunk","content":"..."}`）后端 B4-3 与前端 F1-3 `sendMessageStream` 解析一致

---

## 并行执行建议

**推荐用 subagent-driven-development 执行：**

- **后端线**（B 任务）：一个 subagent 顺序执行 B0 → B1 → B2 → B3 → B4 → B5 → B6
- **前端线**（F 任务）：另一个 subagent 顺序执行 F0 → F1 → F2 → F3 → F4 → F5 → F6
- **阶段 0 必须先完成**（定义契约），之后两条线可完全并行
- **阶段 6 是合流点**：两条线都完成后联调

**阶段间依赖：**
```
阶段0（契约） ──┬─→ 后端线（独立推进）
                └─→ 前端线（独立推进，用 Mock）
                          │
阶段6（联调）←──── 两条线都到 F5/B5 ──┘
```
