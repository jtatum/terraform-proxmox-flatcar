variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "${ssh_public_key}"
storage:
  files:
    - path: /etc/motd
      contents:
        inline: custom-template-marker
