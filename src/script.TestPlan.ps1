[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 

. .\Get-AzureDevOpsContext.ps1
. .\TestPlanFunctions.ps1

$protocol = 'http'
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

# run once, before any test plan migration
# $cfgs = Copy-TestConfigurations -srcCtx $srcCtx -destCtx $destCtx

$srcPlanId = '<test plan ID>' 
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

# helper for troubleshooting
Invoke-TestPlanSuiteCallback -planId $srcPlan.id -suiteId $srcPlan.rootSuite.id -ctx $srcCtx `
    -callback { param($planId, $suiteId, $suite, $ctx) Show-SuiteTestCases -planId $planId -suiteId $suiteId -suite $suite `
    -srcCfgs $srcCfgs.value -destCfgs $destCfgs.value -ctx $ctx }

# test suites migration & test cases association for one test plan only
Invoke-CopyTestPlanSuiteCallback -srcPlanId $srcPlan.id -srcSuiteId $srcPlan.rootSuite.id  -srcCtx $srcCtx `
    -destPlanId $destPlan.id -destParentSuiteId $destPlan.rootSuite.id -destParentSuiteName $destPlan.rootSuite.name -destCtx $destCtx `
    -isRoot -srcCfgs $srcCfgs.value -destCfgs $destCfgs.value -callback { param($srcSuite, $destPlanId, $destParentSuiteId, $destParentSuiteName, $destCtx, $srcCfgs, $destCfgs) `
        return Add-TestPlanSuiteCallback -srcSuite $srcSuite `
        -destPlanId $destPlanId -destParentSuiteId $destParentSuiteId -destParentSuiteName $destParentSuiteName -destCtx $destCtx -srcCfgs $srcCfgs -destCfgs $destCfgs }
