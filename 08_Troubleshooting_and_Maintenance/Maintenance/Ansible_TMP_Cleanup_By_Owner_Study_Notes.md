# Ansible `/tmp` Cleanup by File Owner — Study Notes

This guide explains how to safely find and remove files or directories directly inside `/tmp` that are owned by `ansibleadmin` across Ansible-managed nodes.

> **Warning:** Deletion is destructive. Always preview the exact targets before running a removal command. Deleted files are not automatically recoverable.

## Index

1. [Objective](#1-objective)
2. [Why cleanup must be handled carefully](#2-why-cleanup-must-be-handled-carefully)
3. [Understanding the existing `/tmp` entries](#3-understanding-the-existing-tmp-entries)
4. [The safe preview-first workflow](#4-the-safe-preview-first-workflow)
5. [Remove all matching files and folders](#5-remove-all-matching-files-and-folders)
6. [Remove only directories](#6-remove-only-directories)
7. [Remove only regular files](#7-remove-only-regular-files)
8. [Why the Ansible payload is excluded](#8-why-the-ansible-payload-is-excluded)
9. [Verify cleanup without creating a payload](#9-verify-cleanup-without-creating-a-payload)
10. [Understanding the `find` options](#10-understanding-the-find-options)
11. [Why the shell module reports CHANGED](#11-why-the-shell-module-reports-changed)
12. [Exact-path cleanup with the file module](#12-exact-path-cleanup-with-the-file-module)
13. [Reusable cleanup playbook](#13-reusable-cleanup-playbook)
14. [Understanding `/tmp` permissions and the sticky bit](#14-understanding-tmp-permissions-and-the-sticky-bit)
15. [Directories that must not be manually removed](#15-directories-that-must-not-be-manually-removed)
16. [Troubleshooting](#16-troubleshooting)
17. [Safety checklist](#17-safety-checklist)
18. [Quick command reference](#18-quick-command-reference)
19. [Schedule cleanup every day at midnight Central Time](#19-schedule-cleanup-every-day-at-midnight-central-time)

---

## 1. Objective

The goal is to remove temporary lab files and directories owned by `ansibleadmin` from the managed nodes while preserving:

- `/tmp` itself.
- Root-owned system service directories.
- Ansible's currently active module-payload directory.
- Files belonging to other users.

Example removable directories:

```text
/tmp/ansible-share
/tmp/ansible-lab
/tmp/ansible_ifrah_lab
/tmp/ansible_lab_ibrahim
```

Example directory to exclude during an Ansible command:

```text
/tmp/ansible_ansible.legacy.command_payload_r1aihnnt
```

---

## 2. Why cleanup must be handled carefully

`/tmp` is shared by users, applications, and system services. A command such as the following is too broad:

```bash
rm -rf /tmp/*
```

It can remove:

- Other users' temporary files.
- Application runtime data.
- Service-private directories.
- Active sockets or temporary state.
- Files required by a running process.

The safer method selects entries using several conditions:

- Search only inside `/tmp`.
- Do not select `/tmp` itself.
- Inspect only direct children of `/tmp`.
- Select only entries owned by `ansibleadmin`.
- Exclude the active Ansible payload.
- Preview before deletion.

---

## 3. Understanding the existing `/tmp` entries

List the contents on all inventory hosts:

```bash
ansible all -m command -a "ls -la /tmp"
```

Typical categories include:

| Entry | Owner | Meaning | Action |
|---|---|---|---|
| `ansible-lab` | `ansibleadmin` | Practice directory | Remove when no longer needed |
| `ansible-share` | `ansibleadmin` | Shared practice directory | Remove when no longer needed |
| `ansible_*payload*` | `ansibleadmin` | Current Ansible module payload | Do not deliberately remove |
| `systemd-private-*` | `root` | Private service temporary directory | Leave it alone |
| `/tmp` | `root` | Shared temporary directory | Never remove |

The owner and group appear in the long listing:

```text
drwxr-xr-x. 2 ansibleadmin ansibleadmin 6 Sep 17 14:53 ansible_ifrah_lab
```

The first `ansibleadmin` is the owner. The second is the group.

---

## 4. The safe preview-first workflow

### Step 1: Preview all direct entries owned by ansibleadmin

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

Example output:

```text
/tmp/ansible-share
/tmp/ansible-lab
/tmp/ansible_ifrah_lab
/tmp/ansible_lab_ibrahim
```

Carefully review the output from every managed node.

### Step 2: Stop if anything unexpected appears

Do not run the delete command when the preview shows:

- A file you still need.
- A path outside `/tmp`.
- A service directory.
- Another user's data.
- An unexpected mount point or symbolic link.

### Step 3: Delete only after confirming the preview

Use the removal command described in the next section.

---

## 5. Remove all matching files and folders

The following command removes all direct entries—files, directories, and symbolic links—owned by `ansibleadmin`, except active Ansible payload directories:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

### Expected result

```text
node1 | CHANGED | rc=0 >>
node2 | CHANGED | rc=0 >>
node3 | CHANGED | rc=0 >>
```

Meaning:

- `rc=0` means the command completed successfully.
- Blank output is normal because successful `rm` normally prints nothing.
- `CHANGED` is the shell module's default status and does not list what was removed.

### Why `-b` is used

```text
-b
```

enables privilege escalation. Although an owner can often remove their own `/tmp` entries, becoming root makes cleanup behavior consistent across nodes. The selection conditions still limit the targets to entries owned by `ansibleadmin`.

---

## 6. Remove only directories

First preview only directories:

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -print'
```

After verification, remove them:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

`-type d` selects directories only.

---

## 7. Remove only regular files

Preview regular files:

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -print'
```

Delete only the matching regular files:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -delete'
```

`-type f` selects regular files only. It does not select directories.

The preview remains necessary because ownership alone does not prove that a file is no longer required.

---

## 8. Why the Ansible payload is excluded

When the `command` or `shell` module runs, Ansible may:

1. Connect to the managed node over SSH.
2. Create a temporary directory.
3. Transfer a module payload.
4. Execute the module.
5. Collect the result.
6. Remove the temporary payload.

Example temporary directory:

```text
/tmp/ansible_ansible.legacy.command_payload_mvtaoouj
```

The random suffix changes with each command. Therefore, a new Ansible command may always appear to show a new payload directory.

The exclusion is:

```bash
! -name "ansible_*payload*"
```

Meaning:

- `!` means NOT.
- `-name` matches a filename pattern.
- The quoted pattern is passed to `find` instead of being expanded by the local shell.

Do not deliberately remove an active payload because the current Ansible operation may fail.

---

## 9. Verify cleanup without creating a payload

### Option 1: Use the raw module

The `raw` module executes directly through SSH and normally does not transfer a Python module payload:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

To ignore any remaining payload-style entry:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

No listed paths means the intended entries have been removed.

### Option 2: Use direct SSH

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

Repeat for the other nodes:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node2 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'

ssh -i ~/.ssh/ansible-key ansibleadmin@node3 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

---

## 10. Understanding the `find` options

Command:

```bash
find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin \
! -name "ansible_*payload*" -exec rm -rf -- {} +
```

| Part | Meaning |
|---|---|
| `find /tmp` | Start the search inside `/tmp` |
| `-mindepth 1` | Never select `/tmp` itself |
| `-maxdepth 1` | Select only entries directly under `/tmp` |
| `-user ansibleadmin` | Select entries owned by `ansibleadmin` |
| `!` | Negate the following condition |
| `-name "ansible_*payload*"` | Match Ansible payload names |
| `-exec` | Run a command using the matched paths |
| `rm -rf` | Recursively and forcibly remove selected entries |
| `--` | End `rm` options so a filename beginning with `-` is treated as a path |
| `{}` | Placeholder for paths found by `find` |
| `+` | Pass multiple matches to fewer `rm` executions |

### Why both depth options are important

Without `-mindepth 1`, an incorrectly constructed command could select the starting path. Without `-maxdepth 1`, the command would inspect nested content and could behave differently from the intended top-level cleanup.

---

## 11. Why the shell module reports CHANGED

This read-only command:

```bash
ansible all -m shell -a "find /tmp -maxdepth 1 -print"
```

may return:

```text
node1 | CHANGED | rc=0
```

The ad-hoc `shell` and `command` modules normally report `CHANGED` because Ansible cannot automatically determine whether an arbitrary command modified the system.

Therefore:

- `CHANGED` does not prove that a preview command changed anything.
- `rc=0` means the command executed successfully.
- Read the command and its output to understand the actual result.

In a playbook, mark inspection tasks as read-only:

```yaml
changed_when: false
```

There is no general ad-hoc `--changed-when=false` option.

---

## 12. Exact-path cleanup with the file module

When the exact target is known, the `file` module is clearer and safer than a broad owner-based command.

```bash
ansible web -b -m file \
-a "path=/tmp/ansible_ifrah_lab state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible-lab state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible_lab_ibrahim state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible-share state=absent"
```

`state=absent` means the path must not exist. If the directory already does not exist, Ansible reports no change.

### Recommendation

| Situation | Recommended method |
|---|---|
| Exact paths are known | Use the `file` module |
| Many unknown paths share the same owner | Preview with `find`, then perform a carefully limited cleanup |
| Production environment | Prefer an approved path list, retention policy, and tested playbook |

---

## 13. Reusable cleanup playbook

The following playbook discovers matching top-level entries, displays them, pauses for confirmation, and removes the approved list.

Create:

```bash
vim cleanup-ansibleadmin-tmp.yml
```

Content:

```yaml
---
- name: Safely clean ansibleadmin entries from tmp
  hosts: all
  become: true

  tasks:
    - name: Find direct tmp entries owned by ansibleadmin
      shell: >
        find /tmp
        -mindepth 1
        -maxdepth 1
        -user ansibleadmin
        ! -name 'ansible_*payload*'
        -print
      register: cleanup_targets
      changed_when: false

    - name: Display cleanup targets
      debug:
        var: cleanup_targets.stdout_lines

    - name: Confirm cleanup
      pause:
        prompt: "Review the displayed paths. Press Enter to delete them, or Ctrl+C then A to abort"
      run_once: true

    - name: Remove approved cleanup targets
      file:
        path: "{{ item }}"
        state: absent
      loop: "{{ cleanup_targets.stdout_lines }}"
      when: cleanup_targets.stdout_lines | length > 0
```

### Validate the playbook

```bash
ansible-playbook --syntax-check cleanup-ansibleadmin-tmp.yml
```

### Run it

```bash
ansible-playbook cleanup-ansibleadmin-tmp.yml
```

### Important limitation

The confirmation appears after Ansible has displayed targets from the hosts. Carefully review each host's target list. In a production environment, use `--limit`, `serial`, change approval, backups, and a tested retention policy.

Example limited run:

```bash
ansible-playbook cleanup-ansibleadmin-tmp.yml --limit node1
```

---

## 14. Understanding `/tmp` permissions and the sticky bit

Typical `/tmp` permissions are:

```text
drwxrwxrwt
```

Numeric representation:

```text
1777
```

Meaning:

| Part | Meaning |
|---|---|
| Owner `rwx` | Owner can read, write, and enter the directory |
| Group `rwx` | Group members can read, write, and enter |
| Others `rwx` | Other users can read, write, and enter |
| Final `t` | Sticky bit |

The sticky bit prevents ordinary users from deleting files belonging to other users, even though `/tmp` is world-writable. Normally, an entry can be removed by:

- The entry owner.
- The directory owner.
- Root.

Verify permissions:

```bash
ansible all -m command -a "stat -c '%A %a %U:%G %n' /tmp"
```

Expected format:

```text
drwxrwxrwt 1777 root:root /tmp
```

---

## 15. Directories that must not be manually removed

Examples:

```text
systemd-private-*-chronyd.service-*
systemd-private-*-dbus-broker.service-*
systemd-private-*-httpd.service-*
systemd-private-*-nginx.service-*
systemd-private-*-mariadb.service-*
systemd-private-*-systemd-logind.service-*
```

These root-owned directories provide private temporary storage to services managed by `systemd`.

Do not remove them manually while the corresponding services are running. Let `systemd` manage their lifecycle.

The owner-based cleanup in this guide does not select them because they belong to `root`, not `ansibleadmin`.

---

## 16. Troubleshooting

### The command returns no output

Possible meaning: there are no matching entries. Verify the username and scope:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -printf "%u %y %p\n"'
```

### Permission denied

Use privilege escalation:

```bash
ansible all -b -m shell -a '...'
```

Test sudo:

```bash
ansible all -m command -a "sudo -n whoami"
```

Expected output:

```text
root
```

### A payload directory still appears

Each `command` or `shell` module execution may create a new payload. Use `raw` or direct SSH for final verification.

### A deleted path is needed again

`rm -rf` and `state=absent` do not provide an automatic undo operation. Restore the data from:

- A backup.
- A source repository.
- A VM snapshot.
- A deployment process that recreates the required files.

### Cleanup selected too many entries

Do not proceed. Narrow the selector using one or more of:

```text
-type f
-type d
-name 'ansible-lab*'
-mtime +7
-path '/tmp/specific-name'
```

Preview the revised selector before deletion.

---

## 17. Safety checklist

Before cleanup:

- [ ] Confirm the correct inventory and host pattern.
- [ ] Use `--limit node1` for the first test when possible.
- [ ] Confirm the search starts at `/tmp`, not `/`.
- [ ] Include `-mindepth 1`.
- [ ] Include `-maxdepth 1` for top-level-only cleanup.
- [ ] Confirm the owner is exactly `ansibleadmin`.
- [ ] Exclude active Ansible payload directories.
- [ ] Run the preview command first.
- [ ] Review output from every host.
- [ ] Confirm required data has a backup or can be recreated.

After cleanup:

- [ ] Check `rc=0` on every node.
- [ ] Verify using the `raw` module or direct SSH.
- [ ] Confirm `/tmp` still has mode `1777`.
- [ ] Leave root-owned `systemd-private-*` directories alone.
- [ ] Record the cleanup in lab notes or change documentation.

---

## 18. Quick command reference

### Preview all direct entries owned by ansibleadmin

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### Delete matching files and folders

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

### Preview only directories

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### Delete only directories

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

### Preview only regular files

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -print'
```

### Delete only regular files

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -delete'
```

### Verify using raw

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### Check `/tmp` permissions

```bash
ansible all -m command -a \
"stat -c '%A %a %U:%G %n' /tmp"
```

## 19. Schedule cleanup every day at midnight Central Time

A cleanup playbook can be scheduled from the Ansible control node with `cron`. Use the `America/Chicago` timezone instead of writing only `CST` because Chicago observes:

- CST during standard time.
- CDT during daylight-saving time.

`America/Chicago` automatically follows both. Therefore, `0 0 * * *` means midnight according to the current Chicago local time throughout the year.

> **Important:** A scheduled cleanup can delete a student's active work. Announce the maintenance window and target only known lab-directory patterns.

### Step 1: Create a safer scheduled-cleanup playbook

Create the playbook:

```bash
mkdir -p /home/ansibleadmin/automation/playbooks
vim /home/ansibleadmin/automation/playbooks/cleanup-tmp.yml
```

Add:

```yaml
---
- name: Remove temporary Ansible lab directories
  hosts: three_tier_app
  become: true

  tasks:
    - name: Find known lab directories owned by ansibleadmin
      find:
        paths: /tmp
        file_type: directory
        recurse: false
        owner: ansibleadmin
        patterns:
          - "ansible-*"
          - "ansible_*_lab"
          - "ansible_lab_*"
          - "ansible-share"
        excludes:
          - "ansible_*payload*"
      register: scheduled_lab_directories

    - name: Remove the matched lab directories
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ scheduled_lab_directories.files }}"
      loop_control:
        label: "{{ item.path }}"
```

This version removes only matching top-level directories. It does not delete every file owned by `ansibleadmin`, and it explicitly excludes Ansible payload directories.

### Step 2: Validate and test manually

```bash
cd /home/ansibleadmin/automation
ansible-playbook --syntax-check playbooks/cleanup-tmp.yml
ansible-playbook playbooks/cleanup-tmp.yml --check --diff --limit node1
```

Review the output carefully. After the check-mode result is correct, perform one controlled run:

```bash
ansible-playbook playbooks/cleanup-tmp.yml --limit node1
```

Then test all managed nodes:

```bash
ansible-playbook playbooks/cleanup-tmp.yml
```

### Step 3: Confirm the cron service

```bash
sudo systemctl enable --now crond
sudo systemctl status crond
```

### Step 4: Create the cron job

Edit the `ansibleadmin` user's crontab without `sudo`:

```bash
crontab -e
```

Add:

```cron
CRON_TZ=America/Chicago
0 0 * * * cd /home/ansibleadmin/automation && /usr/bin/flock -n /tmp/ansible-cleanup.lock /usr/bin/ansible-playbook playbooks/cleanup-tmp.yml >> /home/ansibleadmin/automation/cleanup-tmp.log 2>&1
```

Cron-field meaning:

| Field | Value | Meaning |
|---|---:|---|
| Minute | `0` | At minute zero |
| Hour | `0` | At 12:00 AM |
| Day of month | `*` | Every day of the month |
| Month | `*` | Every month |
| Day of week | `*` | Every day of the week |

Command details:

| Part | Purpose |
|---|---|
| `cd /home/ansibleadmin/automation` | Makes the project `ansible.cfg` discoverable and resolves relative paths correctly |
| `/usr/bin/flock -n ...` | Prevents a second cleanup from starting while an earlier run is active |
| `/usr/bin/ansible-playbook` | Uses an absolute executable path suitable for cron's limited environment |
| `>> cleanup-tmp.log` | Appends normal output to the log |
| `2>&1` | Sends error output to the same log |

### Step 5: Verify the schedule and logs

```bash
crontab -l
timedatectl
tail -n 100 /home/ansibleadmin/automation/cleanup-tmp.log
sudo journalctl -u crond --since today --no-pager
```

An empty cleanup log before the first scheduled run is normal.

### Optional: Test cron without waiting until midnight

Temporarily schedule a non-destructive command for the next convenient minute:

```cron
* * * * * /usr/bin/date >> /home/ansibleadmin/automation/cron-test.log 2>&1
```

After confirming that `cron-test.log` is updated, remove this test entry. Do not change the destructive cleanup schedule to every minute.

### Scheduled-cleanup safety checklist

- Test the playbook with `--check`, `--diff`, and `--limit node1` first.
- Use known directory-name patterns instead of deleting everything by owner.
- Keep `ansible_*payload*` excluded.
- Do not target `/tmp/*`, `systemd-private-*`, or root-owned service directories.
- Confirm that SSH keys and passwordless sudo work non-interactively.
- Announce the midnight maintenance window to lab users.
- Review `cleanup-tmp.log` after the first automatic run.
- Disable the cron entry before making major inventory or playbook changes.

## Final recommendation

Use this sequence:

```text
Preview → Review every host → Delete → Verify with raw/SSH → Record the change
```

When exact paths are known, prefer the Ansible `file` module with `state=absent`. Use owner-based `find` cleanup only for a clearly defined scope, and never run broad commands such as `rm -rf /tmp/*`.
