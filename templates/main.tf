# Crear backend de Terraform.
terraform {
  backend "azurerm" {
    resource_group_name  = "App_Tareas"
    storage_account_name = "appalmacen"
    container_name       = "contenedoralmacen"
    key                  = "terraform.tfstate"
  }
}

# Seleccionar el Azure Provider y la versión que usará
terraform {
  required_version = ">= 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1.0"
    }
  }
}

# Configurar Microsoft Azure provider
provider "azurerm" {
  features {}
}

# Crear grupo de recursos en caso de que no exista
resource "azurerm_resource_group" "az_rg" {
  name     = var.ResourceGroupName
  location = var.ResourceGroupLocation
}

# Crear Virtual Network
resource "azurerm_virtual_network" "az_vnet" {
  name                = var.AzurermVirtualNetworkName
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "my-terraform-env"
  }
}

# Crear Subnet en la Virtual Network
resource "azurerm_subnet" "az_subnet" {
  name                 = "my-terraform-subnet"
  resource_group_name  = azurerm_resource_group.az_rg.name
  virtual_network_name = azurerm_virtual_network.az_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Crear IP Pública
resource "azurerm_public_ip" "az_public_ip" {
  name                = "my-terraform-public-ip"
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name
  allocation_method   = "Static"

  tags = {
    environment = "my-terraform-env"
  }
}

# Crear Network Security Group y reglas
resource "azurerm_network_security_group" "az_net_sec_group" {
  name                = "my-terraform-nsg"
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "8080"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.puerto_expuesto
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "my-terraform-env"
  }
}

# Crear Network Interface
resource "azurerm_network_interface" "az_net_int" {
  name                = "my-terraform-nic"
  location            = azurerm_resource_group.az_rg.location
  resource_group_name = azurerm_resource_group.az_rg.name

  ip_configuration {
    name                          = "my-terraform-nic-ip-config"
    subnet_id                     = azurerm_subnet.az_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ip_privada
    public_ip_address_id          = azurerm_public_ip.az_public_ip.id
  }

  tags = {
    environment = "my-terraform-env"
  }
}

# Crear Network Interface Security Group association
resource "azurerm_network_interface_security_group_association" "az_net_int_sec_group" {
  network_interface_id      = azurerm_network_interface.az_net_int.id
  network_security_group_id = azurerm_network_security_group.az_net_sec_group.id
}

# Crear máquina virtual
resource "azurerm_linux_virtual_machine" "az_linux_vm" {
  name                            = "my-terraform-vm"
  location                        = azurerm_resource_group.az_rg.location
  resource_group_name             = azurerm_resource_group.az_rg.name
  network_interface_ids           = [azurerm_network_interface.az_net_int.id]
  size                            = var.size
  computer_name                   = var.hostname
  admin_username                  = var.usuario
  admin_password                  = var.contrasena
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "my-terraform-os-disk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = "my-terraform-env"
  }
}

# Configurar la ejecución de tareas automáticamente al iniciar la MV.
resource "azurerm_virtual_machine_extension" "az_vm_extension" {
  name                 = "customScript"
  virtual_machine_id   = azurerm_linux_virtual_machine.az_linux_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "commandToExecute": "apt-get update && apt-get install -y apache2 git && mkdir -p /var/www/myapp && git clone ${var.github_repo} /var/www/myapp"
    }
  SETTINGS

  tags = {
    environment = "my-terraform-env"
  }
}


# Fuente de datos para acceder a las propiedades de una dirección IP pública de Azure existente.
data "azurerm_public_ip" "az_public_ip" {
  name                = azurerm_public_ip.az_public_ip.name
  resource_group_name = azurerm_linux_virtual_machine.az_linux_vm.resource_group_name
}

# variables:

# Variable de salida: Dirección de IP pública
output "public_ip" {
  value = data.azurerm_public_ip.az_public_ip.ip_address
}

variable "StorageAccountName" {
  type        = string
  default     = "storage01" 
  description = "Nombre para la cuenta de almacenamiento"
}

variable "ResourceGroupName" {
  type        = string 
  default     = "my-terraform-rg" 
  description = "Nombre del grupo de recursos"
}

variable "ResourceGroupLocation" {
  type        = string 
  default     = "West Europe" 
  description = "Región donde reside el grupo de recursos"
}

variable "AzurermVirtualNetworkName" {
  type        = string
  default     = "my-terraform-vnet"
  description = "Nombre para la red virtual de Azure"
}

# Configuración VM
variable "usuario" {
  type        = string 
  default     = "Sergio"
  sensitive   = true 
}

variable "contrasena" {
  type        = string 
  default     = "Usuario1!"
  sensitive   = true
}

variable "hostname" {
  type        = string 
  default     = "myvm" 
}

variable "ip_privada" {
  type        = string
  default     = "10.0.2.5"
}

variable "size" {
  type        = string
  default     = "Standard_DS1_v2"
}

# Variables httpd
variable "puerto_expuesto" {
  type        = string
  default     = "8080"
}

variable "salida_echo" {
  type        = string
  default     = "Hola mundo"
}

variable "github_repo" {
  type        = string
  description = "URL del repositorio de GitHub que contiene la aplicación"
  default     = "https://github.com/sergioTFG/Gestor"
}

