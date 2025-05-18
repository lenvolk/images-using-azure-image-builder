# filepath: c:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\MachineConfig\LAMPServer.ps1

# Check for required modules
$requiredModules = @("Az.Accounts", "PSDesiredStateConfiguration", "GuestConfiguration", "nx", "PSDscResources")
$modulesToInstall = @()

foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        $modulesToInstall += $module
    }
}

if ($modulesToInstall.Count -gt 0) {
    Write-Host "The following required modules are not installed: $($modulesToInstall -join ", ")" -ForegroundColor Yellow
    $installModules = Read-Host "Do you want to install these modules now? (Y/N)"
    
    if ($installModules -eq "Y" -or $installModules -eq "y") {
        foreach ($module in $modulesToInstall) {
            try {
                Write-Host "Installing module $module..." -ForegroundColor Cyan
                Install-Module -Name $module -Repository PSGallery -Force -AllowClobber
                Write-Host "Module $module installed successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to install module $module. Error: $_" -ForegroundColor Red
                Write-Host "Please install the required modules manually and try again." -ForegroundColor Yellow
                exit
            }
        }
    }
    else {
        Write-Host "Please install the required modules manually and try again." -ForegroundColor Yellow
        exit
    }
}

# Check Azure authentication
try {
    $azContext = Get-AzContext -ErrorAction Stop
    
    if (-not $azContext) {
        Write-Host "You are not authenticated to Azure. Please sign in." -ForegroundColor Yellow
        Connect-AzAccount
        $azContext = Get-AzContext
        
        if (-not $azContext) {
            Write-Host "Authentication failed. Exiting script." -ForegroundColor Red
            exit
        }
    }
    else {
        Write-Host "Already authenticated to Azure as $($azContext.Account.Id)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Az module is installed but there was an error checking authentication. Attempting to authenticate..." -ForegroundColor Yellow
    try {
        Connect-AzAccount
        $azContext = Get-AzContext
        
        if (-not $azContext) {
            Write-Host "Authentication failed. Exiting script." -ForegroundColor Red
            exit
        }
    }
    catch {
        Write-Host "Failed to authenticate to Azure. Error: $_" -ForegroundColor Red
        exit
    }
}

# List and select subscription
$subscriptions = Get-AzSubscription
$subscriptionCount = $subscriptions.Count

# Handle subscription selection - use complete if block instead of separate statements
if ($subscriptionCount -eq 0) {
    Write-Host "No subscriptions found for this account. Please check your Azure account permissions." -ForegroundColor Red
    exit
} 
if ($subscriptionCount -eq 1) {
    $selectedSubscriptionId = $subscriptions[0].Id
    Write-Host "Only one subscription available. Using subscription: $($subscriptions[0].Name) ($selectedSubscriptionId)" -ForegroundColor Green
    Set-AzContext -SubscriptionId $selectedSubscriptionId | Out-Null
}
if ($subscriptionCount -gt 1) {
    Write-Host "`nAvailable subscriptions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $subscriptionCount; $i++) {
        Write-Host "[$($i+1)] $($subscriptions[$i].Name) - $($subscriptions[$i].Id)"
    }
    
    $validSelection = $false
    
    while (-not $validSelection) {
        try {
            [int]$selection = Read-Host "`nSelect a subscription (1-$subscriptionCount)"
            
            if ($selection -ge 1 -and $selection -le $subscriptionCount) {
                $selectedSubscriptionId = $subscriptions[$selection-1].Id
                Write-Host "Setting context to subscription: $($subscriptions[$selection-1].Name) ($selectedSubscriptionId)" -ForegroundColor Green
                Set-AzContext -SubscriptionId $selectedSubscriptionId | Out-Null
                $validSelection = $true
            }
            else {
                Write-Host "Invalid selection. Please enter a number between 1 and $subscriptionCount." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
        }
    }
}

# Verify that we can proceed with the current subscription context
$currentContext = Get-AzContext
Write-Host "Using subscription: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -ForegroundColor Green
Write-Host "Continuing with script execution...`n" -ForegroundColor Cyan

#Author a configuration
configuration LAMPServer {
    Import-DSCResource -ModuleName nx
 
    Node localhost {
 
         $requiredPackages = @("httpd","mod_ssl","php","php-mysqlnd","mariadb","mariadb-server")
         $enabledServices = @("httpd","mariadb")         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageManager = "yum"
             }
         }
 
         #Ensure daemons are enabled
         ForEach ($service in $enabledServices){
             nxService $service{
                 Enabled = $true
                 Name = $service
                 Controller = "SystemD"
                 State = "running"
             }
         }
    }
 }

LAMPServer

# Create a package that will audit and apply the configuration (Set)
$params = @{
    Name          = 'LAMPServer'
    Configuration = './LAMPServer/localhost.mof'
    Type          = 'AuditAndSet'
    Force         = $true
}
New-GuestConfigurationPackage @params

# # Get the current compliance results for the local machine
# Get-GuestConfigurationPackageComplianceStatus -Path ./LAMPServer.zip
# # Test applying the configuration to local machine
# Start-GuestConfigurationPackageRemediation -Path ./LAMPServer.zip

#Create a policy definition that enforces a custom configuration package, in a specified path
$demoguid = New-Guid

# Ask user if they want to upload the package to Azure Storage or use existing URI
$useExistingUri = Read-Host "Do you want to use an existing storage URI for the configuration package? (Y/N)"

if ($useExistingUri -eq "Y" -or $useExistingUri -eq "y") {
    $contentUri = Read-Host "Enter the URI for the configuration package (including SAS token)"
}
else {
    # Ask user for storage account information
    Write-Host "`nTo upload the configuration package, we need a storage account." -ForegroundColor Cyan
    
    $resourceGroupName = Read-Host "Enter the resource group name for storage account"
    $storageAccountName = Read-Host "Enter the storage account name"
    
    try {
        # Check if storage account exists
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
        
        if (-not $storageAccount) {
            Write-Host "Storage account not found. Creating new storage account..." -ForegroundColor Yellow
            $location = Read-Host "Enter the location for the new storage account (e.g., eastus)"
            $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS
        }
        
        # Create container if it doesn't exist
        $containerName = "machine-configuration"
        $ctx = $storageAccount.Context
        $container = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue
        
        if (-not $container) {
            Write-Host "Creating container '$containerName'..." -ForegroundColor Yellow
            New-AzStorageContainer -Name $containerName -Context $ctx -Permission Off | Out-Null
        }
        
        # Upload the package
        Write-Host "Uploading LAMPServer.zip to storage..." -ForegroundColor Cyan
        $blobName = "LAMPServer.zip"
        $blob = Set-AzStorageBlobContent -File "./LAMPServer.zip" -Container $containerName -Blob $blobName -Context $ctx -Force
        
        # Generate SAS token
        $startTime = Get-Date
        $expiryTime = $startTime.AddDays(7)
        $sasToken = New-AzStorageBlobSASToken -Container $containerName -Blob $blobName -Permission r -StartTime $startTime -ExpiryTime $expiryTime -Context $ctx
        
        # Construct full URI with SAS token
        $contentUri = "$($blob.BlobBaseClient.Uri)$sasToken"
        Write-Host "Package uploaded successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error uploading package to storage: $_" -ForegroundColor Red
        $contentUri = Read-Host "Please enter a valid URI for the configuration package (including SAS token)"
    }
}

# Proceed with policy creation
Write-Host "`nCreating Guest Configuration policy..." -ForegroundColor Cyan

try {
    # Create directory for policy if it doesn't exist
    if (!(Test-Path "./policies")) {
        New-Item -ItemType Directory -Path "./policies" | Out-Null
    }

    $PolicyConfig = @{
        PolicyId      = $demoguid
        ContentUri    = $contentUri
        DisplayName   = "LAMP server configuration (RHEL)"
        Description   = "Configures Apache HTTP Server, MySQL, and PHP on RHEL Linux machine"
        Path          = "./policies/deployIfNotExists.json"
        Platform      = "Linux"
        PolicyVersion = "1.0.0"
        Mode          = "ApplyAndAutoCorrect"
        Tag           = @{
            InstallLampRHEL = "true"
        }
    }
      
    New-GuestConfigurationPolicy @PolicyConfig

    Write-Host "Guest Configuration policy created successfully." -ForegroundColor Green
    
    # Create Azure Policy Definition
    try {
        Write-Host "Creating Azure Policy Definition..." -ForegroundColor Cyan
        $policyDefPath = '.\policies\deployIfNotExists.json\LAMPServer_DeployIfNotExists.json'
        
        if (Test-Path $policyDefPath) {
            $policyDefinition = New-AzPolicyDefinition -Name 'LAMPServerPolicy' -Policy $policyDefPath
            Write-Host "Azure Policy Definition created successfully with ID: $($policyDefinition.PolicyDefinitionId)" -ForegroundColor Green
            
            # Ask if user wants to assign the policy
            $assignPolicy = Read-Host "Do you want to assign this policy to a scope? (Y/N)"
            
            if ($assignPolicy -eq "Y" -or $assignPolicy -eq "y") {
                # Get scope for assignment
                Write-Host "`nSelect the scope for policy assignment:" -ForegroundColor Cyan
                Write-Host "[1] Current subscription"
                Write-Host "[2] Resource group"
                  $validScopeSelection = $false
                $rgName = $null
                $location = $null
                
                while (-not $validScopeSelection) {
                    try {
                        [int]$scopeSelection = Read-Host "`nEnter scope selection (1-2)"
                        
                        if ($scopeSelection -eq 1) {
                            # Subscription scope
                            $scope = "/subscriptions/$($currentContext.Subscription.Id)"
                            # For subscription level, we need to specify a location for the managed identity
                            $locations = Get-AzLocation | Where-Object {$_.Providers -contains "Microsoft.Authorization"}
                            Write-Host "`nAvailable locations for policy assignment:" -ForegroundColor Cyan
                            for ($i = 0; $i -lt [Math]::Min(10, $locations.Count); $i++) {
                                Write-Host "[$($i+1)] $($locations[$i].DisplayName) - $($locations[$i].Location)"
                            }
                            
                            $validLocationSelection = $false
                            while (-not $validLocationSelection) {
                                try {
                                    [int]$locationSelection = Read-Host "`nSelect a location for the managed identity (1-$([Math]::Min(10, $locations.Count)))"
                                    
                                    if ($locationSelection -ge 1 -and $locationSelection -le [Math]::Min(10, $locations.Count)) {
                                        $location = $locations[$locationSelection-1].Location
                                        $validLocationSelection = $true
                                    }
                                    else {
                                        Write-Host "Invalid selection. Please enter a number between 1 and $([Math]::Min(10, $locations.Count))." -ForegroundColor Red
                                    }
                                }
                                catch {
                                    Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
                                }
                            }
                            $validScopeSelection = $true
                        }
                        elseif ($scopeSelection -eq 2) {
                            # Resource group scope
                            $rgName = Read-Host "Enter resource group name"
                            try {
                                $rg = Get-AzResourceGroup -Name $rgName -ErrorAction Stop
                                $location = $rg.Location
                                $scope = "/subscriptions/$($currentContext.Subscription.Id)/resourceGroups/$rgName"
                                $validScopeSelection = $true
                            }
                            catch {
                                Write-Host "Resource group '$rgName' not found. Please check the name and try again." -ForegroundColor Red
                            }
                        }
                        else {
                            Write-Host "Invalid selection. Please enter 1 or 2." -ForegroundColor Red
                        }
                    }
                    catch {
                        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
                    }                }                
                
                # Assign the policy with a managed identity (required for deployIfNotExists policies)
                $assignmentName = "LAMPServer-" + (Get-Random -Minimum 100000 -Maximum 999999)
                
                try {
                    # Convert policy parameters to JSON string first
                    $parameterObject = @{
                        IncludeArcMachines = @{
                            value = $true
                        }
                    }
                    
                    # Convert to JSON and back to ensure proper formatting
                    $parameterJson = $parameterObject | ConvertTo-Json -Depth 3
                    Write-Host "Using parameter JSON: $parameterJson" -ForegroundColor Cyan
                    
                    # First create the policy assignment without parameters to test
                    Write-Host "Creating policy assignment with managed identity..." -ForegroundColor Cyan
                    $policyAssignment = New-AzPolicyAssignment -Name $assignmentName `
                                                              -PolicyDefinition $policyDefinition `
                                                              -Scope $scope `
                                                              -AssignIdentity `
                                                              -Location $location
                    
                    # If we need to assign contributor role to the managed identity
                    # The managed identity needs permissions to create resources for the Guest Configuration
                    Write-Host "Policy assigned successfully with name: $($policyAssignment.Name)" -ForegroundColor Green
                    Write-Host "A system-assigned managed identity was created for the policy assignment." -ForegroundColor Green
                    
                    # Now try to update the assignment with parameters
                    Write-Host "Updating policy assignment to include Arc-connected machines..." -ForegroundColor Cyan
                    try {
                        # Look at the policy parameter file to see if it has an IncludeArcMachines parameter
                        $policyContent = Get-Content -Path $policyDefPath -Raw | ConvertFrom-Json
                        if ($policyContent.properties.policyRule.then.details.deployment.properties.parameters.IncludeArcMachines -ne $null) {
                            # Update the existing assignment with parameters
                            $policyAssignment = Set-AzPolicyAssignment -Id $policyAssignment.Id `
                                                                      -PolicyParameterObject $parameterObject
                            Write-Host "Policy updated to include Azure Arc-connected machines." -ForegroundColor Green
                        }
                        else {
                            Write-Host "The policy does not have an 'IncludeArcMachines' parameter. Azure Arc-connected machines may not be included." -ForegroundColor Yellow
                        }
                    }
                    catch {
                        Write-Host "Could not update policy to include Arc machines: $_" -ForegroundColor Yellow
                        Write-Host "Continuing with standard Azure VMs only." -ForegroundColor Yellow
                    }
                      # Check if policy assignment was successful and has an identity
                    if ($policyAssignment -and $policyAssignment.Identity -and $policyAssignment.Identity.PrincipalId) {
                        # Assign the Contributor role to the policy assignment's managed identity
                        $roleDefinitionId = (Get-AzRoleDefinition -Name "Contributor").Id
                        Write-Host "Assigning Contributor role to the managed identity..." -ForegroundColor Cyan
                        
                        # We need to wait briefly for the managed identity to propagate
                        Write-Host "Waiting 30 seconds for managed identity to propagate..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 30
                        
                        try {
                            $principalId = $policyAssignment.Identity.PrincipalId
                            Write-Host "Managed Identity Principal ID: $principalId" -ForegroundColor Cyan
                            
                            New-AzRoleAssignment -Scope $scope `
                                                -ObjectId $principalId `
                                                -RoleDefinitionId $roleDefinitionId -ErrorAction Stop | Out-Null
                                                
                            Write-Host "Contributor role assigned successfully to the managed identity." -ForegroundColor Green
                            Write-Host "The policy is now fully configured and ready to enforce the configuration." -ForegroundColor Green
                        }
                        catch {
                            Write-Host "Error assigning role: $_" -ForegroundColor Red
                            Write-Host "You will need to manually assign the Contributor role to the policy assignment's managed identity." -ForegroundColor Yellow
                            Write-Host "Policy Assignment ID: $($policyAssignment.Id)" -ForegroundColor Yellow
                            Write-Host "Principal ID: $($policyAssignment.Identity.PrincipalId)" -ForegroundColor Yellow
                        }
                    }
                    else {
                        Write-Host "Policy assignment was created but managed identity information is not available." -ForegroundColor Yellow
                        Write-Host "You will need to manually assign the Contributor role to the policy assignment's managed identity." -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Error assigning policy or role: $_" -ForegroundColor Red
                    Write-Host "You may need to manually assign the Contributor role to the policy assignment's managed identity." -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "Policy definition file not found at path: $policyDefPath" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error creating Azure Policy Definition: $_" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error creating Guest Configuration policy: $_" -ForegroundColor Red
}