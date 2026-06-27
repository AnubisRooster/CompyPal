import uuid

from app.graph import get_driver


async def save_turn(
    companion_id: str, user_id: str, role: str, text: str
) -> str:
    driver = await get_driver()
    turn_id = str(uuid.uuid4())
    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MATCH (c:Companion {id: $companion_id})
            MATCH (u:User {id: $user_id})
            MERGE (t:ConversationTurn {id: $turn_id})
            SET t.role = $role, t.text = $text, t.created_at = timestamp()
            MERGE (t)-[:FROM_USER]->(u)
            MERGE (t)-[:ABOUT_COMPANION]->(c)
            """,
            companion_id=companion_id,
            user_id=user_id,
            turn_id=turn_id,
            role=role,
            text=text,
        )
    return turn_id


async def get_recent_turns(
    companion_id: str, user_id: str, limit: int = 20
) -> list[dict]:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (t:ConversationTurn)
            WHERE EXISTS {
                MATCH (t)-[:ABOUT_COMPANION]->(c:Companion {id: $companion_id})
                AND EXISTS { MATCH (t)-[:FROM_USER]->(u:User {id: $user_id}) }
            }
            RETURN t.id AS id, t.role AS role, t.text AS text, t.created_at AS created_at
            ORDER BY t.created_at DESC
            LIMIT $limit
            """,
            companion_id=companion_id,
            user_id=user_id,
            limit=limit,
        )
        return [dict(record) async for record in result]
