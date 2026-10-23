# Ansible `lineinfile` Ad-Hoc Demo Lab

## Table of Contents

1. [Lab purpose](#1-lab-purpose)
2. [Lab environment](#2-lab-environment)
3. [`lineinfile` definition](#3-lineinfile-definition)
4. [Important corrections](#4-important-corrections)
5. [Command structure](#5-command-structure)
6. [Step-by-step demo](#6-step-by-step-demo)
7. [Idempotency test](#7-idempotency-test)
8. [Regular-expression explanation](#8-regular-expression-explanation)
9. [Verification commands](#9-verification-commands)
10. [Cleanup](#10-cleanup)
11. [Troubleshooting](#11-troubleshooting)
12. [Quick-reference table](#12-quick-reference-table)
13. [Practice assignment](#13-practice-assignment)

---

## 1. Lab purpose

This lab demonstrates how to use the Ansible `lineinfile` module through ad-hoc commands to:

- Add a line at the beginning of a file
- Add a line at the end of a file
- Add a line after a matching keyword
- Replace an existing line
- Remove a matching line
- Remove an exact line
- Test idempotency
- Match commented and active SSH `Banner` directives with regex
- Delete the complete practice file correctly

---

## 2. Lab environment

| Item | Value |
|---|---|
| Control node | `ansible-server` |
| Inventory group | `three_tier_app` |
| Managed nodes | `node1`, `node2`, `node3` |
| Remote user | `ansibleadmin` |
| Practice directory | `/tmp/ansible-module-lab` |
| Practice file | `/tmp/ansible-module-lab/lineinfile-demo.txt` |

Confirm that all managed nodes are reachable:

```bash
ansible three_tier_app -m ping
```

---

## 3. `lineinfile` definition

The Ansible `lineinfile` module manages individual lines in text files. It can add, replace, or remove a line while normally maintaining idempotency.

View its complete documentation:

```bash
ansible-doc lineinfile
```

View its short syntax reference:

```bash
ansible-doc -s lineinfile
```

---

## 4. Important corrections

### Add a line at the beginning

Use:

```text
insertbefore=BOF
```

Do not use:

```text
insertafter=BOF
```

`BOF` means **Beginning of File**.

### Add a line at the end

Use:

```text
insertafter=EOF
```

`EOF` means **End of File**.

### Delete the complete file

The `lineinfile` module removes lines—not the complete file. To delete a file, use:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt state=absent"
```

---

## 5. Command structure

```bash
ansible <host-pattern> -m lineinfile -a \
'path=<file> line="<text>" <position-or-regexp> state=present'
```

| Component | Meaning |
|---|---|
| `three_tier_app` | Target inventory group |
| `-m lineinfile` | Select the `lineinfile` module |
| `-a` | Supply module arguments |
| `path=` | File to manage on each managed node |
| `line=` | Line that should be present |
| `regexp=` | Pattern used to identify an existing line |
| `insertbefore=` | Insert before a matching line or `BOF` |
| `insertafter=` | Insert after a matching line or `EOF` |
| `state=present` | Ensure the line exists |
| `state=absent` | Ensure the matching line does not exist |
| `backup=yes` | Back up the file before changing it |

---

## 6. Step-by-step demo

### Step 1: Create the practice directory

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab state=directory mode=0755"
```

### Step 2: Create the initial practice file

```bash
ansible three_tier_app -m copy -a \
'content="This is the starting line.\nCourse: Ansible Basics\n" dest=/tmp/ansible-module-lab/lineinfile-demo.txt mode=0644'
```

### Step 3: Verify the initial content

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected file content:

```text
This is the starting line.
Course: Ansible Basics
```

> The `command` module may report `CHANGED` even though `cat` is only reading the file. This does not mean that `cat` modified the file.

### Step 4: Add a line at the beginning

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Welcome to the Ansible lab." insertbefore=BOF state=present backup=yes'
```

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
```

### Step 5: Add a line at the end

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Thanks for completing the practice." insertafter=EOF state=present'
```

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
Thanks for completing the practice.
```

### Step 6: Add a line after a specific keyword

Insert a new line after the line beginning with `Course:`:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt insertafter="^Course:" line="Lab group: three_tier_app" state=present'
```

Verify:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
Lab group: three_tier_app
Thanks for completing the practice.
```

### Step 7: Replace an existing line

Replace the existing `Course:` line:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt regexp="^Course:" line="Course: Ansible Automation" state=present backup=yes'
```

Expected line:

```text
Course: Ansible Automation
```

### Step 8: Remove a line by regular expression

Remove the line beginning with `Lab group:`:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt regexp="^Lab group:" state=absent'
```

### Step 9: Remove an exact line

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Thanks for completing the practice." state=absent'
```

### Step 10: Display the final content

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Automation
```

---

## 7. Idempotency test

Run the same `lineinfile` command twice:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Welcome to the Ansible lab." insertbefore=BOF state=present'
```

The first execution may report:

```text
changed: true
```

The second execution should report:

```text
changed: false
```

Ansible does not duplicate the line because it already exists in the requested state.

---

## 8. Regular-expression explanation

Consider this pattern:

```text
^Course:
```

| Part | Meaning |
|---|---|
| `^` | Beginning of the line |
| `Course:` | Literal text that must follow |

It matches:

```text
Course: Ansible Basics
```

It does not match:

```text
My Course: Ansible Basics
```

Another example:

```text
^Lab group:
```

This matches any line that begins with `Lab group:`.

> When replacing a configuration line, write a pattern that matches both the old and the desired forms whenever practical. This helps preserve idempotency.

### Practical SSH `Banner` regex

The following pattern matches a typical SSH `Banner` directive whether it is commented or active:

```regex
^\s*#?\s*Banner\s+.*$
```

| Regex part | Meaning |
|---|---|
| `^` | Start of the line |
| `\s*` | Zero or more whitespace characters |
| `#?` | An optional `#` comment character |
| `\s*` | Zero or more spaces after `#` |
| `Banner` | The exact SSH directive name |
| `\s+` | One or more whitespace characters after `Banner` |
| `.*` | The remaining value on the line |
| `$` | End of the line |

Examples that match:

```text
#Banner none
# Banner /etc/issue.net
Banner none
    Banner /etc/ssh/banner.txt
```

Examples that do not match:

```text
BannerFile /tmp/banner.txt
MyBanner none
```

The anchors `^` and `$` prevent unrelated text that merely contains `Banner` from matching.

First test the change only on `node1`:

```bash
ansible three_tier_app -b --limit node1 -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

After verifying `node1`, apply it to all three managed nodes:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Important behavior:

- If one line matches, `lineinfile` replaces it with the required line.
- If no line matches, Ansible normally adds the required line at the end of the file.
- If several lines match, `lineinfile` normally changes the last matching line. Use the `replace` module when every matching line must change.
- `backup=yes` creates a backup when Ansible changes the file.
- `validate` checks the temporary SSH configuration before Ansible replaces the live file.
- `%s` represents the temporary candidate file created by Ansible.
- A second run should report `changed=false` when the required line is already correct.

Inspect possible matches before making the change:

```bash
ansible three_tier_app -b -m shell -a \
"grep -nE '^[[:space:]]*#?[[:space:]]*Banner[[:space:]]+.*$' /etc/ssh/sshd_config"
```

The `grep` example uses POSIX character classes. Ansible's `regexp` uses Python-style `\s`; both forms describe whitespace for their respective tools.

---

## 9. Verification commands

### Display the file

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

### Search for one line

This particular `grep` command does not require a pipe, so use the `command` module:

```bash
ansible three_tier_app -m command -a \
"grep ^Course: /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Use the `shell` module only when shell syntax such as a pipe is genuinely required. Example:

```bash
ansible three_tier_app -m shell -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt | grep '^Course:'"
```

### Inspect file metadata

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt"
```

### Check whether a line appears more than once

```bash
ansible three_tier_app -m shell -a \
"grep -c '^Course:' /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected count:

```text
1
```

---

## 10. Cleanup

### Remove only the practice file

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt state=absent"
```

### Verify that it was removed

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt"
```

Look for:

```text
"exists": false
```

### Remove the complete practice directory

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab state=absent"
```

Run the cleanup command again to test idempotency. The second execution should report `changed: false`.

---

## 11. Troubleshooting

### Error: destination file does not exist

By default, `lineinfile` expects the target file to exist. To permit it to create the file, add:

```text
create=yes
```

Example:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/new-file.txt line="First line" create=yes mode=0644'
```

### Permission denied

Use `-b` when modifying protected files such as files under `/etc`:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/example.conf regexp="^Option" line="Option enabled" backup=yes'
```

### Line added at the wrong location

Check whether the expression supplied to `insertbefore` or `insertafter` actually matches a line in the file.

### Multiple matching lines

`lineinfile` is intended primarily for managing one line. If you need to replace multiple matching occurrences, consider the `replace` module.

### Validate important configuration files

When supported by the application, use the `validate` parameter before Ansible installs the changed file. For example, an SSH configuration can be validated with `sshd -t`.

---

## 12. Quick-reference table

| Requirement | Recommended arguments |
|---|---|
| Add at beginning | `line="Text" insertbefore=BOF state=present` |
| Add at end | `line="Text" insertafter=EOF state=present` |
| Add after keyword | `insertafter="^Keyword" line="Text" state=present` |
| Add before keyword | `insertbefore="^Keyword" line="Text" state=present` |
| Replace a line | `regexp="^Keyword" line="Replacement" state=present` |
| Remove matching line | `regexp="^Keyword" state=absent` |
| Remove exact line | `line="Exact text" state=absent` |
| Create missing file | `line="Text" create=yes` |
| Back up before change | `backup=yes` |
| Manage an SSH Banner directive | `regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt"` |
| Delete complete file | Use `file` with `state=absent` |

---

## 13. Practice assignment

Without copying the completed commands, perform these tasks on `node1` first:

1. Create `/tmp/student-lineinfile-lab.txt`.
2. Add `Ansible Practice Lab` at the beginning.
3. Add `End of Lab` at the end.
4. Add `Managed by Ansible` after a line beginning with `Owner:`.
5. Change `Environment: Test` to `Environment: Production`.
6. Remove the line beginning with `Temporary:`.
7. Run each state-management command twice and compare `changed` values.
8. Display the final file.
9. Remove the practice file with the correct module.
10. Repeat the completed exercise against `three_tier_app`.
11. As an advanced exercise, explain each part of `^\s*#?\s*Banner\s+.*$` and test the SSH Banner command with `--limit node1`.

Use `--limit node1` during the first test:

```bash
ansible three_tier_app --limit node1 -m <module> -a '<arguments>'
```

After successful testing, remove `--limit node1` to target the complete group.
