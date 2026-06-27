from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    return {"status": "ok", "service": "companion-api"}


@router.get("/api/health")
async def api_health_check():
    return {"status": "ok", "service": "companion-api"}
