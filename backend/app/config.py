from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Companion API"
    debug: bool = False

    neo4j_uri: str = "bolt://localhost:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: str = ""

    anthropic_api_key: str = ""
    elevenlabs_api_key: str = ""
    openai_api_key: str = ""

    readyplayerme_app_id: str = ""
    readyplayerme_api_key: str = ""

    jwt_secret: str = ""

    s3_endpoint: str = ""
    s3_bucket: str = ""
    s3_access_key: str = ""
    s3_secret_key: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
