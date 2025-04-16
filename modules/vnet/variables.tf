variable "resource_group_name" {
  description = "The name of the resource group in which to create the VNet and related resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
}

variable "address_space" {
  description = "The address space for the Virtual Network (e.g., ['10.0.0.0/16'])."
  type        = list(string)
}

variable "subnets" {
  description = "A map of subnets to create within the VNet. Key is the subnet name, value is an object with address_prefixes (list of strings)."
  type = map(object({
    address_prefixes = list(string)
    # Potentially add service endpoints or delegations here later
  }))
  default = {}
}

variable "nsg_rules" {
  description = "A list of network security group rules to apply. Defaults to a restrictive rule set."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    # Allow VNet internal traffic
    {
      name                       = "AllowVnetInBound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowVnetOutBound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    # Allow Azure Load Balancer health probes
    {
      name                       = "AllowAzureLoadBalancerInBound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    # Deny all other inbound traffic from Internet by default
    {
      name                       = "DenyInternetInbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    # Allow all outbound by default (can be restricted further if needed)
    {
      name                       = "AllowInternetOutbound"
      priority                   = 4000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  ]
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
} 