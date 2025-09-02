variable "admin_password" {
  type        = string
  description = "Admin password"
  sensitive   = true
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "custom_location_id" {
  type        = string
  description = "The custom location ID for the Azure Stack HCI cluster."
}

variable "image_id" {
  type        = string
  description = "The name of a Marketplace Gallery Image already downloaded to the Azure Stack HCI cluster. For example: winServer2022-01"
}

variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
}

variable "logical_network_id" {
  type        = string
  description = "The ID of the logical network to use for the NIC."
}

variable "name" {
  type        = string
  description = "Name of the VM resource"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "auto_upgrade_minor_version" {
  type        = bool
  default     = true
  description = "Whether to enable auto upgrade minor version"
}

variable "data_disk_params" {
  type = map(object({
    name        = string
    diskSizeGB  = number
    dynamic     = bool
    tags        = optional(map(string))
    containerId = optional(string)
  }))
  default     = {}
  description = "The array description of the dataDisks to attach to the vm. Provide an empty array for no additional disks, or an array following the example below."
}

variable "linux_ssh_config" {
  type = object({
    publicKeys = optional(list(object({
      keyData = string
      path    = string
    })), [])
  })
  default     = {
    publicKeys = []
  }
  description = "SSH configuration with public keys for linux. Empty if not used."
}

variable "windows_ssh_config" {
  type = object({
    publicKeys = optional(list(object({
      keyData = string
      path    = string
    })), [])
  })
  default     = {
    publicKeys = []
  }
  description = "SSH configuration with public keys for windows. Empty if not used."
}
variable "memory" {
  type        = number
  default     = 8192
  description = "Memory in MB"
}

variable "os_type" {
  type        = string
  default     = "Windows"
  description = "The OS type of the VM. Possible values are 'Windows' and 'Linux'."
}

variable "secure_boot_enabled" {
  type        = bool
  default     = true
  description = "Enable secure boot"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the arc vm."
}
variable "user_storage_id" {
  type        = string
  default     = ""
  description = "The user storage ID to store images."
}

variable "cpu_count" {
  type        = number
  default     = 2
  description = "Number of vCPUs"
}


