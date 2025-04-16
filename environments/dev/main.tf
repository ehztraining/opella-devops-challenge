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

locals {
  environment = "dev"
  common_tags = {
    environment = local.environment
    managed-by  = "terraform"
    project     = "opella-challenge"
  }
  resource_group_name = "rg-${local.environment}-${var.location}-main"
  vnet_name           = "vnet-${local.environment}-${var.location}-main"
  storage_account_name = "st${local.environment}${var.location}main${substr(md5(local.resource_group_name), 0, 8)}" # Unique name
  vm_name             = "vm-${local.environment}-${var.location}-web"
  nic_name            = "nic-${local.environment}-${var.location}-web"
  public_ip_name      = "pip-${local.environment}-${var.location}-web"
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

  # Example: Add a rule to allow SSH from anywhere (Consider restricting source_address_prefix in production)
  nsg_rules = [
    {
      name                       = "AllowSSHInbound"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*" # WARNING: Open to the internet, restrict in real scenarios
      destination_address_prefix = "*"
    }
    # Append default rules by merging with the default set (or redefine all if needed)
    # Note: Merging complex lists/objects can be tricky, often better to define the full set here if overriding significantly.
    # For simplicity here, we just add SSH on top of potentially existing default rules (TFC variable override might be cleaner)
  ]

  tags = local.common_tags
}

# Create Storage Account
resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

# Create Storage Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Create Public IP for VM
resource "azurerm_public_ip" "main" {
  name                = local.public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static" # Or Dynamic
  sku                 = "Standard" # Required for Standard Load Balancer or Availability Zones
  tags                = local.common_tags
}

# Create Network Interface for VM
resource "azurerm_network_interface" "main" {
  name                = local.nic_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnets["vm-subnet"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Create Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = local.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s" # Smallest size for free tier/testing
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  disable_password_authentication = false # Set to true if using SSH keys

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

output "dev_vm_public_ip" {
  description = "Public IP address of the development VM."
  value       = azurerm_public_ip.main.ip_address
}

output "dev_storage_account_name" {
  description = "Name of the development storage account."
  value       = azurerm_storage_account.main.name
}

output "dev_vnet_info" {
  description = "Information about the VNet created for dev."
  value = {
    id = module.vnet.vnet_id
    name = module.vnet.vnet_name
    subnets = module.vnet.subnet_ids
  }
} 