from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, Query
from fastapi.middleware.cors import CORSMiddleware

from app.api.companions import router as companions_router
from app.api.health import router as health_router
from app.config import settings
from app.graph.schema import ensure_constraints
from app.ws.chat import handle_chat


@asynccontextmanager
async def lifespan(app: FastAPI):
    await ensure_constraints()
    yield
    from app.graph import close_driver
    await close_driver()


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(companions_router)


@app.get("/")
async def root():
    return {"app": settings.app_name, "status": "running"}


@app.websocket("/ws/{companion_id}")
async def websocket_chat(
    ws: WebSocket,
    companion_id: str,
    user_id: str = Query(...),
):
    await handle_chat(ws, companion_id, user_id)
