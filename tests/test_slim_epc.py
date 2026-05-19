from urllib import response

import pytest
from fastapi.testclient import TestClient
from main import app
from epc.api import get_repo
import httpx
client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_db():
    client.post("/reset")
    yield

def test_attach_ue_success():
    response = client.post("/ues", json={"ue_id": 10})
    assert response.status_code == 200
    assert response.json()["ue_id"] == 10
    
    get_resp = client.get("/ues/10")
    assert "9" in get_resp.json()["bearers"]

def test_attach_ue_invalid_id():
    response = client.post("/ues", json={"ue_id": 999})
    assert response.status_code == 422


import time

def test_traffic_flow():
    client.post("/ues", json={"ue_id": 1})
    client.post("/ues/1/bearers", json={"bearer_id": 1})
    
    payload = {"protocol": "udp", "Mbps": 1.0}
    client.post("/ues/1/bearers/1/traffic", json=payload)
    
    time.sleep(1.1)
    
    stats_resp = client.get("/ues/1/bearers/1/traffic")
    assert stats_resp.status_code == 200
    assert stats_resp.json()["tx_bps"] > 0


# To make this test pass
# Uncomment api fix code in   api.py  - detach_ue
def test_ue_reconnect_with_active_traffic():
    """
    Test checks whether traffic is
    removed correctly when UE with active
    traffic is detached and attached again
    """
    ue_id = 50
    bearer_id = 5

    #Attach UE
    attach_payload = {"ue_id": ue_id}
    response = client.post("/ues", json=attach_payload)

    assert response.status_code == 200
    assert response.json() == {"status": "attached", "ue_id": ue_id}

    # Add bearer
    bearer_payload = {"bearer_id": bearer_id}
    response = client.post(f"/ues/{ue_id}/bearers", json=bearer_payload)
    assert response.status_code == 200
    assert response.json()["status"] == "bearer_added"

    # Start traffic
    traffic_payload = {
        "protocol": "udp",
        "kbps": 100
    }

    response = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload)

    assert response.status_code == 200
    assert response.json()["status"] == "traffic_started"
    assert response.json()["ue_id"] == ue_id
    assert response.json()["bearer_id"] == bearer_id
    # Delete UE
    response = client.delete(f"/ues/{ue_id}")

    assert response.status_code == 200
    assert response.json() == {"status": "detached", "ue_id": ue_id}

    #Attach UE
    attach_payload = {"ue_id": ue_id}
    response = client.post("/ues", json=attach_payload)

    assert response.status_code == 200

    assert response.json() == {"status": "attached", "ue_id": ue_id}

    # Add bearer again
    bearer_payload = {"bearer_id": bearer_id}
    response = client.post(f"/ues/{ue_id}/bearers", json=bearer_payload)
    assert response.status_code == 200
    assert response.json()["status"] == "bearer_added"


    # Try start transfer again
    response = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload)

    assert response.status_code == 200

    assert response.json()["status"] == "traffic_started"
    assert response.json()["ue_id"] == ue_id
    assert response.json()["bearer_id"] == bearer_id



def test_double_start_traffic():
        """
        Test checks whether traffic is
        correctly rejected with second
        start traffic try
        """
        ue_id = 50
        bearer_id = 2

        client.post("/ues", json={"ue_id": ue_id})
        client.post(f"/ues/{ue_id}/bearers", json={"bearer_id": bearer_id})

        traffic_payload = {"protocol": "tcp", "kbps": 100}
        traffic_payload2 = {"protocol": "tcp", "kbps": 500}

        # First traffic start
        resp1 = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload)
        assert resp1.status_code == 200

        # Second traffic start
        resp2 = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload2)

        # System should not allow second traffic start when is already started
        assert resp2.status_code == 400


def test_get_stats_for_non_existent_bearer_with_traffic():
    """
    Test checks whether api returns
    correct output for no-existent bearer
    """
    ue_id = 50
    invalid_bearer_id = 99

    client.post("/ues", json={"ue_id": ue_id})

    #Stats for non-existent bearer
    response = client.get(f"/ues/{ue_id}/bearers/{invalid_bearer_id}/traffic")

    assert response.status_code == 200
    data = response.json()
    assert data["tx_bps"] == 0
    assert data["rx_bps"] == 0

def test_start_traffic_with_invalid_protocol():
        """
        Test checks whether system returns
        error when provided invalid protocol name
        """
        ue_id = 50
        bearer_id = 1

        # Attack UE and bearer
        client.post("/ues", json={"ue_id": ue_id})
        client.post(f"/ues/{ue_id}/bearers", json={"bearer_id": bearer_id})

        traffic_payload = {
            "protocol": "xyz_test",
            "kbps": 100
        }

        # Traffic start
        response = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload)

        assert response.status_code == 422
        # Validation in models.py - StartTrafficRequest



def test_start_traffic_with_number_of_throughputs():
        """
        Test checks whether system returns
        error when provided invalid number of throughputs
        """
        ue_id = 50
        bearer_id = 1

        # Attack UE and bearer
        client.post("/ues", json={"ue_id": ue_id})
        client.post(f"/ues/{ue_id}/bearers", json={"bearer_id": bearer_id})

        traffic_payload = {
            "protocol": "udp",
            "kbps": 100,
            "Mbps": 10
        }

        # Traffic start
        response = client.post(f"/ues/{ue_id}/bearers/{bearer_id}/traffic", json=traffic_payload)

        assert response.status_code == 422

        errors = response.json()["detail"]
        first_error = errors[0]
        assert first_error["type"] == "value_error"
        assert first_error["msg"] == "Value error, Provide exactly one throughput value (Mbps, kbps, or bps)"
        # Validation in models.py - StartTrafficRequest