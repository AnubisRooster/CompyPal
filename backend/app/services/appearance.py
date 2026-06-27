from typing import Any

from app.graph.appearance import compute_appearance_hash
from app.services.avatar import AvatarService
from app.services.storage import glb_exists


class AppearanceService:
    def __init__(self) -> None:
        self._avatar = AvatarService()

    async def close(self) -> None:
        await self._avatar.close()

    async def process_appearance_change(
        self,
        companion_id: str,
        attributes: dict[str, str],
    ) -> str | None:
        attr_hash = compute_appearance_hash(attributes)
        cached = await glb_exists(attr_hash)
        if cached:
            return attr_hash

        avatar_url = await self._avatar.get_avatar_url(attributes)
        return avatar_url

    async def get_current_avatar_url(
        self,
        companion_id: str,
        attributes: dict[str, str],
    ) -> str | None:
        return await self._avatar.get_avatar_url(attributes)
