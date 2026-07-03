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
