import hashlib
import json
from pathlib import Path
from typing import Any

from app.config import settings

_CACHE_DIR = Path("cache/meshes")
_CACHE_DIR.mkdir(parents=True, exist_ok=True)


def _hash_key(data: dict[str, Any]) -> str:
    raw = json.dumps(data, sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def _path_for(asset_key: str, suffix: str = ".glb") -> Path:
    return _CACHE_DIR / f"{asset_key}{suffix}"


async def store_glb(asset_key: str, data: bytes) -> str:
    if settings.s3_endpoint and settings.s3_bucket:
        return await _store_s3(asset_key, data)
    path = _path_for(asset_key)
    path.write_bytes(data)
    return path.as_uri()


async def retrieve_glb(asset_key: str) -> bytes | None:
    if settings.s3_endpoint and settings.s3_bucket:
        return await _retrieve_s3(asset_key)
    path = _path_for(asset_key)
    return path.read_bytes() if path.exists() else None


async def glb_exists(asset_key: str) -> bool:
    if settings.s3_endpoint and settings.s3_bucket:
        return await _exists_s3(asset_key)
    return _path_for(asset_key).exists()


async def _store_s3(asset_key: str, data: bytes) -> str:
    try:
        import boto3
    except ImportError:
        raise RuntimeError("boto3 required for S3 storage: pip install boto3")
    client = boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
    )
    key = f"meshes/{asset_key}.glb"
    client.put_object(Bucket=settings.s3_bucket, Key=key, Body=data)
    return f"{settings.s3_endpoint}/{settings.s3_bucket}/{key}"


async def _retrieve_s3(asset_key: str) -> bytes | None:
    try:
        import boto3
    except ImportError:
        raise RuntimeError("boto3 required for S3 storage: pip install boto3")
    client = boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
    )
    try:
        obj = client.get_object(Bucket=settings.s3_bucket, Key=f"meshes/{asset_key}.glb")
        return obj["Body"].read()
    except Exception:
        return None


async def _exists_s3(asset_key: str) -> bool:
    try:
        import boto3
    except ImportError:
        raise RuntimeError("boto3 required for S3 storage: pip install boto3")
    client = boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
    )
    try:
        client.head_object(Bucket=settings.s3_bucket, Key=f"meshes/{asset_key}.glb")
        return True
    except Exception:
        return False
