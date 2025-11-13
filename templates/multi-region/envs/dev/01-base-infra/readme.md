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

**Review Network Configuration**:

* Verify the `region_definitions` in `locals.tf` align with your network design.
* Ensure the subnet CIDR doesn't conflict with existing subnets.

**Configure Key Vault Access**:
   - On the **first run** (resource creation), set `TF_VAR_open_access = true` in your `.tfvars` file to allow public access so the Key Vault and its secrets can be created successfully.
   - After resources and secrets have been created, rerun with `TF_VAR_open_access = false` (recommended for all successive runs, including production) to restrict access to the Function App subnet only.


**Note:** For more information on How to Deploy manually, please follow [Deploy-with-manual-steps](../../../../../docs/wiki/Deploy-with-manual-steps.md).

## What This Step Deploys

This configuration creates:

* **MongoDB Atlas Cluster**: Multi-region cluster with backup enabled by default, but it can be turned off if specified.
* **Virtual Networks**: Dedicated VNets for each region.
* **Private Subnets**: 
  - Private subnet for MongoDB Atlas connectivity in each region
  - Function app subnet for observability resources (eastus only)
  - Private endpoint subnet for secure connections (eastus only)
* **VNet Peerings**: Connections between VNets across all regions for seamless communication.
* **Private Endpoints**: Secure connections to MongoDB Atlas in each region.
* **Azure Key Vault**: Secure storage for MongoDB Atlas client secret with:
  - Network ACL restrictions (configurable via `open_access` variable)
  - Private endpoint for secure access
  - Access policy for Function App managed identity
* **Observability Resources**: Provisions all infrastructure needed for centralized monitoring of MongoDB Atlas and Azure resources (deployed in eastus), including:
  - Log Analytics Workspace
  - Application Insights (with Private Link Scope)
  - Storage Account
  - Service Plan
  - Function App (with system-assigned managed identity)
  - Private DNS Zones
  - Private Endpoints
  - After resource creation, you must deploy the metrics collection function code to the Function App. This function will securely connect to the MongoDB Atlas API using credentials stored in Key Vault, collect metrics, and send them to Application Insights for monitoring and analysis.

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

- **open_access**: Controls Key Vault network access. Default is `false`.
  - On the **first run** (resource creation and initial secret injection), set to `true` to allow public access and enable the creation and population of Key Vault secrets.
  - On the **second and all successive runs**, set to `false` (recommended for production) so that Key Vault restricts access to the specified subnet (Function App subnet).
- **mongo_atlas_client_secret_expiration**: Expiration date for the MongoDB Atlas client secret stored in Key Vault, default is `2026-01-01T00:00:00Z`.

### Region Definitions

The `region_definitions` block in `locals.tf` contains configurations for multiple regions. These include:

* **atlas\_region**: Specifies the MongoDB Atlas region. Example values include `US_EAST`, `US_EAST_2`, and `US_WEST`.
* **azure\_region**: Defines the corresponding Azure region. Example values include `eastus`, `eastus2`, and `westus`.
* **priority**: Sets the priority of the region. Example values include `7`, `6`, and `5`.
* **address\_space**: Specifies the address space for the virtual network. Example values include `10.0.0.0/26`, `10.0.0.64/28`, and `10.0.0.80/28`.
* **private\_subnet\_prefixes**: Defines the prefixes for private subnets. Example values include `10.0.0.0/29`, `10.0.0.64/29`, and `10.0.0.80/29`.
* **node\_count**: Indicates the number of nodes in the region. Example values include `2`, `2`, and `1`.
* **observability\_function\_app\_subnet\_prefixes**: Defines the prefixes for private subnets for the Observability Function App, default is `10.0.0.8/29`.
* **observability\_private\_endpoint\_subnet\_prefixes**: Defines the prefixes for private subnets for Observability private endpoint, default is `10.0.0.16/28`.

> The default addresses set here are placeholders for the template. To run this template, you must provide your own IP addresses.

### Networking Settings

* **regions**: Contains Azure-specific configurations for each region, including:
  * **location**: Azure region.
  * **address\_space**: Address space for the virtual network.
  * **private\_subnet\_prefixes**: Prefixes for private subnets.
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
* **vnet\_names**: Names of the virtual networks created.
* **regions\_values**: Values of the regions configured.
* **function\_app\_default\_hostname**: Function App default hostname.
* **key_vault_id**: ID of the Azure Key Vault.
* **mongo_atlas_client_secret_uri**: URI of the MongoDB Atlas client secret in Key Vault.
