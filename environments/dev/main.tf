# Define variables that will be set in Terraform Cloud Workspace
variable "location" {
  description = "Azure region for the development environment."
  type        = string
  default     = "eastus" # Default for dev, can be overridden in TFC
}

variable "vm_admin_username" {
  description = "Admin username for the VM."
  type        = string
  sensitive   = true # Mark as sensitive, set in TFC
}

variable "vm_admin_password" {
  description = "Admin password for the VM."
  type        = string
  sensitive   = true # Mark as sensitive, set in TFC
}

variable "ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  sensitive   = true # Mark as sensitive, set in TFC
}

# KeyVault for Customer Managed Keys
resource "azurerm_key_vault" "main" {
  name                        = "kv-${local.environment}-${var.location}-main"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"

  # Disable public network access and configure firewall
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
    virtual_network_subnet_ids = [
      module.vnet.subnets["default"].id
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "Create", "List", "Delete", "Purge", "Recover", "GetRotationPolicy",
      "SetRotationPolicy", "Rotate", "Encrypt", "Decrypt", "UnwrapKey", "WrapKey"
    ]
  }

  tags = local.common_tags
}

# Create a key for storage encryption
resource "azurerm_key_vault_key" "storage_key" {
  name            = "storage-key"
  key_vault_id    = azurerm_key_vault.main.id
  key_type        = "RSA-HSM" # Use HSM-backed key
  key_size        = 2048
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  key_opts = [
    "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

data "azurerm_client_config" "current" {}

locals {
  environment = "dev"
  common_tags = {
    environment = local.environment
    managed-by  = "terraform"
    project     = "opella-challenge"
  }
  resource_group_name  = "rg-${local.environment}-${var.location}-main"
  vnet_name            = "vnet-${local.environment}-${var.location}-main"
  storage_account_name = "st${local.environment}${var.location}main${substr(md5(local.resource_group_name), 0, 8)}" # Unique name
  vm_name              = "vm-${local.environment}-${var.location}-web"
  nic_name             = "nic-${local.environment}-${var.location}-web"
  public_ip_name       = "pip-${local.environment}-${var.location}-web"
}

# Create Resource Group for Dev environment
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Deploy VNet using the module
module "vnet" {
  source = "../../modules/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = local.vnet_name
  address_space       = ["10.10.0.0/16"] # Example for Dev

  subnets = {
    "default" = { # A default subnet for general use
      address_prefixes = ["10.10.1.0/24"]
    },
    "vm-subnet" = { # Subnet for the VM
      address_prefixes = ["10.10.2.0/24"]
    }
  }

  # Security rules with restricted access
  nsg_rules = [
    {
      name                       = "AllowSSHInbound"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.0.0/8" # Restrict to specific trusted IPs
      destination_address_prefix = "*"
    }
  ]

  tags = local.common_tags
}

# Create Storage Account with enhanced security
resource "azurerm_storage_account" "main" {
  name                      = local.storage_account_name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = "GRS" # Geo-redundant storage for better replication
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  # Block public access
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  # Shared key authorization settings
  shared_access_key_enabled = false

  # Blob storage settings
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }

    # Enable change feed and versioning
    change_feed_enabled = true
    versioning_enabled  = true

    # Enable logging for all operations
    container_delete_retention_policy {
      days = 7
    }
  }

  # Queue logging
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }

  # Customer Managed Key encryption
  identity {
    type = "SystemAssigned"
  }

  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.storage_key.id
    user_assigned_identity_id = null # Using System Assigned identity
  }

  tags = local.common_tags
}

# Create Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Configure diagnostic settings for blob storage
resource "azurerm_monitor_diagnostic_setting" "blob_diagnostics" {
  name                       = "blob-diagnostics"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "StorageWrite"
    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "StorageDelete"
    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "Capacity"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "Transaction"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 7
    }
  }
}

# Create Log Analytics Workspace for diagnostics
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.environment}-${var.location}-main"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Create a private endpoint for storage account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${local.storage_account_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.vnet.subnets["default"].id

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = local.common_tags
}

# Create a private endpoint for KeyVault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${azurerm_key_vault.main.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.vnet.subnets["default"].id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = local.common_tags
}

# Network Interface for VM - Without public IP
resource "azurerm_network_interface" "main" {
  name                 = local.nic_name
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = false
  tags                 = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnets["vm-subnet"].id
    private_ip_address_allocation = "Dynamic"
    # Removed public IP association for security
  }
}

# Create Linux Virtual Machine with SSH key
resource "azurerm_linux_virtual_machine" "main" {
  name                            = local.vm_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s" # Smallest size for free tier/testing
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true # Using SSH keys instead of password

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  # No VM extensions
  allow_extension_operations = false

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = local.common_tags
}

# Outputs for the dev environment
output "dev_resource_group_name" {
  description = "Name of the development resource group."
  value       = azurerm_resource_group.main.name
}

output "dev_vm_private_ip" {
  description = "Private IP address of the development VM."
  value       = azurerm_network_interface.main.private_ip_address
}

output "dev_storage_account_name" {
  description = "Name of the development storage account."
  value       = azurerm_storage_account.main.name
}

output "dev_vnet_info" {
  description = "Information about the VNet created for dev."
  value = {
    id      = module.vnet.vnet_id
    name    = module.vnet.vnet_name
    subnets = module.vnet.subnet_ids
  }
} 