variable "env" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "key_vault" {
  description = "The key vault name"
  type        = string
  default     = "awsaccesskey-vault"
  
}

variable "region" {
  description = "The Azure region"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "devops-stuff"
}

variable "aks_name" {
  description = "The name of the AKS cluster"
  type        = string
  default     = "api-cluster"
}

variable "acr_name" {
  description = "The name of the ACR"
  type        = string
  default     = "myfirstlab"

  
}

variable "aks_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.29.7"
}
