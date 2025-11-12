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
        inline: flatcar-vm
    - path: /home/core/welcome.txt
      mode: 0644
      user:
        name: core
      group:
        name: core
      contents:
        inline: |
          Welcome to Flatcar Container Linux!
          This VM was provisioned with Terraform + Butane/Ignition.
systemd:
  units:
    - name: docker.service
      enabled: true
