# Azure Virtual Network (VNet) Terraform Module

This module provisions an Azure Virtual Network (VNet), associated subnets, and a Network Security Group (NSG) with configurable rules.

## Features

*   Creates a VNet with a specified address space.
*   Creates multiple subnets based on a map input.
*   Creates a Network Security Group (NSG).
*   Applies NSG rules (configurable, with restrictive defaults).
*   Associates the NSG with all created subnets.
*   Allows tagging of all resources.

## Usage Example

```hcl
module "vnet" {
  source = "../modules/vnet" # Adjust path as necessary

  resource_group_name = "my-resource-group"
  location            = "East US"
  vnet_name           = "my-app-vnet"
  address_space       = ["10.1.0.0/16"]

  subnets = {
    "web" = {
      address_prefixes = ["10.1.1.0/24"]
    },
    "app" = {
      address_prefixes = ["10.1.2.0/24"]
    }
  }

  # Optional: Override default NSG rules if needed
  # nsg_rules = [
  #   {
  #     name                       = "AllowSSH"
  #     priority                   = 300 
  #     direction                  = "Inbound"
  #     access                     = "Allow"
  #     protocol                   = "Tcp"
  #     source_port_range          = "*"
  #     destination_port_range     = "22"
  #     source_address_prefix      = "YOUR_IP_ADDRESS" # Restrict access
  #     destination_address_prefix = "*"
  #   },
  #   # Include other necessary rules or rely on defaults from variables.tf
  # ]

  tags = {
    environment = "development"
    project     = "my-app"
  }
}
```

## Implementation Notes

- This module follows Azure networking best practices
- NSG rules include sensible defaults for enhanced security
- Subnet design supports segregation of workloads
- All resources support tagging for governance and cost tracking

<!-- BEGIN_TF_DOCS -->
<!-- Terraform-docs content will be automatically generated here -->
<!-- END_TF_DOCS -->

## Security Considerations

- Review NSG rules carefully, especially for production use
- Consider using Azure Private Link for PaaS services
- For additional security, evaluate Azure Firewall or NVA options
- Apply least privilege principle to network access rules

## Inputs

| Name                  | Description                                                                                           | Type                                                                                                                              | Default                                          | Required |
| --------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | :------: |
| `resource_group_name` | The name of the resource group in which to create the VNet and related resources.                     | `string`                                                                                                                          | `null`                                           |   yes    |
| `location`            | The Azure region where the resources will be created.                                                 | `string`                                                                                                                          | `null`                                           |   yes    |
| `vnet_name`           | The name of the Virtual Network.                                                                      | `string`                                                                                                                          | `null`                                           |   yes    |
| `address_space`       | The address space for the Virtual Network (e.g., `["10.0.0.0/16"]`).                                     | `list(string)`                                                                                                                    | `null`                                           |   yes    |
| `subnets`             | A map of subnets to create. Key is the name, value is an object with `address_prefixes` (list).        | `map(object({ address_prefixes = list(string) }))`                                                                                | `{}`                                             |    no    |
| `nsg_rules`           | A list of network security group rules to apply. See `variables.tf` for the default restrictive ruleset. | `list(object({ name=string, priority=number, direction=string, access=string, protocol=string, ... }))`                         | (See `variables.tf` for complex default)         |    no    |
| `tags`                | A map of tags to assign to the resources.                                                             | `map(string)`                                                                                                                     | `{}`                                             |    no    |

## Outputs

| Name            | Description                                           |
| --------------- | ----------------------------------------------------- |
| `vnet_id`       | The ID of the created Virtual Network.                |
| `vnet_name`     | The name of the created Virtual Network.              |
| `vnet_location` | The location of the created Virtual Network.          |
| `subnet_ids`    | A map of subnet names to their IDs.                   |
| `subnets`       | A map of subnet names to their full subnet objects.   |
| `nsg_id`        | The ID of the created Network Security Group.         |
| `nsg_name`      | The Name of the created Network Security Group.       |

</rewritten_file> 