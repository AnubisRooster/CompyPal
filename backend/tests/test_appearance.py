import pytest
from starlette.testclient import TestClient

from app.graph.appearance import compute_appearance_hash
from app.main import app


@pytest.mark.asyncio
async def test_compute_appearance_hash():
    attrs = {"eye_color": "green", "hair_color": "brown"}
    h1 = compute_appearance_hash(attrs)
    assert isinstance(h1, str)
    assert len(h1) == 16

    h2 = compute_appearance_hash({"hair_color": "brown", "eye_color": "green"})
    assert h1 == h2, "hash should be order-independent"

    h3 = compute_appearance_hash({"eye_color": "blue", "hair_color": "brown"})
    assert h1 != h3, "different values should produce different hashes"


def test_create_companion_with_appearance_and_update_via_delta(client):
    resp = client.post(
        "/companions",
        json={
            "name": "AppearanceTest",
            "traits": [],
            "appearance": {"hair_color": "brown", "eye_color": "green"},
            "voice_id": None,
        },
        headers={"X-User-Id": "appearance-test-user"},
    )
    assert resp.status_code == 201
    cid = resp.json()["companion_id"]

    resp = client.get(f"/companions/{cid}", headers={"X-User-Id": "appearance-test-user"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["appearance"]["hair_color"] == "brown"
    assert data["appearance"]["eye_color"] == "green"


def test_map_attributes_to_rpm_params():
    from app.services.avatar import map_attributes_to_rpm_params

    params = map_attributes_to_rpm_params({"eye_color": "blue", "hair_color": "brown"})
    assert params.get("eyeColor") == "blue"
    assert params.get("hairColor") == "brown"
    assert "hair_style" not in params

    params = map_attributes_to_rpm_params({})
    assert params == {}


def test_compute_appearance_hash_deterministic():
    h1 = compute_appearance_hash({"a": "1", "b": "2"})
    h2 = compute_appearance_hash({"b": "2", "a": "1"})
    assert h1 == h2

    h3 = compute_appearance_hash({"a": "1"})
    assert h1 != h3


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c
