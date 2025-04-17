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
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
    
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.40.0"
    }
  }
}

provider "azuread" {
  # Utilisation des identifiants disponibles dans l'environnement
}

provider "azurerm" {
  features {}
  use_cli = false
  
  # Récupération des valeurs depuis les variables existantes dans TFC
  # (à adapter si tu as déjà configuré des variables différentes)
  subscription_id = var.ARM_SUBSCRIPTION_ID
}

provider "tfe" {
  # Utilise les identifiants d'environnement ou token disponible
  organization = "opella"
}