*** Settings ***
Library    ApiLibraryPython.py    http://127.0.0.1:7777
Library    Collections

*** Variables ***
${DEFAULT_BEARER_ID}    9
${STATUS_OK}            200

*** Test Cases ***

Scenario: Add Dedicated Bearer
    [Tags]    TC-07    Positive
    [Documentation]    Verify adding a new transport channel to an attached UE.
    ...                Preconditions: UE 5 is attached (has default bearer 9).
    
    Reset App State
    Attach Ue    5

    Add Bearer with ID 1 to UE 5 and expect success
    [Teardown]    Reset App State

Scenario: Add Bearer - ID Out of Range
    [Tags]    TC-08    Negative
    [Documentation]    Verify adding a bearer with an invalid ID (Range is 1-9).
    ...                Preconditions: UE 5 is attached.
    Reset App State
    Attach Ue    5

    Add Bearer with ID 12 to UE 5 and expect error 422
    [Teardown]    Reset App State

Scenario: Add Bearer - Duplicate ID
    [Tags]    TC-09    Negative
    [Documentation]    Verify system behavior when adding an already active bearer.
    ...                Preconditions: UE 5 is attached and already has Bearer ID 1.
    Reset App State
    Attach Ue    5
    
    Add Bearer with ID 1 to UE 5 and expect success
    
    Add Bearer with ID 1 to UE 5 and expect error 400
    [Teardown]    Reset App State

Scenario: Check Active Bearers
    [Tags]    TC-10    Positive
    [Documentation]    Verify retrieving the list of currently available bearers for a UE.
    ...                Preconditions: UE 5 is attached and has Bearers 1 and 9 active.
    Reset App State
    Attach Ue    5
    Add Bearer with ID 1 to UE 5 and expect success
    
    Verify UE 5 has active bearers 1 and 9
    [Teardown]    Reset App State


*** Keywords ***

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect success
    [Documentation]    Adds a specific bearer to a UE and expects a 200 OK status
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    
    Should Be Equal As Strings     ${answer['body']['ue_id']}        ${ue_id}
    Should Be Equal As Strings     ${answer['body']['bearer_id']}    ${bearer_id}

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect error ${expected_error}
    [Documentation]    Attempts to add a bearer and expects a validation error
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_error}

Verify UE ${ue_id} has active bearers ${bearer_1} and ${bearer_2}
    [Documentation]    Checks if the UE info contains specific active bearers
    ${ue_info}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${ue_info['status']}    ${STATUS_OK}
    
    ${bearers_dict}=    Set Variable    ${ue_info['body']['bearers']}
    
    Dictionary Should Contain Key    ${bearers_dict}    ${bearer_1}
    Dictionary Should Contain Key    ${bearers_dict}    ${bearer_2}