# Variables pour l'authentification Azure
variable "ARM_SUBSCRIPTION_ID" {
  description = "L'ID de l'abonnement Azure"
  type        = string
  sensitive   = true
}

variable "ARM_TENANT_ID" {
  description = "L'ID du tenant Azure"
  type        = string
  sensitive   = true
}

variable "ARM_CLIENT_ID" {
  description = "L'ID client de l'application Azure AD"
  type        = string
  sensitive   = true
} 