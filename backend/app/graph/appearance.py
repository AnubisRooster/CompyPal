import hashlib
import json
from typing import Any

from app.graph import get_driver


async def set_appearance_attribute(
    companion_id: str,
    key: str,
    value: str,
) -> None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MATCH (c:Companion {id: $companion_id})
            MERGE (a:AppearanceAttribute {key: $key})
            SET a.value = $value
            MERGE (c)-[:HAS_APPEARANCE]->(a)
            """,
            companion_id=companion_id,
            key=key,
            value=value,
        )


async def apply_appearance_deltas(
    companion_id: str,
    deltas: dict[str, str],
) -> dict[str, str]:
    for key, value in deltas.items():
        await set_appearance_attribute(companion_id, key, value)

    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (c:Companion {id: $companion_id})-[:HAS_APPEARANCE]->(a:AppearanceAttribute)
            RETURN a.key AS key, a.value AS value
            """,
            companion_id=companion_id,
        )
        rows = await result.fetch()
        return {row["key"]: row["value"] for row in rows if row["key"] is not None}


def compute_appearance_hash(attributes: dict[str, str]) -> str:
    raw = json.dumps(attributes, sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]
