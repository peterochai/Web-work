Azure Infrastructure Deployment with Terraform
This repository contains Terraform scripts to deploy a secure, scalable infrastructure on Azure. The infrastructure includes virtual networks, subnets, network security groups, virtual machines, a SQL database, load balancers, an application gateway, Azure Key Vault for secrets management, Azure Backup for data protection, and Azure Security Center for security monitoring.

Prerequisites
Terraform installed on your local machine.
An Azure account.
Azure CLI installed and logged in.


Deployment Steps
1. Clone the Repository
Clone this repository to your local machine:
2. Initialize Terraform
Initialize the Terraform working directory.use terraform init command downloads the Azure provider and prepares your working directory:
3. Configure Variables
Review and, if necessary, modify the variables in the variables.tf file to suit your needs.
4. Plan the Deployment
Run the following command terraform plan to create an execution plan. This allows you to see what Terraform will do before making any changes:
5. Deploy the Infrastructure
Apply the Terraform configuration to create the infrastructure. Terraform will prompt for confirmation before making any changes:

6. Access the Resources
After deployment, you can access the resources:

Virtual Machines: Connect to the VMs using username and password with the public IP addresses assigned to them.
SQL Server: Connect to the SQL Server using the SQL Server Management Studio or any other SQL client.


Files in this Repository
main.tf: Contains the primary Terraform configuration for resources.
variables.tf: Defines the input variables used in the configuration.

Additional Information
Terraform Documentation
Azure Documentation


Troubleshooting
If you encounter issues, refer to the Terraform and Azure documentation or open an issue in this repository.