variable "ResourceGroupName" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "myResourceGroup"
}

variable "ResourceGroupLocation" {
  description = "Ubicación del grupo de recursos"
  type        = string
  default     = "East US"
}

variable "AzurermVirtualNetworkName" {
  description = "Nombre de la red virtual"
  type        = string
  default     = "myVnet"
}

variable "puerto_expuesto" {
  description = "Puerto expuesto por la aplicación web"
  type        = string
  default     = "8080"
}

variable "ip_privada" {
  description = "Dirección IP privada"
  type        = string
  default     = "10.0.2.4"
}

variable "size" {
  description = "Tamaño de la máquina virtual"
  type        = string
  default     = "Standard_B1s"
}

variable "hostname" {
  description = "Nombre del equipo"
  type        = string
  default     = "my-vm"
}

variable "usuario" {
  description = "Nombre del usuario administrador"
  type        = string
  default     = "azureuser"
}

variable "contrasena" {
  description = "Contraseña del usuario administrador"
  type        = string
  default     = ""
}

variable "salida_echo" {
  description = "Mensaje de salida para el script de inicialización"
  type        = string
  default     = "Aplicación web en ejecución"
}

variable "app_repo_url" {
  description = "URL del repositorio del código de la aplicación"
  type        = string
  default     = "https://github.com/sergioTFG/Gestor"
}
