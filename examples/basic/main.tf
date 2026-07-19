terraform {
  required_version = ">= 1.0"
}

module "flatcar_vm" {
  source = "../.."

  proxmox_api_url          = "https://proxmox.example.com:8006/api2/json"
  proxmox_api_token_id     = "terraform@pve!example"
  proxmox_api_token_secret = "example-token-secret"
  proxmox_node             = "pve"

  vm_id   = 100
  vm_name = "flatcar-basic"

  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExampleExample user@example"
}
