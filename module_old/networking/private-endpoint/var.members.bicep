@export()
@description('I don\'t know why we can\'t use the provdier and resource type, but use some weird shortnames to lookup instead, but that is how it works .')
var varMemberReference = {
  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Machine Learning and AI
  'Microsoft.CognitiveServices/accounts': {
    default: {
      groupId: 'account'
      privateDns: 'privatelink.cognitiveservices.azure.com'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Synapse
  'Microsoft.Synapse/privateLinkHubs': {
    default: {
      groupId: 'web'
      privateDns: 'privatelink.privatelinkhub.azure.com'
    }
  }
  'Microsoft.Synapse/workspaces': {
    default: {
      groupId: 'Sql'
      privateDns: 'privatelink.sql.azure.com'
    }
    sql: {
      groupId: 'Sql'
      privateDns: 'privatelink.sql.azuresynapse.net'
    }
    sqlOnDemand: {
      groupId: 'SqlOnDemand'
      privateDns: 'privatelink.sql.azuresynapse.net'
    }
    dev: {
      groupId: 'Dev'
      privateDns: 'dev.azuresynapse.net'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// IoT
  'Microsoft.Devices/provisioningServices': {
    default: {
      groupId: 'iotDps'
      privateDns: 'privatelink.azure-devices-provisioning.net'
    }
  }
  'Microsoft.IoTCentral/IoTApps': {
    default: {
      groupId: 'IoTApps'
      privateDns: 'privatelink.azureiotcentral.com'
    }
  }
  'Microsoft.Devices/IotHubs': {
    default: {
      groupId: 'iotHub'
      privateDns: 'privatelink.azure-devices.net'
    }
  }
  'Microsoft.DigitalTwins/digitalTwinsInstances': {
    default: {
      groupId: 'API'
      privateDns: 'privatelink.api.wcus.digitaltwins.azure.net'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Messaging and networking
  'Microsoft.Relay/namespaces': {
    default: {
      groupId: 'namespace'
      privateDns: 'privatelink.servicebus.windows.net'
    }
  }
  'Microsoft.ServiceBus/namespaces': {
    default: {
      groupId: 'namespace'
      privateDns: 'privatelink.servicebus.windows.net'
    }
  }
  'Microsoft.EventGrid/domain': {
    default: {
      groupId: 'domain'
      privateDns: 'privatelink.eventgrid.azure.net'
    }
  }
  'Microsoft.EventGrid/topics': {
    topics: {
      groupId: 'topic'
      privateDns: 'privatelink.eventgrid.azure.net'
    }
  }
  'Microsoft.EventHub/namespaces': {
    default: {
      groupId: 'namespace'
      privateDns: 'privatelink.servicebus.windows.net'
    }
  }

  'Microsoft.SignalRService/signalR': {
    default: {
      groupId: 'signalr'
      privateDns: 'privatelink.service.signalr.net'
    }
  }

  'Microsoft.Network/privateLinkServices': {
    default: {
      groupId: null
      privateDns: 'privatelink.pls.azure.com'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Web
  'Microsoft.Web/sites': {
    default: {
      groupId: 'sites'
      privateDns: 'privatelink.azurewebsites.net'
    }
  }

  'Microsoft.ApiManagement/service': {
    default: {
      groupId: 'Gateway'
      privateDns: 'privatelink.azure-api.net'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Computation and automation
  'Microsoft.ContainerService/managedClusters': {
    default: {
      groupId: 'management'
      privateDns: 'privatelink.aks.azure.com'
    }
  }
  'Microsoft.Compute/diskAccesses': {
    default: {
      groupId: 'managed disk'
      privateDns: 'privatelink.diskaccess.windows.net'
    }
  }

  'Microsoft.Automation/automationAccounts': {
    default: {
      groupId: 'DSCAndHybridWorker'
      privateDns: 'privatelink.azure-automation.net'
    }
    DSCAndHybridWorker: {
      groupId: 'DSCAndHybridWorker'
      privateDns: 'privatelink.azure-automation.net'
    }
    webhook: {
      groupId: 'Webhook'
      privateDns: 'privatelink.azure-automation.net'
    }
  }

  'Microsoft.Batch/batchAccounts': {
    default: {
      groupId: 'batchAccount'
      privateDns: 'privatelink.batch.azure.com'
    }
    nodeManagement: {
      groupId: 'nodeManagement'
      privateDns: 'privatelink.batch.azure.com'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Storage
  'Microsoft.Storage/storageAccounts': {
    default: {
      groupId: 'blob'
      privateDns: 'privatelink.blob.${az.environment().suffixes.storage}'
    }
    blob: {
      groupId: 'blob'
      privateDns: 'privatelink.blob.${az.environment().suffixes.storage}'
    }
    table: {
      groupId: 'table'
      privateDns: 'privatelink.table.${az.environment().suffixes.storage}'
    }
    queue: {
      groupId: 'queue'
      privateDns: 'privatelink.queue.${az.environment().suffixes.storage}'
    }
    file: {
      groupId: 'file'
      privateDns: 'privatelink.file.${az.environment().suffixes.storage}'
    }
    web: {
      groupId: 'web'
      privateDns: 'privatelink.web.${az.environment().suffixes.storage}'
    }
    dfs: {
      groupId: 'dfs'
      privateDns: 'privatelink.dfs.${az.environment().suffixes.storage}'
    }
    blob_secondary: {
      groupId: 'blob_secondary'
      privateDns: 'privatelink.blob.${az.environment().suffixes.storage}'
    }
    table_secondary: {
      groupId: 'table_secondary'
      privateDns: 'privatelink.table.${az.environment().suffixes.storage}'
    }
    queue_secondary: {
      groupId: 'queue_secondary'
      privateDns: 'privatelink.queue.${az.environment().suffixes.storage}'
    }
    file_secondary: {
      groupId: 'file_secondary'
      privateDns: 'privatelink.file.${az.environment().suffixes.storage}'
    }
    web_secondary: {
      groupId: 'web_secondary'
      privateDns: 'privatelink.web.${az.environment().suffixes.storage}'
    }
    dfs_secondary: {
      groupId: 'dfs_secondary'
      privateDns: 'privatelink.dfs.${az.environment().suffixes.storage}'
    }
  }

  'Microsoft.StorageSync/storageSyncServices': {
    default: {
      groupId: 'File Sync Service'
      privateDns: 'privatelink.afs.azure.net'
    }
  }

  'Microsoft.RecoveryServices/vaults': {
    default: {
      groupId: 'AzureBackup'
      privateDns: 'privatelink.azureBackup.azure.net'
    }
    azureBackup: {
      groupId: 'AzureBackup'
      privateDns: 'privatelink.azurebackup.azure.net'
    }
    azureSiteRecovery: {
      groupId: 'AzureSiteRecovery'
      privateDns: 'privatelink.siterecovery.windowsazure.com'
    }
  }

  'Microsoft.KeyVault/vaults': {
    default: {
      groupId: 'vault'
      privateDns: 'privatelink.vaultcore.azure.net'
    }
  }
  'Microsoft.Keyvault/managedHSMs': {
    default: {
      groupId: 'HSM'
      privateDns: 'privatelink.managedhsm.azure.net'
    }
  }

  'Microsoft.ContainerRegistry/registries': {
    default: {
      groupId: 'registry'
      privateDns: 'privatelink.azurecr.io'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Database
  'Microsoft.DBforMariaDB/servers': {
    default: {
      groupId: 'mariadbServer'
      privateDns: 'privatelink.mariadb.database.azure.com'
    }
  }
  'Microsoft.DBforMariaDB/flexibleServers': {
    default: {
      groupId: 'mariadbServer'
      privateDns: 'privatelink.mariadb.database.azure.com'
    }
  }

  'Microsoft.DBforPostgreSQL/flexibleServers': {
    default: {
      groupId: 'postgresqlServer'
      privateDns: 'privatelink.postgres.database.azure.com'
    }
  }
  'Microsoft.DBforPostgreSQL/servers': {
    default: {
      groupId: 'postgresqlServer'
      privateDns: 'privatelink.postgres.database.azure.com'
    }
  }
  'Microsoft.DBforPostgreSQL/serverGroupsv2': {
    default: {
      groupId: 'coordinator'
      privateDns: 'privatelink.postgres.database.azure.com'
    }
  }

  'Microsoft.DBforMySQL/servers': {
    default: {
      groupId: 'mysqlServer'
      privateDns: 'privatelink.mysql.database.azure.com'
    }
  }
  'Microsoft.DBforMySQL/flexibleServers': {
    default: {
      groupId: 'mysqlServer'
      privateDns: 'privatelink.mysql.database.azure.com'
    }
  }

  'Microsoft.Sql/sqlServers': {
    default: {
      groupId: 'sqlServer'
      privateDns: 'privatelink.sql.azure.com'
    }
  }
  'Microsoft.Sql/managedInstance': {
    default: {
      groupId: 'managedInstance'
      privateDns: 'privatelink${az.environment().suffixes.sqlServerHostname}'
    }
  }

  'Microsoft.DocumentDb/databaseAccounts': {
    default: {
      groupId: 'SQL'
      privateDns: 'privatelink.documents.azure.com'
    }
    sql: {
      groupId: 'SQL'
      privateDns: 'privatelink.documents.azure.com'
    }
    mongoDB: {
      groupId: 'MongoDB'
      privateDns: 'privatelink.mongo.cosmos.azure.com'
    }
    cassandra: {
      groupId: 'Cassandra'
      privateDns: 'privatelink.cassandra.cosmos.azure.com'
    }
    gremlin: {
      groupId: 'Gremlin'
      privateDns: 'privatelink.gremlin.cosmos.azure.com'
    }
    table: {
      groupId: 'Table'
      privateDns: 'privatelink.table.cosmos.azure.com'
    }
  }

  'Microsoft.Cache/redis': {
    default: {
      groupId: 'redisCache'
      privateDns: 'privatelink.redis.cache.windows.net'
    }
  }
  'Microsoft.Cache/redisEnterprise': {
    default: {
      groupId: 'redisEnterprise'
      privateDns: 'privatelink.redisenterprise.cache.azure.net'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Big data and analytics
  'Microsoft.HDInsight/clusters': {
    default: {
      groupId: 'cluster'
      privateDns: 'privatelink.azurehdinsight.net'
    }
  }
  'Microsoft.Kusto/clusters': {
    default: {
      groupId: 'cluster'
      privateDns: 'privatelink.kusto.windows.net'
    }
  }

  'Microsoft.DataFactory/factories': {
    default: {
      groupId: 'dataFactory'
      privateDns: 'privatelink.datafactory.azure.net'
    }
  }

  'Microsoft.Databricks/workspaces': {
    databricks_ui_api: {
      groupId: 'databricks_ui_api'
      privateDns: 'privatelink.azuredatabricks.net'
    }
    browser_authentication: {
      groupId: 'browser_authentication'
      privateDns: 'privatelink.azuredatabricks.net'
    }
  }

  'Microsoft.Search/searchServices': {
    default: {
      groupId: 'searchService'
      privateDns: 'privatelink.search.windows.net'
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  ////// Healthcare and configuration
  'Microsoft.HealthcareApis/services': {
    default: {
      groupId: 'fhir'
      privateDns: 'privatelink.azurehealthcareapis.com'
    }
  }
  'Microsoft.Appconfiguration/configurationStores': {
    default: {
      groupId: 'configurationStores'
      privateDns: 'privatelink.azconfig.io'
    }
  }

  'Microsoft.Attestation/attestationProviders': {
    default: {
      groupId: 'standard'
      privateDns: 'privatelink.attest.azure.net'
    }
  }

  'Microsoft.Media/mediaservices': {
    default: {
      groupId: 'mediaservices'
      privateDns: 'privatelink.mediaservices.azure.net'
    }
    keydelivery: {
      groupId: 'keydelivery'
      privateDns: 'privatelink.keydelivery.mediaservices.azure.net'
    }
    liveevent: {
      groupId: 'liveevent'
      privateDns: 'privatelink.liveevent.mediaservices.azure.net'
    }
    streamingendpoint: {
      groupId: 'streamingendpoint'
      privateDns: 'privatelink.streaming.mediaservices.azure.net'
    }
  }

  'Microsoft.Migrate/assessmentProjects': {
    default: {
      groupId: 'project'
      privateDns: 'privatelink.migrateassessment.azure.com'
    }
  }
  'Microsoft.Insights/privatelinkscopes': {
    default: {
      groupId: 'azuremonitor'
      privateDns: 'privatelink.monitor.azure.com'
    }
  }

  'Microsoft.Purview/accounts': {
    default: {
      groupId: 'account'
      privateDns: 'privatelink.purview.azure.com'
    }
    account: {
      groupId: 'account'
      privateDns: 'privatelink.purview.azure.com'
    }
    portal: {
      groupId: 'portal'
      privateDns: 'privatelink.purviewstudio.azure.com'
    }
  }

  'Microsoft.DeviceUpdate/accounts': {
    default: {
      groupId: 'DeviceUpdate'
      privateDns: 'privatelink.deviceupdate.azure.com'
    }
  }

  'Microsoft.PowerBI/privateLinkServicesForPowerBI': {
    default: {
      groupId: 'Power BI'
      privateDns: 'privatelink.powerbi.com'
    }
  }

  //'Microsoft.Authorization/resourceManagementPrivateLinks': {
  //  default: {
  //    groupId: 'ResourceManagement'
  //    privateDns: 'privatelink.management.azure.com'
  //  }
  //}
}
