# Cleanup Guide

Follow these steps to safely and completely clean up all resources provisioned by this Terraform solution.

---

## Cleanup Options

You can delete all infrastructure either with **Terraform** (recommended for automation and completeness) or by manually deleting resources in the Azure Portal and MongoDB Atlas.

---

### **Path 1: Terraform Destroy (Recommended)**

#### ⚠️ Important Note for Pipeline Deployments

If you deployed the infrastructure using a pipeline, any Key Vaults are owned by the pipeline's managed identity—not by your Azure user.
**By default, you will NOT have permissions to access or delete the Key Vault directly when using `terraform destroy`.**

**Before starting, grant your user account the necessary permissions:**

1. **Add Yourself to the Key Vault Access Policies:**
   - Go to the [Azure Portal](https://portal.azure.com/).
   - Locate the Key Vault created by the pipeline.
   - In the left menu, go to **Access policies** (or **Roles and administrators** if using RBAC).
   - Add your Microsoft Entra ID user account, granting at least the `Key Vault Administrator` role or necessary deletion permissions.
   - Save the changes.

---

#### Steps to destroy using Terraform:

1. **Update Key Vault Networking (Required for Destroy)**
   > **Important:**
   > The Key Vault restricts access using private endpoints or network rules.
   > **Before running destroy, temporarily set "Public access" to enabled, or add the Terraform execution machine/service to the allowed networks.** Otherwise, Terraform cannot destroy the Key Vault or its related secrets.
   >
   > In the Azure Portal, go to your Key Vault’s **Networking** section and adjust network settings as needed.

2. **Create a Destroy Execution Plan:**
   Run in your deployment directory:
   ```sh
   terraform plan -destroy -var-file="local.tfvars" -out main.destroy.tfplan
   ```
   **Key Points:**
   - This command shows the destruction plan without executing it.
   - `-out` ensures you run **exactly** the plan you reviewed.
   - **You (or the identity running `terraform destroy`) must have permissions to delete all resources, including the Key Vault. See the note above.**

3. **Apply the Destroy Execution Plan:**
   ```sh
   terraform apply main.destroy.tfplan
   ```

4. **Verify Azure Resource Cleanup:**
   In the Azure Portal, confirm all Resource Groups, VNets, private endpoints, Key Vaults, and related components are deleted.

5. **Delete the MongoDB Atlas Organization (optional):**
   - Go to [Organizations page](https://cloud.mongodb.com/v2#/org).
   - Follow the [official instructions](https://www.mongodb.com/docs/atlas/access/orgs-create-view-edit-delete/#delete-an-organization).
   - Complete this only if you want to ensure no active organization or charges remain.

---

### **Path 2: Manual Deletion via Portal or CLI**

1. **Delete the Resource Group (removes all Azure resources):**

   - **Via the Azure Portal:**
     1. Go to the [Azure Portal](https://portal.azure.com/).
     2. Navigate to "Resource groups".
     3. Select your target resource group.
     4. Click "Delete resource group".
     5. Confirm deletion as required.

   - **Via Azure CLI:**
     ```sh
     az group delete --name <resource-group-name> --yes --no-wait
     ```

   > **Note:**
   > Sometimes DNS records, especially private DNS zone links, may not be removed on the first try due to lingering Azure resource dependencies.
   > **If you encounter issues with DNS resources not deleting:**
   > - Wait a few minutes and try deleting the resource group again.
   > - Manually check for and remove any Private DNS Zone resources or links that remain.

2. **Delete resources in MongoDB Atlas manually:**
   - Go to [MongoDB Atlas portal](https://cloud.mongodb.com/).
   - Manually remove:
     - All **clusters**.
     - All **projects** (after removing clusters).
     - All **private endpoints** (from the project’s Network Access section).
   - Double-check no resources stay active.

3. **Delete the MongoDB Atlas Organization (optional):**
   - Go to your Organization in Atlas ([Organizations page](https://cloud.mongodb.com/v2#/org)).
   - Follow [official MongoDB docs](https://www.mongodb.com/docs/atlas/access/orgs-create-view-edit-delete/#delete-an-organization).
   - Ensure the organization and billing are cleared.

---

**Tip:** The Terraform path ensures all dependencies and resources are torn down in the correct order. Use manual deletion mostly if you face Terraform or permission issues.
