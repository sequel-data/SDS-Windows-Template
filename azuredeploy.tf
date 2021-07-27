#Resource Groups
resource "azurerm_resource_group" "rg1" {
  name     = var.azure-rg-1
  location = var.loc1

}
#VNETs and Subnets
#Hub VNET and Subnets
resource "azurerm_virtual_network" "region1-vnet1-hub1" {
  name                = var.region1-vnet1-name
  location            = var.loc1
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = [var.region1-vnet1-address-space]
  dns_servers         = ["10.10.1.4", "168.63.129.16", "8.8.8.8"]

}
resource "azurerm_subnet" "region1-vnet1-snet1" {
  name                 = var.region1-vnet1-snet1-name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.region1-vnet1-hub1.name
  address_prefixes     = [var.region1-vnet1-snet1-range]

}
#Lab NSG
resource "azurerm_network_security_group" "region1-nsg" {
  name                = "region1-nsg"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "RDP-In"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
   }
}
#NSG Association to all Lab Subnets
resource "azurerm_subnet_network_security_group_association" "vnet1-snet1" {
  subnet_id                 = azurerm_subnet.region1-vnet1-snet1.id
  network_security_group_id = azurerm_network_security_group.region1-nsg.id
}
#Public IP
resource "azurerm_public_ip" "region1-vm01-pip" {
  name                = "region1-vm01-pip"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.loc1
  allocation_method   = "Static"
  sku                 = "Standard"
}
#Create NIC and associate the Public IP
resource "azurerm_network_interface" "region1-vm01-nic" {
  name                = "region1-vm01-nic"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.rg1.name
 ip_configuration {
    name                          = "region1-vm01-ipconfig"
    subnet_id                     = azurerm_subnet.region1-vnet1-snet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.region1-vm01-pip.id
  }
}
#Create VM
resource "azurerm_virtual_machine" "region1-vm01-vm" {
  name                = "region1-vm01-vm"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.loc1
  vm_size             = var.vmsize
  network_interface_ids = [azurerm_network_interface.region1-vm01-nic.id]
  
  #source_image_reference {
  #  publisher = "MicrosoftWindowsServer"
  #  offer     = "WindowsServer"
  #  sku       = "2019-Datacenter"
  #  version   = "latest"
  #}
  storage_os_disk {
    name          = "osdisk"
    vhd_uri       = "https://cscustomimages.blob.core.windows.net/cscustomimages/WinSrv2019Std.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }
  os_profile {
      computer_name = azurerm_virtual_machine.region1-vm01-vm.name
      admin_username = var.adminusername
      admin_password = var.adminpassword
 }
}