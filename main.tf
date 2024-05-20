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
resource "azurerm_windows_virtual_machine" "web_vms" {
 {
  count                = 2
  name                 = "web-vm-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.ASSET.name
  location             = azurerm_resource_group.ASSET.location
  size                 = "Standard_D2s_v3"
  admin_username       = "Azureuser"
  admin_password       = "YourP@ssword123"
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
  location            = azurerm_resource_group.ASSET.location
  resource_group_name = azurerm_resource_group.ASSET.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Backend Pool for Application Gateway
resource "azurerm_application_gateway_backend_address_pool" "web_backend_pool" {
  name                = "web-backend-pool"
  resource_group_name = azurerm_resource_group.ASSET.name
  location            = azurerm_resource_group.ASSET.location
  backend_addresses   = [azurerm_windows_virtual_machine.web_vms.*.network_interface.*.private_ip_address]
}

# Create HTTP Settings for Application Gateway
resource "azurerm_application_gateway_http_settings" "http_settings" {
  name                      = "http-settings"
  resource_group_name       = azurerm_resource_group.ASSET.name
  location                  = azurerm_resource_group.ASSET.location
  cookie_based_affinity     = "Disabled"
  port                      = 80
  protocol                  = "Http"
  request_timeout           = 20
}

# Create Listener for Application Gateway
resource "azurerm_application_gateway_listener" "http_listener" {
  name                                = "http-listener"
  resource_group_name                 = azurerm_resource_group.ASSET.name
  location                            = azurerm_resource_group.ASSET.location
  frontend_ip_configuration_name      = azurerm_application_gateway_frontend_ip_configuration.appgw_frontend_ip.name
  frontend_port_name                  = "http-port"
  protocol                            = "Http"
}

# Create Routing Rule for Application Gateway
resource "azurerm_application_gateway_url_path_map" "url_path_map" {
  name                     = "url-path-map"
  resource_group_name      = azurerm_resource_group.ASSET.name
  location                 = azurerm_resource_group.ASSET.location
  default_backend_address_pool_id = azurerm_application_gateway_backend_address_pool.web_backend_pool.id
  default_backend_http_settings_id = azurerm_application_gateway_http_settings.http_settings.id
  default_redirect_configuration {
    redirect_type = "Permanent"
    target_url = "https://www.example.com"
  }
}

# Associate URL Path Map with Listener
resource "azurerm_application_gateway_url_path_map" "path_map_association" {
  name                     = "path-map-association"
  resource_group_name      = azurerm_resource_group.ASSET.name
  location                 = azurerm_resource_group.ASSET.location
  gateway_id               = azurerm_application_gateway.appgw.id
  default_backend_address_pool_id = azurerm_application_gateway_backend_address_pool.web_backend_pool.id
  default_backend_http_settings_id = azurerm_application_gateway_http_settings.http_settings.id
  default_redirect_configuration {
    redirect_type = "Permanent"
    target_url = "https://www.example.com"
  }
}

# Create Frontend IP Configuration for Application Gateway
resource "azurerm_application_gateway_frontend_ip_configuration" "appgw_frontend_ip" {
  name                                = "appgw-frontend-ip"
  resource_group_name                 = azurerm_resource_group.ASSET.name
  location                            = azurerm_resource_group.ASSET.location
  public_ip_address_id                = azurerm_public_ip.appgw_public_ip.id
  private_ip_address_allocation       = "Dynamic"
  subnet_id                           = azurerm_subnet.web_subnet.id
}

# Create Azure Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                                = "app-gateway"
  resource_group_name                 = azurerm_resource_group.ASSET.name
  location                            = azurerm_resource_group.ASSET.location
  sku                                 = "Standard_v2"
  gateway_ip_configuration {
    name                              = "appgw-frontend-ip-config"
    subnet_id                         = azurerm_subnet.web_subnet.id
  }
  frontend_port {
    name                              = "http-port"
    port                              = 80
  }
  frontend_ip_configuration {
    name                              = "appgw-frontend-ip"
    public_ip_address_id              = azurerm_public_ip.appgw_public_ip.id
  }
  backend_address_pool {
    name                              = "web-backend-pool"
    backend_addresses                 = azurerm_windows_virtual_machine.web_vms.*.network_interface.*.private_ip_address
  }
  backend_http_settings {
    name                              = "http-settings"
    cookie_based_affinity             = "Disabled"
    port                              = 80
    protocol                          = "Http"
    request_timeout                   = 20
  }
  http_settings {
    name                              = "http-settings"
    cookie_based_affinity             = "Disabled"
    port                              = 80
    protocol                          = "Http"
    request_timeout                   = 20
  }
  gateway_ip_configuration {
    name                              = "appgw-frontend-ip-config"
    subnet_id                         = azurerm_subnet.web_subnet.id
  }
  frontend_ip_configuration {
    name                              = "appgw-frontend-ip"
    public_ip_address_id              = azurerm_public_ip.appgw_public_ip.id
  }
  url_path_map {
    name                              = "url-path-map"
    default_backend_address_pool_id   = azurerm_application_gateway_backend_address_pool.web_backend_pool.id
    default_backend_http_settings_id  = azurerm_application_gateway_http_settings.http_settings.id
    default_redirect_configuration {
      redirect_type                   = "Permanent"
      target_url                      = "https://www.example.com"
    }
  }
  ssl_certificate {
    name                              = "appgw-ssl-cert"
    data                              = "base64encodedcertificatedata"
    password                          = "certpassword"
  }
}



# Create SQL Server
resource "azurerm_sql_server" "main" {
  name                         = "my-sql-server"
  resource_group_name          = azurerm_resource_group.ASSET.name
  location                     = azurerm_resource_group.ASSET.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "H@Sh1CoR3!"
}

# Create SQL Database
resource "azurerm_sql_database" "main" {
  name                = "my-sql-database"
  resource_group_name = azurerm_resource_group.ASSET.name
  location            = azurerm_resource_group.ASSET.location
  server_name         = azurerm_sql_server.main.name
  edition             = "Standard"
  requested_service_objective_name = "S0"
}

# Create Firewall Rule to allow Azure services to access the server
resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.ASSET.name
  server_name         = azurerm_sql_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Backup configuration for Virtual Machines
resource "azurerm_backup_policy_vm" "daily" {
  name                = "daily-backup-policy"
  resource_group_name = azurerm_resource_group.ASSET.name
  location            = azurerm_resource_group.ASSET.location

  retention_daily {
    count = 7
  }

  schedule {
    time_zone = "UTC"
    daily {
      hour = 2
      minute = 0
    }
  }
}

# Backup configuration for SQL Database
resource "azurerm_backup_protected_item" "sql_backup" {
  resource_group_name       = azurerm_resource_group.ASSET.name
  vault_name                = azurerm_backup_vault.main.name
  backup_policy_id          = azurerm_backup_policy_sql.daily.id
  source_data_source_id     = azurerm_sql_database.main.id
}

# Backup Vault
resource "azurerm_backup_vault" "main" {
  name                = "my-backup-vault"
  resource_group_name = azurerm_resource_group.ASSET.name
  location            = azurerm_resource_group.ASSET.location
  sku                 = "Standard"
}

# Security Center configuration
resource "azurerm_security_center_subscription_pricing" "standard" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "sql" {
  tier          = "Standard"
  resource_type = "SqlServers"
}

# Create Availability Set for Web tier VMs
resource "azurerm_availability_set" "web_availability_set" {
  name                         = "web-tier-availability-set"
  resource_group_name          = azurerm_resource_group.ASSET.name
  location                     = azurerm_resource_group.ASSET.location
  managed                      = true
}

## Create Windows Server 2019 VMs for the web tier
resource "azurerm_windows_virtual_machine" "web_vms" {
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
  resource_group_name      = azurerm_resource_group.ASSET.name
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