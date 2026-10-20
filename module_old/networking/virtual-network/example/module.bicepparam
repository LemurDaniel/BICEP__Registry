using './module.bicep'

param environment = 'dev'

param config = {
  addressSpace: '10.0.0.0/19'

  subnet: {
    app: {
      securityGroup: 'nsg_01'
    }

    db: {
      // Leaving nsg_key empty.
      // nsg_key: 'nsg_00'
    }

    kv: {
      securityGroup: 'nsg_00'
    }
  }

  nsg: {
    nsg_00: {
      inbound: {
        Allow_SSH: {
          priority: 200
          access: 'Allow'
          protocol: 'Tcp'
          destinationPorts: [
            '22'
          ]
        }
        Allow_HTTP: {
          priority: 210
          access: 'Allow'
          protocol: 'Tcp'
          destinationPorts: [
            '80'
          ]
        }
      }
    }
    nsg_01: {
      inbound: {
        Allow_SSH: {
          priority: 200
          access: 'Allow'
          protocol: 'Tcp'
          destinationPort: '22'
        }
        Allow_HTTP: {
          priority: 210
          access: 'Allow'
          protocol: 'Tcp'
          destinationPort: '80'
        }
      }
    }
  }
}
