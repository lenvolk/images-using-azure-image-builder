param(
  $Name = 'WEB1',
  $Location = 'westus2',
  $ResourceGroup = 'WebServers'
)

New-AzResourceGroup -Name $ResourceGroup -Location $Location

$params = @{
  Name = $Name
  Location = $Location
  ResourceGroup = $ResourceGroup
  VirtualNetworkName = "$ResourceGroup-VNET"
  SubnetName = "$ResourceGroup-Subnet"
  SecurityGroupName = "$Name-NSG"
  PublicIpAddressName = 'myPublicIp'
  OpenPorts = 80
}

New-AzVm @params