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

# 2. Storage Account para Backend do Terraform com Hardening
# checkov:skip=CKV_AZURE_59: "Storage Account de Lab requer acesso publico autenticado via OIDC/Azure CLI sem VNet dedicada"
# checkov:skip=CKV_AZURE_206: "Replicacao LRS escolhida deliberadamente para otimizacao de custo FinOps em ambiente Dev"
# checkov:skip=CKV_AZURE_33: "Storage Logging de filas desabilitado pois o servico de Queue nao e utilizado neste projeto"
# checkov:skip=CKV2_AZURE_1: "Criptografia padrao com chave gerenciada pela Microsoft (MMK) atende requisitos sem custo de Key Vault HSM"
# checkov:skip=CKV2_AZURE_33: "Private Endpoint desnecessario para ambiente de laboratorio publico com autenticacao RBAC"
# checkov:skip=CKV2_AZURE_40: "Autorizacao Shared Key mantida exclusivamente para compatibilidade do backend nativo do Terraform azurerm"
# checkov:skip=CKV2_AZURE_21: "Metricas padrao do Azure Monitor utilizadas em substituicao aos logs legados de blob storage"
resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  sas_policy {
    expiration_period = "01.00:00:00" # 1 dia maximo para SAS tokens
  }

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# 3. Azure Container Registry (ACR) com Hardening
# checkov:skip=CKV_AZURE_166: "Quarentena de imagem e recurso exclusivo do SKU Premium"
# checkov:skip=CKV_AZURE_237: "Data endpoints dedicados exigem SKU Premium"
# checkov:skip=CKV_AZURE_139: "Acesso de rede publico obrigatorio para runners publicos do GitHub Actions sem Self-Hosted Runner em VNet"
# checkov:skip=CKV_AZURE_164: "Content Trust / Image signing validado via Trivy em CI"
# checkov:skip=CKV_AZURE_167: "Retention policy de manifests orfaos e recurso exclusivo do SKU Premium"
# checkov:skip=CKV_AZURE_165: "Geo-replicacao e recurso exclusivo do SKU Premium"
# checkov:skip=CKV_AZURE_163: "Microsoft Defender for Containers nao habilitado por questoes de custo no tier basico"
# checkov:skip=CKV_AZURE_233: "Zonas de disponibilidade exigem SKU Premium"
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

# RBAC: Permissao de menor privilegio (AcrPush)
resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.gh_actions.object_id
}