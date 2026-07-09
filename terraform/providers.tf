terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }
  }
  required_version = "~> 1.15.0"

  backend "azurerm" {
    resource_group_name = "devops-helloworld-pipeline"
    storage_account_name = "storageaccount2697"
    container_name       = "tfstatefile"
    key                   = "devops-project.tfstate"
    }
}