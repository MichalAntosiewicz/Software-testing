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
#test section 1
Detach UE with ID ${ue_id} and expect success status ${expected_success_status}
    [Documentation]    Verifies whether system correctly detaches UE
    ${answer}=    Detach Ue    ${ue_id}
    Should Be Equal As Integers    ${answer['status']}    ${expected_success_status}
    # check if ue data was removed (Get Ue)
    ${get_ue_answer}=    Get Ue    ${ue_id}
    Should Be Equal As Integers    ${get_ue_answer['status']}    ${STATUS_BAD_REQUEST}

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

#test section 3 - modified
Remove bearer ${bearer_id} from UE ${ue_id} and expect success ${STATUS_OK}
    [Documentation]    Removes bearer and checks status 'bearer_deleted'
    ${res}=    Remove Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${res['status']}    ${STATUS_OK}
    Should Be Equal As Strings     ${res['body']['status']}    bearer_deleted

Add dedicated bearer ${bearer_id} to UE ${ue_id} and expect success ${STATUS_OK}
    [Documentation]    Adds a new bearer to UE [cite: 144, 152]
    ${res}=    Add Bearer    ${ue_id}    ${bearer_id}
    Should Be Equal As Integers    ${res['status']}    ${STATUS_OK}

#test section 4
Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect error ${expected_status}
    ${answer}=    Start Traffic Mb    ${ue_id}    ${bearer_id}    ${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}


Start Traffic on UE ${ue_id} Bearer ${bearer_id} with ${val} Mbps and expect success ${expected_status}
    ${answer}=    Start Traffic Mb    ${ue_id}    ${bearer_id}    ${val}
    Should Be Equal As Integers    ${answer['status']}    ${expected_status}

#new 
Check if traffic on UE ${ue_id} Bearer ${bearer_id} is stopped
    ${answer}=    Get Traffic Stats    ${ue_id}    ${bearer_id}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['status']}    ${STATUS_OK}
    #check if UE data is coorect
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['ue_id']}        ${ue_id}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['bearer_id']}    ${bearer_id}

    #check if int data is equal '0'
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['tx_bps']}    0
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['rx_bps']}    0
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${answer['body']['duration']}  0
    #check if string data is equal 'null'
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${answer['body']['protocol']}    None
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${answer['body']['target_bps']}  None

