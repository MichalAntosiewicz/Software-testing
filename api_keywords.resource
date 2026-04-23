*** Settings ***
# Python api library import
Library    ApiLibraryPython.py    http://127.0.0.1:8000
Library    Collections

*** Variables ***
# App parameters
${DEFAULT_BEARER_ID}          9

# Status codes
${STATUS_OK}                  200
${STATUS_VALIDATION_ERROR}    422
${STATUS_BAD_REQUEST}         400

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


Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect error ${expected_status}
    ${answer}=    Start Traffic Mb    ${ue_id}    ${bearer_id}    ${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}