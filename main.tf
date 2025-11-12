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

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure

  ssh {
    agent    = true
    username = "root"
  }
}

# Read Butane configuration from template
# Template variables available to Butane templates:
#   - ssh_public_key: SSH public key for VM access
locals {
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : trimspace(file("~/.ssh/id_rsa.pub"))

  # Use custom template if provided, otherwise use default bundled template
  template_path = var.butane_template_path != "" ? var.butane_template_path : "${path.module}/butane-config.yaml.tpl"

  butane_config = templatefile(local.template_path, {
    ssh_public_key = local.ssh_public_key
  })
}

# Generate Ignition config from Butane
data "ct_config" "ignition" {
  content = local.butane_config
  strict  = true
}

# Upload Ignition config as snippet to Proxmox using bpg provider
resource "proxmox_virtual_environment_file" "ignition_snippet" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data      = data.ct_config.ignition.rendered
    file_name = "user-data-vm-${var.vm_id}.yml"
  }
}

# Download and import Flatcar image directly from CDN
resource "proxmox_virtual_environment_download_file" "flatcar_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = var.flatcar_image_url
  file_name    = "flatcar_production_proxmoxve_image.qcow2"

}

# Create and configure VM using native Proxmox provider
resource "proxmox_virtual_environment_vm" "flatcar_vm" {
  vm_id     = var.vm_id
  name      = var.vm_name
  node_name = var.proxmox_node

  on_boot = var.vm_onboot
  started = true

  cpu {
    cores = var.vm_cores
  }

  memory {
    dedicated = var.vm_memory
  }

  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.network_vlan
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    import_from  = proxmox_virtual_environment_download_file.flatcar_image.id
    file_format  = "raw"
    size         = 10
  }

  boot_order = ["scsi0"]

  initialization {
    datastore_id = var.storage_pool
    interface    = "ide2"
    ip_config {
      ipv4 {
        address = var.vm_ip_config == "ip=dhcp" ? "dhcp" : split(",", replace(var.vm_ip_config, "ip=", ""))[0]
        gateway = var.vm_ip_config == "ip=dhcp" ? null : try(split("=", split(",", var.vm_ip_config)[1])[1], null)
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.ignition_snippet.id
  }
}
