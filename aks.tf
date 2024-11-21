# Key Vault creation
resource "azurerm_key_vault" "kv" {
  name                        = "${var.key_vault}"
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  enable_rbac_authorization = true
}

resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.this.location
  name                = "id-csi-driver-controlplane-01"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = azurerm_resource_group.this.location
  name                = "id-csi-driver-kubelet-01"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "controlplane_identity_contributor" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "cluster_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

### CSI Driver identity
resource "azurerm_user_assigned_identity" "workload_identity" {
  location            = azurerm_resource_group.this.location
  name                = "id-csi-driver-workloadidentity-01"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "secret_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

resource "azurerm_role_assignment" "current_user_secret_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_container_registry" "acr" {
  name                     = "${var.acr_name}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  sku                      = "Standard"  # Options: Basic, Standard, Premium
}


resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# AKS cluster with User-Assigned Identity and Secrets Store CSI Driver enabled
resource "azurerm_kubernetes_cluster" "this" {
  name                      = "${var.env}-${var.aks_name}"
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_prefix                = "${var.env}-aks"
  kubernetes_version        = var.aks_version
  oidc_issuer_enabled    = true
  private_cluster_enabled   = false


  sku_tier = "Free"


  
    identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controlplane.id]
  }

   kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  # Enable the Secrets Store CSI Driver 
 key_vault_secrets_provider {
  secret_rotation_enabled = true
   
 }

  network_profile {
    network_plugin = "kubenet"
    dns_service_ip = "10.0.3.4"
    service_cidr   = "10.0.3.0/24"
  }

  

  default_node_pool {
    name                 = "newpool"
    vm_size              = "Standard_D2_v2"
    vnet_subnet_id       = azurerm_subnet.subnet1.id
    node_count           = 2
  }

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_resourcegroup_contributor
  ]

  tags = {
    env = var.env
  }
}


