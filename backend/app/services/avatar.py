import hashlib
import json
from collections.abc import AsyncIterator
from typing import Any

import httpx

from app.config import settings

_DEMO_AVATAR_URL = "https://models.readyplayer.me/6185a4acfb622cf1cdc49348.glb"
_RPM_API_BASE = "https://api.readyplayer.me/v2"


_ATTRIBUTE_TO_RPM: dict[str, str] = {
    "hair_color": "hairColor",
    "hair_style": "hairStyle",
    "eye_color": "eyeColor",
    "skin_color": "skinColor",
    "beard_style": "beardStyle",
    "beard_color": "beardColor",
    "eyebrow_style": "eyebrowStyle",
    "glasses": "glasses",
    "outfit": "outfit",
    "face_shape": "faceShape",
    "lip_shape": "lipShape",
    "nose_shape": "noseShape",
}


def map_attributes_to_rpm_params(attributes: dict[str, str]) -> dict[str, Any]:
    rpm: dict[str, Any] = {}
    for attr_key, value in attributes.items():
        rpm_key = _ATTRIBUTE_TO_RPM.get(attr_key)
        if rpm_key:
            rpm[rpm_key] = value
    return rpm


def compute_attribute_hash(attributes: dict[str, str]) -> str:
    raw = json.dumps(attributes, sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


class AvatarService:
    def __init__(self) -> None:
        self._http = httpx.AsyncClient(timeout=30.0)

    async def close(self) -> None:
        await self._http.aclose()

    async def get_avatar_url(self, attributes: dict[str, str]) -> str | None:
        attr_hash = compute_attribute_hash(attributes)
        cached = await self._check_cache(attr_hash)
        if cached:
            return cached

        if not settings.readyplayerme_api_key:
            return _DEMO_AVATAR_URL

        rpm_params = map_attributes_to_rpm_params(attributes)
        avatar_id = await self._create_avatar(rpm_params)
        if not avatar_id:
            return _DEMO_AVATAR_URL

        url = f"https://models.readyplayer.me/{avatar_id}.glb"
        await self._write_cache(attr_hash, url)
        return url

    async def _create_avatar(self, params: dict[str, Any]) -> str | None:
        headers = {
            "x-api-key": settings.readyplayerme_api_key,
            "Content-Type": "application/json",
        }
        body: dict[str, Any] = {
            "data": {
                "partner": settings.readyplayerme_app_id or "default",
                "bodyType": "fullbody",
                "assets": params,
            }
        }
        try:
            resp = await self._http.post(
                f"{_RPM_API_BASE}/avatars",
                headers=headers,
                json=body,
            )
            if resp.status_code == 201:
                data = resp.json()
                return data.get("data", {}).get("id")
        except Exception:
            return None
        return None

    async def _check_cache(self, attr_hash: str) -> str | None:
        from app.services.storage import retrieve_glb
        return await retrieve_glb(attr_hash)

    async def _write_cache(self, attr_hash: str, url: str) -> None:
        from app.services.storage import store_glb
        await store_glb(attr_hash, url.encode())
