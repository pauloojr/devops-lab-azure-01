output "azure_client_id" {
  value       = azuread_application.gh_actions.client_id
  description = "Application (Client) ID para o GitHub Actions"
}

output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Directory (Tenant) ID do Azure"
}

output "azure_subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Subscription ID do Azure"
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "Endpoint do Azure Container Registry"
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Nome da Storage Account de Terraform State"
}