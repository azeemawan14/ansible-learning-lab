# Ansible `restorecon` Ad-Hoc Command — Study Notes

## Table of Contents

1. [Command](#1-command)
2. [Purpose](#2-purpose)
3. [Command Breakdown](#3-command-breakdown)
4. [Why restorecon Is Needed](#4-why-restorecon-is-needed)
5. [Understanding the Options](#5-understanding-the-options)
6. [Verify the SELinux Context](#6-verify-the-selinux-context)
7. [restorecon vs chmod vs chown](#7-restorecon-vs-chmod-vs-chown)
8. [Expected Ansible Result](#8-expected-ansible-result)
9. [Troubleshooting](#9-troubleshooting)
10. [Quick Summary](#10-quick-summary)

---

## 1. Command

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

This Ansible ad-hoc command restores the correct SELinux security contexts on the Nginx website directory and everything inside it.

---

## 2. Purpose

The website files were copied from a temporary directory such as:

```text
/tmp/space-science-extracted/
```

Files in `/tmp` may have a temporary SELinux context such as:

```text
user_tmp_t
```

Nginx normally needs static website content to have a web-readable SELinux type such as:

```text
httpd_sys_content_t
```

The command restores the policy-defined context:

```text
user_tmp_t
    ↓ restorecon
httpd_sys_content_t
```

Without the correct context, normal Linux permissions may look correct, but SELinux can still prevent Nginx from reading the files. This may cause `403 Forbidden`.

---

## 3. Command Breakdown

| Part | Explanation |
|---|---|
| `ansible` | Runs an Ansible ad-hoc command |
| `node1` | Runs the operation only on the inventory host named `node1` |
| `-b` | Enables privilege escalation, normally through `sudo` |
| `-m command` | Uses the Ansible `command` module |
| `-a` | Passes arguments to the selected module |
| `restorecon` | Restores SELinux contexts according to the system policy |
| `-R` | Processes the directory recursively |
| `-v` | Displays files whose contexts are restored |
| `/var/www/lawfirm.com/html` | Website directory being processed |

### Why is `-b` required?

Changing SELinux labels on system web directories normally requires root privileges. The `-b` option tells Ansible to use privilege escalation.

### Why use the `command` module?

`restorecon` is an operating-system command. It does not require shell features such as pipes, redirects, wildcard expansion, or command substitution, so the `command` module is appropriate.

---

## 4. Why `restorecon` Is Needed

SELinux makes access decisions in addition to standard Linux ownership and permissions.

For example, this file may appear readable:

```text
-rw-r--r-- root root index.html
```

However, if its SELinux type is wrong, Nginx may still be denied access.

The complete access check includes:

1. File ownership
2. Standard permissions
3. SELinux security context

All three must allow Nginx to read the website.

---

## 5. Understanding the Options

### `-R` — Recursive

Processes the specified directory and all files and subdirectories inside it:

```text
/var/www/lawfirm.com/html/
├── index.html
├── css/
├── images/
└── js/
```

Without `-R`, only the specified path would be processed.

### `-v` — Verbose

Displays which paths were relabeled. Example:

```text
Relabeled /var/www/lawfirm.com/html/index.html from user_tmp_t to httpd_sys_content_t
```

If every context is already correct, `restorecon` may produce no output.

---

## 6. Verify the SELinux Context

### Check the website directory and files

```bash
ansible node1 -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

Look for this SELinux type:

```text
httpd_sys_content_t
```

### Check only the index file

```bash
ansible node1 -m command -a \
"ls -lZ /var/www/lawfirm.com/html/index.html"
```

### Test the website after restoring the context

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200"
```

An HTTP status of `200` means Nginx successfully served the page.

---

## 7. `restorecon` vs `chmod` vs `chown`

| Command | What it changes | Example |
|---|---|---|
| `restorecon` | SELinux security context | `httpd_sys_content_t` |
| `chmod` | Standard file permissions | `0644`, `0755` |
| `chown` | File owner and group | `root:root` |

The following operations solve different problems:

```bash
# Restore the SELinux context
restorecon -Rv /var/www/lawfirm.com/html

# Set permissions
chmod -R u=rwX,g=rX,o=rX /var/www/lawfirm.com/html

# Set ownership
chown -R root:root /var/www/lawfirm.com/html
```

`restorecon` does not change ownership, standard permissions, or file contents.

---

## 8. Expected Ansible Result

If files require relabeling, output may look similar to:

```text
node1 | CHANGED | rc=0 >>
Relabeled /var/www/lawfirm.com/html/index.html ...
```

Important fields:

| Field | Meaning |
|---|---|
| `CHANGED` | The `command` module executed; it does not always prove that a label changed |
| `rc=0` | The command completed successfully |
| `Relabeled ...` | A file's SELinux context was actually corrected |

The `command` module normally reports `CHANGED` whenever it runs. Therefore, running this ad-hoc command again may still display `CHANGED`, even if no context required correction.

### More accurate change reporting in a playbook

```yaml
- name: Restore SELinux contexts on website files
  command: restorecon -Rv /var/www/lawfirm.com/html
  register: restorecon_result
  changed_when: restorecon_result.stdout | length > 0
```

This reports a change only when `restorecon -v` produces relabeling output.

---

## 9. Troubleshooting

### Problem: Website still returns `403 Forbidden`

Check the Nginx error log:

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"
```

Check permissions on every directory in the path:

```bash
ansible node1 -m command -a \
"namei -l /var/www/lawfirm.com/html/index.html"
```

Check the context:

```bash
ansible node1 -m command -a \
"ls -lZ /var/www/lawfirm.com/html/index.html"
```

### Problem: `restorecon` is not found

On Rocky Linux, the command is normally provided by an SELinux utility package. Check it with:

```bash
ansible node1 -m command -a "which restorecon"
```

### Problem: Context changes back unexpectedly

`restorecon` applies the context defined by the SELinux file-context policy. To inspect the expected context, use:

```bash
ansible node1 -b -m command -a \
"matchpathcon /var/www/lawfirm.com/html/index.html"
```

If a custom path does not have an appropriate persistent policy mapping, use `semanage fcontext` to define one before running `restorecon`.

---

## 10. Quick Summary

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

- Runs only on `node1`.
- Uses `sudo` through `-b`.
- Restores SELinux contexts recursively.
- Helps Nginx read static website files.
- Does not change ownership, standard permissions, or website content.
- Can help resolve an SELinux-related `403 Forbidden` response.
