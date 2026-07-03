# 减肥教练助手 - 设计文档

**日期**: 2026-07-03
**状态**: 已确认（待用户最终审阅）

---

## 1. 项目概述

### 1.1 目标
为减肥教练打造的个人管理助手，帮助教练管理多学员数据，并基于学员数据通过 AI 进行针对性指导。

### 1.2 角色
- **教练**：唯一使用者（MVP），手动录入学员数据，与 AI 对话获取指导建议
- **学员端**：预留扩展，MVP 不实现

### 1.3 核心功能
- 学员档案管理（档案、体重、围度/体脂、饮食/运动记录）
- 教练↔AI 对话（基于选中学员近期数据做上下文）
- 软件自更新机制（前后端 OTA）
- RAG 接口预留

### 1.4 技术栈
- **前端**：Flutter（一套代码，安卓 APP + Web）
- **后端**：AgentScope + FastAPI（单进程）
- **数据库**：SQLite
- **LLM**：OpenAI 兼容 API
- **部署**：云服务器 VPS
- **认证**：单一 Token

---

## 2. 整体架构

```
┌─────────────────────────────┐
│  前端 Flutter（一套代码）    │
│  ├─ Android APP             │
│  └─ Web（flutter build web  │
│     + FastAPI/nginx 托管）   │
└──────────────┬──────────────┘
               │ HTTPS  +  Bearer Token
               │ REST (JSON) + SSE (对话流式)
               ▼
┌─────────────────────────────┐
│  后端 AgentScope + FastAPI   │
│  单进程，三层：              │
│  ├─ API 层（路由/校验/SSE）  │
│  ├─ Service 层（业务逻辑）   │
│  └─ Agent 层（对话/RAG预留） │
└──────┬──────────────┬───────┘
       │              │
       ▼              ▼
┌──────────┐   ┌──────────────┐
│ SQLite   │   │ OpenAI 兼容  │
│ (本地文件)│   │ LLM API      │
└──────────┘   └──────────────┘
```

### 关键点
- 前端一套 Flutter 代码，Web 端用响应式布局适配
- 后端单进程三层结构：API → Service → Agent。Service 层负责业务逻辑（学员 CRUD、数据录入），Agent 层只管对话
- RAG：Agent 层留 `Retriever` 抽象接口，MVP 给空实现（直接返回空上下文），后期接向量库不改上层

---

## 3. 后端模块划分

```
backend/
├─ api/              # API 层：路由 + 请求校验 + SSE
│  ├─ students.py        # 学员档案 CRUD
│  ├─ records.py         # 体重/围度/饮食运动记录
│  ├─ chat.py            # 对话（SSE 流式）
│  ├─ admin.py           # 运维：后端更新、版本查询、apk 上传
│  └─ deps.py            # 依赖注入（Token 校验、db session）
├─ service/          # Service 层：业务逻辑
│  ├─ student_service.py
│  ├─ record_service.py
│  └─ chat_service.py    # 组装 Agent 上下文（注入学员近期数据）
├─ agent/            # Agent 层：AgentScope
│  ├─ coach_agent.py     # 教练↔AI 对话 Agent
│  └─ retriever.py       # RAG 抽象接口 + 空实现
├─ model/            # SQLAlchemy ORM
│  ├─ student.py
│  ├─ record.py          # 体重、围度、饮食运动（按类型分表）
│  └─ chat_history.py    # 对话历史
├─ db.py             # SQLite 引擎 + session
├─ config.py         # 配置（LLM key/地址、Token、DB路径）
└─ main.py           # FastAPI app 入口
```

### 职责边界
- **API 层**：参数校验、Token 鉴权、调 Service、返回结果；不含业务逻辑
- **Service 层**：业务核心（学员/记录的增删改查、为对话组装上下文）
- **Agent 层**：`coach_agent` 调 LLM；`retriever` 是 RAG 接口，MVP 返回空，后期接向量库
- **Model 层**：纯数据结构，无逻辑

### 扩展点
- 学员端 = 加 `api/student_portal/` + 中间件
- RAG = 实现 `retriever.py` 接口
- 新功能 = 加 `api/xxx.py` + `service/xxx_service.py`，不动现有代码

---

## 4. 数据模型

### 4.1 Student 学员档案
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| name | str | 姓名 |
| gender | str | 性别 |
| age | int | 年龄 |
| height_cm | float | 身高 |
| target_weight_kg | float | 目标体重 |
| start_date | date | 开始日期 |
| notes | text | 备注 |
| created_at / updated_at | datetime | 时间戳 |

### 4.2 WeightRecord 每日体重
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| student_id | FK → Student | |
| record_date | date | 记录日期（唯一约束：student_id+record_date） |
| weight_kg | float | 体重 |
| note | str | 备注 |
| created_at | datetime | |

**唯一约束**：`(student_id, record_date)`，防止同天重复（覆盖式更新）

### 4.3 BodyMetricRecord 身体围度/体脂
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| student_id | FK → Student | |
| record_date | date | 记录日期 |
| metric_type | str | 类型（腰围/臀围/体脂率/臂围/大腿围…） |
| value | float | 数值 |
| unit | str | 单位（cm/%） |
| created_at | datetime | |

**扩展性**：`metric_type` 字段化，新增指标类型无需改表结构

### 4.4 DailyLog 饮食/运动记录
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| student_id | FK → Student | |
| log_date | date | 日期 |
| log_type | str | 类型（breakfast/lunch/dinner/snack/exercise） |
| content | text | 文本内容 |
| calories | float | 摄入/消耗热量（可选） |
| created_at | datetime | |

### 4.5 ChatSession / ChatMessage 对话历史
**ChatSession**：
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| student_id | FK（可空） | 绑定学员则注入该学员数据作上下文 |
| title | str | 会话标题 |
| created_at | datetime | |

**ChatMessage**：
| 字段 | 类型 | 说明 |
|------|------|------|
| id | PK | 主键 |
| session_id | FK → ChatSession | |
| role | str | user / assistant |
| content | text | 消息内容 |
| created_at | datetime | |

### 设计要点
- **分表而非单表**：体重、围度、饮食运动结构差异大，分表字段清晰、查询直接，避免稀疏列
- **软删除**：MVP 不做，个人用直接物理删除

---

## 5. API 设计

所有接口统一前缀 `/api/v1`，请求头 `Authorization: Bearer <token>`。

### 5.1 学员档案
```
GET    /students                # 学员列表（支持姓名搜索、分页）
POST   /students                # 新建学员
GET    /students/{id}           # 学员详情
PUT    /students/{id}           # 更新档案
DELETE /students/{id}           # 删除学员
```

### 5.2 数据记录
```
# 体重
GET    /students/{id}/weights?start=&end=    # 区间查询（图表用）
POST   /students/{id}/weights                # 录入（日期重复则覆盖）
DELETE /students/{id}/weights/{record_id}

# 围度/体脂
GET    /students/{id}/body-metrics?start=&end=
POST   /students/{id}/body-metrics
DELETE /students/{id}/body-metrics/{record_id}

# 饮食/运动
GET    /students/{id}/daily-logs?date=
POST   /students/{id}/daily-logs
DELETE /students/{id}/daily-logs/{record_id}
```

### 5.3 对话
```
POST   /chat/sessions                      # 新建会话（可选 student_id 绑定学员）
GET    /chat/sessions?student_id=          # 会话列表
GET    /chat/sessions/{id}/messages        # 历史消息
POST   /chat/sessions/{id}/messages        # 发送消息 → SSE 流式返回
DELETE /chat/sessions/{id}
```

**对话 SSE 格式**（`POST /chat/sessions/{id}/messages`）：
```
请求: { "content": "小王最近体重怎么不降？" }

响应 (text/event-stream):
data: {"type":"chunk","content":"根据"}
data: {"type":"chunk","content":"小王近7天"}
data: {"type":"done"}
```

**对话上下文注入**：发送消息时，若会话绑定了 `student_id`，Service 层自动拉取该学员近 7 天体重 + 最近围度 + 最近饮食运动摘要，作为 system prompt 注入，再交给 AgentScope Agent 生成回复。

### 5.4 软件更新
**后端自更新**：
```
POST   /admin/update                    # git pull → 安装依赖 → 重启服务
GET    /admin/version                   # 当前版本（git commit hash + 时间）
```
- 服务由 systemd 管理，重启后自动拉起
- **前提**：VPS 部署时项目需初始化为 git 仓库并配置远程（`git clone` 部署），否则 `git pull` 无效
- 前端调用后轮询 `/admin/version` 确认更新完成

**安卓 APP OTA**：
```
GET    /app/version                     # { version, url, force_update, changelog }
POST   /app/upload                      # 上传新 apk（仅教练 Token，存于 uploads/）
```
- 流程：打包新 apk → 通过 APP 上传 → APP 启动检查版本 → 下载 apk → 安装
- Web 端无需此机制：前端部署后刷新浏览器即生效

**Web 前端部署**：`flutter build web` 产物由 FastAPI 托管静态文件，更新时重新构建+替换文件，用户刷新生效。

---

## 6. 前端结构

```
frontend/
├─ lib/
│  ├─ main.dart                    # 入口
│  ├─ core/
│  │  ├─ api/                      # HTTP 客户端（dio）
│  │  │  ├─ client.dart            # 封装：baseURL、Bearer Token、SSE
│  │  │  └─ api_service.dart       # 各 API 端点
│  │  ├─ config.dart               # 配置（后端 URL、Token 本地存储）
│  │  └─ responsive.dart           # 响应式断点（手机/Web 适配）
│  ├─ features/
│  │  ├─ students/                 # 学员模块
│  │  │  ├─ pages/                 # 列表页、详情页、编辑页
│  │  │  ├─ widgets/               # 学员卡片、数据图表
│  │  │  └─ providers/             # 状态管理（Riverpod）
│  │  ├─ records/                  # 数据录入模块
│  │  │  ├─ weight_page.dart       # 体重录入+折线图
│  │  │  ├─ body_metric_page.dart  # 围度/体脂
│  │  │  └─ daily_log_page.dart    # 饮食/运动
│  │  ├─ chat/                     # 对话模块
│  │  │  ├─ chat_list_page.dart    # 会话列表
│  │  │  └─ chat_page.dart         # 对话页（SSE 流式渲染）
│  │  └─ settings/                 # 设置模块
│  │     ├─ server_config_page.dart  # 配置后端 URL + Token
│  │     └─ update_page.dart       # 检查更新/上传 apk
│  └─ shared/
│     └─ widgets/                  # 通用组件
└─ pubspec.yaml
```

### 路由（go_router）
```
/                        → 学员列表（首页）
/students/:id            → 学员详情（Tab: 档案/体重/围度/饮食运动/对话）
/students/new            → 新建学员
/chat                    → 会话列表
/chat/:sessionId         → 对话页
/settings                → 设置（含更新管理）
```

### 响应式适配
- **手机**：单栏，底部导航（学员/对话/设置）
- **Web（宽屏 ≥900px）**：左侧侧边栏导航 + 内容区；学员详情页可左右分栏（左列表右详情）
- 用 `LayoutBuilder` + 断点判断，一套代码两端通用

### 状态管理
- Riverpod，学员数据/对话状态用 `AsyncNotifier`，统一 loading/error 处理

### SSE 处理
- dio + 流式读取，逐 chunk 拼接渲染对话气泡，模拟打字效果

### 本地配置
- 首次使用需在设置页填后端 URL 和 Token，用 `shared_preferences` 持久化

### 技术选型
- `dio` - HTTP 客户端（支持流式）
- `go_router` - 声明式路由
- `riverpod` - 状态管理
- `fl_chart` - 体重/围度折线图
- `shared_preferences` - 本地配置存储

---

## 7. 错误处理

### 7.1 后端（统一异常处理）
- FastAPI 全局异常处理器，统一返回格式：
  ```json
  { "code": "STUDENT_NOT_FOUND", "message": "学员不存在", "detail": null }
  ```
- 业务异常类：`NotFoundError` / `ValidationError` / `LLMError` / `UpdateError`
- Token 无效/缺失 → 401
- LLM 调用失败 → SSE 返回 `data: {"type":"error","message":"AI 服务暂时不可用"}`，前端在对话气泡显示错误

### 7.2 前端
- dio 拦截器统一处理：
  - 网络错误 → 提示"无法连接服务器"
  - 401 → 跳设置页重配 Token
  - 5xx → Toast 提示
- Riverpod AsyncValue 统一 loading/error 状态，页面显示骨架屏 + 重试按钮

---

## 8. 测试策略

### 8.1 后端（pytest）
- 单元测试：Service 层逻辑（学员 CRUD、上下文组装），mock LLM
- API 测试：FastAPI TestClient，覆盖各端点（含 Token 校验、SSE 流式）
- 重点测：体重录入日期覆盖逻辑、对话上下文注入（验证 system prompt 含学员数据）
- 目标：Service + API 层覆盖率 ≥ 80%

### 8.2 前端
- Widget 测试：学员列表渲染、表单校验、对话气泡流式渲染
- 关键页面：学员详情页 Tab 切换、体重折线图数据渲染

### 8.3 手动验证清单（MVP 验收）
1. 配置后端 URL + Token，能正常访问
2. 新建学员 → 录入体重/围度/饮食 → 详情页图表正常
3. 绑定学员发对话，AI 回复含该学员数据上下文
4. 后端 `/admin/update` 触发 git pull 重启，前端确认版本更新
5. APP 检查到新版本 → 下载 apk → 安装成功

---

## 9. 部署

- 后端：systemd 服务单元文件 + `deploy.sh` 一键脚本
- 配置走 `.env` 文件（LLM key、Token、DB 路径），不入库
- Web 前端：构建产物由 FastAPI 托管静态文件
