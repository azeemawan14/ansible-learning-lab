# SSH Custom Key Filename for Ansible — Study Notes

## Lab information

- Control-node user: `ansibleadmin`
- Control node: `ansible-server.nitclasses.com`
- Private key: `/home/ansibleadmin/.ssh/ansible-key`
- Public key: `/home/ansibleadmin/.ssh/ansible-key.pub`

| Managed node | IP address |
|---|---|
| `node1` | `192.168.1.154` |
| `node2` | `192.168.1.185` |
| `node3` | `192.168.1.190` |

## Why SSH requested a password

This command worked without a password:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

But this command requested a password:

```bash
ssh node1
```

The reason is that `ansible-key` is a custom filename. SSH automatically tries common private-key names such as `id_ed25519`, but it does not automatically know that it should use `~/.ssh/ansible-key`.

Giving the key a custom name was **not a mistake**. SSH simply needs to be told which key to use through one of these methods:

1. The `-i` command-line option
2. The SSH client configuration file
3. Ansible's `private_key_file` setting

## Key filename versus key comment

These are different things:

- `ansible-key` is the private-key **filename**.
- `ansible-key.pub` is the public-key **filename**.
- Text such as `ansibleadmin@ansible-server.nitclasses.com` at the end of a public key is only a **comment or label**.

The comment helps identify who created the key. It does not control authentication and does not need to match the key filename.

## Manually installing a public key

Manually adding the contents of `ansible-key.pub` to the managed node's `~/.ssh/authorized_keys` file is valid. `ssh-copy-id` is only a convenient and safer way to perform the same basic task.

Recommended command:

```bash
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node1
```

Repeat it for the other nodes:

```bash
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node2
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node3
```

It is normal for `authorized_keys` to contain multiple public keys. For example, one key can belong to the Ansible control node and another can belong to a Windows workstation.

## Recommended method: SSH client configuration

Create or edit the configuration file on the Ansible control node:

```bash
vim ~/.ssh/config
```

Add:

```sshconfig
Host node1 node1.nitclasses.com 192.168.1.154
    HostName 192.168.1.154
    User ansibleadmin
    IdentityFile ~/.ssh/ansible-key
    IdentitiesOnly yes

Host node2 node2.nitclasses.com 192.168.1.185
    HostName 192.168.1.185
    User ansibleadmin
    IdentityFile ~/.ssh/ansible-key
    IdentitiesOnly yes

Host node3 node3.nitclasses.com 192.168.1.190
    HostName 192.168.1.190
    User ansibleadmin
    IdentityFile ~/.ssh/ansible-key
    IdentitiesOnly yes
```

Protect the file:

```bash
chmod 600 ~/.ssh/config
```

Now the short commands should use the correct key automatically:

```bash
ssh node1
ssh node2
ssh node3
```

`IdentitiesOnly yes` tells SSH to use the configured identity instead of trying unrelated keys.

## Configure the key in Ansible

For a project located at `~/automation`, use the following in `~/automation/ansible.cfg`:

```ini
[defaults]
inventory = ./inventory/nodes
host_key_checking = True
remote_user = ansibleadmin
ask_pass = False
private_key_file = /home/ansibleadmin/.ssh/ansible-key

[privilege_escalation]
become_method = sudo
become_user = root
become_ask_pass = False
```

`private_key_file` gives Ansible the exact private key it should use for SSH connections. Using an absolute path avoids ambiguity.

The same setting can also be placed in the inventory:

```ini
[all:vars]
ansible_user = ansibleadmin
ansible_python_interpreter = /usr/bin/python3
ansible_ssh_private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

Usually, define a shared key in **one place**, preferably the project `ansible.cfg`. Avoid unnecessary duplication.

## Required permissions

On the control node:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ansible-key
chmod 644 ~/.ssh/ansible-key.pub
chmod 600 ~/.ssh/config
```

On each Rocky Linux managed node:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
restorecon -RFv ~/.ssh
```

The `restorecon` command repairs SELinux security contexts when necessary.

## Verification commands

Confirm that SSH works without asking for a password:

```bash
ssh -o BatchMode=yes node1 hostname
ssh -o BatchMode=yes node2 hostname
ssh -o BatchMode=yes node3 hostname
```

`BatchMode=yes` prevents SSH from prompting for a password. If key authentication fails, the command fails immediately.

Check which SSH settings will be used:

```bash
ssh -G node1 | grep -Ei '^(hostname|user|identityfile|identitiesonly)'
```

Inspect detailed SSH authentication troubleshooting output:

```bash
ssh -vvv node1
```

Check the public-key fingerprint on the control node:

```bash
ssh-keygen -lf ~/.ssh/ansible-key.pub
```

Check Ansible's active project configuration:

```bash
cd ~/automation
ansible-config dump --only-changed
```

Test one managed node:

```bash
ansible node1 -m ping
```

Test the complete three-tier group:

```bash
ansible three_tier_app -m ping
```

## Security recommendations

- Never share or commit the private file `ansible-key` to Git.
- Only copy the public file `ansible-key.pub` to managed nodes.
- Every administrator or learner should use a separate SSH key pair.
- Remove a person's public key from `authorized_keys` when access is no longer required.
- Keep `host_key_checking = True` so Ansible verifies the identity of managed nodes.

## Roman Urdu summary

`ansible-key` naam dena ghalti nahin thi. Yeh custom filename hai, is liye SSH ko batana hota hai ke kaunsi private key use karni hai. `-i` option, `~/.ssh/config`, ya Ansible ke `private_key_file` se yeh kaam kiya ja sakta hai. Behtareen daily-use setup yeh hai ke SSH config mein `IdentityFile ~/.ssh/ansible-key` likhein aur Ansible project config mein bhi private key ka absolute path rakhein.
