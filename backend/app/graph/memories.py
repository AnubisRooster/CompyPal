import uuid
from typing import Any

from app.graph import get_driver


async def get_salient_memories(
    user_id: str, companion_id: str, limit: int = 10
) -> list[dict[str, Any]]:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (u:User {id: $user_id})-[hm:HAS_MEMORY]->(m:Memory)
            WHERE hm.about_companion = $companion_id
            RETURN m.id AS id, m.content AS content, m.kind AS kind,
                   m.salience AS salience, m.created_at AS created_at
            ORDER BY m.salience DESC
            LIMIT $limit
            """,
            user_id=user_id,
            companion_id=companion_id,
            limit=limit,
        )
        return [dict(record) async for record in result]


async def create_memory(
    user_id: str,
    companion_id: str,
    content: str,
    kind: str,
    salience: float,
    source_turn_id: str | None = None,
) -> str:
    dedup_id = await _find_duplicate(user_id, companion_id, content)
    if dedup_id is not None:
        await _bump_salience(dedup_id, salience)
        return dedup_id

    driver = await get_driver()
    memory_id = str(uuid.uuid4())
    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MATCH (u:User {id: $user_id})
            MERGE (m:Memory {id: $memory_id})
            SET m.content = $content,
                m.kind = $kind,
                m.salience = $salience,
                m.created_at = timestamp(),
                m.source_turn_id = $source_turn_id
            MERGE (u)-[:HAS_MEMORY {about_companion: $companion_id}]->(m)
            """,
            user_id=user_id,
            companion_id=companion_id,
            memory_id=memory_id,
            content=content,
            kind=kind,
            salience=salience,
            source_turn_id=source_turn_id,
        )

        if source_turn_id:
            await session.run(
                """
                MATCH (m:Memory {id: $memory_id})
                MATCH (t:ConversationTurn {id: $source_turn_id})
                MERGE (m)-[:MENTIONED_IN]->(t)
                """,
                memory_id=memory_id,
                source_turn_id=source_turn_id,
            )

    return memory_id


async def _find_duplicate(
    user_id: str, companion_id: str, content: str
) -> str | None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (u:User {id: $user_id})-[hm:HAS_MEMORY]->(m:Memory)
            WHERE hm.about_companion = $companion_id
              AND m.content CONTAINS $content_substr
            RETURN m.id AS id
            ORDER BY m.salience DESC
            LIMIT 1
            """,
            user_id=user_id,
            companion_id=companion_id,
            content_substr=content[:60],
        )
        row = await result.single()
        return row["id"] if row else None


async def _bump_salience(memory_id: str, additional: float) -> None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MATCH (m:Memory {id: $memory_id})
            SET m.salience = m.salience + $additional
            """,
            memory_id=memory_id,
            additional=additional,
        )
