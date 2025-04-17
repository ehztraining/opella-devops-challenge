# Opella DevOps Technical Challenge - Azure Infrastructure with Terraform

This repository contains Terraform code to provision Azure infrastructure for the Opella DevOps technical challenge.

## Objective

Deploy Azure infrastructure using reusable Terraform modules, Terraform Cloud workspaces, and GitHub Actions for CI/CD, focusing on:

*   **Reusability:** Using a dedicated module for VNet creation.
*   **Environments:** Managing `dev` and `prod` environments via Terraform Cloud.
*   **Automation:** Using GitHub Actions for linting and security scanning before Terraform Cloud takes over for planning and applying.
*   **Security:** Implementing basic network security and leveraging tools like `checkov`.
*   **Maintainability:** Enforcing code quality with `tflint`.

## Structure

```
.
├── .github/workflows/         # GitHub Actions workflows (CI)
│   └── ci.yml
├── environments/
│   ├── common/                # Optional: Common configuration (e.g., providers)
│   ├── dev/                   # Development environment configuration
│   │   ├── main.tf
│   │   └── versions.tf
│   └── prod/                  # Production environment configuration
│       ├── main.tf
│       └── versions.tf
├── modules/
│   └── vnet/                  # Reusable VNet module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── .gitignore
├── .tflint.hcl              # TFLint configuration
└── README.md                # This file
```

## Prerequisites

*   Azure Account and Subscription
*   Terraform Cloud Account and Organization
*   GitHub Account
*   Azure CLI (optional, for authentication or local testing)
*   Terraform CLI (optional, for local testing)
*   TFLint (optional, for local testing)
*   Checkov (optional, for local testing)

## Setup

1.  **Fork/Clone this repository.**
2.  **Configure Terraform Cloud:**
    *   Create an organization.
    *   Create two workspaces: `dev` and `prod`.
    *   Link each workspace to this GitHub repository.
    *   Set the "Terraform Working Directory" for the `dev` workspace to `environments/dev`.
    *   Set the "Terraform Working Directory" for the `prod` workspace to `environments/prod`.
    *   Configure Azure credentials (OIDC recommended or Service Principal) as environment variables within each TFC workspace.
3.  **Configure GitHub Actions (if using OIDC):**
    *   Set up the OIDC trust relationship between GitHub Actions and Azure AD.

## OIDC Authentication with Azure and Terraform Cloud

This project uses OpenID Connect (OIDC) federation between Terraform Cloud and Azure, which eliminates the need for long-lived credentials by generating short-lived tokens for each run.

### Benefits of OIDC Authentication

- **Enhanced Security**: No long-lived secrets stored in Terraform Cloud
- **Reduced Risk**: Temporary credentials expire after each run
- **Simplified Rotation**: No need to regularly rotate service principal secrets
- **Auditability**: Better tracking of which run accessed Azure resources

### Configuration Steps

#### 1. Azure Configuration

1. **Create an App Registration in Azure AD**:
   - Navigate to Azure Portal > Azure Active Directory > App Registrations
   - Create a new registration for Terraform Cloud authentication

2. **Create Federated Identity Credentials**:
   - In your App Registration, go to "Certificates & secrets" > "Federated credentials"
   - Create four separate credentials to support plan and apply operations for both environments:

   | Name | Issuer | Audience | Subject |
   |------|--------|----------|---------|
   | TFC-dev-plan | https://app.terraform.io | api://AzureADTokenExchange | organization:opella:project:Default Project:workspace:dev-opella:run_phase:plan |
   | TFC-dev-apply | https://app.terraform.io | api://AzureADTokenExchange | organization:opella:project:Default Project:workspace:dev-opella:run_phase:apply |
   | TFC-prod-plan | https://app.terraform.io | api://AzureADTokenExchange | organization:opella:project:Default Project:workspace:prod-opella:run_phase:plan |
   | TFC-prod-apply | https://app.terraform.io | api://AzureADTokenExchange | organization:opella:project:Default Project:workspace:prod-opella:run_phase:apply |

3. **Assign RBAC Permissions**:
   - Grant the App Registration appropriate RBAC roles (e.g., Contributor) on your subscription or resource groups

#### 2. Terraform Cloud Configuration

For each workspace (`dev-opella` and `prod-opella`), configure these variables:

1. **Terraform Variables** (sensitive):
   - `ARM_SUBSCRIPTION_ID`: Your Azure Subscription ID
   - `ARM_TENANT_ID`: Your Azure Tenant ID
   - `ARM_CLIENT_ID`: Your App Registration Client ID

2. **Environment Variables**:
   - `TFC_AZURE_PROVIDER_AUTH`: Set to `true`
   - `TFC_AZURE_RUN_CLIENT_ID`: Your App Registration Client ID (sensitive)

#### 3. Terraform Configuration

The `provider` blocks in each environment's `versions.tf` are configured to use the OIDC authentication method:

```terraform
provider "azurerm" {
  features {}
  use_cli = false
  
  # Using ARM_SUBSCRIPTION_ID variable defined in TFC
  subscription_id = var.ARM_SUBSCRIPTION_ID
}
```

The required variables are declared in `variables.tf`:

```terraform
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
```

### Troubleshooting OIDC

If you encounter authentication issues:

1. Verify the exact format of subject strings in Azure federated credentials
2. Ensure all required variables are set in Terraform Cloud
3. Check that the App Registration has appropriate Azure RBAC permissions
4. Examine Terraform Cloud run logs for specific authentication errors

## Usage

*   **Pull Requests:** When a PR is opened, the GitHub Actions workflow (`.github/workflows/ci.yml`) will run `tflint` and `checkov` to validate the code.
*   **Merge to Main:** When changes are merged into the `main` branch, Terraform Cloud will automatically trigger a `plan` for the affected workspace(s).
*   **Apply:** Log in to the Terraform Cloud UI to review the plan and manually approve the `apply` (especially for `prod`).

## Tools

*   **TFLint:** Lints Terraform code for errors and best practices.
*   **Checkov:** Scans Infrastructure as Code for security misconfigurations. 