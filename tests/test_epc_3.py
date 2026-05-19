import time
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from epc import api as api_module
from epc import traffic as traffic_module
from epc.api import get_repo
from epc.db import EPCRepository
from main import app


@pytest.fixture()
def client(tmp_path):
    # Każdy test dostaje osobną bazę SQLite i czyste singletony aplikacji.
    api_module._repo_singleton = None
    traffic_module.traffic_manager = None

    repo = EPCRepository(str(tmp_path / "epc_test.db"))
    app.dependency_overrides[get_repo] = lambda: repo

    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        traffic = traffic_module.traffic_manager
        if traffic is not None:
            traffic.stop_all()
        app.dependency_overrides.clear()
        api_module._repo_singleton = None
        traffic_module.traffic_manager = None


# Sprawdza, czy attach UE tworzy domyślny bearer 9 i czy lista UEs się aktualizuje.
def test_attach_ue_creates_default_bearer_and_list_updates(client: TestClient):
    response = client.post("/ues", json={"ue_id": 12})
    assert response.status_code == 200
    assert response.json() == {"status": "attached", "ue_id": 12}

    list_response = client.get("/ues")
    assert list_response.status_code == 200
    assert list_response.json() == {"ues": [12]}

    ue_response = client.get("/ues/12")
    assert ue_response.status_code == 200
    body = ue_response.json()
    assert body["ue_id"] == 12
    assert body["bearers"]["9"]["bearer_id"] == 9
    assert body["bearers"]["9"]["active"] is False
    assert body["stats"] == {}


# Sprawdza pełny cykl start/stop traffic i to, czy statystyki rosną w tle.
def test_start_traffic_updates_stats_and_can_be_stopped(client: TestClient):
    assert client.post("/ues", json={"ue_id": 5}).status_code == 200
    assert client.post("/ues/5/bearers", json={"bearer_id": 2}).status_code == 200

    start_response = client.post(
        "/ues/5/bearers/2/traffic",
        json={"protocol": "tcp", "kbps": 64},
    )
    assert start_response.status_code == 200
    assert start_response.json()["target_bps"] == 64000

    time.sleep(1.2)

    stats_response = client.get("/ues/5/bearers/2/traffic")
    assert stats_response.status_code == 200
    stats = stats_response.json()
    assert stats["protocol"] == "tcp"
    assert stats["target_bps"] == 64000
    assert stats["tx_bps"] > 0
    assert stats["rx_bps"] > 0
    assert stats["duration"] > 0

    stop_response = client.delete("/ues/5/bearers/2/traffic")
    assert stop_response.status_code == 200
    assert stop_response.json() == {"status": "traffic_stopped", "ue_id": 5, "bearer_id": 2}

    ue_response = client.get("/ues/5")
    assert ue_response.status_code == 200
    assert ue_response.json()["bearers"]["2"]["active"] is False


# Sprawdza, czy usunięcie bearera czyści stats w repozytorium i chroni bearer 9.
def test_delete_bearer_removes_stats_and_keeps_default_bearer(client: TestClient):
    assert client.post("/ues", json={"ue_id": 21}).status_code == 200
    assert client.post("/ues/21/bearers", json={"bearer_id": 3}).status_code == 200
    assert client.post(
        "/ues/21/bearers/3/traffic",
        json={"protocol": "udp", "bps": 8000},
    ).status_code == 200

    time.sleep(1.1)

    delete_response = client.delete("/ues/21/bearers/3")
    assert delete_response.status_code == 200
    assert delete_response.json() == {"status": "bearer_deleted", "ue_id": 21, "bearer_id": 3}

    ue_response = client.get("/ues/21")
    assert ue_response.status_code == 200
    body = ue_response.json()
    assert "3" not in body["bearers"]
    assert "3" not in body["stats"]

    default_delete = client.delete("/ues/21/bearers/9")
    assert default_delete.status_code == 400
    assert default_delete.json()["detail"] == "Cannot remove default bearer"


# Sprawdza bezpośrednio repozytorium: domyślny bearer zostaje, a stats dla usuwanego bearera znikają.
def test_repository_delete_bearer_removes_stats(tmp_path):
    repo = EPCRepository(str(tmp_path / "repo_test.db"))
    repo.attach_ue(7)
    repo.add_bearer(7, 2)

    repo.update_stats(
        7,
        traffic_module.ThroughputStats(
            bearer_id=2,
            ue_id=7,
            bytes_tx=1234,
            bytes_rx=4321,
            start_ts=time.time(),
            last_update_ts=time.time(),
            protocol="tcp",
            target_bps=1000,
        ),
    )

    repo.delete_bearer(7, 2)
    state = repo.get_ue(7)
    assert 2 not in state.bearers
    assert 2 not in state.stats
    assert 9 in state.bearers


# Sprawdza bezpośrednio manager ruchu: start ma odrzucić bearer bez konfiguracji.
def test_traffic_manager_rejects_unconfigured_bearer(tmp_path):
    repo = EPCRepository(str(tmp_path / "traffic_test.db"))
    repo.attach_ue(9)
    repo.add_bearer(9, 4)

    manager = traffic_module.TrafficGeneratorManager(repo)
    state = repo.get_ue(9)
    bearer = state.bearers[4]

    with pytest.raises(ValueError, match="Bearer not configured for traffic"):
        manager.start(9, bearer)
