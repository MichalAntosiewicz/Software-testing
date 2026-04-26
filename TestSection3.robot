*** Settings ***
# Python api library import
Library    ApiLibraryPython.py    http://127.0.0.1:8000
Library    Collections

*** Variables ***
${DEFAULT_BEARER_ID}    9
${STATUS_OK}            200
${STATUS_ERROR}         400

*** Test Cases ***
Scenario: System Should Allow To Remove Dedicated Bearer From Attached UE
    [Tags]    TC-11    Positive
    [Documentation]    Checks removal of bearer 2 for UE 5 [cite: 183, 184]
    Attach to UE with ID 5 and expect success
    Add dedicated bearer 2 to UE 5
    Remove bearer 2 from UE 5 and expect success
    [Teardown]    Reset App State

Scenario: System Should Reject Removal Of Default Bearer
    [Tags]    TC-12    Negative
    [Documentation]    Checks if bearer 9 is protected [cite: 193, 194]
    Attach to UE with ID 5 and expect success
    Remove bearer 9 from UE 5 and expect error
    [Teardown]    Reset App State

Scenario: System Should Reject Removal Of Bearer That Is Not Active
    [Tags]    TC-13    Negative
    [Documentation]    Checks removal of non-existent bearer 3 [cite: 204, 205]
    Attach to UE with ID 5 and expect success
    Remove bearer 3 from UE 5 and expect error
    [Teardown]    Reset App State

Scenario: System Should Reject Removal Of Bearer When ID Is Out Of Range
    [Tags]    TC-14    Negative
    [Documentation]    Checks removal of bearer 15 (limit 1-9) [cite: 215, 217]
    Attach to UE with ID 5 and expect success
    Remove bearer 15 from UE 5 and expect error
    [Teardown]    Reset App State

Scenario: User Should Be Able To Start Downlink Data Transfer
    [Tags]    TC-15    Positive    Transfer
    [Documentation]    Checks 50 Mbps DL transfer for UE 10 [cite: 227, 233]
    Attach to UE with ID 10 and expect success
    Start 50 Mbps traffic on bearer 9 for UE 10 and expect success
    [Teardown]    Reset App State


*** Keywords ***
Attach to UE with ID ${ue_id} and expect success
    [Arguments]    ${expected_bearer}=${DEFAULT_BEARER_ID}    ${expected_success_status}=${STATUS_OK}
    [Documentation]    Performs attach and verifies response and default bearer [cite: 88, 96]
    ${answer}=    Attach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    Should Be Equal As Strings     ${answer['body']['ue_id']}    ${ue_id}
    # Check if default bearer 9 exists [cite: 20]
    ${ue_info}=    Get Ue    ${ue_id}
    Dictionary Should Contain Key    ${ue_info['body']['bearers']}    ${expected_bearer}

Add dedicated bearer ${bearer_id} to UE ${ue_id}
    [Documentation]    Adds a new bearer to UE [cite: 144, 152]
    ${res}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${res['status']}    ${STATUS_OK}

Remove bearer ${bearer_id} from UE ${ue_id} and expect success
    [Documentation]    Removes bearer and checks status 'bearer_deleted' [cite: 183, 192]
    ${res}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${res['status']}    ${STATUS_OK}
    Should Be Equal As Strings     ${res['body']['status']}    bearer_deleted

Remove bearer ${bearer_id} from UE ${ue_id} and expect error
    [Arguments]    ${expected_error_status}=${STATUS_ERROR}
    [Documentation]    Verifies rejection of bearer removal [cite: 193, 204, 215]
    ${res}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${res['status']}    ${expected_error_status}

Start 50 Mbps traffic on bearer ${bearer_id} for UE ${ue_id} and expect success
    [Documentation]    Starts DL traffic and verifies 'traffic_started' [cite: 227, 235]
    ${res}=    Start Traffic MB    ${ue_id}    ${bearer_id}    50
    Should Be Equal As Integers    ${res['status']}    ${STATUS_OK}
    Should Be Equal As Strings     ${res['body']['status']}    traffic_started