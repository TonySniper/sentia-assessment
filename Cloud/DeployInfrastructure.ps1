param([string]
      [Parameter(Mandatory=$True)]
      $resourceGroup)

Import-Module "$PSScriptRoot\BaseInfrastructure.psm1" -Force

$resourceGroup = $resourceGroup.ToLower()

#Network
$vnetResourceGroup = "rg-network"
$vnetName = "vnet-antonio"
$vnetAddressRange = "10.0.0.0/16"
$defaultSubnetName = "subnet-antonio"
$defaultSubnetAddressRange = "10.0.0.0/24"

Add-ResourceGroup -resourceGroupName $vnetResourceGroup
Add-DefaultVirtualNetwork -vnetResourceGroupName $vnetResourceGroup -vnetName $vnetName -vnetAddressRange $vnetAddressRange -defaultSubnetName $defaultSubnetName -defaultSubnetAddressRange $defaultSubnetAddressRange

#Resource group
Add-ResourceGroup -resourceGroupName $resourceGroup

#Sql Server (PaaS)
# $sqlAdmin = "sqlAdmin"
# $sqlPassword = "Password!@#123"
# $sqlServerName = "$($resourceGroup)server"

& $PSScriptRoot\DeploySql.ps1 -resourceGroup $resourceGroup
# Add-SqlServer -resourceGroupName $resourceGroup

$webAppName = "dcwebapplication"
$webAppType = "app" #windows

$webApiName = "dcapi"

#AppServices 
# Add-WebApp -resourceGroup $resourceGroup -name $webAppName -type $webAppType
# Add-WebApp -resourceGroup $resourceGroup -name $webApiName -type $webAppType