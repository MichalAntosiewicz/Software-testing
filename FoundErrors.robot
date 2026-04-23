*** Settings ***
Resource          api_keywords.resource
Test Teardown     Reset App State

*** Test Cases ***
# copied from TestSection1
TC-01: User Should Be Able To Attach Devices Within Allowed ID Range
    [Tags]    TC-01    Section-1    Positive
    [Documentation]    Check whether system attaches device correctly with ID in correct range
    ...                Expected: System should connect device with code: ${STATUS_OK} 
    Attach UE with ID 0 and expect success status ${STATUS_OK}   

# new tests
TC-21 User Should Not Be Able To Start Traffic Out Of Upper Allowed Speed Range
    [Tags]    TC-21    Section-5    Negative
    [Documentation]    Check whether system rejects traffic connection correctly with speed out of correct upper range
    ...                Expected: System should reject connection with code: ${STATUS_BAD_REQUEST} 
    Attach UE with ID 1 and expect success status ${STATUS_OK}   
    Start Traffic on UE 1 Bearer 9 with 110 Mbps and expect error ${STATUS_BAD_REQUEST}

TC-22 User Should Not Be Able To Start Traffic Out Of Lower Allowed Speed Range
    [Tags]    TC-21    Section-5    Negative
    [Documentation]    Check whether system rejects traffic connection correctly with speed out of correct lower range
    ...                Expected: System should reject connection with code: ${STATUS_BAD_REQUEST} 
    Attach UE with ID 1 and expect success status ${STATUS_OK}   
    Start Traffic on UE 1 Bearer 9 with -100 Mbps and expect error ${STATUS_BAD_REQUEST}    
    