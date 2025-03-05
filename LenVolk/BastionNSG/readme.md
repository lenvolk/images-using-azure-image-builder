# Network Security Group Deployment Template

This template deploys a Network Security Group (NSG) with predefined security rules and associates it with an existing subnet in a specified resource group.

## Template Overview

The template creates the following resources:
1. Network Security Group with Bastion-compatible security rules
2. Association of the NSG with an existing subnet

## Architecture Diagram

```mermaid
graph TD
    A[ARM Template: NSG-subnet.json] --> B[Network Security Group]
    B --> |Contains| C[Inbound Security Rules]
    B --> |Contains| D[Outbound Security Rules]
    A --> E[Nested Deployment]
    E --> |Updates| F[Existing Subnet]
    B --> |Associated with| F
    
    subgraph "Inbound Rules"
    C --> C1[AllowHttpsInBound]
    C --> C2[AllowGatewayManagerInBound]
    C --> C3[AllowLoadBalancerInBound]
    C --> C4[AllowBastionHostCommunicationInBound]
    C --> C5[DenyAllInBound]
    end
    
    subgraph "Outbound Rules"
    D --> D1[AllowSshRdpOutBound]
    D --> D2[AllowAzureCloudCommunicationOutBound]
    D --> D3[AllowBastionHostCommunicationOutBound]
    D --> D4[AllowGetSessionInformationOutBound]
    D --> D5[DenyAllOutBound]
    end
    
    subgraph "Parameters"
    G[resourceGroupName] --> A
    H[nsgName] --> A
    I[subnetId] --> A
    J[location] --> A
    end
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| resourceGroupName | Name of the existing resource group where the subnet is located |
| nsgName | Name of the Network Security Group to create |
| subnetId | Resource ID of the existing subnet to associate with the NSG |
| location | Azure region for NSG |

## Deployment

To deploy this template:

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file NSG-subnet.json \
  --parameters \
    resourceGroupName="myResourceGroup" \
    nsgName="BastionNSG" \
    subnetId="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Network/virtualNetworks/myVnet/subnets/mySubnet" \
    location="eastus"
```

## Output

- **nsgId**: Resource ID of the created Network Security Group
