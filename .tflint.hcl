config {
  module = true
  force = false
  disabled_by_default = false
}

plugin "azurerm" {
  enabled = true
  version = "0.26.0" # Use a specific version for consistency
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

ruleset {
  name    = "recommended"
  version = "0.2.0" # Example version, check for latest
  source  = "github.com/terraform-linters/tflint-ruleset-recommended"
} 