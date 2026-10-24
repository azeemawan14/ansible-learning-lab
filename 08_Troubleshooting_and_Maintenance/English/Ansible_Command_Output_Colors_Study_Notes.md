# Ansible Command Output Colors — Study Notes

## 1. Why Ansible Uses Colors

Ansible uses colors in terminal output to help you quickly understand the result of a task.

A useful memory rule is:

```text
🟢 GREEN  = OK / SUCCESS
🟡 YELLOW = CHANGED
🔵 BLUE   = SKIPPED
🔴 RED    = FAILED
```

> Important: Colors are useful for quickly scanning output, but always read the actual status words and messages such as `ok`, `changed`, `failed`, `skipped`, and `UNREACHABLE`.

---

## 2. 🟢 Green — SUCCESS / OK

Green normally means:

> The task completed successfully and Ansible did not need to change the managed node.

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

The important part is:

```text
"changed": false
```

This means the operation was successful, but nothing on the managed system was modified.

### Another Example

Suppose Apache is already installed and a playbook contains:

```yaml
- name: Make sure Apache is installed
  dnf:
    name: httpd
    state: present
```

If `httpd` is already installed, Ansible may report:

```text
ok: [node1]
```

### Remember

```text
🟢 GREEN
   ↓
SUCCESS / OK
   ↓
changed: false
   ↓
Task successful, no system modification required
```

---

## 3. 🟡 Yellow — CHANGED

Yellow normally means:

> The task completed successfully AND Ansible changed something on the managed node.

Example:

```yaml
- name: Install Apache
  dnf:
    name: httpd
    state: present
```

If Apache was not previously installed, Ansible may display:

```text
changed: [node1]
```

Before:

```text
httpd = not installed
```

Ansible performs the task.

After:

```text
httpd = installed
```

Therefore:

```text
changed: true
```

### Important

Yellow does **not** normally mean warning or failure in this situation.

It means:

```text
🟡 YELLOW
   ↓
CHANGED
   ↓
Task successful
   +
Managed system was modified
```

---

## 4. Green vs Yellow

This distinction is very important in Ansible.

```text
GREEN
changed: false
     ↓
Successful
     ↓
Nothing needed to change
```

Compared with:

```text
YELLOW
changed: true
     ↓
Successful
     ↓
Something was changed
```

Example:

First run:

```text
changed: [node1]
```

Ansible installs/configures something.

Second run of the same idempotent task:

```text
ok: [node1]
```

The desired state already exists, so Ansible does not need to change it again.

---

## 5. 🔴 Red — FAILED

Red normally indicates that a task failed.

Example from the lab:

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

Output included:

```text
node1 | FAILED! => {
    "changed": false,
    "msg": "MODULE FAILURE",
    "rc": 1
}
```

The `ping` module treats:

```text
data=crash
```

as a special value that intentionally raises an exception.

Therefore, this particular failure was expected.

Possible real-world causes of failures include:

- Invalid module parameters
- Missing privileges
- Package/repository problems
- Bad commands
- Configuration errors
- Service problems
- Other module execution errors

### Remember

```text
🔴 RED
   ↓
FAILED
   ↓
Read the error message
   ↓
Investigate the cause
```

---

## 6. 🔵 Blue/Cyan — SKIPPED

Blue/cyan commonly represents a task that Ansible skipped.

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

Ansible might report:

```text
changed: [node1]
skipping: [node2]
```

Why was `node2` skipped?

Because this condition:

```yaml
when: ansible_os_family == "RedHat"
```

was not true for Ubuntu.

So:

```text
🔵 BLUE
   ↓
SKIPPED
   ↓
Task was not executed
   ↓
Usually because a condition did not apply
```

A skipped task is not automatically a problem.

---

## 7. UNREACHABLE

Another very important Ansible status is:

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

This means Ansible could not establish the required connection to the managed host.

Possible causes include:

- Wrong IP address or hostname
- SSH service unavailable
- Firewall issue
- Wrong SSH user
- Wrong SSH key
- DNS problem
- Network connectivity problem

Do not depend only on the exact displayed color. Read:

```text
UNREACHABLE!
```

and especially the accompanying `msg`.

---

## 8. My `ping` Module Practice

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

Ansible successfully connected and executed the module without modifying the managed node.

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

The custom module argument worked, but no system state was changed.

---

### Test 3 — `data=crash`

```bash
ansible web -m ping -a "data=crash" -i ./automation/inventory/
```

Result included:

```text
node1 | FAILED!
Exception: boom
```

Meaning:

```text
🔴 Red
FAILED
```

This failure was intentionally generated by using:

```text
data=crash
```

---

## 9. Why `ping` Usually Does Not Produce Yellow

The `ping` module normally tests Ansible connectivity/module execution.

It does not normally modify the managed system.

Therefore its successful output usually contains:

```text
"changed": false
```

and appears green.

To naturally see yellow `changed` output, modules that modify system state are more useful, such as:

```text
dnf
file
user
copy
service
```

For example, creating a directory that does not exist can produce `changed`.

---

## 10. Quick Color Table

| Color | Typical Status | Meaning |
|---|---|---|
| 🟢 Green | `ok` / `SUCCESS` | Successful; nothing changed |
| 🟡 Yellow | `changed` | Successful; system was changed |
| 🔵 Blue/Cyan | `skipped` | Task was not executed |
| 🔴 Red | `failed` | Task failed |

Other colors can appear depending on the Ansible version, callback plugin, terminal, and configuration.

---

## 11. Best Troubleshooting Habit

Do **not** diagnose a problem only from the color.

Always read the actual output.

Look for:

```text
ok
changed
failed
skipped
UNREACHABLE
```

Also check:

```text
changed: true
changed: false
msg
rc
stdout
stderr
```

when they are present.

Example:

```text
🔴 Red
   ↓
FAILED
   ↓
Read "msg"
   ↓
Understand the error
   ↓
Troubleshoot the actual cause
```

---

## 12. Interview-Ready Explanation

If an interviewer asks:

**“What do Ansible output colors mean?”**

A concise answer is:

> Ansible uses colors to make task results easier to identify. Green generally indicates a successful task with no change, while yellow indicates that the task succeeded and changed the managed system. Red indicates a failure, and blue/cyan commonly indicates a skipped task. I do not rely only on the color; I also check statuses such as `ok`, `changed`, `failed`, `skipped`, and `UNREACHABLE`, along with the detailed message.

---

# Quick Revision

```text
🟢 GREEN
OK / SUCCESS
changed: false
Nothing changed
```

```text
🟡 YELLOW
CHANGED
changed: true
Task successful + system modified
```

```text
🔵 BLUE
SKIPPED
Task did not run
```

```text
🔴 RED
FAILED
Read the error and troubleshoot
```

And remember:

```text
COLOR = quick visual clue

STATUS + MESSAGE = actual information
```
