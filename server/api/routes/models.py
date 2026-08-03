import os
import boto3
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

try:
    from models.database import get_db, ModelVersion
    from core.config import settings
except ImportError:
    from server.models.database import get_db, ModelVersion
    from server.core.config import settings

router = APIRouter()

def get_s3_client():
    """Initialize AWS S3 client using boto3"""
    return boto3.client(
        "s3",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID if settings.AWS_ACCESS_KEY_ID else None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY if settings.AWS_SECRET_ACCESS_KEY else None,
    )

@router.get("/latest")
async def get_latest_global_adapter(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ModelVersion).order_by(ModelVersion.created_at.desc())
    )
    latest = result.scalars().first()

    if not latest:
        return {
            "version": "global_v1.0",
            "size_bytes": 2048576,
            "download_url": "/api/v1/models/global_v1.0/download",
            "created_at": datetime.utcnow().isoformat(),
        }

    return {
        "version": latest.version,
        "round_id": latest.round_id,
        "artifact_path": latest.artifact_path,
        "download_url": f"/api/v1/models/{latest.version}/download",
        "created_at": latest.created_at.isoformat(),
    }

@router.get("/{version}/download")
async def download_adapter(version: str, db: AsyncSession = Depends(get_db)):
    # Check if configured for AWS S3
    if settings.AWS_ACCESS_KEY_ID and settings.AWS_S3_BUCKET:
        try:
            s3 = get_s3_client()
            url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": settings.AWS_S3_BUCKET, "Key": f"models/{version}.bin"},
                ExpiresIn=3600,
            )
            return {"download_url": url, "storage": "AWS_S3"}
        except Exception as e:
            pass

    # Fallback local artifact response
    return {"message": f"Downloading global adapter version {version} from server storage."}
