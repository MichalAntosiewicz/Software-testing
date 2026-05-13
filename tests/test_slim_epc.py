import pytest
from fastapi.testclient import TestClient
from main import app
from epc.api import get_repo

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