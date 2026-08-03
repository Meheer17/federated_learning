from datetime import datetime
from typing import AsyncGenerator
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base, relationship

from core.config import settings

Base = declarative_base()

# Async Engine and SessionMaker
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

class Device(Base):
    __tablename__ = "devices"

    id = Column(String, primary_key=True)
    public_key = Column(String, nullable=False)
    registered_at = Column(DateTime, default=datetime.utcnow)
    last_seen = Column(DateTime, default=datetime.utcnow)
    total_rounds = Column(Integer, default=0)

class FLRound(Base):
    __tablename__ = "fl_rounds"

    id = Column(String, primary_key=True)
    status = Column(String, default="CREATED")  # CREATED, ACTIVE, AGGREGATING, COMPLETED
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    num_participants = Column(Integer, default=0)
    config_json = Column(Text, nullable=True)

class UpdateSubmission(Base):
    __tablename__ = "update_submissions"

    id = Column(String, primary_key=True)
    device_id = Column(String, ForeignKey("devices.id"))
    round_id = Column(String, ForeignKey("fl_rounds.id"))
    encrypted_blob_path = Column(String, nullable=False)
    dataset_size = Column(Integer, default=1)
    received_at = Column(DateTime, default=datetime.utcnow)

class ModelVersion(Base):
    __tablename__ = "model_versions"

    id = Column(String, primary_key=True)
    version = Column(String, nullable=False)
    round_id = Column(String, ForeignKey("fl_rounds.id"), nullable=True)
    artifact_path = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
