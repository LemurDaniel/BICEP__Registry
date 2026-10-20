using './module.bicep'

var exampleIdentifier = 'governance.management-group'
//
//

param managementGroup = {
  name: 'root.${exampleIdentifier}'
  childs: [
    {
      name: 'platform.${exampleIdentifier}'
      childs: [
        {
          name: 'identity.${exampleIdentifier}'
          childs: []
        }
        {
          name: 'connectivity.${exampleIdentifier}'
          childs: []
        }
        {
          name: 'security.${exampleIdentifier}'
          childs: []
        }
        {
          name: 'management.${exampleIdentifier}'
          childs: []
        }
      ]
    }
    {
      name: 'landingzone.${exampleIdentifier}'
      childs: [
        {
          name: 'corp.${exampleIdentifier}'
          childs: []
        }
        {
          name: 'online.${exampleIdentifier}'
          childs: []
        }
      ]
    }
    {
      name: 'sandbox.${exampleIdentifier}'
      childs: []
    }
  ]
}
