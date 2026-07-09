terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }
  }
  required_version = "~> 1.15.0"
}

provider "azurerm" {
  features {}
}