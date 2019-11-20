param([string]
      [Parameter(Mandatory=$True)]
      $resourceGroup)
     
Import-Module "$PSScriptRoot\BaseInfrastructure.psm1" -Force

$resourceGroupName = "$resourceGroup".ToLower()
Write-Host "Adding Database...."
$sqlDbName = "TestDatabase"
$sqlAdminUserName  = "sqlAdmin"
$sqlPassword = ConvertTo-SecureString "Password123!@#" -AsPlainText -Force 

Add-SqlServer -resourceGroupName $resourceGroupName `
              -templatePath "$PSScriptRoot\Database\SqlServer\template.json" `
              -adminUserName $sqlAdminUserName `
              -password $sqlPassword `
              -location "centralus" `
              -secondaryLocation "eastus" `
              -sqlDbName $sqlDbName