# SSH Login Banner — Manual aur Ansible Three-Node Lab (Roman Urdu)

Yeh study guide batati hai ke SSH pre-login banner ko pehle manually `node1` par kaise configure karein aur phir Ansible se `node1`, `node2`, aur `node3` par automate kaise karein.

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [SSH banner kya hai?](#3-ssh-banner-kya-hai)
4. [SSH Banner aur MOTD mein farq](#4-ssh-banner-aur-motd-mein-farq)
5. [Zaroori corrections aur safety rules](#5-zaroori-corrections-aur-safety-rules)
6. [Part 1 — node1 par manual demonstration](#6-part-1--node1-par-manual-demonstration)
7. [Part 2 — Ansible se teenon nodes automate karein](#7-part-2--ansible-se-teenon-nodes-automate-karein)
8. [Playbook ki block-wise explanation](#8-playbook-ki-block-wise-explanation)
9. [Ansible se result verify karein](#9-ansible-se-result-verify-karein)
10. [Control node se SSH test](#10-control-node-se-ssh-test)
11. [Idempotency demonstrate karein](#11-idempotency-demonstrate-karein)
12. [Rollback procedure](#12-rollback-procedure)
13. [Troubleshooting](#13-troubleshooting)
14. [Class demonstration ka suggested order](#14-class-demonstration-ka-suggested-order)
15. [Quick command reference](#15-quick-command-reference)

---

## 1. Learning objectives

Is lab ko complete karne ke baad aap:

- SSH pre-login banner ka maqsad samajh sakein ge.
- SSH banner aur `/etc/motd` ka farq bata sakein ge.
- SSH banner manually configure kar sakein ge.
- `/etc/ssh/sshd_config` ko safely validate kar sakein ge.
- SSH service ko reload kar sakein ge.
- Ansible se teen managed nodes par banner configure kar sakein ge.
- Handler ki madad se `sshd` ko sirf change hone par reload kar sakein ge.
- Ansible idempotency demonstrate kar sakein ge.
- Zaroorat par change rollback kar sakein ge.

---

## 2. Lab environment

| Role | Host | IP address |
|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` |
| Managed node | `node1` | `192.168.1.154` |
| Managed node | `node2` | `192.168.1.185` |
| Managed node | `node3` | `192.168.1.190` |

SSH user:

```text
ansibleadmin
```

SSH private key:

```text
/home/ansibleadmin/.ssh/ansible-key
```

Ansible project directory:

```text
/home/ansibleadmin/automation
```

Teen hosts ko aik sath target karne ke liye yeh Ansible pattern use hoga:

```text
node1:node2:node3
```

Ansible host pattern mein colon `:` ka matlab OR hota hai: `node1` ya `node2` ya `node3`.

---

## 3. SSH banner kya hai?

SSH banner woh text hai jo SSH client ko **authentication se pehle** dikhaya jata hai. Is ka istemal aam tor par in maqasid ke liye hota hai:

- Authorized-use warning dikhana.
- Monitoring notice dena.
- Legal ya organizational notice dikhana.
- Lab ya server ki pehchan batana.

SSH server ki configuration mein directive yeh hoti hai:

```text
Banner /etc/ssh/banner.txt
```

`Banner` directive `sshd` ko batati hai ke authentication se pehle kis file ka content display karna hai.

Personal lab mein friendly welcome message theek hai. Production server par aam tor par approved security/legal warning use ki jati hai aur system ki unnecessary information expose nahin ki jati.

---

## 4. SSH Banner aur MOTD mein farq

| Feature | SSH banner | MOTD |
|---|---|---|
| Common file | `/etc/ssh/banner.txt` jaisi custom file | `/etc/motd` |
| Kab nazar aata hai? | Authentication se pehle | Successful login ke baad |
| Configuration | `sshd_config` mein `Banner` | Login/PAM configuration |
| Maqsad | Warning ya legal notice | Welcome, news ya maintenance information |
| User authenticate ho chuka hota hai? | Nahin | Haan |

Is lab mein hum SSH **pre-login banner** configure kar rahe hain, MOTD nahin.

---

## 5. Zaroori corrections aur safety rules

### Absolute path use karein

Sahi:

```bash
cd /etc/ssh
```

Ghalat:

```bash
cd etc/ssh
```

Leading `/` na ho to shell current directory ke andar `etc/ssh` dhoondti hai.

### Directive ki spelling sahi rakhein

```text
Banner /etc/ssh/banner.txt
```

### Configuration ka backup banayein

```bash
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
```

### Reload se pehle validation karein

```bash
sudo /usr/sbin/sshd -t
```

- Agar output na aaye to aam tor par syntax theek hai.
- Agar error aaye to pehle usay correct karein.
- Validation fail ho to `sshd` ko reload ya restart na karein.

### Current SSH session khula rakhein

Jis session mein configuration kar rahe hain usay open rakhein. Nayi setting ko doosre terminal se test karein. Agar koi masla ho to pehla session troubleshooting ke liye available rahega.

### Restart ke bajaye reload ko preference dein

```bash
sudo systemctl reload sshd
```

Reload configuration ko apply karta hai aur full service restart se kam disruptive hota hai.

---

## 6. Part 1 — node1 par manual demonstration

### Step 1: node1 se connect karein

Control node se:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

### Step 2: SSH configuration directory mein jayein

```bash
cd /etc/ssh
```

### Step 3: sshd_config ka backup banayein

```bash
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
```

Backup check karein:

```bash
ls -l /etc/ssh/sshd_config*
```

### Step 4: Banner file banayein

```bash
sudo vim /etc/ssh/banner.txt
```

Yeh content add karein:

```text
**************************************************
WARNING: Authorized access only

Welcome to node1 — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
```

Save aur exit:

```vim
:wq
```

Ownership aur permissions set karein:

```bash
sudo chown root:root /etc/ssh/banner.txt
sudo chmod 0644 /etc/ssh/banner.txt
```

### Step 5: sshd_config edit karein

```bash
sudo vim /etc/ssh/sshd_config
```

Vim mein Banner line search karein:

```vim
/Banner
```

Line ko is tarah configure karein:

```text
Banner /etc/ssh/banner.txt
```

Save aur exit:

```vim
:wq
```

> Agar `#Banner none` mojood ho to usay required active line se replace karein. Mukhtalif files mein conflicting active `Banner` directives na chhorein.

### Step 6: Configuration validate karein

```bash
sudo /usr/sbin/sshd -t
```

Agar error na aaye to aglay step par jayein.

### Step 7: SSH service reload karein

```bash
sudo systemctl reload sshd
```

### Step 8: Service aur effective setting verify karein

```bash
sudo systemctl is-active sshd
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

Expected output:

```text
active
banner /etc/ssh/banner.txt
```

### Step 9: Doosre terminal se test karein

Pehla SSH session open rakhein. Doosre terminal se:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Banner authentication complete hone se pehle nazar aana chahiye.

---

## 7. Part 2 — Ansible se teenon nodes automate karein

Manual process samjhane ke baad isi kaam ko `node1`, `node2`, aur `node3` par automate karein.

### Step 1: Connectivity check karein

```bash
cd /home/ansibleadmin/automation
ansible 'node1:node2:node3' -m ping
```

Teenon nodes se `SUCCESS` aur `pong` milna chahiye.

### Step 2: Playbook banayein

```bash
vim ssh-banner.yml
```

Yeh playbook add karein:

```yaml
---
- name: Configure SSH login banner on three nodes
  hosts: "node1:node2:node3"
  become: true

  tasks:
    - name: Create a customized SSH banner
      copy:
        dest: /etc/ssh/banner.txt
        owner: root
        group: root
        mode: "0644"
        content: |
          **************************************************
          WARNING: Authorized access only

          Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
          All activities may be monitored.
          **************************************************

    - name: Configure the SSH Banner directive
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^\s*#?\s*Banner\s+'
        line: 'Banner /etc/ssh/banner.txt'
        backup: true
        validate: '/usr/sbin/sshd -t -f %s'
      notify: Reload sshd

  handlers:
    - name: Reload sshd
      service:
        name: sshd
        state: reloaded
```

### Step 3: Syntax check karein

```bash
ansible-playbook --syntax-check ssh-banner.yml
```

Expected result:

```text
playbook: ssh-banner.yml
```

### Step 4: Changes ka preview dekhein

```bash
ansible-playbook --check --diff ssh-banner.yml
```

Check mode possible changes ka preview deta hai. Har module ya command ki complete simulation guarantee nahin hoti, is liye isay useful preview samjhein, final test ka replacement nahin.

### Step 5: Playbook run karein

```bash
ansible-playbook ssh-banner.yml
```

Play recap mein teenon nodes ke liye yeh hona chahiye:

```text
failed=0
unreachable=0
```

---

## 8. Playbook ki block-wise explanation

### `hosts`

```yaml
hosts: "node1:node2:node3"
```

Yeh pattern teenon inventory hosts ko target karta hai. Agar inventory mein in teenon ka group bana hua ho, to group name bhi use kiya ja sakta hai.

### `become`

```yaml
become: true
```

`/etc/ssh` ke files modify karne aur service reload karne ke liye root privileges chahiye hoti hain.

### `copy` module

`copy` task:

- `/etc/ssh/banner.txt` create karti hai.
- Owner aur group `root` set karti hai.
- Permissions `0644` set karti hai.
- Har node ke liye customized content banati hai.

```yaml
Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
```

`inventory_hostname` har managed node par us ka inventory name deta hai.

### `lineinfile` module

Yeh task active ya commented Banner line search karke required line set karti hai:

```text
Banner /etc/ssh/banner.txt
```

| Parameter | Kaam |
|---|---|
| `path` | Jis file ko manage karna hai |
| `regexp` | Existing active/commented Banner line dhoondta hai |
| `line` | Final required configuration line |
| `backup` | Change se pehle timestamped backup banata hai |
| `validate` | Temporary file ko real file replace karne se pehle test karta hai |

Agar validation fail ho jaye to Ansible invalid temporary file ko real configuration ke upar install nahin karta.

### Handler

```yaml
notify: Reload sshd
```

Handler sirf tab run hota hai jab `lineinfile` task change report kare. Agar correct configuration pehle se mojood ho to service unnecessary reload nahin hoti.

---

## 9. Ansible se result verify karein

### Banner files display karein

```bash
ansible 'node1:node2:node3' -b -m command \
-a "cat /etc/ssh/banner.txt"
```

### Teenon nodes par sshd configuration validate karein

```bash
ansible 'node1:node2:node3' -b -m command \
-a "/usr/sbin/sshd -t"
```

Successful validation mein aam tor par configuration error ka output nahin aata.

### Effective Banner value check karein

Pipe (`|`) ki wajah se `shell` module use karein:

```bash
ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"
```

Expected output:

```text
banner /etc/ssh/banner.txt
```

### SSH service check karein

```bash
ansible 'node1:node2:node3' -b -m command \
-a "systemctl is-active sshd"
```

Har node ka expected output:

```text
active
```

---

## 10. Control node se SSH test

Har node ko test karein:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ssh -i ~/.ssh/ansible-key ansibleadmin@node2
ssh -i ~/.ssh/ansible-key ansibleadmin@node3
```

Customized message is tarah nazar aana chahiye:

- `Welcome to node1 — NIT Classes Ansible Lab`
- `Welcome to node2 — NIT Classes Ansible Lab`
- `Welcome to node3 — NIT Classes Ansible Lab`

Session se bahar aane ke liye:

```bash
exit
```

---

## 11. Idempotency demonstrate karein

Playbook doosri martaba run karein:

```bash
ansible-playbook ssh-banner.yml
```

Agar first run ke baad kisi ne files manually change nahin ki to second run mein aam tor par yeh milega:

```text
changed=0
failed=0
```

Is ka matlab Ansible ne pehchan liya ke desired state pehle se mojood hai. Isi behavior ko **idempotency** kehte hain.

- `copy` task unchanged hogi kyun ke content, ownership aur permissions sahi hain.
- `lineinfile` unchanged hogi kyun ke required Banner line pehle se mojood hai.
- Handler run nahin hoga kyun ke configuration mein change nahin hui.

---

## 12. Rollback procedure

Rollback playbook banayein:

```bash
vim remove-ssh-banner.yml
```

Content:

```yaml
---
- name: Remove the SSH login banner configuration
  hosts: "node1:node2:node3"
  become: true

  tasks:
    - name: Disable the SSH Banner directive
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^\s*#?\s*Banner\s+'
        line: 'Banner none'
        backup: true
        validate: '/usr/sbin/sshd -t -f %s'
      notify: Reload sshd

    - name: Remove the custom banner file
      file:
        path: /etc/ssh/banner.txt
        state: absent

  handlers:
    - name: Reload sshd
      service:
        name: sshd
        state: reloaded
```

Syntax check, preview aur run:

```bash
ansible-playbook --syntax-check remove-ssh-banner.yml
ansible-playbook --check --diff remove-ssh-banner.yml
ansible-playbook remove-ssh-banner.yml
```

Verify karein:

```bash
ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"
```

Expected effective value:

```text
banner none
```

---

## 13. Troubleshooting

### Permission denied aa raha hai

Play mein privilege escalation check karein:

```yaml
become: true
```

Passwordless sudo test karein:

```bash
ansible 'node1:node2:node3' -m command -a "sudo -n whoami"
```

Expected output:

```text
root
```

### Banner nazar nahin aa raha

Effective setting check karein:

```bash
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

File check karein:

```bash
sudo ls -l /etc/ssh/banner.txt
sudo cat /etc/ssh/banner.txt
```

Service check karein:

```bash
sudo systemctl status sshd --no-pager
```

### Configuration validation fail ho rahi hai

```bash
sudo /usr/sbin/sshd -t
```

Error mein diye gaye filename aur line ko check karein. Error fix karke dobara validation karein. Jab tak validation successful na ho, service reload na karein.

### Host unreachable hai

```bash
ansible 'node1:node2:node3' -m ping
```

Phir direct SSH test karein:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
```

Yeh cheezen check karein:

- IP address ya name resolution.
- Network connectivity.
- Remote SSH service.
- Private-key path aur permissions.
- Remote `authorized_keys` mein public key.

### Playbook har run par changed dikha rahi hai

```bash
ansible-playbook --diff ssh-banner.yml
```

Bar-bar hone wali difference inspect karein. Mumkin causes:

- Koi doosra process file modify kar raha hai.
- Content ya whitespace different hai.
- Multiple conflicting Banner directives hain.
- Koi doosra configuration-management tool different state enforce kar raha hai.

---

## 14. Class demonstration ka suggested order

1. SSH pre-login banner ka concept explain karein.
2. SSH banner aur `/etc/motd` ka farq batayein.
3. `node1` par manual configuration karein.
4. `sshd_config` ka backup aur validation dikhayein.
5. `sshd` reload karke doosre terminal se test karein.
6. Explain karein ke bohat se servers par manual repetition inefficient hai.
7. Ansible playbook explain karein.
8. `--syntax-check` run karein.
9. `--check --diff` run karein.
10. Teenon nodes par playbook apply karein.
11. Banner, effective SSH setting aur service state verify karein.
12. Playbook dobara run karke `changed=0` dikhayein.
13. Time ho to rollback playbook bhi demonstrate karein.

Yeh order automation ki value clear karta hai: pehle task manually samjhein, phir repeat hone wale kaam ko safe aur reusable playbook se automate karein.

---

## 15. Quick command reference

### node1 par manual configuration

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
cd /etc/ssh
sudo cp -p /etc/ssh/sshd_config \
/etc/ssh/sshd_config.bak.$(date +%F_%H%M%S)
sudo vim /etc/ssh/banner.txt
sudo chown root:root /etc/ssh/banner.txt
sudo chmod 0644 /etc/ssh/banner.txt
sudo vim /etc/ssh/sshd_config
sudo /usr/sbin/sshd -t
sudo systemctl reload sshd
sudo systemctl is-active sshd
sudo /usr/sbin/sshd -T | grep -i '^banner'
```

### Ansible deployment aur validation

```bash
cd /home/ansibleadmin/automation
ansible 'node1:node2:node3' -m ping
ansible-playbook --syntax-check ssh-banner.yml
ansible-playbook --check --diff ssh-banner.yml
ansible-playbook ssh-banner.yml
ansible-playbook ssh-banner.yml

ansible 'node1:node2:node3' -b -m command \
-a "cat /etc/ssh/banner.txt"

ansible 'node1:node2:node3' -b -m command \
-a "/usr/sbin/sshd -t"

ansible 'node1:node2:node3' -b -m shell \
-a "/usr/sbin/sshd -T | grep -i '^banner'"

ansible 'node1:node2:node3' -b -m command \
-a "systemctl is-active sshd"
```

## Final recommendation

Demo mein pehle `node1` par manual configuration karein, phir Ansible se teenon nodes configure karein. Hamesha backup banayein, `sshd -t` se validation karein, current SSH session open rakhein, aur sirf configuration change ke liye `restart` ke bajaye `reload` ko preference dein.
