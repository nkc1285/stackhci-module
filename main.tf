locals {
  virtual_machine_osProfile = {
    computerName = var.name
    linuxConfiguration = {
      ssh = var.linux_ssh_config == null ? {} : var.linux_ssh_config
    }
    windowsConfiguration = {
      provisionVMAgent       = true
      provisionVMConfigAgent = true
      ssh                    = var.windows_ssh_config == null ? {} : var.windows_ssh_config
    }
    adminUsername = var.admin_username
    adminPassword = var.admin_password
  }
  virtual_machine_properties_all = merge(
    (local.virtual_machine_properties_omit_null),
    {
      osProfile = local.virtual_machine_osProfile
    }
  )
  virtual_machine_properties_omit_null = { for key, value in local.virtual_machine_properties_without_auth : key => value if value != null }
  
  virtual_machine_properties_without_auth = {
    hardwareProfile = {
      vmSize              = "Custom"
      processors          = var.cpu_count
      memoryMB            = var.memory
      }
    httpProxyConfig = {}

    securityProfile = {
      uefiSettings = {
        secureBootEnabled = var.secure_boot_enabled
      }
    }
    storageProfile = {
      vmConfigStoragePathId = var.user_storage_id == "" ? null : var.user_storage_id
      imageReference = {
        id = var.image_id
      }
      dataDisks = [for key, value in azapi_resource.data_disks : {
        id = value.id
      }]
      osDisk = {
        osType = var.os_type
      }
    }
    networkProfile = {
      networkInterfaces = [
        {
          id = azapi_resource.nic.id
        }
      ]
    }
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Hybrid Compute Machine
resource "azapi_resource" "hybrid_compute_machine" {
  type = "Microsoft.HybridCompute/machines@2023-10-03-preview"
  body = {
    kind = "HCI",
    properties = {
      agentUpgrade = {
        correlationId          = null
        desiredVersion         = null
        enableAutomaticUpgrade = null
      }
      clientPublicKey = null
      cloudMetadata   = {}
      licenseProfile = {
        esuProfile = {
          licenseAssignmentState = null
        }
      }
      mssqlDiscovered = null
      osProfile = {
        linuxConfiguration = {
          patchSettings = {
            assessmentMode = null
            patchMode      = null
          }
        }
        windowsConfiguration = {
          patchSettings = {
            assessmentMode = null
            patchMode      = null
          }
        }
      }
      osType = null
      serviceStatuses = {
        extensionService = {
          startupType = null
          status      = null
        }
        guestConfigurationService = {
          startupType = null
          status      = null
        }
      }
      vmId = null
    }
  }
  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      body.properties.agentUpgrade,
      body.properties.clientPublicKey,
      body.properties.cloudMetadata,
      body.properties.extensions,
      body.properties.licenseProfile,
      body.properties.locationData,
      body.properties.locationData.city,
      body.properties.locationData.countryOrRegion,
      body.properties.locationData.district,
      body.properties.locationData.name,
      body.properties.mssqlDiscovered,
      body.properties.osProfile,
      body.properties.osType,
      body.properties.parentClusterResourceId,
      body.properties.privateLinkScopeResourceId,
      body.properties.serviceStatuses,
      body.properties.vmId,
      identity[0].identity_ids,
      parent_id,
      tags
    ]
  }
}

# Virtual Machine Instance
resource "azapi_resource" "virtual_machine" {
  type = "Microsoft.AzureStackHCI/virtualMachineInstances@2023-09-01-preview"
  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = local.virtual_machine_properties_all
  }
  name      = "default" # value must be 'default' per 2023-09-01-preview
  parent_id = azapi_resource.hybrid_compute_machine.id
  ignore_missing_property = true

  timeouts {
    create = "2h"
  }

  lifecycle {
    ignore_changes = [
      body.properties.storageProfile.vmConfigStoragePathId,
      parent_id,
      tags
    ]
  }
}

resource "azapi_resource" "data_disks" {
  for_each = var.data_disk_params

  type = "Microsoft.AzureStackHCI/virtualHardDisks@2023-09-01-preview"
  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      diskSizeGB  = each.value.diskSizeGB
      dynamic     = each.value.dynamic
    }
  }
  location  = var.location
  name      = each.value.name != "" ? each.value.name : "${var.name}dataDisk${format("%02d", index(var.data_disk_params, each.key) + 1)}"
  parent_id = data.azurerm_resource_group.rg.id
  tags      = each.value.tags

  lifecycle {
    ignore_changes = [
      body.properties.dynamic,
      parent_id,
      tags
    ]
  }
}

resource "azapi_resource" "nic" {
  type = "Microsoft.AzureStackHCI/networkInterfaces@2023-09-01-preview"
  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }

    properties = {
      ipConfigurations = [{
        properties = {
          subnet = {
            id = var.logical_network_id
          }
        }
      }]
    }
  }
  location  = var.location
  name      = "${var.name}-nic"
  parent_id = data.azurerm_resource_group.rg.id
  ignore_missing_property = true

  lifecycle {
    ignore_changes = [
      body.properties.ipConfigurations[0].name,
      body.properties.ipConfigurations[0].properties.privateIPAddress,
      body.properties.macAddress,
      parent_id,
      tags,
    ]
  }
}
