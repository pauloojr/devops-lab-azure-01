data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Resource Group Principal
resource "azurerm_resource_group" "main" {
  name     = "rg-portfolio-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "DevOps-Portfolio"
  }
}

# 2. Storage Account para Backend do Terraform (azurerm v4.x ready)
resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# 3. Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acrportfolio${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = azurerm_resource_group.main.tags
}

# 4. Azure AD (Entra ID) App & Federated Identity para GitHub Actions
resource "azuread_application" "gh_actions" {
  display_name = "app-github-actions-portfolio"
}

resource "azuread_service_principal" "gh_actions" {
  client_id = azuread_application.gh_actions.client_id
}

# Credencial Federada para a branch main
resource "azuread_application_federated_identity_credential" "gh_actions_main" {
  application_id = azuread_application.gh_actions.id
  display_name   = "github-actions-main-branch"
  description    = "Federated credential for GitHub Actions main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:ref:refs/heads/main"
}

# Credencial Federada para Pull Requests
resource "azuread_application_federated_identity_credential" "gh_actions_pr" {
  application_id = azuread_application.gh_actions.id
  display_name   = "github-actions-pull-requests"
  description    = "Federated credential for GitHub Actions pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:pull_request"
}

# RBAC: Permissao estrita de AcrPush no ACR
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.gh_actions.object_id
}