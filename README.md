# 减肥教练助手（Slim Coach Assistant）

为减肥教练打造的个人管理助手：管理多学员数据（档案 / 体重 / 围度 / 饮食运动），并基于学员近期数据通过 AI 对话给出针对性指导建议。

- **前端**：Flutter（一套代码 → Android APP + Web）
- **后端**：FastAPI + AgentScope 2.0（单进程，三层：API → Service → Agent）
- **数据库**：SQLite
- **LLM**：OpenAI 兼容 API

> 详细设计见 [DESIGN.md](./DESIGN.md)，实施任务拆解见 [docs/superpowers/plans/](./docs/superpowers/plans/)。

---

## 目录结构

```
.
├── lib/                    # Flutter 前端（仓库根即 Flutter 项目）
│   ├── core/               # 主题 / 路由 / 响应式 / Repository 抽象 / 数据模型
│   ├── features/           # 学员 / 数据记录 / 对话 / 设置 各业务模块
│   └── shared/             # 通用组件（响应式导航外壳）
├── backend/                # FastAPI 后端
│   ├── app/
│   │   ├── api/            # 路由层（学员 / 记录 / 对话 / 运维 / APP发布）
│   │   ├── service/        # 业务逻辑层
│   │   ├── agent/          # AgentScope Agent + RAG 抽象（空实现）
│   │   ├── model/          # SQLAlchemy ORM
│   │   ├── schemas/        # Pydantic 请求/响应模型（前后端契约）
│   │   ├── config.py       # 从 .env 读配置
│   │   ├── db.py           # 异步引擎 + session
│   │   └── main.py         # FastAPI 入口（含启动建表 + Web 静态托管）
│   └── tests/              # pytest（35 个）
├── deploy/                 # systemd 服务单元 + 一键部署脚本
└── DESIGN.md               # 设计文档
```

---

## 前置要求

| 工具 | 版本 | 说明 |
|------|------|------|
| [Flutter](https://flutter.dev) | 3.44.x（stable） | 建议用 [FVM](https://fvm.app) 管理：`fvm install stable && fvm use stable` |
| [uv](https://docs.astral.sh/uv/) | 最新 | Python 依赖管理 |
| Python | ≥ 3.11（开发环境为 3.14） | 后端运行时 |

---

## 本地开发

### 1. 启动后端

```bash
cd backend

# 首次：安装依赖
uv sync

# 首次：准备配置（按需修改里面的 LLM key、Token）
cp .env.example .env

# 启动（开发模式，热重载）
uv run uvicorn app.main:app --reload --port 8000
```

启动后：
- 健康检查：`curl http://127.0.0.1:8000/api/health` → `{"status":"ok"}`
- API 文档（Swagger）：浏览器打开 `http://127.0.0.1:8000/docs`
- 数据库文件自动创建在 `backend/data/coach.db`，表在启动时自动建表（`lifespan`）

> **配置项说明**（`backend/.env`）：
> - `APP_TOKEN`：访问令牌，前端 Bearer Token 必须与此一致（默认 `change-me-please`，生产务必修改）
> - `LLM_API_KEY` / `LLM_BASE_URL` / `LLM_MODEL`：OpenAI 兼容 LLM 配置
> - `DATABASE_URL`：SQLite 路径
> - `UPLOAD_DIR`：APK 上传目录

### 2. 启动前端

前端支持**两种运行模式**：

#### 模式 A：Mock 模式（无需后端，纯前端开发）

不配置服务器地址时，前端自动使用内置的 `MockRepository`（返回内存假数据，含 1 个种子学员「小王」+ 14 天体重），适合快速预览 UI。

```bash
# 在仓库根目录
fvm flutter pub get
fvm flutter run -d macos     # 或 -d chrome / -d <模拟器>
```

#### 模式 B：对接真实后端

1. 先按上面步骤启动后端
2. 运行 APP → 底部导航「设置」→「服务器配置」
   - 后端地址：`http://127.0.0.1:8000`
   - 访问令牌：与 `backend/.env` 的 `APP_TOKEN` 一致（默认 `change-me-please`）
3. 保存后 APP 自动从 Mock 切换到 HTTP，所有数据走真实后端

> **配置持久化**：服务器地址与令牌存于 `shared_preferences`，下次启动自动加载。

#### 构建 Web 版

```bash
fvm flutter build web --release
# 产物在 build/web/，部署时拷贝到 backend/static/ 由 FastAPI 托管（见下文部署）
```

### 3. 跑测试

```bash
# 后端（35 个测试，覆盖 Service + API + 鉴权 + 上下文组装 + SSE）
cd backend && uv run pytest -v

# 前端
fvm flutter test
fvm flutter analyze
```

---

## 部署到服务器（VPS）

### 一键部署

项目提供 `deploy/deploy.sh`，流程为：安装后端依赖 → 构建 Flutter Web → 拷贝到 `backend/static/` → 重启 systemd 服务。

```bash
# 1. 在 VPS 上 clone 项目
git clone <repo-url> /opt/slim-coach
cd /opt/slim-coach

# 2. 配置后端环境
cd backend
cp .env.example .env
# 编辑 .env：填真实 LLM_API_KEY、修改 APP_TOKEN
cd ..

# 3. 安装 systemd 服务
sudo cp deploy/slim-coach.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable slim-coach

# 4. 一键部署（需 VPS 已装好 flutter 与 uv）
bash deploy/deploy.sh
```

### systemd 服务

`deploy/slim-coach.service` 关键配置（按实际路径/用户调整）：

```ini
[Service]
WorkingDirectory=/opt/slim-coach/backend
ExecStart=/opt/slim-coach/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
EnvironmentFile=/opt/slim-coach/backend/.env
```

### Nginx 反向代理（推荐）

Web 端通过 FastAPI 托管静态文件，建议前面挂 Nginx 做 HTTPS + SSE 透传：

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        # SSE 必须关闭缓冲
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 300s;
    }
}
```

> SSE 流式对话要求 `proxy_buffering off`，否则对话会卡住直到整个响应完成。

### 软件更新

#### 后端自更新

APP 内「设置 → 检查更新」可触发后端 `POST /api/v1/admin/update`（执行 `git pull` + `uv sync`，systemd 随后自动重启）。前端轮询 `/admin/version`（git commit hash）确认更新完成。

> 前提：VPS 上项目须用 `git clone` 部署，否则 `git pull` 无效。

#### 安卓 APP OTA

后端已实现完整链路（`POST /app/upload` 上传 apk → `GET /app/version` 检查 → `GET /app/download/{id}` 下载）。

> **当前状态**：后端 OTA 接口与测试已就绪；安卓客户端的「下载 apk + 调用系统安装器」原生逻辑为后续工作项（需平台通道代码 + 真机验证）。

---

## 核心功能一览

| 功能 | 后端 API | 前端页面 |
|------|----------|----------|
| 学员档案 | `GET/POST/PUT/DELETE /api/v1/students` | 学员列表 / 编辑 / 详情 |
| 体重记录（含折线图）| `/students/{id}/weights`（同日覆盖）| 详情页「体重」Tab |
| 围度 / 体脂 | `/students/{id}/body-metrics` | 详情页「围度」Tab |
| 饮食 / 运动 | `/students/{id}/daily-logs` | 详情页「饮食运动」Tab |
| AI 对话（SSE 流式）| `POST /chat/sessions/{id}/messages` | 对话页（绑定学员注入上下文）|
| 后端自更新 | `POST /admin/update`、`GET /admin/version` | 设置页 |
| 安卓 OTA | `/app/version`、`/app/upload`、`/app/download/{id}` | 设置页（版本查询）|

**对话上下文注入**：会话绑定 `student_id` 时，后端自动拉取该学员近 7 天体重 + 最近围度 + 最近饮食运动，作为 system prompt 注入 LLM，使 AI 回复基于真实数据。

---

## 技术栈版本

- Flutter 3.44.4（stable，FVM 管理）
- Dart 3.x
- FastAPI 0.139 + Uvicorn
- SQLAlchemy 2.0（async）+ aiosqlite
- Pydantic v2 + pydantic-settings
- AgentScope 2.0（`agentscope-ai`）
- dio 5.7 / go_router 14.2 / flutter_riverpod 2.5 / fl_chart 0.69

---

## 许可证

见 [LICENSE](./LICENSE)。
