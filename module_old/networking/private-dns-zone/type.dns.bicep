type dnsEntryType = {
  a: {
    *: {
      ipv4Address: string
      ttl: int?
    }
  }?
  aaaa: {
    *: {
      ipv6Address: string
      ttl: int?
    }
  }?
  cname: {
    *: {
      cname: string
      ttl: int?
    }
  }?
  txt: {
    *: {
      txt: string[]
      ttl: int?
    }
  }?
}?

@export()
type typeDnsServices = {
  //////////////////////////////////////////
  ///////////////////// AI + Machine Learning
  'Microsoft.MachineLearningServices/workspaces': {
    default: dnsEntryType
  }?
  'Microsoft.CognitiveServices/accounts': {
    openAi: dnsEntryType
    cognitiveService: dnsEntryType
  }?
  'Microsoft.BotService/botServices': {
    bot: dnsEntryType
    token: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Analytics
  'Microsoft.Synapse/workspaces': {
    sql: dnsEntryType
    sqlOnDemand: dnsEntryType
    dev: dnsEntryType
  }?
  'Microsoft.Synapse/privateLinkHubs': {
    default: dnsEntryType
  }?
  'Microsoft.EventHub/namespaces': {
    default: dnsEntryType
  }?
  'Microsoft.DataFactory/factories': {
    dataFactory: dnsEntryType
    headnode: dnsEntryType
  }?
  'Microsoft.HDInsight/clusters': {
    gateway: dnsEntryType
    portal: dnsEntryType
  }?
  'Microsoft.Kusto/Clusters': {
    default: dnsEntryType
  }?
  'Microsoft.Databricks/workspaces': {
    databricks_ui_api: dnsEntryType
    browser_authentication: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Compute
  'Microsoft.Batch/batchAccounts': {
    batchAccount: dnsEntryType
    nodeManagement: dnsEntryType
  }?
  'Microsoft.DesktopVirtualization/workspaces': {
    global: dnsEntryType
    feed: dnsEntryType
  }?
  'Microsoft.DesktopVirtualization/hostpools': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Containers
  'Microsoft.ContainerService/managedClusters': {
    default: dnsEntryType
  }?
  'Microsoft.App/ManagedEnvironments': {
    default: dnsEntryType
  }?
  'Microsoft.ContainerRegistry/registries': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Database
  'Microsoft.Sql/servers': {
    default: dnsEntryType
  }?
  'Microsoft.Sql/managedInstances': {
    default: dnsEntryType
  }?
  'Microsoft.DocumentDB/databaseAccounts': {
    Sql: dnsEntryType
    MongoDB: dnsEntryType
    Cassandra: dnsEntryType
    Gremlin: dnsEntryType
    Table: dnsEntryType
    Analytical: dnsEntryType
  }?
  'Microsoft.DBforPostgreSQL/serverGroupsv2': {
    default: dnsEntryType
  }?
  'Microsoft.DBforPostgreSQL/servers': {
    default: dnsEntryType
  }?
  'Microsoft.DBforPostgreSQL/flexibleServers': {
    default: dnsEntryType
  }?
  'Microsoft.DBforMySQL/servers': {
    default: dnsEntryType
  }?
  'Microsoft.DBforMySQL/flexibleServers': {
    default: dnsEntryType
  }?
  'Microsoft.DBforMariaDB/servers': {
    default: dnsEntryType
  }?
  'Microsoft.Cache/Redis': {
    default: dnsEntryType
  }?
  'Microsoft.Cache/RedisEnterprise': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Hybrid + multicloud
  'Microsoft.HybridCompute/privateLinkScopes': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Integration
  'Microsoft.ServiceBus/namespaces': {
    default: dnsEntryType
  }?
  'Microsoft.EventGrid/namespaces': {
    topics: dnsEntryType
    domains: dnsEntryType
    topicSpace: dnsEntryType
    partnerNameSpace: dnsEntryType
  }?
  'Microsoft.ApiManagement/service': dnsEntryType
  'Microsoft.HealthcareApis/workspaces': {
    healthcareWorkspace: dnsEntryType
    fhir: dnsEntryType
    dicom: dnsEntryType
  }?
  'Microsoft.Devices/IotHubs': {
    iotHub: dnsEntryType
    serviceBus: dnsEntryType
  }?
  'Microsoft.Devices/ProvisioningServices': {
    default: dnsEntryType
  }?
  'Microsoft.DeviceUpdate/accounts': {
    default: dnsEntryType
  }?
  'Microsoft.IoTCentral/IoTApps': {
    default: dnsEntryType
  }?
  'Microsoft.DigitalTwins/digitalTwinsInstances': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Media
  'Microsoft.Media/mediaservices': {
    keyDelivery: dnsEntryType
    liveevent: dnsEntryType
    streamingendpoint: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Management and Governance
  'Microsoft.Automation/automationAccounts': {
    Webhook: dnsEntryType
    DSCAndHybridWorker: dnsEntryType
  }?
  'Microsoft.RecoveryServices/vaults': {
    AzureBackup: dnsEntryType
    AzureSiteRecovery: dnsEntryType
  }?
  'Microsoft.Insights/privateLinkScopes': {
    azuremonitor: dnsEntryType
    oms: dnsEntryType
    ods: dnsEntryType
    agentsvc: dnsEntryType
  }?
  'Microsoft.Purview/accounts': {
    account: dnsEntryType
    portal: dnsEntryType
  }?
  'Microsoft.Migrate/migrateProjects': {
    default: dnsEntryType
  }?
  'Microsoft.Authorization/resourceManagementPrivateLinks': {
    default: dnsEntryType
  }?
  'Microsoft.Dashboard/grafana': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Security
  'Microsoft.KeyVault/vaults': {
    default: dnsEntryType
  }?
  'Microsoft.KeyVault/managedHSMs': {
    default: dnsEntryType
  }?
  'Microsoft.AppConfiguration/configurationStores': {
    default: dnsEntryType
  }?
  'Microsoft.Attestation/attestationProviders': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Storage
  'Microsoft.Storage/storageAccounts': {
    blob: dnsEntryType
    file: dnsEntryType
    queue: dnsEntryType
    table: dnsEntryType
    dfs: dnsEntryType
  }?
  'Microsoft.StorageSync/storageSyncServices': {
    default: dnsEntryType
  }?
  'Microsoft.Compute/diskAccesses': {
    default: dnsEntryType
  }?
  //////////////////////////////////////////
  ///////////////////// Web
  'Microsoft.Search/searchServices': {
    default: dnsEntryType
  }?
  'Microsoft.Relay/namespaces': {
    default: dnsEntryType
  }?
  'Microsoft.Web/sites': {
    default: dnsEntryType
  }?
  'Microsoft.SignalRService/SignalR': {
    default: dnsEntryType
  }?
  'Microsoft.Web/staticSites': {
    default: dnsEntryType
  }?
}
