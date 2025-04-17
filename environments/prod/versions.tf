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
  use_cli = false
  
  # Pas besoin de use_oidc = true pour TFC, il utilise TFC_AZURE_PROVIDER_AUTH à la place
  # Ajoute ces valeurs dans le fichier ou utilise des variables
  # subscription_id = "ton-subscription-id"
  # tenant_id       = "ton-tenant-id"
}