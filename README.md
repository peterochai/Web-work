# Web-work
The first  script will create a resource group named "vnet-resource-group" in the "East US" region, and within that resource group, it will create a virtual network named "my-vnet". Inside this virtual network, it will define two subnets: "web-subnet" with the address prefix "10.0.1.0/24" and "database-subnet" with the address prefix "10.0.2.0/24".

I ve added two azurerm_network_security_group resources to define NSGs for the web tier and the database tier.
For the web tier NSG, we've created security rules to allow inbound HTTP (port 80) and HTTPS (port 443) traffic.
For the database tier NSG, I created a security rule to allow inbound SQL traffic (port 1433) from the web tier subnet. 


Created an availability set specifically for the web tier virtual machines (azurerm_availability_set.web_availability_set).
We've then created two Windows Server 2019 virtual machines for the web tier using the specified size, managed disks, and availability set (azurerm_windows_virtual_machine.web_vms).
The virtual machines are placed in the specified resource group and location, and each gets a premium SSD managed disk with a size of 128 GB.
We've attached each VM's network interface to the subnet created for the web tier (azurerm_subnet.web_subnet).
The VMs are created with the latest version of the Windows Server 2019 Datacenter image.