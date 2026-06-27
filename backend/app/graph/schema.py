from app.graph import get_driver


async def ensure_constraints() -> None:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        await session.run(
            "CREATE CONSTRAINT IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE"
        )
        await session.run(
            "CREATE CONSTRAINT IF NOT EXISTS FOR (c:Companion) REQUIRE c.id IS UNIQUE"
        )
        await session.run(
            "CREATE CONSTRAINT IF NOT EXISTS FOR (m:Memory) REQUIRE m.id IS UNIQUE"
        )
        await session.run(
            "CREATE CONSTRAINT IF NOT EXISTS FOR (t:ConversationTurn) REQUIRE t.id IS UNIQUE"
        )
