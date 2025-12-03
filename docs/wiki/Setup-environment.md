# Environment Setup

This document describes the required environment variables, prerequisites, and setup steps for running Terraform and automation pipelines.

---

## Table of Contents

- [Variable Overview](#variable-overview)
- [Setting Environment Variables Locally](#setting-environment-variables-locally)
- [Pipeline / CI Setup](#pipeline--ci-setup)
- [Terraform version](#terraform-version)
- [Additional Notes](#additional-notes)

---

## Variable Overview

| Variable                        | When to Set                                      | Purpose                                       |
|----------------------------------|--------------------------------------------------|-----------------------------------------------|
| `ARM_SUBSCRIPTION_ID`            | Before any step (including step 00-devops)        | Azure subscription for all resources          |
| `MONGODB_ATLAS_PUBLIC_API_KEY`   | After creating Atlas org (after step 00-devops)   | MongoDB Atlas API access (from step 01 onward)|
| `MONGODB_ATLAS_PRIVATE_API_KEY`  | After creating Atlas org (after step 00-devops)   | MongoDB Atlas API access (from step 01 onward)|

---

## Setting Environment Variables Locally

Set the required variables in your terminal session before running Terraform or automation scripts.

### macOS/Linux or Bash on Windows

```bash
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
# After step 00-devops:
export MONGODB_ATLAS_PUBLIC_API_KEY="<ATLAS_PUBLIC_KEY>"
export MONGODB_ATLAS_PRIVATE_API_KEY="<ATLAS_PRIVATE_KEY>"
```

### Windows (Command Prompt)

```bat
set ARM_SUBSCRIPTION_ID=<your-subscription-id>
:: After step 00-devops:
set MONGODB_ATLAS_PUBLIC_API_KEY=<ATLAS_PUBLIC_KEY>
set MONGODB_ATLAS_PRIVATE_API_KEY=<ATLAS_PRIVATE_KEY>
```

### Windows (PowerShell)

```powershell
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
# After step 00-devops:
$env:MONGODB_ATLAS_PUBLIC_API_KEY = "<ATLAS_PUBLIC_KEY>"
$env:MONGODB_ATLAS_PRIVATE_API_KEY = "<ATLAS_PRIVATE_KEY>"
```

## Terraform variables

For local development, each template provides a `local.tfvars.template` file with the required variables.
To configure variables for your environment:

1. Copy the template in the same directory and rename it to `local.tfvars`.
2. Edit `local.tfvars` and update the values to match your environment.

These `local.tfvars` files will be used when deploying with manual steps.

> Do not commit your `local.tfvars` files. They are intended for local use only and are excluded via `.gitignore`.

---

## Pipeline / CI Setup

### GitHub Environment Requirements

Before running the pipeline, you must create a GitHub environment named `dev` in your repository settings.
Follow the official [Creating a GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) guide for detailed instructions.

---

**Environment Configuration**

In the `dev` environment, set the following secrets and variables:

---

#### **Secrets**

| Name                          | Description                                                                                                             |
|-------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `MONGODB_ATLAS_PUBLIC_API_KEY`    | MongoDB Atlas public API key. See [MongoDB API Access documentation](https://www.mongodb.com/docs/atlas/configure-api-access-org/) for instructions. |
| `MONGODB_ATLAS_PRIVATE_API_KEY`   | MongoDB Atlas private API key. See [MongoDB API Access documentation](https://www.mongodb.com/docs/atlas/configure-api-access-org/) for instructions. |
| `TF_VAR_mongo_atlas_client_id`    | MongoDB Atlas client ID. [See deployment guide](./MongoAtlasMetrics_deployment_steps.md) to generate this.           |
| `TF_VAR_mongo_atlas_client_secret`| MongoDB Atlas client secret. [See deployment guide](./MongoAtlasMetrics_deployment_steps.md) to generate this.        |
| `TF_VAR_org_id`                   | MongoDB Atlas organization ID.                                                                                      |

---

#### **Variables**

| Name                                  | Description                                                                               | Sample Value                                         |
|----------------------------------------|-------------------------------------------------------------------------------------------|------------------------------------------------------|
| `ARM_CLIENT_ID`                        | Managed identity client ID.                                                               | `00000000-0000-0000-0000-000000000000`              |
| `ARM_SUBSCRIPTION_ID`                  | Azure subscription ID where resources will be created.                                    | `00000000-0000-0000-0000-000000000000`              |
| `ARM_TENANT_ID`                        | Azure tenant ID for your subscription.                                                    | `00000000-0000-0000-0000-000000000000`              |
| `TF_VAR_project_name`                  | MongoDB Atlas project name.                                                               | `atlas-dev-proj`                                     |
| `TF_VAR_cluster_name`                  | MongoDB Atlas cluster name.                                                               | `atlas-dev-cluster`                                  |
| `TF_VAR_resource_group_name_tfstate`   | Name of the Azure Resource Group storing the Terraform state.                             | `rg-devops`                                          |
| `TF_VAR_storage_account_name_tfstate`  | Name of the Azure Storage Account for Terraform state.                                    | `sttfdev147`                                         |
| `TF_VAR_container_name_tfstate`        | Name of the Storage Account container for Terraform state.                                | `tfstate`                                            |
| `TF_VAR_key_name_tfstate`              | Key (filename) of the Terraform state for the DevOps deployment.                          | `devops.tfstate`                                     |
| `FUNCTIONAPP_RG_NAME`                  | Name of the Resource Group created for infrastructure resources where the Function app is deployed. For Multi Region, by default is the Zone A resource group.                          | `rg-infra`                                           |
| `TF_VAR_open_access`                   | Boolean flag to control open (true) or restricted (false) Key Vault and Azure Function network access.       | `true` or `false`                                    |

---

#### *Optional Variables (for Test DB Connection App)*

*These variables are only required if deploying the test database connection application.
They must be configured **after running the Application pipeline step**, when app(s) are created and their names known.*

| Name                          | Description                                                           | Sample Value                       |
|-------------------------------|-----------------------------------------------------------------------|------------------------------------|
| `TF_VAR_key_name_infra_tfstate` | Key (filename) of the Terraform state for infrastructure resources. | `01-base-infra.tfstate`                      |
| `APP_WEBAPPS`                   | Comma-separated list of Web App names. Single for single-region; multiple for multi-region. | `app-application` (single) or `app-application-zoneA,app-application-zoneB, app-application-zoneC` (multi) |
| `APP_WEBAPPS_RG_NAMES`          | Comma-separated list of Web App Resource Group names for the application step resources.            | `rg-app-application` (single) or `rg-app-application-zoneA,rg-app-application-zoneB, rg-app-application-zoneC` (multi) |
| `FUNCTION_APP_NAME`             | Name of the Azure Function App created in the infra step (step 1). | `func-infrasingregion`         |
- **Important:**
  - You will find the org id in the organization's settings as shown below:
  ![org_id](../images/org_id.png)

---

## Terraform version

Terraform version is pinned in `.terraform-version`:

- Local: install [`tfenv`](https://github.com/tfutils/tfenv) or [`asdf`](https://asdf-vm.com/) for automatic switching.
- Pipelines: read `.terraform-version` dynamically.

To upgrade:

1. Update `.terraform-version`
2. Update `terraform.tf` _required_version_ for modules and templates
3. Pipelines and local envs will automatically use the new version.

---

## Additional Notes

- Each environment (`dev`, `test`, `prod`, etc.) should have its own folder under `envs/` inside the respective single-region or multi-region folder.
- Never hardcode sensitive values (such as API keys or subscription IDs) directly in code or version control.

---
