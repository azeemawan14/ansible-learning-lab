# VS Code to Ansible Control Node — Study Bundle

This bundle documents two practical ways to work with Ansible files from Windows:

1. Write files locally in VS Code and transfer them with `scp`.
2. Use VS Code Remote - SSH to edit files directly on the Ansible control node.

The Remote SSH preparation includes installing the required Rocky Linux archive utilities:

```bash
sudo dnf install -y tar gzip
```

Start with [VS_Code_Ansible_SCP_and_Remote_SSH_Guide.md](VS_Code_Ansible_SCP_and_Remote_SSH_Guide.md).

## Bundle contents

- `VS_Code_Ansible_SCP_and_Remote_SSH_Guide.md` — complete study notes
- `examples/ssh-config.example` — corrected Windows SSH configuration
- `screenshots/` — screenshots from the actual Remote - SSH setup

The guide also documents the Rocky Linux 9 `ansible-lint` dependency error, enabling CRB, installing the missing dependency, and configuring VS Code lint validation.

> Security note: the bundle shows the **path** of a private key, but never contains a private key.
