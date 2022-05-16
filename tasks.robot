*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Windows
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.JSON
Library             OperatingSystem
Library             RPA.Robocloud.Secrets


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secretkey}=    Get The Secret Key
    ${user_input_key}=    Open Password Enter
    ${correct_key}=    Set Variable    False

    WHILE    ${correct_key} == False
        IF    "${user_input_key}" == "${secretkey}"
            ${correct_key}=    Set Variable    True
        ELSE
            ${user_input_key}=    Invalid Password
        END
    END

    Open the robot order website
    Download the Order file
    Open and save workbook in variable


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Invalid Password
    Add heading    Admin Credentials
    Add password input
    ...    secret_key_field
    ...    label=Wrong secret key, please try again.
    ...    placeholder=secret key
    ${result}=    Run dialog    height=300    on_top=True    title=Please Enter Secret Key
    RETURN    ${result.secret_key_field}

Download the Order file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Open and save workbook in variable
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill and submit the form for one order    ${order}
    END
    Create ZIP Archive of PDFs
    [Teardown]    Log out and close the browser

Log out and close the browser
    Close Browser

Close the annoying modal
    Click Button    Yep

Get The Secret Key
    ${secret}=    Get Secret    secret_creds
    ${secretkey}=    Set Variable    ${secret}[pass]
    RETURN    ${secretkey}

Open Password Enter
    Add heading    Admin Credentials
    Add password input
    ...    secret_key_field
    ...    label=Please enter the secret key to start.
    ...    placeholder=secret key
    ${result}=    Run dialog    height=300    on_top=True    title=Please Enter Secret Key
    RETURN    ${result.secret_key_field}

Fill and submit the form for one order
    [Arguments]    ${order}
    Wait Until Page Contains Element    head
    Select From List By Value    head    ${order}[Head]
    Click Element    //label[./input[@value=${order}[Body]]]
    Input Text    //*[@type="number"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    5x    0.5 sec    Submit order
    Export the receipt as a PDF    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Click Button    id:order-another

Submit order
    Click Button    id:order
    Page Should Contain Element    //*[@id="receipt"]

Add Screenshot To Pdf
    [Arguments]    ${order_number}
    ${files}=    Create List
    ...    output_files${/}${order_number}.png:align=center
    Add Files To PDF    ${files}    output_files${/}${order_number}.pdf    append=True

Take a screenshot of the robot
    [Arguments]    ${order_number}
    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    output_files${/}${order_number}.png
    Add Screenshot To Pdf    ${order_number}

Export the receipt as a PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_reciept}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_reciept}    output_files${/}${order_number}.pdf

Create ZIP Archive of PDFs
    Archive Folder With ZIP    output_files    orders.zip    recursive=True    include=*.pdf
    Empty Directory    output_files
    Remove file    orders.csv
