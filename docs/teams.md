# Teams 

To migrate teams use the nkdagility Sync Migrator.

Use the VstsSyncMigrator.configuration.json configuration file for this step.
Execute the following steps:
 - Add the TeamMigrationConfig processor to the configuration file: 
``` json
"Processors": [
  {
    "ObjectType": "VstsSyncMigrator.Engine.Configuration.Processing.TeamMigrationConfig",
    "PrefixProjectToNodes": false,
    "Enabled": true,
    "EnableTeamSettingsMigration": false
  },
 ...
]
```
 - Execute the migration: 
```
migration.exe -c <path to config file>
```
 - Configure the team settings manually: iterations, areas, members, etc.
