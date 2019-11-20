function Add-DefaultVirtualNetwork {
    param(
    [Parameter(Mandatory = $True)]
    [string]
    $vnetResourceGroupName,
    [Parameter(Mandatory = $True)]
    [string]
    $vnetName,
    [Parameter(Mandatory = $True)]
    [string]
    $vnetAddressRange,
    [Parameter(Mandatory = $True)]
    [string]
    $defaultSubnetName,
    [Parameter(Mandatory = $True)]
    [string]
    $defaultSubnetAddressRange
    )
    
    Write-Host "Checking if virtual network $resourceGroupName exists..."
    
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $vnetResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
    
    if($vnet) {
        Write-Host "Virtual network $vnetName already exists, skipping virtual network creation..."
        return
    }
    
    # New-AzResourceGroupDeployment -Name "network" -TemplateFile ".\Network\template.json" -ResourceGroupName $vnetResourceGroupName -vnetName $vnetName -subnet1Name $defaultSubnetName -vnetAddressPrefix $vnetAddressPrefix -subnet1Prefix $subnetAddressPrefix
    New-AzResourceGroupDeployment -Name "network" `
    -TemplateFile ".\Network\template.json" `
    -ResourceGroupName $vnetResourceGroupName `
    -vnetName $vnetName `
    -vnetAddressPrefix $vnetAddressRange `
    -defaultSubnetName $defaultSubnetName `
    -defaultSubnetAddressRange $defaultSubnetAddressRange `
}

function Add-ResourceGroup {
    param(
    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,
    [string]
    $location = "centralus"
    )
    
    Write-Host "Checking if resource group $resourceGroupName exists..."
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    
    if ($resourceGroup) {
        Write-Host "Resource group $resourceGroupName exists, skipping resource group creation..."
        return
    }
    
    Write-Host "Creating resource group '$resourceGroupName' in location '$location'";
    
    New-AzDeployment -Name "resourceGroup" -TemplateFile ".\ResourceGroup\template.json" -Location $location -rgLocation $location -rgName $resourceGroupName
}

function Add-SqlServer {
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $resourceGroupName,
        [Parameter(Mandatory = $True)]
        [string]
        $templatePath,
        [Parameter(Mandatory = $True)]
        [string]
        $adminUserName,
        [Parameter(Mandatory = $True)]
        [securestring]
        $password,
        [string]
        $location = "northeurope",
        [string]
        $secondaryLocation = "westeurope",
        [string]
        $sqlDbName)

    $serverName = "$($resourceGroupName)sqlserver"

    $sqlServer = Get-AzSqlServer -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -ErrorAction SilentlyContinue

    if ($sqlServer) {
        Write-Host "$serverName already exists..."
        return
    }

    Write-Host "Creating $serverName..."
        
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
        -TemplateFile $templatePath `
        -sqlServerPrimaryName $serverName `
        -sqlServerSecondaryName "$($serverName)secondary" `
        -sqlServerSecondaryRegion $secondaryLocation `
        -sqlFailoverGroupName "$($serverName)failover" `
        -sqlServerPrimaryAdminUsername $adminUserName `
        -sqlServerPrimaryAdminPassword $password `
        -sqlServerSecondaryAdminUsername $adminUserName `
        -sqlServerSecondaryAdminPassword $password `
        -sqlDatabaseName $sqlDbName 
        
    # Add-ConnectionStringKeyVault -ResourceGroupName $resourcegroupname `
    #     -keyvaultName "DBConnectionString" `
    #     -databaseName $sqlDbName `
    #     -adminUserName $adminUserName `
    #     -password $password
    
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
        -ServerName $serverName `
        -AllowAllAzureIPs 
}

function Add-SqlServerDatabase {
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $resourceGroupName,
        [Parameter(Mandatory = $True)]
        [string]
        $templatePath,
        [Parameter(Mandatory = $True)]
        [string]
        $name,
        [Parameter(Mandatory = $True)]
        [string]
        $adminUserName,
        [Parameter(Mandatory = $True)]
        [securestring]
        $password,
        [Parameter(Mandatory = $True)]
        [string]
        $keyvaultKey)

    $serviceName = Get-ServiceName -resourceGroupName $resourceGroupName `
        -templatePath $templatePath
        
    $sqlDatabase = Get-AzSqlDatabase -ResourceGroupName $resourcegroupname `
        -ServerName $serviceName `
        -DatabaseName $name `
        -ErrorAction SilentlyContinue
    if ($sqlDatabase) {
        Write-Host "$name DataBase already exists..."
        return
    }

    Write-Host "Creating $name..."

    New-AzSqlDatabase  -ResourceGroupName $resourcegroupname `
        -ServerName $serviceName `
        -DatabaseName $name

    # Add-ConnectionStringKeyVault -ResourceGroupName $resourcegroupname `
    #     -keyvaultName $keyvaultKey `
    #     -databaseName $name `
    #     -adminUserName $adminUserName `
    #     -password $password
}

function Add-ConnectionStringKeyVault {
    param(
    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,
    [Parameter(Mandatory = $True)]
    [string]
    $keyvaultName,
    [Parameter(Mandatory = $True)]
    [string]
    $databaseName,
    [Parameter(Mandatory = $True)]
    [string]
    $adminUserName,
    [Parameter(Mandatory = $True)]
    [securestring]
    $password)
    
    $binaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $unsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($binaryString)
    $connectionString = "Server=tcp:$serviceName.database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$adminUserName;Password=$unsecurePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    $secureConnectionString = ConvertTo-SecureString -String $connectionString -AsPlainText -Force
    
    Set-AzureKeyVaultSecret -VaultName "$($resourceGroupName)keyvault" `
    -Name $keyvaultName `
    -SecretValue $secureConnectionString `
    -Verbose
}

function Add-WebApp {
    param(
    [Parameter(Mandatory = $True)]
    [string]
    $name,
    [Parameter(Mandatory = $True)]
    [string]
    $type,
    [string]
    $sku = "S1",
    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroup)
    
    
    $webapp = Get-AzWebApp -ResourceGroupName $resourceGroup -Name "$($name)webapp" -ErrorAction SilentlyContinue
    $appPlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroup -Name "$($name)appserviceplan" -ErrorAction SilentlyContinue

    if($webapp){
        Write-Host "Web app $name already exists..."
    }

    if($appPlan){
        Write-Host "App service plan $name already exists..."
    }

    if($appPlan -or $webapp){
        return;
    }

    Write-Host "Deploying new Application Services with name $($resourceGroup)$($name)webapp"

    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup `
        -TemplateFile ".\WebApp\template.json" `
        -webAppName $name `
        -webAppType $type `
        -sku $sku
}