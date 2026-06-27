import logging
import sys

from app.config import settings

logger = logging.getLogger("startup")

REQUIRED_KEYS = (
    "neo4j_password",
)

REQUIRED_FOR_PRODUCTION = (
    "anthropic_api_key",
    "elevenlabs_api_key",
    "jwt_secret",
)


def validate_env() -> None:
    missing: list[str] = []
    for key in REQUIRED_KEYS:
        if not getattr(settings, key, None):
            missing.append(key)

    if missing:
        logger.error("Missing required env vars: %s", ", ".join(missing))
        sys.exit(1)

    if settings.app_env == "production":
        prod_missing: list[str] = []
        for key in REQUIRED_FOR_PRODUCTION:
            if not getattr(settings, key, None):
                prod_missing.append(key)
        if prod_missing:
            logger.error(
                "Production requires: %s", ", ".join(prod_missing)
            )
            sys.exit(1)

    logger.info("Environment validated")
