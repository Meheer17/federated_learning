import os
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

try:
    from api.schemas import RoundInfoResponse, UpdateSubmissionRequest, UpdateSubmissionResponse
    from models.database import get_db, FLRound, UpdateSubmission, Device
    from core.config import settings
except ImportError:
    from server.api.schemas import RoundInfoResponse, UpdateSubmissionRequest, UpdateSubmissionResponse
    from server.models.database import get_db, FLRound, UpdateSubmission, Device
    from server.core.config import settings

router = APIRouter()

@router.get("/current", response_model=RoundInfoResponse)
async def get_current_round(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(FLRound).where(FLRound.status == "ACTIVE"))
    current_round = result.scalars().first()

    if not current_round:
        # Create round 1 if none active
        current_round = FLRound(
            id="round_1",
            status="ACTIVE",
            started_at=datetime.utcnow(),
            num_participants=0,
        )
        db.add(current_round)
        await db.commit()
        await db.refresh(current_round)

    return RoundInfoResponse(
        round_id=current_round.id,
        status=current_round.status,
        num_participants=current_round.num_participants,
        min_clients=settings.FL_MIN_CLIENTS,
    )

@router.post("/{round_id}/submit", response_model=UpdateSubmissionResponse)
async def submit_encrypted_update(
    round_id: str,
    payload: UpdateSubmissionRequest,
    db: AsyncSession = Depends(get_db)
):
    submission_id = str(uuid.uuid4())
    
    # Save update payload blob to local storage/directory
    blob_dir = os.path.join(os.getcwd(), "submissions")
    os.makedirs(blob_dir, exist_ok=True)
    blob_path = os.path.join(blob_dir, f"{submission_id}.bin")

    with open(blob_path, "wb") as f:
        f.write(bytes(payload.encrypted_blob))

    # Record update submission in database
    submission = UpdateSubmission(
        id=submission_id,
        device_id=payload.device_id,
        round_id=round_id,
        encrypted_blob_path=blob_path,
        dataset_size=payload.dataset_size,
        received_at=datetime.utcnow(),
    )
    db.add(submission)

    # Increment round participant count
    result = await db.execute(select(FLRound).where(FLRound.id == round_id))
    fl_round = result.scalars().first()
    if fl_round:
        fl_round.num_participants += 1

    await db.commit()

    return UpdateSubmissionResponse(
        status="accepted",
        submission_id=submission_id,
    )
