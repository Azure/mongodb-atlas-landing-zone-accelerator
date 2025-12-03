terraform {
  required_version = "~> 1.13.1"
  backend "local" {
  }

  # After deploying the resources with the local backend, 
  # migrate the state to the Azure backend to avoid losing
  # track of the infrastructure.

  # The steps to follow would be:
  # 1.- Deploy the resources with the local backend
  # 2.- Delete the local backend block
  # 3.- Uncomment and update the azurerm backend block with the appropriate values
  # 4.- Migrate the state to the Azure backend by running: terraform init -migrate-state
  # 5.- Delete the local terraform.tfstate file

  # backend "azurerm" {
  #   resource_group_name  = "{rg-devops-name-deployed-with-local-backend}"
  #   storage_account_name = "{sa-devops-name-deployed-with-local-backend}"
  #   container_name       = "{container-devops-name-deployed-with-local-backend}"
  #   key                  = "devops.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
}
