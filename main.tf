# Configure the Azure Resource Provider
provider "azurerm" {
  features {}
}

# Define a resource group
resource "azurerm_resource_group" "ASSET" {
  name     = "vnet-resource-group"
  location = "East US" 
}

# Create the Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name

  # Define subnets within the Virtual Network
  subnet {
    name              = "web-subnet"
    address_prefixes  = ["10.0.1.0/24"]
  }

  subnet {
    name              = "database-subnet"
    address_prefixes  = ["10.0.2.0/24"]
  }
}



# Configure the Azure Resource Provider
provider "azurerm" {
  features {}
}

# Define a resource group
resource "azurerm_resource_group" "example" {
  name     = "vnet-resource-group"
  location = "East US"  
}

# Create the Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name
}

# Create Web tier NSG
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-tier-nsg"
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Database tier NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "database-tier-nsg"
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name

  security_rule {
    name                       = "SQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_subnet.web_subnet.address_prefixes[0]  
    destination_address_prefix = "*"
  }
}

# Create Availability Set for Web tier VMs
resource "azurerm_availability_set" "web_availability_set" {
  name                         = "web-tier-availability-set"
  resource_group_name          = azurerm_resource_group.ASSET.name
  location                     = azurerm_resource_group.ASSET.location
  managed                      = true
}

## Create Windows Server 2019 VMs for the web tier
 resource "azurerm_windows_virtual_machine" "web_vms" 
 {
  count                = 2
  name                 = "web-vm-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.ASSET.name
  location             = azurerm_resource_group.ASSET.location
  size                 = "Standard_D2s_v3"
  admin_username       = "Azureuser"
  admin_password       = "yhere"
  availability_set_id  = azurerm_availability_set.web_availability_set.id
  delete_os_disk_on_termination = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  network_interface {
    name    = "web-nic-${count.index + 1}"
    primary = true

    ip_configuration {
      name                          = "internal"
      subnet_id                     = azurerm_subnet.web_subnet.id  
      private_ip_address_allocation = "Dynamic"
    }
  }
}

# Create Public IP for the Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "web-lb-public-ip"
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Backend Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  name                = "web-backend-pool"
  resource_group_name = azurerm_resource_group.ASSET.name
  loadbalancer_id     = azurerm_lb.web_lb.id
}

# Create Health Probe for Load Balancer
resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  resource_group_name = azurerm_resource_group.ASSET.name
  loadbalancer_id     = azurerm_lb.web_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

# Create Load Balancing Rule for Load Balancer
resource "azurerm_lb_rule" "http_rule" {
  name                     = "http-rule"
  resource_group_name      = azurerm_resource_group.ASSET.name
  loadbalancer_id          = azurerm_lb.web_lb.id
  frontend_ip_configuration_id = azurerm_lb_frontend_ip_configuration.web_frontend_ip.id
  backend_address_pool_id      = azurerm_lb_backend_address_pool.web_backend_pool.id
  probe_id                     = azurerm_lb_probe.http_probe.id
  protocol                     = "Tcp"
  frontend_port                = 80
  backend_port                 = 80
}

# Create Frontend IP Configuration for Load Balancer
resource "azurerm_lb_frontend_ip_configuration" "web_frontend_ip" {
  name                     = "web-frontend-ip"
  resource_group_name      = aazurerm_resource_group.ASSET.name
  loadbalancer_id          = azurerm_lb.web_lb.id
  public_ip_address_id     = azurerm_public_ip.lb_public_ip.id
}

# Create Azure Load Balancer
resource "azurerm_lb" "web_lb" {
  name                = "web-lb"
  resource_group_name = azurerm_resource_group.ASSET.name
  location            = azurerm_resource_group.ASSET.location
  sku                 = "Standard"
}

# Create Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "appgw-public-ip"
  location            = azurerm_resource