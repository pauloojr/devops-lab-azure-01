terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Configurar apos o primeiro apply para armazenar o estado no Azure Storage
  # backend "azurerm" {
  #   resource_group_name  = "rg-portfolio-dev"
  #   storage_account_name = "sttfstate<random>"
  #   container_name       = "tfstate"
  #   key                  = "lab01.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}