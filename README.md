# Terraform Proxmox Flatcar Module

A Terraform module for creating Flatcar Container Linux VMs on Proxmox using the bpg/proxmox provider with Butane/Ignition configuration.

## Features

- **Fully declarative**: 100% native Terraform resources (no SSH commands)
- **Automatic image download**: Flatcar image downloaded directly from CDN to Proxmox
- **Butane/Ignition support**: Cloud-init configuration via Ignition
- **Clean state management**: All resources properly tracked in Terraform state
- **Customizable Butane template**: Bring your own Butane configuration or use the included default

## Prerequisites

- Terraform >= 1.0
- Access to a Proxmox server with API token authentication
- SSH access to Proxmox host (for provider file operations)

## Usage

### Basic Example

```hcl
module "flatcar_vm" {
  source = "github.com/yourusername/terraform-proxmox-flatcar"

  # Proxmox connection
  proxmox_api_url          = "https://proxmox.example.com:8006/api2/json"
  proxmox_api_token_id     = "terraform@pve!mytoken"
  proxmox_api_token_secret = var.proxmox_token_secret
  proxmox_tls_insecure     = true
  proxmox_node             = "pve"

  # VM configuration
  vm_id   = 100
  vm_name = "flatcar-vm"

  # Optional: use a different SSH key
  # ssh_public_key = file("~/.ssh/custom_key.pub")
}

# Access the VM IP addresses
output "vm_ips" {
  value = module.flatcar_vm.vm_ipv4_addresses
}
```

### Advanced Example with Custom Resources

```hcl
module "flatcar_vm" {
  source = "github.com/yourusername/terraform-proxmox-flatcar"

  proxmox_api_url          = "https://proxmox.example.com:8006/api2/json"
  proxmox_api_token_id     = "terraform@pve!mytoken"
  proxmox_api_token_secret = var.proxmox_token_secret
  proxmox_node             = "pve"

  vm_id     = 100
  vm_name   = "flatcar-k8s-node"
  vm_cores  = 4
  vm_memory = 8192

  # Static IP configuration
  vm_ip_config = "ip=192.168.1.100/24,gw=192.168.1.1"

  # Custom network
  network_bridge = "vmbr1"
  network_vlan   = 10

  # Different storage
  storage_pool = "nvme-pool"

  # Start VM on Proxmox boot
  vm_onboot = true
}
```

## Proxmox Setup

### 1. Create a Terraform User (Recommended)

It's best practice to create a dedicated user for Terraform rather than using root:

1. Log into Proxmox web interface
2. Go to **Datacenter > Permissions > Users**
3. Click **Add** and create a user (e.g., `terraform@pve`)

### 2. Configure Permissions

Grant the necessary permissions to your Terraform user:

1. Go to **Datacenter > Permissions**
2. Click **Add > User Permission**
3. Select:
   - Path: `/` (root)
   - User: `terraform@pve`
   - Role: Select or create a role with these privileges:
     - VM.Allocate
     - VM.Config.*
     - Datastore.Allocate
     - Datastore.AllocateSpace
     - Pool.Allocate (if using pools)
     - SDN.Use (if using SDN)

For simplicity during testing, you can use the built-in `PVEAdmin` role, but a custom role with minimal permissions is recommended for production.

### 3. Create API Token

Create an API token for Terraform authentication:

1. Go to **Datacenter > Permissions > API Tokens**
2. Click **Add**
3. Configure:
   - User: Select your terraform user (e.g., `terraform@pve`)
   - Token ID: Give it a name (e.g., `terraform-token`)
   - Privilege Separation: Uncheck this box (so the token inherits user permissions)
4. Click **Add**
5. **IMPORTANT**: Copy the token secret immediately - it won't be shown again
   - Token ID format: `terraform@pve!terraform-token`
   - Token Secret: A long UUID string

### 4. Configure SSH Access

The bpg/proxmox provider requires SSH access for file operations. Set up passwordless SSH:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "terraform"

# Copy your public key to Proxmox
ssh-copy-id root@proxmox.example.com
```

**Note**: SSH access is used by the provider for:
- Uploading cloud-init/Ignition snippets
- Downloading VM images to the datastore

The provider uses your SSH agent, so no passwords are stored in Terraform.

## Module Files

- [main.tf](main.tf): Main Terraform configuration with providers, Butane compilation, and VM creation
- [variables.tf](variables.tf): Input variable definitions
- [outputs.tf](outputs.tf): Output definitions for VM information
- [butane-config.yaml.tpl](butane-config.yaml.tpl): Default Butane template (SSH keys injected automatically, converted to Ignition)
- [terraform.tfvars.example](terraform.tfvars.example): Example configuration for reference

## How It Works

1. **SSH Key Injection**: Your SSH public key is read from `~/.ssh/id_rsa.pub` (or from the `ssh_public_key` variable)
2. **Butane Template Rendering**: The Butane template is rendered with your SSH key injected
3. **Butane to Ignition**: The CT provider converts the rendered Butane YAML config to Ignition JSON
4. **Upload Ignition Snippet**: The Ignition config is uploaded to Proxmox as a cloud-init snippet
5. **Download Flatcar Image**: The provider downloads the Flatcar image from the CDN to Proxmox datastore
6. **Create VM**: A VM is created using the bpg/proxmox provider with:
   - The imported Flatcar image as the boot disk
   - Cloud-init configured with the Ignition snippet
   - Specified CPU, memory, and network settings
7. **Start VM**: The VM starts automatically and Ignition provisions it on first boot
8. **IP Detection**: Once the VM boots, the QEMU guest agent reports IP addresses to Terraform

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `proxmox_api_url` | Proxmox API URL | `string` | n/a | yes |
| `proxmox_api_token_id` | Proxmox API token ID | `string` | n/a | yes |
| `proxmox_api_token_secret` | Proxmox API token secret | `string` | n/a | yes |
| `proxmox_node` | Proxmox node name | `string` | n/a | yes |
| `vm_id` | Unique VM ID number | `number` | n/a | yes |
| `proxmox_tls_insecure` | Skip TLS verification | `bool` | `true` | no |
| `vm_name` | Name of the virtual machine | `string` | `"flatcar-vm"` | no |
| `flatcar_image_url` | URL to Flatcar image | `string` | `"https://stable.release.flatcar-linux.net/..."` | no |
| `vm_cores` | Number of CPU cores | `number` | `2` | no |
| `vm_memory` | Amount of memory in MB | `number` | `4096` | no |
| `storage_pool` | Storage pool name | `string` | `"local-lvm"` | no |
| `network_bridge` | Network bridge to use | `string` | `"vmbr0"` | no |
| `network_vlan` | VLAN ID for network device | `number` | `null` | no |
| `vm_ip_config` | IP configuration (e.g., `ip=dhcp` or `ip=192.168.1.100/24,gw=192.168.1.1`) | `string` | `"ip=dhcp"` | no |
| `vm_onboot` | Start VM on Proxmox boot | `bool` | `false` | no |
| `ssh_public_key` | SSH public key for VM access | `string` | `""` (reads from `~/.ssh/id_rsa.pub`) | no |
| `butane_template_path` | Path to custom Butane template file | `string` | `""` (uses bundled default) | no |

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | The ID of the created VM |
| `vm_name` | The name of the created VM |
| `vm_status` | The status of the VM (running/stopped) |
| `proxmox_node` | The Proxmox node where the VM is located |
| `vm_ipv4_addresses` | IPv4 addresses assigned to the VM |
| `ignition_config` | The generated Ignition configuration (sensitive) |

## Customization

### Custom Butane Configuration

The module includes a default [butane-config.yaml.tpl](butane-config.yaml.tpl) that:
- Configures the `core` user with your SSH key
- Enables Docker
- Creates a welcome file

To use your own Butane configuration, pass the `butane_template_path` variable:

```hcl
module "flatcar_vm" {
  source = "github.com/yourusername/terraform-proxmox-flatcar"

  # ... other required variables ...

  # Use your custom Butane template
  butane_template_path = "${path.module}/my-butane-config.yaml.tpl"
}
```

Your template file will receive the `${ssh_public_key}` variable automatically. Example custom template:

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "${ssh_public_key}"
storage:
  files:
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: my-custom-hostname
systemd:
  units:
    - name: docker.service
      enabled: true
    - name: my-app.service
      enabled: true
      contents: |
        [Unit]
        Description=My Application
        After=docker.service
        Requires=docker.service
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/docker run my-app
        [Install]
        WantedBy=multi-user.target
```

See the [Butane documentation](https://coreos.github.io/butane/) for all available options.

### SSH Key Configuration

By default, the module reads your SSH public key from `~/.ssh/id_rsa.pub`. To use a different key:

```hcl
module "flatcar_vm" {
  source = "github.com/yourusername/terraform-proxmox-flatcar"
  # ...
  ssh_public_key = file("~/.ssh/custom_key.pub")
}
```

## Troubleshooting

- **TLS certificate errors**: Set `proxmox_tls_insecure = true` for self-signed certificates
- **Permission errors**: Ensure your API token has sufficient privileges
- **SSH connection refused**: Verify passwordless SSH access to the Proxmox host
- **Image download fails**: Check that Proxmox can reach the Flatcar CDN URL, or specify a different `flatcar_image_url`
- **VM already exists**: Choose a different `vm_id` if the ID is already in use
- **Butane syntax errors**: Validate your Butane config at https://coreos.github.io/butane/
- **VM won't boot**: Check Ignition logs in the VM console: `journalctl -u ignition*`
- **No IP addresses in output**: Wait for the VM to boot and the QEMU guest agent to start

## Architecture

This module uses the **bpg/proxmox** provider which offers several advantages:

- **No manual SSH commands**: All operations use native Terraform resources
- **Proper state tracking**: VM lifecycle fully managed by Terraform
- **Automatic downloads**: Images downloaded directly from URLs
- **Built-in file uploads**: Snippets uploaded via provider, not manual scp
- **Better resource management**: Disks, networks, cloud-init all declarative

The provider requires SSH access for internal file operations, which it handles automatically via the configured SSH agent.

## Security Notes

- Never commit API tokens or secrets to version control
- Use environment variables or a secrets manager for sensitive values
- The module does not create or manage `.tfvars` files - handle secrets in your implementation repo
- SSH access is required for the provider but uses your SSH agent for key management
