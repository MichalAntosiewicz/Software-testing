import pytest
from pydantic import ValidationError
from epc.models import StartTrafficRequest, UEState, BearerConfig, AttachUERequest


# 1. TEST KLAS RÓWNOWAŻNOŚCI: Walidacja jednostek przepustowości
def test_traffic_request_exactly_one_throughput_enforced():
    """
    Test sprawdza zachowanie reguły wzajemnego wykluczania (XOR) dla jednostek przepustowości.
    Model StartTrafficRequest powinien wymagać zdefiniowania dokładnie jednej wartości 
    spośród: Mbps, kbps lub bps.
    """
    # Przypadek poprawny: zdefiniowana tylko jedna jednostka
    req = StartTrafficRequest(protocol="tcp", Mbps=10.0)
    assert req.Mbps == 10.0

    # Przypadek niepoprawny: brak zdefiniowanej przepustowości
    with pytest.raises(ValidationError) as exc_info:
        StartTrafficRequest(protocol="udp")
    assert "Provide exactly one throughput value" in str(exc_info.value)

    # Przypadek niepoprawny: konflikt (zdefiniowane dwie jednostki jednocześnie)
    with pytest.raises(ValidationError) as exc_info:
        StartTrafficRequest(protocol="tcp", Mbps=2.0, bps=2000)
    assert "Provide exactly one throughput value" in str(exc_info.value)


# 2. TEST LOGIKI MATEMATYCZNEH: Normalizacja jednostek do bitów na sekundę
def test_traffic_request_target_bps_normalization():
    """
    Weryfikacja poprawności obliczeń metody target_bps() przeliczającej 
    wartości typu float na kanoniczną wartość całkowitą (bps).
    """
    # Konwersja Mbps -> bps (1.5 Mbps = 1 500 000 bps)
    req_mbps = StartTrafficRequest(protocol="tcp", Mbps=1.5)
    assert req_mbps.target_bps() == 1500000

    # Konwersja kbps -> bps (250 kbps = 250 000 bps)
    req_kbps = StartTrafficRequest(protocol="udp", kbps=250.0)
    assert req_kbps.target_bps() == 250000

    # Brak konwersji dla bazowej jednostki bps
    req_bps = StartTrafficRequest(protocol="tcp", bps=9600)
    assert req_bps.target_bps() == 9600


# 3. TEST WARTOŚCI BRZEGOWYCH: Identyfikatory urządzeń (UE ID)
def test_ue_id_boundary_analysis():
    """
    Analiza wartości brzegowych (Boundary Value Analysis) przedziału identyfikatorów UE ID [1..100].
    """
    # Punkty wewnątrz i na granicach przedziału
    assert AttachUERequest(ue_id=1).ue_id == 1
    assert AttachUERequest(ue_id=50).ue_id == 50
    assert AttachUERequest(ue_id=100).ue_id == 100

    # Wartość poniżej dopuszczalnego minimum (0)
    with pytest.raises(ValidationError):
        AttachUERequest(ue_id=0)

    # Wartość powyżej dopuszczalnego maksimum (101)
    with pytest.raises(ValidationError):
        AttachUERequest(ue_id=101)


# 4. TEST WARTOŚCI BRZEGOWYCH: Identyfikatory połączeń (Bearer ID)
def test_bearer_id_boundary_analysis():
    """
    Analiza wartości brzegowych (Boundary Value Analysis) przedziału Bearer ID [1..9].
    """
    # Granice przedziału dopuszczalnego
    assert BearerConfig(bearer_id=1).bearer_id == 1
    assert BearerConfig(bearer_id=9).bearer_id == 9

    # Wartości spoza przedziału dopuszczalnego
    with pytest.raises(ValidationError):
        BearerConfig(bearer_id=0)
    with pytest.raises(ValidationError):
        BearerConfig(bearer_id=10)


# 5. TEST INTEGRALNOŚCI: Inicjalizacja domyślnych struktur danych (Validator Before)
def test_ue_state_initialization_safeguards():
    """
    Weryfikacja działania walidatora 'before' inicjalizującego puste kolekcje,
    w sytuacji gdy do modelu zostanie przekazana jawna wartość None.
    """
    raw_data = {
        "ue_id": 10,
        "bearers": None,
        "stats": None
    }
    
    state = UEState.model_validate(raw_data)
    
    assert state.bearers == {}
    assert state.stats == {}
    assert isinstance(state.bearers, dict)
    assert isinstance(state.stats, dict)


# 6. TEST INTEGRALNOŚCI STANÓW: Spójność relacji między Bearers a Stats
def test_developer_ue_state_bearer_and_stats_consistency_bug():
    """
    Weryfikacja spójności danych strukturalnych obiektu UEState z perspektywy dewelopera.
    Test sprawdza relację stanów agregatu w sytuacji, gdy określony Bearer ID 
    nie został poprawnie zamontowany w słowniku 'bearers', ale model inicjalizuje
    dla niego rekord statystyk w słowniku 'stats'.
    """
    from epc.models import UEState, BearerConfig, ThroughputStats

    # Konfiguracja stanu urządzenia: zarejestrowany wyłącznie domyślny bearer o ID 9
    attached_bearers = {
        9: BearerConfig(bearer_id=9, protocol="tcp", target_bps=100000, active=True)
    }
    
    # Inicjalizacja struktur statystyk zawierająca rekord dla niezałączonego bearera o ID 2
    corrupted_stats = {
        9: ThroughputStats(bearer_id=9, ue_id=1, bytes_tx=500, bytes_rx=500),
        2: ThroughputStats(bearer_id=2, ue_id=1, bytes_tx=99999, bytes_rx=99999)
    }

    # Budowanie agregatu danych - oczekiwane rzucenie ValidationError ze względu na
    # obecność osieroconych statystyk dla nienależącego do sesji identyfikatora połączenia.
    with pytest.raises(ValidationError, match="Dangling stats found for unattached bearer"):
        UEState(
            ue_id=1,
            bearers=attached_bearers,
            stats=corrupted_stats
        )