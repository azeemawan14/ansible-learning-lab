# SSH Banner Using Ansible Ad-Hoc Commands — Study Notes

This lab configures an SSH pre-login banner on `node1`, `node2`, and `node3` by using suitable Ansible ad-hoc commands.

It forms the middle stage of this learning sequence:

```text
Manual configuration on one node
             ↓
Ad-hoc commands on all managed nodes
             ↓
Reusable playbook with a handler
```

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [Why this is a suitable ad-hoc demonstration](#3-why-this-is-a-suitable-ad-hoc-demonstration)
4. [Important safety rules](#4-important-safety-rules)
5. [Step 1 — Move into the project directory](#5-step-1--move-into-the-project-directory)
6. [Step 2 — Verify connectivity](#6-step-2--verify-connectivity)
7. [Step 3 — Create the banner with `copy`](#7-step-3--create-the-banner-with-copy)
8. [Step 4 — Inspect the banner](#8-step-4--inspect-the-banner)
9. [Step 5 — Configure `sshd_config` with `lineinfile`](#9-step-5--configure-sshd_config-with-lineinfile)
10. [Step 6 — Validate SSH configuration](#10-step-6--validate-ssh-configuration)
11. [Step 7 — Verify the effective setting](#11-step-7--verify-the-effective-setting)
12. [Step 8 — Reload and verify `sshd`](#12-step-8--reload-and-verify-sshd)
13. [Step 9 — Test the banner](#13-step-9--test-the-banner)
14. [Complete command sequence](#14-complete-command-sequence)
15. [Idempotency behavior](#15-idempotency-behavior)
16. [Ad-hoc commands vs playbook](#16-ad-hoc-commands-vs-playbook)
17. [Rollback](#17-rollback)
18. [Troubleshooting](#18-troubleshooting)
19. [Module summary](#19-module-summary)
20. [Review questions](#20-review-questions)

---

## 1. Learning objectives

After completing this lab, you should be able to:

- Configure an SSH banner across multiple managed nodes.
- Select a purpose-built Ansible module for each operation.
- Use `inventory_hostname` to customize content per host.
- Back up and safely validate `sshd_config`.
- Explain why `reload` is preferred over `restart` for this change.
- Identify which ad-hoc steps are idempotent.
- Explain why a playbook with a handler remains the better reusable solution.

## 2. Lab environment

| Role | Host | IP address |
|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` |
| Managed node | `node1` | `192.168.1.154` |
| Managed node | `node2` | `192.168.1.185` |
| Managed node | `node3` | `192.168.1.190` |

Inventory group:

```text
three_tier_app
```

Remote user:

```text
ansibleadmin
```

Project directory:

```text
/home/ansibleadmin/automation
```

## 3. Why this is a suitable ad-hoc demonstration

The job contains several small tasks, and each task maps naturally to an Ansible module:

| Requirement | Suitable module | Reason |
|---|---|---|
| Check connectivity | `ping` | Tests Ansible communication and Python availability |
| Create the banner file | `copy` | Manages content, ownership, and mode idempotently |
| Inspect the file | `command` / `stat` | Reads content or metadata without editing it |
| Configure `sshd_config` | `lineinfile` | Manages one configuration directive idempotently |
| Validate configuration | `command` | Runs `sshd -t` without requiring shell features |
| Filter effective settings | `shell` | A pipe to `grep` requires a shell |
| Apply the configuration | `service` | Manages the SSH service state |

Ad-hoc commands are appropriate for demonstrating the individual operations. A playbook is still preferable for repeated or production automation.

## 4. Important safety rules

- Keep the current SSH session open.
- Test the final banner from a second terminal.
- Create a backup of `sshd_config` before changing it.
- Validate SSH configuration before reloading the service.
- Do not reload or restart `sshd` if validation fails.
- Prefer `reload` instead of `restart` for this configuration change.
- Test on `node1` first when learning or changing the command.

Limit a command to `node1` with:

```bash
--limit node1
```

## 5. Step 1 — Move into the project directory

```bash
cd /home/ansibleadmin/automation
```

This is important because the current directory may contain the active `ansible.cfg` and relative inventory path.

Confirm the active configuration:

```bash
ansible --version
ansible-config dump --only-changed
```

## 6. Step 2 — Verify connectivity

```bash
ansible three_tier_app -m ping
```

Expected result from every managed node:

```text
"ping": "pong"
```

Do not modify SSH configuration until all intended nodes are reachable.

## 7. Step 3 — Create the banner with `copy`

First test on `node1`:

```bash
ansible three_tier_app -b --limit node1 -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

After checking `node1`, apply it to all three nodes:

```bash
ansible three_tier_app -b -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

The variable produces host-specific text:

| Host | Generated line |
|---|---|
| `node1` | `Welcome to node1 — NIT Classes Ansible Lab` |
| `node2` | `Welcome to node2 — NIT Classes Ansible Lab` |
| `node3` | `Welcome to node3 — NIT Classes Ansible Lab` |

The `copy` module manages:

- File content
- Destination path
- Owner
- Group
- Permissions

## 8. Step 4 — Inspect the banner

Display its content:

```bash
ansible three_tier_app -m command -a \
"cat /etc/ssh/banner.txt"
```

Inspect metadata:

```bash
ansible three_tier_app -m stat -a \
"path=/etc/ssh/banner.txt"
```

Important expected values:

```text
exists: true
mode: 0644
pw_name: root
gr_name: root
```

## 9. Step 5 — Configure `sshd_config` with `lineinfile`

First test on `node1`:

```bash
ansible three_tier_app -b --limit node1 -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Then apply it to all managed nodes:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Argument explanation:

| Argument | Meaning |
|---|---|
| `path` | File Ansible manages |
| `regexp` | Matches commented or active `Banner` directives |
| `line` | Exact required directive |
| `state=present` | Ensures the line exists |
| `backup=yes` | Creates a backup when a change is made |
| `validate` | Tests the temporary file before replacing the live configuration |
| `%s` | Temporary candidate-file path supplied by Ansible |

Required final directive:

```text
Banner /etc/ssh/banner.txt
```

The validation option is especially valuable: an invalid temporary configuration should be rejected instead of replacing the working configuration.

## 10. Step 6 — Validate SSH configuration

Although `lineinfile` validates before saving, perform an explicit demonstration:

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"
```

Expected result:

```text
rc=0
```

No output normally means the syntax is valid. Any error must be corrected before reloading `sshd`.

## 11. Step 7 — Verify the effective setting

Use `sshd -T` to print effective SSH server configuration. A pipe is needed to filter the result, so this step uses `shell`:

```bash
ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"
```

Expected output:

```text
banner /etc/ssh/banner.txt
```

The ad-hoc `shell` module normally reports `CHANGED` when its command succeeds, even though this verification command does not modify the system.

## 12. Step 8 — Reload and verify `sshd`

Reload only after validation succeeds:

```bash
ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"
```

Why use reload?

- It rereads the configuration.
- It is less disruptive than a full restart.
- Existing SSH sessions normally remain connected.

Verify the service:

```bash
ansible three_tier_app -m command -a \
"systemctl is-active sshd"
```

Expected output:

```text
active
```

## 13. Step 9 — Test the banner

Use a second terminal while keeping the original session open:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ssh -i ~/.ssh/ansible-key ansibleadmin@node2
ssh -i ~/.ssh/ansible-key ansibleadmin@node3
```

The banner should appear before authentication completes.

For detailed SSH troubleshooting:

```bash
ssh -v -i ~/.ssh/ansible-key ansibleadmin@node1
```

## 14. Complete command sequence

```bash
cd /home/ansibleadmin/automation

ansible three_tier_app -m ping

ansible three_tier_app -b -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'

ansible three_tier_app -m command -a \
"cat /etc/ssh/banner.txt"

ansible three_tier_app -m stat -a \
"path=/etc/ssh/banner.txt"

ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'

ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"

ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"

ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"

ansible three_tier_app -m command -a \
"systemctl is-active sshd"
```

## 15. Idempotency behavior

| Step | Idempotent status behavior |
|---|---|
| `copy` | Reports no change when content, ownership, group, and mode are already correct |
| `lineinfile` | Reports no change when the correct directive already exists |
| `stat` | Read-only; does not change the system |
| `command` validation | Usually reported as successful execution, not configuration management |
| `shell` verification | Normally reports `CHANGED` even though it only reads data |
| `service state=reloaded` | Reload action normally reports a change each time it is requested |

To demonstrate idempotency clearly, run `copy` and `lineinfile` twice. On the second run, both should normally return `changed=false`.

The ad-hoc workflow cannot automatically connect the change result to a conditional service reload. A playbook handler solves that problem.

## 16. Ad-hoc commands vs playbook

| Feature | Ad-hoc commands | Playbook |
|---|---|---|
| Best use | Quick, one-time operation | Repeatable automation |
| Multiple steps | Run manually in order | Stored in YAML order |
| Error coordination | Operator must stop after a failure | Can control task flow |
| Conditional reload | Manual decision | Handler runs only when notified |
| Documentation | Command history or notes | Automation is self-documenting |
| Reuse | Limited | High |
| Version control | Awkward | Natural fit |

Recommended learning order:

```text
Manual method → Ad-hoc modules → Playbook → Handler → Role/AWX job template
```

## 17. Rollback

### Find configuration backups

```bash
ansible three_tier_app -b -m shell -a \
"ls -1t /etc/ssh/sshd_config.*~ 2>/dev/null | head"
```

Backup filenames produced by Ansible can vary. Review the output before restoring anything.

### Disable the banner directive safely

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="#Banner none" backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Validate:

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"
```

Reload:

```bash
ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"
```

Optionally remove the banner file:

```bash
ansible three_tier_app -b -m file -a \
"path=/etc/ssh/banner.txt state=absent"
```

## 18. Troubleshooting

### Banner does not appear

Check the effective setting:

```bash
ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"
```

Check the file:

```bash
ansible three_tier_app -m command -a \
"ls -l /etc/ssh/banner.txt"
```

### Validation fails

Run with more verbosity:

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t" -vv
```

Do not reload until the error is resolved.

### One node is unreachable

Test that host only:

```bash
ansible node2 -m ping -vvvv
ssh -v -i ~/.ssh/ansible-key ansibleadmin@node2
```

### `sudo` asks for a password

Verify non-interactive sudo:

```bash
ansible three_tier_app -m command -a \
"sudo -n whoami"
```

Expected output:

```text
root
```

### Multiple Banner directives exist

Inspect the main file and drop-in directory:

```bash
ansible three_tier_app -b -m shell -a \
"grep -RniE '^[[:space:]]*Banner[[:space:]]+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null"
```

Use `sshd -T` as the final authority for the effective value.

## 19. Module summary

| Module | Job in this lab |
|---|---|
| `ping` | Verify Ansible connectivity |
| `copy` | Create and manage `/etc/ssh/banner.txt` |
| `command` | Display files, validate SSH, and check service state |
| `stat` | Inspect banner-file metadata |
| `lineinfile` | Manage the `Banner` directive |
| `shell` | Run verification commands that require pipes or redirection |
| `service` | Reload `sshd` |
| `file` | Remove the banner during rollback |

## 20. Review questions

1. Why is `copy` more suitable than `shell` for creating the banner file?
2. What does `inventory_hostname` provide?
3. What does the `regexp` argument do in `lineinfile`?
4. Why is `backup=yes` useful?
5. What does `%s` represent in the validation command?
6. What does no output from `sshd -t` normally mean?
7. Why is `shell` used for `sshd -T | grep ...`?
8. Why is `reload` preferred over `restart`?
9. Which steps demonstrate idempotency?
10. Why is a handler better than a separate ad-hoc reload command?

---

## Final recommendation

Use this ad-hoc lab to understand how individual modules solve individual tasks. For ongoing administration, keep the playbook version as the authoritative automation because it can validate changes and notify a handler to reload `sshd` only when necessary.
