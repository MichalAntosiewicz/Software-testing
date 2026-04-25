*** Settings ***
Documentation     API Regression Testing Suite for Simple EPC Simulator 0.1.0.
...               Focus areas: Traffic management validation and logical consistency (SUS analysis).
Library           ApiLibraryPython.py    http://127.0.0.1:8000
Library           Collections

*** Variables ***
${STATUS_OK}                    ${200}
${STATUS_BAD_REQUEST}           ${400}
${STATUS_NOT_FOUND}             ${404}
${STATUS_VALIDATION_ERROR}      ${422}

*** Test Cases ***

TC-16: Reject Traffic Execution Beyond Maximum Bandwidth Limit
    [Tags]    Traffic    Negative
    [Documentation]    Verify that the system rejects traffic requests exceeding the 100 Mbps threshold.
    Reset App State
    Attach Ue    10
    Execute Bandwidth Validation    10    9    110    ${STATUS_VALIDATION_ERROR}
    [Teardown]    Reset App State

TC-17: Reject Traffic Execution For Non-Existent Radio Bearer
    [Tags]    Traffic    Negative
    [Documentation]    Ensure system prevents data transfer on a bearer ID that has not been initialized.
    Reset App State
    Attach Ue    10
    Execute Bandwidth Validation    10    2    50    ${STATUS_VALIDATION_ERROR}
    [Teardown]    Reset App State

TC-18: Logical Validation of Bearer Resource Allocation
    [Tags]    ResourceManagement    SUS
    [Documentation]    Verification of the system's ability to handle duplicate bearer resource requests.
    Reset App State
    Attach Ue    10
    Add Bearer    10    5
    ${response}=    Add Bearer    10    5
    Should Be Equal As Integers    ${response['status']}    ${STATUS_BAD_REQUEST}
    Should Be Equal As Strings     ${response['body']['detail']}    Bearer already exists
    [Teardown]    Reset App State

TC-19: Evaluation of API Consistency For Inactive Bearer Statistics
    [Tags]    Statistics    SUS    Known_Issue
    [Documentation]    Identify logical inconsistency where API returns HTTP 200 for non-existent bearer stats.
    Reset App State
    Attach Ue    10
    ${response}=    Get Traffic Stats    ${{int(10)}}    ${{int(99)}}
    Should Be Equal As Integers    ${response['status']}    ${STATUS_OK}
    Should Be Equal As Integers    ${response['body']['tx_bps']}    0
    [Teardown]    Reset App State

TC-20: System State Integrity Post Global Reset
    [Tags]    System    Positive
    [Documentation]    Validate complete removal of UE contexts after invoking the global reset procedure.
    Reset App State
    Attach Ue    1
    Attach Ue    2
    Reset App State
    Verify Context Erasure    1
    Verify Context Erasure    2
    [Teardown]    Reset App State

*** Keywords ***

Execute Bandwidth Validation
    [Arguments]    ${ue_id}    ${bearer_id}    ${val}    ${expected_status}
    ${answer}=    Start Traffic    ${{int($ue_id)}}    ${{int($bearer_id)}}    mbps=${{int($val)}}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

Verify Context Erasure
    [Arguments]    ${ue_id}
    ${answer}=    Get Ue    ${{int($ue_id)}}
    Should Not Be Equal As Integers    ${answer['status']}    ${STATUS_OK}