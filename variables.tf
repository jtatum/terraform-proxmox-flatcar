# Proxmox Connection Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://proxmox.example.com:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., terraform@pve!mytoken)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (use true for self-signed certificates)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name where VM will be created"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (defaults to reading from ~/.ssh/id_rsa.pub). This value is passed to the Butane template as `$${ssh_public_key}` for custom templates."
  type        = string
  default     = ""
}

variable "butane_template_path" {
  description = "Path to custom Butane template file. If not provided, uses the default template bundled with the module. The template receives `$${ssh_public_key}` as a variable."
  type        = string
  default     = ""
}

# VM Configuration Variables
variable "vm_id" {
  description = "Unique VM ID number"
  type        = number
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "flatcar-vm"
}

variable "flatcar_image_url" {
  description = "URL to Flatcar image (will be downloaded to Proxmox)"
  type        = string
  default     = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img"
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 4096
}

variable "storage_pool" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan" {
  description = "VLAN ID for network device (optional)"
  type        = number
  default     = null
}

variable "vm_ip_config" {
  description = "IP configuration (e.g., 'ip=dhcp' or 'ip=192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "ip=dhcp"
}

variable "vm_onboot" {
  description = "Start VM on Proxmox boot"
  type        = bool
  default     = false
}
