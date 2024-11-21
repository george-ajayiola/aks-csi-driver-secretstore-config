output "aks_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.this.fqdn
}

output "aks_node_rg" {
  value = azurerm_kubernetes_cluster.this.node_resource_group
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}