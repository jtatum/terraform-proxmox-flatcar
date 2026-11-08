# Plan-only tests with mocked providers: no Proxmox host or credentials needed.
# Run with: terraform init -backend=false && terraform test

mock_provider "proxmox" {}
mock_provider "ct" {}

variables {
  proxmox_api_url          = "https://proxmox.example.com:8006/api2/json"
  proxmox_api_token_id     = "terraform@pve!test"
  proxmox_api_token_secret = "test-secret"
  proxmox_node             = "pve"
  vm_id                    = 123
  ssh_public_key           = "ssh-ed25519 AAAATESTKEY test@example"
}

run "dhcp_by_default" {
  command = plan

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].address == "dhcp"
    error_message = "ip=dhcp should configure DHCP"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].gateway == null
    error_message = "DHCP should not set a gateway"
  }
}

run "static_address_and_gateway" {
  command = plan

  variables {
    vm_ip_config = "ip=192.168.1.100/24,gw=192.168.1.1"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].address == "192.168.1.100/24"
    error_message = "static address was not parsed from vm_ip_config"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].gateway == "192.168.1.1"
    error_message = "gateway was not parsed from vm_ip_config"
  }
}

run "static_address_without_gateway" {
  command = plan

  variables {
    vm_ip_config = "ip=10.0.0.5/16"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].address == "10.0.0.5/16"
    error_message = "static address was not parsed from vm_ip_config"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.initialization[0].ip_config[0].ipv4[0].gateway == null
    error_message = "a missing gw= should leave the gateway unset"
  }
}

run "butane_receives_ssh_key_and_snippet_is_per_vm" {
  command = plan

  assert {
    condition     = strcontains(data.ct_config.ignition.content, "\"ssh-ed25519 AAAATESTKEY test@example\"")
    error_message = "the SSH public key was not rendered into the Butane config"
  }

  assert {
    condition     = proxmox_virtual_environment_file.ignition_snippet.source_raw[0].file_name == "user-data-vm-123.yml"
    error_message = "the Ignition snippet name should be derived from vm_id"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.flatcar_vm.vm_id == 123 && proxmox_virtual_environment_vm.flatcar_vm.node_name == "pve"
    error_message = "VM id and node were not passed through"
  }
}

run "custom_butane_template" {
  command = plan

  variables {
    butane_template_path = "./tests/fixtures/custom.yaml.tpl"
  }

  assert {
    condition     = strcontains(data.ct_config.ignition.content, "custom-template-marker") && strcontains(data.ct_config.ignition.content, "AAAATESTKEY")
    error_message = "butane_template_path was not used, or did not receive ssh_public_key"
  }
}

run "hostname_follows_vm_name" {
  command = plan

  variables {
    vm_name = "worker-01"
  }

  assert {
    condition     = strcontains(data.ct_config.ignition.content, "inline: worker-01") && !strcontains(data.ct_config.ignition.content, "inline: flatcar-vm")
    error_message = "the guest hostname should match vm_name"
  }
}
