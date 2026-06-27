import pytest
from starlette.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_create_companion(client: TestClient):
    response = client.post(
        "/companions",
        json={"name": "Aria", "traits": [{"name": "curious", "intensity": 0.8}]},
        headers={"X-User-Id": "test-user-1"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "companion_id" in data


def test_create_companion_with_appearance(client: TestClient):
    response = client.post(
        "/companions",
        json={
            "name": "Boba",
            "traits": [{"name": "playful", "intensity": 0.9}],
            "appearance": {"hair_color": "blue", "eye_color": "hazel"},
        },
        headers={"X-User-Id": "test-user-2"},
    )
    assert response.status_code == 201


def test_get_companion_not_found(client: TestClient):
    response = client.get(
        "/companions/nonexistent",
        headers={"X-User-Id": "test-user-1"},
    )
    assert response.status_code == 404


def test_create_and_get_companion(client: TestClient):
    create_resp = client.post(
        "/companions",
        json={
            "name": "Cora",
            "traits": [{"name": "warm", "intensity": 1.0}],
            "appearance": {"hair_color": "blonde"},
        },
        headers={"X-User-Id": "test-user-3"},
    )
    assert create_resp.status_code == 201
    cid = create_resp.json()["companion_id"]

    get_resp = client.get(
        f"/companions/{cid}",
        headers={"X-User-Id": "test-user-3"},
    )
    assert get_resp.status_code == 200
    state = get_resp.json()
    assert state["name"] == "Cora"
    assert state["relationship_stage"] == "acquaintance"
