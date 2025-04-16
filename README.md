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

## Usage

*   **Pull Requests:** When a PR is opened, the GitHub Actions workflow (`.github/workflows/ci.yml`) will run `tflint` and `checkov` to validate the code.
*   **Merge to Main:** When changes are merged into the `main` branch, Terraform Cloud will automatically trigger a `plan` for the affected workspace(s).
*   **Apply:** Log in to the Terraform Cloud UI to review the plan and manually approve the `apply` (especially for `prod`).

## Tools

*   **TFLint:** Lints Terraform code for errors and best practices.
*   **Checkov:** Scans Infrastructure as Code for security misconfigurations. 