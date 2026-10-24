# Ansible Command Output Colors — Roman Urdu Study Notes

## 1. Ansible Colors Kyun Use Karta Hai?

Ansible terminal output mein colors use karta hai taa-ke aap task ka result jaldi samajh saken.

Sab se useful memory rule:

```text
🟢 GREEN  = OK / SUCCESS
🟡 YELLOW = CHANGED
🔵 BLUE   = SKIPPED
🔴 RED    = FAILED
```

> Important: Colors output ko jaldi scan karne mein help karte hain, lekin sirf color par depend na karein. `ok`, `changed`, `failed`, `skipped`, `UNREACHABLE` aur actual error message bhi zaroor parhein.

---

## 2. 🟢 Green — SUCCESS / OK

Green ka aam tor par matlab hai:

> Task successfully complete hui, lekin Ansible ko managed node par koi change karne ki zaroorat nahi pari.

Example:

```bash
ansible web -m ping
```

Possible output:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Important part:

```text
"changed": false
```

Iska matlab:

> Kaam successful hua, lekin managed system mein koi modification nahi hui.

### Ek Aur Example

Agar Apache pehle se installed hai aur playbook mein ho:

```yaml
- name: Make sure Apache is installed
  dnf:
    name: httpd
    state: present
```

Ansible check karega aur agar `httpd` already installed hai to output aa sakta hai:

```text
ok: [node1]
```

### Yaad Rakhein

```text
🟢 GREEN
   ↓
SUCCESS / OK
   ↓
changed: false
   ↓
Task successful, koi change zaroori nahi tha
```

---

## 3. 🟡 Yellow — CHANGED

Yellow ka aam tor par matlab hai:

> Task successfully complete hui AUR Ansible ne managed node par actual change kiya.

Example:

```yaml
- name: Install Apache
  dnf:
    name: httpd
    state: present
```

Agar Apache pehle installed nahi tha, Ansible output de sakta hai:

```text
changed: [node1]
```

Before:

```text
httpd = not installed
```

Ansible task run karta hai.

After:

```text
httpd = installed
```

Is liye:

```text
changed: true
```

### Important

Is context mein yellow ka matlab warning ya failure nahi hai.

Iska matlab:

```text
🟡 YELLOW
   ↓
CHANGED
   ↓
Task successful
   +
Managed system modify hua
```

---

## 4. Green vs Yellow

Yeh Ansible ka bohat important concept hai.

```text
GREEN
changed: false
     ↓
Successful
     ↓
Koi change nahi hua
```

Compare karein:

```text
YELLOW
changed: true
     ↓
Successful
     ↓
Kuch change hua
```

Example:

Pehli dafa task run ki:

```text
changed: [node1]
```

Ansible ne kuch install/configure kiya.

Wohi idempotent task dobara run ki:

```text
ok: [node1]
```

Desired state already mojood thi, is liye dobara change ki zaroorat nahi pari.

---

## 5. 🔴 Red — FAILED

Red normally batata hai ke task fail ho gayi.

Hamari lab ka example:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

Output mein aya:

```text
node1 | FAILED! => {
    "changed": false,
    "msg": "MODULE FAILURE",
    "rc": 1
}
```

`ping` module mein:

```text
data=crash
```

ek special value hai jo jaan-boojh kar exception raise karti hai.

Is liye hamari lab mein yeh failure expected thi.

Real-world failures ki possible wajahen:

- Invalid module parameters
- Required privileges na hona
- Package/repository problem
- Galat command
- Configuration error
- Service problem
- Module execution error

### Yaad Rakhein

```text
🔴 RED
   ↓
FAILED
   ↓
Error message parhein
   ↓
Actual cause troubleshoot karein
```

---

## 6. 🔵 Blue/Cyan — SKIPPED

Blue/cyan aam tor par skipped task ko represent karta hai.

Example:

```yaml
- name: Install Apache only on Red Hat systems
  dnf:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

Suppose:

```text
node1 = Rocky Linux
node2 = Ubuntu
```

Output ho sakta hai:

```text
changed: [node1]
skipping: [node2]
```

`node2` kyun skip hua?

Kyun ke condition:

```yaml
when: ansible_os_family == "RedHat"
```

Ubuntu ke liye true nahi thi.

Is liye:

```text
🔵 BLUE
   ↓
SKIPPED
   ↓
Task execute nahi hui
   ↓
Aam tor par condition apply nahi hui
```

Skipped task ka matlab automatically problem nahi hota.

---

## 7. UNREACHABLE

Ek aur bohat important Ansible status hai:

```text
UNREACHABLE!
```

Example:

```text
node2 | UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh..."
}
```

Iska matlab Ansible managed host ke saath required connection establish nahi kar saka.

Possible reasons:

- Wrong IP address ya hostname
- SSH service available nahi
- Firewall issue
- Wrong SSH user
- Wrong SSH key
- DNS problem
- Network connectivity problem

Sirf exact color par depend na karein.

Yeh status dekhein:

```text
UNREACHABLE!
```

aur especially:

```text
msg
```

ko parhein.

---

## 8. Meri `ping` Module Practice

### Test 1 — Normal Ping

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

Meaning:

```text
🟢 Green
SUCCESS
changed: false
```

Ansible successfully connect hua aur module execute hua, lekin managed node modify nahi hua.

---

### Test 2 — `data=hello`

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

Meaning:

```text
🟢 Green
SUCCESS
changed: false
```

Custom module argument successfully pass hua, lekin system state change nahi hui.

---

### Test 3 — `data=crash`

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

Result mein aya:

```text
node1 | FAILED!
Exception: boom
```

Meaning:

```text
🔴 Red
FAILED
```

Yeh failure intentionally:

```text
data=crash
```

use karke generate ki gayi thi.

---

## 9. `ping` Normally Yellow Kyun Nahi Dikhata?

`ping` module normally Ansible connectivity aur module execution test karta hai.

Yeh aam tor par managed system ko modify nahi karta.

Is liye successful output normally:

```text
"changed": false
```

hota hai aur green nazar aata hai.

Yellow `changed` naturally dekhne ke liye aise modules useful hain jo system state modify karte hain:

```text
dnf
file
user
copy
service
```

Misal ke taur par agar aap ek nayi directory create karte hain jo pehle exist nahi karti, to Ansible `changed` dikha sakta hai.

---

## 10. Quick Color Table

| Color | Typical Status | Roman Urdu Meaning |
|---|---|---|
| 🟢 Green | `ok` / `SUCCESS` | Task successful, koi change nahi hua |
| 🟡 Yellow | `changed` | Task successful aur system change hua |
| 🔵 Blue/Cyan | `skipped` | Task execute nahi hui |
| 🔴 Red | `failed` | Task fail ho gayi |

Ansible version, callback plugin, terminal aur configuration ke mutabiq doosre colors bhi nazar aa sakte hain.

---

## 11. Best Troubleshooting Habit

Problem ko sirf color dekh kar diagnose **na karein**.

Actual output zaroor parhein.

In statuses ko dekhein:

```text
ok
changed
failed
skipped
UNREACHABLE
```

Aur jab available hon to yeh fields bhi check karein:

```text
changed: true
changed: false
msg
rc
stdout
stderr
```

Example:

```text
🔴 Red
   ↓
FAILED
   ↓
"msg" parhein
   ↓
Error samjhein
   ↓
Actual cause troubleshoot karein
```

---

## 12. Interview-Ready Answer

Agar interviewer pooche:

**“What do Ansible output colors mean?”**

Aap keh sakte hain:

> Ansible output colors task results ko quickly identify karne mein help karte hain. Green generally successful task ko show karta hai jahan koi change nahi hua. Yellow ka matlab task successful hui aur managed system par change hua. Red failure ko indicate karta hai, jab ke blue/cyan commonly skipped task ko show karta hai. Main sirf colors par depend nahi karta; main `ok`, `changed`, `failed`, `skipped`, `UNREACHABLE` aur detailed error message bhi check karta hoon.

---

# Quick Revision

```text
🟢 GREEN
OK / SUCCESS
changed: false
Koi change nahi hua
```

```text
🟡 YELLOW
CHANGED
changed: true
Task successful + system modify hua
```

```text
🔵 BLUE
SKIPPED
Task execute nahi hui
```

```text
🔴 RED
FAILED
Error parhein aur troubleshoot karein
```

Sab se important formula:

```text
COLOR = Quick visual clue

STATUS + MESSAGE = Actual information
```
