targetScope = 'managementGroup'

param parentId string = az.managementGroup().id
param managementGroup object

module mgmModule 'br/modules:governance/management-group:1.1.0' = {

  name: 'mgm.level0.${managementGroup.name}'
  params: {
    parentId: parentId
    managementGroup: managementGroup
  }
}
