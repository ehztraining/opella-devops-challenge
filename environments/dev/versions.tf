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
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.0.2"
    }
 
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0" # Essayer cette version spécifique
    }
 
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.62.0"
    }
  }
}
 
provider "azuread" {}


provider "azurerm" {
  features {}
  use_cli = false
  
  # Pas besoin de use_oidc = true pour TFC, il utilise TFC_AZURE_PROVIDER_AUTH à la place
  # Ajoute ces valeurs dans le fichier ou utilise des variables
  # subscription_id = "ton-subscription-id"
  # tenant_id       = "ton-tenant-id"
} 