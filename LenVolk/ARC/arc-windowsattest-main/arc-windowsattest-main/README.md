# Software Assurance Attestation for Azure Arc Windows Servers

## Description


The script uses the  [query.kusto](./query.kusto) file to get the list of Arc-enabled servers that are eligible for Software Assurance. The script then attests the servers by setting the  softwareAssuranceCustomer  property to  true . It is based on the script published on [Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-arc/servers/windows-server-management-overview?branch=main&branchFallbackFrom=pr-en-us-216&tabs=powershell#enrollment) .
 
The  *Set-Attestation*  function is used to attest the servers. The function takes the subscription ID, resource group name, machine name, and location as parameters. The function then sends a PUT request to the  Azure Arc API endpoint to attest the server.

The script will get the list of Arc-enabled servers that are eligible for Software Assurance and attest the servers by setting the  softwareAssuranceCustomer  property to  true .

## Prerequisites

 - An Microsoft Entra ID tenant as well as an active Azure subscription.
 - Windows Server(s) already onboarded to the Azure ARC platform. Please check the [Connected Machine agent prerequisites](https://learn.microsoft.com/en-us/azure/azure-arc/servers/prerequisites) to ensure your servers are ready for onboarding.
 - The Microsoft Entra application ID and secret key for the service principal created above.

## Azure rights required for the scripts to work

The following rights have to be delegated on the resource groups you plan on using to store the ESU licence objects as well as the resource groups containing the Azure ARC servers:

- "Microsoft.HybridCompute/machines/*/read"
- "Microsoft.HybridCompute/machines/*/write"

There is a custom role definition located in the Custom Roles folder in this repository that can be used to create a custom role with the required rights. Please check the [Create a custom role using Azure PowerShell](https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles-powershell#create-a-custom-role-using-azure-powershell) to create a custom role with the custom role definition.

## Running the script 
 
<p>To run the script, open a Powershell (Ideally from CloudShell) window and run the following command:</p> 

1. git clone https://github.com/cobeyerrett/arc-windowsattest.git
 2. .\arc-windowsattest\attestArcServers.ps1 -subscriptionId YOUR_SUBID -tenantId YOUR_TENANTID

## Verification of Attestation

The attestation of the Windows SA licensing can be achieved by running the resource graph [verifySAattestation.kusto](./verifySAattestation.kusto) KQL query in your environment.

## Resources

### Navigating the source code

This project has the following structure:

File/Folder | Description
---|---
[attestArcServers.ps1](./attestArcServers.ps1) | Main powershell file to attest the Windows Software Assurance for Azure Arc connected machines
[query.kusto](./query.kusto) | The kusto (KQL) query to obtain the Arc-enabled Windows servers to attest 
[verifySAattestation.kusto](./verifySAattestation.kusto) | The kusto (KQL) query to verify the Arc-enabled Windows servers have been attested 
