resource "azurerm_resource_group" "Web" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"

}
 
# Create virtual network
resource "azurerm_virtual_network""Web_net" {
  name                = "${random_pet.prefix.id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define Subnets:
resource "azurerm_virtual_network" "my_vnet" {
  name                = "web_subnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.my_rg.name
}
 
resource "azurerm_subnet" "web_subnet" {
  name                 = "web_subnet"
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
 
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}
 
# Create NSGs:
 
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.my_rg.name
}
 
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.my_rg.name
}
 
Define NSG Rules:
 
resource "azurerm_network_security_rule" "web_http" {
  name                        = "web-http"
  priority                    = 250
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
 
resource "azurerm_network_security_rule" "web_https" {
  name                        = "web-https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}
 
resource "azurerm_network_security_rule" "db_sql" {
  name                        = "db_sql"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = azurerm_subnet.web_subnet.address_prefixes[0]
  destination_address_prefix  = azurerm_subnet.db_subnet.address_prefixes[0]
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

# Associate NSGs with Subnets:
resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}
 
resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
 
# Create availability_set
resource "azurerm_availability_set "DemoAset" { 
  name                 = "example-aset"  
  location             = azurerm_resource_group.rg.location  
  resource_group_name  = azurerm_resource_group.rg.name
}

# Create VM
resource "azurerm_windows_virtual_machine" "vm" {
  count               = 2
  name                = "my-vm-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = ["Standard_D2s_v3", "Standard_D2s_v3"][count.index]  # Customize VM sizes
  admin_username      = "myadminuser"
  admin_password      = "MyP@ssw0rd123"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"  # Customize disk type
    disk_size_gb         = [128, 128[count.index]  # Customize disk size
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  boot_diagnostics {   
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Create network_interface 
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "my-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "static"
  sku		      = "standard"
}

# Create Public Load Balancer resource "azurerm_lb" "my_lb" { 
  name                = "my_lb"
  location            = azurerm_resource_group.my_resource_group.location   
  resource_group_name = azurerm_resource_group.my_resource_group.name   
  sku                 = "Standard" 
  frontend_ip_configuration { 
 
   name                 = "Public-ip"  
 public_ip_address_id = azurerm_public_ip.public_ip.id  
 } 
} 
resource "azurerm_lb_backend_address_pool" "my_lb_pool" { 
  loadbalancer_id      = azurerm_lb.my_lb.id 
  name                 = "test-pool" 
} 
resource "azurerm_lb_probe" "my_lb_probe" {  
 resource_group_name = azurerm_resource_group.my_resource_group.name  
 loadbalancer_id     = azurerm_lb.my_lb.id 
 name                = "test-probe"  
 port                = 80 
} 
resource "azurerm_lb_rule" "my_lb_rule" {  
 resource_group_name             = azurerm_resource_group.my_resource_group.name 
  loadbalancer_id                = azurerm_lb.my_lb.id  
 name                            = "test-rule" 
  protocol                       = "Tcp"  
 frontend_port                   = 80  
 backend_port                    = 80 
  disable_outbound_snat          = true  
 frontend_ip_configuration_name  = public-ip  
 probe_id                        = azurerm_lb_probe.my_lb_probe.id 
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.my_lb_pool.id]
}

# Associate Network Interface to the Backend Pool of the Load Balancer 
resource "azurerm_network_interface_backend_address_pool_association" "my_nic_lb_pool" { 
  count                   = 2  
  network_interface_id    = azurerm_network_interface.nic[count.index1].id  
  ip_configuration_name   = "internal"  
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_lb_pool.id
}

# Create public IPs
resource "azurerm_public_ip" "my_public_ip" {
  name                = "my_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "static"
  sku		      = "standard"
}

# Create application_gateway
resource "azurerm_application_gateway""main"{  
 name                ="myAppGateway"
 resource_group_name = azurerm_resource_group.rg.name 
 location            = azurerm_resource_group.rg.location  
 sku {  
   name     ="Standard_v2"
   tier     ="Standard_v2"
   capacity = 2  
} 
gateway_ip_configuration {   
  name      ="my-gateway-ip-configuration"
  subnet_id = azurerm_subnet.frontend.id  
}  
 frontend_port {   
   name = var.frontend_port_name     
   port = 80  
}  
 frontend_ip_configuration {   
   name                 = var.frontend_ip_configuration_name   
   public_ip_address_id = azurerm_public_ip.pip.id
}  
 backend_address_pool { 
    name = var.backend_address_pool_name  
} 
 backend_http_settings {   
  name                  = var.http_setting_name     
  cookie_based_affinity ="Disabled"
  port                  = 80  
  protocol              ="Http"
  request_timeout       = 60 
 }
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-${count.index+1}"  
  location            = azurerm_resource_group.rg.location 
  resource_group_name = azurerm_resource_group.rg.name 
  ip_configuration {  
    name                          = "nic-ipconfig-${count.index+1}"   
    subnet_id                     = azurerm_subnet.backend.id   
    private_ip_address_allocation = "Dynamic"
  } 
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc" {   
  count                    = 2  
  network_interface_id     = azurerm_network_interface.nic[count.index].id 
  ip_configuration_name    = "nic-ipconfig-${count.index+1}" 
  backend_address_pool_id  = one(azurerm_application_gateway.main.backend_address_pool).id
}

# Generate random text for a unique storage account name
resource
"random_id"
"random_id"
{   keepers = {    
# Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name   }   byte_length = 8}echo "# Provisioning-a-Web-Infrastructure-Stack" >> README.md