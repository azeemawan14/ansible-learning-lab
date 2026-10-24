# Ansible ke liye Custom SSH Key Filename — Roman Urdu Study Notes

## Lab ki maloomat

- Control-node user: `ansibleadmin`
- Control node: `ansible-server.nitclasses.com`
- Private key: `/home/ansibleadmin/.ssh/ansible-key`
- Public key: `/home/ansibleadmin/.ssh/ansible-key.pub`

| Managed node | IP address |
|---|---|
| `node1` | `192.168.1.154` |
| `node2` | `192.168.1.185` |
| `node3` | `192.168.1.190` |

## SSH ne password kyun manga?

Yeh command password ke baghair kaam kar gayi:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Lekin yeh command password mang rahi thi:

```bash
ssh node1
```

Is ki wajah yeh hai ke `ansible-key` ek **custom filename** hai. SSH aam tor par standard naam wali keys, jaise `id_ed25519`, ko khud talash karta hai. Lekin SSH ko khud maloom nahin hota ke `~/.ssh/ansible-key` use karni hai.

Key ko custom naam dena **ghalti nahin thi**. Bas SSH ko batana zaroori hai ke kaunsi key use karni hai. Is ke teen tareeqe hain:

1. Command ke saath `-i` option lagana
2. `~/.ssh/config` mein key define karna
3. Ansible mein `private_key_file` set karna

## Key filename aur key comment mein farq

- `ansible-key` private key ka **filename** hai.
- `ansible-key.pub` public key ka **filename** hai.
- Public key ke aakhir mein `ansibleadmin@ansible-server.nitclasses.com` jaisa text sirf **comment ya label** hota hai.

Comment se key ki pehchan asaan hoti hai. Yeh authentication ko control nahin karta aur iska filename se match karna zaroori nahin hai.

## Public key ko manually install karna

`ansible-key.pub` ke contents ko managed node ki `~/.ssh/authorized_keys` file mein manually paste karna bilkul durust hai. `ssh-copy-id` sirf isi kaam ko asaan aur zyada mehfooz tareeqe se karta hai.

```bash
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node1
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node2
ssh-copy-id -i ~/.ssh/ansible-key.pub ansibleadmin@node3
```

`authorized_keys` mein aik se zyada public keys ka hona normal hai. Misal ke tor par aik key Ansible control node ki aur doosri Windows computer ki ho sakti hai.

## Behtareen tareeqa: SSH client configuration

Control node par SSH configuration file kholein:

```bash
vim ~/.ssh/config
```

Is mein yeh configuration likhein:

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

File ki permission durust karein:

```bash
chmod 600 ~/.ssh/config
```

Ab yeh commands sahi key automatically use kareingi:

```bash
ssh node1
ssh node2
ssh node3
```

`IdentitiesOnly yes` ka matlab hai ke SSH configured key ko use kare aur doosri ghair-zaroori keys try na kare.

## Ansible mein private key configure karna

Agar project `~/automation` mein hai, to `~/automation/ansible.cfg` mein yeh settings rakhein:

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

`private_key_file` Ansible ko batata hai ke SSH connection ke liye kaunsi private key use karni hai. Absolute path dene se confusion kam hoti hai.

Yahi setting inventory file mein bhi di ja sakti hai:

```ini
[all:vars]
ansible_user = ansibleadmin
ansible_python_interpreter = /usr/bin/python3
ansible_ssh_private_key_file = /home/ansibleadmin/.ssh/ansible-key
```

Aam tor par shared private key ko **sirf aik jagah**, yani project ke `ansible.cfg` mein define karna behtar hai. Bila-wajah aik hi setting ko kai jagah repeat na karein.

## Zaroori permissions

Control node par:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ansible-key
chmod 644 ~/.ssh/ansible-key.pub
chmod 600 ~/.ssh/config
```

Har Rocky Linux managed node par:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R ansibleadmin:ansibleadmin ~/.ssh
restorecon -RFv ~/.ssh
```

`restorecon` zaroorat par SELinux security contexts ko durust karta hai.

## Verification commands

Password prompt ke baghair SSH test karein:

```bash
ssh -o BatchMode=yes node1 hostname
ssh -o BatchMode=yes node2 hostname
ssh -o BatchMode=yes node3 hostname
```

`BatchMode=yes` SSH ko password mangne se rokta hai. Agar key authentication fail ho, to command foran fail ho jayegi.

Dekhein ke SSH asal mein kaunsi settings use karega:

```bash
ssh -G node1 | grep -Ei '^(hostname|user|identityfile|identitiesonly)'
```

SSH authentication ki tafseeli troubleshooting ke liye:

```bash
ssh -vvv node1
```

Public key ka fingerprint check karein:

```bash
ssh-keygen -lf ~/.ssh/ansible-key.pub
```

Ansible ki active project configuration check karein:

```bash
cd ~/automation
ansible-config dump --only-changed
```

Aik managed node ko test karein:

```bash
ansible node1 -m ping
```

Poore three-tier group ko test karein:

```bash
ansible three_tier_app -m ping
```

## Security recommendations

- Private key `ansible-key` ko kabhi share ya Git mein commit na karein.
- Managed nodes par sirf public key `ansible-key.pub` copy karein.
- Har administrator ya learner apna alag SSH key pair use kare.
- Jab kisi shakhs ko access ki zaroorat na rahe to us ki public key `authorized_keys` se hata dein.
- `host_key_checking = True` rakhein taa-ke Ansible managed nodes ki identity verify kare.

## Khulasa

`ansible-key` naam dena ghalti nahin thi. Yeh custom filename hai, is liye SSH ko batana hota hai ke isi private key ko use karna hai. Rozana istemal ke liye behtareen setup yeh hai ke `~/.ssh/config` mein `IdentityFile ~/.ssh/ansible-key` likhein aur Ansible project ke `ansible.cfg` mein `private_key_file` ka absolute path define karein.
