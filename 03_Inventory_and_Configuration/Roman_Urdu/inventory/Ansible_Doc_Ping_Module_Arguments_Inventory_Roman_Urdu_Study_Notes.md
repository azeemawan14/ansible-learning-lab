# Ansible Study Notes — Roman Urdu
## `ansible-doc`, `ping` Module Arguments, aur Temporary Inventory

## 1. In Notes ka Maqsad

In notes mein hum wohi Ansible concepts cover kar rahe hain jo lab mein practically run kiye gaye:

- `ansible-doc` se module help/documentation lena
- `ping` module ko samajhna
- Ad-hoc command mein `-a` ke through module arguments dena
- `data=hello` aur `data=crash` ka behavior
- Temporary/static inventory ko `-i` ke saath use karna
- Current lab inventory ka structure
- Inventory aur host variables inspect karne ke useful commands

---

# 2. `ansible-doc` — Ansible Module Help

Linux mein hum aksar command help ke liye use karte hain:

```bash
man ls
```

Ansible modules ke liye usi tarah ka documentation tool hai:

```bash
ansible-doc
```

## Basic Syntax

```bash
ansible-doc MODULE_NAME
```

Example:

```bash
ansible-doc ping
```

ya FQCN ke saath:

```bash
ansible-doc ping
```

---

## Useful `ansible-doc` Commands

### Full documentation dekhne ke liye

```bash
ansible-doc ping
```

### Short syntax/options dekhne ke liye

```bash
ansible-doc -s ping
```

`-s` bohat useful hai jab aap mainly yeh dekhna chahte hon:

- Parameters
- Options
- Expected values

### Available modules/plugins list karne ke liye

```bash
ansible-doc -l
```

### Module list mein search karne ke liye

```bash
ansible-doc -l | grep ping
```

Package module example:

```bash
ansible-doc -l | grep dnf
```

---

# 3. `ping` Module ko Samajhna

Ansible ka `ping` module normal Linux/network ICMP `ping` ke barabar nahi hai.

Normal network ping:

```bash
ping 192.168.1.154
```

yeh mainly network reachability check karta hai.

Ansible ping:

```bash
ansible web -m ping
```

yeh check karta hai ke Ansible managed host ke saath successfully communicate kar sakta hai aur module execute kar sakta hai.

Successful result aam tor par:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Simple flow:

```text
Control Node
    |
    | Ansible connection
    v
Managed Node
    |
    | Module execute hota hai
    v
Python / Module Execution
    |
    v
SUCCESS -> "pong"
```

---

# 4. Basic Ad-Hoc `ping` Command

Lab mein yeh command run ki gayi:

```bash
ansible web -m ping -i ./automation/inventory/
```

Result:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Command Breakdown

```text
ansible web -m ping -i ./automation/inventory/
   |      |    |              |
   |      |    |              +-- inventory path
   |      |    +----------------- module name
   |      +---------------------- target inventory group
   +----------------------------- Ansible ad-hoc command
```

### `web`

Yeh inventory ka target group hai.

### `-m ping`

`-m` batata hai ke konsa Ansible module chalana hai.

### `-i`

`-i` batata hai ke Ansible ko konsa inventory source use karna hai.

---

# 5. Module Arguments `-a` ke Saath

General syntax:

```bash
ansible TARGET -m MODULE -a "argument=value"
```

Example:

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

Yahan:

```text
-m ping
```

ka matlab:

> `ping` module use karo.

Aur:

```text
-a "data=hello"
```

ka matlab:

> Module ko `data=hello` argument do.

---

# 6. `data=hello`

Command:

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

Result:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "hello"
}
```

Normally ping module return karta hai:

```text
"ping": "pong"
```

Lekin jab hum pass karte hain:

```text
data=hello
```

to result aata hai:

```text
"ping": "hello"
```

Is se prove hota hai ke module argument successfully pass hua.

---

# 7. `data=crash`

Command:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

Command intentionally fail hui aur output mein aya:

```text
An exception occurred during task execution.
The error was: Exception: boom
```

aur:

```text
node1 | FAILED!
```

Yeh expected behavior hai.

`crash` value `ping` module ke liye special value hai jo jaan-boojh kar exception raise karti hai.

Iska maqsad yeh dekhna hai ke Ansible module failure ko kaise report karta hai.

## Simple Flow

```text
data=hello
     |
     v
Module successfully execute hota hai
     |
     v
"ping": "hello"
```

Compare:

```text
data=crash
     |
     v
Module intentionally exception raise karta hai
     |
     v
FAILED
Exception: boom
```

Is failure ka matlab yeh nahi ke SSH ya managed node broken tha.

Failure intentionally generate ki gayi thi.

---

# 8. Failure ki Zyada Detail Kaise Dekhein

Output ne suggest kiya:

```text
To see the full traceback, use -vvv
```

Is liye verbose command:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/ -vvv
```

`-vvv` zyada troubleshooting detail deta hai, including connection aur module execution information.

Normal commands ke liye hamesha `-vvv` use karna zaroori nahi.

---

# 9. Meri Temporary / Static Inventory File

Current inventory file:

```text
/home/ansibleadmin/automation/inventory/nodes
```

Confirm kiya:

```bash
realpath ./automation/inventory/nodes
```

Output:

```text
/home/ansibleadmin/automation/inventory/nodes
```

Current inventory structure:

```ini
# ============================================
# Ansible Static Inventory — Personal Lab
# ============================================

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

[database]
192.168.10.[1:20]

[sandbox]
server[1:9].nitclasses.com

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3

# Optional private SSH key
# ansible_ssh_private_key_file=/home/ansibleadmin/.ssh/id_ed25519
```

---

# 10. Inventory Structure Samajhna

## Control Group

```ini
[control]
ansible-server ansible_connection=local
```

Iska matlab `ansible-server` control group mein hai.

```text
ansible_connection=local
```

Ansible ko batata hai ke is host ke liye SSH use na karo, local execution karo.

---

## Web Group

```ini
[web]
node1 ansible_host=192.168.1.154
```

Yahan:

```text
node1
```

inventory name/alias hai.

Aur:

```text
ansible_host=192.168.1.154
```

actual IP hai jahan Ansible connect karega.

```text
node1
   |
   +--> ansible_host
           |
           v
      192.168.1.154
```

---

## App Group

```ini
[app]
node2 ansible_host=192.168.1.185
```

`node2` app group mein hai.

---

## DB Group

```ini
[db]
node3 ansible_host=192.168.1.190
```

`node3` db group mein hai.

---

# 11. Parent Group with `:children`

```ini
[three_tier_app:children]
web
app
db
```

Yeh parent group banata hai:

```text
three_tier_app
```

Is ke child groups hain:

```text
web
app
db
```

Conceptually:

```text
three_tier_app
├── web
│   └── node1
├── app
│   └── node2
└── db
    └── node3
```

Ab poore three-tier environment ko target kiya ja sakta hai:

```bash
ansible three_tier_app -m ping -i ~/automation/inventory/nodes
```

---

# 12. Host Range Examples

Inventory mein practice example:

```ini
[database]
192.168.10.[1:20]
```

Yeh range represent karti hai:

```text
192.168.10.1
192.168.10.2
192.168.10.3
...
192.168.10.20
```

Aur:

```ini
[sandbox]
server[1:9].nitclasses.com
```

represent karta hai:

```text
server1.nitclasses.com
server2.nitclasses.com
...
server9.nitclasses.com
```

## Important Lab Note

Agar yeh sirf examples hain aur actual hosts nahi hain, to:

```bash
ansible all -m ping
```

in hosts par bhi connect karne ki koshish karega aur failures aa sakte hain.

Clean lab ke liye unused example groups ko temporarily comment out karna behtar hai.

---

# 13. Global Inventory Variables

Inventory mein:

```ini
[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

`[all:vars]` ka matlab yeh variables inventory hosts inherit kar sakte hain.

## `ansible_user`

```ini
ansible_user=ansibleadmin
```

Yeh remote SSH user hai.

Equivalent idea:

```bash
ssh ansibleadmin@192.168.1.154
```

---

## `ansible_python_interpreter`

```ini
ansible_python_interpreter=/usr/bin/python3
```

Yeh Ansible ko batata hai ke managed node par Python-based modules ke liye konsa Python interpreter use karna hai.

---

# 14. Useful Inventory Inspection Commands

## Inventory hierarchy dekhna

```bash
ansible-inventory -i ~/automation/inventory/nodes --graph
```

Yeh useful hai:

- Groups
- Child groups
- Hosts

samajhne ke liye.

---

## Ek host ke resolved variables dekhna

```bash
ansible-inventory -i ~/automation/inventory/nodes --host node1
```

Yeh especially useful hai variables dekhne ke liye:

```text
ansible_host
ansible_user
ansible_python_interpreter
```

`node1` ke kuch variables host line par defined hain aur kuch `[all:vars]` se inherit hote hain.

---

## Complete resolved inventory dekhna

```bash
ansible-inventory -i ~/automation/inventory/nodes --list
```

---

## Group ke hosts list karna

```bash
ansible web -i ~/automation/inventory/nodes --list-hosts
```

Expected idea:

```text
hosts (1):
  node1
```

---

# 15. Inventory Directory vs Inventory File

Yeh command work hui:

```bash
ansible web -m ping -i ./automation/inventory/
```

Yahan aapne inventory directory di.

More explicit form:

```bash
ansible web -m ping -i ./automation/inventory/nodes
```

Dono work kar sakte hain agar directory valid inventory sources contain karti ho.

Learning aur troubleshooting ke liye exact inventory file dena zyada clear hota hai:

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

Is se ambiguity kam hoti hai.

---

# 16. Short Form vs FQCN

Yeh work karta hai:

```bash
ansible web -m ping
```

Full module name:

```bash
ansible web -m ping
```

Ad-hoc practice mein short name convenient hai.

Playbooks aur documentation mein FQCN zyada clear hota hai:

```yaml
- name: Test managed host
  ping:
```

---

# 17. Ad-Hoc Command Pattern Yaad Rakhein

Useful general pattern:

```bash
ansible <target> -m <module> -a "<module arguments>" -i <inventory>
```

Lab example:

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Breakdown:

```text
ansible
   |
   +-- web                  -> target group
   |
   +-- -m ping              -> module
   |
   +-- -a "data=hello"      -> module argument
   |
   +-- -i .../nodes         -> inventory source
```

---

# 18. Commands Jo Lab Mein Practice Kiye

### Default Ansible ping

```bash
ansible web -m ping -i ./automation/inventory/
```

### Custom data pass ki

```bash
ansible web -m ping -a "data=hello" -i ./automation/inventory/
```

### Intentionally exception generate ki

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

### Exact inventory path find ki

```bash
realpath ./automation/inventory/nodes
```

Result:

```text
/home/ansibleadmin/automation/inventory/nodes
```

---

# 19. Ek Chhota Environment Lesson

Command:

```bash
explorer.exe .
```

ne return kiya:

```text
-bash: explorer.exe: command not found
```

Yeh is liye kyun ke `explorer.exe` Windows executable hai.

WSL mein yeh aksar chal jata hai kyun ke WSL Windows executables ko call kar sakta hai.

Lekin normal Linux VM/server par Windows Explorer available nahi hota.

Linux mein use karein:

```bash
pwd
ls
ls -la
```

ya:

```bash
cd ~/automation/inventory
ls -l
```

---

# 20. Quick Revision

## Documentation

```bash
ansible-doc ping
```

Full help.

```bash
ansible-doc -s ping
```

Short syntax/options.

---

## Module

```bash
-m ping
```

Module select karta hai.

---

## Arguments

```bash
-a "data=hello"
```

Module ko arguments deta hai.

---

## Inventory

```bash
-i ~/automation/inventory/nodes
```

Inventory source select karta hai.

---

## Default `ping`

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

Expected:

```text
"ping": "pong"
```

---

## Custom Data

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Expected:

```text
"ping": "hello"
```

---

## Intentional Failure

```bash
ansible web -m ping -a "data=crash" -i ~/automation/inventory/nodes
```

Expected:

```text
FAILED
Exception: boom
```

---

# 21. Best Learning Sequence

Best study flow:

```text
1. ansible-doc
        ↓
2. Module samjho
        ↓
3. Ad-hoc command mein module run karo
        ↓
4. Module arguments pass karo
        ↓
5. Inventory groups target karo
        ↓
6. Inventory variables inspect karo
        ↓
7. Same module ko playbook mein use karo
```

Yeh direct large playbooks par jump karne se behtar hai kyun ke har layer clear ho jati hai.

---

# 22. Key Interview / Study Points

- `ansible-doc` Ansible modules/plugins ki documentation deta hai.
- `-m` module select karta hai.
- `-a` selected module ko arguments deta hai.
- `-i` inventory source select karta hai.
- Ansible `ping`, ICMP/network ping nahi hai.
- Successful Ansible ping normally `pong` return karta hai.
- `data=hello` module argument passing ko demonstrate karta hai.
- `data=crash` intentionally exception raise karta hai.
- `node1` jaisa inventory alias `ansible_host` ke through actual IP par map ho sakta hai.
- `[all:vars]` ke variables hosts inherit kar sakte hain.
- `ansible-inventory --graph` inventory structure dikhata hai.
- `ansible-inventory --host node1` ek host ke resolved variables dekhne ke liye bohat useful hai.

---

# 23. Meri Lab Summary

Current working setup:

```text
ansible-server
      |
      | Ansible
      v
[web]
node1
      |
      +--> 192.168.1.154
      |
      +--> ansible_user=ansibleadmin
      |
      +--> ansible_python_interpreter=/usr/bin/python3
```

Successful test:

```bash
ansible web -m ping -i ~/automation/inventory/nodes
```

Successful argument test:

```bash
ansible web -m ping -a "data=hello" -i ~/automation/inventory/nodes
```

Intentional failure test:

```bash
ansible web -m ping -a "data=crash" -i ~/automation/inventory/nodes
```

Yeh foundation aage Ansible modules aur playbooks samajhne ke liye bohat strong hai.
