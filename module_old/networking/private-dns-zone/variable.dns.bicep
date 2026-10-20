@export()
@description('''
**Get Private DNS Zone Info**
''')
func getDefaultPrivateDns(serviceName string, subServiceName string) {
  name: string
} => {
  name: commonDnsNames[serviceName][?subServiceName] ?? fail(format(
    'No private DNS zone found for service "{0}" and subService "{1}".',
    serviceName,
    subServiceName
  ))
}

// https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
@export()
var commonDnsNames = {
  //////////////////////////////////////////
  ///////////////////// AI + Machine Learning
  'Microsoft.MachineLearningServices/workspaces': {
    default: 'privatelink.api.azureml.ms'
    workspace: 'privatelink.api.azureml.ms'
  }
  'Microsoft.CognitiveServices/accounts': {
    cognitiveServices: 'privatelink.cognitiveservices.azure.com'
    openAi: 'privatelink.openai.azure.com'
  }
  'Microsoft.BotService/botServices': {
    bot: 'privatelink.directline.botframework.com'
    token: 'privatelink.token.botframework.com'
  }

  //////////////////////////////////////////
  ///////////////////// Analytics
  'Microsoft.Synapse/workspaces': {
    default: 'privatelink.azuresynapse.net'
    sql: 'privatelink.sql.azuresynapse.net'
    sqlOnDemand: 'privatelink.sql.azuresynapse.net'
    dev: 'privatelink.dev.azuresynapse.net'
  }
  'Microsoft.Synapse/privateLinkHubs': {
    default: 'privatelink.azuresynapse.net'
    web: 'privatelink.azuresynapse.net'
  }
  'Microsoft.EventHub/namespaces': {
    default: 'privatelink.servicebus.windows.net'
    eventHub: 'privatelink.servicebus.windows.net'
    serviceBus: 'privatelink.servicebus.windows.net'
  }
  'Microsoft.DataFactory/factories': {
    default: 'privatelink.datafactory.azure.net'
    dataFactory: 'privatelink.datafactory.azure.net'
    portal: 'privatelink.adf.azure.com'
  }
  'Microsoft.HDInsight/clusters': {
    default: 'privatelink.azurehdinsight.net'
    gateway: 'privatelink.azurehdinsight.net'
    headnode: 'privatelink.azurehdinsight.net'
  }
  'Microsoft.Kusto/Clusters': {
    default: 'privatelink.kusto.windows.net'
    cluster: 'privatelink.{regionName}.kusto.windows.net'
  }
  /////////////////////'Microsoft.PowerBI/privateLinkServicesForPowerBI/tenant': {
  /////////////////////  privateDNS: 'privatelink.analysis.windows.net'
  /////////////////////  
  /////////////////////}
  /////////////////////'Microsoft.PowerBI/privateLinkServicesForPowerBI/tenant': {
  /////////////////////  privateDNS: 'privatelink.pbidedicated.windows.net'
  /////////////////////  
  /////////////////////}
  /////////////////////'Microsoft.PowerBI/privateLinkServicesForPowerBI/tenant': {
  /////////////////////  privateDNS: 'privatelink.tip1.powerquery.microsoft.com'
  /////////////////////  
  /////////////////////}

  'Microsoft.Databricks/workspaces': {
    default: 'privatelink.azuredatabricks.net'
    databricks_ui_api: 'privatelink.azuredatabricks.net'
    browser_authentication: 'privatelink.azuredatabricks.net'
  }

  //////////////////////////////////////////
  ///////////////////// Compute
  'Microsoft.Batch/batchAccounts': {
    default: 'privatelink.batch.azure.com'
    batchAccount: 'privatelink.batch.azure.com'
    nodeManagement: 'privatelink.batch.azure.com'
  }
  'Microsoft.DesktopVirtualization/workspaces': {
    default: 'privatelink.wvd.microsoft.com'
    global: 'privatelink-global.wvd.microsoft.com'
    feed: 'privatelink.wvd.microsoft.com'
  }
  'Microsoft.DesktopVirtualization/hostpools': {
    default: 'privatelink.wvd.microsoft.com'
    hostpools: 'privatelink.wvd.microsoft.com'
  }

  //////////////////////////////////////////
  ///////////////////// Containers
  'Microsoft.ContainerService/managedClusters': {
    default: 'privatelink.{regionName}.azmk8s.io'
    management: 'privatelink.{regionName}.azmk8s.io'
    subzone: '{subzone}.privatelink.{regionName}.azmk8s.io'
  }
  'Microsoft.App/ManagedEnvironments': {
    default: 'privatelink.{regionName}.azurecontainerapps.io'
    managedEnvironments: 'privatelink.{regionName}.azurecontainerapps.io'
  }
  'Microsoft.ContainerRegistry/registries': {
    default: 'privatelink.azurecr.io'
    registries: 'privatelink.azurecr.io'
  }

  //////////////////////////////////////////
  ///////////////////// Database
  'Microsoft.Sql/servers': {
    default: 'privatelink.${environment().suffixes.sqlServerHostname}'
    servers: 'privatelink.${environment().suffixes.sqlServerHostname}'
  }
  'Microsoft.Sql/managedInstances': {
    default: 'privatelink.${environment().suffixes.sqlServerHostname}'
    managedInstances: 'privatelink.{dnsPrefix}.${environment().suffixes.sqlServerHostname}'
  }
  'Microsoft.DocumentDB/databaseAccounts': {
    default: 'privatelink.documents.azure.com'
    sql: 'privatelink.documents.azure.com'
    mongoDB: 'privatelink.mongo.cosmos.azure.com'
    cassandra: 'privatelink.cassandra.cosmos.azure.com'
    gremlin: 'privatelink.gremlin.cosmos.azure.com'
    table: 'privatelink.table.cosmos.azure.com'
    analytical: 'privatelink.analytics.cosmos.azure.com'
  }
  'Microsoft.DBforPostgreSQL/serverGroupsv2': {
    default: 'privatelink.postgres.cosmos.azure.com'
    serverGroupsv2: 'privatelink.postgres.cosmos.azure.com'
  }
  'Microsoft.DBforPostgreSQL/servers': {
    default: 'privatelink.postgres.database.azure.com'
    servers: 'privatelink.postgres.database.azure.com'
  }
  'Microsoft.DBforPostgreSQL/flexibleServers': {
    default: 'privatelink.postgres.database.azure.com'
    flexibleServers: 'privatelink.postgres.database.azure.com'
  }
  'Microsoft.DBforMySQL/servers': {
    default: 'privatelink.mysql.database.azure.com'
    servers: 'privatelink.mysql.database.azure.com'
  }
  'Microsoft.DBforMySQL/flexibleServers': {
    default: 'privatelink.mysql.database.azure.com'
    flexibleServers: 'privatelink.mysql.database.azure.com'
  }
  'Microsoft.DBforMariaDB/servers': {
    default: 'privatelink.mariadb.database.azure.com'
    servers: 'privatelink.mariadb.database.azure.com'
  }
  'Microsoft.Cache/Redis': {
    default: 'privatelink.redis.cache.windows.net'
    redis: 'privatelink.redis.cache.windows.net'
  }
  'Microsoft.Cache/RedisEnterprise': {
    default: 'privatelink.redisenterprise.cache.azure.net'
    redisEnterprise: 'privatelink.redisenterprise.cache.azure.net'
  }
  //////////////////////////////////////////
  ///////////////////// Hybrid + multicloud
  'Microsoft.HybridCompute/privateLinkScopes': {
    default: 'privatelink.azure.com'
    his: 'privatelink.his.arc.azure.com'
    guestConfiguration: 'privatelink.guestconfiguration.azure.com'
    dpKubernetesConfiguration: 'privatelink.dp.kubernetesconfiguration.azure.com'
  }

  //////////////////////////////////////////
  ///////////////////// Integration
  'Microsoft.ServiceBus/namespace': {
    default: 'privatelink.servicebus.windows.net'
    serviceBus: 'privatelink.servicebus.windows.net'
  }
  'Microsoft.EventGrid/namespaces': {
    default: 'privatelink.eventgrid.azure.net'
    topics: 'privatelink.eventgrid.azure.net'
    domains: 'privatelink.eventgrid.azure.net'
    topicSpace: 'privatelink.ts.eventgrid.azure.net'
    partnerNamespace: 'privatelink.eventgrid.azure.net'
  }
  'Microsoft.ApiManagement/service': {
    default: 'privatelink.azure-api.net'
    gateway: 'privatelink.azure-api.net'
  }
  'Microsoft.HealthcareApis/workspaces': {
    default: 'privatelink.azurehealthcareapis.com'
    healthcareWorkspace: 'privatelink.workspace.azurehealthcareapis.com'
    fhir: 'privatelink.fhir.azurehealthcareapis.com'
    dicom: 'privatelink.dicom.azurehealthcareapis.com'
  }

  //////////////////////////////////////////
  ///////////////////// Internet of Things (IoT)
  'Microsoft.Devices/IotHubs': {
    default: 'privatelink.azure-devices.net'
    iotHub: 'privatelink.azure-devices.net'
    serviceBus: 'privatelink.servicebus.windows.net'
  }
  'Microsoft.Devices/ProvisioningServices': {
    default: 'privatelink.azure-devices-provisioning.net'
    iotDps: 'privatelink.azure-devices-provisioning.net'
  }
  'Microsoft.DeviceUpdate/accounts': {
    default: 'privatelink.api.adu.microsoft.com'
    deviceUpdate: 'privatelink.api.adu.microsoft.com'
  }
  'Microsoft.IoTCentral/IoTApps': {
    default: 'privatelink.azureiotcentral.com'
    iotApp: 'privatelink.azureiotcentral.com'
  }
  'Microsoft.DigitalTwins/digitalTwinsInstances': {
    default: 'privatelink.digitaltwins.azure.net'
    digitalTwinsInstances: 'privatelink.digitaltwins.azure.net'
  }

  //////////////////////////////////////////
  ///////////////////// Media
  'Microsoft.Media/mediaservices': {
    default: 'privatelink.media.azure.net'
    keyDelivery: 'privatelink.media.azure.net'
    liveevent: 'privatelink.media.azure.net'
    streamingendpoint: 'privatelink.media.azure.net'
  }

  //////////////////////////////////////////
  ///////////////////// Management and Governance
  'Microsoft.Automation/automationAccounts': {
    default: 'privatelink.azure-automation.net'
    webhook: 'privatelink.azure-automation.net'
    dSCAndHybridWorker: 'privatelink.azure-automation.net'
  }
  'Microsoft.RecoveryServices/vaults': {
    default: 'privatelink.vaultcore.azure.net'
    azureBackup: 'privatelink.{regionCode}.backup.windowsazure.com'
    azureSiteRecovery: 'privatelink.siterecovery.windowsazure.com'
  }
  'Microsoft.Insights/privateLinkScopes': {
    default: 'privatelink.monitor.azure.com'
    azuremonitor: 'privatelink.monitor.azure.com'
    oms: 'privatelink.oms.opinsights.azure.com'
    ods: 'privatelink.ods.opinsights.azure.com'
    agentsvc: 'privatelink.agentsvc.azure-automation.net'
  }
  'Microsoft.Purview/accounts': {
    default: 'privatelink.purview.azure.com'
    account: 'privatelink.purview.azure.com'
    portal: 'privatelink.purviewstudio.azure.com'
  }
  'Microsoft.Migrate/migrateProjects': {
    default: 'privatelink.azure.com'
    migrateProjects: 'privatelink.prod.migration.windowsazure.com'
  }
  'Microsoft.Authorization/resourceManagementPrivateLinks': {
    default: 'privatelink.azure.com'
    resourceManagementPrivateLinks: 'privatelink.azure.com'
  }
  'Microsoft.Dashboard/grafana': {
    default: 'privatelink.grafana.azure.com'
    grafana: 'privatelink.grafana.azure.com'
  }

  //////////////////////////////////////////
  ///////////////////// Security
  'Microsoft.KeyVault/vaults': {
    default: 'privatelink.vaultcore.azure.net'
    vaults: 'privatelink.vaultcore.azure.net'
  }
  'Microsoft.KeyVault/managedHSMs': {
    default: 'privatelink.managedhsm.azure.net'
    managedHSMs: 'privatelink.managedhsm.azure.net'
  }
  'Microsoft.AppConfiguration/configurationStores': {
    default: 'privatelink.azconfig.io'
    configurationStores: 'privatelink.azconfig.io'
  }
  'Microsoft.Attestation/attestationProviders': {
    default: 'privatelink.attest.azure.net'
    attestationProviders: 'privatelink.attest.azure.net'
  }

  //////////////////////////////////////////
  ///////////////////// Storage
  'Microsoft.Storage/storageAccounts': {
    default: 'privatelink.blob.${environment().suffixes.storage}'
    blob: 'privatelink.blob.${environment().suffixes.storage}'
    publicDNS: 'blob.${environment().suffixes.storage}'
    file: 'privatelink.file.${environment().suffixes.storage}'
    queue: 'privatelink.queue.${environment().suffixes.storage}'
    table: 'privatelink.table.${environment().suffixes.storage}'
    dfs: 'privatelink.dfs.${environment().suffixes.storage}'
  }

  'Microsoft.StorageSync/storageSyncServices': {
    default: 'privatelink.afs.azure.net'
    storageSyncService: 'privatelink.afs.azure.net'
  }
  'Microsoft.Compute/diskAccesses': {
    default: 'privatelink.blob.${environment().suffixes.storage}'
    diskAccesses: 'privatelink.blob.${environment().suffixes.storage}'
  }

  //////////////////////////////////////////
  ///////////////////// Web
  'Microsoft.Search/searchServices': {
    default: 'privatelink.search.windows.net'
    searchServices: 'privatelink.search.windows.net'
  }
  'Microsoft.Relay/namespaces': {
    default: 'privatelink.servicebus.windows.net'
    namespaces: 'privatelink.search.windows.net'
  }
  'Microsoft.Web/sites': {
    default: 'privatelink.azurewebsites.net'
    sites: 'privatelink.azurewebsites.net'
  }
  'Microsoft.SignalRService/SignalR': {
    default: 'privatelink.service.signalr.net'
    signalR: 'privatelink.service.signalr.net'
  }
  'Microsoft.Web/staticSites': {
    default: 'privatelink.azurestaticapps.net'
    staticSites: 'privatelink.azurestaticapps.net'
  }
}
