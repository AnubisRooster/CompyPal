import base64

import httpx

from app.config import settings


async def stream_tts(
    text: str,
    voice_id: str = "21m00Tcm4TlvDq8ikWAM",
    model_id: str = "eleven_multilingual_v2",
) -> list[str]:
    if not settings.elevenlabs_api_key:
        return [_silence_chunk()]

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream"
    headers = {
        "xi-api-key": settings.elevenlabs_api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "text": text,
        "model_id": model_id,
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.7},
    }

    chunks: list[str] = []
    async with httpx.AsyncClient() as client:
        async with client.stream("POST", url, json=payload, headers=headers) as resp:
            seq = 0
            async for data in resp.aiter_bytes():
                encoded = base64.b64encode(data).decode()
                chunks.append(encoded)
                seq += 1

    return chunks


async def stream_tts_generator(
    text: str,
    voice_id: str = "21m00Tcm4TlvDq8ikWAM",
    model_id: str = "eleven_multilingual_v2",
):
    if not settings.elevenlabs_api_key:
        yield _silence_chunk()
        return

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream"
    headers = {
        "xi-api-key": settings.elevenlabs_api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "text": text,
        "model_id": model_id,
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.7},
    }

    seq = 0
    async with httpx.AsyncClient() as client:
        async with client.stream("POST", url, json=payload, headers=headers) as resp:
            async for data in resp.aiter_bytes():
                encoded = base64.b64encode(data).decode()
                yield {"seq": seq, "data": encoded}
                seq += 1


def _silence_chunk() -> str:
    return ""
