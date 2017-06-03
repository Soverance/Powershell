# Create a new Windows VM and create a new AD Forest, Domain and DC

This template will deploy a new VM (along with a new VNet, Storage Account and Load Balancer) and will configure it as a Domain Controller and create a new forest and domain.

This script will deploy the entire UA Master Default Configuration into Azure
The master config consists of the following resources:
- a new Azure Virtual Network, configured for a site-to-site VPN connection to local BKV resources
- a new storage account
- a load-balanced Windows Server 2016 instance with a new unified.agency Active Directory Domain.