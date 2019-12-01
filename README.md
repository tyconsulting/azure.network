# Azure Network Pattern for Tao's Lab 

This repository contains the Network pattern for Tao's lab Azure tenant. In deploys the following resources to multiple subscriptions within a same Azure AD tenant:

* AHub VNet in the management sub
* Multiple Spoke VNets across multiple workload subs
* VNet peering between the hub and all spoke vnets
* (Optional) Site-to-Site VPN to on-prem network, which consists of VPN gateway, local network gateway and VPN connection.
* (Optional) A subnet dedicated for Azure AD DS in the Hub VNet. - AADDS itself is not part of this pattern.
* Various Bastion Hosts for several VNets
* A NSG for each VNet
* A Private DNS Zone that is linked to all the Hub and Spoke VNets

## Network Configuration

The network pattern consists of a hub Vnet and multiple spoke Vnets spanned across multiple subscriptions within a same Azure AD tenant (as shown below)
![001](./images/lab_vnet_diagram.png)

### Hub Networks

| Subscription | VNet Name | Type | Address Space | Location | Resource Group | Bastion Enabled |
|:------------:|:---------:|:----:|:-------------:|:--------:|:--------------:|:---------------:|
| Management Sub | vnet-hub01 | Hub | 10.100.0.0/16 | Australia East | rg-network-hub | Yes |

### Spoke Networks

| Subscription | VNet Name | Type | Address Space | Location | Resource Group | Bastion Enabled |
|:------------:|:---------:|:----:|:-------------:|:--------:|:--------------:|:---------------:|
| Workload Sub #1 | vnet-spoke-w0101 | Spoke | 10.111.0.0/16 | Australia East | rg-network-spoke-101 | Yes |
| Workload Sub #1 | vnet-spoke-w0102 | Spoke | 10.112.0.0/16 | Australia Southeast | rg-network-spoke-102 | No |
| Workload Sub #1 | vnet-spoke-w0103 | Spoke | 10.113.0.0/16 | Southeast Asia | rg-network-spoke-103 | No |
| Workload Sub #2 | vnet-spoke-w0201 | Spoke | 10.121.0.0/16 | East US | rg-network-spoke-201 | Yes |
| Workload Sub #2 | vnet-spoke-w0202 | Spoke | 10.122.0.0/16 | West Europe | rg-network-spoke-202 | Yes |

## Pipeline Configuration

The Pipeline requires the following objects need to be created in Azure DevOps project:

### Marketplace Extensions

This pipeline uses tasks from the following extensions that can be installed via Azure DevOps Marketplace:
| Name | Link |
|:-----|:-----|
| Pester Test Runner Build Task | <https://marketplace.visualstudio.com/items?itemName=richardfennellBM.BM-VSTS-PesterRunner-Task> |

### Service Connections

| Name | Type | Target |
|:----:|:----:|:------:|
| sub-mgmt | Azure Resource Manager | Management Sub |
| sub-workload-1 | Azure Resource Manager | Workload Sub #1|
| sub-workload-2 | Azure Resource Manager | Workload Sub #2|

### Variable Groups

#### test- network

![002](./images/variable_group_test_network.png)

>**NOTE:** The following variables in variable group **test - network** are used by the Pester test. Do not modify the values unless you have updated the ARM templates for hub VNet, Spoke VNet and VNet Peering.

| Variable Name | Value |
|:-------------|:-----|
| **hubParameters** | 'hubVnetName', 'deployVpnGateway', 'gatewaySku', 'hubVnetPrefix', 'dmzSubnetPrefix', 'mgmtSubnetPrefix', 'sharedSubnetPrefix', 'gatewaySubnetPrefix', 'aaddsSubnetPrefix', 'bastionSubnetPrefix', 'localNetworkAddressPrefixes', 'localGatewayIpAddress', 'vpnConnectionType', 'vpnConnectionProtocol', 'IPSecSharedKey', 'deployBastion', 'deployAaddsSubnet' |
| **hubResources** | 'Microsoft.Network/virtualNetworks', 'Microsoft.Network/publicIPAddresses', 'Microsoft.Network/bastionHosts', 'Microsoft.Network/networkSecurityGroups', 'Microsoft.Network/networkSecurityGroups', 'Microsoft.Network/publicIPAddresses', 'Microsoft.Network/virtualNetworkGateways', 'Microsoft.Network/localNetworkGateways', 'Microsoft.Network/connections' |
| **hubVariables** | 'dmzSubnetName', 'mgmtSubnetName', 'sharedSubnetName', 'gatewaySubnetName', 'aaddsSubnetName', 'gatewayName', 'gatewayPIPName', 'localNetworkGatewayName', 'vpnConnectionName', 'subnetGatewayId', 'nsgName', 'aaddsNsgName', 'bastionSubnetName', 'bastionPipName', 'bastionName' |
| **peeringParameters** | 'localVnetName', 'remoteVnetName', 'remoteVnetSubscriptionId', 'remoteVnetResourceGroup' |
| **peeringResources** | 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings' |
| **spokeParameters** | 'nsgName', 'spokeVnetName', 'spokeVnetPrefix', 'spokeResourceSubnetPrefix', 'spokeBastionSubnetPrefix', 'deployBastion' |
| **spokeResources** | 'Microsoft.Network/virtualNetworks', 'Microsoft.Network/networkSecurityGroups', 'Microsoft.Network/publicIPAddresses', 'Microsoft.Network/bastionHosts' |
| **spokeVariables** | 'spokeResourceSubnetName', 'spokeBastionSubnetName', 'nsgName', 'bastionPipName', 'bastionName' |
| **dnsZoneParameters** | 'zoneName', 'LinkedVNetResourceIds' |
| **dnsZoneResources** | 'Microsoft.Network/privateDnsZones', 'Microsoft.Network/privateDnsZones/virtualNetworkLinks' |

#### variables - network

![003](./images/variable_group_variables_network.png)

>**NOTE:** Modify the following variables in variable group **variables - network** to suit your requirements. The values provided are samples only.

| Variable Name | Sample Value | Comment |
|:--------------|:-------------|:--------|
| **deployAaddsSubnet** | No | *Specify if you want to deploy a subnet in the Hub VNet for Azure AD Domain Services (created seperately)* |
| **deployVpnGateway** | No | *Specify if you want to deploy a VPN gateway (for site-to-site VPN) |
| **hubLocation** | Australia East | *Specify the location of Hub VNet. if This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [hub.network.azuredeploy.parameters.json](./templates/hub/hub.network.azuredeploy.parameters.json) file.
| **hubResourceGroup** | rg-network-hub-01 | *specify the resource group for the Hub VNet* |
| **hubVnetName** | vnet-hub01 | *specify the Hub VNet name* |
| **localGatewayIpAddress** | 11.22.33.44 | *specify your on-prem VPN gateway IP* i.e. **11.22.33.44*** |
| **localNetworkAddressPrefixes** | ["192.168.0.0/16","10.0.0.0/16"] | *specify your on-prem network addresses* i.e. **["192.168.0.0/16","10.0.0.0/16"]*** |
| **spokeLocation0101** | Australia East | *Location for Spoke Vnet 101 in workload sub #1. If This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [spoke.sub1.network1.azuredeploy.parameters.json](./templates/spoke/spoke.sub1.network1.azuredeploy.parameters.json) file.* |
| **spokeLocation0102** | Australia Southeast | *Location for Spoke Vnet 102 in workload sub #1. If This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [spoke.sub1.network2.azuredeploy.parameters.json](./templates/spoke/spoke.sub1.network2.azuredeploy.parameters.json) file.* |
| **spokeLocation0103** | Southeast Asia | *Location for Spoke Vnet 103 in workload sub #1. If This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [spoke.sub1.network3.azuredeploy.parameters.json](./templates/spoke/spoke.sub1.network3.azuredeploy.parameters.json) file.* |
| **spokeLocation0201** | East US | *Location for Spoke Vnet 201 in workload sub #2. If This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [spoke.sub2.network1.azuredeploy.parameters.json](./templates/spoke/spoke.sub2.network1.azuredeploy.parameters.json) file.* |
| **spokeLocation0202** | West US | *Location for Spoke Vnet 202 in workload sub #2. If This location does not support Azure Bastion Host, change the **'deployBastion'** parameter value to **false** in the [spoke.sub2.network2.azuredeploy.parameters.json](./templates/spoke/spoke.sub2.network2.azuredeploy.parameters.json) file.* |
| **spokeResourceGroup0101** | rg-network-spoke-101 | *Resource group name for spoke VNet 101* |
| **spokeResourceGroup0102** | rg-network-spoke-102 | *Resource group name for spoke VNet 102* |
| **spokeResourceGroup0103** | rg-network-spoke-103 | *Resource group name for spoke VNet 103* |
| **spokeResourceGroup0201** | rg-network-spoke-201 | *Resource group name for spoke VNet 201* |
| **spokeResourceGroup0202** | rg-network-spoke-202 | *Resource group name for spoke VNet 202* |
| **spokeVnetName0101** | vnet-spoke-w0101 | *Spoke VNet 101 name* |
| **spokeVnetName0102** | vnet-spoke-w0102 | *Spoke VNet 102 name* |
| **spokeVnetName0103** | vnet-spoke-w0103 | *Spoke VNet 103 name* |
| **spokeVnetName0201** | vnet-spoke-w0201 | *Spoke VNet 201 name* |
| **spokeVnetName0202** | vnet-spoke-w0202 | *Spoke VNet 202 name* |
| **vpnConnectionType** | IPsec | VPN Connection type |
| **vpnConnectionProtocol** | IKEv2 | VPN connection protocol |
| **IPSecSharedKey** | wjEf7n599CuY3wbf | IPSec Shared key, you will also need to use this key when creating your on-prem VPN connection |

### Pipeline steps

The pipeline contains 2 stages:

* test_and_build
* lab_deploy

>**NOTE:** The lab_deploy stage includes steps to deploy all required resources across multiple subscriptions (management sub and workload subs), because my lab environment consists multiple subscriptions within a single Azure AD tenant.

![004](./images/pipeline_stages.png)

### **test_and_build** stage

This stage consists of the following steps:

* Pester-test all three (3) ARM templates in the solution
    * Hub vnet template
    * Spoke vnet template
    * Vnet peering template
* ARM deployment validation
* Publish build artifacts

### **lab_deploy** stage

This stage consists of the following ARM deployment tasks

* Deploy Hub Vnet in the Management subscription
* Deploy all spoke vnets in multiple Workload subscriptions
* Create VNet peerings between Hub VNet and each Spoke VNet

>**IMPORTANT NOTE:** The deployment for VPN gateways and Bastion hosts can take very long time to finish. In my lab, this pipeline takes more than one (1) hour to execute. When using free Microsoft hosted agents, the maximum pipeline execution time is 60 minutes. Depending on your pipeline, if you are using Microsoft hosted agents, you may need to purchase an additional parallel job in order to increase the maximum execution time to 6 hours.
