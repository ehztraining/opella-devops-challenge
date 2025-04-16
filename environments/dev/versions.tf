terraform {
  required_version = ">= 1.3"

  # Supprime ou commente ce bloc si tu utilises principalement les runs VCS de TFC
  # cloud {
  #   organization = "opella" # Replace with your TFC organization name
  #   workspaces {
  #     name = "dev" # Assure-toi que ce nom correspond si tu utilises les runs CLI
  #   }
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0" # Essayer cette version spécifique
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
  # Credentials will be configured in Terraform Cloud (OIDC or Service Principal)
} 