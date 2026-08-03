from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

try:
    from api.schemas import DeviceRegisterRequest, DeviceRegisterResponse
    from models.database import get_db, Device
    from core.config import settings
except ImportError:
    from server.api.schemas import DeviceRegisterRequest, DeviceRegisterResponse
    from server.models.database import get_db, Device
    from server.core.config import settings

router = APIRouter()

@router.post("/register", response_model=DeviceRegisterResponse)
async def register_device(payload: DeviceRegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check if device already registered
    result = await db.execute(select(Device).where(Device.id == payload.device_id))
    device = result.scalars().first()

    if device:
        device.public_key = payload.public_key
        device.last_seen = datetime.utcnow()
    else:
        device = Device(
            id=payload.device_id,
            public_key=payload.public_key,
            registered_at=datetime.utcnow(),
            last_seen=datetime.utcnow(),
        )
        db.add(device)

    await db.commit()
    await db.refresh(device)

    # Server public key for sodium box encryption
    server_public_key = "FEDCHAT_SERVER_PUBLIC_KEY_X25519_2026"

    return DeviceRegisterResponse(
        status="registered",
        server_public_key=server_public_key,
    )

@router.get("/{device_id}/status")
async def get_device_status(device_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Device).where(Device.id == device_id))
    device = result.scalars().first()

    if not device:
        raise HTTPException(status_code=44, detail="Device not registered")

    return {
        "device_id": device.id,
        "fl_eligible": True,
        "registered_at": device.registered_at.isoformat(),
        "total_rounds": device.total_rounds,
    }
