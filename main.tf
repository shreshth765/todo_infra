resource "azurerm_resource_group" "rg" {
  name     = "RG_VM"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
    depends_on = [ azurerm_resource_group.rg ]
  name                = "VM_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "RG_VM"
}

resource "azurerm_subnet" "subnet" {
    depends_on = [ azurerm_virtual_network.vnet ]
  name                 = "subnet-vm"
  resource_group_name  = "RG_VM"
  virtual_network_name = "VM_vnet"
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "public_ip" {
    depends_on = [ azurerm_virtual_network.vnet ]
  name                = "vm-public-ip"
  location            = "West Europe"
  resource_group_name = "RG_VM"
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "NIC" {
  name                = "example-nic"
  location            = "West Europe"
  resource_group_name = "RG_VM"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
    depends_on = [ azurerm_subnet.subnet ]
  name                = "testvm-machine"
  resource_group_name = "RG_VM"
  location            = "West Europe"
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password = "Cloud@1234"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]
  disable_password_authentication = false

  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  custom_data = base64encode(<<EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
EOF
  )
}