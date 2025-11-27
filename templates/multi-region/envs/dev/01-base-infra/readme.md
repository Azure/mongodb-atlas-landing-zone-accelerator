# Base Infrastructure - Step 1

## Overview

This Terraform configuration deploys the foundational infrastructure for MongoDB Atlas clusters and associated Azure resources in a multi-region setup.

## Prerequisites

⚠️ **IMPORTANT**: You must complete the prerequisites before running this configuration.

### Required Previous Steps

1. **Environment Setup**: Ensure the environment is properly configured.

   * Verify the `locals.tf` file contains accurate values for your setup.

### Required Manual Configuration

Before running this step, you need to:

**Configure Key Vault Access**:
   * On the **first run** (resource creation), set `TF_VAR_open_access = true` in your `.tfvars` file to allow public access so the Key Vault and its secrets can be created successfully.
   * After resources and secrets have been created, rerun with `TF_VAR_open_access = false` (recommended for all successive runs, including production) to restrict access to the Function App subnet only.

**Note:** For more information on How to Deploy manually, please follow [Deploy-with-manual-steps](../../../../../docs/wiki/Deploy-with-manual-steps.md).

## What This Step Deploys

This configuration creates:

* **MongoDB Atlas Cluster**: Multi-region cluster with backup enabled by default, but it can be turned off if specified.
* **Virtual Networks**: Dedicated VNets for each configured region.
* **App Workload Subnets**: 
  * App workload subnet for MongoDB Atlas connectivity in each region
  * Function app subnet for observability resources (primary region only)
  * A single shared Private Endpoint subnet for all Azure Private Endpoints (Monitoring, Key Vault, Observability, etc.) (primary region only)
* **VNet Peerings**: Connections between VNets across all regions for seamless communication.
* **Private Endpoints**: Secure connections to MongoDB Atlas in each region.
* **Monitoring Resources** (per region):
  * Log Analytics Workspace
  * Application Insights (primary region only)
  * Azure Monitor Private Link Scope - AMPLS (primary region only)
  * Private DNS Zones (created in primary region, linked to all regions)
* **Azure Key Vault** (primary region): Secure storage for MongoDB Atlas client secret with:
  * Network ACL restrictions (configurable via `open_access` variable)
  * Private endpoint for secure access (deployed into the shared Private Endpoint subnet)
  * Access policy for Function App managed identity
* **Observability Resources** (primary region): Provisions infrastructure for centralized monitoring, including:
  * Storage Account
  * Service Plan
  * Function App (with system-assigned managed identity)
  * Private DNS Zones
  * Private Endpoints (all deployed into the shared Private Endpoint subnet)
  * After resource creation, you must deploy the metrics collection function code to the Function App. This function will securely connect to the MongoDB Atlas API using credentials stored in Key Vault, collect metrics, and send them to Application Insights for monitoring and analysis.
  * On the **first run** (resource creation), set `TF_VAR_open_access = true` in your `.tfvars` file to allow public access so the Azure Function code can be deployed successfully.
  * After resources have been created and code has been deployed, rerun with `TF_VAR_open_access = false` (recommended for all successive runs, including production) to restrict access to the Function App subnet only.
* **Diagnostic Settings**: Configures Azure Monitor diagnostic settings for all deployed Azure resources across all regions (Storage Accounts, Function Apps, App Service Plans, Key Vaults, Virtual Networks, and Application Insights), sending logs and metrics to the centralized Log Analytics workspace for comprehensive monitoring and troubleshooting.

## Validate

* MongoDB Atlas cluster is deployed and healthy across all configured regions.
* Private Endpoints are approved and in a connected state in all regions.
* DNS resolution from within the VNet returns a private IP for the Atlas FQDN.
* VNet peerings are successfully established between all regions.
* Key Vault is deployed and accessible from the Function App subnet (eastus).
* Key Vault contains the MongoDB Atlas client secret.
* Function App has Key Vault access policy configured with "Get" permission.

## Next Steps

After the infrastructure is deployed, you can proceed to Step 2 for application resources.
Follow the detailed guide: [Application Resources Guide](../02-app-resources/readme.md)

## Default Values in `locals.tf`

### General Settings

* **location**: Specifies the Azure region where resources will be deployed. Default is `eastus2`.
* **environment**: Defines the environment type, e.g., `dev`.
* **tags**: Metadata tags for resources, including `environment` and `project`.

### MongoDB Atlas Cluster Settings

* **cluster\_type**: Type of cluster, default is `REPLICASET`.
* **instance\_size**: Size of the cluster instance, default is `M10`.
* **backup\_enabled**: Enables backup for the cluster, default is `true`.
* **reference\_hour\_of\_day**: Hour of the day for reference, default is `3`.
* **reference\_minute\_of\_hour**: Minute of the hour for reference, default is `45`.
* **restore\_window\_days**: Number of days for the restore window, default is `4`.

### Security Settings

- **open_access**: Controls Key Vault and Azure Function network access. Default is `false`.
  - On the **first run** (resource creation and initial secret injection), set to `true` to allow public access and enable the creation and population of Key Vault secrets and Azure Function's code deployment.
  - On the **second and all successive runs**, set to `false` (recommended for production) so that Key Vault and the Azure Function restricts access to the specified subnet (Function App subnet).
      
    In production, you should never expose this Key Vault publicly, run your deployment from a build agent that has private networking access to your workload's resources.

- **mongo_atlas_client_secret_expiration**: Expiration date for the MongoDB Atlas client secret stored in Key Vault, default is `2026-01-01T00:00:00Z`.

### Region Definitions

Region definitions are configured in Step 0 (`00-devops/locals.tf`) and passed to this step via remote state. Each region includes:

* **atlas\_region**: MongoDB Atlas region identifier
* **azure\_region**: Corresponding Azure region
* **priority**: Region priority for Atlas cluster
* **address\_space**: Virtual network address space
* **app_workload_subnet_prefixes**: Prefixes for the application workload subnet (MongoDB connectivity)
* **private\_endpoints\_subnet\_prefixes**: CIDR ranges for the shared Private Endpoint subnet used by all Azure PEs (Monitoring, Key Vault, Observability, etc.)
* **observability\_function\_app\_subnet\_prefixes** (primary region only): Subnet for the Observability Function App
* **node\_count**: Number of Atlas nodes in the region
* **deploy\_observability\_subnets**: Whether to deploy the shared Private Endpoint subnet for observability-related resources (e.g., Monitoring, Key Vault, Observability, etc.)
* **has\_keyvault\_private\_endpoint**: Whether to deploy the shared Private Endpoint subnet for Key Vault private endpoint.
* **has\_observability\_storage\_account**: Whether to deploy the shared Private Endpoint subnet for observability storage account.

### Networking Settings

* **regions**: Contains Azure-specific configurations for each region, including:
  * **location**: Azure region.
  * **address\_space**: Address space for the virtual network.
  * **app_workload_subnet_prefixes**: Prefixes for the application workload subnet (MongoDB connectivity)
  * **manual\_connection**: Indicates whether manual connection is required.
  * **observability\_function\_app\_subnet\_prefixes**: Prefixes fot Observability Function App.
  * **observability\_private\_endpoint\_subnet\_prefixes**: Prefixes for Observability private endpoint subnet.

## Backup Configuration

The backup feature is enabled by default (`backup_enabled = true`). It ensures that the MongoDB Atlas cluster has automated backups for data protection and recovery. The following parameters are relevant:

* **reference\_hour\_of\_day**: Specifies the hour of the day when backups are initiated.
* **reference\_minute\_of\_hour**: Specifies the minute of the hour when backups are initiated.
* **restore\_window\_days**: Defines the number of days for which backups are retained and can be restored.

### Outputs

* **cluster\_id**: ID of the MongoDB Atlas cluster.
* **project\_name**: Name of the MongoDB Atlas project.
* **mongodb\_project\_id**: ID of the MongoDB Atlas project.
* **privatelink\_ids**: IDs of the private links created for MongoDB Atlas.
* **atlas\_pe\_service\_ids**: IDs of the Atlas private endpoint services.
* **atlas\_privatelink\_endpoint\_ids**: IDs of the Atlas private link endpoints.
* **vnets**: Name and resource group of the virtual networks created.
* **regions\_values**: Values of the regions configured.
* **function\_app\_default\_hostname**: Function App default hostname.
