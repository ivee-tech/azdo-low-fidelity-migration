# Area Paths & Iterations 

To migrate area paths & iterations use the nkdagility Sync Migrator. There is no separation so both area paths & iterations will be migrated.
Use the VstsSyncMigrator.configuration.json configuration file for this step.
Execute the following steps:
 - Add the NodeStructuresMigrationConfig processor to the configuration file: 
``` json
"Processors": [
  {
    "ObjectType": "VstsSyncMigrator.Engine.Configuration.Processing.NodeStructuresMigrationConfig",
    "PrefixProjectToNodes": false,
    "Enabled": true,
    "BasePaths": [
    ]
  },
 ...
]
```
 - Execute the migration: 
```
migration.exe -c <path to config file>
```
