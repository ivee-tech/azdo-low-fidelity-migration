Function Get-WorkItem {
    [CmdletBinding()]
    param(
      [ValidateNotNullOrEmpty()]
      [Parameter(Mandatory = $true)][int]$workItemId,
      [Parameter()][string]$fields,
      # [ValidateSet("None", "Relations", "Fields", "Links", "All")] - combinations are possible, use comma-separated values
      [Parameter()][string]$expand,
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)][hashtable]$context
    )
# GET https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/{id}?fields={fields}&asOf={asOf}&$expand={$expand}&api-version=5.1  
    $v = $context.apiVersion
    $qs = ''
    if($PSBoundParameters.ContainsKey("fields")) {
        $c = if('' -eq $qs) {''} else {'&'} #(IIf '' -eq $qs '' '&')
        $qs = $qs + $c + 'fields=' + $fields
    }
    if($PSBoundParameters.ContainsKey("expand")) {
        $c = if('' -eq $qs) {''} else {'&'} #(IIf '' -eq $qs '' '&')
        $qs = $qs + $c + '$expand=' + $expand
    }
    $c = if('' -eq $qs) {''} else {'&'} #(IIf '' -eq $qs '' '&')
    $workItemUrl = $context.projectBaseUrl + '/wit/workitems/' + $workItemId + '?' + $qs + $c + 'api-version=' + $v
    Write-Host "workItemUrl: $workItemUrl"
  
    if ($context.isOnline) {
      $workItem = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $workItemUrl
    }
    else {
      $workItem = Invoke-RestMethod -Uri $workItemUrl -UseDefaultCredentials
    }
  
    return $workItem # | ConvertTo-Json
  }
  
