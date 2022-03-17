*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           OperatingSystem
Library           RPA.FileSystem
Library           Collections
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Click Button    Preview
        Wait Until Keyword Succeeds    5x    3    Submit Order    ${row}
        Click Button    Order another robot
    END
    Create ZIP package from PDF files

*** Keywords ***
Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}/receipts
    ...    ${zip_file_name}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Wait Until Page Contains Element    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    ${secret}=    Get Secret    link
    Log    ${secret}[csvlink]
    Add text input    link    label=Orders Link    placeholder=https://robotsparebinindustries.com/orders.csv
    ${result}=    Run dialog
    Download    ${result.link}    overwrite=True
    RPA.FileSystem.Wait Until Created    orders.csv
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}

Fill the form
    [Arguments]    ${row}
    ${head} =    Get From Dictionary    ${row}    Head
    ${body} =    Get From Dictionary    ${row}    Body
    ${legs} =    Get From Dictionary    ${row}    Legs
    ${address} =    Get From Dictionary    ${row}    Address
    Select From List By Value    head    ${head}
    Select Radio Button    body    ${body}
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${legs}
    Input Text    address    ${address}

Submit Order
    [Arguments]    ${row}
    Click Button    Order
    Sleep    2
    ${failed} =    Does Page Contain    Error
    IF    ${failed}
        Fail
    END
    ${failed} =    Does Page Contain    On And Off
    IF    ${failed}
        Fail
    END
    ${sales_results_html}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}/receipts/${row}[Order number].pdf
    Capture Page Screenshot    filename=${OUTPUT_DIR}/receipts/${row}[Order number].png
    ${files}=    Create List
    ...    ${OUTPUT_DIR}/receipts/${row}[Order number].png
    Add Files To Pdf    ${files}    target_document=${OUTPUT_DIR}/receipts/${row}[Order number].pdf    append=True
