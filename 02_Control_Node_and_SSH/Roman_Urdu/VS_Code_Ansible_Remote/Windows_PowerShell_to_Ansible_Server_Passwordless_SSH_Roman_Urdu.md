# Passwordless SSH: Windows PowerShell se Ansible Control Node — Roman Urdu

## Fehrist (Table of Contents)

1. [Lab ki maloomat](#1-lab-ki-maloomat)
2. [Passwordless SSH kaise kaam karta hai?](#2-passwordless-ssh-kaise-kaam-karta-hai)
3. [Normal SSH access test karein](#3-normal-ssh-access-test-karein)
4. [Windows SSH directory check karein](#4-windows-ssh-directory-check-karein)
5. [SSH key generate karein](#5-ssh-key-generate-karein)
6. [Dono key files ko samjhein](#6-dono-key-files-ko-samjhein)
7. [Public key Ansible server par install karein](#7-public-key-ansible-server-par-install-karein)
8. [Passwordless SSH test karein](#8-passwordless-ssh-test-karein)
9. [SSH alias banayen](#9-ssh-alias-banayen)
10. [Alias ko SCP ke saath use karein](#10-alias-ko-scp-ke-saath-use-karein)
11. [Alias ko VS Code Remote SSH ke saath use karein](#11-alias-ko-vs-code-remote-ssh-ke-saath-use-karein)
12. [Permissions aur SELinux context verify karein](#12-permissions-aur-selinux-context-verify-karein)
13. [Troubleshooting](#13-troubleshooting)
14. [Security recommendations](#14-security-recommendations)
15. [Quick command reference](#15-quick-command-reference)
16. [Final result](#16-final-result)

---

## 1. Lab ki maloomat

| Item | Value |
|---|---|
| Client computer | Windows PowerShell |
| Windows user | `krmar` |
| Ansible control node IP | `192.168.1.233` |
| Remote SSH user | `ansibleadmin` |
| Control-node hostname | `ansible-server.nitclasses.com` |
| SSH port | `22` |
| Optional SSH alias | `ansible-control` |

Yeh key connection is direction mein use hoga:

```text
Windows laptop → Ansible control node
```

Yeh us SSH key se alag purpose rakhta hai jo is direction mein use hoti hai:

```text
Ansible control node → managed nodes
```

Windows se control node tak login ke liye Windows wali private key use hogi. Control node se `node1`, `node2` aur `node3` tak Ansible connection ke liye control node par maujood key use hogi.

---

## 2. Passwordless SSH kaise kaam karta hai?

SSH key authentication ek key pair use karti hai:

- **Private key** Windows computer par rehti hai.
- **Public key** remote user ki `authorized_keys` file mein add hoti hai.
- Login ke waqt server verify karta hai ke Windows client ke paas matching private key hai.
- Private key kabhi server par copy nahi ki jati.

Relevant paths:

```text
Windows private key:
C:\Users\krmar\.ssh\id_ed25519

Windows public key:
C:\Users\krmar\.ssh\id_ed25519.pub

Server authorized keys:
/home/ansibleadmin/.ssh/authorized_keys
```

Simple flow:

```text
Windows private key
        ↓ proves identity
SSH server compares public key
        ↓
/home/ansibleadmin/.ssh/authorized_keys
        ↓
Login allowed
```

---

## 3. Normal SSH access test karein

Windows PowerShell open karein:

```powershell
ssh ansibleadmin@192.168.1.233
```

`ansibleadmin` ka password enter karein.

Login ke baad verify karein:

```bash
whoami
hostname
```

Expected results:

```text
ansibleadmin
ansible-server.nitclasses.com
```

Server se bahar aayen:

```bash
exit
```

Public key ko SSH ke zariye install karne se pehle normal password-based SSH ka kaam karna zaroori hai.

---

## 4. Windows SSH directory check karein

PowerShell mein run karein:

```powershell
Get-ChildItem "$HOME\.ssh" -Force
```

Directory aam tor par yeh hogi:

```text
C:\Users\krmar\.ssh
```

Agar directory exist nahi karti to banayen:

```powershell
New-Item -ItemType Directory -Force "$HOME\.ssh"
```

`$HOME` current Windows user ke home folder ko represent karta hai. Aap ke environment mein yeh aam tor par `C:\Users\krmar` hai.

---

## 5. SSH key generate karein

Is lab mein requested simple command use karein:

```powershell
ssh-keygen
```

Program poochay ga:

```text
Enter file in which to save the key (C:\Users\krmar/.ssh/id_ed25519):
```

Default path accept karne ke liye **Enter** press karein.

Phir yeh poochay ga:

```text
Enter passphrase (empty for no passphrase):
```

Personal practice lab mein completely passwordless access ke liye kuch type kiye baghair **Enter** press karein.

Dobara poochay ga:

```text
Enter same passphrase again:
```

Dobara **Enter** press karein.

### Bohat important safety warning

Agar yeh message aaye:

```text
C:\Users\krmar\.ssh\id_ed25519 already exists.
Overwrite (y/n)?
```

Type karein:

```text
n
```

Existing key ko overwrite na karein. Ho sakta hai woh key pehle se kisi doosre server, GitHub ya lab ke access ke liye use ho rahi ho.

Agar default key pehle se maujood hai, to uski public key use ki ja sakti hai. Nayi named key tabhi banayen jab aap jaan-boojh kar separate key rakhna chahte hon.

---

## 6. Dono key files ko samjhein

Simple `ssh-keygen` command normally do files banata hai:

```text
C:\Users\krmar\.ssh\id_ed25519
C:\Users\krmar\.ssh\id_ed25519.pub
```

| File | Maqsad | Share kar sakte hain? |
|---|---|---|
| `id_ed25519` | Private key; identity prove karti hai | **Nahi** |
| `id_ed25519.pub` | Public key; server par install hoti hai | Haan |

Files verify karein:

```powershell
Get-ChildItem "$HOME\.ssh\id_ed25519*"
```

Sirf public key display karein:

```powershell
Get-Content "$HOME\.ssh\id_ed25519.pub"
```

Output aam tor par is se start hogi:

```text
ssh-ed25519
```

`id_ed25519` private file ka content kabhi display, email, upload ya share na karein.

---

## 7. Public key Ansible server par install karein

Windows PowerShell mein normally `ssh-copy-id` command available nahi hoti. Is liye yeh command use karein:

```powershell
Get-Content "$HOME\.ssh\id_ed25519.pub" |
ssh ansibleadmin@192.168.1.233 'umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; key=$(cat); grep -qxF "$key" ~/.ssh/authorized_keys || printf "%s\n" "$key" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'
```

`ansibleadmin` ka password aakhri martaba enter karein.

### Yeh command kya karti hai?

1. `Get-Content` Windows public key read karta hai.
2. Pipe `|` key ka content SSH command ko bhejta hai.
3. `umask 077` secure default permissions set karta hai.
4. `mkdir -p ~/.ssh` remote `.ssh` directory banata hai agar woh missing ho.
5. `touch ~/.ssh/authorized_keys` authorized-keys file ensure karta hai.
6. `key=$(cat)` pipe se aane wali public key read karta hai.
7. `grep -qxF` check karta hai ke exact key pehle se file mein hai ya nahi.
8. Key missing ho to `printf` usay append karta hai.
9. `.ssh` ko `0700` aur `authorized_keys` ko `0600` permission milti hai.

Duplicate check ki wajah se command repeat karne par same key bar bar add nahi hogi.

---

## 8. Passwordless SSH test karein

Normal command run karein:

```powershell
ssh ansibleadmin@192.168.1.233
```

OpenSSH automatically default `id_ed25519` private key check karta hai. Ab Linux account password nahi poocha jana chahiye.

Login ke baad verify karein:

```bash
whoami
hostname
```

Exit karein:

```bash
exit
```

Key ko explicitly bhi test kar sakte hain:

```powershell
ssh -i "$HOME\.ssh\id_ed25519" -o IdentitiesOnly=yes ansibleadmin@192.168.1.233
```

- `-i` specific private key select karta hai.
- `IdentitiesOnly=yes` SSH ko sirf selected/configured key offer karne ko kehta hai.

Agar explicit command kaam kare lekin normal command password poochay, to SSH config aur offered identities check karein.

---

## 9. SSH alias banayen

Alias ke zariye yeh lambi command:

```powershell
ssh ansibleadmin@192.168.1.233
```

is chhoti command mein badal jayegi:

```powershell
ssh ansible-control
```

Windows SSH configuration open karein:

```powershell
notepad "$HOME\.ssh\config"
```

Yeh content add karein:

```sshconfig
Host ansible-control
    HostName 192.168.1.233
    User ansibleadmin
    IdentityFile C:/Users/krmar/.ssh/id_ed25519
    IdentitiesOnly yes
```

### Windows profile name mein space ho

Agar Windows profile `C:\Users\windows 11` ho to complete path ko unquoted
na likhein. Safest aur recommended configuration yeh hai:

```sshconfig
Host ansible-control
    HostName 192.168.1.99
    User ansibleadmin
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

`~/.ssh/id_ed25519` current Windows user ke profile path ko automatically
represent karta hai. Doosra option complete path ko quotes mein likhna hai:

```sshconfig
IdentityFile "C:/Users/windows 11/.ssh/id_ed25519"
```

Username, profile aur key verify karein:

```powershell
$env:USERNAME
$HOME
$env:USERPROFILE
Test-Path "$HOME\.ssh\id_ed25519"
Get-ChildItem "$HOME\.ssh" -Force
```

Resolved configuration aur connection test karein:

```powershell
ssh -G ansible-control |
Select-String "hostname|user|identityfile|identitiesonly"
ssh ansible-control
ssh -vvv ansible-control
```

Windows display name change karne se profile folder aam tor par rename nahi
hota. `C:\Users\windows 11` ko manually rename na karein, kyun ke profile
configuration break ho sakti hai. `~` use karne se masla solve ho jata hai.
Agar clean path lazmi ho to `ansiblelab` jaisay simple naam se naya account
banana zyada safe hai.

### Lines ka matlab

| Line | Matlab |
|---|---|
| `Host ansible-control` | Local shortcut/alias define karta hai. |
| `HostName 192.168.1.233` | Asal server IP deta hai. |
| `User ansibleadmin` | Remote Linux username define karta hai. |
| `IdentityFile ...` | Windows private-key path specify karta hai. |
| `IdentitiesOnly yes` | SSH ko isi configured key tak limit karta hai. |

File ko exact is naam se save karein:

```text
config
```

Yeh nahi hona chahiye:

```text
config.txt
```

Verify karein:

```powershell
Get-ChildItem "$HOME\.ssh\config"
Get-Content "$HOME\.ssh\config"
```

Check karein ke SSH alias ko kaise resolve kar raha hai:

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

Alias test karein:

```powershell
ssh ansible-control
```

---

## 10. Alias ko SCP ke saath use karein

Windows se Ansible server par playbook bhejen:

```powershell
scp .\playbook.yml ansible-control:/home/ansibleadmin/automation/playbooks/
```

Server se file current Windows directory mein layen:

```powershell
scp ansible-control:/home/ansibleadmin/automation/playbooks/playbook.yml .
```

Complete directory recursively copy karein:

```powershell
scp -r .\playbooks ansible-control:/home/ansibleadmin/automation/
```

`-r` ka matlab recursive hai: directory aur us ke andar ka tamam content copy hoga.

---

## 11. Alias ko VS Code Remote SSH ke saath use karein

1. VS Code open karein.
2. Microsoft **Remote - SSH** extension install karein agar pehle se nahi hai.
3. `Ctrl+Shift+P` press karein.
4. **Remote-SSH: Connect to Host...** select karein.
5. `ansible-control` select karein.
6. Platform poochay to **Linux** select karein.
7. `/home/ansibleadmin/automation` folder open karein.

VS Code wahi Windows SSH config aur private key use karega.

Rocky Linux control node par VS Code Server archive ke liye required utilities install karein:

```bash
sudo dnf install -y tar gzip
```

---

## 12. Permissions aur SELinux context verify karein

Server se connect karein:

```powershell
ssh ansible-control
```

Permissions check karein:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Expected permission patterns:

```text
drwx------  .ssh
-rw-------  authorized_keys
```

Agar permissions ghalat hon:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
```

Rocky Linux par SELinux contexts restore karein:

```bash
sudo restorecon -Rv /home/ansibleadmin/.ssh
```

Correct permissions aur SELinux labels zaroori hain. Ghalat permissions ya context ki wajah se valid public key ke bawajood authentication reject ho sakti hai.

---

## 13. Troubleshooting

### Ab bhi account password pooch raha hai

PowerShell se verbose debugging run karein:

```powershell
ssh -vvv ansible-control
```

In lines ko dhoondhein:

```text
Offering public key
Server accepts key
Authenticated using "publickey"
```

Private key ka existence check karein:

```powershell
Test-Path "$HOME\.ssh\id_ed25519"
```

Expected:

```text
True
```

Server par public key check karein:

```bash
cat ~/.ssh/authorized_keys
```

### Key sirf `-i` use karne par kaam karti hai

Explicit command:

```powershell
ssh -i "$HOME\.ssh\id_ed25519" -o IdentitiesOnly=yes ansibleadmin@192.168.1.233
```

Phir SSH config ka identity path check karein:

```powershell
ssh -G ansible-control | Select-String "identityfile"
```

Config ka path existing private key se match karna chahiye.

### `Could not resolve hostname ansible-control`

Check karein file ka naam `config` hai, `config.txt` nahi:

```powershell
Get-ChildItem "$HOME\.ssh" -Force
```

Zaroorat ho to rename karein:

```powershell
Rename-Item "$HOME\.ssh\config.txt" "config"
```

### `Permission denied (publickey,password)`

Server par permissions, ownership aur SELinux context correct karein:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
sudo restorecon -Rv /home/ansibleadmin/.ssh
```

### SSH server ki effective configuration check karein

```bash
sudo /usr/sbin/sshd -T |
grep -E 'pubkeyauthentication|authorizedkeysfile|passwordauthentication'
```

Important expected settings:

```text
pubkeyauthentication yes
authorizedkeysfile .ssh/authorized_keys
```

### SSH restart karne se pehle validate karein

Sirf tab restart karein jab aap ne SSH configuration change ki ho. Pehle syntax validate karein:

```bash
sudo /usr/sbin/sshd -t
```

No output aam tor par valid configuration ka matlab hai.

Phir zaroorat ho to:

```bash
sudo systemctl restart sshd
```

### Port 22 connection test

PowerShell se:

```powershell
Test-NetConnection 192.168.1.233 -Port 22
```

Important result:

```text
TcpTestSucceeded : True
```

`False` aaye to passwordless key ka nahi, network/firewall/SSH service ka masla hai.

---

## 14. Security recommendations

- `id_ed25519` private key kabhi share na karein.
- Sirf `id_ed25519.pub` server par copy karein.
- Existing key ko samjhe baghair overwrite na karein.
- Pehli connection par server host-key fingerprint verify karein.
- Empty passphrase private lab mein convenient hai, lekin private key chori hone par protection kam hoti hai.
- Production mein private key par passphrase lagayen aur `ssh-agent` use karein.
- Sirf convenience ke liye direct root SSH login enable na karein.
- Linux par `.ssh` permission `0700` aur `authorized_keys` permission `0600` rakhein.
- Private key ko Git repository mein kabhi commit na karein.

---

## 15. Quick command reference

### Windows PowerShell

```powershell
# Normal SSH test
ssh ansibleadmin@192.168.1.233

# SSH directory check
Get-ChildItem "$HOME\.ssh" -Force

# Default SSH key pair generate karein
ssh-keygen

# Generated files verify karein
Get-ChildItem "$HOME\.ssh\id_ed25519*"

# Sirf public key display karein
Get-Content "$HOME\.ssh\id_ed25519.pub"

# Public key server par install karein
Get-Content "$HOME\.ssh\id_ed25519.pub" |
ssh ansibleadmin@192.168.1.233 'umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; key=$(cat); grep -qxF "$key" ~/.ssh/authorized_keys || printf "%s\n" "$key" >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys'

# Passwordless SSH test
ssh ansibleadmin@192.168.1.233

# SSH config open karein
notepad "$HOME\.ssh\config"

# Alias resolution check karein
ssh -G ansible-control |
Select-String "hostname|user|identityfile|identitiesonly"

# Alias se connect karein
ssh ansible-control

# Detailed debug
ssh -vvv ansible-control
```

### Ansible control node

```bash
# SSH permissions check
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys

# Permissions aur ownership correct karein
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh

# Rocky Linux SELinux contexts restore karein
sudo restorecon -Rv /home/ansibleadmin/.ssh

# Effective SSH configuration check karein
sudo /usr/sbin/sshd -T |
grep -E 'pubkeyauthentication|authorizedkeysfile|passwordauthentication'

# SSH configuration syntax validate karein
sudo /usr/sbin/sshd -t
```

---

## 16. Final result

Configuration se pehle:

```powershell
ssh ansibleadmin@192.168.1.233
```

Server Linux account ka password maangta tha.

Configuration ke baad in mein se koi command account password maange baghair connect karegi:

```powershell
ssh ansibleadmin@192.168.1.233
```

ya:

```powershell
ssh ansible-control
```

Default `id_ed25519` filename setup ko simple banata hai kyun ke OpenSSH authentication ke waqt is key ko automatically check karta hai.
