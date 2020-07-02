Function Get-AzureDevOpsContext {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][string]$protocol,
      [Parameter(Mandatory = $true)][string]$coreServer,
      [Parameter(Mandatory = $true)][string]$org,
      [Parameter(Mandatory = $true)][string]$project,
      [Parameter(Mandatory = $true)][string]$apiVersion,
      [switch]$isOnline,
      [Parameter()][string]$pat
    )
    
  
    $orgBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/_apis'
    $projectBaseUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project + '/_apis'
    $orgUrl = $protocol + '://' + $coreServer + '/' + $org
    $projectUrl = $protocol + '://' + $coreServer + '/' + $org + '/' + $project
    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($org):$pat"))
  
    [hashtable]$r = @{ } 
    
    $r.orgBaseUrl = $orgBaseUrl
    $r.projectBaseUrl = $projectBaseUrl
    $r.orgUrl = $orgUrl
    $r.projectUrl = $projectUrl
    $r.base64AuthInfo = $base64AuthInfo
    $r.protocol = $protocol
    $r.coreServer = $coreServer
    $r.org = $org
    $r.project = $project
    $r.apiVersion = $apiVersion
    $r.isOnline = $isOnline
  
    return $r
  }
  