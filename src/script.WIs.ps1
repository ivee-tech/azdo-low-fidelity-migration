[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 

. .\Get-AzureDevOpsContext.ps1
$protocol = 'http'
$coreServer = '<source server>/tfs'
$org = '<source collection>'
$project = '<source project>'
$apiVersion = '5.1'
$srcCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion

$protocol = 'http'
$coreServer = 'dev.azure.com'
$org = '<target org>'
$project = '<target project>'
$apiVersion = '5.1'
$pat = '***'
$destCtx = Get-AzureDevOpsContext -protocol $protocol -coreServer $coreServer -org $org -project $project -apiVersion $apiVersion -isOnline -pat $pat

$user = '<domain>\<user>'
$pass = '***'
$cred = New-Object System.Net.NetworkCredential($user, $pass)

# generate the CSV mapping file from the target project, using a query to extract the migrated batch
# make sure you include the following fields: ReflectedWorkItemID as OldId and ID as NewId
. .\Copy-Comments.ps1
$csvFilePath = './file-map.csv' 
Copy-Comments -srcCtx $srcCtx -destCtx $destCtx -csvFilePath $csvFilePath
