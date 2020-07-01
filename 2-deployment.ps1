### User Parameters
$TenantAdminName = "svc-azadmin@arrowdemo.se" ## MFA is not supported for Tenant Admn
$TenantName = "Workshop WVD" ## New WVD Tenant Name
$tenantAdminPassword = read-host "Please enter Tenant Admin password" -AsSecureString
$SubscriptionID = "c5eb9813-8233-47f0-8e40-34ec6be97c61" ## Azure Subscription ID
$AzureADID = "f3f7f190-3138-490a-9c8d-2a030cabe016" ## Azure Active Directory ID, can be found in properties in Azure Active Directory
$resourceGroupName = "workshop-wvd-pool-1" ## Name for new or empty resource group for Host Pool
$resourceGroupLocation = "westeurope" ## Location for resource group for Host Pool
$rdshNamePrefix = "workshopwvd" ## Prefix of the VDI pool machines that will be created
$rdshNumberOfInstances = "1" ## Number of VM's to be created in the Pool
$rdshVMDiskType = "Premium_LRS" ## Disk type
$rdshVmSize = "Standard_D4s_v3" ## VM size
$domainToJoin = "arrowdemo.se" ## Domain to join the VM's
$existingDomainUPN = "svc-azadmin@arrowdemo.se" ## UPN of domain admin
$existingDomainPassword = read-host "Enter domain admin password" -AsSecureString  ## Password of domain admin
$ouPath = "" ## Path to OU where VM will be created. Leave emptye and they will default go in to computer OU
$existingVnetName = "ARROWDEMO_AZ_CIDER" ## Vnet that is connect to Active Directory
$existingSubnetName = "WindowsVdSubnet" ## Name of the subnate in the VNet
$virtualNetworkResourceGroupName  = "DO_NOT_REMOVE" ## Name of resource group where VNet is located"
$existingTenantGroupName = "Default Tenant Group" ## Tenant group name default is Default Tenant Group
$hostPoolName = "workshop-host-pool-1" ## Name of the new host pool 
$defaultDesktopUsers = "simon.ostling@arrowdemo.se,joakim.zetterstrom@arrowdemo.se" ## User who get acces to the new WVD desktop 
 
### Default Parameters
$rdshImageSource = "Gallery"
$vmImageVhdUri = ""
$rdshGalleryImageSKU = "Windows-10-Enterprise-multi-session-with-Office-365-ProPlus"
$rdshCustomImageSourceName = ""
$rdshCustomImageSourceResourceGroup = ""
$enableAcceleratedNetworking = $false
$rdshUseManagedDisks = $true
$storageAccountResourceGroupName = "" 
$newOrExistingVnet = "existing"
$existingTenantName = $TenantName
$enablePersistentDesktop = $false
$tenantAdminUpnOrApplicationId = $TenantAdminName
$isServicePrincipal = $false
$location = $resourceGroupLocation
 
 
### Importing and Installing modules
Write-host -foreground Green "Installing and Importing PowerShell Modules"
 
# Azure Active Directory Module
if (Get-Module -ListAvailable -Name AzureAD)
{
     Import-Module AzureAD | Out-Null
}
else
{
     Install-Module -Name AzureAD -scope AllUsers -Confirm:$false -force
     Import-Module AzureAD | Out-Null
}
 
# Azure RM Module
if (Get-Module -ListAvailable -Name AzureRM)
{
     Import-Module AzureRM | Out-Null
}
else
{
     Install-Module -Name AzureRM -scope AllUsers -Confirm:$false -force
     Import-Module AzureRM | Out-Null
}
 
# RD Infra Module
if (Get-Module -ListAvailable -Name Microsoft.RDInfra.RDPowerShell)
{
     Import-Module Microsoft.RDInfra.RDPowerShell | Out-Null
}
else
{
     Install-Module -Name Microsoft.RDInfra.RDPowerShell -scope AllUsers -Confirm:$false -force
     Import-Module Microsoft.RDInfra.RDPowerShell | Out-Null
}
 
### Connect to Azure AD
write-host -ForegroundColor Yellow "Enter your Azure Active Directory Crendentials"
Connect-AzureAD
 
### Assign admin RDS TenantCreator Role
$username = $TenantAdminName
$app_name = "Windows Virtual Desktop"
$app_role_name = "TenantCreator"
 
# Get the user to assign, and the service principal for the app to assign to
$user = Get-AzureADUser -ObjectId "$username"
$sp = Get-AzureADServicePrincipal -Filter "displayName eq '$app_name'" 
$appRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $app_role_name } 
 
# Assign the user to the app role
New-AzureADUserAppRoleAssignment -ObjectId $user.ObjectId -PrincipalId $user.ObjectId -ResourceId $sp.ObjectId -Id $appRole.Id | out-null
sleep 5
 
### Creating new WVD Tenant
 
# Sign into WVD Environment
Write-Host -ForegroundColor yellow "Enter your Tenant Admin Credentials"
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
 
# Creating new WVD Tenant
New-RdsTenant -Name $TenantName -AadTenantId $AzureADID -AzureSubscriptionId $SubscriptionID
 
### Deploying new host Pool with AzureRM
 
#Sign into Azure
Write-Host -ForegroundColor yellow "Enter your Azure Admin Credentials"
Login-AzureRmAccount
 
# Register RPs
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )
 
    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}
 
$resourceProviders = @("microsoft.resources","microsoft.compute");
if($resourceProviders.length) {
    Write-Host -ForegroundColor Green "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}
 
# Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host -ForegroundColor Green "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else{
    Write-Host -foreground Yellow "Using existing resource group '$resourceGroupName'";
}
# Start the deployment
Write-Host -ForegroundColor Green "Starting Host Pool deployment this can take some time (~15min)..."
$templatefile = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/Create%20and%20provision%20WVD%20host%20pool/mainTemplate.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "New-WVD-HostPool" -TemplateUri $templatefile `
-tenantAdminPassword $tenantAdminPassword `
-rdshNamePrefix $rdshNamePrefix `
-rdshNumberOfInstances $rdshNumberOfInstances `
-rdshVMDiskType $rdshVMDiskType `
-rdshVmSize $rdshVmSize `
-domainToJoin $domainToJoin `
-existingDomainUPN $existingDomainUPN `
-existingDomainPassword $existingDomainPassword `
-ouPath $ouPath `
-existingVnetName $existingVnetName `
-existingSubnetName $existingSubnetName `
-virtualNetworkResourceGroupName $virtualNetworkResourceGroupName `
-existingTenantGroupName $existingTenantGroupName `
-hostPoolName $hostPoolName `
-defaultDesktopUsers $defaultDesktopUsers `
-rdshImageSource $rdshImageSource `
-vmImageVhdUri $vmImageVhdUri `
-rdshGalleryImageSKU $rdshGalleryImageSKU `
-rdshCustomImageSourceName $rdshCustomImageSourceName `
-rdshCustomImageSourceResourceGroup $rdshCustomImageSourceResourceGroup `
-enableAcceleratedNetworking $enableAcceleratedNetworking `
-rdshUseManagedDisks $rdshUseManagedDisks `
-storageAccountResourceGroupName $storageAccountResourceGroupName `
-newOrExistingVnet $newOrExistingVnet `
-existingTenantName $existingTenantName `
-enablePersistentDesktop $enablePersistentDesktop `
-tenantAdminUpnOrApplicationId $tenantAdminUpnOrApplicationId `
-isServicePrincipal $isServicePrincipal `
-location $location
### Checking Host Pool
$hostPool = Get-RdsHostPool -TenantName $tenantName -Name $HostPoolName
if(!$hostpool){
 write-host -ForegroundColor red "Something went wrong check te deployment in the resource group"
}else{
 write-host -ForegroundColor green "WVD Tenant is created and users can now sign in to https://rdweb.wvd.microsoft.com/webclient/index.html"
}