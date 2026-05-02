import sys
from unittest.mock import MagicMock

# Inject mock before Main imports PushNotification (which opens a key file at module load)
mock_push = MagicMock()
sys.modules["PushNotification"] = mock_push

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from Main import app, Base, get_db, is_inside_fence

# ---------- test database ----------

test_engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def reset_db():
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def client():
    return TestClient(app)


# ================================================================
# is_inside_fence
# ================================================================

SQUARE = [(0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0)]


def test_fence_point_inside():
    assert is_inside_fence(0.5, 0.5, SQUARE) is True


def test_fence_point_outside():
    assert is_inside_fence(2.0, 2.0, SQUARE) is False


def test_fence_negative_coords_outside():
    assert is_inside_fence(-1.0, -1.0, SQUARE) is False


def test_fence_empty_polygon():
    assert is_inside_fence(0.5, 0.5, []) is False


# ================================================================
# POST /api/location
# ================================================================

LOCATION_PAYLOAD = {
    "device_id": "Nala",
    "lat": 0.5,
    "lng": 0.5,
    "bat": 90,
    "status": False,
}


def test_post_location_returns_data(client):
    resp = client.post("/api/location", json=LOCATION_PAYLOAD)
    assert resp.status_code == 200
    data = resp.json()
    assert data["device_id"] == "Nala"
    assert data["lat"] == 0.5
    assert data["bat"] == 90
    assert "timestamp" in data


def test_post_location_uses_provided_timestamp(client):
    payload = {**LOCATION_PAYLOAD, "timestamp": "2024-01-01T00:00:00"}
    resp = client.post("/api/location", json=payload)
    assert resp.status_code == 200
    assert resp.json()["timestamp"] == "2024-01-01T00:00:00"


def test_post_location_generates_timestamp_when_absent(client):
    resp = client.post("/api/location", json=LOCATION_PAYLOAD)
    assert resp.json()["timestamp"] not in (None, "")


def test_post_location_geofence_exit_triggers_notification(client):
    mock_push.reset_mock()
    client.post("/api/geo_fence/new-fence/", json={
        "name": "Home",
        "points": [[0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [1.0, 0.0]],
    })
    client.post("/api/APNHolder/store", json={"device_id": "phone1", "token": "tok1"})

    # First update: inside fence — no notification yet
    client.post("/api/location", json={**LOCATION_PAYLOAD, "lat": 0.5, "lng": 0.5})
    mock_push.send_notification.assert_not_called()

    # Second update: outside fence — should fire
    client.post("/api/location", json={**LOCATION_PAYLOAD, "lat": 5.0, "lng": 5.0})
    mock_push.send_notification.assert_called_once()


def test_post_location_no_notification_when_stays_inside(client):
    mock_push.reset_mock()
    client.post("/api/geo_fence/new-fence/", json={
        "name": "Home",
        "points": [[0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [1.0, 0.0]],
    })
    client.post("/api/APNHolder/store", json={"device_id": "phone1", "token": "tok1"})

    for _ in range(3):
        client.post("/api/location", json={**LOCATION_PAYLOAD, "lat": 0.5, "lng": 0.5})

    mock_push.send_notification.assert_not_called()


# ================================================================
# GET /api/location/latest
# ================================================================

def test_latest_location_returns_most_recent(client):
    for lat, ts in [(1.0, "2024-01-01T01:00:00"), (2.0, "2024-01-01T02:00:00")]:
        client.post("/api/location", json={**LOCATION_PAYLOAD, "lat": lat, "timestamp": ts})
    resp = client.get("/api/location/latest", params={"device_id": "Nala"})
    assert resp.status_code == 200
    assert resp.json()["lat"] == 2.0


def test_latest_location_not_found(client):
    resp = client.get("/api/location/latest", params={"device_id": "ghost"})
    assert resp.status_code == 404


# ================================================================
# GET /api/dogs
# ================================================================

def test_dog_count_empty(client):
    resp = client.get("/api/dogs")
    assert resp.status_code == 200
    assert resp.json() == 0


def test_dog_count_distinct_devices(client):
    for device in ["Nala", "Buddy", "Nala"]:
        client.post("/api/location", json={**LOCATION_PAYLOAD, "device_id": device})
    resp = client.get("/api/dogs")
    assert resp.json() == 2


# ================================================================
# GET /api/device_id
# ================================================================

def test_device_ids_empty(client):
    resp = client.get("/api/device_id")
    assert resp.status_code == 200
    assert resp.json() == []


def test_device_ids_distinct(client):
    for device in ["Nala", "Buddy", "Nala"]:
        client.post("/api/location", json={**LOCATION_PAYLOAD, "device_id": device})
    resp = client.get("/api/device_id")
    assert sorted(resp.json()) == ["Buddy", "Nala"]


# ================================================================
# POST /api/geo_fence/new-fence/
# ================================================================

FENCE_PAYLOAD = {
    "name": "Park",
    "points": [[0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [1.0, 0.0]],
}


def test_add_fence_returns_data(client):
    resp = client.post("/api/geo_fence/new-fence/", json=FENCE_PAYLOAD)
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "Park"
    assert "id" in data


# ================================================================
# GET /api/geoFence/data
# ================================================================

def test_get_geo_data_empty(client):
    resp = client.get("/api/geoFence/data")
    assert resp.status_code == 200
    assert resp.json() == []


def test_get_geo_data_returns_all(client):
    for name in ["Park", "Yard"]:
        client.post("/api/geo_fence/new-fence/", json={**FENCE_PAYLOAD, "name": name})
    resp = client.get("/api/geoFence/data")
    assert len(resp.json()) == 2


# ================================================================
# DELETE /api/geoFence/{fence_id}
# ================================================================

def test_delete_fence_removes_it(client):
    create = client.post("/api/geo_fence/new-fence/", json=FENCE_PAYLOAD)
    fence_id = create.json()["id"]
    assert client.delete(f"/api/geoFence/{fence_id}").status_code == 200
    assert client.get("/api/geoFence/data").json() == []


def test_delete_fence_not_found(client):
    resp = client.delete("/api/geoFence/9999")
    assert resp.status_code == 404


# ================================================================
# POST /api/APNHolder/store
# ================================================================

def test_store_new_apn_token(client):
    resp = client.post("/api/APNHolder/store", json={"device_id": "Nala", "token": "tok1"})
    assert resp.status_code == 200
    assert resp.json()["token"] == "tok1"


def test_update_existing_apn_token(client):
    client.post("/api/APNHolder/store", json={"device_id": "Nala", "token": "old"})
    resp = client.post("/api/APNHolder/store", json={"device_id": "Nala", "token": "new"})
    assert resp.status_code == 200
    assert resp.json()["token"] == "new"


# ================================================================
# POST /api/lostWifi
# ================================================================

def test_lost_wifi_sends_warning_to_all_registered_devices(client):
    mock_push.reset_mock()
    client.post("/api/APNHolder/store", json={"device_id": "phone1", "token": "t1"})
    client.post("/api/APNHolder/store", json={"device_id": "phone2", "token": "t2"})
    client.post("/api/lostWifi", json={"device_id": "Nala"})
    assert mock_push.send_warning.call_count == 2


def test_lost_wifi_no_warning_when_no_devices(client):
    mock_push.reset_mock()
    client.post("/api/lostWifi", json={"device_id": "Nala"})
    mock_push.send_warning.assert_not_called()
