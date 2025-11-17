# Manual Terraform Deployment Guide

This guide explains how to manually deploy infrastructure resources using Terraform for both single-region and multi-region environments.

---

## Directory Structure

Select the appropriate folder for your deployment:

- **Single-region:** `templates/single-region/envs/dev/`
- **Multi-region:** `templates/multi-region/envs/dev/`

---

## Terraform Variables

For local development, each template provides a `local.tfvars.template` file with the required variables.

To configure variables for your environment:
1. Copy the template in the same directory and rename it to `local.tfvars`.
2. Edit `local.tfvars` and update the values for your environment.

These `local.tfvars` files are for manual deployments.

> **Do not commit your `local.tfvars` files.** They are for local use only and are excluded by `.gitignore`.

---

## Manual Deployment Process

| Step      | Purpose                                        | Path                      |
|-----------|------------------------------------------------|---------------------------|
| Step 00   | DevOps Setup (Manual prerequisite, always run first) | `00-devops/`              |
| Step 01   | Base Infrastructure                            | `01-base-infra/`          |
| Step 02   | Application Infrastructure (Optional)          | `02-app-resources/`       |

---

### DevOps Setup (Manual Prerequisite)

- **Purpose:**  
  - Sets up the Terraform backend and core identity.
  - Optionally creates a MongoDB Atlas Organization.
- **Preparation:**  
  - Set required environment variables (see [Setup-environment.md](Setup-environment.md)).
  - In `local.tfvars`:  
      - `should_create_mongo_org = true` — Terraform creates MongoDB Atlas Org  
      - `should_create_mongo_org = false` — Use an existing Atlas Org and set API keys as environment variables.
- **Commands:**
  ```bash
  cd 00-devops/
  terraform init
  terraform plan -var-file="local.tfvars"
  terraform apply -var-file="local.tfvars" -auto-approve
  ```
- **After deployment:**  
  1. Copy these outputs for the next steps:
      - `container_name`
      - `storage_account_name`
      - `resource_group_name`
  2. **Migrate the Terraform state to Azure:**
      - Edit `terraform.tf`:
        - Delete (or comment out) the `backend "local"` block.
        - Uncomment and update the `backend "azurerm"` block with values from the outputs above (`resource_group_name`, `storage_account_name`, `container_name`). Set the `key` as desired.
      - Run:
        ```bash
        terraform init -migrate-state
        ```
      - Delete the local `terraform.tfstate` file from this folder.

  > Migrating to remote state ensures your Terraform state is safely stored in Azure and is required before you continue.

- **If you created a new Atlas Org:**  
  * Create a service account and generate API keys.  
  * Follow the [official MongoDB Atlas documentation](https://www.mongodb.com/docs/atlas/configure-api-access-org/).  
  * Add the API keys and the service account values as environment secrets.

---

### Base Infrastructure

- **Purpose:** Provisions networking, MongoDB Atlas resources, and observability components.
- **Preparation:**  
  - In `01-base-infra/terraform.tf`, update the backend block using outputs from Step 00:
    ```hcl
    backend "azurerm" {
      resource_group_name  = "<resource_group_name_from_step_00>"
      storage_account_name = "<storage_account_name_from_step_00>"
      container_name       = "<container_name_from_step_00>"
      key                  = "01-base-infra.tfstate"
    }
    ```
  - Set all required environment variables.
- **Note:**  
  - **You must run this stage twice:**
    1. First, run with `open_access=true` to allow Key Vault creation, injection of initial secrets and to deploy the Azure Function's code.
    2. After a successful apply and secret creation, run again with `open_access=false` to restrict Key Vault and Azure Function network access for security compliance.

- **Commands:**
  ```bash
  cd 01-base-infra/
  terraform init
  terraform validate
  terraform plan -var-file="local.tfvars" -out=tfplan
  terraform apply -var-file="local.tfvars" tfplan
  ```

--- 

### Application Infrastructure (Optional)

- **Purpose:** Deploys infrastructure for the sample/test application (App Service Plan, subnet, Web App). Does **not** deploy app code.
- **Preparation:**  
  - In `02-app-resources/terraform.tf`, update the backend block using outputs from Step 00:
    ```hcl
    backend "azurerm" {
      resource_group_name  = "<resource_group_name_from_step_00>"
      storage_account_name = "<storage_account_name_from_step_00>"
      container_name       = "<container_name_from_step_00>"
      key                  = "02-application.tfstate"
    }
    ```
  - Ensure remote state references for previous steps are present in `data.tf`, if required.
  - Set all necessary environment variables.
- **Commands:**
  ```bash
  cd 02-app-resources/
  terraform init
  terraform plan -var-file="local.tfvars"
  terraform apply -var-file="local.tfvars" -auto-approve
  ```
- **For instructions on deploying app code:** See `Test_DB_connection_steps.md`.

---

## Common Scenarios

### Using an Existing Backend or Resource Groups

- **Existing Backend:**  
  - In each `terraform.tf`, configure the backend to use the existing Azure storage account/container.  
  - Do not re-create these resources via Terraform.
- **Existing Resource Groups:**  
  - Use `data` blocks to reference existing resource groups.  
  - Update variables and module inputs as necessary.

See inline comments in the Terraform files and `Setup-environment.md` for more details.

---

## Checklist

- [ ] Step 00: Run DevOps setup and copy required outputs.
- [ ] Step 01: Update backend config and deploy base infrastructure.
- [ ] Step 02: (Optional) Deploy application infrastructure.

---

## Tips

- See `Setup-environment.md` for variable setup.
- Only run the setup (Step 00) again if you intend to destroy and redeploy all resources.
- Deploy steps in sequence for reliability.
- See inline documentation in Terraform files for troubleshooting or special cases.

---