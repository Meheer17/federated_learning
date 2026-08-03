from fastapi import APIRouter
from server.api.schemas import DeviceRegisterRequest, DeviceRegisterResponse

router = APIRouter()

@router.post("/register", response_model=DeviceRegisterResponse)
async def register_device(payload: DeviceRegisterRequest):
    return DeviceRegisterResponse(
        status="registered",
        server_public_key="SERVER_SODIUM_PUBKEY_HEX_2026",
    )

@router.get("/{device_id}/status")
async def get_device_status(device_id: str):
    return {
        "device_id": device_id,
        "fl_eligible": True,
        "active_round": "round_1",
    }
