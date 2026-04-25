*** Settings ***
Library    ApiLibraryPython.py    http://127.0.0.1:8000
Library    Collections
Test Teardown    Reset App State

*** Variables ***
${DEFAULT_BEARER_ID}          9

${STATUS_OK}                  200
${STATUS_VALIDATION_ERROR}    422
${STATUS_BAD_REQUEST}         400

*** Test Cases ***

TC-07: System Should Successfully Add Dedicated Bearer To Attached UE
    [Tags]    TC-07    Section-2    Positive
    [Documentation]    Check whether system adds a new transport channel to an attached UE correctly
    ...                Expected: System should add bearer and return code: ${STATUS_OK}
    Attach Ue    5
    Add Bearer with ID 1 to UE 5 and expect success status ${STATUS_OK}

TC-08: System Should Reject Adding Bearer When Bearer ID Is Out Of Range
    [Tags]    TC-08    Section-2    Negative
    [Documentation]    Check whether system rejects adding a bearer with an invalid ID (Range is 1-9)
    ...                Expected: System should reject adding bearer with code: ${STATUS_VALIDATION_ERROR}
    Attach Ue    5
    Add Bearer with ID 12 to UE 5 and expect error status ${STATUS_VALIDATION_ERROR}

TC-09: System Should Reject Adding Bearer When Bearer Is Already Active
    [Tags]    TC-09    Section-2    Negative
    [Documentation]    Check whether system rejects adding an already active bearer to an attached UE
    ...                Expected: System should reject adding bearer with code: ${STATUS_BAD_REQUEST}
    Attach Ue    5
    Add Bearer with ID 1 to UE 5 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 5 and expect error status ${STATUS_BAD_REQUEST}

TC-10: System Should Return List Of Active Bearers For Attached UE
    [Tags]    TC-10    Section-2    Positive
    [Documentation]    Check whether system retrieves the list of currently available bearers for a UE
    ...                Expected: System should return the active bearers for UE 5 including 1 and 9
    Attach Ue    5
    Add Bearer with ID 1 to UE 5 and expect success status ${STATUS_OK}
    Verify UE 5 has active bearers 1 and 9


*** Keywords ***

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect success status ${expected_success_status}
    [Documentation]    Adds a specific bearer to a UE and expects a success status
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    
    Should Be Equal As Strings     ${answer['body']['ue_id']}        ${ue_id}
    Should Be Equal As Strings     ${answer['body']['bearer_id']}    ${bearer_id}

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect error status ${expected_error_status}
    [Documentation]    Attempts to add a bearer and expects a specific error code
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_error_status}

Verify UE ${ue_id} has active bearers ${bearer_1} and ${bearer_2}
    [Documentation]    Checks if the UE info contains specific active bearers
    ${ue_info}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${ue_info['status']}    ${STATUS_OK}
    
    ${bearers_dict}=    Set Variable    ${ue_info['body']['bearers']}
    
    Dictionary Should Contain Key    ${bearers_dict}    ${bearer_1}
    Dictionary Should Contain Key    ${bearers_dict}    ${bearer_2}