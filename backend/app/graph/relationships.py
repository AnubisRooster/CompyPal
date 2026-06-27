from typing import Any

from app.graph import get_driver

STAGE_THRESHOLDS: list[tuple[int, str]] = [
    (0, "acquaintance"),
    (10, "friend"),
    (50, "confidant"),
]


def stage_for_turn_count(count: int) -> str:
    stage = "acquaintance"
    for threshold, s in reversed(STAGE_THRESHOLDS):
        if count >= threshold:
            stage = s
            break
    return stage


async def increment_turn_count(
    companion_id: str, user_id: str
) -> dict[str, Any]:
    driver = await get_driver()
    async with driver.session(database="neo4j") as session:
        result = await session.run(
            """
            MATCH (c:Companion {id: $companion_id})-[r:RELATIONSHIP_STAGE]->(u:User {id: $user_id})
            SET r.turn_count = coalesce(r.turn_count, 0) + 1
            RETURN r.turn_count AS turn_count, r.stage AS current_stage
            """,
            companion_id=companion_id,
            user_id=user_id,
        )
        row = await result.single()

        if row is None:
            return {"turn_count": 1, "stage": "acquaintance"}

        new_count = row["turn_count"]
        new_stage = stage_for_turn_count(new_count)

        if new_stage != row["current_stage"]:
            await session.run(
                """
                MATCH (c:Companion {id: $companion_id})-[r:RELATIONSHIP_STAGE]->(u:User {id: $user_id})
                SET r.stage = $new_stage
                """,
                companion_id=companion_id,
                user_id=user_id,
                new_stage=new_stage,
            )

        return {"turn_count": new_count, "stage": new_stage}
