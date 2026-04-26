*** Settings ***
Resource          api_keywords.resource
Test Teardown     Reset App State

*** Test Cases ***
# copied from TestSection1
TC-01: User Should Be Able To Attach Devices Within Allowed ID Range
    [Tags]    TC-01    Section-1    Positive
    [Documentation]    Check whether system attaches device correctly with ID in correct range\n\n
    ...                Expected: System should connect device with code: ${STATUS_OK} 
    Attach UE with ID 0 and expect success status ${STATUS_OK}   

TC-19: Evaluation of API Consistency For Inactive Bearer Statistics
    [Tags]    Compliance    Defect_Tracking    Negative
    [Documentation]    Identify logical inconsistency where API incorrectly returns HTTP 200 for non-existent resources. 
    ...               Expected result: 404 Not Found.
    Reset App State
    Attach UE context    10    ${STATUS_OK}
    ${response}=    Get Traffic Stats    ${{int(10)}}    ${{int(99)}}
    # Triggering intentional FAIL to document API discrepancy (Returns 200 instead of 404)
    Should Be Equal As Integers    ${response['status']}    ${STATUS_NOT_FOUND}
    [Teardown]    Reset App State

# new tests
TC-21 User Should Not Be Able To Start Traffic Out Of Upper Allowed Speed Range
    [Tags]    TC-21    Section-5    Negative
    [Documentation]    Check whether system rejects traffic connection correctly with speed out of correct upper range\n\n
    ...                Expected: System should reject connection with code: ${STATUS_BAD_REQUEST} 
    Attach UE with ID 1 and expect success status ${STATUS_OK}   
    Start Traffic on UE 1 Bearer 9 with 110 Mbps and expect error ${STATUS_BAD_REQUEST}

TC-22 User Should Not Be Able To Start Traffic Out Of Lower Allowed Speed Range
    [Tags]    TC-22    Section-5    Negative
    [Documentation]    Check whether system rejects traffic connection correctly with speed out of correct lower range\n\n
    ...                Expected: System should reject connection with code: ${STATUS_BAD_REQUEST} 
    Attach UE with ID 1 and expect success status ${STATUS_OK}   
    Start Traffic on UE 1 Bearer 9 with -100 Mbps and expect error ${STATUS_BAD_REQUEST}    

TC-23 User Should Be Able To Restart Traffic On Restarted UE
    [Tags]    TC-23    Section-5    Positive
    [Documentation]    Check whether system correctly allow user to attach UE, add bearer, start traffic 
    ...                then detach same UE and then add same ID bearer and start traffic \n\n
    ...                Expected: System should accept connection with code: ${STATUS_OK} 
    
    # Attach UE, Add bearer, start traffic and detach UE while traffic is ongoing
    Attach UE with ID 1 and expect success status ${STATUS_OK}       
    Add dedicated bearer 1 to UE 1 and expect success ${STATUS_OK}
    Start Traffic on UE 1 Bearer 1 with 10 Mbps and expect success ${STATUS_OK}   
    Detach UE with ID 1 and expect success status ${STATUS_OK}

    # Again attach same UE, add same bearer, start traffic on that bearer
    #  - system should allow connection (as in same scenario but with detaching only bearer not ue)
    Attach UE with ID 1 and expect success status ${STATUS_OK}       
    Add dedicated bearer 1 to UE 1 and expect success ${STATUS_OK}
    Check if traffic on UE 1 Bearer 1 is stopped
    Run Keyword And Continue On Failure    Start Traffic on UE 1 Bearer 1 with 10 Mbps and expect success ${STATUS_OK}       
    # sleep to measure traffic
    Sleep    1s
    # app returns error but traffic starts
    Check if traffic on UE 1 Bearer 1 is stopped
