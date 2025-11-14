# Pipeline Deployment Guide

This guide shows you how to deploy infrastructure using the automated GitHub Actions pipelines available in this repository.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Pipeline Steps](#pipeline-steps)
- [Running the Pipeline](#running-the-pipeline)
- [Choosing the Right Pipeline](#choosing-the-right-pipeline)
- [Notes](#notes)
- [Using an Existing Terraform Backend or Resource Groups](#using-an-existing-terraform-backend-or-resource-groups)

---

## Overview

This repository provides two main GitHub Actions pipelines for infrastructure deployment:

- **Single-Region:**  
  Workflow: `.github/workflows/ci-cd-infra-dev-single-region.yml`

- **Multi-Region:**  
  Workflow: `.github/workflows/ci-cd-infra-dev-multi-region.yml`

Use the pipeline that matches your deployment scenario. Each pipeline automatically manages the correct folder paths and deployment steps.

---

## Prerequisites

- **Manual Step (Step 00: DevOps):**  
  You must run step 00-devops manually before starting the pipeline. This initializes the resource groups, storage, and permissions needed for the rest of the deployment.  
  - Path: `envs/dev/00-devops/` (single- or multi-region as appropriate)
  - For details on this manual step, see [DevOps Setup (Manual Prerequisite)](./Deploy-with-manual-steps.md#devops-setup-manual-prerequisite).
- **Pipeline Environment Variables:**  
  After running step 00-devops, set all required environment variables and GitHub secrets using the outputs. See [Setup-environment.md](Setup-environment.md#github-environment-requirements) for details.

---

## Pipeline Steps

1. **Environment Setup**
   - Make sure all required environment variables and secrets in GitHub are set using the outputs from step 00. See [Setup-environment.md](Setup-environment.md).

2. **Base Infrastructure (Pipeline)**
   - Deploys core networking, MongoDB Atlas resources, observability infrastructure, and, if multi-region, configures VNet peering.
   - For details on observability and function app setup, see [Mongo Atlas Metrics App docs](./MongoAtlasMetrics_deployment_steps.md).
   - **Important:** You need to run this step twice:
     1. **First run:** Set `TF_VAR_open_access=true` to allow Key Vault creation and initial secret injection.
     2. **Second run:** Set `TF_VAR_open_access=false` to restrict Key Vault network access according to SFI/compliance requirements.

3. **Application (Optional)**
   - Deploys test application infrastructure (App Service Plan, subnet, Azure Web App).
   - Make sure to set any additional variables mentioned in [Setup-environment.md](Setup-environment.md#github-environment-requirements), such as `TF_VAR_key_name_infra_tfstate`.

4. **Testing Connectivity (Optional)**
   - You can deploy a web app to test database connectivity. See [Test_DB_connection_steps.md](Test_DB_connection_steps.md) for more information.
   - **Note:** The variables `FUNCTION_APP_NAME`, `INFRA_RG_NAME`, `APP_WEBAPPS`, and `APP_RG_NAME` must be set **after running and applying the Application step**, as their values are determined from the outputs of that step.

---

## Running the Pipeline

> **Note:** The pipeline does **not** automatically apply all changes. It will pause at the apply step and create a GitHub issue for manual approval by your designated approvers.

- Set the `approvers` parameter in [ci-cd-infra-base.yml](../../.github/workflows/ci-cd-infra-base.yml).
- See [Manual Approval Action documentation](https://trstringer.com/github-actions-manual-approval/) for details.

### How to Run

1. Go to the **Actions** tab in your GitHub repository.
2. Select the workflow matching your region type:
   - **Single-Region:** `CI - CD Infra Dev (Single-Region)`
   - **Multi-Region:** `CI - CD Infra Dev (Multi-Region)`
   - **App Code Deployment:** `Deploy Applications' code`
3. Click **Run workflow**.
4. Choose the steps as needed via checkboxes (plan/apply, infra/app, etc.).
5. Wait for the manual approval step if changes are detected.

**Deploy Applications' code** includes:
- **Deploy MongoAtlasMetrics Function App:** (default: enabled, requires infrastructure deployed)
- **Deploy Test DB Connection App:** (optional, requires infra & app infrastructure deployed)

---

## Choosing the Right Pipeline

- **Single-Region:** `.github/workflows/ci-cd-infra-dev-single-region.yml`  
  — For deployments using `templates/single-region/envs/dev/`
- **Multi-Region:** `.github/workflows/ci-cd-infra-dev-multi-region.yml`  
  — For deployments using `templates/multi-region/envs/dev/`
- **App Code:** `.github/workflows/ci-cd-application.yml`  
  — For deploying the MongoAtlasMetrics Function App or Test DB Connection App

---

## Notes

- If you need to re-run a pipeline, make sure all manual prerequisites (such as API key creation) are up to date.
- Do not run both the single-region and multi-region pipelines at the same time unless you are certain your Terraform state references are separate and correct.

---

## Using an Existing Terraform Backend or Resource Groups

For instructions on using an existing Terraform backend or existing resource groups, see [Using an Existing Backend or Resource Groups](./Deploy-with-manual-steps.md#using-an-existing-backend-or-resource-groups).

---