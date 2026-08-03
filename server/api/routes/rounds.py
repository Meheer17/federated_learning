import uuid
from fastapi import APIRouter
from server.api.schemas import RoundInfoResponse, UpdateSubmissionRequest, UpdateSubmissionResponse

router = APIRouter()

@router.get("/current", response_model=RoundInfoResponse)
async def get_current_round():
    return RoundInfoResponse(
        round_id="round_1",
        status="ACTIVE",
        num_participants=2,
        min_clients=3,
    )

@router.post("/{round_id}/submit", response_model=UpdateSubmissionResponse)
async def submit_encrypted_update(round_id: str, payload: UpdateSubmissionRequest):
    submission_id = str(uuid.uuid4())
    return UpdateSubmissionResponse(
        status="accepted",
        submission_id=submission_id,
    )
