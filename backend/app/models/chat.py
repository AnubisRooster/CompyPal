from pydantic import BaseModel


class UserMessage(BaseModel):
    type: str = "user_message"
    text: str


class ServerToken(BaseModel):
    type: str = "token"
    text: str


class ServerEmotion(BaseModel):
    type: str = "emotion"
    state: str


class ServerDone(BaseModel):
    type: str = "done"


class ServerError(BaseModel):
    type: str = "error"
    message: str
