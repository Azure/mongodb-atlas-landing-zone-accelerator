terraform {
  required_version = "~> 1.13.1"

  backend "azurerm" {
    use_azuread_auth = true
  }

  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.39.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "mongodbatlas" {
}

resource "time_static" "build_time" {}
