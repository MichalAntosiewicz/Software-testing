*** Settings ***
Documentation     Final API Regression Suite for Simple EPC Simulator v0.1.0.
...               Validation of traffic constraints, resource lifecycle, and API specification compliance.
Library           ApiLibraryPython.py    http://127.0.0.1:8000
Library           Collections

*** Variables ***
${STATUS_OK}                    ${200}
${STATUS_BAD_REQUEST}           ${400}
${STATUS_NOT_FOUND}             ${404}
${STATUS_VALIDATION_ERROR}      ${422}

*** Test Cases ***

TC-16: Reject Traffic Execution Beyond Maximum Bandwidth Limit
    [Tags]    TrafficControl    NonFunctional
    [Documentation]    Verify enforcement of the 100 Mbps uplink/downlink ceiling per bearer.
    Reset App State
    Attach Ue    10
    Validate Traffic Request Status    10    9    110    ${STATUS_VALIDATION_ERROR}
    [Teardown]    Reset App State

TC-17: Reject Traffic Execution For Uninitialized Radio Bearer
    [Tags]    TrafficControl    Negative
    [Documentation]    Ensure the system denies data transmission on non-existent bearer contexts.
    Reset App State
    Attach Ue    10
    Validate Traffic Request Status    10    2    50    ${STATUS_VALIDATION_ERROR}
    [Teardown]    Reset App State

TC-18: Prevent Redundant Bearer Resource Allocation
    [Tags]    ResourceManagement    Robustness
    [Documentation]    Verify that duplicate Bearer ID allocation for the same UE is correctly intercepted and rejected.
    Reset App State
    Attach Ue    10
    Add Bearer    10    5
    ${response}=    Add Bearer    10    5
    Should Be Equal As Integers    ${response['status']}    ${STATUS_BAD_REQUEST}
    Should Be Equal As Strings     ${response['body']['detail']}    Bearer already exists
    [Teardown]    Reset App State

TC-19: Validate API Response Integrity For Inactive Bearer Statistics
    [Tags]    Compliance    Defect_Tracking
    [Documentation]    Check for API specification compliance. Returns FAIL if API incorrectly provides HTTP 200 for non-existent resources.
    Reset App State
    Attach Ue    10
    ${response}=    Get Traffic Stats    ${{int(10)}}    ${{int(99)}}
    Should Be Equal As Integers    ${response['status']}    ${STATUS_NOT_FOUND}
    [Teardown]    Reset App State

TC-20: Verify Global Context Erasure Post Simulator Reset
    [Tags]    Stability    Lifecycle
    [Documentation]    Confirm that all UE and bearer contexts are fully purged after a global system reset.
    Reset App State
    Attach Ue    1
    Attach Ue    2
    Reset App State
    Verify Ue Context Nonexistence    1
    Verify Ue Context Nonexistence    2
    [Teardown]    Reset App State

*** Keywords ***

Validate Traffic Request Status
    [Arguments]    ${ue_id}    ${bearer_id}    ${val}    ${expected_status}
    ${answer}=    Start Traffic    ${{int($ue_id)}}    ${{int($bearer_id)}}    mbps=${{int($val)}}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Verify Ue Context Nonexistence
    [Arguments]    ${ue_id}
    ${answer}=    Get Ue    ${{int($ue_id)}}
    Should Not Be Equal As Integers    ${answer['status']}    ${STATUS_OK}