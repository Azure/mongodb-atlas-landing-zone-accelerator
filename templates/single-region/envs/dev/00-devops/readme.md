# DevOps Resources - Step 0

## Overview

This step provisions foundational DevOps resources for the single-region MongoDB Atlas landing zone accelerator using Terraform. It sets up Azure storage for state management, federated identity for secure automation, and permissions for GitHub Actions integration. Optionally, it deploys a MongoDB Atlas Organization via Azure Marketplace.

## What This Configuration Creates

* **Resource Groups**: Containers for DevOps, Infrastructure, and Application resources.
* **Storage Account**: Used for storing Terraform state files, with versioning and delete retention enabled, and public access disabled.
* **Federated Identity**: Enables GitHub Actions to authenticate with Azure using OIDC.
* **Permissions**: Assigns roles such as Contributor on all resource groups and Storage Blob Data Contributor on the Storage Account.
* **Region Definition**: Defines region configuration including address spaces, subnet prefixes, and observability settings for use in subsequent steps.
* **MongoDB Atlas Organization**: Creates a new MongoDB Atlas organization via Azure Marketplace if `should_create_mongo_org` is set to `true`.

## Prerequisites

* Copy `local.tfvars.template` to `local.tfvars` and fill in all required values for your environment (organization, repository, identity, permissions, etc.).
* Set the `ARM_SUBSCRIPTION_ID` environment variable to your Azure subscription ID before running Terraform commands.

> For more information, see [Setup Environment](../../../../../docs/wiki/Setup-environment.md)

## Deployment Steps

```bash
terraform init
terraform validate
terraform plan -var-file=local.tfvars -out tfplan
terraform apply -var-file=local.tfvars tfplan
```

**Note:** For more information on How to Deploy manually, please follow [Deploy-with-manual-steps](../../../../../docs/wiki/Deploy-with-manual-steps.md).

## Validation Checklist

* `DevOps` resource group is created
* `Infrastructure` resource group is created
* `Application` resource group is created
* Storage Account is provisioned with:
  * Replication type and account tier
  * Versioning and delete retention enabled
  * Public access to nested items disabled
* Storage Container for Terraform state is created
* User Assigned Identity is created for automation
* Federated Identity Credential for GitHub Actions OIDC is created and linked to the identity
* Role assignments:
  * `Contributor` on all resource groups
  * `User Access Administrator` on all resource groups
  * `Storage Blob Data Contributor` on the Storage Account
* Region definition is configured and available in outputs

  _Note: The default addresses set here are placeholders for the template. To run this template, you must provide your own IP addresses._
* All outputs are available after apply
* MongoDB Atlas Organization is created via Azure Marketplace if enabled

## Configuration Reference

See `local.tfvars.template` for all configurable values, including:

* Azure region, resource group names, and tags
* Region definition with address spaces and subnet configurations
* Storage account and container settings
* GitHub organization and repository
* Federated identity and OIDC settings
* MongoDB Atlas organization and user details
* Marketplace offer parameters

## Outputs

* `identity_info`: Output from the DevOps module containing identity and resource details
* `resource_group_names`: Map with the names of the DevOps, Infrastructure, and Application resource groups
* `region_definition`: Region configuration including address spaces and subnet prefixes

## Permissions Granted

* `Contributor` on `DevOps` resource group
* `Contributor` on `Infrastructure` resource group
* `Contributor` on `Application` resource group
* `Storage Blob Data Contributor` on the Storage Account
* `User Access Administrator` on `DevOps` resource group
* `User Access Administrator` on `Infrastructure` resource group
* `User Access Administrator` on `Application` resource group

## Notes

* Deleting the Atlas Organization in Azure does not remove it from the Atlas portal
