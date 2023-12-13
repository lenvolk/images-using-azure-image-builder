Clear-Host

$excelfilename = "Action Plan - Template.xlsx"
# $tenantid = "e8695001-811b-4992-8959-7ebe939176ec"
$workingFolderPath = "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\WAF" #Split-Path $script:MyInvocation.MyCommand.Path
$SubfilePath = "$workingFolderPath\subs.txt"
# Install required modules
Install-Module -Name ImportExcel -Force -SkipPublisherCheck
Install-Module -Name Az -SkipPublisherCheck -InformationAction SilentlyContinue

# Clone the GitHub repository to a temporary folder
$repoUrl = "https://github.com/Azure/Azure-Proactive-Resiliency-Library"
Set-Location -path $workingFolderPath;
New-Item -Path "Azure-Proactive-Resiliency-Library" -ItemType Directory -ErrorAction SilentlyContinue
$clonePath = "Azure-Proactive-Resiliency-Library"
git clone $repoUrl $clonePath --quiet

# Get list of APRL Services and Abbreviations
$servicesAbbreviationsArray = Import-Csv -Path "Azure-Proactive-Resiliency-Library\services-abbreviations.csv"


# Ask the user to enter a text file with the subIds
$filePath = $SubfilePath

# Check if the file exists
if (Test-Path $filePath -PathType Leaf) {
    # Read the content of the file and split it into an array of subscription IDs
    $subscriptionIds = Get-Content $filePath -ErrorAction Stop | ForEach-Object { $_ -split ',' }
    
    # Display the subscription IDs
    Write-Host "---------------------------------------------------------------------"
    Write-Host "Executing Analysis of the following Subscription IDs:"
    $subscriptionIds
} else {
    Write-Host "File not found: $filePath"
}

# Connect To Azure Tenant
# Connect-AzAccount -Tenant $tenantid
.\Authenticate2Azure.ps1

pause
foreach($subid in $subscriptionIds){
    Write-Host "---------------------------------------------------------------------"
    Write-Host "Validating Subscription: "$subid

    Set-AzContext -Subscription $subid

# Get list of Resources Types in the subscription
$queryAllResourceTypes = @"
summarize by type
"@

    # Extract and display resource types with the query
    $resultAllResourceTypes = Search-AzGraph -Query $queryAllResourceTypes
    $resourceTypesInUse = $resultAllResourceTypes | ForEach-Object { $_.type }

    # Check which services types are available in APRL and gets the abbreviation for the Kusto

    $resourceTypeAbbreviations = @()
    foreach ($resourceType in $resourceTypesInUse) {
        # Find the corresponding abbreviation in $servicesAbbreviationsArray
        $abbreviationObject = $servicesAbbreviationsArray | Where-Object { $_.type -eq $resourceType }
    
        # If an abbreviation is found, add it to the result array
        if ($abbreviationObject) {
            $resourceTypeAbbreviations += [PSCustomObject]@{
                ResourceType = $resourceType
                Abbreviation = $abbreviationObject.abbreviation
            }
        } else {
            # If no abbreviation is found, add "null"
            $resourceTypeAbbreviations += [PSCustomObject]@{
                ResourceType = $resourceType
                Abbreviation = $false
            }
        }
    }

    # Display the result
    $resourceTypeAbbreviations | Format-Table -AutoSize

    #--- Executing Queries ----------------------------------------------------------------------#

    # Initialize an array to store the combined results
    $results = @()

    # Initialize an array to store the errors
    $errors = @()

    # Loop truu each resource type in use
    foreach ($resourceType in $resourceTypesInUse) {
    
        # Check if service exists in APRL
        $abbreviationObject = $resourceTypeAbbreviations | Where-Object { $_.ResourceType -eq $resourceType }

        # If service exists, proceed to run the queries
        if ($abbreviationObject -and $abbreviationObject.Abbreviation -ne $false) {
        
            $abbreviation = $abbreviationObject.Abbreviation

            # Get a list of all .kql files in the cloned repository that match the abbreviation
            $kqlFiles = Get-ChildItem -Path $clonePath -Filter "$abbreviation-*.kql" -Recurse
        
            # Loop through each KQL file and execute the queries
            foreach ($kqlFile in $kqlFiles) {
                Write-Output "++++++++++++++++++ $kqlFile +++++++++++++++"
            
                # Read the query content from the file
                $query = Get-Content -Path $kqlFile.FullName | Out-String

                # Validating if Query is Under Development
                if ($query -match "development") {
                    Write-Host "Query $kqlFile under development - Validate Recommendation manually"
                    $result = [PSCustomObject]@{
                        recommendationId = $kqlFile
                        name             = "Query under development - Validate Recommendation manually"
                        id               = ""
                        param1           = ""
                        param2           = ""
                        param3           = ""
                        param4           = ""
                        param5           = ""
                    }
                    $results += $result

                } else {
                    try {
                        # Execute the query and collect the results
                        $queryResults = Search-AzGraph -Query $query -ErrorAction SilentlyContinue
                
                        foreach ($row in $queryResults) {
                            $result = [PSCustomObject]@{
                                recommendationId = $row.recommendationId -as [string] -replace '^', ''
                                name             = $row.name -as [string] -replace '^', ''
                                id               = $row.id -as [string] -replace '^', ''
                                param1           = $row.param1 -as [string] -replace '^', ''
                                param2           = $row.param2 -as [string] -replace '^', ''
                                param3           = $row.param3 -as [string] -replace '^', ''
                                param4           = $row.param4 -as [string] -replace '^', ''
                                param5           = $row.param5 -as [string] -replace '^', ''
                            }
                            $results += $result
                        }
                    } catch {
                        # Log the error and continue with the next iteration
                        $errorMessage = $_.Exception.Message
                        Write-Output "Error executing query from file $($kqlFile.FullName): $errorMessage"
                        $errors += [PSCustomObject]@{
                            File  = $kqlFile
                            Error = $errorMessage
                        }
                    }
                }
            }
        }
    }
}

# Path to the Excel file and the name of the worksheet
$excelFilePath = $excelfilename
$worksheetName = "ImpactedResources"

# Check if the Excel file exists
if (Test-Path -Path $excelFilePath) {
    # Import the existing data from the Excel file
    $existingData = Import-Excel -Path $excelFilePath -WorksheetName $worksheetName

    # Append new results to the existing data
    $combinedData = $existingData + $results

    # Write the combined data back to the same Excel file and worksheet
    $combinedData | Export-Excel -Path $excelFilePath -WorksheetName $worksheetName -AutoFilter -Append

    Write-Host "Data appended successfully."
} else {
    Write-Error "The specified Excel file does not exist at the path: $excelFilePath"
}

# [Optional] - export errors to a separate file
if ($errors.Count -gt 0) {
    $errors | Export-Csv -Path "Errors.csv" -NoTypeInformation
}