# Basic Example

A minimal example that provisions a single Flatcar Container Linux VM on Proxmox
using this module with mostly default settings (2 cores, 4096 MB RAM, DHCP
networking, SSH key read from `~/.ssh/id_rsa.pub`).

The module is referenced with a local relative `source` (`../../`) so the
example tracks the module in this repository. When copying this into your own
project, replace the `source` with a versioned reference, e.g.:

```hcl
module "flatcar_vm" {
  source = "github.com/jtatum/terraform-proxmox-flatcar"
  # ...
}
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Proxmox endpoint, API token, node, and VM ID

terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default |
| --- | --- | --- | --- |
| `proxmox_api_url` | Proxmox API URL | `string` | — |
| `proxmox_api_token_id` | Proxmox API token ID | `string` | — |
| `proxmox_api_token_secret` | Proxmox API token secret (sensitive) | `string` | — |
| `proxmox_node` | Proxmox node name | `string` | — |
| `vm_id` | Unique VM ID number | `number` | `900` |

## Outputs

| Name | Description |
| --- | --- |
| `vm_id` | The ID of the created VM |
| `vm_name` | The name of the created VM |
| `vm_ipv4_addresses` | IPv4 addresses assigned to the VM |

See the [root module README](../../README.md) for the full list of supported
variables (VM resources, storage, networking, custom Butane templates, etc.).
