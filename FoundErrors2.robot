*** Settings ***
Resource          api_keywords.resource
Test Teardown     Reset App State

*** Test Cases ***
TC-24 User Should Be Able To Stop All Traffic For UE At Once
    [Tags]    TC-24    Section-5    Negative
    [Documentation]    Check whether system allows stopping all traffic for UE without specifying bearer_id\n\n
    ...                Expected: System should stop traffic with code: ${STATUS_OK} 
    Attach UE with ID 1 and expect success status ${STATUS_OK}
    Start Traffic on UE 1 Bearer 9 with 10 Mbps and expect success ${STATUS_OK}
    Stop All Traffic On UE 1 and expect success ${STATUS_OK}

TC-25 System Should Use Kbps As Default Unit For Stats
    [Tags]    TC-25    Section-4    Negative
    [Documentation]    Check whether system returns overall stats using kbps as default unit\n\n
    ...                Expected: System should return JSON keys with kbps suffix 
    Attach UE with ID 1 and expect success status ${STATUS_OK}
    Start Traffic on UE 1 Bearer 9 with 10 Mbps and expect success ${STATUS_OK}
    Check Default Traffic Stats Unit For UE 1