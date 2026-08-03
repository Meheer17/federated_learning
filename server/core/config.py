import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "FedChat FL Server"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "SUPER_SECRET_FEDCHAT_KEY_2026")

    # Database & Redis
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./fedchat_server.db")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # AWS S3 Configurations
    AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "")
    AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "")
    AWS_REGION: str = os.getenv("AWS_REGION", "us-east-1")
    AWS_S3_BUCKET: str = os.getenv("AWS_S3_BUCKET", "fedchat-models-bucket")

    # Federated Learning Parameters
    FL_MIN_CLIENTS: int = 3
    FL_ROUNDS: int = 10
    FL_LEARNING_RATE: float = 0.001
    ROUND_TIMEOUT_SECONDS: int = 3600

    # Differential Privacy Parameters
    DP_EPSILON: float = 1.0
    DP_DELTA: float = 1e-5
    DP_CLIP_NORM: float = 1.0

    class Config:
        case_sensitive = True

settings = Settings()
