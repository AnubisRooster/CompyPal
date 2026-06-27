import base64
import io

import httpx

from app.config import settings


async def transcribe_whisper(audio_base64: str) -> str:
    if not settings.openai_api_key:
        return ""

    audio_bytes = base64.b64decode(audio_base64)
    audio_file = io.BytesIO(audio_bytes)
    audio_file.name = "audio.wav"

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.openai.com/v1/audio/transcriptions",
            headers={"Authorization": f"Bearer {settings.openai_api_key}"},
            files={"file": ("audio.wav", audio_file, "audio/wav")},
            data={"model": "whisper-1"},
        )
        if response.status_code != 200:
            return ""
        data = response.json()
        return data.get("text", "")
