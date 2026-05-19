import sys
import time
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from epc import api as api_module
from epc import traffic as traffic_module
from epc.api import get_repo
from epc.db import EPCRepository
from epc.models import BearerConfig, ThroughputStats, UEState
from main import app


@pytest.fixture()
def repo(tmp_path):
    return EPCRepository(str(tmp_path / "regression_test.db"))


@pytest.fixture()
def client(repo):
    # Każdy test dostaje osobną bazę SQLite i czyste singletony aplikacji,
    # żeby stan z jednego przypadku nie wpływał na drugi.
    api_module._repo_singleton = None
    traffic_module.traffic_manager = None

    api_module._repo_singleton = repo
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


# Sprawdza spójność modelu UEState: statystyki nie powinny istnieć dla bearera,
# którego nie ma w słowniku bearers. To jest test na błąd integralności danych.
# Gdy model działa poprawnie, taka konstrukcja powinna skończyć się ValidationError.
def test_ue_state_rejects_dangling_stats():
    bearers = {
        9: BearerConfig(bearer_id=9, protocol="tcp", target_bps=100000, active=True),
    }
    dangling_stats = {
        9: ThroughputStats(
            bearer_id=9,
            ue_id=1,
            bytes_tx=500,
            bytes_rx=500,
            start_ts=time.time(),
            last_update_ts=time.time(),
            protocol="tcp",
            target_bps=100000,
        ),
        2: ThroughputStats(
            bearer_id=2,
            ue_id=1,
            bytes_tx=999,
            bytes_rx=999,
            start_ts=time.time(),
            last_update_ts=time.time(),
            protocol="tcp",
            target_bps=100000,
        ),
    }

    with pytest.raises(ValidationError, match="Dangling stats found for unattached bearer"):
        UEState(ue_id=1, bearers=bearers, stats=dangling_stats)


# Sprawdza scenariusz, w którym UE ma aktywny ruch, po czym zostaje odłączony.
# Dobry stan aplikacji powinien najpierw zatrzymać task w TrafficGeneratorManager,
# a dopiero potem usunąć rekord z bazy. W przeciwnym razie zostaje wiszący task
# próbujący dalej aktualizować stan nieistniejącego już UE.
def test_detach_ue_stops_active_traffic(client: TestClient, repo):
    assert client.post("/ues", json={"ue_id": 31}).status_code == 200
    assert client.post("/ues/31/bearers", json={"bearer_id": 4}).status_code == 200
    assert client.post(
        "/ues/31/bearers/4/traffic",
        json={"protocol": "udp", "kbps": 128},
    ).status_code == 200

    tm = traffic_module.get_traffic_manager(repo)
    assert tm.is_running(31, 4) is True

    response = client.delete("/ues/31")
    assert response.status_code == 200
    assert response.json() == {"status": "detached", "ue_id": 31}
    assert tm.is_running(31, 4) is False
