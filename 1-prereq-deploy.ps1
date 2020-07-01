Set-executionpolicy -executionpolicy unrestricted
Install-Module -Name Microsoft.RDInfra.RDPowerShell -allowclobber -force
Install-Module -Name Az -AllowClobber -force
Import-Module -Name Microsoft.RDInfra.RDPowerShell
Import-Module -Name Az

Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$WVDTenant = "Workshop WVD"
$AzureTenantID = "f3f7f190-3138-490a-9c8d-2a030cabe016"
$SubscriptionID = "c5eb9813-8233-47f0-8e40-34ec6be97c61"
$WVDHostPool = "workshop-host-pool-1"
$WVDAppGroup = "workshop-app-group-1"
$UPNAccount = "svc-azadmin@arrowdemo.se"
$DefaultUsers = "simon.ostling@arrowdemo.se,joakim.zetterstrom@arrowdemo.se"

#Get-rdssessionhost -TenantName $WVDTenant -HostPoolName $WVDHostPool

New-RdsTenant -Name $WVDTenant -AadTenantId $AzureTenantID -AzureSubscriptionId $SubscriptionID

New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -UserPrincipalName $UPNAccount -TenantGroupName "Default Tenant Group" -TenantName $WVDTenant

New-RdsHostPool -TenantName $WVDTenant -name $WVDHostPool

New-RdsAppGroup -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup

Add-RdsAppGroupUser -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup -UserPrincipalName $DefaultUsers