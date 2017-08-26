/*This template aims is to create the following architecture
1 RG
1 vNET
1 Subnet FrontEnd
1 Subnet BackEnd
1 Subnet Bastion
2 VM FrontEnd Web Apache + Azure LB
2 VM Backend DB PostgreSQL 
1 VM Linux Bastion
1 public IP on FrontEnd
1 public IP on Bastion
1 external AzureLB
AzureManagedDIsk
NSG on FrontEnd Subnet
    Allow HTTP HTTPS from Internet through ALB
    Allow Access to internet egress
    Allow PostgreSQL to DB Tier
NSG on Backend Subnet
    Allow PostgreSQL Access from Web tier
    Allow egress Internet
NSG on Bastion
    Allow SSH from internet
    Allow SSH to all subnet
    Allow Internet access egress

*/
######################################################################
# Access to Azure
######################################################################


# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf

provider "azurerm" {

    subscription_id = "${var.AzureSubscriptionID}"
    client_id       = "${var.AzureClientID}"
    client_secret   = "${var.AzureClientSecret}"
    tenant_id       = "${var.AzureTenantID}"
}


######################################################################
# Foundations resources, including ResourceGroup and vNET
######################################################################

# Creating the ResourceGroup


resource "azurerm_resource_group" "RSG-BasicLinux" {

    name        = "${var.RSGName}"
    location    = "${var.AzureRegion}"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }
    }

# Creating vNET

resource "azurerm_virtual_network" "vNET-BasicLinux" {

    name = "vNET-BasicLinux"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"
    address_space = ["10.0.0.0/20"]
    location = "${var.AzureRegion}"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }   
}

######################################################################
# Network security, NSG and subnet
######################################################################

# Creating NSG for FrontEnd

resource "azurerm_network_security_group" "NSG-Subnet-BasicLinuxFrontEnd" {

    name = "NSG-Subnet-BasicLinuxFrontEnd"
    location = "${var.AzureRegion}"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"

    #############################################
    # Rules Section
    #############################################

    # Rule for incoming HTTP from internet

    security_rule {

    name                       = "OK-http-Inbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "INTERNET"
    destination_address_prefix = "10.0.0.0/24"
        
    }

    # Rule for incoming HTTPS from internet
    
    security_rule {

    name                       = "OK-https-Inbound"
    priority                   = 1101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "INTERNET"
    destination_address_prefix = "10.0.0.0/24"
    }

    # Rule for AZure Load Balancer

    security_rule {

    name                       = "OK-AzureLB-Inbound"
    priority                   = 1102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AZURELOADBALANCER"
    destination_address_prefix = "10.0.0.0/24"

    }

    # Rule for incoming SSH from Bastion

    security_rule {

    name                       = "OK-BastionSubnet-Inbound"
    priority                   = 1103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.0.0/24"



    }

    #Rule for outbound to Internet traffic

    security_rule {

    name                       = "OK-FrontEndInternet-Outbound"
    priority                   = 1400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "INTERNET"
  }

}
# Creating Subnet FrontEnd

resource "azurerm_subnet" "Subnet-BasicLinuxFrontEnd" {

    name = "Subnet-BasicLinuxFrontEnd"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    virtual_network_name        = "${azurerm_virtual_network.vNET-BasicLinux.name}"
    address_prefix              = "10.0.0.0/24"
    network_security_group_id   = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.id}"


}

# Creating NSG for BackEnd

resource "azurerm_network_security_group" "NSG-Subnet-BasicLinuxBackEnd" {

    name = "NSG-Subnet-BasicLinuxBackEnd"
    location = "${var.AzureRegion}"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"
    
    #############################################
    # Rules Section
    #############################################

    # Rule for incoming * from frontend subnet

    security_rule {

    name                       = "OK-all-SubnetFrontEndInbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/24"
    destination_address_prefix = "10.0.1.0/24"
        
    }

    # Rule for incoming SSH from Bastion
    
    security_rule {

    name                       = "OK-SSH-Inbound"
    priority                   = 1102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.1.0/24"
    }

    # Rule for AZure Load Balancer

    security_rule {

    name                       = "OK-AzureLB-Inbound"
    priority                   = 1103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AZURELOADBALANCER"
    destination_address_prefix = "10.0.1.0/24"

    }

    # Temporary rule for SSH
    security_rule {

    name                       = "OK-SSHTemp-Inbound"
    priority                   = 1105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "AZURELOADBALANCER"
    destination_address_prefix = "10.0.1.0/24"

    }

    #Rule for outbound to Internet traffic

    security_rule {

    name                       = "OK-BackEndInternet-Outbound"
    priority                   = 1400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "INTERNET"

    }

}


# Creating Subnet Bastion

resource "azurerm_subnet" "Subnet-BasicLinuxBackEnd"{

    name = "Subnet-BasicLinuxBackEnd"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    virtual_network_name        = "${azurerm_virtual_network.vNET-BasicLinux.name}"
    address_prefix              = "10.0.1.0/24"
    network_security_group_id   = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBackEnd.id}"


}

# Creating NSG for Bastion

resource "azurerm_network_security_group" "NSG-Subnet-BasicLinuxBastion" {

    name = "NSG-Subnet-BasicLinuxBastion"
    location = "${var.AzureRegion}"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"

    #############################################
    # Rules Section
    #############################################

    # Rule for incoming SSH from internet

    security_rule {

    name                       = "OK-SSH-Inbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "INTERNET"
    destination_address_prefix = "10.0.2.0/24"

    }

    #Rule for outbound to Internet traffic

    security_rule {

    name                       = "OK-Subnet2Internet-Outbound"
    priority                   = 1400
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "INTERNET"
    }

}


# Creating Subnet Bastion

resource "azurerm_subnet" "Subnet-BasicLinuxBastion" {

    name                        = "Subnet-BasicLinuxBastion"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    virtual_network_name        = "${azurerm_virtual_network.vNET-BasicLinux.name}"
    address_prefix              = "10.0.2.0/24"
    network_security_group_id   = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBastion.id}"


}


######################################################################
# Public IP Address
######################################################################

# Creating Public IP for Load Balancer on FrontEnd

resource "azurerm_public_ip" "PublicIP-FrontEndBasicLinux" {

    name                            = "PublicIP-FrontEndBasicLinux"
    location                        = "${var.AzureRegion}"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    public_ip_address_allocation    = "static"
    domain_name_label               = "${var.PrefixforPublicIP}dvtweb"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }

}

# Creating Public IP for Bastion

resource "azurerm_public_ip" "PublicIP-BastionBasicLinux" {

    name                            = "PublicIP-BastionBasicLinux"
    location                        = "${var.AzureRegion}"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    public_ip_address_allocation    = "static"
    domain_name_label               = "${var.PrefixforPublicIP}dvtbastion"
    
    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }
}

######################################################################
# Load Balancing
######################################################################



# Creating Azure Load Balancer for front end http / https


resource "azurerm_lb" "LB-WebFrontEndBasicLinux" {

    name                        = "LB-WebFrontEndBasicLinux"
    location                    = "${var.AzureRegion}"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"

    frontend_ip_configuration {

        name                    = "weblbbasiclinux"
        public_ip_address_id    = "${azurerm_public_ip.PublicIP-FrontEndBasicLinux.id}"
    }

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }
}


# Creating Back-End Address Pool

resource "azurerm_lb_backend_address_pool" "LB-WebFRontEndBackEndPool" {

    name                = "LB-WebFRontEndBackEndPool"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"
    loadbalancer_id     = "${azurerm_lb.LB-WebFrontEndBasicLinux.id}"
    
}


# Creating Health Probe

resource "azurerm_lb_probe" "LB-WebFrontEnd-sshprobe" {

    name                = "LB-WebFrontEnd-sshprobe"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"
    loadbalancer_id     = "${azurerm_lb.LB-WebFrontEndBasicLinux.id}"
    port                = 22


}

# Creating Load Balancer rules

resource "azurerm_lb_rule" "LB-WebFrondEndrule" {

    name                            = "LB-WebFrondEndrule"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    loadbalancer_id                 = "${azurerm_lb.LB-WebFrontEndBasicLinux.id}"
    protocol                        = "tcp"
    probe_id                        = "${azurerm_lb_probe.LB-WebFrontEnd-sshprobe.id}"
    frontend_port                   = 80
    #frontend_ip_configuration_name  = "${azurerm_public_ip.PublicIP-FrontEndBasicLinux.name}"
    frontend_ip_configuration_name = "weblbbasiclinux"
    backend_port                    = 80
    backend_address_pool_id         = "${azurerm_lb_backend_address_pool.LB-WebFRontEndBackEndPool.id}"


}


###########################################################################
# Managed Disk creation
###########################################################################

# Managed disks for Web frontend VMs

resource "azurerm_managed_disk" "WebFrontEndManagedDisk" {

    count                   = 3
    name                    = "WebFrontEnd-${count.index + 1}-Datadisk"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    storage_account_type    = "Standard_LRS"
    create_option           = "Empty"
    disk_size_gb            = "127"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
    
}



# Managed disks for Web DB Backend VMs

resource "azurerm_managed_disk" "DBBackEndManagedDisk" {

    count                   = 2
    name                    = "DBBackEnd-${count.index + 1}-Datadisk"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    storage_account_type    = "Premium_LRS"
    create_option           = "Empty"
    disk_size_gb            = "127"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
    
}

# Managed disks for Bastion VM

resource "azurerm_managed_disk" "BastionManagedDisk" {

    count                   = 1
    name                    = "Bastion-${count.index + 1}-Datadisk"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    storage_account_type    = "Standard_LRS"
    create_option           = "Empty"
    disk_size_gb            = "127"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
    
}

###########################################################################
#NICs creation
###########################################################################

# NIC Creation for Web FrontEnd VMs

resource "azurerm_network_interface" "WebFrontEndNIC" {

    count                   = 3
    name                    = "WebFrontEnd${count.index +1}-NIC"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"

    ip_configuration {

        name                                        = "ConfigIP-NIC${count.index + 1}-WebFrontEnd${count.index + 1}"
        subnet_id                                   = "${azurerm_subnet.Subnet-BasicLinuxFrontEnd.id}"
        private_ip_address_allocation               = "dynamic"
        load_balancer_backend_address_pools_ids     = ["${azurerm_lb_backend_address_pool.LB-WebFRontEndBackEndPool.id}"]
    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }


}


# NIC Creation for DB BackEnd VMs

resource "azurerm_network_interface" "DBBackEndNIC" {

    count                   = 2
    name                    = "DBBackEnd${count.index +1}-NIC"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"

    ip_configuration {

        name                                        = "ConfigIP-NIC${count.index + 1}-DBBackEnd${count.index + 1}"
        subnet_id                                   = "${azurerm_subnet.Subnet-BasicLinuxBackEnd.id}"
        private_ip_address_allocation               = "dynamic"
            }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }


}

# NIC Creation for Bastion VMs

resource "azurerm_network_interface" "BastionNIC" {

    count                   = 1
    name                    = "Bastion${count.index +1}-NIC"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"

    ip_configuration {

        name                                        = "ConfigIP-NIC${count.index + 1}-Bastion${count.index + 1}"
        subnet_id                                   = "${azurerm_subnet.Subnet-BasicLinuxBastion.id}"
        private_ip_address_allocation               = "dynamic"
        public_ip_address_id                        = "${azurerm_public_ip.PublicIP-BastionBasicLinux.id}"
            }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }


}


###########################################################################
#VMs Creation
###########################################################################

# Availability Set for Web FrontEnd VMs

resource "azurerm_availability_set" "BasicLinuxWebFrontEnd-AS" {

    name                    = "BasicLinuxWebFrontEnd-AS"
    location                = "${var.AzureRegion}"
    managed                 = "true"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
  }
}

# Availability Set for BackEnd VMs

resource "azurerm_availability_set" "BasicLinuxDBBackEnd-AS" {

    name                    = "BasicLinuxDBBackEnd-AS"
    location                = "${var.AzureRegion}"
    managed                 = "true"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
  }
}

# Availability Set for Bastion VM

resource "azurerm_availability_set" "BasicLinuxBastion-AS" {

    name                    = "BasicLinuxBastion-AS"
    location                = "${var.AzureRegion}"
    managed                 = "true"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
  }
}

# Web FrontEnd VMs creation


resource "azurerm_virtual_machine" "BasicLinuxWebFrontEndVM" {

    count                   = 3
    name                    = "BasicLinuxWebFrontEnd${count.index +1}"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_interface_ids   = ["${element(azurerm_network_interface.WebFrontEndNIC.*.id, count.index)}"]
    vm_size                 = "${var.VMSize}"
    availability_set_id     = "${azurerm_availability_set.BasicLinuxWebFrontEnd-AS.id}"
    depends_on              = ["azurerm_network_interface.WebFrontEndNIC"]

    storage_image_reference {

        publisher   = "${var.OSPublisher}"
        offer       = "${var.OSOffer}"
        sku         = "${var.OSsku}"
        version     = "${var.OSversion}"

    }

    storage_os_disk {

        name                = "WebFrontEnd-${count.index + 1}-OSDisk"
        caching             = "ReadWrite"
        create_option       = "FromImage"
        managed_disk_type   = "Standard_LRS"

    }

    storage_data_disk {

        name                = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.name, count.index)}"
        managed_disk_id     = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.id, count.index)}"
        create_option       = "Attach"
        lun                 = 0
        disk_size_gb        = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.disk_size_gb, count.index)}"

    }

    os_profile {

        computer_name   = "WebFrontEnd${count.index + 1}"
        admin_username  = "${var.VMAdminName}"
        admin_password  = "${var.VMAdminPassword}"

    }

    /*os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.OCPAdminName}/.ssh/authorized_keys"
      key_data = "${var.OCPPublicSSHKey}"
    }

    }*/

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}

# Creating virtual machine extension for Front End
/*
resource "azurerm_virtual_machine_extension" "DSCExtension-basicLinuxFrontEnd" {
  count                = 2
  name                 = "DSCExtensionFrontEnd"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxWebFrontEnd${count.index +1}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "DSCForLinux"
  type_handler_version = "2.5"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxWebFrontEndVM"]
    /*  settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/squasta/TerraformAzureRM/master/deploy2.sh" ],
        "commandToExecute": "bash deploy2.sh"
    }
    SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}
*/

# DB BackEnd VMs Creation

resource "azurerm_virtual_machine" "BasicLinuxDBBackEndVM" {

    count                   = 2
    name                    = "BasicLinuxDBBackEnd${count.index +1}"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_interface_ids   = ["${element(azurerm_network_interface.DBBackEndNIC.*.id, count.index)}"]
    vm_size                 = "${var.VMSize}"
    availability_set_id     = "${azurerm_availability_set.BasicLinuxDBBackEnd-AS.id}"
    depends_on              = ["azurerm_network_interface.DBBackEndNIC"]

    storage_image_reference {

        publisher   = "${var.OSPublisher}"
        offer       = "${var.OSOffer}"
        sku         = "${var.OSsku}"
        version     = "${var.OSversion}"

    }

    storage_os_disk {

        name                = "DBBackEnd-${count.index + 1}-OSDisk"
        caching             = "ReadWrite"
        create_option       = "FromImage"
        managed_disk_type   = "Premium_LRS"

    }

    storage_data_disk {

        name                = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.name, count.index)}"
        managed_disk_id     = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.id, count.index)}"
        create_option       = "Attach"
        lun                 = 0
        disk_size_gb        = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.disk_size_gb, count.index)}"

    }

    os_profile {

        computer_name   = "DBBackEnd${count.index + 1}"
        admin_username  = "${var.VMAdminName}"
        admin_password  = "${var.VMAdminPassword}"

    }

    /*os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.OCPAdminName}/.ssh/authorized_keys"
      key_data = "${var.OCPPublicSSHKey}"
    }

    }*/

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}


# Creating virtual machine extension for Back End
/*
resource "azurerm_virtual_machine_extension" "DSCExtension-basicLinuxBackEnd" {
  count                = 2
  name                 = "DSCExtensionBackEnd"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxDBBackEnd${count.index +1}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "DSCForLinux"
  type_handler_version = "2.5"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxDBBackEndVM"]

    /*  settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/squasta/TerraformAzureRM/master/deploy2.sh" ],
        "commandToExecute": "bash deploy2.sh"
    }
    SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}
*/

# Bastion VM Creation

resource "azurerm_virtual_machine" "BasicLinuxBastionVM" {

    count                   = 1
    name                    = "BasicLinuxBastion${count.index +1}"
    location                = "${var.AzureRegion}"
    resource_group_name     = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_interface_ids   = ["${element(azurerm_network_interface.BastionNIC.*.id, count.index)}"]
    vm_size                 = "${var.VMSize}"
    availability_set_id     = "${azurerm_availability_set.BasicLinuxBastion-AS.id}"
    depends_on              = ["azurerm_network_interface.BastionNIC"]

    storage_image_reference {

        publisher   = "${var.OSPublisher}"
        offer       = "${var.OSOffer}"
        sku         = "${var.OSsku}"
        version     = "${var.OSversion}"

    }

    storage_os_disk {

        name                = "Bastion-${count.index + 1}-OSDisk"
        caching             = "ReadWrite"
        create_option       = "FromImage"
        managed_disk_type   = "Standard_LRS"

    }

    storage_data_disk {

        name                = "${element(azurerm_managed_disk.BastionManagedDisk.*.name, count.index)}"
        managed_disk_id     = "${element(azurerm_managed_disk.BastionManagedDisk.*.id, count.index)}"
        create_option       = "Attach"
        lun                 = 0
        disk_size_gb        = "${element(azurerm_managed_disk.BastionManagedDisk.*.disk_size_gb, count.index)}"

    }

    os_profile {

        computer_name   = "Bastion${count.index + 1}"
        admin_username  = "${var.VMAdminName}"
        admin_password  = "${var.VMAdminPassword}"

    }

    /*os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.OCPAdminName}/.ssh/authorized_keys"
      key_data = "${var.OCPPublicSSHKey}"
    }

    }*/

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}

# Creating virtual machine extension for Bastion

resource "azurerm_virtual_machine_extension" "CustomExtension-basicLinuxBastion" {
  count                = 1
  name                 = "CustomExtensionBastion"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxBastion${count.index +1}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.5"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxBastionVM"]

      settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/dfrappart/terraform/master/azure-basiclinux/deployansible.sh" ],
        "commandToExecute": "bash deployansible.sh"
    }
    SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}
