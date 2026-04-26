*** Settings ***
Library    ApiLibraryPython2.py    http://127.0.0.1:8000
Library    Collections
Test Teardown    Reset App State

*** Variables ***
${DEFAULT_BEARER_ID}          9
${STATUS_OK}                  200
${STATUS_VALIDATION_ERROR}    422
${STATUS_BAD_REQUEST}         400
${STATUS_NOT_FOUND}           404

*** Test Cases ***
TC-26: Reattaching UE Should Restore Clean Bearer Context
    [Tags]    TC-26    Section-5    Positive
    [Documentation]    Verify that detach clears all dedicated bearer state and a reattach creates a fresh context.
    Reset App State
    Attach UE with ID 7 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 7 and expect success status ${STATUS_OK}
    Detach UE with ID 7 and expect success status ${STATUS_OK}
    Attach UE with ID 7 and expect success status ${STATUS_OK}
    Verify UE 7 has only bearer ${DEFAULT_BEARER_ID}

TC-27: Adding Bearer To Detached UE Should Be Rejected
    [Tags]    TC-27    Section-5    Negative
    [Documentation]    Verify that bearer creation is blocked once a UE has been detached.
    Reset App State
    Attach UE with ID 8 and expect success status ${STATUS_OK}
    Detach UE with ID 8 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 8 and expect error status ${STATUS_BAD_REQUEST}

TC-28: Starting Traffic On Inactive Bearer Should Fail
    [Tags]    TC-28    Section-5    Negative
    [Documentation]    Verify that traffic cannot start on a bearer that is not active for the UE.
    Reset App State
    Attach UE with ID 10 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 10 and expect success status ${STATUS_OK}
    Start Traffic on UE 10 Bearer 2 with 20 Mbps and expect error ${STATUS_BAD_REQUEST}
    Verify UE 10 does not contain bearer 2

TC-29: Stopping One Bearer Should Not Affect Another Active Bearer
    [Tags]    TC-29    Section-5    Positive    Traffic
    [Documentation]    Verify traffic isolation between bearer contexts within the same UE.
    Reset App State
    Attach UE with ID 11 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 11 and expect success status ${STATUS_OK}
    Start Traffic on UE 11 Bearer 9 with 10 Mbps and expect success ${STATUS_OK}
    Start Traffic on UE 11 Bearer 1 with 15 Mbps and expect success ${STATUS_OK}
    Stop Traffic on UE 11 Bearer 1 and expect success ${STATUS_OK}
    Verify Traffic on UE 11 Bearer 9 is active

TC-32: Stopping One Bearer Should Clear Its Traffic Context
    [Tags]    TC-32    Section-5    Negative    Traffic
    [Documentation]    Verify that stopping traffic removes the bearer traffic context as described in the documentation.
    Reset App State
    Attach UE with ID 11 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 11 and expect success status ${STATUS_OK}
    Start Traffic on UE 11 Bearer 1 with 15 Mbps and expect success ${STATUS_OK}
    Stop Traffic on UE 11 Bearer 1 and expect success ${STATUS_OK}
    Check if traffic on UE 11 Bearer 1 is stopped



TC-31: Reset Should Remove Every UE Context
    [Tags]    TC-31    Section-5    Stability
    [Documentation]    Verify that reset removes all previously attached UEs and their bearer state.
    Reset App State
    Attach UE with ID 1 and expect success status ${STATUS_OK}
    Attach UE with ID 2 and expect success status ${STATUS_OK}
    Add Bearer with ID 1 to UE 1 and expect success status ${STATUS_OK}
    Add Bearer with ID 2 to UE 2 and expect success status ${STATUS_OK}
    Reset App State
    ${response_1}=    Get Ue    1
    ${response_2}=    Get Ue    2
    Should Not Be Equal As Integers    ${response_1['status']}    ${STATUS_OK}
    Should Not Be Equal As Integers    ${response_2['status']}    ${STATUS_OK}

*** Keywords ***
Attach UE with ID ${ue_id} and expect success status ${expected_success_status}
    [Arguments]    ${expected_bearer}=${DEFAULT_BEARER_ID}
    [Documentation]    Performs attach and verifies response and expected bearer id.
    ${answer}=    Attach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    Should Be Equal As Strings     ${answer['body']['ue_id']}    ${ue_id}
    ${ue_info}=    Get Ue    ${ue_id}
    Dictionary Should Contain Key    ${ue_info['body']['bearers']}    ${expected_bearer}    msg=Error: Could not find bearer with ID ${expected_bearer} in system response
    Should Be Equal As Integers    ${ue_info['body']['bearers']['${expected_bearer}']['bearer_id']}    ${expected_bearer}

Detach UE with ID ${ue_id} and expect success status ${expected_success_status}
    [Documentation]    Verifies whether system correctly detaches UE.
    ${answer}=    Detach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    ${get_ue_answer}=    Get Ue    ${ue_id}
    Should Not Be Equal As Integers    ${get_ue_answer['status']}    ${STATUS_OK}

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect success status ${expected_success_status}
    [Documentation]    Adds a specific bearer to a UE and expects a success status.
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    Should Be Equal As Strings     ${answer['body']['ue_id']}        ${ue_id}
    Should Be Equal As Strings     ${answer['body']['bearer_id']}    ${bearer_id}

Add Bearer with ID ${bearer_id} to UE ${ue_id} and expect error status ${expected_error_status}
    [Documentation]    Attempts to add a bearer and expects a specific error code.
    ${answer}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_error_status}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect success ${expected_status}
    ${answer}=    Start Traffic Mb    ${ue_id}    ${bearer_id}    ${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect error ${expected_status}
    ${answer}=    Start Traffic Mb    ${ue_id}    ${bearer_id}    ${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Stop Traffic on UE ${ue_id} Bearer ${bearer_id} and expect success ${expected_status}
    ${answer}=    Stop Traffic    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Stop All Traffic On UE ${ue_id} and expect success ${expected_status}
    [Documentation]    Tries to stop all traffic for UE without specifying bearer_id.
    ${answer}=    Stop All Traffic    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Check if traffic on UE ${ue_id} Bearer ${bearer_id} is stopped
    ${answer}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['ue_id']}        ${ue_id}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['bearer_id']}    ${bearer_id}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['tx_bps']}    0
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['rx_bps']}    0
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['duration']}  0
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${answer['body']['protocol']}    None
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${answer['body']['target_bps']}  None

Verify Traffic on UE ${ue_id} Bearer ${bearer_id} is active
    ${answer}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    Should Be Equal As Integers    ${answer['body']['ue_id']}    ${ue_id}
    Should Be Equal As Integers    ${answer['body']['bearer_id']}    ${bearer_id}
    Should Not Be Equal As Integers    ${answer['body']['tx_bps']}    0

Verify UE ${ue_id} has only bearer ${bearer_id}
    ${ue_info}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${ue_info['status']}    ${STATUS_OK}
    ${bearers_count}=    Evaluate    len($ue_info['body']['bearers'])
    Dictionary Should Contain Key    ${ue_info['body']['bearers']}    ${bearer_id}
    Should Be Equal As Integers    ${bearers_count}    1

Verify UE ${ue_id} does not contain bearer ${bearer_id}
    ${ue_info}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${ue_info['status']}    ${STATUS_OK}
    Dictionary Should Not Contain Key    ${ue_info['body']['bearers']}    ${bearer_id}
