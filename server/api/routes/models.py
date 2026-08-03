from fastapi import APIRouter

router = APIRouter()

@router.get("/latest")
async def get_latest_global_adapter():
    return {
        "version": "global_v1.0",
        "size_bytes": 2048576,
        "download_url": "/api/v1/models/global_v1.0/download",
    }

@router.get("/{version}/download")
async def download_adapter(version: str):
    return {"message": f"Downloading global adapter version {version}"}
