#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Bypass

#Make temp dir
New-Item -Path "C:\" -Name "temp" -ItemType "directory"

#Download files
$uri = "https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.1.1/AzFilesHybrid.zip"
Invoke-WebRequest $uri -OutFile "C:\temp\AzFilesHybrid.zip"

#Set Location
Set-Location "C:\temp"

#Unzip
Expand-Archive -Path "AzFilesHybrid.zip"

#Set Location again
Set-Location "C:\temp\AzFilesHybrid"

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

#Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

#Login with an Azure AD credential that has either storage account owner or contributer RBAC assignment
Connect-AzAccount

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId "c5eb9813-8233-47f0-8e40-34ec6be97c6"

# Register the target storage account with your active directory environment under the target OU (for example: "OU=ComputersOU,DC=prod,DC=corp,DC=contoso,DC=com")
# You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account, depends on the AD permission you have and preference. 
Join-AzStorageAccountForAuth `
        -ResourceGroupName "workshop-wvd-pool-1" `
        -Name "something-something-profile" `
        -DomainAccountType "ServiceLogonAccount" `
        -OrganizationalUnitName "OU=something-something,DC=arrowdemo,DC=se"