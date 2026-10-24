# Passwordless SSH: Windows PowerShell to Ansible Control Node

## Table of Contents

1. [Lab information](#1-lab-information)
2. [How passwordless SSH works](#2-how-passwordless-ssh-works)
3. [Test normal SSH access](#3-test-normal-ssh-access)
4. [Check the Windows SSH directory](#4-check-the-windows-ssh-directory)
5. [Generate the SSH key](#5-generate-the-ssh-key)
6. [Understand the two key files](#6-understand-the-two-key-files)
7. [Install the public key on the Ansible server](#7-install-the-public-key-on-the-ansible-server)
8. [Test passwordless SSH](#8-test-passwordless-ssh)
9. [Create an SSH alias](#9-create-an-ssh-alias)
10. [Use the alias with SCP](#10-use-the-alias-with-scp)
11. [Use the alias with VS Code Remote SSH](#11-use-the-alias-with-vs-code-remote-ssh)
12. [Verify permissions and SELinux context](#12-verify-permissions-and-selinux-context)
13. [Troubleshooting](#13-troubleshooting)
14. [Security recommendations](#14-security-recommendations)
15. [Quick command reference](#15-quick-command-reference)
16. [Final result](#16-final-result)

---

## 1. Lab information

| Item | Value |
|---|---|
| Client computer | Windows PowerShell |
| Windows user | `krmar` |
| Ansible control node IP | `192.168.1.233` |
| Remote SSH user | `ansibleadmin` |
| Control-node hostname | `ansible-server.nitclasses.com` |
| SSH port | `22` |
| Optional SSH alias | `ansible-control` |

This key connection is used for:

```text
Windows laptop → Ansible control node
```

It is different from the SSH key used for:

```text
Ansible control node → managed nodes
```

---

## 2. How passwordless SSH works

SSH key authentication uses a key pair:

- The **private key** remains on the Windows computer.
- The **public key** is added to the remote user's `authorized_keys` file.
- During login, the server confirms that the Windows client possesses the matching private key.
- The private key is never copied to the server.

The relevant paths will be:

```text
Windows private key:
C:\Users\krmar\.ssh\id_ed25519

Windows public key:
C:\Users\krmar\.ssh\id_ed25519.pub

Server authorized keys:
/home/ansibleadmin/.ssh/authorized_keys
```

---

## 3. Test normal SSH access

Open Windows PowerShell and run:

```powershell
ssh ansibleadmin@192.168.1.233
```

Enter the password for `ansibleadmin`.

After connecting, verify:

```bash
whoami
hostname
```

Expected results should identify:

```text
ansibleadmin
ansible-server.nitclasses.com
```

Exit the server:

```bash
exit
```

Password-based SSH must work before the public key can be installed through SSH.

---

## 4. Check the Windows SSH directory

Run in PowerShell:

```powershell
Get-ChildItem "$HOME\.ssh" -Force
```

The directory is normally:

```text
C:\Users\krmar\.ssh
```

If it does not exist, create it:

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh"
```

---

## 5. Generate the SSH key

Use the simple command requested for this lab:

```powershell
ssh-keygen
```

The program asks:

```text
Enter file in which to save the key (C:\Users\krmar/.ssh/id_ed25519):
```

Press **Enter** to accept the default path.

It then asks:

```text
Enter passphrase (empty for no passphrase):
```

For completely passwordless access in this personal lab, press **Enter** without typing a passphrase.

It asks again:

```text
Enter same passphrase again:
```

Press **Enter** again.

### Critical safety warning

If the following message appears:

```text
C:\Users\krmar\.ssh\id_ed25519 already exists.
Overwrite (y/n)?
```

Enter:

```text
n
```

Do not overwrite an existing key. That key might already provide access to other systems.

If an existing default key is present, inspect its public-key file and use it, or generate a separately named key only after deciding that a new key is required.

---

## 6. Understand the two key files

The simple `ssh-keygen` command normally creates:

```text
C:\Users\krmar\.ssh\id_ed25519
C:\Users\krmar\.ssh\id_ed25519.pub
```

| File | Purpose | May it be shared? |
|---|---|---|
| `id_ed25519` | Private key used to prove identity | **No** |
| `id_ed25519.pub` | Public key installed on servers | Yes |

Verify both files:

```powershell
Get-ChildItem "$HOME\.ssh\id_ed25519*"
```

Display only the public key:

```powershell
Get-Content "$HOME\.ssh\id_ed25519.pub"
```

It should normally begin with:

```text
ssh-ed25519
```

Never display, email, upload, or copy the contents of `id_ed25519`.

---

## 7. Install the public key on the Ansible server

Windows PowerShell does not normally provide `ssh-copy-id`. Use this command:

```powershell
Get-Content "$HOME\.ssh\id_ed25519.pub" |
ssh ansibleadmin@192.168.1.233 'umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; key=$(cat); grep -qxF "$key" ~/.ssh/authorized_keys || printf "%s\n" "$key" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
```

Enter the `ansibleadmin` password one final time.

The remote command performs these operations:

1. Applies a restrictive creation mask with `umask 077`.
2. Creates `/home/ansibleadmin/.ssh` if needed.
3. Creates `authorized_keys` if needed.
4. Reads the Windows public key from standard input.
5. Checks whether the exact key already exists.
6. Adds it only when it is missing.
7. Sets `.ssh` to permission `0700`.
8. Sets `authorized_keys` to permission `0600`.

The duplicate check is useful because running the command again will not keep adding the same key.

---

## 8. Test passwordless SSH

Test the normal command:

```powershell
ssh ansibleadmin@192.168.1.233
```

SSH automatically checks the default private-key name `id_ed25519`. You should now connect without the Linux account password.

After connecting:

```bash
whoami
hostname
```

Exit:

```bash
exit
```

You can also explicitly test the key:

```powershell
ssh -i "$HOME\.ssh\id_ed25519" -o IdentitiesOnly=yes ansibleadmin@192.168.1.233
```

If the explicit command works but the normal command does not, check the Windows SSH configuration and other identities being offered.

---

## 9. Create an SSH alias

An alias lets you replace this command:

```powershell
ssh ansibleadmin@192.168.1.233
```

with:

```powershell
ssh ansible-control
```

Open the Windows SSH configuration:

```powershell
notepad "$HOME\.ssh\config"
```

Add:

```sshconfig
Host ansible-control
    HostName 192.168.1.233
    User ansibleadmin
    IdentityFile C:/Users/krmar/.ssh/id_ed25519
    IdentitiesOnly yes
```

### Windows profile name contains a space

If the Windows profile is `C:\Users\windows 11`, do not leave the complete
path unquoted. The safest and recommended configuration is:

```sshconfig
Host ansible-control
    HostName 192.168.1.99
    User ansibleadmin
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

`~/.ssh/id_ed25519` automatically resolves to the current user's profile.
Alternatively, quote the complete path:

```sshconfig
IdentityFile "C:/Users/windows 11/.ssh/id_ed25519"
```

Verify the username, profile, and key:

```powershell
$env:USERNAME
$HOME
$env:USERPROFILE
Test-Path "$HOME\.ssh\id_ed25519"
Get-ChildItem "$HOME\.ssh" -Force
```

Verify and test:

```powershell
ssh -G ansible-control |
Select-String "hostname|user|identityfile|identitiesonly"
ssh ansible-control
ssh -vvv ansible-control
```

Changing the Windows display name normally does not rename the profile folder.
Do not manually rename `C:\Users\windows 11`, because it can damage the
profile configuration. Using `~` avoids the issue. If a clean path is
required, create a new account with a simple name such as `ansiblelab`.

Save the filename exactly as:

```text
config
```

It must not be:

```text
config.txt
```

Verify:

```powershell
Get-ChildItem "$HOME\.ssh\config"
Get-Content "$HOME\.ssh\config"
```

Confirm how SSH resolves the alias:

```powershell
ssh -G ansible-control |
Select-String "hostname|user|identityfile|identitiesonly"
```

Important expected values:

```text
user ansibleadmin
hostname 192.168.1.233
identityfile C:/Users/krmar/.ssh/id_ed25519
identitiesonly yes
```

Test:

```powershell
ssh ansible-control
```

---

## 10. Use the alias with SCP

Copy a playbook from Windows to the Ansible server:

```powershell
scp .\playbook.yml ansible-control:/home/ansibleadmin/automation/playbooks/
```

Copy a playbook from the server back to the current Windows directory:

```powershell
scp ansible-control:/home/ansibleadmin/automation/playbooks/playbook.yml .
```

Copy a directory recursively:

```powershell
scp -r .\playbooks ansible-control:/home/ansibleadmin/automation/
```

---

## 11. Use the alias with VS Code Remote SSH

1. Open VS Code.
2. Install the Microsoft **Remote - SSH** extension if needed.
3. Press `Ctrl+Shift+P`.
4. Run **Remote-SSH: Connect to Host...**.
5. Select `ansible-control`.
6. Select **Linux** if VS Code asks for the platform.
7. Open `/home/ansibleadmin/automation`.

VS Code uses the same Windows SSH configuration and private key.

On the Rocky Linux control node, install the archive utilities needed by VS Code Server:

```bash
sudo dnf install -y tar gzip
```

---

## 12. Verify permissions and SELinux context

Connect to the server:

```powershell
ssh ansible-control
```

Check permissions:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Expected permission patterns:

```text
drwx------  .ssh
-rw-------  authorized_keys
```

Correct them if required:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
```

On Rocky Linux, restore the SELinux contexts:

```bash
sudo restorecon -Rv /home/ansibleadmin/.ssh
```

---

## 13. Troubleshooting

### It still asks for the account password

Use verbose debugging from PowerShell:

```powershell
ssh -vvv ansible-control
```

Look for lines such as:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

Confirm that the private key exists:

```powershell
Test-Path "$HOME\.ssh\id_ed25519"
```

Expected:

```text
True
```

Confirm that the Windows public key appears on the server:

```bash
cat ~/.ssh/authorized_keys
```

### The key works only when `-i` is used

Test explicitly:

```powershell
ssh -i "$HOME\.ssh\id_ed25519" -o IdentitiesOnly=yes ansibleadmin@192.168.1.233
```

Then confirm that the SSH configuration points to the same key:

```powershell
ssh -G ansible-control | Select-String "identityfile"
```

### `Could not resolve hostname ansible-control`

Confirm that the configuration file is named `config`, not `config.txt`:

```powershell
Get-ChildItem "$HOME\.ssh" -Force
```

If necessary:

```powershell
Rename-Item "$HOME\.ssh\config.txt" "config"
```

### `Permission denied (publickey,password)`

On the server, confirm:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
sudo restorecon -Rv /home/ansibleadmin/.ssh
```

### Check the SSH server configuration

```bash
sudo /usr/sbin/sshd -T |
grep -E 'pubkeyauthentication|authorizedkeysfile|passwordauthentication'
```

Important expected settings include:

```text
pubkeyauthentication yes
authorizedkeysfile .ssh/authorized_keys
```

### Validate before restarting SSH

Only restart SSH if its configuration was changed. First validate it:

```bash
sudo /usr/sbin/sshd -t
```

No output normally means the configuration syntax is valid.

Then restart if required:

```bash
sudo systemctl restart sshd
```

### Port 22 connection test

From PowerShell:

```powershell
Test-NetConnection 192.168.1.233 -Port 22
```

The important result is:

```text
TcpTestSucceeded : True
```

---

## 14. Security recommendations

- Never share `id_ed25519`; it is the private key.
- Only copy `id_ed25519.pub` to servers.
- Do not overwrite an existing key without understanding where it is used.
- Accept a server host key only after confirming the server identity.
- An empty passphrase is convenient for a private lab but provides less protection if the private key is stolen.
- For production use, protect the private key with a passphrase and use `ssh-agent`.
- Do not enable direct root SSH login simply to avoid using `sudo`.
- Keep `.ssh` at permission `0700` and `authorized_keys` at `0600` on Linux.

---

## 15. Quick command reference

### Windows PowerShell

```powershell
# Test normal SSH
ssh ansibleadmin@192.168.1.233

# Check the SSH directory
Get-ChildItem "$HOME\.ssh" -Force

# Generate the default SSH key pair
ssh-keygen

# Verify the generated files
Get-ChildItem "$HOME\.ssh\id_ed25519*"

# Display only the public key
Get-Content "$HOME\.ssh\id_ed25519.pub"

# Install the public key on the server
Get-Content "$HOME\.ssh\id_ed25519.pub" |
ssh ansibleadmin@192.168.1.233 'umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; key=$(cat); grep -qxF "$key" ~/.ssh/authorized_keys || printf "%s\n" "$key" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'

# Test passwordless SSH
ssh ansibleadmin@192.168.1.233

# Open the SSH config
notepad "$HOME\.ssh\config"

# Inspect resolved alias options
ssh -G ansible-control |
Select-String "hostname|user|identityfile|identitiesonly"

# Use the alias
ssh ansible-control

# Debug the connection
ssh -vvv ansible-control
```

### Ansible control node

```bash
# Check SSH file permissions
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys

# Correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh

# Restore Rocky Linux SELinux contexts
sudo restorecon -Rv /home/ansibleadmin/.ssh

# Check the effective SSH server configuration
sudo /usr/sbin/sshd -T |
grep -E 'pubkeyauthentication|authorizedkeysfile|passwordauthentication'

# Validate the SSH server configuration
sudo /usr/sbin/sshd -t
```

---

## 16. Final result

Before configuration:

```powershell
ssh ansibleadmin@192.168.1.233
```

The server requested the Linux account password.

After configuration, either of these commands should connect without requesting that password:

```powershell
ssh ansibleadmin@192.168.1.233
```

or:

```powershell
ssh ansible-control
```

The default `id_ed25519` filename makes this setup simple because OpenSSH automatically checks that key during authentication.
