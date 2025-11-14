# Terraform Landing Zone for MongoDB Atlas on Azure

## Solution Overview

This repository provides a modular Terraform solution for deploying a secure MongoDB Atlas environment on Azure, featuring:

- Private networking and secure connectivity
- DevOps automation for remote state and identity
- End-to-end cluster setup for MongoDB Atlas
- Observability and monitoring with Azure Application Insights and a Metrics Function App
- Automated infrastructure provisioning, Atlas cluster configuration, and a test application for validation

> [!IMPORTANT]
> The Terraform Landing Zone for MongoDB Atlas on Azure assumes that you already successfully implemented an Azure landing zone. However, you can use the Terraform Landing Zone for MongoDB Atlas on Azure if your infrastructure doesn't conform to Azure landing zones. For more information, refer to [Cloud Adoption Framework enterprise-scale landing zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/)
>
> We recommend evaluating whether additional Microsoft security services beyond those listed, e.g Azure Firewall, Defender for DDoS, Defender for Cloud, Microsoft Entra, and Azure Key Vault - are appropriate for your environment. Depending on your architecture and threat model, you may also want to consider among other options:
>
> - [Azure Web Application Firewall (WAF)](https://learn.microsoft.com/en-us/azure/web-application-firewall/overview)
> - [Defender for App Service](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-app-service-introduction)
> - [Defender for Servers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-servers-overview)
> - [Microsoft Entra Global Secure Access (GSA)](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-what-is-global-secure-access)

---

## Get Started: Deployment Steps

### 1. Review and Select Desired Architecture

Before deploying, determine the architecture that best fits your requirements and understand the modules involved:

- **Reference example architectures:**
  - **Single Region:**
    ![Single Region Architecture](docs/images/architecture-single-region.png)
  - **Multi Region:**
    ![Multi Region Architecture](docs/images/architecture-multi-region.png)
- **Learn more:**
  - Read about [available Terraform modules and their usage](./docs/wiki/Modules.md) to see which modules to compose.

### 2. Prepare Your Environment

- Review and configure [environment prerequisites](docs/wiki/Prerequisites.md).
- Configure required environment variables: [Setup Environment Guide](docs/wiki/Setup-environment.md).

### 3. Decide How to Deploy

- **Automated (Recommended):**
  - Deploy through GitHub Actions CI/CD workflows for full automation. Follow the [Pipeline Deployment Guide](docs/wiki/Deploy-with-pipeline.md).
- **Manual:**
  - Run Terraform and supporting scripts directly. See [Manual Deployment Steps](docs/wiki/Deploy-with-manual-steps.md).

### 4. Choose Your Deployment Pattern

- Both **single-region** and **multi-region** patterns are supported across automated and manual deployment options.

### 5. Clean Up Resources

To avoid unexpected charges, **always clean up resources when you're done**.

See [Cleanup.md](docs/wiki/Cleanup.md) for the full step-by-step cleanup procedure, including how to destroy Azure and MongoDB Atlas resources in the correct order.


---

## Disclaimer

> **Warning:** Deploying this infrastructure is **NOT free**.
> It provisions paid resources such as a dedicated MongoDB Atlas cluster (minimum M10 tier for Private Endpoints), Azure networking components, and other Azure services. Review pricing details in the [MongoDB Atlas Private Endpoint documentation](https://www.mongodb.com/docs/atlas/security-private-endpoint/) before running `terraform apply`.

This code is provided for demonstration purposes and should not be used in production without thorough testing.
You are responsible for validating the configuration and ensuring it meets your environment's requirements.

For questions or to discuss suitability for your use case, please create an issue in this repository.

By using this repository, you agree to assume all risks and use it at your own discretion. Microsoft and the authors are not liable for damages or losses from its use.
See the [Support section](./SUPPORT.md) for details.

---

## Documentation & Wiki

Start exploring more detailed documentation in the [Wiki Home](docs/wiki/Home.md), including:

- [Known Issues](docs/wiki/KnownIssues.md)
- [Frequently Asked Questions](docs/wiki/FAQ.md)
- [Contribution Guidelines](docs/wiki/Contributing.md)

---

## Contributing

This project welcomes contributions and suggestions.
Before contributing, you will need to sign the [Microsoft Contributor License Agreement (CLA)](https://cla.opensource.microsoft.com).

Pull requests will be checked automatically by the CLA bot to determine if a CLA is required. Follow its instructions as needed.

We follow the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or email [opencode@microsoft.com](mailto:opencode@microsoft.com).

> Contribution details can be found in the [wiki](docs/wiki/Contributing.md).

---

## Trademarks

This project may contain trademarks or logos for projects, products, or services.
Authorized use of Microsoft trademarks or logos is subject to and must follow the [Microsoft Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Any use of third-party trademarks or logos is subject to those third parties’ policies.
