# Ansible Hands-On Lab — Roman Urdu Master Study Notes

## Lab Environment

- **Control node:** `ansible-server`
- **User:** `ansibleadmin`
- **Inventory file:** `/home/ansibleadmin/automation/inventory/nodes`
- **node1:** `192.168.1.154` → `node1.nitclasses.com`
- **node2:** `192.168.1.185` → `node2.nitclasses.com`
- **node3:** `192.168.1.190` → `node3.nitclasses.com`
- `three_tier_app` aik parent group hai jis ke andar `web`, `app`, aur `db` groups hain.

---

## 1. Ansible Ad-Hoc Command ka Basic Structure

```bash
ansible TARGET -m MODULE -a "ARGUMENTS" -i INVENTORY
```

Samajhne ka asaan tareeqa:

- `TARGET` = kis host ya group par command chalani hai
- `-m` = kaunsa Ansible module use karna hai
- `-a` = module ko kya arguments dene hain
- `-i` = kaunsi inventory file use karni hai

Example:

```bash
ansible three_tier_app \
-m command \
-a "hostname -f" \
-i ./automation/inventory/nodes
```

---

## 2. Ping Module se Connectivity Test

```bash
ansible web -m ping \
-i ./automation/inventory/nodes
```

Successful output aam tor par:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Important

Ansible ka `ping` normal Linux/network ICMP `ping` nahi hai.

Yeh check karta hai ke Ansible managed node se connect kar sakta hai aur module successfully execute ho raha hai.

Custom data:

```bash
ansible web -m ping \
-a "data=hello" \
-i ./automation/inventory/nodes
```

Expected:

```text
"ping": "hello"
```

Intentional failure practice:

```bash
ansible web -m ping \
-a "data=crash" \
-i ./automation/inventory/nodes
```

`data=crash` special value hai jo jaan-boojh kar module ko fail karwati hai. Detailed troubleshooting ke liye:

```bash
ansible web -m ping \
-a "data=crash" \
-i ./automation/inventory/nodes -vvv
```

---

## 3. ansible-doc

Linux mein documentation ke liye:

```bash
man ls
```

Ansible mein:

```bash
ansible-doc MODULE_NAME
```

Examples:

```bash
ansible-doc ping
ansible-doc ping
ansible-doc dnf
ansible-doc service
```

Sab modules/plugins ki list:

```bash
ansible-doc -l
```

Short documentation:

```bash
ansible-doc -s dnf
```

Search:

```bash
ansible-doc -l | grep firewalld
```

Yaad rakhein:

> Linux command ke liye `man`, Ansible module ke liye `ansible-doc`.

---

## 4. Inventory Example

```ini
[control]
ansible-server ansible_connection=local

[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190

[three_tier_app:children]
web
app
db

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

`three_tier_app` ke andar teen child groups hain:

```text
three_tier_app
├── web → node1
├── app → node2
└── db  → node3
```

Is liye `three_tier_app` ko target karne se teeno managed nodes target ho jate hain.

---

## 5. Inventory Groups ke Hosts Dekhna

```bash
ansible web:app --list-hosts \
-i ./automation/inventory/nodes
```

Output:

```text
hosts (2):
  node1
  node2
```

`--list-hosts` inventory aliases/names dikhata hai. Yeh zaroori nahi ke `ansible_host` wali IP address dikhaye.

---

## 6. inventory_hostname vs ansible_host

Inventory mein:

```ini
node1 ansible_host=192.168.1.154
```

Is ka matlab:

```text
inventory_hostname = node1
ansible_host        = 192.168.1.154
```

Dono ko aik saath dekhne ke liye:

```bash
ansible web:app \
-i ./automation/inventory/nodes \
-m debug \
-a 'msg="{{ inventory_hostname }} -> {{ ansible_host }}"'
```

Hamare lab ka result:

```text
node1 -> 192.168.1.154
node2 -> 192.168.1.185
```

### Quoting ka Important Point

Correct:

```bash
-a 'msg="{{ inventory_hostname }} -> {{ ansible_host }}"'
```

`msg` ki value ke andar quotes is liye hain taake spaces aur arrow ke sath poora message aik hi argument samjha jaye.

---

## 7. Inventory Inspect Karna

Inventory hierarchy:

```bash
ansible-inventory --graph \
-i ./automation/inventory/nodes
```

Complete inventory:

```bash
ansible-inventory --list \
-i ./automation/inventory/nodes
```

Sirf `node1` ki resolved variables:

```bash
ansible-inventory --host node1 \
-i ./automation/inventory/nodes
```

Yeh variables samajhne ke liye useful hai:

- `ansible_host`
- `ansible_user`
- `ansible_python_interpreter`

---

## 8. Hostname aur FQDN Practice

Remote nodes par hostname:

```bash
ansible three_tier_app \
-m command \
-a "hostname" \
-i ./automation/inventory/nodes
```

Hamare nodes ne return kiya:

```text
node1.nitclasses.com
node2.nitclasses.com
node3.nitclasses.com
```

FQDN check:

```bash
ansible three_tier_app \
-m command \
-a "hostname -f" \
-i ./automation/inventory/nodes
```

Result:

```text
node1.nitclasses.com
node2.nitclasses.com
node3.nitclasses.com
```

Yahan:

```text
-f = FQDN = Fully Qualified Domain Name
```

Linux par compare karein:

```bash
hostname
hostname -s
hostname -f
hostnamectl
```

Generally:

```text
hostname     = current configured hostname
hostname -s  = short hostname
hostname -f  = FQDN
```

### Important

Is command mein:

```bash
-a "hostname -f"
```

`-f` **Ansible ka option nahi** hai. Yeh Linux `hostname` command ka option hai.

---

## 9. command Module

```bash
ansible three_tier_app \
-m command \
-a "hostname -f" \
-i ./automation/inventory/nodes
```

Breakdown:

```text
three_tier_app
      ↓
Target group

command
      ↓
Ansible module

hostname -f
      ↓
Managed nodes par chalne wali Linux command
```

Agar output mein:

```text
rc=0
```

ho to normally iska matlab command successfully complete hui.

`command` module read-only command, jaise `hostname -f`, ke liye bhi `CHANGED` report kar sakta hai. Is ka matlab yeh nahi ke hostname asal mein change hua.

---

## 10. Directory Create Karna — file Module

Hamne chalaya:

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-lab state=directory" \
-i ./automation/inventory/nodes
```

First run par:

```text
CHANGED
"changed": true
```

Kyun?

```text
Desired state = directory honi chahiye
            ↓
Directory mojood nahi thi
            ↓
Ansible ne create ki
            ↓
CHANGED = true
```

---

## 11. Idempotency — Bohat Important Concept

Wohi exact command dobara chalayi:

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-lab state=directory" \
-i ./automation/inventory/nodes
```

Second run:

```text
SUCCESS
"changed": false
```

Kyun?

Directory pehle se mojood thi aur desired state already satisfy ho rahi thi.

```text
First Run
Directory nahi thi
      ↓
Ansible ne banayi
      ↓
CHANGED = true

Second Run
Directory already mojood
      ↓
Kuch karne ki zaroorat nahi
      ↓
SUCCESS / changed=false
```

### Idempotency ka Matlab

Aap same Ansible task ko baar baar chala sakte hain. Jab system already desired state mein ho, Ansible unnecessary change nahi karta.

### Interview-Ready Answer

> Ansible modules generally idempotent hotay hain. Agar managed system already desired state mein ho to Ansible unnecessary change nahi karta aur `changed: false` report karta hai.

---

## 12. Directory Output Samajhna

Hamare output mein tha:

```text
"owner": "ansibleadmin"
"group": "ansibleadmin"
"mode": "0755"
"path": "/tmp/ansible-lab"
"state": "directory"
```

`0755` ka matlab:

```text
Owner  → rwx
Group  → r-x
Others → r-x
```

Hamare nodes par `ansibleadmin` ke numeric UID different thay:

```text
node1 → 3005
node2 → 1000
node3 → 1001
```

Yeh possible hai. Alag Linux systems par same username ka numeric UID different ho sakta hai.

---

## 13. SELinux Context

Output mein yeh bhi tha:

```text
"secontext": "unconfined_u:object_r:user_tmp_t:s0"
```

`secontext` ka matlab:

```text
SELinux Security Context
```

Abhi sirf itna yaad rakhein. SELinux ke detailed labs mein is ko aur deeply study karenge.

---

## 14. Directory Remove Karna

Hamne chalaya:

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-lab state=absent" \
-i ./automation/inventory/nodes
```

Output:

```text
CHANGED
"changed": true
"state": "absent"
```

Kyun?

Directory mojood thi aur desired state `absent` thi. Is liye Ansible ne directory remove kar di.

---

## 15. state= Samajhna

```text
state=directory
```

Matlab directory **honi chahiye**.

```text
state=touch
```

File ko touch/create karo.

```text
state=absent
```

File/directory **nahi honi chahiye**.

Memory trick:

```text
directory → hona chahiye
touch     → create/touch karo
absent    → nahi hona chahiye
```

Note: `state=touch` existing file ke timestamps update kar sakta hai, is liye idempotency ke `changed=false` demonstration ke liye yeh best example nahi hai.

---

## 16. Empty File Create Karna

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-test.txt state=touch" \
-i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app \
-m command \
-a "ls -l /tmp/ansible-test.txt" \
-i ./automation/inventory/nodes
```

---

## 17. Content ke Sath File Create Karna

`copy` module:

```bash
ansible three_tier_app \
-m copy \
-a 'content="Hello from Ansible\n" dest=/tmp/ansible-test.txt' \
-i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app \
-m command \
-a "cat /tmp/ansible-test.txt" \
-i ./automation/inventory/nodes
```

Expected:

```text
Hello from Ansible
```

Same `copy` command dobara run karein. Agar file ka content already bilkul same hai to normally:

```text
changed: false
```

mile ga. Yeh idempotency ka acha example hai.

---

## 18. Permissions ke Sath Directory

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/devops state=directory mode=0755" \
-i ./automation/inventory/nodes
```

Verify:

```bash
ansible three_tier_app \
-m command \
-a "ls -ld /tmp/devops" \
-i ./automation/inventory/nodes
```

---

## 19. File Delete Karna

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-test.txt state=absent" \
-i ./automation/inventory/nodes
```

Agar file mojood hai:

```text
changed=true
```

Dobara run karein jab file already delete ho chuki ho:

```text
changed=false
```

Yeh bhi idempotency ka acha practical example hai.

---

## 20. Ansible Output Status

```text
GREEN  → SUCCESS / OK
YELLOW → CHANGED
BLUE   → SKIPPED
RED    → FAILED
```

Exact terminal colors configuration/version ke hisaab se vary kar sakte hain. Hamesha actual status words bhi parhein.

### SUCCESS

```text
SUCCESS
changed=false
```

Command/task successful thi, lekin koi change required nahi tha.

### CHANGED

```text
CHANGED
changed=true
```

Task successful thi aur managed node par change hua.

### FAILED

Task fail hui. Yeh fields dekhein:

- `msg`
- `rc`
- `stdout`
- `stderr`

### UNREACHABLE

Ansible managed node tak required connection establish nahi kar saka.

Possible reasons:

- wrong IP/hostname
- SSH issue
- wrong user
- wrong SSH key
- firewall/network issue
- DNS/name resolution problem

---

## 21. Complete Practice Exercise

### Step 1 — Directory Create

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-practice state=directory mode=0755" \
-i ./automation/inventory/nodes
```

First run:

```text
CHANGED
```

### Step 2 — Same Command Dobara Run Karein

Expected:

```text
SUCCESS
changed=false
```

Yahan idempotency prove hoti hai.

### Step 3 — Verify

```bash
ansible three_tier_app \
-m command \
-a "ls -ld /tmp/ansible-practice" \
-i ./automation/inventory/nodes
```

### Step 4 — File aur Content Add Karein

```bash
ansible three_tier_app \
-m copy \
-a 'content="Ansible practice lab\n" dest=/tmp/ansible-practice/readme.txt' \
-i ./automation/inventory/nodes
```

### Step 5 — File Read Karein

```bash
ansible three_tier_app \
-m command \
-a "cat /tmp/ansible-practice/readme.txt" \
-i ./automation/inventory/nodes
```

### Step 6 — Cleanup

```bash
ansible three_tier_app \
-m file \
-a "path=/tmp/ansible-practice state=absent" \
-i ./automation/inventory/nodes
```

---

## 22. Ab Tak Practice Kiye Gaye Modules

| Module | Kaam |
|---|---|
| `ping` | Ansible connectivity/module execution test |
| `command` | Managed nodes par command chalana |
| `debug` | Variables/messages display karna |
| `file` | Files/directories/permissions manage karna |
| `copy` | File copy ya content manage karna |

---

## 23. Important Options

| Option | Matlab |
|---|---|
| `-m` | Module |
| `-a` | Module arguments |
| `-i` | Inventory |
| `-vvv` | Detailed verbose troubleshooting |
| `--list-hosts` | Target hone wale hosts dikhana |

Important:

```bash
-a "hostname -f"
```

mein `-f` Linux `hostname` command ka option hai, Ansible ka nahi.

---

## 24. Ansible Mental Model

```text
Inventory
   ↓
Target / Group
   ↓
Module
   ↓
Arguments
   ↓
Desired State
   ↓
Actual State se compare
   ↓
Already correct?
   ├── YES → SUCCESS / changed=false
   └── NO  → change karo → CHANGED
```

Har command chalate waqt 6 sawal poochein:

1. **WHO?** Kis host/group ko target kar raha hoon?
2. **WHAT?** Kaunsa module use ho raha hai?
3. **HOW?** Kaun se arguments diye hain?
4. **WHAT CHANGED?** `changed=true` ya `false`?
5. **VERIFY?** Result ko kaise verify karunga?
6. **IDEMPOTENT?** Same command dobara chalane par kya hoga?

---

## 25. Interview Quick Review

### Ansible inventory kya hai?

Inventory managed hosts aur groups ko define karti hai jin par Ansible kaam karega.

### `-m` kya hai?

Kaunsa module use karna hai.

### `-a` kya hai?

Selected module ko arguments dene ke liye.

### `-i` kya hai?

Inventory source/file specify karta hai.

### `ansible_host` kya hai?

Actual IP/DNS address jis par Ansible connection karta hai.

### `inventory_hostname` kya hai?

Inventory ke andar host ka naam/alias.

### Idempotency kya hai?

Same desired-state task ko repeat karne se unnecessary changes nahi hotay jab system already required state mein ho.

### `CHANGED` aur `SUCCESS` mein farq?

`CHANGED` = task successful aur system mein change hua.

`SUCCESS` + `changed:false` = task successful, lekin change ki zaroorat nahi thi.

### `state=absent` kya hai?

Specified resource system par nahi hona chahiye.

### `rc=0` kya hai?

Executed command normally successfully complete hui.

---

## 26. Next Hands-On Labs

Is master notebook ko aage in topics ke sath continue karna useful hoga:

1. File ownership aur permissions
2. Control node se managed nodes par files copy karna
3. User aur group modules
4. `dnf` se package management
5. Services manage karna
6. Ansible facts / `setup`
7. `become` aur sudo
8. Pehla Ansible playbook

---

**Study Notes:** Ansible Hands-On Practice Lab — Roman Urdu  
**Last Updated:** September 10, 2026
