terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.13"
    }
  }
}

module "flatcar_vm" {
  source = "../../"

  # Proxmox connection
  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_node             = var.proxmox_node

  # VM configuration
  vm_id        = var.vm_id
  vm_name      = "flatcar-basic"
  vm_cores     = 2
  vm_memory    = 4096
  vm_ip_config = "ip=dhcp"
}

