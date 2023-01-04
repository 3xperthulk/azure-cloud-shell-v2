provider "azurerm" {
  features {}

  subscription_id = "bb1bb7fb-1a10-4932-ad07-6c495a180b42"
  client_id       = "e671a044-100d-433f-9612-e445ce5d3cce"
  client_secret   = "ffZ8Q~fKVfjDQlUCzWQ4X9UtsYH5vxKrDTKZvbr4"
  tenant_id       = "9ebf3598-ad1d-4b7d-a695-052c047690e0"
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    count                        = 1
    name                         = "myPublicIP${count.index}"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "INBOUND"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "OUTBOUND"
        priority                   = 1002
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    count                     = 1
    name                      = "myNIC${count.index}"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.*.id[count.index]  #[element(azurerm_public_ip.myterraformsubnet.*.id, count.index)]
    }

    tags = {
        environment = "Terraform Demo"
    }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "myterraformnic" {
    count = 1
    network_interface_id      = azurerm_network_interface.myterraformnic.*.id[count.index]
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    count                 = 1
    name                  = "kafka${count.index}"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [element(azurerm_network_interface.myterraformnic.*.id, count.index)]
    size                  = "Standard_B4ms"
    computer_name         = "kafka${count.index}"
    admin_username        = "kafkaadmin"
    disable_password_authentication = true

   # custom_data = filebase64("customdata.tpl")

    os_disk {
        name              = "myOsDisk${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }


    admin_ssh_key {
        username       = "kafkaadmin"
        public_key     = file("~/.ssh/id_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    provisioner "file" {
     connection {
        user = "kafkaadmin"
        type = "ssh"
        private_key = file("~/.ssh/id_rsa")
        timeout = "20m"
        agent = false
        host = self.public_ip_address
    }
    source      = "customdata.sh"
    destination = "/tmp/customdata.sh"
  }

  provisioner file {
    destination = "/etc/ssh/sshd_config"
    source      = "sshd_config"
  }

  provisioner remote-exec {
    inline = [
      "systemctl restart sshd", # This works Centos. If you use another OS, you must change this line.
    ]
  }
    provisioner "remote-exec" {
     connection {
        user = "kafkaadmin"
        type = "ssh"
        private_key = file("~/.ssh/id_rsa")
        timeout = "20m"
        agent = false
        host = self.public_ip_address
    }
    inline = [
      "sleep 120",
      "chmod +x /tmp/customdata.sh",
      "/tmp/customdata.sh",
    ]
  }

    tags = {
        environment = "Terraform Demo"
    }
}
