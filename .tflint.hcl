config {
  call_module_type = "all"
  force = false
  disabled_by_default = false
}

plugin "azurerm" {
  enabled = true
  version = "0.26.0" # Use a specific version for consistency
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  preset = "recommended"
} 