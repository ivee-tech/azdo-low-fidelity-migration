Function Add-AzureDevOpsUser {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$upn,
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)][hashtable]$context
    )

# coreServer should be vssps.dev.azure.com
$contentType = 'application/json'
$v = $context.apiVersion + '-preview.1'
$usersUrl = $context.orgBaseUrl + '/graph/users?api-version=' + $v
$usersUrl

$data = @{
    principalName = $upn
} | ConvertTo-Json

if($context.isOnline) {
    $user = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $usersUrl -Body $data -Method POST -ContentType $contentType
    if($user -eq $null) {
        Write-Host 'Unable to create user (no error returned).'
    }
    else {
        Write-Host "User created successfully for UPN $upn."
        $user
    }
    return $user
}
else {
    Write-Host 'This cmdlet works only with Azure DevOps Services.'
    return $null
}

}
