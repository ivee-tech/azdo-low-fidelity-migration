# Work Items Migration

The [nkdagility Sync Migrator](https://nkdagility.github.io/azure-devops-migration-tools/) has a powerful processor for migrating work items.

Execute the following steps:
 - Add the WorkItemMigrationConfig processor: 
``` json
"Processors": [
  {
    "ObjectType": "VstsSyncMigrator.Engine.Configuration.Processing.WorkItemMigrationConfig",
    "ReplayRevisions": true,
    "PrefixProjectToNodes": false,
    "UpdateCreatedDate": true,
    "UpdateCreatedBy": true,
    "UpdateSourceReflectedId": false,
    "BuildFieldTable": true,
    "AppendMigrationToolSignatureFooter": false,
    "QueryBit": "AND [System.WorkItemType] IN ('User Story', 'Task', 'Bug')",
    "OrderBit": "[System.ChangedDate] desc",
    "Enabled": true,
    "LinkMigration": true,
    "AttachmentMigration": true,
    "AttachmentWorkingPath": "c:\\temp\\WorkItemAttachmentWorkingFolder\\",
    "FixHtmlAttachmentLinks": false,
    "SkipToFinalRevisedWorkItemType": true,
    "WorkItemCreateRetryLimit": 5,
    "FilterWorkItemsThatAlreadyExistInTarget": true,
    "PauseAfterEachWorkItem": false,
    "AttachmentMazSize": 480000000,
    "CollapseRevisions": false
  }
]
```
 - Execute the migration: 
```
migrate.exe -c <path to config file>
```

For information on the WorkItemMigrationConfig processor settings, check this page: https://nkdagility.github.io/azure-devops-migration-tools/Processors/WorkItemMigrationConfig.html 

You can leave most of the default values as they are, but pay attention to the `QueryBit` setting. It's recommended to to tweak it to limit the number of work items subject to migration. Based on our experience, it's better to run migration in smaller batches if possible, to prevent timeouts, throttling, etc. 

