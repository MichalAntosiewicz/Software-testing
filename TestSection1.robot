*** Settings ***
# Python api library import
Library    ApiLibraryPython.py    http://127.0.0.1:8000
Library    Collections

*** Variables ***
${DEFAULT_BEARER_ID}    9
${STATUS_OK}            200
${STATUS_VALIDATION_ERROR}    422

*** Test Cases ***
Scenario: User Should Be Able To Attach Devices Within Allowed ID Range
    [Tags]    TC-01    Positive
    [Documentation]    Checks ID value 50
    Attach to UE with ID 50 and expect success 
    [Teardown]    Reset App State

Scenario: System Should Reject Connection When Device ID Is Out Of Upper Boundary Range  
    [Tags]    TC-02    Negative
    [Documentation]    Checks ID value 101
    Attach to UE with ID 101 and expect error
    [Teardown]    Reset App State

Scenario: System Should Reject Connection When Device ID Is Out Of Lower Boundary Range  
    [Tags]    TC-03    Negative
    [Documentation]    Checks negative ID value: -1
    Attach to UE with ID -1 and expect error
    [Teardown]    Reset App State

Scenario: System Should Reject Connection To Device ID When Is Already Connected
    [Tags]    TC-04    Negative
    [Documentation]    Checks connecting device with ID that system already accepted
    ...                Expected: System should reject second enquiry with code: 422
    #firstly we expect success connection
    Attach to UE with ID 10 and expect success 
    Attach to UE with ID 10 and expect error
    [Teardown]    Reset App State


*** Keywords ***
Attach to UE with ID ${ue_id} and expect success
    [Arguments]    ${expected_bearer}=${DEFAULT_BEARER_ID}    ${expected_success_status}=${STATUS_OK}
    [Documentation]    Performs attach and verifies response and expected bearer id
    # use attach_ue() from ApiLibraryPython.py
    ${answer}=    Attach Ue    ${ue_id}    
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    Should Be Equal As Strings     ${answer['body']['ue_id']}    ${ue_id}
    
    # check if bearer id is equal to 'DEFAULT_BEARER_ID' as in documentation
    ${ue_info}=    Get Ue    ${ue_id}  #ApiLibraryPython method
    # check if response dictionary contains bearer id
    Dictionary Should Contain Key    ${ue_info['body']['bearers']}    ${expected_bearer}    msg=Error: Could not find bearer with ID ${expected_bearer} in system response
    # check bearer_id in bearers dictionary 
    Should Be Equal As Integers    ${ue_info['body']['bearers']['${expected_bearer}']['bearer_id']}    ${expected_bearer}            

Attach to UE with ID ${ue_id} and expect error
    [Arguments]    ${expected_error_status}=${STATUS_VALIDATION_ERROR}
    [Documentation]    Verifies whether system rejects connection and does not create resource
    ${answer}=    Attach Ue    ${ue_id}    
    Should Be Equal As Integers    ${answer['status']}    ${expected_error_status}  
    
    ${ue_info}=    Get Ue    ${ue_id}  #ApiLibraryPython method
    Should Be Equal As Integers    ${ue_info['status']}    ${expected_error_status}        


