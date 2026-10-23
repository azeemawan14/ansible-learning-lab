# Solution: Deploy Two Static Websites with Ansible and Nginx

## Table of Contents

1. [Solution Overview](#1-solution-overview)
2. [Prepare the Project](#2-prepare-the-project)
3. [Prepare the Template Sources](#3-prepare-the-template-sources)
4. [Prechecks](#4-prechecks)
5. [Method 1: URL Subdirectories](#5-method-1-url-subdirectories)
6. [Method 1 Verification](#6-method-1-verification)
7. [Method 2: Separate Hostnames](#7-method-2-separate-hostnames)
8. [Method 2 Verification](#8-method-2-verification)
9. [Idempotency](#9-idempotency)
10. [Troubleshooting](#10-troubleshooting)
11. [Safe Cleanup](#11-safe-cleanup)
12. [Key Learning Points](#12-key-learning-points)

---

## 1. Solution Overview

The same two templates will be deployed in two ways:

| Method | Space Science | Frozen Yogurt Shop |
|---|---|---|
| URL paths | `http://192.168.1.154/space-science/` | `http://192.168.1.154/frozen-yogurt/` |
| Hostnames | `http://space.nitclasses.com/` | `http://yogurt.nitclasses.com/` |

Pilot all commands on `node1`. Replace `node1` with `three_tier_app` only after the pilot succeeds and the required Nginx configuration is consistent across all target nodes.

---

## 2. Prepare the Project

```bash
cd /home/ansibleadmin/automation

mkdir -p files/sites/space-science
mkdir -p files/sites/frozen-yogurt
mkdir -p files/nginx
mkdir -p downloads
mkdir -p evidence
```

Expected structure:

```text
automation/
├── files/
│   ├── sites/
│   │   ├── space-science/
│   │   └── frozen-yogurt/
│   └── nginx/
├── downloads/
└── evidence/
```

---

## 3. Prepare the Template Sources

### Step 1: Download both ZIP files

From the official site, download:

- Space Science Template
- Frozen Yogurt Shop Template

```text
https://freewebsitetemplates.com/
```

Place the downloaded ZIP files in:

```text
/home/ansibleadmin/automation/downloads/
```

For clarity, rename them:

```text
space-science.zip
frozen-yogurt.zip
```

### Step 2: Confirm the file types

```bash
file downloads/space-science.zip
file downloads/frozen-yogurt.zip
```

Both should report ZIP archive data.

### Step 3: Inspect the archives

```bash
unzip -l downloads/space-science.zip | less
unzip -l downloads/frozen-yogurt.zip | less
```

### Step 4: Extract them locally

```bash
mkdir -p downloads/space-extracted
mkdir -p downloads/yogurt-extracted

unzip downloads/space-science.zip -d downloads/space-extracted
unzip downloads/frozen-yogurt.zip -d downloads/yogurt-extracted
```

### Step 5: Locate the index files

```bash
find downloads/space-extracted -name index.html -print
find downloads/yogurt-extracted -name index.html -print
```

For the known Space Science archive, the deployable directory is normally similar to:

```text
downloads/space-extracted/space-science/upload/
```

The Frozen Yogurt Shop archive layout may differ. Use the directory containing its deployable `index.html`, CSS, images, and JavaScript.

### Step 6: Build clean local website sources

Space Science example:

```bash
cp -a downloads/space-extracted/space-science/upload/. \
files/sites/space-science/
```

For Frozen Yogurt Shop, replace `<FROZEN_YOGURT_SITE_DIRECTORY>` with the directory containing its deployable `index.html`:

```bash
cp -a <FROZEN_YOGURT_SITE_DIRECTORY>/. \
files/sites/frozen-yogurt/
```

Verify:

```bash
test -f files/sites/space-science/index.html && echo "Space source ready"
test -f files/sites/frozen-yogurt/index.html && echo "Frozen Yogurt source ready"

find files/sites/space-science -maxdepth 2 -type f | head
find files/sites/frozen-yogurt -maxdepth 2 -type f | head
```

---

## 4. Prechecks

### Check Ansible configuration and inventory

```bash
ansible --version
ansible-config dump --only-changed
ansible node1 --list-hosts
ansible node1 -m ping
```

### Confirm the active Nginx document root

If Nginx is already installed:

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

This solution uses the existing lab root:

```text
/var/www/lawfirm.com/html
```

---

## 5. Method 1: URL Subdirectories

### Step 1: Install Nginx

```bash
ansible node1 -b -m dnf -a "name=nginx state=present"
```

### Step 2: Start and enable Nginx

```bash
ansible node1 -b -m service -a \
"name=nginx state=started enabled=yes"
```

### Step 3: Allow HTTP through firewalld

```bash
ansible node1 -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=enabled"
```

### Step 4: Create both website directories

```bash
ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/space-science state=directory owner=root group=root mode=0755"

ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt state=directory owner=root group=root mode=0755"
```

### Step 5: Copy Space Science from the control node

```bash
ansible node1 -b -m copy -a \
"src=files/sites/space-science/ dest=/var/www/lawfirm.com/html/space-science/ owner=root group=root mode=preserve"
```

### Step 6: Copy Frozen Yogurt Shop from the control node

```bash
ansible node1 -b -m copy -a \
"src=files/sites/frozen-yogurt/ dest=/var/www/lawfirm.com/html/frozen-yogurt/ owner=root group=root mode=preserve"
```

Because `remote_src` is not used, these source paths are read from the Ansible control node.

### Step 7: Restore SELinux contexts

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html/space-science"

ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html/frozen-yogurt"
```

### URL mappings

```text
http://192.168.1.154/space-science/
                      ↓
/var/www/lawfirm.com/html/space-science/index.html
```

```text
http://192.168.1.154/frozen-yogurt/
                      ↓
/var/www/lawfirm.com/html/frozen-yogurt/index.html
```

---

## 6. Method 1 Verification

### Verify the files

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/space-science/index.html"

ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt/index.html"
```

### Verify SELinux contexts

```bash
ansible node1 -m command -a \
"ls -Zd /var/www/lawfirm.com/html/space-science"

ansible node1 -m command -a \
"ls -Zd /var/www/lawfirm.com/html/frozen-yogurt"
```

Look for `httpd_sys_content_t`.

### Verify HTTP status

```bash
ansible node1 -m uri -a \
"url=http://localhost/space-science/ status_code=200"

ansible node1 -m uri -a \
"url=http://localhost/frozen-yogurt/ status_code=200"
```

### Browser tests

```text
http://192.168.1.154/space-science/
http://192.168.1.154/frozen-yogurt/
```

---

## 7. Method 2: Separate Hostnames

### Step 1: Create separate document roots

```bash
ansible node1 -b -m file -a \
"path=/var/www/space/html state=directory owner=root group=root mode=0755"

ansible node1 -b -m file -a \
"path=/var/www/yogurt/html state=directory owner=root group=root mode=0755"
```

### Step 2: Deploy each website

```bash
ansible node1 -b -m copy -a \
"src=files/sites/space-science/ dest=/var/www/space/html/ owner=root group=root mode=preserve"

ansible node1 -b -m copy -a \
"src=files/sites/frozen-yogurt/ dest=/var/www/yogurt/html/ owner=root group=root mode=preserve"
```

### Step 3: Restore SELinux contexts

```bash
ansible node1 -b -m command -a "restorecon -Rv /var/www/space"
ansible node1 -b -m command -a "restorecon -Rv /var/www/yogurt"
```

If these custom paths do not inherit `httpd_sys_content_t`, define persistent mappings:

```bash
ansible node1 -b -m command -a \
"semanage fcontext -a -t httpd_sys_content_t '/var/www/space(/.*)?'"

ansible node1 -b -m command -a \
"semanage fcontext -a -t httpd_sys_content_t '/var/www/yogurt(/.*)?'"

ansible node1 -b -m command -a "restorecon -Rv /var/www/space"
ansible node1 -b -m command -a "restorecon -Rv /var/www/yogurt"
```

If `semanage` is unavailable, install its provider:

```bash
ansible node1 -b -m dnf -a "name=policycoreutils-python-utils state=present"
```

### Step 4: Create the Space Science server block locally

Create `files/nginx/space.conf`:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name space.nitclasses.com;

    root /var/www/space/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Step 5: Create the Frozen Yogurt Shop server block locally

Create `files/nginx/yogurt.conf`:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name yogurt.nitclasses.com;

    root /var/www/yogurt/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Step 6: Copy both server blocks

```bash
ansible node1 -b -m copy -a \
"src=files/nginx/space.conf dest=/etc/nginx/conf.d/space.conf owner=root group=root mode=0644 backup=yes"

ansible node1 -b -m copy -a \
"src=files/nginx/yogurt.conf dest=/etc/nginx/conf.d/yogurt.conf owner=root group=root mode=0644 backup=yes"
```

### Step 7: Validate Nginx configuration

```bash
ansible node1 -b -m command -a "nginx -t"
```

Do not reload Nginx if validation fails.

### Step 8: Reload Nginx

```bash
ansible node1 -b -m service -a "name=nginx state=reloaded"
```

### Step 9: Configure client-side hostname resolution

On the computer running the web browser, add:

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

Windows hosts file:

```text
C:\Windows\System32\drivers\etc\hosts
```

Linux or WSL hosts file:

```text
/etc/hosts
```

---

## 8. Method 2 Verification

### Verify the Nginx configuration

```bash
ansible node1 -b -m command -a "nginx -t"
```

### Verify both sites through the HTTP Host header

```bash
ansible node1 -m shell -a \
"curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: space.nitclasses.com' http://127.0.0.1/"

ansible node1 -m shell -a \
"curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: yogurt.nitclasses.com' http://127.0.0.1/"
```

Expected result for each site:

```text
200
```

### Browser tests

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

### Why the same IP serves two sites

The browser sends an HTTP `Host` header:

```text
Host: space.nitclasses.com
```

or:

```text
Host: yogurt.nitclasses.com
```

Nginx compares that value with each `server_name` and selects the matching server block.

---

## 9. Idempotency

Run the deployment commands again.

Expected behavior:

| Operation | Second-run expectation |
|---|---|
| `dnf state=present` | `changed=false` |
| `service state=started enabled=yes` | `changed=false` |
| `firewalld state=enabled` | `changed=false` |
| `file state=directory` | `changed=false` |
| `copy` website content | `changed=false` when files match |
| `copy` server blocks | `changed=false` when configuration matches |
| `stat` and `uri` | Verification only |
| `command` | May report `CHANGED` simply because it executed |

`service state=reloaded` reloads Nginx every time. In a playbook, use handlers so Nginx reloads only when a configuration file changes.

---

## 10. Troubleshooting

### `403 Forbidden`

```bash
ansible node1 -b -m command -a "tail -n 30 /var/log/nginx/error.log"
ansible node1 -m command -a "ls -lZ /var/www/space/html/index.html"
ansible node1 -m command -a "namei -l /var/www/space/html/index.html"
```

Check for a missing index file, directory traversal permissions, and SELinux context.

### `404 Not Found`

Confirm that the URL corresponds to the directory containing `index.html`.

### Wrong website appears

Check:

- client hostname resolution;
- browser cache;
- the request's `Host` header;
- Nginx `server_name` values;
- duplicate or default server blocks.

```bash
ansible node1 -b -m command -a "nginx -T"
```

### Nginx reload fails

```bash
ansible node1 -b -m command -a "nginx -t"
ansible node1 -b -m command -a "journalctl -u nginx --no-pager -n 30"
```

---

## 11. Safe Cleanup

Use `node1` for the pilot cleanup. Use `three_tier_app` only when the deployment was performed on every managed node.

### Remove Method 1 websites

```bash
ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/space-science state=absent"

ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt state=absent"
```

### Remove Method 2 document roots

```bash
ansible node1 -b -m file -a "path=/var/www/space state=absent"
ansible node1 -b -m file -a "path=/var/www/yogurt state=absent"
```

### Remove the two server blocks

```bash
ansible node1 -b -m file -a \
"path=/etc/nginx/conf.d/space.conf state=absent"

ansible node1 -b -m file -a \
"path=/etc/nginx/conf.d/yogurt.conf state=absent"
```

### Validate and reload the remaining configuration

```bash
ansible node1 -b -m command -a "nginx -t"
ansible node1 -b -m service -a "name=nginx state=reloaded"
```

### Verify cleanup

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/space-science"

ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt"

ansible node1 -m stat -a "path=/var/www/space"
ansible node1 -m stat -a "path=/var/www/yogurt"
```

Each removed path should report:

```text
exists: false
```

---

## 12. Key Learning Points

1. One Nginx server can host multiple static websites.
2. URL paths map to subdirectories under a document root.
3. Named virtual hosts share an IP and port but use different `Host` headers.
4. Prepare clean website sources before deployment.
5. Use `copy` without `remote_src` when the source is on the control node.
6. Validate Nginx configuration before reload.
7. Keep SELinux enabled and assign web-readable contexts.
8. Pilot on one node before wider deployment.
9. Repeated state-management commands should be idempotent.
10. Cleanup must remove only resources created by the lab.
