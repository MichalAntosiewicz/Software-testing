import time
 
import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
 
from epc import api as api_module
from epc import traffic as traffic_module
from epc.api import get_repo
from epc.db import EPCRepository
from epc.models import BearerConfig, ThroughputStats
from main import app

@pytest.fixture()
def repo(tmp_path):
    """Isolated in-memory SQLite repo per test — no shared state."""
    return EPCRepository(str(tmp_path / "test.db"))
 
 
@pytest.fixture()
def client(repo):
    """FastAPI test client wired to the isolated repo; stops all traffic after each test."""
    api_module._repo_singleton = None
    traffic_module.traffic_manager = None
 
    app.dependency_overrides[get_repo] = lambda: repo
 
    try:
        with TestClient(app) as tc:
            yield tc
    finally:
        tm = traffic_module.traffic_manager
        if tm is not None:
            tm.stop_all()
        app.dependency_overrides.clear()
        api_module._repo_singleton = None
        traffic_module.traffic_manager = None

# models.py

class TestBearerConfigProtocol:
    def test_valid_protocols_accepted(self):
        """tcp and udp are the only accepted protocol strings."""
        assert BearerConfig(bearer_id=1, protocol="tcp").protocol == "tcp"
        assert BearerConfig(bearer_id=1, protocol="udp").protocol == "udp"
 
    def test_invalid_protocol_rejected(self):
        """Any string outside tcp/udp must raise ValidationError."""
        with pytest.raises(ValidationError):
            BearerConfig(bearer_id=1, protocol="http")
 
    def test_protocol_defaults_to_none(self):
        """Protocol is optional; omitting it should produce None, not an error."""
        assert BearerConfig(bearer_id=1).protocol is None


# db.py

class TestEPCRepositoryDirect:
    def test_list_ues_returns_multiple_ids_in_ascending_order(self, repo):
        """list_ues must yield every attached UE in ascending order, not insertion order."""
        repo.attach_ue(7)
        repo.attach_ue(1)
        repo.attach_ue(3)
        assert list(repo.list_ues()) == [1, 3, 7]
 
    def test_save_ue_overwrites_existing_record(self, repo):
        """save_ue uses INSERT OR REPLACE, so a second call must overwrite the first."""
        repo.attach_ue(10)
        state = repo.get_ue(10)
        state.bearers[5] = BearerConfig(bearer_id=5)
        repo.save_ue(state)
        assert 5 in repo.get_ue(10).bearers
 
    def test_update_bearer_persists_all_fields(self, repo):
        """update_bearer must write protocol, target_bps, and active back to the db."""
        repo.attach_ue(20)
        repo.add_bearer(20, 3)
        state = repo.get_ue(20)
        bearer = state.bearers[3]
        bearer.protocol = "udp"
        bearer.target_bps = 500_000
        bearer.active = True
        repo.update_bearer(20, bearer)
 
        saved = repo.get_ue(20).bearers[3]
        assert saved.protocol == "udp"
        assert saved.target_bps == 500_000
        assert saved.active is True
 
    def test_reset_all_leaves_database_empty(self, repo):
        """reset_all must remove every UE; list_ues should return nothing afterwards."""
        for uid in (1, 2, 3):
            repo.attach_ue(uid)
        repo.reset_all()
        assert list(repo.list_ues()) == []
 
    def test_add_bearer_duplicate_raises_value_error(self, repo):
        """Calling add_bearer with an ID that already exists must raise ValueError.
        (Existing tests check this via the API; this hits the repo layer directly.)"""
        repo.attach_ue(15)
        repo.add_bearer(15, 4)
        with pytest.raises(ValueError, match="Bearer already exists"):
            repo.add_bearer(15, 4)
 
    def test_get_ue_missing_raises_value_error(self, repo):
        """get_ue on a UE that was never attached must raise ValueError."""
        with pytest.raises(ValueError, match="UE not found"):
            repo.get_ue(99)
 
    def test_detach_ue_missing_raises_value_error(self, repo):
        """detach_ue on a UE that was never attached must raise ValueError."""
        with pytest.raises(ValueError, match="UE not found"):
            repo.detach_ue(99)

# traffic.py

class TestTrafficGeneratorManager:
    def test_stop_all_cancels_every_running_task(self, repo):
        """stop_all must cancel all futures and leave tasks dict empty."""
        repo.attach_ue(1)
        repo.add_bearer(1, 2)
        repo.add_bearer(1, 3)
        for bid in (2, 3):
            repo.update_bearer(1, BearerConfig(bearer_id=bid, protocol="tcp", target_bps=64_000, active=True))
 
        mgr = traffic_module.TrafficGeneratorManager(repo)
        state = repo.get_ue(1)
        mgr.start(1, state.bearers[2])
        mgr.start(1, state.bearers[3])
        assert mgr.is_running(1, 2) and mgr.is_running(1, 3)
 
        mgr.stop_all()
 
        assert not mgr.is_running(1, 2)
        assert not mgr.is_running(1, 3)
        assert mgr.tasks == {}
 
    def test_double_start_same_bearer_raises_value_error(self, repo):
        """Starting traffic on a bearer that is already running must raise ValueError."""
        repo.attach_ue(2)
        repo.add_bearer(2, 1)
        repo.update_bearer(2, BearerConfig(bearer_id=1, protocol="udp", target_bps=32_000, active=True))
 
        mgr = traffic_module.TrafficGeneratorManager(repo)
        mgr.start(2, repo.get_ue(2).bearers[1])
        with pytest.raises(ValueError, match="Traffic already running"):
            mgr.start(2, repo.get_ue(2).bearers[1])
        mgr.stop_all()
 
    def test_is_running_returns_false_after_stop(self, repo):
        """is_running must return False as soon as stop() is called."""
        repo.attach_ue(3)
        repo.add_bearer(3, 1)
        repo.update_bearer(3, BearerConfig(bearer_id=1, protocol="tcp", target_bps=8_000, active=True))
 
        mgr = traffic_module.TrafficGeneratorManager(repo)
        mgr.start(3, repo.get_ue(3).bearers[1])
        assert mgr.is_running(3, 1)
        mgr.stop(3, 1)
        assert not mgr.is_running(3, 1)
 
    def test_stop_on_non_running_bearer_does_not_raise(self, repo):
        """stop() on a bearer that was never started must be a safe no-op."""
        mgr = traffic_module.TrafficGeneratorManager(repo)
        mgr.stop(99, 99)  # no exception expected

# api.py

class TestAPIErrorPaths:
    def test_attach_duplicate_ue_returns_400(self, client):
        client.post("/ues", json={"ue_id": 10})
        resp = client.post("/ues", json={"ue_id": 10})
        assert resp.status_code == 400
        assert "already attached" in resp.json()["detail"]
 
    def test_get_nonexistent_ue_returns_400(self, client):
        resp = client.get("/ues/55")
        assert resp.status_code == 400
 
    def test_detach_nonexistent_ue_returns_400(self, client):
        resp = client.delete("/ues/55")
        assert resp.status_code == 400
 
    def test_add_bearer_to_nonexistent_ue_returns_400(self, client):
        resp = client.post("/ues/99/bearers", json={"bearer_id": 3})
        assert resp.status_code == 400
 
    def test_add_duplicate_bearer_returns_400(self, client):
        client.post("/ues", json={"ue_id": 10})
        client.post("/ues/10/bearers", json={"bearer_id": 3})
        resp = client.post("/ues/10/bearers", json={"bearer_id": 3})
        assert resp.status_code == 400
 
    def test_delete_bearer_nonexistent_ue_returns_400(self, client):
        resp = client.delete("/ues/99/bearers/1")
        assert resp.status_code == 400
 
    def test_delete_nonexistent_bearer_returns_400(self, client):
        client.post("/ues", json={"ue_id": 10})
        resp = client.delete("/ues/10/bearers/5")
        assert resp.status_code == 400
 
    def test_start_traffic_nonexistent_ue_returns_400(self, client):
        resp = client.post("/ues/99/bearers/1/traffic", json={"protocol": "tcp", "kbps": 64})
        assert resp.status_code == 400
 
    def test_start_traffic_nonexistent_bearer_returns_400(self, client):
        client.post("/ues", json={"ue_id": 10})
        resp = client.post("/ues/10/bearers/5/traffic", json={"protocol": "tcp", "kbps": 64})
        assert resp.status_code == 400
 
    def test_stop_traffic_nonexistent_ue_returns_400(self, client):
        resp = client.delete("/ues/99/bearers/1/traffic")
        assert resp.status_code == 400
 
    def test_stop_traffic_nonexistent_bearer_returns_400(self, client):
        client.post("/ues", json={"ue_id": 10})
        resp = client.delete("/ues/10/bearers/5/traffic")
        assert resp.status_code == 400
 
    def test_get_traffic_stats_nonexistent_ue_returns_400(self, client):
        resp = client.get("/ues/99/bearers/1/traffic")
        assert resp.status_code == 400

class TestAggregatedStats:
    def test_empty_repo_returns_all_zeros(self, client):
        resp = client.get("/ues/stats")
        assert resp.status_code == 200
        data = resp.json()
        assert data["scope"] == "all"
        assert data["ue_count"] == 0
        assert data["bearer_count"] == 0
        assert data["total_tx_bps"] == 0
        assert data["total_rx_bps"] == 0
        assert data["details"] is None

    def test_bearer_count_sums_across_all_ues(self, client):
        """bearer_count reflects only bearers that have traffic stats records,
        not all attached bearers. Bearers with no traffic history are not counted."""
        client.post("/ues", json={"ue_id": 1})
        client.post("/ues", json={"ue_id": 2})
        client.post("/ues/2/bearers", json={"bearer_id": 3})

        data = client.get("/ues/stats").json()
        assert data["ue_count"] == 2
        assert data["bearer_count"] == 0
 
    def test_ue_id_filter_scopes_response(self, client):
        """?ue_id=5 should narrow scope and set the scope field to 'ue:5'."""
        client.post("/ues", json={"ue_id": 5})
        client.post("/ues", json={"ue_id": 6})
 
        data = client.get("/ues/stats?ue_id=5").json()
        assert data["scope"] == "ue:5"
        assert data["ue_count"] == 1
 
    def test_ue_id_filter_nonexistent_returns_400(self, client):
        resp = client.get("/ues/stats?ue_id=99")
        assert resp.status_code == 400
 
    def test_include_details_false_by_default(self, client):
        client.post("/ues", json={"ue_id": 1})
        assert client.get("/ues/stats").json()["details"] is None
 
    def test_include_details_true_returns_dict(self, client):
        client.post("/ues", json={"ue_id": 1})
        data = client.get("/ues/stats?include_details=true").json()
        assert isinstance(data["details"], dict)
 
    def test_active_traffic_produces_nonzero_bps(self, client):
        """After >1 s of traffic the aggregated bps values must be positive."""
        client.post("/ues", json={"ue_id": 7})
        client.post("/ues/7/bearers", json={"bearer_id": 2})
        client.post("/ues/7/bearers/2/traffic", json={"protocol": "tcp", "kbps": 64})
        time.sleep(1.2)
 
        data = client.get("/ues/stats?ue_id=7").json()
        assert data["total_tx_bps"] > 0
        assert data["total_rx_bps"] > 0
 
    def test_include_details_with_active_traffic_contains_bearer_entry(self, client):
        """details[ue_id][bearer_id] must exist when that bearer has active traffic."""
        client.post("/ues", json={"ue_id": 8})
        client.post("/ues/8/bearers", json={"bearer_id": 2})
        client.post("/ues/8/bearers/2/traffic", json={"protocol": "udp", "kbps": 128})
        time.sleep(1.2)
 
        details = client.get("/ues/stats?include_details=true").json()["details"]
        assert "8" in details
        assert "2" in details["8"]
 
    def test_reset_endpoint_wipes_all_ues(self, client):
        """POST /reset must stop all traffic, remove all UEs, and return status=reset."""
        client.post("/ues", json={"ue_id": 1})
        client.post("/ues", json={"ue_id": 2})
 
        resp = client.post("/reset")
        assert resp.status_code == 200
        assert resp.json() == {"status": "reset"}
        assert client.get("/ues").json() == {"ues": []}