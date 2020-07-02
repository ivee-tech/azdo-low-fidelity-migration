. .\AzureDevOpsContext.ps1
. .\Get-AzureDevOpsContext.ps1

Function Get-TestPlan {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.1'
  $testPlansUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '?api-version=' + $v
  $testPlansUrl

  if ($context.isOnline) {
    $testPlan = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testPlansUrl
  }
  else {
    $testPlan = Invoke-RestMethod -Uri $testPlansUrl -UseDefaultCredentials
  }

  return $testPlan # | ConvertTo-Json
}

Function Add-TestPlan {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][string]$name,
    [Parameter(Mandatory = $true)][string]$areaPath,
    [Parameter(Mandatory = $true)][string]$iteration,
    [Parameter(Mandatory = $true)][string]$startDate,
    [Parameter(Mandatory = $true)][string]$endDate,
    [Parameter(Mandatory = $true)][string]$state,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $contentType = 'application/json'

  $v = $context.apiVersion + '-preview.1'
  $testPlansUrl = $context.projectBaseUrl + '/testplan/plans?api-version=' + $v
  $testPlansUrl


  $data = @{
    name        = $name;
    areaPath    = $areaPath;
    iteration   = $iteration;
    description = $name;
    startDate   = $startDate;
    endDate     = $endDate;
    owner       = $null;
    state       = $state; # "Active"
  } | ConvertTo-Json -Depth 100

  $data

  if ($context.isOnline) {
    $testPlan = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testPlansUrl -Method POST -Body $data -ContentType $contentType
  }
  else {
    $testPlan = Invoke-RestMethod -Uri $testPlansUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
  }

  return $testPlan

}


Function Get-TestConfigurations {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.1'
  $testConfigurationsUrl = $context.projectBaseUrl + '/testplan/configurations?api-version=' + $v
  $testConfigurationsUrl

  if ($context.isOnline) {
    $configurations = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testConfigurationsUrl
  }
  else {
    $configurations = Invoke-RestMethod -Uri $testConfigurationsUrl -UseDefaultCredentials
  }

  return $configurations # | ConvertTo-Json
}

Function Add-TestConfiguration {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][string]$name,
    [Parameter()][string]$description,
    [ValidateSet("active", "inactive")]
    [Parameter(Mandatory = $true)][string]$state,
    [Parameter()][switch]$isDefault,
    [Parameter()][array]$values,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $contentType = 'application/json'

  $v = $context.apiVersion + '-preview.1'
  $testConfigurationsUrl = $context.projectBaseUrl + '/testplan/configurations?api-version=' + $v
  $testConfigurationsUrl

  $data = @{
    name = $name;
    description = $description;
    state = $state;
    values = @();
  }

  if($isDefault) {
    $data.isDefault = $true
  }
  if($null -ne $values) {
    $data.values = $values
  }

  $body = $data | ConvertTo-Json -Depth 100
  Write-Host $body

  if ($context.isOnline) {
    $configuration = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testConfigurationsUrl -Body $body -Method POST -ContentType $contentType
  }
  else {
    $configuration = Invoke-RestMethod -Uri $testConfigurationsUrl -UseDefaultCredentials -Body $body -Method POST -ContentType $contentType
  }

  return $configuration # | ConvertTo-Json
}

Function Copy-TestConfigurations {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$srcCtx,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$destCtx
    )

    $srcCfgs = $srcCtx | Get-TestConfigurations
    $destCfgs = $destCtx | Get-TestConfigurations
    $smartSingleQuotes = '[\u2019\u2018]'
    $smartDoubleQuotes = '[\u201C\u201D]'

    $srcCfgs.value | ForEach-Object {
      $srcName = $_.name
      $destCfg = $destCfgs.value | Where-Object { $_.name -eq $srcName }
      if($null -eq $destCfg) {
        $values = $_.values
        $description = $_.description -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'
        if($_.isDefault) {
            $destCfg = $destCtx | Add-TestConfiguration -name $_.name -description $description -state $_.state -values $values -isDefault
        }
        else {
            $destCfg = $destCtx | Add-TestConfiguration -name $_.name -description $description -state $_.state -values $values
        }
      }
    }
    $destCfgs = $destCtx | Get-TestConfigurations
    return $destCfgs
}

Function Get-TestPlanSuites {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )
  $v = $context.apiVersion + '-preview.1'
  $testPlanSuitesUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites?expand=Children,DefaultTesters&api-version=' + $v
  $testPlanSuitesUrl

  if ($context.isOnline) {
    $suites = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testPlanSuitesUrl
  }
  else {
    $suites = Invoke-RestMethod -Uri $testPlanSuitesUrl -UseDefaultCredentials
  }

  return $suites 
}

Function Get-TestPlanSuite {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$suiteId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.1'
  $testPlanSuiteUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '?expand=Children,DefaultTesters&api-version=' + $v
  $testPlanSuiteUrl

  if ($context.isOnline) {
    $suite = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testPlanSuiteUrl
  }
  else {
    $suite = Invoke-RestMethod -Uri $testPlanSuiteUrl -UseDefaultCredentials
  }

  return $suite
}

Function Add-TestPlanSuite {
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$parentSuiteId,
    [Parameter(Mandatory = $true)][string]$parentSuiteName,
    [Parameter(Mandatory = $true)][string]$suiteName,
    [Parameter(Mandatory = $true)][string]
    [ValidateSet("staticTestSuite", "requirementTestSuite", "dynamicTestSuite")]
    $suiteType,
    [Parameter()][string]$requirementId,
    [Parameter()][string]$queryString,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $contentType = 'application/json'

  $v = $context.apiVersion + '-preview.1'
  $destTestSuiteUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $parentSuiteId + '?api-version=' + $v
  $destTestSuiteUrl

  $smartSingleQuotes = '[\u2019\u2018]'
  $smartDoubleQuotes = '[\u201C\u201D]'

  $name = $suiteName -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'
  $parentName = $parentSuiteName -replace $smartSingleQuotes, "'" -replace $smartDoubleQuotes, '"'

  $destSuiteData = @{
    suiteType   = $suiteType;
    name        = $name;
    parentSuite = @{
      id   = $parentSuiteId;
      name = $parentName
    }
  }

  if ($PSBoundParameters.ContainsKey('requirementId') -and $null -ne $requirementId) {
    $destSuiteData.requirementId = $requirementId
  }

  if ($PSBoundParameters.ContainsKey('queryString')) {
    $destSuiteData.queryString = $queryString
  }

  $data = $destSuiteData | ConvertTo-Json -Depth 100
  if ($context.isOnline) {
    $destTestSuite = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $destTestSuiteUrl -Method POST -Body $data -ContentType $contentType
  }
  else {
    $destTestSuite = Invoke-RestMethod -Uri $destTestSuiteUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
  }

  return $destTestSuite

}


Function Invoke-QueryWorkItemFromDestBySrc {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][string]$srcId,
    [Parameter(Mandatory = $true)][AzureDevOpsContext]$srcCtx,
    [Parameter(Mandatory = $true)][AzureDevOpsContext]$destCtx
  )

  $contentType = 'application/json'
  $srcWIUrl = $srcCtx.projectUrl + '_workitems/edit/' + $srcId
  
  $data = @{
    query = "SELECT
      [System.Id],
      [System.WorkItemType],
      [System.Title],
      [System.AssignedTo],
      [System.State],
      [System.Tags]
  FROM workitems
  WHERE
      [System.TeamProject] = @project
      AND [Custom.ReflectedWorkItemID] = '$srcId'
  "
  } | ConvertTo-Json
  
  $v = $destCtx.apiVersion
  $wiqlDestUrl = $destCtx.projectBaseUrl + '/wit/wiql?api-version=' + $v
  $wiqlDestUrl

  $data

  if ($destCtx.isOnline) {
    $results = Invoke-RestMethod -Headers @{Authorization = "Basic $($destCtx.base64AuthInfo)" } -Uri $wiqlDestUrl -Method POST -Body $data -ContentType $contentType
  }
  else {
    $results = Invoke-RestMethod -Uri $wiqlDestUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
  }

  return $results

}

Function Get-SuiteTestCases {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$suiteId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.2'
  $suiteTestCasesUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '/testcase?api-version=' + $v
  $suiteTestCasesUrl
  
  if ($context.isOnline) {
    $suiteTestCases = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $suiteTestCasesUrl
  }
  else {
    $suiteTestCases = Invoke-RestMethod -Uri $suiteTestCasesUrl -UseDefaultCredentials
  }

  return $suiteTestCases

}

Function Get-SuiteTestCase {
  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$suiteId,
    [Parameter(Mandatory = $true)][int]$testCaseId, # this is the actual Work Item ID
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.2'
  $suiteTestCaseUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '/testcase/' + $testCaseId + '?api-version=' + $v
  $suiteTestCaseUrl
  
  if ($context.isOnline) {
    $suiteTestCase = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $suiteTestCaseUrl
  }
  else {
    $suiteTestCase = Invoke-RestMethod -Uri $suiteTestCaseUrl -UseDefaultCredentials
  }

  return $suiteTestCase

}

Function Add-SuiteTestCase {
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$suiteId,
    [Parameter(Mandatory = $true)][int]$workItemId,
    [Parameter(Mandatory = $true)][int]$configurationId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $contentType = 'application/json'

  $v = '6.0-preview.2' # $context.apiVersion + '-preview.2'
  $suiteTestCaseUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '/testcase?api-version=' + $v
  $suiteTestCaseUrl

  $arr = @()
  $arr += @{ workItem = @{ id = $workItemId }; pointAssignments = @( @{ configurationId = $configurationId } )}
  $data = $arr | ConvertTo-Json -Depth 100
  $data
$data = '[
    {
      "workItem": { "id": ' + $workItemId + '},
      "pointAssignments": [
        { "configurationId": ' + $configurationId + ' }
      ]
    }
  ]'
  $data


  if ($context.isOnline) {
    $suiteTestCase = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $suiteTestCaseUrl -Method POST -Body $data -ContentType $contentType
  }
  else {
    $suiteTestCase = Invoke-RestMethod -Uri $suiteTestCaseUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
  }

  return $suiteTestCase
}

Function Add-SuiteTestCaseMultiPoint {
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$planId,
    [Parameter(Mandatory = $true)][int]$suiteId,
    [Parameter(Mandatory = $true)][int]$workItemId,
    [Parameter(Mandatory = $true)][int[]]$configurationIds,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $contentType = 'application/json'

  $v = '6.0-preview.2' # $context.apiVersion + '-preview.2'
  $suiteTestCaseUrl = $context.projectBaseUrl + '/testplan/plans/' + $planId + '/suites/' + $suiteId + '/testcase?api-version=' + $v
  $suiteTestCaseUrl

  $arr = @()
  $arr += @{ workItem = @{ id = $workItemId }; pointAssignments = @(); }
  $configurationIds | ForEach-Object {
    $arr[0].pointAssignments += @{ configurationId = $_ }
  }
  $data = ConvertTo-Json -InputObject $arr -Depth 100
  $data

  if ($context.isOnline) {
    $suiteTestCase = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $suiteTestCaseUrl -Method POST -Body $data -ContentType $contentType
  }
  else {
    $suiteTestCase = Invoke-RestMethod -Uri $suiteTestCaseUrl -UseDefaultCredentials -Method POST -Body $data -ContentType $contentType
  }

  return $suiteTestCase
}

Function Remove-TestCase {
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)][int]$testCaseId,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AzureDevOpsContext]$context
  )

  $v = $context.apiVersion + '-preview.1'
  $testCaseUrl = $context.projectBaseUrl + '/test/testcases/' + $testCaseId + '?api-version=' + $v
  $testCaseUrl

  if ($context.isOnline) {
    $response = Invoke-RestMethod -Headers @{Authorization = "Basic $($context.base64AuthInfo)" } -Uri $testCaseUrl -Method DELETE
  }
  else {
    $response = Invoke-RestMethod -Uri $testCaseUrl -UseDefaultCredentials -Method DELETE
  }

  return $response
}

Function Add-TestPlanSuiteCallback ($srcSuite, $destPlanId, $destParentSuiteId, $destParentSuiteName, $destCtx, $srcCfgs, $destCfgs) {
  try {
  if($srcSuite.suiteType -eq 'requirementTestSuite') {
      $srcRequirementId = $srcSuite.requirementId
      $destResults = Invoke-QueryWorkItemFromDestBySrc -srcId $srcRequirementId -srcCtx $srcCtx -destCtx $destCtx
      $destRequirementId = $destResults.workItems.id
      $destSuite = $destCtx | Add-TestPlanSuite -planId $destPlanId -parentSuiteId $destParentSuiteId -parentSuiteName $destParentSuiteName `
          -suiteName $srcSuite.name -suiteType $srcSuite.suiteType -requirementId $destRequirementId -queryString $srcSuite.queryString
      return $destSuite
  }
  if($srcSuite.suiteType -eq 'dynamicTestSuite') { 
      # may not work, query could be linked to the source
      $queryString = $srcSuite.queryString # .Replace("[System.AreaPath] under '<source project>\", "[System.AreaPath] under '<target project>\")
      Write-Host $queryString
      $destSuite = $destCtx | Add-TestPlanSuite -planId $destPlanId -parentSuiteId $destParentSuiteId -parentSuiteName $destParentSuiteName `
          -suiteName $srcSuite.name -suiteType $srcSuite.suiteType -queryString $queryString
      return $destSuite
  }
  if($srcSuite.suiteType -eq 'staticTestSuite') { 
      $destSuite = $destCtx | Add-TestPlanSuite -planId $destPlanId -parentSuiteId $destParentSuiteId -parentSuiteName $destParentSuiteName `
          -suiteName $srcSuite.name -suiteType $srcSuite.suiteType
      $srcTestCases = $srcCtx | Get-SuiteTestCases -planId $srcPlanId -suiteId $srcSuite.id
      $defaultDestCfg = $destCfgs | Where-Object { $_.name -eq 'Windows 10' }
      $srcTestCases.value | ForEach-Object { 
          $srcPointAssignments = $_.pointAssignments
          # Write-Host $srcPointAssignments
          $srcWIId = $_.workItem.id
          if ($null -ne $srcWIId) {
              $results = Invoke-QueryWorkItemFromDestBySrc -srcId $srcWIId -srcCtx $srcCtx -destCtx $destCtx
              $destWIId = $results.workItems.id
              if($null -ne $destWIId) {
                  $destCfgIds = @()
                  $srcPointAssignments | ForEach-Object {
                      $srcCfgId = $_.configurationId
                      # Write-Host "srcCfgId: $srcCfgId"
                      $srcCfg = $srcCfgs | Where-Object { $_.id -eq $srcCfgId }
                      # Write-Host "srcWIId: $srcWIId"
                      # Write-Host $srcCfg
                      $destCfg = $destCfgs | Where-Object { $_.name -eq $srcCfg.name }
                      # Write-Host "destWIId: $destWIId"
                      # Write-Host $destCfg
                      if($null -ne $destCfg) { $destCfgId = $destCfg.id  } else { $destCfgId = $defaultDestCfg.id }
                      $destCfgIds += $destCfgId
                  }
                  $destTestCase = $destCtx | Add-SuiteTestCaseMultiPoint -planId $destPlanId -suiteId $destSuite.id -workItemId $destWIId -configurationIds $destCfgIds
              } 
          }
      }
      return $destSuite
  }
  }
  catch {
  Write-Host "Exception occurred while running Add-TestPlanSuiteCallback with the following parameters:
srcSuite: $srcSuite, destPlanId: $destPlanId, destParentSuiteId: $destParentSuiteId, destParentSuiteName: $destParentSuiteName
"
      Write-Host $_
      throw # don't continue
  }
}

Function Show-SuiteTestCases
{
  param($planId, $suiteId, $suite, $srcCfgs, $destCfgs, [AzureDevOpsContext]$ctx)

  if($suite.suiteType -eq 'dynamicTestSuite') {
      Write-Host $suite
  }
  
  # $testCases = Get-SuiteTestCases -planId $planId -suiteId $suiteId -context $ctx
  # $testCases.value | ConvertTo-Json
  <#
  $testCases.value | Foreach-Object{ 
      Write-Host "$($_.workItem.name)" 
      $srcPointAssignments = $_.pointAssignments
      $srcPointAssignments | ForEach-Object {
          $srcCfgId = $_.configurationId
          $srcCfg = $srcCfgs | Where-Object { $_.id -eq $srcCfgId }
          Write-Host "srcCfg: $srcCfg"
          $destCfg = $destCfgs | Where-Object { $_.name -eq $srcCfg.name }
          Write-Host "destCfg: $destCfg"
      }
  } # ConvertTo-Json
  #> 
}

Function Invoke-TestPlanSuiteCallback([int]$planId, [int]$suiteId, [AzureDevOpsContext]$ctx, [scriptblock]$callback)
{
  $suite = Get-TestPlanSuite -planId $planId -suiteId $suiteId -context $ctx
  if($null -ne $callback) {
      $callback.Invoke($planId, $suiteId, $suite, $ctx)
  }
  if($suite.hasChildren) {
      $suite.children | ForEach-Object {
          $childSuiteId = $_.id
          Invoke-TestPlanSuiteCallback -planId $planId -suiteId $childSuiteId -ctx $ctx -callback $callback
      }
  }
}

Function Invoke-CopyTestPlanSuiteCallback([int]$srcPlanId, [int]$srcSuiteId, [AzureDevOpsContext]$srcCtx, `
  [int]$destPlanId, [int]$destParentSuiteId, [string]$destParentSuiteName, [AzureDevOpsContext]$destCtx, `
  [switch]$isRoot, $srcCfgs, $destCfgs, [scriptblock]$callback)
{

  $srcSuite = $srcCtx | Get-TestPlanSuite -planId $srcPlanId -suiteId $srcSuiteId
  if(!$isRoot) {
      $destSuite = $callback.Invoke($srcSuite, $destPlanId, $destParentSuiteId, $destParentSuiteName, $destCtx, $srcCfgs, $destCfgs)
  }
  else {
      $destSuite = $destCtx | Get-TestPlanSuite -planId $destPlanId -suiteId $destParentSuiteId
  }
  if($srcSuite.hasChildren) {
      $srcSuite.children | ForEach-Object {
          Invoke-CopyTestPlanSuiteCallback -srcPlanId $srcPlanId -srcSuiteId $_.id -srcCtx $srcCtx `
              -destPlanId $destPlanId -destParentSuiteId $destSuite.id -destParentSuiteName $destSuite.name -destCtx $destCtx `
              -srcCfgs $srcCfgs -destCfgs $destCfgs -callback $callback
      }
  }
}
