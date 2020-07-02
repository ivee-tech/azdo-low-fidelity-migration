. .\AzureDevOpsContext.ps1
. .\Add-AzureDevOpsUserProjectEntitlement.ps1

Function Add-AzureDevOpsUsersProjectEntitlement {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$usersCsvPath,
      [ValidateSet("advanced", "earlyAdopter", "express", "none", "professional", "stakeholder")]
      [Parameter(Mandatory = $true)][string]$accountLicenseType, 
      [string]$projectId = $null,
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
    )

$data = Import-Csv -Path $usersCsvPath # Header: ID, Each line: <DOMAIN>\<USER>

$data | ForEach-Object {
    $userName = ($_.ID -split "\\")[1]
    $filter = 'Name -like "' + $userName + '"'
    $u = Get-ADUser -Filter $filter | Where-Object { $_.Enabled -eq $true }
    $upn = $u.UserPrincipalName
    $response = $destCtx | Add-AzureDevOpsUserProjectEntitlement -upn $upn -accountLicenseType $accessLevel -projectId $projectId
}
    
}
