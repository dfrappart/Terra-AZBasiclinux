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

    subscription_id = "${var.AzureSubscriptionID3}"
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

}


    #############################################
    # Rules Section
    #############################################

    # Rule for incoming HTTP from internet

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-HTTPIN" {

    name                        = "OK-http-Inbound"
    priority                    = 1100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "10.0.0.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.name}"
    
}
    
    # Rule for incoming HTTPS from internet

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-HTTPSIN" {

    name                        = "AlltoFrontEnd-OK-HTTPSIN"
    priority                    = 1101
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "443"
    source_address_prefix       = "*"
    destination_address_prefix  = "10.0.0.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.name}"  

}   


    # Rule for incoming SSH from Bastion

resource "azurerm_network_security_rule" "BastiontoFrontEnd-OK-SSHIN" {

    name                        = "BastiontoFrontEnd-OK-SSHIN"
    priority                    = 1102
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "10.0.2.0/24"
    destination_address_prefix  = "10.0.0.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.name}"

}


    #Rule for outbound to Internet traffic

resource "azurerm_network_security_rule" "FrontEndtoInternet-OK-All" {

    name                        = "FrontEndtoInternet-OK-All"
    priority                    = 1103
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "10.0.0.0/24"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.name}"


}

 # Rule for incoming SSH from Internet
/*
resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-SSHIN" {

    name                        = "BastiontoFrontEnd-OK-SSHIN"
    priority                    = 1104
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "10.0.0.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.name}"

}
*/

# Creating Subnet FrontEnd

resource "azurerm_subnet" "Subnet-BasicLinuxFrontEnd" {

    name = "Subnet-BasicLinuxFrontEnd"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    virtual_network_name        = "${azurerm_virtual_network.vNET-BasicLinux.name}"
    address_prefix              = "10.0.0.0/24"
    network_security_group_id   = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxFrontEnd.id}"


}

# Creating NSG for Backend

resource "azurerm_network_security_group" "NSG-Subnet-BasicLinuxBackEnd" {

    name = "NSG-Subnet-BasicLinuxBackEnd"
    location = "${var.AzureRegion}"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"


}   
    #############################################
    # Rules Section
    #############################################


    # Rule for incoming MySQL from FE

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-MySQLIN" {

    name                       = "OK-http-Inbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"     
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBackEnd.name}"
    
}
    


    # Rule for incoming SSH from Bastion

resource "azurerm_network_security_rule" "BastiontoBackEnd-OK-SSHIN" {

    name                       = "BastiontoBackEnd-OK-SSHIN"
    priority                   = 1101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.1.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBackEnd.name}"

}


    #Rule for outbound to Internet traffic

resource "azurerm_network_security_rule" "BackEndtoInternet-OK-All" {

    name                       = "BackEndtoInternet-OK-All"
    priority                   = 1102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBackEnd.name}"

}

 # Rule for incoming SSH from Internet

resource "azurerm_network_security_rule" "AlltoBackEnd-OK-SSHIN" {

    name                       = "AlltoBackEnd-OK-SSHIN"
    priority                   = 1103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBackEnd.name}"

}


# Creating Subnet Backend

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

}

    #############################################
    # Rules Section
    #############################################

 # Rule for incoming SSH from Internet

resource "azurerm_network_security_rule" "AlltoBastion-OK-SSHIN" {

    name                       = "AlltoBastion-OK-SSHIN"
    priority                   = 1101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.0/24"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBastion.name}"

}

# Rule for outgoing internet traffic
resource "azurerm_network_security_rule" "BastiontoInternet-OK-All" {

    name                       = "BastiontoInternet-OK-All"
    priority                   = 1102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
    resource_group_name         = "${azurerm_resource_group.RSG-BasicLinux.name}"
    network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicLinuxBastion.name}"

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

resource "random_string" "PublicIPfqdnprefixFE" {

    

    length = 5
    special = false
    upper = false
    number = false
}

resource "azurerm_public_ip" "PublicIP-FrontEndBasicLinux" {

    name                            = "PublicIP-FrontEndBasicLinux"
    location                        = "${var.AzureRegion}"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    public_ip_address_allocation    = "static"
    domain_name_label               = "${random_string.PublicIPfqdnprefixFE.result}dvtweb"

    tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
    }

}

# Creating Public IP for Bastion

resource "random_string" "PublicIPfqdnprefixBastion" {



    length = 5
    special = false
    upper = false
    number = false
}

resource "azurerm_public_ip" "PublicIP-BastionBasicLinux" {

    name                            = "PublicIP-BastionBasicLinux"
    location                        = "${var.AzureRegion}"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    public_ip_address_allocation    = "static"
    domain_name_label               = "${random_string.PublicIPfqdnprefixBastion.result}dvtbastion"
    
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

resource "azurerm_lb_probe" "LB-WebFrontEnd-httpprobe" {

    name                = "LB-WebFrontEnd-httpprobe"
    resource_group_name = "${azurerm_resource_group.RSG-BasicLinux.name}"
    loadbalancer_id     = "${azurerm_lb.LB-WebFrontEndBasicLinux.id}"
    port                = 80


}

# Creating Load Balancer rules

resource "azurerm_lb_rule" "LB-WebFrondEndrule" {

    name                            = "LB-WebFrondEndrule"
    resource_group_name             = "${azurerm_resource_group.RSG-BasicLinux.name}"
    loadbalancer_id                 = "${azurerm_lb.LB-WebFrontEndBasicLinux.id}"
    protocol                        = "tcp"
    probe_id                        = "${azurerm_lb_probe.LB-WebFrontEnd-httpprobe.id}"
    frontend_port                   = 80
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

    os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.VMAdminName}/.ssh/authorized_keys"
      key_data = "${var.AzurePublicSSHKey}"
    }

    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}





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

    os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.VMAdminName}/.ssh/authorized_keys"
      key_data = "${var.AzurePublicSSHKey}"
    }

    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}




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

    os_profile_linux_config {
    
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.VMAdminName}/.ssh/authorized_keys"
      key_data = "${var.AzurePublicSSHKey}"
    }

    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
    }
    

}

# Creating virtual machine extension for Bastion

resource "azurerm_virtual_machine_extension" "CustomExtension-basicLinuxBastion" {
  count                = 1
  name                 = "CustomExtensionBastion-${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxBastion${count.index +1}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxBastionVM"]

      settings = <<SETTINGS
        {
        "fileUris": [ "https://raw.githubusercontent.com/dfrappart/Terra-AZBasiclinux/master/deployansible.sh" ],
        "commandToExecute": "bash deployansible.sh"
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}


# Creating virtual machine extension for FrontEnd

resource "azurerm_virtual_machine_extension" "CustomExtension-basicLinuxFrontEnd" {
  
  count                = 3
  name                 = "CustomExtensionFrontEnd-${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxWebFrontEnd${count.index +1}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.5"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxWebFrontEndVM"]

      settings = <<SETTINGS
        {   
        "fileUris": [ "https://raw.githubusercontent.com/dfrappart/Terra-AZBasiclinux/master/installapache.sh" ],
        "commandToExecute": "bash installapache.sh"
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine extension for Backend

resource "azurerm_virtual_machine_extension" "CustomExtension-basicLinuxBackEnd" {
  
  count                = 2
  name                 = "CustomExtensionBackEnd-${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "BasicLinuxDBBackEnd${count.index +1}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.5"
  depends_on           = ["azurerm_virtual_machine.BasicLinuxDBBackEndVM"]

      settings = <<SETTINGS
        {   
        "fileUris": [ "https://raw.githubusercontent.com/dfrappart/Terra-AZBasiclinux/master/installmysql.sh" ],
        "commandToExecute": "bash installmysql.sh"
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}


# Creating virtual machine Network watcher extension for Bastion

resource "azurerm_virtual_machine_extension" "Bastion-NetworkWatcherAgent" {
  

  count                = 1
  name                 = "NetworkWatcherAgent-Bastion${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicLinuxBastionVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"

      settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}


# Creating virtual machine Network watcher extension for FrontEnd

resource "azurerm_virtual_machine_extension" "FE-NetworkWatcherAgent" {
  

  count                = 3
  name                 = "NetworkWatcherAgent-Frontend${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicLinuxWebFrontEndVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"

      settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine Network watcher extension for Backend

resource "azurerm_virtual_machine_extension" "BE-NetworkWatcherAgent" {
  

  count                = 2
  name                 = "NetworkWatcherAgent-Backend${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RSG-BasicLinux.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicLinuxDBBackEndVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"

      settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS
    
  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}



#####################################################################################
# Output
#####################################################################################



output "Bastion Public IP" {

  value = "${azurerm_public_ip.PublicIP-BastionBasicLinux.ip_address}"
}

output "Bastion FQDN" {

  value = "${azurerm_public_ip.PublicIP-BastionBasicLinux.fqdn}"
}

output "Azure LB Public IP" {

  value = "${azurerm_public_ip.PublicIP-FrontEndBasicLinux.ip_address}"
}

output "Azure Web LB FQDN " {

  value = "${azurerm_public_ip.PublicIP-FrontEndBasicLinux.fqdn}"
}

output "DB VM Private IP" {
    
  value = ["${element(azurerm_network_interface.DBBackEndNIC.*.private_ip_address, 1)}","${element(azurerm_network_interface.DBBackEndNIC.*.private_ip_address, 2)}"]
}

output "FE VM Private IP" {
    
    value = ["${element(azurerm_network_interface.WebFrontEndNIC.*.private_ip_address, 1)}","${element(azurerm_network_interface.WebFrontEndNIC.*.private_ip_address, 2)}","${element(azurerm_network_interface.WebFrontEndNIC.*.private_ip_address, 3)}"]
}


output "Web Load Balancer FE IP Config Name" {

    value = "${azurerm_lb.LB-WebFrontEndBasicLinux.frontend_ip_configuration}"
}

