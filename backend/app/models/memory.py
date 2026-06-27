from pydantic import BaseModel


class MemoryIn(BaseModel):
    content: str
    kind: str  # fact, preference, event, emotion
    salience: float = 0.5


class MemoryOut(BaseModel):
    id: str
    content: str
    kind: str
    salience: float
    created_at: int
    source_turn_id: str | None = None
