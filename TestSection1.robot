*** Settings ***
# Python api library import
Library    ApiLibraryPython.py    http://127.0.0.1:8000
Library    Collections
Test Teardown    Reset App State

*** Variables ***
# App parameters
${DEFAULT_BEARER_ID}          9

# Status codes
${STATUS_OK}                  200
${STATUS_VALIDATION_ERROR}    422
${STATUS_BAD_REQUEST}         400

*** Test Cases ***
TC-01: User Should Be Able To Attach Devices Within Allowed ID Range
    [Tags]    TC-01    Section-1    Positive
    [Documentation]    Check whether system attaches device correctly with ID in correct range
    ...                Expected: System should connect device with code: ${STATUS_OK} 
    Run Keyword And Continue On Failure    Attach UE with ID 0 and expect success status ${STATUS_OK}    
    Run Keyword And Continue On Failure    Attach UE with ID 10 and expect success status ${STATUS_OK}  
    Run Keyword And Continue On Failure    Attach UE with ID 50 and expect success status ${STATUS_OK}  
    Run Keyword And Continue On Failure    Attach UE with ID 100 and expect success status ${STATUS_OK}  

TC-02: System Should Reject Connection When Device ID Is Out Of Upper Boundary Range  
    [Tags]    TC-02    Section-1    Negative
    [Documentation]    Check whether system rejects device connection correctly with ID out of upper boundary range
    ...                Expected: System should reject device connection with code: ${STATUS_VALIDATION_ERROR}
    Attach UE with ID 101 and expect error status ${STATUS_VALIDATION_ERROR} 
    Attach UE with ID -1 and expect error status ${STATUS_VALIDATION_ERROR} 

TC-03: System Should Reject Connection When Device ID Is Out Of Lower Boundary Range  
    [Tags]    TC-03    Section-1    Negative
    [Documentation]    Check whether system rejects device connection correctly with ID out of lower boundary range
    ...                Expected: System should reject device connection with code: ${STATUS_VALIDATION_ERROR}
    Attach UE with ID -1 and expect error status ${STATUS_VALIDATION_ERROR} 

TC-04: System Should Reject Connection To Device ID When Is Already Connected
    [Tags]    TC-04    Section-1    Negative
    [Documentation]    Checks whether system rejects correctly connection of device with ID that was already accepted
    ...                Expected: System should reject second enquiry with code: ${STATUS_BAD_REQUEST} 
    #firstly we expect success connection
    Attach UE with ID 10 and expect success status ${STATUS_OK}
    Attach UE with ID 10 and expect error status ${STATUS_BAD_REQUEST} 

TC-05: System Should Successfully Detach Connected UE
    [Tags]    TC-05    Section-1    Positive
    [Documentation]    Checks whether system detaches device correctly with ID that was previously attached
    ...                Expected: System should return code: ${STATUS_OK}
    Attach UE with ID 25 and expect success status ${STATUS_OK}
    Detach UE with ID 25 and expect success status ${STATUS_OK}

TC-06: System Should Reject Detaching UE That Is Not Connected
    [Tags]    TC-06    Section-1    Negative
    [Documentation]    Checks whether system correctly rejects detaching device with ID that is not connected
    ...                Expected: System should return code: ${STATUS_BAD_REQUEST}
    Detach UE with ID 40 and expect error status ${STATUS_BAD_REQUEST}



*** Keywords ***
Attach UE with ID ${ue_id} and expect success status ${expected_success_status}
    [Arguments]    ${expected_bearer}=${DEFAULT_BEARER_ID}
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

Attach UE with ID ${ue_id} and expect error status ${expected_error_status}
    [Documentation]    Verifies whether system rejects connection and does not create resource
    ${answer}=    Attach Ue    ${ue_id}    
    Should Be Equal As Integers    ${answer['status']}    ${expected_error_status}

Detach UE with ID ${ue_id} and expect success status ${expected_success_status}
    [Documentation]    Verifies whether system correctly detaches UE
    ${answer}=    Detach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    # check if ue data was removed (Get Ue)
    ${get_ue_answer}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${get_ue_answer['status']}    ${STATUS_BAD_REQUEST}

Detach UE with ID ${ue_id} and expect error status ${expected_error_status}
    [Documentation]    Verifies whether system return error codes correctly when detaching incorrect UE
    ${answer}=    Detach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_error_status}
