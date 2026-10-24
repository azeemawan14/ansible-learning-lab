# Ansible Ad-Hoc Lab: Deploy a Static Website on Nginx

This revised solution follows the commands and paths that worked in the Rocky Linux lab. Test on `node1` (`192.168.1.154`) first, then deploy to the other managed nodes.

## Table of Contents

1. [Lab Environment](#1-lab-environment)
2. [Important Document-Root Decision](#2-important-document-root-decision)
3. [Prechecks](#3-prechecks)
4. [Install and Start Nginx](#4-install-and-start-nginx)
5. [Diagnose the Initial 403](#5-diagnose-the-initial-403)
6. [Inspect the Website Archive](#6-inspect-the-website-archive)
7. [Deploy the Website](#7-deploy-the-website)
8. [Verify the Deployment](#8-verify-the-deployment)
9. [Deploy to All Nodes](#9-deploy-to-all-nodes)
10. [Idempotency](#10-idempotency)
11. [Troubleshooting](#11-troubleshooting)
12. [Complete Cleanup](#12-complete-cleanup)
13. [Key Learning Points](#13-key-learning-points)

---

## 1. Lab Environment

| Item | Value |
|---|---|
| Control user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Inventory group | `three_tier_app` |
| Pilot host | `node1` |
| node1 IP | `192.168.1.154` |
| Operating system | Rocky Linux 9 |
| Active virtual host | `lawfirm.com` |
| Active document root | `/var/www/lawfirm.com/html` |
| Website archive | `/tmp/space-science.zip` |
| Extraction directory | `/tmp/space-science-extracted` |

```bash
cd /home/ansibleadmin/automation
```

---

## 2. Important Document-Root Decision

Rocky Linux normally provides `/usr/share/nginx/html`, but the active `lawfirm.com` server block in this lab uses:

```text
/var/www/lawfirm.com/html
```

The active configuration takes precedence, so this is where the website must be deployed. Check configured roots when uncertain:

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

---

## 3. Prechecks

### Step 1: Confirm the active Ansible configuration

```bash
ansible --version
ansible-config dump --only-changed
```

Confirm that Ansible is reading the expected `ansible.cfg` and inventory.

### Step 2: Inspect the inventory

```bash
ansible-inventory --graph
ansible three_tier_app --list-hosts
```

Expected hosts:

```text
node1
node2
node3
```

### Step 3: Test connectivity

```bash
ansible three_tier_app -m ping
```

Each host should return `SUCCESS` and `pong`.

---

## 4. Install and Start Nginx

### Step 1: Install Nginx and unzip on the pilot host

```bash
ansible node1 -b -m dnf -a "name=nginx,unzip state=present"
```

`state=present` installs missing packages. DNF may also replace an older package build with the current repository build.

### Step 2: Start and enable Nginx

```bash
ansible node1 -b -m service -a "name=nginx state=started enabled=yes"
```

- `state=started` requires Nginx to run now.
- `enabled=yes` starts it automatically after boot.

### Step 3: Verify the current state

```bash
ansible node1 -m command -a "systemctl is-active nginx"
```

Expected result: `active`.

The `service` result can contain an earlier status snapshot. `systemctl is-active nginx` checks the current state directly.

### Step 4: Allow HTTP through the firewall

```bash
ansible node1 -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=enabled"
```

`changed=false` means HTTP was already allowed; this is correct idempotent behavior.

### Step 5: Test the active website root

```bash
ansible node1 -m uri -a "url=http://localhost status_code=200"
```

The first lab test returned `403 Forbidden`. Nginx was running, but it had no index page in its active document root.

---

## 5. Diagnose the Initial 403

### Step 1: Inspect the standard Nginx directory

Inspect the standard directory and the Nginx error log:

```bash
ansible node1 -b -m command -a "ls -laZ /usr/share/nginx/html"
```
[index.html explanation](md/Nginx_Index_HTML_Home_Page_Study_Notes.md)

This directory contained Rocky Linux's standard Nginx files, but it was not the active root for the `lawfirm.com` server block.

### Step 2: Read the Nginx error log

```bash
ansible node1 -b -m command -a "tail -n 20 /var/log/nginx/error.log"
```

The important error was:

```text
directory index of "/var/www/lawfirm.com/html/" is forbidden
```

This exposed the real active document root. It was empty:

### Step 3: Inspect the active document root

```bash
ansible node1 -b -m command -a "ls -laZ /var/www/lawfirm.com/html"
```

### Step 4: Create a temporary test page

Create a temporary test page:

```bash
ansible node1 -b -m copy -a \
'content="<h1>Welcome to lawfirm.com</h1>\n<p>Deployed using Ansible.</p>\n" dest=/var/www/lawfirm.com/html/index.html owner=root group=root mode=0644'
```

### Step 5: Restore SELinux contexts

```bash
ansible node1 -b -m command -a "restorecon -Rv /var/www/lawfirm.com/html"
```

[restorecon explanation](md/Ansible_Restorecon_AdHoc_Command_Study_Notes.md)

### Step 6: Test the temporary page

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200 return_content=yes"
```

[URI Explanation](md/Ansible_URI_Status_Code_Study_Notes_English.md)

Status `200` proves that Nginx, the active root, permissions, and SELinux access are working.

---

## 6. Inspect the Website Archive

### Step 1: Download the template

Download the template if it is not already present:

```bash
ansible node1 -m get_url -a \
"url=https://freewebsitetemplates.com/download/space-science/ dest=/tmp/space-science.zip mode=0644"
```

### Step 2: Confirm that the archive exists

```bash
ansible node1 -m stat -a "path=/tmp/space-science.zip"
```

Look for `exists: true` and `mimetype: application/zip`.

### Step 3: Confirm the file type

```bash
ansible node1 -m command -a "file /tmp/space-science.zip"
```

The result should say `Zip archive data`, not `HTML document`.

### Step 4: Inspect the archive layout

```bash
ansible node1 -m command -a "unzip -l /tmp/space-science.zip"
```

The successful lab result showed a valid ZIP of approximately 26 MB. The deployable website is under:

```text
space-science/upload/
```

Its main page is `space-science/upload/index.html`. The archive also contains license and design-source folders; Nginx does not need those files.

---

## 7. Deploy the Website

### Step 1: Create a temporary extraction directory

```bash
ansible node1 -b -m file -a \
"path=/tmp/space-science-extracted state=directory mode=0755"
```

### Step 2: Extract the archive on node1

```bash
ansible node1 -b -m unarchive -a \
"src=/tmp/space-science.zip dest=/tmp/space-science-extracted remote_src=yes creates=/tmp/space-science-extracted/space-science/upload/index.html"
```

- `remote_src=yes` means the archive already exists on the managed node.
- `creates=` prevents unnecessary repeat extraction.

### Step 3: Copy only the website contents

```bash
ansible node1 -b -m copy -a \
"src=/tmp/space-science-extracted/space-science/upload/ dest=/var/www/lawfirm.com/html/ remote_src=yes owner=root group=root mode=preserve"
```

The trailing slash after `upload/` copies its **contents** into the document root instead of creating another `upload` directory. This also replaces the temporary test page with the real template page.

### Step 4: Restore SELinux contexts

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

In the lab, copied files changed from `user_tmp_t` to the web-readable `httpd_sys_content_t` context.

### Step 5: Confirm the deployed index

```bash
ansible node1 -m stat -a "path=/var/www/lawfirm.com/html/index.html"
ansible node1 -b -m command -a "ls -laZ /var/www/lawfirm.com/html"
```

---

## 8. Verify the Deployment

```bash
ansible node1 -m uri -a "url=http://localhost status_code=200"
```

The successful response showed `status: 200`, `server: nginx/1.20.1`, `content_length: 3538`, and `changed: false`.

[URI explanation](md/Ansible_URI_Status_Code_Study_Notes_English.md)

Open this URL from a browser:

```text
http://192.168.1.154/
```

### Understand the browser URL and filesystem mapping

The website is deployed correctly, but the browser URL must match the directory where the files were copied.

#### Option A: Serve the website from the root URL — current deployment

The files were copied directly into:

```text
/var/www/lawfirm.com/html/
```

Therefore, use:

```text
http://192.168.1.154/
             ↓
/var/www/lawfirm.com/html/index.html
```

If you open:

```text
http://192.168.1.154/space-science/
```

Nginx searches for:

```text
/var/www/lawfirm.com/html/space-science/
```

That directory does not exist in the current deployment, so Nginx returns `404 Not Found`.

#### Option B: Serve the website from `/space-science/`

If you specifically want this URL:

```text
http://192.168.1.154/space-science/
```

create the subdirectory and copy the website there:

```bash
ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/space-science state=directory owner=root group=root mode=0755"

ansible node1 -b -m copy -a \
"src=/tmp/space-science-extracted/space-science/upload/ dest=/var/www/lawfirm.com/html/space-science/ remote_src=yes owner=root group=root mode=preserve"

ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html/space-science"

ansible node1 -m uri -a \
"url=http://localhost/space-science/ status_code=200"
```

The mapping is then:

```text
http://192.168.1.154/space-science/
                      ↓
/var/www/lawfirm.com/html/space-science/index.html
```

Choose one deployment layout and use its matching URL. For the current lab, Option A is simpler. The browser may show **Not secure** because the lab uses HTTP instead of HTTPS.

Additional checks:

```bash
ansible node1 -m command -a "systemctl is-active nginx"
ansible node1 -m shell -a "ss -tln | grep ':80 '"
ansible node1 -m uri -a "url=http://localhost status_code=200"
```

---

## 9. Deploy to All Nodes

First verify that every node uses `/var/www/lawfirm.com/html`. If it does, run:

### Step 1: Install Nginx and unzip

```bash
ansible three_tier_app -b -m dnf -a "name=nginx,unzip state=present"
```

### Step 2: Start and enable Nginx

```bash
ansible three_tier_app -b -m service -a "name=nginx state=started enabled=yes"
```

### Step 3: Allow HTTP through firewalld

```bash
ansible three_tier_app -b -m firewalld -a "service=http permanent=yes immediate=yes state=enabled"
```

### Step 4: Download the archive

```bash
ansible three_tier_app -m get_url -a "url=https://freewebsitetemplates.com/download/space-science/ dest=/tmp/space-science.zip mode=0644"
```

### Step 5: Create the extraction directory

```bash
ansible three_tier_app -b -m file -a "path=/tmp/space-science-extracted state=directory mode=0755"
```

### Step 6: Extract the archive

```bash
ansible three_tier_app -b -m unarchive -a "src=/tmp/space-science.zip dest=/tmp/space-science-extracted remote_src=yes creates=/tmp/space-science-extracted/space-science/upload/index.html"
```

### Step 7: Copy the website to the active document root

```bash
ansible three_tier_app -b -m copy -a "src=/tmp/space-science-extracted/space-science/upload/ dest=/var/www/lawfirm.com/html/ remote_src=yes owner=root group=root mode=preserve"
```

### Step 8: Restore SELinux contexts

```bash
ansible three_tier_app -b -m command -a "restorecon -Rv /var/www/lawfirm.com/html"
```

### Step 9: Verify HTTP status

```bash
ansible three_tier_app -m uri -a "url=http://localhost status_code=200"
```

Browser URLs:

```text
http://192.168.1.154/
http://192.168.1.185/
http://192.168.1.190/
```

---

## 10. Idempotency

| Operation | Expected second-run behavior |
|---|---|
| `dnf state=present` | `changed=false` when packages are correct |
| `service state=started enabled=yes` | `changed=false` when already running and enabled |
| `firewalld state=enabled` | `changed=false` when HTTP is already allowed |
| `get_url` | Usually `changed=false` when the remote file is unchanged |
| `unarchive creates=...` | Skips extraction when the marker exists |
| `copy` | `changed=false` when contents already match |
| `uri` | Verification only; normally `changed=false` |

The `command` module normally reports `CHANGED` whenever it executes, even for a read-only command. This does not necessarily mean the host was modified.

---

## 11. Troubleshooting

### HTTP 403 Forbidden

```bash
ansible node1 -b -m command -a "tail -n 20 /var/log/nginx/error.log"
ansible node1 -b -m command -a "ls -laZ /var/www/lawfirm.com/html"
ansible node1 -b -m shell -a "nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

A 403 commonly means the active root has no index file, a directory cannot be traversed, or SELinux contexts are wrong.

### HTTP 404 at `/space-science/`

Use `http://192.168.1.154/`. This deployment installed the site at the document root.

### Port 80 already in use

```bash
ansible node1 -b -m shell -a "ss -tlnp | grep ':80 '"
```

### ZIP is actually an HTML document

```bash
ansible node1 -m command -a "file /tmp/space-science.zip"
```

It must report ZIP archive data.

### Validate the Nginx configuration

```bash
ansible node1 -b -m command -a "nginx -t"
```

---

## 12. Complete Cleanup

Use the inventory group `three_tier_app`, not `all`. In this lab, `all` may also include the Ansible control node.

### Option 1: Reset only the website lab — recommended

This removes the deployed content and temporary files but keeps Nginx and the `lawfirm.com` configuration ready for the next practice run.

#### Step 1: Remove the current website content

```bash
ansible three_tier_app -b -m file -a \
"path=/var/www/lawfirm.com/html state=absent"
```

#### Step 2: Recreate an empty document root

```bash
ansible three_tier_app -b -m file -a \
"path=/var/www/lawfirm.com/html state=directory owner=root group=root mode=0755"
```

Recreating the directory allows the next deployment to copy files into it. Until a new `index.html` is deployed, the root URL may return `403`.

#### Step 3: Remove the extracted files

```bash
ansible three_tier_app -b -m file -a \
"path=/tmp/space-science-extracted state=absent"
```

#### Step 4: Remove the downloaded archive

```bash
ansible three_tier_app -b -m file -a \
"path=/tmp/space-science.zip state=absent"
```

#### Step 5: Verify the practice cleanup

```bash
ansible three_tier_app -m stat -a "path=/var/www/lawfirm.com/html/index.html"
ansible three_tier_app -m stat -a "path=/tmp/space-science.zip"
ansible three_tier_app -m stat -a "path=/tmp/space-science-extracted"
```

Each removed item should report `exists: false`.

### Option 2: Full Nginx reset

Use this only when no other website on the managed nodes needs Nginx or port 80.

#### Step 1: Stop and disable Nginx

```bash
ansible three_tier_app -b -m service -a \
"name=nginx state=stopped enabled=no"
```

#### Step 2: Remove Nginx packages

```bash
ansible three_tier_app -b -m dnf -a \
"name=nginx,nginx-core,nginx-filesystem state=absent"
```

#### Step 3: Optionally remove unzip

```bash
ansible three_tier_app -b -m dnf -a "name=unzip state=absent"
```

Remove it only if it was installed solely for this lab.

#### Step 4: Disable HTTP in firewalld

```bash
ansible three_tier_app -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=disabled"
```

#### Step 5: Verify the full reset

```bash
ansible three_tier_app -m command -a \
"rpm -q nginx nginx-core nginx-filesystem"

ansible three_tier_app -b -m shell -a \
"ss -tlnp | grep ':80 ' || true"
```

Packages should report `not installed`, and no Nginx process should listen on port 80.

### Optional destructive configuration cleanup

Do not remove `/etc/nginx` during normal practice cleanup. It contains the `lawfirm.com` configuration that defines `/var/www/lawfirm.com/html` as the active root.

If you intentionally want to rebuild the complete Nginx configuration later, you may remove it:

```bash
ansible three_tier_app -b -m file -a "path=/etc/nginx state=absent"
```

After deleting `/etc/nginx`, reinstalling Nginx alone may restore the package defaults, but it will not recreate your custom `lawfirm.com` server block. You must recreate that configuration before using `/var/www/lawfirm.com/html` again.

---

## 13. Key Learning Points

1. Inspect the active Nginx configuration instead of assuming its document root.
2. A `403` means the server responded but could not serve the requested content.
3. Inspect an unfamiliar archive before extracting it.
4. Deploy only the archive directory containing the real website.
5. A trailing slash controls whether `copy` transfers a directory or its contents.
6. Run `restorecon` after copying files from `/tmp` on an SELinux system.
7. Test on `node1` before targeting every managed node.
8. Use `uri` to verify HTTP, not only the service state.
9. Limit cleanup to exact lab paths.
10. Convert the tested ad-hoc workflow into a playbook for repeatable automation.
