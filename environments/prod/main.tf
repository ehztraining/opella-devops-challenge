# Define variables that will be set in Terraform Cloud Workspace
variable "location" {
  description = "Azure region for the production environment."
  type        = string
  default     = "westeurope" # Default for prod, can be overridden in TFC
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

# Example Prod-specific variable (could be VM size, etc.)
variable "vm_size" {
  description = "Size of the production VM."
  type        = string
  default     = "Standard_B2s" # Larger than dev
}

locals {
  environment = "prod"
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

# Create Resource Group for Prod environment
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
  address_space       = ["10.20.0.0/16"] # Different CIDR for Prod

  subnets = {
    "default" = { # A default subnet for general use
      address_prefixes = ["10.20.1.0/24"]
    },
    "vm-subnet" = { # Subnet for the VM
      address_prefixes = ["10.20.2.0/24"]
    }
  }

  # Production NSG Rules: Restrictive by default
  nsg_rules = [
    {
      name                       = "DenyAllInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowVNetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
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
      days = 30 # Higher retention for production
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  # Queue logging
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 30
    }
  }

  tags = local.common_tags
}

# Create Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
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
    # No public IP for prod
  }
}

# Create Linux Virtual Machine with SSH key
resource "azurerm_linux_virtual_machine" "main" {
  name                            = local.vm_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size # Use prod-specific size
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

# Outputs for the prod environment
output "prod_resource_group_name" {
  description = "Name of the production resource group."
  value       = azurerm_resource_group.main.name
}

output "prod_vm_private_ip" {
  description = "Private IP address of the production VM."
  value       = azurerm_network_interface.main.private_ip_address
}

output "prod_storage_account_name" {
  description = "Name of the production storage account."
  value       = azurerm_storage_account.main.name
}

output "prod_vnet_info" {
  description = "Information about the VNet created for prod."
  value = {
    id      = module.vnet.vnet_id
    name    = module.vnet.vnet_name
    subnets = module.vnet.subnet_ids
  }
} 