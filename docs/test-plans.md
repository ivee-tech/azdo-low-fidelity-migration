# Test Plans and Test Suites

Test Plans and Test Suites are a special type of Work Items. They could be migrated as part of Work Item migration, however only the common fields data is migrated.
These WITs have specific related information such as test suite type (requirements-based, query-based, static), or the hierarchy info which require a different approach.
In order to migrate a test plan, follow these steps:
 - extract the source test plan
 - map the area path and iteration to the target (that is required if the source project name is different than the target project name)
 - create the target test plan
 - recursively, starting with the root suite, go through all suites and perform the following tasks:
 - get the source test suite
 - create the target test suite:
 - if the test suite is query-based, make sure the destination query is mapped to the source
 - if the test suite is requirements-based, map the requirement ID from source to the requirement ID from target
 - if the test suite is static, associate the target Test Cases based on source Test Cases, making sure the Test Points (configurations) are matching
The first step is to initialise the source and target contexts for authentication (the first line is required for proxy auth):
``` PowerShell
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
 
. .\Get-AzureDevOpsContext.ps1
. .\TestPlanFunctions.ps1
 
$protocol = 'https'
$coreServer = '<source server>/tfs'
$org = '<source collection>'
$project = '<source project>'
$apiVersion = '5.1'
$srcCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion
 
$protocol = 'https'
$coreServer = 'dev.azure.com'
$org = '<target org>'
$project = '<target project>'
$apiVersion = '5.1'
$pat = '***'
$destCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion -isOnline -pat $pat
```

Execute the following step only once, before any test plan migration
``` PowerShell
# run once, before any test plan migration
$cfgs = Copy-TestConfigurations -srcCtx $srcCtx -destCtx $destCtx
```

Migrate the test plan: get the source test plan, ensure the are path and iteration are matching the target project, create the target test plan and create the target test suites recursively
``` PowerShell
$srcPlanId = <Source Test Plan ID>
$srcPlan = Get-TestPlan -planId $srcPlanId -context $srcCtx
 
$areaPath = $destCtx.project + $srcPlan.areaPath.Substring($srcCtx.project.Length)
$iteration = $destCtx.project + $srcPlan.iteration.Substring($srcCtx.project.Length)
$areaPath
$iteration
$destPlanAdd = $destCtx | Add-TestPlan -name $srcPlan.name -areaPath $areaPath -iteration $iteration -startDate $srcPlan.startDate -endDate $srcPlan.endDate -state $srcPlan.state
$destPlanId = $destPlanAdd.id
$destPlan = $destCtx | Get-TestPlan -planId $destPlanId
 
$srcCfgs = $srcCtx | Get-TestConfigurations
$destCfgs = $destCtx | Get-TestConfigurations
 
# test suites migration & test cases association for one test plan only
Invoke-CopyTestPlanSuiteCallback -srcPlanId $srcPlan.id -srcSuiteId $srcPlan.rootSuite.id  -srcCtx $srcCtx `
    -destPlanId $destPlan.id -destParentSuiteId $destPlan.rootSuite.id -destParentSuiteName $destPlan.rootSuite.name -destCtx $destCtx `
    -isRoot -srcCfgs $srcCfgs.value -destCfgs $destCfgs.value -callback { param($srcSuite, $destPlanId, $destParentSuiteId, $destParentSuiteName, $destCtx, $srcCfgs, $destCfgs) `
        return Add-TestPlanSuiteCallback -srcSuite $srcSuite `
        -destPlanId $destPlanId -destParentSuiteId $destParentSuiteId -destParentSuiteName $destParentSuiteName -destCtx $destCtx -srcCfgs $srcCfgs -destCfgs $destCfgs }
```
