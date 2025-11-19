# Devops Module

## Overview

This module creates the Azure resources required to store the Terraform remote state and supports federated identity and role assignments for secure automation. It also creates resource groups for infrastructure and application resources, supporting both single-region and multi-region deployments. The creation of application resource groups is optional since they are used to test the connection with the deployed cluster.

## Features

- Creates Azure Resource Group for DevOps (step 00)
- Creates Infrastructure resource groups (step 01) - supports single or multiple regions
- Creates Application resource groups (optional, step 02) - supports single or multiple regions
- Provisions Azure Storage Account and Blob Storage Container
- Configures Azure User Assigned Identity for automation
- Sets up Federated Identity Credential and Role Assignments
- Assigns Contributor and User Access Administrator roles to the identity on DevOps, Infrastructure, and Application resource groups
- Assigns Storage Blob Data Contributor role to the identity on the Storage Account

## Usage

```hcl
module "devops" {
  source = "./modules/devops"

  resource_group_name_devops = "rg-devops"
  resource_groups_infrastructure = {
    zoneA = {
      name     = "rg-infra-zoneA"
      location = "centralus"
    }
    zoneB = {
      name     = "rg-infra-zoneB"
      location = "northcentralus"
    }
    zoneC = {
      name     = "rg-infra-zoneC"
      location = "westcentralus"
    }
  }
  resource_groups_app = {
    zoneA = {
      name     = "rg-app-zoneA"
      location = "centralus"
    }
    zoneB = {
      name     = "rg-app-zoneB"
      location = "northcentralus"
    }
    zoneC = {
      name     = "rg-app-zoneC"
      location = "westcentralus"
    }
  }
  location             = "centralus"
  storage_account_name = "stdevops"
  account_tier         = "Standard"
  replication_type     = "ZRS"
  container_name       = "tfstate"
  container_access_type = "private"

  tags = {
    Environment = "dev"
    Project     = "devops"
  }

  audiences = ["audience1", "audience2"]
  issuer    = "https://issuer.example.com"

  federation = {
    setting1 = "value1"
    setting2 = "value2"
  }
}
```

## Inputs

| Name                               | Description                                                                                      | Type                                      | Default | Required |
| ---------------------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------- | ------- | -------- |
| `resource_group_name_devops`       | Name of the DevOps resource group                                                                | `string`                                  | -       | yes      |
| `resource_groups_infrastructure`   | Map of infrastructure resource groups with their locations (key is region identifier)            | `map(object({name=string, location=string}))` | `{}`    | no       |
| `resource_groups_app`              | Map of application resource groups with their locations (key is region identifier)               | `map(object({name=string, location=string}))` | `{}`    | no       |
| `location`                         | Location for the DevOps resources (storage account, identity)                                    | `string`                                  | -       | yes      |
| `storage_account_name`             | Name of the storage account                                                                      | `string`                                  | -       | yes      |
| `account_tier`                     | Storage account tier (e.g., Standard)                                                            | `string`                                  | `"Standard"` | no  |
| `replication_type`                 | Replication type (e.g., LRS, ZRS)                                                                | `string`                                  | `"LRS"` | no       |
| `container_name`                   | Name of the blob container for Terraform state                                                   | `string`                                  | -       | yes      |
| `container_access_type`            | Access type for the container                                                                    | `string`                                  | `"private"` | no   |
| `tags`                             | Tags to apply to all resources                                                                   | `map(string)`                             | -       | yes      |
| `audiences`                        | List of audiences for federated identity                                                         | `list(string)`                            | -       | yes      |
| `issuer`                           | Issuer for federated identity                                                                    | `string`                                  | -       | yes      |
| `federation`                       | Map of federation settings (federated_identity_name, subject)                                    | `map(string)`                             | -       | yes      |

## Outputs

| Name                    | Description                                                                                           |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| `identity_info`         | Object containing tenant ID, subscription ID, client ID, resource group IDs (DevOps, Infrastructure per region, Application per region), storage account name and ID, and container name for automation |
| `resource_group_names`  | Object containing the names of the DevOps resource group and maps of Infrastructure and Application resource group names by region |