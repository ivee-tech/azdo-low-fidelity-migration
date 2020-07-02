# Quick steps guide

This is a quick steps guide for low-fidelity migration. You can find more information on the full guide [here](./main.md).
 - For dry-runs, it's better to use a sandpit Azure DevOps Server instance (a copy of your production system) as source, to avoid impacting the normal business activity; for target, use a sandpit Azure DevOps organisation (not the production organisation)
 - Install nkdagility Vsts Sync Migrator: https://github.com/nkdAgility/azure-devops-migration-tools
 - Install WiMigrator: https://github.com/microsoft/vsts-work-item-migrator 
 - Clone the migration scripts and configuration files from this repo: TODO: insert repo link
 - Configure the inherited process, use either Scrum or Agile as base and create your own inherited process
 - configure custom fields, if any - the target fields cannot contain "." in the name, and the reference name will become Custom.<FieldName>; to overcome this issue, you can name the target fields using "_" (`<Org>_<Namespace>_<Field>`)
 - configure custom work item types, if any
 - configure layout
 - to avoid linking new items with a particular user, you can use a service account to perform the migration (add the corresponding user, give it temporary organisation admin permissions and create a PAT - you will use this PAT later)
 - add users to the target organisation / project - this is a one-off task; add users manually using Organisation settings → Users page
There is an option to automate the user creation process by running the *script.Identities.ps1* script:
- first, create the authentication context for both source and target projects
``` PowerShell
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
 
. .\Get-AzureDevOpsContext.ps1
 
$protocol = 'https'
$coreServer = '<tf server>/tfs'
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
```

- add one user / user entitlement (entitlement refers to assigning projects to users)
``` PowerShell
$upn = '<user email>'
$projectId = '<project guid>'
$accessLevel = 'stakeholder'
# . .\Add-AzureDevOpsUser.ps1
# $user = $destCtx | Add-AzureDevOpsUser -upn $upn
# . .\Add-AzureDevOpsUserProjectEntitlement.ps1
$response = $destCtx | Add-AzureDevOpsUserProjectEntitlement -upn $upn -accountLicenseType $accessLevel -projectId $projectId
```

 - add multiple users entitlements using a CSV file (the users have already been added to Users.csv file)
``` PowerShell
$projectId = '<project guid>'
$accessLevel = 'stakeholder'
 
$destCtx | Add-AzureDevOpsUsersProjectEntitlement -usersCsvPath .\Users.csv -accountLicenseType $accessLevel -projectId $projectId
```

 - Area Paths & Iterations and Teams migration. Use the VstsSyncMigrator.configuration.2.json configuration file for this step.
Configure the Source & Target settings to point to the correct source and target projects (you may use a service account PAT for target PersonalAccessToken).

Use the processor **NodeStructuresMigrationConfig** for Area Paths & Iterations and the processor **TeamMigrationConfig** for Teams migration (make sure Enabled is set to true).

Team configuration (add members, set default backlog iteration, associate area paths and iterations) must be done manually, for each migrated team.
``` json
{
  "Source": {
    "Collection": "https://<source server>/tfs/<source collection>",
    "Project": "<source project>",
    "ReflectedWorkItemIDFieldName": "Title",
    "AllowCrossProjectLinking": false,
    "PersonalAccessToken": ""
  },
  "Target": {
    "Collection": "https://dev.azure.com/<target org>",
    "Project": "<target project>",
    "ReflectedWorkItemIDFieldName": "Custom.ReflectedWorkItemID",
    "AllowCrossProjectLinking": false,
    "PersonalAccessToken": "***"
  },
  "Processors": [
    {
      "ObjectType": "VstsSyncMigrator.Engine.Configuration.Processing.NodeStructuresMigrationConfig",
      "PrefixProjectToNodes": false,
      "Enabled": true,
      "BasePaths": [
      ]
    },
    {
      "ObjectType": "VstsSyncMigrator.Engine.Configuration.Processing.TeamMigrationConfig",
      "PrefixProjectToNodes": false,
      "Enabled": true,
      "EnableTeamSettingsMigration": false
    }
}
```

 - Work Items migration - we used the WiMigrator for this step, as nkdagility Vsts Sync Migrator gave slow time estimation (~19 hours for ~1,000 work items)
 - WiMigrator works with saved queries; it's recommended you run the WIs migration in batches and create a query for each batch.
Use the *WiMigrator.configuration.json* configuration file.
Some of the configuration settings are described below:
 - `source-connection` - authentication information related to on-prem Azure DevOps server instance; set "use-integrated-auth" to true; make sure the current user has collection admin permissions
 - `target-connection` - authentication information for target Azure DevOps Services organisation; set access-token to the PAT created for your service account
 - `query` - the name (and path) of the query returning the WIs you want to migrate in a batch
``` json
  "query": "My Queries/WIs under 1920 - PI4",
```
 - "move-*" settings
``` json
"move-history": true,  
"move-history-limit": 200,  
"move-git-links": true,  
"move-attachments": true,  
"move-links": true,
```

Unfortunately, move-history only creates a JSON attachment containing up to move-history-limit (default 200), which doesn't seem to be very useful. The next step "Comment history migration" will show how to perform proper history migration.

 - "tag" settings
``` json
"source-post-move-tag": "",  
"target-post-move-tag": "batch-migration-001",
```
You can update the source Work Items tag as well, if you want to keep track of the migrated Work Items in the source project. However, it's more important to set the target post move tag as it makes easy to identify and track the currently migrated batch.
 - field mappings - this is required, as custom fields will need to be manually created and cannot match the on-prem Xml-hosted reference name
``` json
"field-replacements": {
  "System.Id": { "field-reference-name": "Custom.ReflectedWorkItemID" },
  "<Org>.<Namespace>.<Field>": { "field-reference-name": "Custom.<Field>" },
  ...
},
```

The field names on the left represent the source fields, whereas the field names in **field-reference-name** property on the right are target fields. The `Custom.ReflectedWorkItemID` is crucial in mapping source and target WIs; it is used for comment history migration and Test Case association with Test Suites.
 - Comment history migration: use the script *script.WIs.ps1* to perform comment history migration.

You need to generate the CSV mapping file, containing the source ID and the target ID. You can generate the CSV file by creating a target query pointing to the migrated batch and export the results to CSV. You will need to rename the header to match the OldId and NewId fields used by the script.
``` PowerShell
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 

. .\Get-AzureDevOpsContext.ps1
$protocol = 'https'
$coreServer = '<Azure DevOps / TFS server>/tfs'
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

. .\Copy-Comments.ps1
$csvFilePath = '<map CSV file>'
Copy-Comments -srcCtx $srcCtx -destCtx $destCtx -csvFilePath $csvFilePath
```

 - Test Plans migration: see the [Test Plans migration page](./test-plans.md)

