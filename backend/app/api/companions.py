from fastapi import APIRouter, Header, HTTPException

from app.graph.companions import create_companion, get_companion_state
from app.graph.users import ensure_user
from app.models.companion import (
    CompanionState,
    CreateCompanionRequest,
    CreateCompanionResponse,
)

router = APIRouter(prefix="/companions", tags=["companions"])


@router.post("", response_model=CreateCompanionResponse, status_code=201)
async def create(
    body: CreateCompanionRequest,
    x_user_id: str = Header(...),
) -> CreateCompanionResponse:
    await ensure_user(x_user_id)
    result = await create_companion(
        user_id=x_user_id,
        name=body.name,
        traits=[t.model_dump() for t in body.traits],
        appearance=body.appearance,
        voice_id=body.voice_id,
    )
    return CreateCompanionResponse(**result)


@router.get("/{companion_id}", response_model=CompanionState)
async def get_state(
    companion_id: str,
    x_user_id: str = Header(...),
) -> CompanionState:
    state = await get_companion_state(companion_id, x_user_id)
    if state is None:
        raise HTTPException(status_code=404, detail="Companion not found")
    return CompanionState(**state)
