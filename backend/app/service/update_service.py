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
