from typing import List, Optional
from pydantic import BaseModel

class DeviceRegisterRequest(BaseModel):
    device_id: str
    public_key: str

class DeviceRegisterResponse(BaseModel):
    status: str
    server_public_key: str

class RoundInfoResponse(BaseModel):
    round_id: str
    status: str
    num_participants: int
    min_clients: int

class UpdateSubmissionRequest(BaseModel):
    device_id: str
    dataset_size: int
    encrypted_blob: List[int]

class UpdateSubmissionResponse(BaseModel):
    status: str
    submission_id: str
