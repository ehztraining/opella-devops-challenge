terraform {
  required_version = ">= 1.3"

  cloud {
    organization = "opella" # Replace with your TFC organization name

    workspaces {
      name = "prod"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Credentials will be configured in Terraform Cloud (OIDC or Service Principal)
} 