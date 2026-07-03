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
