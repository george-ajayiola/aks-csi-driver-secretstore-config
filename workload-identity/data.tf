data "azurerm_resource_group" "rg" {
  name = "devops-stuff"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "dev-django-rest-api-cluster"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_user_assigned_identity" "workload_identity" {
  name                = "id-csi-driver-workloadidentity-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}