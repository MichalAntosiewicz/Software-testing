*** Settings ***
Documentation     Scenariusze testowe 16-20 zgodne ze specyfikacją OAS 3.1 i Twoją listą.
Library           ApiLibraryPython.py    http://127.0.0.1:8000
Library           Collections

*** Variables ***
${STATUS_OK}                    200
${STATUS_VALIDATION_ERROR}      422

*** Test Cases ***

Scenario: Start Transfer – Speed Over Limit
    [Tags]    TC-16    Negative
    [Documentation]    Weryfikacja odrzucenia transferu powyżej 100 Mbps.
    Reset App State
    Attach Ue    10
    # Oczekujemy 422 dla błędnego zakresu (110 Mbps)
    Start Traffic on UE 10 Bearer 9 with 110 Mbps and expect error 422
    [Teardown]    Reset App State

Scenario: Start Transfer – Bearer Not Active
    [Tags]    TC-17    Negative
    [Documentation]    Próba uruchomienia ruchu na nieistniejącym bearerze[cite: 773].
    Reset App State
    Attach Ue    10
    # Oczekujemy 422, ponieważ Bearer 2 nie został dodany
    Start Traffic on UE 10 Bearer 2 with 50 Mbps and expect error 422
    [Teardown]    Reset App State

Scenario: Check Transfer (Default Units)
    [Tags]    TC-18    Positive
    [Documentation]    Weryfikacja statystyk w jednostkach kbps[cite: 778].
    Reset App State
    Attach Ue    10
    # Uruchomienie transferu (Prekondycja dla sprawdzenia statystyk)
    Start Traffic on UE 10 Bearer 9 with 1000 kbps and expect success
    # Sprawdzenie czy tx_bps wynosi 1 000 000 (1000 kbps)
    Verify Traffic on UE 10 Bearer 9 matches 1000 kbps
    [Teardown]    Reset App State

Scenario: Stop Data Transfer (Total for UE)
    [Tags]    TC-19    Positive
    [Documentation]    Zatrzymanie ruchu dla UE (zgodnie z Twoją funkcją stop_data_transfer)[cite: 783].
    Reset App State
    Attach Ue    10
    Start Traffic on UE 10 Bearer 9 with 1 Mbps and expect success
    # Wywołanie Twojej funkcji stop_data_transfer bez podawania bearer_id
    Stop all transfers for UE 10 and expect success
    [Teardown]    Reset App State

Scenario: Simulator Reset
    [Tags]    TC-20    Positive
    [Documentation]    Weryfikacja powrotu symulatora do stanu początkowego[cite: 804].
    Reset App State
    Attach Ue    1
    Attach Ue    2
    # Resetowanie stanu aplikacji [cite: 803-804]
    Reset App State
    Verify UE 1 is not in system
    Verify UE 2 is not in system
    [Teardown]    Reset App State

*** Keywords ***

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect success
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    mbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect error ${expected_status}
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    mbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} kbps and expect success
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    kbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Verify Traffic on UE ${ue_id} Bearer ${bearer_id} matches ${expected_kbps} kbps
    ${answer}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    # Przeliczenie kbps na bps: 1000 * 1000 = 1 000 000 bps
    ${expected_bps}=    Evaluate    ${expected_kbps} * 1000
    Should Be Equal As Integers    ${answer['body']['tx_bps']}    ${expected_bps}

Stop all transfers for UE ${ue_id} and expect success
    # Wywołanie Twojej funkcji stop_data_transfer bez bearer_id [cite: 313-315]
    ${answer}=    Stop Data Transfer    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Verify UE ${ue_id} is not in system
    ${answer}=    Get Ue    ${ue_id}
    Should Not Be Equal As Integers    ${answer['status']}    ${STATUS_OK}