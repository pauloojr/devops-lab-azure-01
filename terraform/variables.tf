variable "location" {
  type        = string
  description = "Regiao do Azure onde os recursos serao criados"
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Identificador de ambiente"
  default     = "dev"
}

variable "github_repo" {
  type        = string
  description = "Caminho do repositorio GitHub (ex: usuario/devops-lab-azure-01)"
}