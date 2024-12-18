
<# 
//-----------------------------------------------------------------------

THE SUBJECT SCRIPT IS PROVIDED “AS IS” WITHOUT ANY WARRANTY OF ANY KIND AND SHOULD ONLY BE USED FOR TESTING OR DEMO PURPOSES.
YOU ARE FREE TO REUSE AND/OR MODIFY THE CODE TO FIT YOUR NEEDS

//-----------------------------------------------------------------------

.SYNOPSIS
Attest at scale fof Azure Arc-enabled servers to enroll in Windows Server Management enabled by Azure Arc.

.DESCRIPTION
The script uses the  query.kusto  file to get the list of Arc-enabled servers that are eligible for Software Assurance. The script then attests the servers by setting the  softwareAssuranceCustomer  property to  true . 

.NOTES
File Name : attestArcServers.ps1
Author    : Cobey Errett
Version   : 1.0
Date      : 05-November-2024
Update    : 05-November-2024
Tested on : PowerShell Version 7.4.6
Requires  : Powershell Core version 7.x or later
Product   : Azure ARC

.LINK
To get more information on Azure ARC Attestation please visit:
https://learn.microsoft.com/en-us/azure/azure-arc/servers/windows-server-management-overview?branch=main&branchFallbackFrom=pr-en-us-216&tabs=powershell#enrollment

.EXAMPLE-1
./attestArcServers.ps1 -subscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
-tenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `

This command attests the Arc-enabled servers.
#>
##############################
#Parameters definition block #
##############################


param(
    [Parameter(Mandatory=$true, HelpMessage="The ID of the subscription where the license will be created.")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', ErrorMessage="The input '{0}' has to be a valid subscription ID.")]
    [Alias("sub")]
    [string]$subscriptionId,
    [Parameter(Mandatory=$true, HelpMessage="The tenant ID of the Microsoft Entra instance used for authentication.")]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', ErrorMessage="The input '{0}' has to be a valid tenant ID.")]
    [string]$tenantId
)

#####################################
#End of Parameters definition block #
#####################################

##############################
# Variables definition block #
##############################




#########################################
# End of the variables definition block #
#########################################

################################
# Function(s) definition block #
################################

function Get-AzureADBearerToken {
    param(
        [Parameter(Mandatory=$true, HelpMessage="The tenant ID of the Microsoft Entra instance used for authentication.")]
        [string]$tenantId,
        [Parameter(Mandatory=$true, HelpMessage="The subscription ID of the Microsoft Entra instance used for authentication.")]
        [string]$subscriptionId
    )

    try {
        $account       = Connect-AzAccount -Subscription $subscriptionId -Tenant $tenantId
        $context       = Set-azContext -Subscription $subscriptionId 
        $profile       = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile 
        $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.rmProfileClient]::new( $profile ) 
        $token         = $profileClient.AcquireAccessToken($context.Subscription.TenantId) 
        $header = @{ 
            'Content-Type'='application/json' 
            'Authorization'='Bearer ' + $token.AccessToken
        }
        return $header
    }
    catch {
        Write-Error "Error obtaining Bearer token: $_"
        return $null
    }
     
    

}

#Set the Software Assurance attestation for the Arc Enabled Servers
function Set-Attestation {
    param (
        [string]$subscriptionId,
        [string]$resourceGroupName,
        [string]$machineName,
        [string]$location
        )
    
    try {
        $uri = [System.Uri]::new( "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.HybridCompute/machines/$machineName/licenseProfiles/default?api-version=2023-10-03-preview" ) 
        $contentType = "application/json"
        $data = @{         
            location = $location; 
            properties = @{ 
                softwareAssurance = @{ 
                    softwareAssuranceCustomer= $true; 
                }; 
            }; 
        };  
        $json = $data | ConvertTo-Json; 
        $response = Invoke-RestMethod -Method PUT -Uri $uri.AbsoluteUri -ContentType $contentType -Headers $header -Body $json; 
        $response.properties

    }
    catch {
        
        $json = $_ | ConvertFrom-Json
        $StatusCode = $json.error.code
        $StatusException = $json.error.message
        Write-Host "$machineName StatusCode: $StatusCode StatusDescription: $StatusException"
        Write-Output "$machineName StatusCode: $StatusCode StatusDescription: $StatusException" | Out-File -FilePath .\output.txt -Append
    }

}

#######################################
# End of Function(s) definition block #
#######################################


#####################
# Main script block #
#####################

#Kusto query for the Arc Enabled Servers eligible for Software Assurance
$query = Get-Content .\query.kusto

#Loop through the Arc Enabled Servers and set the Software Assurance attestation
$counter = 0

$header = Get-AzureADBearerToken -tenantId $tenantId -subscriptionId $subscriptionId

#Get the Arc Enabled Servers eligible for Software Assurance
$graphuri = [System.Uri]::new( "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2022-10-01" )
$contentType = "application/json"  
$data = @{         
    query = "$query"
}; 
$queryjson = $data | ConvertTo-Json; 
$graphResponse = Invoke-RestMethod -Method Post -Uri $graphuri.AbsoluteUri -ContentType $contentType -Headers $header -Body $queryjson; 



$graphResponse.data | ForEach-Object {
    $counter++
        
    Set-Attestation -subscriptionId $_.subscriptionId -resourceGroupName $_.resourceGroup -machineName $_.name -location $_.location
    Write-Progress -Activity "Setting Software Assurance attestation for Arc Enabled Servers" -Status "Processing $_.name" -PercentComplete ($counter / $graphResponse.data.Count * 100)
}


