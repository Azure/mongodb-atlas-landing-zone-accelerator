# Base Infrastructure - Step 1

## Overview

This Terraform configuration deploys the foundational infrastructure for MongoDB Atlas clusters and associated Azure resources in a single-region setup.

## Prerequisites

⚠️ **IMPORTANT**: You must complete the prerequisites before running this configuration.

### Required Previous Steps

1. **Environment Setup**: Ensure the environment is properly configured.

   - Verify the `locals.tf` file contains accurate values for your setup.

2. **Deploy the Terraform state from step 00**:
   - Follow the instructions on the step 00 `terraform.tf` file to migrate the Terraform state to the Azure backend

### Required Manual Configuration

Before running this step, you need to:

**Review Network Configuration**:

   - Verify the `vnet_address_space`, `private_subnet_prefixes`, `observability_function_app_subnet_prefixes`, and `observability_private_endpoint_subnet_prefixes` in `locals.tf` align with your network design.
   - Ensure the subnet CIDR doesn't conflict with existing subnets.

**Configure Key Vault Access**:
   - On the **first run** (resource creation), set `TF_VAR_open_access = true` in your `.tfvars` file to allow public access so the Key Vault and its secrets can be created successfully.
   - After resources and secrets have been created, rerun with `TF_VAR_open_access = false` (recommended for all successive runs, including production) to restrict access to the Function App subnet only.

> **Note:** For information on How to Deploy manually, please follow the steps in [Deploy with manual steps](../../../../../docs/wiki/Deploy-with-manual-steps.md) guide.

## What This Step Deploys

This configuration creates:

- **MongoDB Atlas Cluster**: Single-region cluster with backup enabled by default, but it can be turned off if specified.
- **Virtual Network**: Dedicated VNet for the cluster.
- **Private Subnets**: 
  - Private subnet for MongoDB Atlas connectivity
  - Function app subnet for observability resources
  - Private endpoint subnet for secure connections
- **Private Endpoint**: Secure connection to MongoDB Atlas.
- **Azure Key Vault**: Secure storage for MongoDB Atlas client secret with:
  - Network ACL restrictions (configurable via `open_access` variable)
  - Private endpoint for secure access
  - Access policy for Function App managed identity
- **Observability Resources**: Provisions all infrastructure needed for centralized monitoring of MongoDB Atlas and Azure resources, including:
  - Log Analytics Workspace
  - Application Insights (with Private Link Scope)
  - Storage Account
  - Service Plan
  - Function App (with system-assigned managed identity)
  - Private DNS Zones
  - Private Endpoints
  - After resource creation, you must deploy the metrics collection function code to the Function App. This function will securely connect to the MongoDB Atlas API using credentials stored in Key Vault, collect metrics, and send them to Application Insights for monitoring and analysis.
  - On the **first run** (resource creation), set `TF_VAR_open_access = true` in your `.tfvars` file to allow public access so the Azure Function code can be deployed successfully.
  - After resources have been created and code has been deployed, rerun with `TF_VAR_open_access = false` (recommended for all successive runs, including production) to restrict access to the Function App subnet only.
- **Diagnostic Settings**: Configures Azure Monitor diagnostic settings for all deployed Azure resources (Storage Accounts, Function Apps, App Service Plans, Key Vaults, Virtual Networks, and Application Insights), sending logs and metrics to the centralized Log Analytics workspace for comprehensive monitoring and troubleshooting.

## Validate

- Atlas cluster is deployed and healthy in the configured region.
- Private Endpoint is approved/connected.
- DNS resolution from inside the VNet returns a private IP for the Atlas hostname.
- Key Vault is deployed and accessible from the Function App subnet.
- Key Vault contains the MongoDB Atlas client secret.
- Function App has Key Vault access policy configured with "Get" permission.

## Post-Deployment Steps

After the infrastructure is deployed, you can proceed to Step 2 for application resources.
Follow the detailed guide: [Application Resources Guide](../02-app-resources/readme.md)

## Default Values in `locals.tf`

### General Settings

- **location**: Specifies the Azure region where resources will be deployed. Default is `eastus2`.
- **environment**: Defines the environment type, e.g., `dev`.
- **tags**: Metadata tags for resources, including `environment`, `location`, and `project`.

### MongoDB Atlas Cluster Settings

- **cluster_type**: Type of cluster, default is `REPLICASET`.
- **instance_size**: Size of the cluster instance, default is `M10`.
- **backup_enabled**: Enables backup for the cluster, default is `true`.
- **region**: MongoDB Atlas region, default is `US_EAST_2`.
- **electable_nodes**: Number of electable nodes, default is `3`.
- **priority**: Priority of the region, default is `7`.
- **reference_hour_of_day**: Hour of the day for reference, default is `3`.
- **reference_minute_of_hour**: Minute of the hour for reference, default is `45`.
- **restore_window_days**: Number of days for the restore window, default is `4`.

### Networking Settings

- **vnet_address_space**: Address space for the virtual network, default is `10.0.0.0/26`.
- **private_subnet_prefixes**: Prefixes for private subnets (MongoDB connectivity), default is `10.0.0.0/29`.
- **observability_function_app_subnet_prefixes**: Prefixes for Observability Function App subnet, default is `10.0.0.8/29`.
- **observability_private_endpoint_subnet_prefixes**: Prefixes for Observability private endpoint subnet, default is `10.0.0.16/28`.
> The default addresses set here are placeholders for the template. To run this template, you must provide your own IP addresses.

### Security Settings

- **open_access**: Controls Key Vault and Azure Function network access. Default is `false`.
  - On the **first run** (resource creation and initial secret injection), set to `true` to allow public access and enable the creation and population of Key Vault secrets.
  - On the **second and all successive runs**, set to `false` (recommended for production) so that Key Vault restricts access to the specified subnet (Function App subnet).

    In production, you should never expose this Key Vault publicly, run your deployment from a build agent that has private networking access to your workload's resources.

- **mongo_atlas_client_secret_expiration**: Expiration date for the MongoDB Atlas client secret stored in Key Vault, default is `2026-01-01T00:00:00Z`.

## Backup Configuration

The backup feature is enabled by default (`backup_enabled = true`). It ensures that the MongoDB Atlas cluster has automated backups for data protection and recovery. The following parameters are relevant:

- **reference_hour_of_day**: Specifies the hour of the day when backups are initiated.
- **reference_minute_of_hour**: Specifies the minute of the hour when backups are initiated.
- **restore_window_days**: Defines the number of days for which backups are retained and can be restored.

## Outputs

- **vnet_name**: Name of the virtual network created.
- **cluster_id**: ID of the MongoDB Atlas cluster.
- **project_name**: Name of the MongoDB Atlas project.
- **mongodb_project_id**: ID of the MongoDB Atlas project.
- **privatelink_id**: ID of the private link created for MongoDB Atlas.
- **atlas_pe_service_id**: ID of the Atlas private endpoint service.
- **atlas_privatelink_endpoint_id**: ID of the Atlas private link endpoint.
- **function_app_default_hostname**: Function App default hostname.
