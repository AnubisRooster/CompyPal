from app.graph import get_driver


async def ensure_user(user_id: str, display_name: str | None = None) -> None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        await session.run(
            """
            MERGE (u:User {id: $user_id})
            ON CREATE SET u.display_name = $display_name, u.created_at = timestamp()
            ON MATCH SET u.display_name = coalesce($display_name, u.display_name)
            """,
            user_id=user_id,
            display_name=display_name or user_id,
        )
