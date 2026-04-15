*** Settings ***
Documentation     Zestaw testów 16-20 zgodny ze specyfikacją OAS 3.1.
Library           ApiLibraryPython.py    http://127.0.0.1:8000
Library           Collections

*** Variables ***
${STATUS_OK}                    200
${STATUS_VALIDATION_ERROR}      422

*** Test Cases ***

Scenario: Start Traffic - Speed Over Limit
    [Tags]    TC-16    Negative
    [Documentation]    Weryfikacja błędu przy przekroczeniu 100 Mbps.
    Reset All
    Attach Ue    10
    # Próba ustawienia 110 Mbps
    Start Traffic on UE 10 Bearer 9 with 110 Mbps and expect error 422
    [Teardown]    Reset All

Scenario: Start Traffic - Bearer Not Active
    [Tags]    TC-17    Negative
    [Documentation]    Próba uruchomienia ruchu na nieaktywnym bearerze.
    Reset All
    Attach Ue    10
    Start Traffic on UE 10 Bearer 2 with 50 Mbps and expect error 422
    [Teardown]    Reset All

Scenario: Check Traffic Stats
    [Tags]    TC-18    Positive
    [Documentation]    Weryfikacja statystyk tx_bps dla 1000 kbps.
    Reset All
    Attach Ue    10
    # Startujemy ruch 1000 kbps
    Start Traffic on UE 10 Bearer 9 with 1000 kbps and expect success
    Verify Traffic on UE 10 Bearer 9 matches 1000 kbps
    [Teardown]    Reset All

Scenario: Stop Traffic for Specific Bearer
    [Tags]    TC-19    Positive
    [Documentation]    Zatrzymanie ruchu metodą DELETE.
    Reset All
    Attach Ue    10
    Start Traffic on UE 10 Bearer 9 with 1 Mbps and expect success
    Stop Traffic for UE 10 on Bearer 9 and expect success
    [Teardown]    Reset All

Scenario: Simulator Full Reset
    [Tags]    TC-20    Positive
    [Documentation]    Pełny reset symulatora przez POST /reset.
    Reset All
    Attach Ue    1
    Attach Ue    2
    Reset All
    Verify UE 1 is not in system
    Verify UE 2 is not in system
    [Teardown]    Reset All

*** Keywords ***

*** Keywords ***

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect success
    [Documentation]    Uruchamia ruch Mbps i sprawdza status 200 [cite: 768-771].
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    mbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect error ${expected_status}
    [Documentation]    Sprawdza odrzucenie ruchu Mbps (np. powyżej 100 Mbps) [cite: 772-773].
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    mbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} kbps and expect success
    [Documentation]    Uruchamia ruch kbps i sprawdza status 200 [cite: 768-771].
    ${answer}=    Start Traffic    ${ue_id}    ${bearer_id}    kbps=${val}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Verify Traffic on UE ${ue_id} Bearer ${bearer_id} matches ${expected_kbps} kbps
    [Documentation]    Weryfikacja tx_bps (przeliczenie kbps na bity) [cite: 774-778].
    ${answer}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    # Przeliczenie: 1000 kbps * 1000 = 1 000 000 bps
    ${expected_bps}=    Evaluate    ${expected_kbps} * 1000
    Should Be Equal As Integers    ${answer['body']['tx_bps']}    ${expected_bps}

Stop Traffic for UE ${ue_id} on Bearer ${bearer_id} and expect success
    [Documentation]    Zatrzymuje ruch dla konkretnego bearera metodą DELETE [cite: 779-783].
    ${answer}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}

Verify UE ${ue_id} is not in system
    [Documentation]    Weryfikacja braku zasobu (Get Ue nie powinno zwrócić 200) [cite: 803-804].
    ${answer}=    Get Ue    ${ue_id}
    Should Not Be Equal As Integers    ${answer['status']}    ${STATUS_OK}