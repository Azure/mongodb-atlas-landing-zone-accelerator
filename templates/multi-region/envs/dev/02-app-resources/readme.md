# Application Resources - Step 2

## Overview

This Terraform configuration deploys Azure application resources including App Service Plan, Web Apps, and networking components for hosting the test db connection App with VNet integration.

Since it is Multi-Region, this step is able to deploy the Azure resources in the different regions you specify to test the connection to the Database in the Clusters deployed in the step #1.

## Prerequisites

⚠️ **IMPORTANT**: You must run the **Step 1** using the pipeline before running this configuration. (You can also run the steps manually, but we recommend using the pipeline as it is simpler)

### Required Previous Steps

1. **Base Infrastructure (Step 1)**: The `01-base-infra` step must be successfully deployed first.

   * This creates the foundational resources including Virtual Networks in each specified region, and other base infrastructure.
   * The remote state from Step 1 is required for this configuration to work properly.

### Required Manual Configuration

For information on How to Deploy manually, please follow [Deploy-with-manual-steps](../../../../../docs/wiki/Deploy-with-manual-steps.md).

## What This Step Deploys

This configuration creates the following for each specified region:

* **App Service Plan**: B1 SKU with Windows OS (required for VNet integration).
* **Application Subnet**: Dedicated subnet for App Service VNet integration.
* **Azure Web App**: Azure Web App resource with .NET 8.0 runtime.

## Validate

* App Service Plans deployed with correct SKU and OS.
* Application subnets created and delegated for VNet integration.
* Web Apps reachable and able to connect to Atlas via Private Endpoint.

## Usage

1. **Ensure Prerequisites**: Verify Step 1 is completed and remote state is accessible.
2. **Configure Locals**: Update `locals.tf` with your specific values.
3. **Use the pipeline to deploy this step**.

## Post-Deployment Steps

After the infrastructure is deployed, to utilize the test database connection app, you need to deploy the code.
Follow the detailed guide: [Database Connection Testing Guide](../../../../../docs/wiki/Test_DB_connection_steps.md).

## Default Values in `locals.tf`

### General Settings

* **environment**: Defines the environment type, e.g., `dev`. Default is set to `dev`.

### Application Settings

* **app\_information\_by\_region**: Contains application-specific configurations for each region, including:
  * **resource\_group\_name**: Generated in step `00-devops`.
  * **location**: Generated in step `00-devops`.
  * **app\_service\_plan\_name**: Generated dynamically with Azure Naming Module.
  * **app\_service\_plan\_sku**: Default is set to `B1`.
  * **app\_web\_app\_name**: Generated dynamically with Azure Naming Module.
  * **virtual\_network\_name**: Generated in step `01-base-infra`.
  * **subnet\_name**: Generated dynamically with Azure Naming Module.
  * **address\_prefixes**: Generated in step `00-devops`.

### Tags

* **tags**: Metadata tags for resources, including `environment`. Default includes `environment` set to `dev`.
