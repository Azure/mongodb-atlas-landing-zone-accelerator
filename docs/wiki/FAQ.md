# FAQ

## Table of Contents

- [General Questions](#general-questions)
- [Deployment Questions](#deployment-questions)
- [Troubleshooting](#troubleshooting)

## General Questions

### What is this repository for?

This repository provides a modular Terraform solution for deploying a secure MongoDB Atlas environment on Azure, featuring private networking, DevOps automation, and end-to-end cluster setup.

### What deployment scenarios are supported?

The repository supports both single-region and multi-region deployments.

### Is this infrastructure free to deploy?

No, deploying this infrastructure provisions paid resources such as MongoDB Atlas clusters, Azure networking components, and other Azure services. Review pricing details before running `terraform apply`.

---

## Deployment Questions

### How do I deploy the infrastructure?

You can deploy the infrastructure using the provided GitHub Actions workflows or manually with Terraform. For step-by-step deployment guidance, see the [deployment guide](./Home#Deployment-Methods).

### What are the prerequisites for deployment?

Ensure you have the required tools installed (Terraform CLI, Azure CLI) and access to an Azure subscription. See [Prerequisites.md](./Prerequisites.md) for details.

### Can I use an existing MongoDB Atlas organization?

Yes, you can use an existing Atlas organization by setting the variable `should_create_mongo_org` as `false` during Step 00 (DevOps) and in the step 01 (Infrastructure) you will add the data of the existing Organization. The default value is `true`. For more information, please refer to the [Setup environment guide](./Setup-environment.md).

---

## Troubleshooting

### What should I do if the deployment fails?

Check the Terraform output for error messages. Common issues include missing environment variables, incorrect configuration values, or insufficient permissions.

### How do I test database connectivity?

Use the provided .NET test app in `test-db-connection/test-pe-db-connection/` and follow the [Database Connection Testing Guide](./Test_DB_connection_steps.md).

### What if the connection to MongoDB Atlas times out?

Verify VNet integration is correct, check Network Security Group rules, and ensure the private endpoint is accessible from the App Service VNet.
