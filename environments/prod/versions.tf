terraform {
  required_version = ">= 1.3"

  # Supprime ou commente ce bloc si tu utilises principalement les runs VCS de TFC
  # cloud {
  #   organization = "opella" # Replace with your TFC organization name
  #   workspaces {
  #     name = "prod"
  #   }
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  # Credentials will be configured in Terraform Cloud (OIDC or Service Principal)
}