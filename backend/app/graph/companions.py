import uuid
from typing import Any

from app.graph import get_driver


async def create_companion(
    user_id: str,
    name: str,
    traits: list[dict[str, Any]] | None = None,
    appearance: dict[str, str] | None = None,
    voice_id: str | None = None,
) -> dict[str, Any]:
    driver = await get_driver()
    companion_id = str(uuid.uuid4())

    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MATCH (u:User {id: $user_id})
            MERGE (c:Companion {id: $companion_id})
            SET c.name = $name, c.created_at = timestamp()
            MERGE (u)-[:HAS_COMPANION]->(c)
            """,
            user_id=user_id,
            companion_id=companion_id,
            name=name,
        )

        if traits:
            for t in traits:
                await session.run(
                    """
                    MATCH (c:Companion {id: $companion_id})
                    MERGE (t:PersonalityTrait {name: $trait_name})
                    SET t.intensity = $intensity
                    MERGE (c)-[:HAS_TRAIT]->(t)
                    """,
                    companion_id=companion_id,
                    trait_name=t["name"],
                    intensity=t.get("intensity", 0.5),
                )

        if appearance:
            for key, value in appearance.items():
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

        if voice_id:
            await session.run(
                """
                MATCH (c:Companion {id: $companion_id})
                MERGE (v:Voice {provider: 'elevenlabs'})
                SET v.voice_id = $voice_id
                MERGE (c)-[:USES_VOICE]->(v)
                """,
                companion_id=companion_id,
                voice_id=voice_id,
            )

        await session.run(
            """
            MATCH (c:Companion {id: $companion_id})
            WITH c
            MATCH (u:User {id: $user_id})
            MERGE (c)-[:RELATIONSHIP_STAGE {stage: 'acquaintance', turn_count: 0}]->(u)
            """,
            companion_id=companion_id,
            user_id=user_id,
        )

    return {"companion_id": companion_id}


async def get_companion_state(
    companion_id: str, user_id: str
) -> dict[str, Any] | None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (c:Companion {id: $companion_id})
            OPTIONAL MATCH (c)-[:HAS_TRAIT]->(t:PersonalityTrait)
            OPTIONAL MATCH (c)-[:HAS_APPEARANCE]->(a:AppearanceAttribute)
            OPTIONAL MATCH (c)-[:USES_VOICE]->(v:Voice)
            OPTIONAL MATCH (c)-[r:RELATIONSHIP_STAGE]->(u:User {id: $user_id})
            RETURN c.name AS name, c.created_at AS created_at,
                   collect(DISTINCT {name: t.name, intensity: t.intensity}) AS traits,
                   collect(DISTINCT {key: a.key, value: a.value}) AS appearance,
                   v.voice_id AS voice_id,
                   r.stage AS relationship_stage,
                   r.turn_count AS turn_count
            """,
            companion_id=companion_id,
            user_id=user_id,
        )
        row = await result.single()
        if row is None:
            return None

        return {
            "companion_id": companion_id,
            "name": row["name"],
            "traits": [t for t in row["traits"] if t["name"] is not None],
            "appearance": {
                a["key"]: a["value"]
                for a in row["appearance"]
                if a["key"] is not None
            },
            "voice_id": row.get("voice_id"),
            "relationship_stage": row.get("relationship_stage") or "acquaintance",
            "turn_count": row.get("turn_count") or 0,
        }
