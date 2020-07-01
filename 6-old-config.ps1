Set-executionpolicy -executionpolicy unrestricted
Install-Module -Name Microsoft.RDInfra.RDPowerShell -allowclobber -force
Install-Module -Name Az -AllowClobber -force
Import-Module -Name Microsoft.RDInfra.RDPowerShell
Import-Module -Name Az

Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"

$WVDTenant = "Arrowdemo WVD"
$AzureTenantID = "f3f7f190-3138-490a-9c8d-2a030cabe016"
$SubscriptionID = "c5eb9813-8233-47f0-8e40-34ec6be97c61"
$WVDHostPool = "arw-host-pool-1"
$WVDAppGroup = "arw-app-group-1"
$UPNAccount = "svc-azadmin@arrowdemo.se"

New-RdsTenant -Name $WVDTenant -AadTenantId $AzureTenantID -AzureSubscriptionId $SubscriptionID
#Remove-RdsTenant -Name $WVDTenant

New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -UserPrincipalName $UPNAccount -TenantGroupName "Default Tenant Group" -TenantName $WVDTenant

New-RdsHostPool -TenantName $WVDTenant -name $WVDHostPool
#remove-RdsHostPool -TenantName $WVDTenant -name $WVDHostPool

New-RdsAppGroup -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup
#Get-RdsAppGroup -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup
#remove-RdsAppGroup -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup

## Add users
Add-RdsAppGroupUser -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup -UserPrincipalName "simon.ostling@arrowdemo.se"
#Get-RdsAppGroupUser -TenantName $WVDTenant -HostPoolName $WVDHostPool -AppGroupName $WVDAppGroup

## list apps currently on the host
Get-RdsStartMenuApp $WVDTenant $WVDHostPool $WVDAppGroup | Out-GridView

## Add apps currently on the host
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "RemoteDesktop" -AppAlias remotedesktopconnection

#### Login to rdsh and install apps
Enter-PSSession "arw-wvdrdsh-0.arrowdemo.se"

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#restart shell
choco feature enable -n allowGlobalConfirmation
choco install googlechrome
choco install firefox
choco install microsoft-edge
choco install royalts
choco install notepadplusplus
choco install microsoft-windows-terminal

## list apps currently on the host
Get-RdsStartMenuApp $WVDTenant $WVDHostPool $WVDAppGroup | Out-GridView

## Install new apps
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Google Chrome" -AppAlias googlechrome
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Mozilla Firefox" -AppAlias firefox
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "PowerPoint" -AppAlias powerpoint
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Excel" -AppAlias excel
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Word" -AppAlias word
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Outlook" -AppAlias outlook
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Microsoft Edge" -AppAlias microsoftedge
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Royal TS V4" -AppAlias royaltsv4
New-RdsRemoteApp $WVDTenant $WVDHostPool $WVDAppGroup -Name "Notepad plus plus" -AppAlias notepad

# Set timezone on server
Get-TimeZone -ListAvailable | where ({$_.Id -like "w. europe*"})
Set-TimeZone -Id "W. Europe Standard Time"