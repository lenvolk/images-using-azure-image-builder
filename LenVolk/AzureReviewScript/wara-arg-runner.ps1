<#
The goal of this tool is to execute ARGs from APRL and export the results to an Excel file.

When using more than 1 Subscription in the -SubscriptionIds parameter use Subscription1,Subscription2...

APRL Repo will be downloaded in the script's folder
ver: 0.11
#>

Param(
        [switch]$Debug,
        [switch]$Help,
        $SubscriptionsFile,
        $SubscriptionIds,
        $ResourceGroups,
        $TenantID)

if ($Debug.IsPresent) {$DebugPreference = 'Continue'} else {$DebugPreference = "silentlycontinue" }

Clear-Host

# This will delete the local files of APRL if they exist
$ResetLocalRepo = $false

# This variable is to prevent all APRL Recommendations in the 1st tab
$FullRepo = $false

$Global:Runtime = Measure-Command -Expression {

    function CheckParameters {
        if([string]::IsNullOrEmpty($SubscriptionIds) -and [string]::IsNullOrEmpty($SubscriptionsFile)) 
        {
            Write-Host ""
            Write-Host "Suscription ID or Subscription File is required"
            Write-Host ""
            Exit
        }
    }

    function Help {
        Write-Host ""
        Write-Host "Parameters"
        Write-Host ""
        Write-Host " -TenantID <ID>        :  Tenant to be used. "
        Write-Host " -SubscriptionIds <IDs>:  Specifies Subscription(s) to be included in the analysis: Subscription1,Subscription2. "
        Write-Host " -SubscriptionsFile    :  Specifies the file with the subscription list to be analysed (one subscription per line). "
        Write-Host " -ResourceGroups       :  Specifies Resource Group(s) to be included in the analysis: ResourceGroup1,ResourceGroup2. "
        Write-Host " -Debug                :  Writes Debugging information of the script during the execution. "
        Write-Host ""
        Write-Host "Examples: "
        Write-Host "  Run against all the subscriptions in the Tenant"
        Write-Host "  .\wara-arg-runner.ps1 -TenantID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
        Write-Host ""
        Write-Host "  Run against specific Subscriptions in the Tenant"
        Write-Host "  .\wara-arg-runner.ps1 -TenantID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -SubscriptionIds YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY,AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
        Write-Host ""
        Write-Host "  Run against the subscriptions in a file the Tenant"
        Write-Host '  .\wara-arg-runner.ps1 -TenantID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -SubscriptionsFile "C:\Temp\Subscriptions.txt"'
        Write-Host ""
        Write-Host ""
    }

    function Variables {
        $Global:servicesAbbreviationsArray = ''
        $Global:EnvironmentResource = @()
        $Global:SubIds = ''
        $Global:results = @()
        $Global:errors = @()
    }

    function Requirements {
        # Install required modules
        Write-Host "Validating " -NoNewline
        Write-Host "ImportExcel" -ForegroundColor Cyan -NoNewline
        Write-Host " Module.."
        $ImportExcel = Get-Module -Name ImportExcel -ListAvailable -ErrorAction silentlycontinue
        if ($null -eq $ImportExcel) {
            Write-Host "Installing ImportExcel Module" -ForegroundColor Yellow
            Install-Module -Name ImportExcel -Force -SkipPublisherCheck
        }
        Write-Host "Validating " -NoNewline
        Write-Host "Az.ResourceGraph" -ForegroundColor Cyan -NoNewline
        Write-Host " Module.."
        $AzModules = Get-Module -Name Az.ResourceGraph -ListAvailable -ErrorAction silentlycontinue
        if ($null -eq $AzModules) {
            Write-Host "Installing Az Modules" -ForegroundColor Yellow
            Install-Module -Name Az.ResourceGraph -SkipPublisherCheck -InformationAction SilentlyContinue
        }
        Write-Host "Validating " -NoNewline
        Write-Host "Git" -ForegroundColor Cyan -NoNewline
        Write-Host " Installation.."
        $GitVersion = git --version
        if ($null -eq $GitVersion) {
            Write-Host "Missing Git" -ForegroundColor Red
            Exit
        }
    }

    function LocalFiles {
        Write-Debug "Setting local path"

        # Clone the GitHub repository to a temporary folder
        $repoUrl = "https://github.com/Azure/Azure-Proactive-Resiliency-Library"

        # Define script path as the default path to save files
        $workingFolderPath = $PSScriptRoot
        Set-Location -path $workingFolderPath;
        Write-Debug "Checking default folder"
        if ((Test-Path -Path "$PSScriptRoot\Azure-Proactive-Resiliency-Library" -PathType Container) -eq $false) {
            New-Item -Path "$PSScriptRoot\Azure-Proactive-Resiliency-Library" -ItemType Directory | Out-Null
        }
        if((Get-ChildItem -Path "$PSScriptRoot\Azure-Proactive-Resiliency-Library" -Force | Measure-Object).Count -gt 0)
            {
                if($ResetLocalRepo -eq $true)
                    {
                        Get-ChildItem -Path "$PSScriptRoot\Azure-Proactive-Resiliency-Library" -Include *.* -File -Recurse | ForEach-Object { $_.Delete()}
                        $clonePath = "$PSScriptRoot\Azure-Proactive-Resiliency-Library"
                        git clone $repoUrl $clonePath --quiet
                    }
            }
        else
            {
                $Global:clonePath = "$PSScriptRoot\Azure-Proactive-Resiliency-Library"
                git clone $repoUrl $clonePath --quiet
            }

        # Get list of APRL Services and Abbreviations
        $Global:servicesAbbreviationsArray = Import-Csv -Path "$PSScriptRoot\Azure-Proactive-Resiliency-Library\services-abbreviations.csv"
    }

    function ConnectToAzure {
        # Connect To Azure Tenant
        Write-Host "Authenticating to Azure"
        if ([string]::IsNullOrEmpty($TenantID)) 
            {
                write-host "Tenant ID not specified."
                write-host ""
                Connect-AzAccount -WarningAction SilentlyContinue
                $Tenants = Get-AzTenant
                if($Tenants.count -gt 1)
                    {
                        Write-Host "Select the Azure Tenant to connect : "
                        $Selection = 1
                        foreach ($Tenant in $Tenants) {
                            $TenantName = $Tenant.Name
                            write-host "$Selection)  $TenantName"
                            $Selection ++
                        }
                        write-host ""
                        [int]$SelectedTenant = read-host "Select Tenant"
                        $defaultTenant = --$SelectedTenant
                        $TenantID = $Tenants[$defaultTenant]
                        Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue
                    }
            }
        else
            {
                Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue
            }
        #Set the default variable with the list of subscriptions in case no Subscription File was informed
        $Global:SubIds = Get-AzSubscription -TenantId $TenantID -WarningAction SilentlyContinue
    }

    function Subscriptions {
        # Checks if the Subscription file  and TenantID were informed
        if(![string]::IsNullOrEmpty($SubscriptionsFile))
            {
                #$filePath = Read-Host "Please provide the path to a text file containing subscription IDs (one SubId per line)"

                # Check if the file exists
                if (Test-Path $SubscriptionsFile -PathType Leaf) {
                    # Read the content of the file and split it into an array of subscription IDs
                    $Global:SubIds = Get-Content $SubscriptionsFile -ErrorAction Stop | ForEach-Object { $_ -split ',' }

                    # Display the subscription IDs
                    Write-Host "---------------------------------------------------------------------"
                    Write-Host "Executing Analysis from Subscription File: " -NoNewline
                    Write-Host $SubscriptionsFile -ForegroundColor Blue
                    Write-Host "---------------------------------------------------------------------"
                    Write-Host "The following Subscription IDs were found: "
                    Write-Host $SubIds
                } else {
                    Write-Host "File not found: $SubscriptionsFile"
                }
            }
    }

    function ResourceExtraction {

        if(![string]::IsNullOrEmpty($SubscriptionIds) -and [string]::IsNullOrEmpty($SubscriptionsFile))
            {
                $SubIds = $SubIds | Where-Object {$_.Id -in $SubscriptionIds}
            }

        # Initialize an array to store the combined results
        $Global:results = @()

        # Initialize an array to store the errors
        $Global:errors = @()

        # Set the variables used in the loop
        foreach($Subid in $SubIds){
            if([string]::IsNullOrEmpty($subid.name))
                {
                    # If the variable was set in the Subscription File only IDs will be available
                    $Subid = $Subid
                    $SubName = $Subid
                }
            else
                {
                    # If using the variable set during the login to Azure, Subscription Name is available
                    $SubName = $Subid.Name
                    $Subid = $Subid.id
                }
            Write-Host "---------------------------------------------------------------------"
            Write-Host "Validating Subscription: " -NoNewline
            Write-Host $SubName -ForegroundColor Cyan

            Set-AzContext -Subscription $Subid -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null

            # Extract and display resource types with the query with subscriptions, we need this to filter the subscriptions later
            $resultAllResourceTypes = Search-AzGraph -Query "resources | summarize count() by type" -Subscription $Subid

            # Check which services types are available in APRL and gets the abbreviation for the Kusto

            $resourceTypeAbbreviations = @()
            foreach ($resourceType in $resultAllResourceTypes) 
                {
                    # Find the corresponding abbreviation in $servicesAbbreviationsArray
                    $abbreviationObject = $servicesAbbreviationsArray | Where-Object { $_.type -eq $resourceType.type }

                    # If an abbreviation is found, add it to the result array
                    if ($abbreviationObject) 
                        {
                            $resourceTypeAbbreviations += [PSCustomObject]@{
                                ResourceType = $resourceType.type
                                ResourceCount = $resourceType.count_
                                Abbreviation = $abbreviationObject.abbreviation
                            }
                        } 
                    else 
                        {
                            # If no abbreviation is found, add "null"
                            $resourceTypeAbbreviations += [PSCustomObject]@{
                                ResourceType = $resourceType.type
                                ResourceCount = $resourceType.count_
                                Abbreviation = $false
                            }
                        }
                }

            # Display the result
            #$resourceTypeAbbreviations | Format-Table -AutoSize

            #--- Executing Queries ----------------------------------------------------------------------#

            # Loop truu each resource type in use
            foreach ($resourceType in $resultAllResourceTypes) {

                # Check if service exists in APRL
                $abbreviationObject = $resourceTypeAbbreviations | Where-Object { $_.ResourceType -eq $resourceType.type }

                # If service exists, proceed to run the queries
                if ($abbreviationObject -and $abbreviationObject.Abbreviation -ne $false) {
                
                    $abbreviation = $abbreviationObject.Abbreviation

                    # Get a list of all .kql files in the cloned repository that match the abbreviation
                    $kqlFiles = Get-ChildItem -Path $clonePath -Filter "$abbreviation-*.kql" -Recurse

                    # Loop through each KQL file and execute the queries
                    foreach ($kqlFile in $kqlFiles) {
                        $kqlshort = [string]$kqlFile.FullName.split('\')[-1]
                        Write-Host "++++++++++++++++++ " -NoNewline
                        Write-Host $kqlshort -ForegroundColor Green -NoNewline
                        Write-Host " +++++++++++++++"

                        $kqlname = $kqlshort.split('.')[0]
                        $Global:EnvironmentResource += $kqlname

                        # Read the query content from the file
                        $query = Get-Content -Path $kqlFile.FullName | Out-String

                        # Validating if Query is Under Development
                        if ($query -match "development") {
                            Write-Host "Query $kqlshort under development - Validate Recommendation manually" -ForegroundColor Yellow
                            $result = [PSCustomObject]@{
                                recommendationId = $kqlshort.replace('.kql','')
                                name             = "Query under development - Validate Recommendation manually"
                                id               = ""
                                tags             = ""
                                param1           = ""
                                param2           = ""
                                param3           = ""
                                param4           = ""
                                param5           = ""
                            }
                            $Global:results += $result

                        } else {
                            try {
                                if($resourceType.count_ -lt 5000)
                                    {
                                        # Execute the query and collect the results
                                        $queryResults = Search-AzGraph -Query $query -Subscription $Subid -ErrorAction SilentlyContinue

                                        # Filter out the resources based on Subscription
                                        # $queryResults = $queryResults | Where-Object {$_.id.split('/')[2] -eq $Subid}

                                        foreach ($row in $queryResults) 
                                            {
                                            $result = [PSCustomObject]@{
                                                    recommendationId = [string]$row.recommendationId
                                                    name             = [string]$row.name
                                                    id               = [string]$row.id
                                                    tags             = [string]$row.tags
                                                    param1           = [string]$row.param1
                                                    param2           = [string]$row.param2
                                                    param3           = [string]$row.param3
                                                    param4           = [string]$row.param4
                                                    param5           = [string]$row.param5
                                                }
                                            $Global:results += $result
                                            }
                                    }
                                else
                                    {
                                        Write-Host 'Resource Type: ' -NoNewLine
                                        Write-Host $resourceType.Type -NoNewline -ForegroundColor Yellow
                                        Write-Host ' has:  ' -NoNewline
                                        Write-Host $resourceType.count_ -NoNewline -ForegroundColor Cyan
                                        Write-Host ' resources and extraction will be looped!'

                                        $query+'| order by id'
                                        $Loop = $resourceType.count_ / 1000
                                        $Loop = [math]::ceiling($Loop)
                                        $Looper = 0
                                        $Limit = 1

                                        while ($Looper -lt $Loop) {
                                            $queryResults = Search-AzGraph -Query ($query+'| order by id') -Subscription $Subid -Skip $Limit -first 1000 -ErrorAction SilentlyContinue
                                            foreach ($row in $queryResults) {
                                                $result = [PSCustomObject]@{
                                                    recommendationId = [string]$row.recommendationId
                                                    name             = [string]$row.name
                                                    id               = [string]$row.id
                                                    tags             = [string]$row.tags
                                                    param1           = [string]$row.param1
                                                    param2           = [string]$row.param2
                                                    param3           = [string]$row.param3
                                                    param4           = [string]$row.param4
                                                    param5           = [string]$row.param5
                                                }
                                                $Global:results += $result
                                            }
                                            $Looper ++
                                            $Limit = $Limit + 1000
                                        }
                                    }
                                #After processing the ARG Queries, now is time to process the -ResourceGroups 
                                if(![string]::IsNullOrEmpty($ResourceGroups))
                                    {
                                        $TempResult = $Global:results
                                        $Global:results = @()

                                        foreach($result in $TempResult)
                                            {
                                                $res = $result.id.split('/')
                                                if($res[4] -in $ResourceGroups)
                                                    {
                                                        $Global:results += $result
                                                    }
                                                if($result.name -eq "Query under development - Validate Recommendation manually")
                                                    {
                                                        $Global:results += $result
                                                    }
                                            }                                        
                                    }
                            } catch {
                                # Log the error and continue with the next iteration
                                $errorMessage = $_.Exception.Message
                                Write-Host "Error executing query from file $($kqlFile.FullName): $errorMessage" -ForegroundColor Red
                                $errors += [PSCustomObject]@{
                                    File  = $kqlFile
                                    Error = $errorMessage
                                }
                            }
                        }
                    }
                }
                #Store all resourcetypes not in APRL
                if($resourceType.type -notin $Global:servicesAbbreviationsArray.Type)
                {
                    $type = $resourceType.type
                    Write-Host "Type $type Not Available In APRL - Validate Service manually" -ForegroundColor Yellow
                            $result = [PSCustomObject]@{
                                recommendationId = $resourceType.type
                                name             = "Service Not Available In APRL - Validate Service manually if Applicable, if not Delete this line"
                                id               = ""
                                tags             = ""
                                param1           = ""
                                param2           = ""
                                param3           = ""
                                param4           = ""
                                param5           = ""
                            }
                            $Global:results += $result
                } 
            }
        }
    }

    function ExcelFile {

        Write-Host "---------------------------------------------------------------------"
        Write-Host "Starting Excel file Processing. "

        $TableStyle = "Light19"
        $Global:Recommendations = @()

        # Defines the Excel file to be created in the root folder
        $Global:ExcelFile = ($PSScriptRoot+ "\WARA Action Plan " + (get-date -Format "yyyy-MM-dd_HH_mm") + ".xlsx")

        # Defines the Excel stiles for the header line in the ImpactedResources Sheet
        $Styles = @(
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -VerticalAlignment Center -AutoSize -Range "A:B"
        New-ExcelStyle -HorizontalAlignment Left -FontName 'Calibri' -FontSize 11 -VerticalAlignment Center -Width 80  -Range "C:C"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -VerticalAlignment Center -AutoSize -Range "D:I"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -BackgroundColor "DarkSlateGray" -AutoSize -Range "A1:B1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -BackgroundColor "DarkSlateGray" -Width 80 -Range "C1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -BackgroundColor "DarkSlateGray" -AutoSize -Range "D1:I1"
        )

        # Creates the first sheet (ImpactedResources)
        $results | ForEach-Object { [PSCustomObject]$_ } | Select-Object $_ |
                Export-Excel -Path $ExcelFile -WorksheetName 'ImpactedResources' -TableName 'Table2' -AutoSize -TableStyle $TableStyle -Style $Styles

        # Folders to be used in the Recommendations sheet
        $FolderServices = "$PSScriptRoot\Azure-Proactive-Resiliency-Library\docs\content\services"
        $FolderWAF = "$PSScriptRoot\Azure-Proactive-Resiliency-Library\docs\content\well-architected"
        $TextInfo = (Get-Culture).TextInfo


        # Search trough all the _index.md files in the services folder
        $ServiceFolders = Get-ChildItem -Path $FolderServices -Directory | Where-Object {$_.Name -ne 'code'}
        foreach($ServiceFolder in $ServiceFolders)
        {
            $ServiceCategory = $ServiceFolder.Name
            $ServiceSubFolders = Get-ChildItem -Path $ServiceFolder.FullName -Directory | Where-Object {$_.Name -ne 'code'}

            foreach($ServiceSubFolder in $ServiceSubFolders)
                {
                    $ServiceCategoryTopic = $ServiceSubFolder.Name
                    $ServiceFiles = Get-ChildItem -Path $ServiceSubFolder.FullName -File '_index.md' -Recurse

                    foreach($ServiceFile in $ServiceFiles)
                        {
                            $FileDetail = Get-Content -Path $ServiceFile.FullName -Raw
                            #Validates if the files contains data and are not categories or services lists (we only want the _index.md files that have Recommendations)
                            if($FileDetail -notlike '*## Categories List*' -and $FileDetail -notlike '*## Services List*' -and ![string]::IsNullOrEmpty($FileDetail))
                                {
                                    if(![string]::IsNullOrEmpty($FileDetail))
                                        {
                                            $MDTopic = $FileDetail.split('###')
                                            $MDTopic = $MDTopic[1..($MDTopic.Length - 1)]

                                            Foreach($Topic in $MDTopic)
                                                {                                             
                                                    $RecommendationDetails = $Topic.split('**')
                                                    $ID = $Topic.split(' - ')[0]
                                                    $ID = $ID.Replace(' ','')

                                                    if($FullRepo -or $ID -in $Global:EnvironmentResource)
                                                        {                                                            
                                                            $IDNUM = $ID.split('-')[1]

                                                            $Category = if($RecommendationDetails[1] -like '*Category*'){$RecommendationDetails[1].split(':')[1]}else{''}
                                                            $Title = if(![string]::IsNullOrEmpty($Topic.split('**'))){($Topic.split('**')).split(' - ')[1]}else{''}
                                                            $Impact = if(![string]::IsNullOrEmpty($RecommendationDetails[3])){if($RecommendationDetails[3] -like '*Impact*'){$RecommendationDetails[3].split(':')[1]}else{$RecommendationDetails[1].split(':')[1]}}else{""}
                                                            $BestPractices = if($RecommendationDetails[5] -like '*Guidance*' -or $RecommendationDetails[5] -like '*Recommendation*' ){$RecommendationDetails[6]}else{$RecommendationDetails[4]}

                                                            $ReadMore1 = if($RecommendationDetails[5] -like '*Resources*' -and $RecommendationDetails[6].split('[').split(']')[2] -like '*http*')
                                                                {
                                                                    $RecommendationDetails[6].split('[').split(']')[2].split(')').replace('(','')[0]
                                                                }
                                                            elseif($RecommendationDetails[7] -like '*Resources*' -and $RecommendationDetails[8].split('[').split(']')[2] -like '*http*')
                                                                {
                                                                    $RecommendationDetails[8].split('[').split(']')[2].split(')').replace('(','')[0]
                                                                }
                                                            else
                                                                {
                                                                    ''
                                                                }
                                                            $ReadMore2 = if($RecommendationDetails[5] -like '*Resources*' -and $RecommendationDetails[6].split('[').split(']')[4] -like '*http*')
                                                                {
                                                                    $RecommendationDetails[6].split('[').split(']')[4].split(')').replace('(','')[0]
                                                                }
                                                            elseif($RecommendationDetails[7] -like '*Resources*' -and $RecommendationDetails[8].split('[').split(']')[4] -like '*http*')
                                                                {
                                                                    $RecommendationDetails[8].split('[').split(']')[4].split(')').replace('(','')[0]
                                                                }
                                                            else
                                                                {
                                                                    ''
                                                                }
                                                            $tmp = @{
                                                                'Implemented?Yes/No' = ('=IF((COUNTIF(ImpactedResources!A:A,"'+$ID+'")=0),"Yes","No")');
                                                                'Number of Impacted Resources?' = ('=COUNTIF(ImpactedResources!A:A,"'+$ID+'")');
                                                                'Azure Service / Well-Architected' = 'Azure Service';
                                                                'Azure Service Category / Well-Architected Area' = $TextInfo.ToTitleCase($ServiceCategory.Replace('-',' '));
                                                                'Azure Service / Well-Architected Topic' = $TextInfo.ToTitleCase($ServiceCategoryTopic.Replace('-',' '));
                                                                'Resiliency Category' = $Category;
                                                                'ID' = $ID;
                                                                'IDNUM' = $IDNUM;
                                                                'Recommendation Title' = $Title;
                                                                'Health / Risk' = 'Health';
                                                                'Impact' = $Impact;
                                                                'Best Practices Guidance' = $BestPractices;
                                                                'Read More 1' = $ReadMore1;
                                                                'Read More 2' = $ReadMore2;
                                                                'Add associated Outage TrackingID and/or Support Request # and/or Service Retirement TrackingID' = '';
                                                                'Observation / Annotation' = '';
                                                                'Next Steps - Recommended Microsoft Services' = ''
                                                            }

                                                            $Global:Recommendations += $tmp
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }


        $WAFFolders = Get-ChildItem -Path $FolderWAF -Directory | Where-Object {$_.Name -ne 'code'}
        foreach($WAFFolder in $WAFFolders)
        {
            $WAFCategory = $WAFFolder.Name
            $WAFFiles = Get-ChildItem -Path $WAFFolder.FullName -File '_index.md' -Recurse

            foreach($WAFFile in $WAFFiles)
                {
                    $WAFFileDetail = Get-Content -Path $WAFFile.FullName -Raw

                    if($WAFFileDetail -notlike '*## Categories List*' -and $WAFFileDetail -notlike '*## Services List*' -and ![string]::IsNullOrEmpty($WAFFile))
                        {
                            if(![string]::IsNullOrEmpty($WAFFileDetail))
                                {
                                    $MDTopic = $WAFFileDetail.split('###')
                                    $MDTopic = $MDTopic[1..($MDTopic.Length - 1)]

                                    Foreach($Topic in $MDTopic)
                                        {
                                            $RecommendationDetails = $Topic.split('**')
                                            $ID = $Topic.split(' - ')[0]
                                            $ID = $ID.Replace(' ','')
                                            $IDNUM = $ID.split('-')[1]
                                            $Category = if($RecommendationDetails[1] -like '*Category*'){$RecommendationDetails[1].split(':')[1]}else{''}
                                            $Title = if(![string]::IsNullOrEmpty($Topic.split('**'))){($Topic.split('**')).split(' - ')[1]}else{''}
                                            $Impact = if($RecommendationDetails[3] -like '*Impact*'){$RecommendationDetails[3].split(':')[1]}else{$RecommendationDetails[1].split(':')[1]}
                                            $BestPractices = if($RecommendationDetails[5] -like '*Guidance*' -or $RecommendationDetails[5] -like '*Recommendation*' ){$RecommendationDetails[6]}else{$RecommendationDetails[4]}

                                            $ReadMore1 = if($RecommendationDetails[5] -like '*Resources*' -and $RecommendationDetails[6].split('[').split(']')[2] -like '*http*')
                                                {
                                                    $RecommendationDetails[6].split('[').split(']')[2].split(')').replace('(','')[0]
                                                }
                                            elseif($RecommendationDetails[7] -like '*Resources*' -and $RecommendationDetails[8].split('[').split(']')[2] -like '*http*')
                                                {
                                                    $RecommendationDetails[8].split('[').split(']')[2].split(')').replace('(','')[0]
                                                }
                                            else
                                                {
                                                    ''
                                                }
                                            $ReadMore2 = if($RecommendationDetails[5] -like '*Resources*' -and $RecommendationDetails[6].split('[').split(']')[4] -like '*http*')
                                                {
                                                    $RecommendationDetails[6].split('[').split(']')[4].split(')').replace('(','')[0]
                                                }
                                            elseif($RecommendationDetails[7] -like '*Resources*' -and $RecommendationDetails[8].split('[').split(']')[4] -like '*http*')
                                                {
                                                    $RecommendationDetails[8].split('[').split(']')[4].split(')').replace('(','')[0]
                                                }
                                            else
                                                {
                                                    ''
                                                }
                                            $tmp = @{
                                                'Implemented?Yes/No' = ('=IF((COUNTIF(ImpactedResources!A:A,"'+$ID+'")=0),"Yes","No")');
                                                'Number of Impacted Resources?' = ('=COUNTIF(ImpactedResources!A:A,"'+$ID+'")');
                                                'Azure Service / Well-Architected' = 'Well Architected';
                                                'Azure Service Category / Well-Architected Area' = $TextInfo.ToTitleCase($WAFCategory.split('-')[1]);
                                                'Azure Service / Well-Architected Topic' = $TextInfo.ToTitleCase($WAFCategory.split('-')[1]);
                                                'Resiliency Category' = $Category;
                                                'ID' = $ID;
                                                'IDNUM' = $IDNUM;
                                                'Recommendation Title' = $Title;
                                                'Health / Risk' = 'Risk';
                                                'Impact' = $Impact;
                                                'Best Practices Guidance' = $BestPractices;
                                                'Read More 1' = $ReadMore1;
                                                'Read More 2' = $ReadMore2;
                                                'Add associated Outage TrackingID and/or Support Request # and/or Service Retirement TrackingID' = '';
                                                'Observation / Annotation' = '';
                                                'Next Steps - Recommended Microsoft Services' = ''
                                            }

                                            $Global:Recommendations += $tmp
                                        }
                                }
                        }
                }
        }


        $Styles = @(
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 14 -Range "A1:B1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 18 -Range "C1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 25 -Range "D1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 35 -Range "E1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 20 -Range "F1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 10 -Range "G1:H1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 55 -Range "I1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 10 -Range "J1:K1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 90 -Range "L1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -FontColor "White" -VerticalAlignment Center -Bold -WrapText -BackgroundColor "DarkSlateGray" -Width 35 -Range "M1:Q1"
        New-ExcelStyle -HorizontalAlignment Center -FontName 'Calibri' -FontSize 11 -VerticalAlignment Center -WrapText -Range "A:Q"
        )

        # Configure the array of fields to be used in the Recommendations sheet
        $FinalWorksheet = New-Object System.Collections.Generic.List[System.Object]
        $FinalWorksheet.Add('Implemented?Yes/No')
        $FinalWorksheet.Add('Number of Impacted Resources?')
        $FinalWorksheet.Add('Azure Service / Well-Architected')
        $FinalWorksheet.Add('Azure Service Category / Well-Architected Area')
        $FinalWorksheet.Add('Azure Service / Well-Architected Topic')
        $FinalWorksheet.Add('Resiliency Category')
        $FinalWorksheet.Add('ID')
        $FinalWorksheet.Add('IDNUM')
        $FinalWorksheet.Add('Recommendation Title')
        $FinalWorksheet.Add('Health / Risk')
        $FinalWorksheet.Add('Impact')
        $FinalWorksheet.Add('Best Practices Guidance')
        $FinalWorksheet.Add('Read More 1')
        $FinalWorksheet.Add('Read More 2')
        $FinalWorksheet.Add('Add associated Outage TrackingID and/or Support Request # and/or Service Retirement TrackingID')
        $FinalWorksheet.Add('Observation / Annotation')
        $FinalWorksheet.Add('Next Steps - Recommended Microsoft Services')

        # Creates the recommendations sheet in Excel
        $Global:Recommendations | ForEach-Object { [PSCustomObject]$_ } | Select-Object $FinalWorksheet |
                Export-Excel -Path $ExcelFile -WorksheetName 'Recommendations' -TableName 'Table1' -AutoSize -TableStyle $tableStyle -Style $Styles -MoveToStart

        # Creates the empty PivotTable sheet to be used later
        "" | Export-Excel -Path $ExcelFile -WorksheetName 'PivotTable'

        # Creates the Charts sheet and already add the first line with the yellow background
        $StyleOver = New-ExcelStyle -Range A1:G1 -Bold -FontSize 11 -BackgroundColor ([System.Drawing.Color]::Yellow) -Merge -HorizontalAlignment Left
        "Copy the Charts below to your Word and Powerpoint Documents" | Export-Excel -Path $ExcelFile -WorksheetName 'Charts' -Style $StyleOver

        # Open the Excel file to add the Pivot Tables and Charts
        $Excel = Open-ExcelPackage -Path $ExcelFile

        $PTParams = @{
            PivotTableName          = "P0"
            Address                 = $Excel.PivotTable.cells["A3"]
            SourceWorkSheet         = $Excel.Recommendations
            PivotRows               = @("Azure Service / Well-Architected","Azure Service / Well-Architected Topic")
            PivotColumns            = @("Impact")
            PivotData               = @{"Azure Service Category / Well-Architected Area" = "Count" }
            PivotTableStyle         = 'Medium8'
            Activate                = $true
            PivotFilter             = 'Implemented?Yes/No'
            ShowPercent             = $true
            IncludePivotChart       = $true
            #ShowCategory            = $true
            ChartType               = "BarClustered"
            ChartRow                = 80
            ChartColumn             = 3
            NoLegend                = $false
            ChartTitle              = 'Recommendations per Services/Well-Architected Area'
            ChartHeight             = 696
            ChartWidth              = 450
        }
        Add-PivotTable @PTParams


        $PTParams = @{
            PivotTableName          = "P1"
            Address                 = $Excel.PivotTable.cells["H3"]
            SourceWorkSheet         = $Excel.Recommendations
            PivotRows               = @("Resiliency Category")
            PivotColumns            = @("Impact")
            PivotData               = @{"Resiliency Category" = "Count" }
            PivotTableStyle         = 'Medium9'
            Activate                = $true
            PivotFilter             = 'Implemented?Yes/No'
            ShowPercent             = $true
            IncludePivotChart       = $true
            ChartType               = "BarClustered"
            ChartRow                = 80
            ChartColumn             = 30
            NoLegend                = $false
            ChartTitle              = 'Recommendations per Resiliency Category'
            ChartHeight             = 569
            ChartWidth              = 462
        }
        Add-PivotTable @PTParams


        $PTParams = @{
            PivotTableName          = "P2"
            Address                 = $Excel.PivotTable.cells["O3"]
            SourceWorkSheet         = $Excel.Recommendations
            PivotRows               = @("Health / Risk")
            PivotColumns            = @("Impact")
            PivotData               = @{"Health / Risk" = "Count" }
            PivotTableStyle         = 'Medium14'
            Activate                = $true
            PivotFilter             = 'Implemented?Yes/No'
            ShowPercent             = $true
            IncludePivotChart       = $true
            ChartType               = "Pie"
            ChartRow                = 80
            ChartColumn             = 60
            NoLegend                = $false
            ChartTitle              = 'Health x Risk issues'
            ChartHeight             = 206
            ChartWidth              = 463
        }
        Add-PivotTable @PTParams

        $PTParams = @{
            PivotTableName          = "P3"
            Address                 = $Excel.PivotTable.cells["V3"]
            SourceWorkSheet         = $Excel.Recommendations
            PivotRows               = @("Next Steps - Recommended Microsoft Services")
            PivotTableStyle         = 'Light16'
            Activate                = $true
            PivotFilter             = 'Implemented?Yes/No'
            ShowPercent             = $true
        }
        Add-PivotTable @PTParams

        Close-ExcelPackage $Excel

        Write-Host "Customizing Excel Charts. "
        # Open the Excel using the API to move the charts from the PivotTable sheet to the Charts sheet and change chart style, font, etc..
        Write-Debug 'Openning Excel Application'
        $ExcelApplication = New-Object -ComObject Excel.Application
        Start-Sleep -Seconds 2
        if ($ExcelApplication) {
            Write-Debug 'Openning Excel File'
            $Ex = $ExcelApplication.Workbooks.Open($ExcelFile)
            Start-Sleep -Seconds 2
            Write-Debug 'Openning Excel Sheets'
            $WS = $ex.Worksheets | Where-Object { $_.Name -eq 'PivotTable' }
            $WS2 = $ex.Worksheets | Where-Object { $_.Name -eq 'Charts' }
            Write-Debug 'Moving Charts to Chart sheet'
            ($WS.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Cut()
            $WS2.Paste()
            ($WS.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Cut()
            $WS2.Paste()
            ($WS.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Cut()
            $WS2.Paste()

            Write-Debug 'Reloading Excel Chart Sheet'
            $WS2 = $ex.Worksheets | Where-Object { $_.Name -eq 'Charts' }

            Write-Debug 'Editing ChartP0'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Chart.ChartStyle = 222
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Chart.ChartArea.Font.Name = 'Segoe UI'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Chart.ChartArea.Font.Size = 9
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Chart.ChartArea.Left = 18
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP0' }).DrawingObject.Chart.ChartArea.Top = 40

            Write-Debug 'Editing ChartP1'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Chart.ChartStyle = 222
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Chart.ChartArea.Font.Name = 'Segoe UI'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Chart.ChartArea.Font.Size = 9
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Chart.ChartArea.Left = 555
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP1' }).DrawingObject.Chart.ChartArea.Top = 40

            Write-Debug 'Editing ChartP2'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Chart.ChartStyle = 222
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Chart.ChartArea.Font.Name = 'Segoe UI'
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Chart.ChartArea.Font.Size = 9
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Chart.ChartArea.Left = 555
            ($WS2.Shapes | Where-Object { $_.name -eq 'ChartP2' }).DrawingObject.Chart.ChartArea.Top = 490

            Write-Debug 'Editing Pivot Filters'
            $WS.Range("B1").Formula = 'No'
            $WS.Range("I1").Formula = 'No'
            $WS.Range("P1").Formula = 'No'
            $WS.Range("W1").Formula = 'No'

            Write-Debug 'Saving File'
            $Ex.Save()
            Write-Debug 'Closing Excel Application'
            $Ex.Close()
            $ExcelApplication.Quit()
            # Ensures the Excel process opened by the API is closed
            Write-Debug 'Ensuring Excel Process is Closed.'
            Get-Process -Name "excel" -ErrorAction Ignore | Where-Object {$_.CommandLine -like '*/automation*'} | Stop-Process
        }


        # [Optional] - export errors to a separate file
        if ($errors.Count -gt 0) {
            $errors | Export-Csv -Path "Errors.csv" -NoTypeInformation
        }

    }

    #Call the functions
    if($Help.IsPresent)
        {
            Help
            Exit
        }
    
    Write-Debug "Checking Parameters"
    CheckParameters

    Write-Debug "Reseting Variables"
    Variables

    Write-Debug "Calling Function: Requirements"
    Requirements

    Write-Debug "Calling Function: LocalFiles"
    LocalFiles

    Write-Debug "Calling Function: ConnectToAzure"
    ConnectToAzure

    Write-Debug "Calling Function: Subscriptions"
    Subscriptions

    Write-Debug "Calling Function: ResourceExtraction"
    ResourceExtraction

    Write-Debug "Calling Function: ExcelFile"
    ExcelFile

}

$TotalTime = $Global:Runtime.Totalminutes.ToString('#######.##')

Write-Host "---------------------------------------------------------------------"
Write-Host ('Execution Complete. Total Runtime was: ') -NoNewline
Write-Host $TotalTime -NoNewline -ForegroundColor Cyan
Write-Host (' Minutes')
Write-Host "Excel File: " -NoNewline
Write-Host $Global:ExcelFile -ForegroundColor Blue
Write-Host "---------------------------------------------------------------------"