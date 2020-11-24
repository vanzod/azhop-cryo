provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length = 8
  special = false
}

resource "random_string" "resource_postfix" {
  length = 6
  special = false
  upper = false
  lower = true
  number = true
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}