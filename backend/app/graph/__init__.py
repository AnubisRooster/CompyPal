from neo4j import AsyncGraphDatabase, AsyncDriver, basic_auth
from app.config import settings

_driver: AsyncDriver | None = None
_NEO4J_VERSION: tuple[int, ...] | None = None


async def get_driver() -> AsyncDriver:
    global _driver, _NEO4J_VERSION
    if _driver is None:
        auth = None
        if settings.neo4j_user:
            auth = basic_auth(settings.neo4j_user, settings.neo4j_password or "")
        _driver = AsyncGraphDatabase.driver(
            settings.neo4j_uri,
            auth=auth,
        )
        await _driver.verify_connectivity()
    return _driver


async def close_driver() -> None:
    global _driver
    if _driver is not None:
        await _driver.close()
        _driver = None
