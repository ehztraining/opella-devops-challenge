terraform {
  required_version = ">= 1.3"

  

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  # Credentials will be configured in Terraform Cloud (OIDC or Service Principal)
} 