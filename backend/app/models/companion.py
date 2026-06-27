from pydantic import BaseModel


class Trait(BaseModel):
    name: str
    intensity: float = 0.5


class CreateCompanionRequest(BaseModel):
    name: str
    traits: list[Trait] = []
    appearance: dict[str, str] = {}
    voice_id: str | None = None


class CreateCompanionResponse(BaseModel):
    companion_id: str


class CompanionState(BaseModel):
    companion_id: str
    name: str
    traits: list[Trait] = []
    appearance: dict[str, str] = {}
    voice_id: str | None = None
    relationship_stage: str = "acquaintance"
    turn_count: int = 0
