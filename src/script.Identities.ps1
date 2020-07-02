[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 

# some Get-ADUser examples
Get-ADUser -Filter 'Name -like "<user>"' | Where-Object { $_.Enabled -eq $true }
Get-ADUser -Filter 'Surname -like "<user>"' | Where-Object { $_.Enabled -eq $true }

. .\Get-AzureDevOpsContext.ps1

$protocol = 'http'
$coreServer = '<source server>/tfs'
$org = '<source collection>'
$project = '<source project>'
$apiVersion = '5.1'
$srcCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion

$protocol = 'https'
# $coreServer = 'vssps.dev.azure.com' # for add user 
$coreServer = 'vsaex.dev.azure.com' # for add user entitlement
$org = '<target org>'
$project = '<target project>'
$apiVersion = '5.1'
$pat = '***'
$destCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion -isOnline -pat $pat

$destCtx
$upn = '<user email>'
$projectId = '<project guid>'
$accessLevel = 'stakeholder'
# . .\Add-AzureDevOpsUser.ps1
# $user = $destCtx | Add-AzureDevOpsUser -upn $upn
# . .\Add-AzureDevOpsUserProjectEntitlement.ps1
$response = $destCtx | Add-AzureDevOpsUserProjectEntitlement -upn $upn -accountLicenseType $accessLevel -projectId $projectId

$destCtx | Add-AzureDevOpsUsersProjectEntitlement -usersCsvPath .\Users.csv -accountLicenseType $accessLevel -projectId $projectId

# $data = Import-Csv -Path .\Users.csv # | Select-Object { $_.ToString().Split("{\}")[1] }

# $data | ForEach-Object {
#     $userName = ($_.ID -split "\\")[1]
#     # $userName
#     $filter = 'Name -like "' + $userName + '"'
#     $u = Get-ADUser -Filter $filter | Where-Object { $_.Enabled -eq $true }
#     $upn = $u.UserPrincipalName
#     $response = $destCtx | Add-AzureDevOpsUserProjectEntitlement -upn $upn -accountLicenseType $accessLevel -projectId $projectId
# }


