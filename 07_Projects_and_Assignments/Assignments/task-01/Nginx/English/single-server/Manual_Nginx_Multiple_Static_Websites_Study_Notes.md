# Manual Nginx Deployment: Two Static Websites on Rocky Linux 9.8

These study notes show how to deploy the **Space Science** and **Frozen Yogurt Shop** templates manually on `node1.nitclasses.com`, without using Ansible. They are the Rocky Linux 9.8 version of the Ubuntu WSL lab and include SELinux, firewalld, remote-client name resolution, detailed verification, rollback, and troubleshooting.

## Table of Contents

1. [Lab Objective](#1-lab-objective)
2. [Manual Linux vs Ansible](#2-manual-linux-vs-ansible)
3. [Lab Environment](#3-lab-environment)
4. [Connect to node1](#4-connect-to-node1)
5. [Install and Configure Nginx](#5-install-and-configure-nginx)
6. [Download and Prepare the Website Templates](#6-download-and-prepare-the-website-templates)
7. [Method 1: URL Subdirectories](#7-method-1-url-subdirectories)
8. [Method 1 Verification](#8-method-1-verification)
9. [Method 2: Separate Hostnames](#9-method-2-separate-hostnames)
10. [Method 2 Verification](#10-method-2-verification)
11. [Troubleshooting](#11-troubleshooting)
12. [Safe Cleanup](#12-safe-cleanup)
13. [Command Summary](#13-command-summary)
14. [Key Learning Points](#14-key-learning-points)
15. [Nginx Directives and Blocks](#15-nginx-directives-and-blocks)
16. [Request Flow and Log Interpretation](#16-request-flow-and-log-interpretation)
17. [Interview-Ready Summary](#17-interview-ready-summary)
18. [Final Lab Checklist](#18-final-lab-checklist)

---

## 1. Lab Objective

Deploy two static websites on one Rocky Linux 9 server:

1. Space Science
2. Frozen Yogurt Shop

Use two hosting methods:

| Method | Space Science | Frozen Yogurt Shop |
|---|---|---|
| URL subdirectories | `http://192.168.1.154/space-science/` | `http://192.168.1.154/frozen-yogurt/` |
| Separate hostnames | `http://space.nitclasses.com/` | `http://yogurt.nitclasses.com/` |

---

## 2. Manual Linux vs Ansible

The manual commands demonstrate the operations that Ansible normally automates.

| Manual Linux command | Related Ansible module |
|---|---|
| `dnf install` | `dnf` |
| `systemctl` | `service` or `systemd` |
| `firewall-cmd` | `firewalld` |
| `mkdir`, `chmod`, `chown`, `rm` | `file` |
| `cp` or `scp` | `copy` |
| `restorecon` | `command` |
| `curl` | `uri` |
| `ls`, `find`, `nginx -t` | `command` or `shell` |

Manual commands are useful for understanding the operating-system steps. Ansible makes the same work repeatable across multiple managed nodes.

---

## 3. Lab Environment

| Item | Value |
|---|---|
| FQDN | `node1.nitclasses.com` |
| Short hostname | `node1` |
| IP address | `192.168.1.154` |
| Operating system | Rocky Linux 9.8 (Blue Onyx) |
| Kernel | `5.14.0-687.42.1.el9_8.x86_64` |
| Architecture | `x86-64` |
| Virtualization | Xen HVM virtual machine |
| Normal user | `ansibleadmin` |
| User-owned lab workspace | `/home/ansibleadmin/nginx-multisite-lab` |
| Web server | Nginx |
| HTTP port | `80` |
| Existing document root | `/var/www/lawfirm.com/html` |

> Run the server-side commands on `node1`. Run the initial `scp` commands on the machine where the ZIP files are stored.

> This version intentionally keeps all downloads, extraction work, prepared content, and backups inside the user-owned lab workspace instead of a system temporary directory. Rocky Linux system files still belong in `/var/www`, `/etc/nginx`, and `/var/log/nginx`.

### 3.1 Confirm the environment

```bash
hostnamectl
hostname -s
hostname -f
cat /etc/os-release
uname -r
uname -m
```

Important distinction:

```text
Short hostname: node1
FQDN:           node1.nitclasses.com
Domain part:    nitclasses.com
```

`hostnamectl` changes and displays the static hostname. In this lab the static hostname is already the FQDN `node1.nitclasses.com`.

### 3.2 Preflight checks

Before changing the server, collect a baseline:

```bash
whoami
ip -4 address
ip -4 route
df -h / /var
getenforce
systemctl is-active firewalld
sudo ss -tlnp | grep -E ':80\b' || true
rpm -q nginx httpd
```

Why these checks matter:

- Confirm the correct server and user.
- Confirm available disk space.
- Determine whether SELinux is enforcing.
- Confirm firewalld state.
- Identify any process already using port 80.
- Detect an Apache/httpd and Nginx port conflict before installation.

---

## 4. Connect to node1

Connect from the control node or another SSH client:

```bash
ssh ansibleadmin@192.168.1.154
```

Confirm the current server and user:

```bash
hostname
whoami
```

Expected values:

```text
node1.nitclasses.com
ansibleadmin
```

Stay logged in as `ansibleadmin`. Use `sudo` only for commands that modify system locations. This keeps `$HOME` equal to `/home/ansibleadmin`, so the WSL-style lab directory remains consistent.

Define the lab root and create its complete structure:

```bash
LAB_ROOT="$HOME/nginx-multisite-lab"
export LAB_ROOT

mkdir -p "$LAB_ROOT/downloads"
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"
mkdir -p "$LAB_ROOT/backups"
```

Verify:

```bash
printf 'LAB_ROOT=%s\n' "$LAB_ROOT"
find "$LAB_ROOT" -maxdepth 2 -type d -print | sort
```

Expected root:

```text
/home/ansibleadmin/nginx-multisite-lab
```

Final lab workspace layout:

```text
/home/ansibleadmin/nginx-multisite-lab/
├── downloads/
├── extracted/
│   ├── space/
│   └── yogurt/
├── prepared/
│   ├── space-science/
│   └── frozen-yogurt/
└── backups/
```

`LAB_ROOT` is a shell variable. Define and export it again after opening a new shell or reconnecting to the server.

---

## 5. Install and Configure Nginx

### 5.1 Install the required packages

```bash
sudo dnf install nginx unzip policycoreutils-python-utils -y
```

Package purposes:

| Package | Purpose |
|---|---|
| `nginx` | Serves the websites |
| `unzip` | Extracts template ZIP archives |
| `policycoreutils-python-utils` | Provides `semanage` for persistent SELinux mappings |

Rocky Linux 9 normally provides Nginx through its standard repositories. EPEL is not automatically required just to install Nginx. Confirm the selected package source with:

```bash
sudo dnf info nginx
```

### 5.2 Check for a port conflict

Before starting Nginx:

```bash
sudo ss -tlnp | grep -E ':80\b' || true
sudo systemctl is-active httpd
```

If Apache/httpd is already bound to `0.0.0.0:80` or `[::]:80`, Nginx cannot use the same listeners. Decide which service should own port 80; do not blindly stop a production service.

### 5.3 Start and enable Nginx

```bash
sudo systemctl enable --now nginx
```

- `--now` starts Nginx immediately.
- `enable` configures Nginx to start automatically during boot.

Verify:

```bash
systemctl is-active nginx
systemctl is-enabled nginx
sudo nginx -t
sudo ss -tlnp | grep -E ':80\b'
```

### 5.4 Allow HTTP through firewalld

```bash
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
```

This allows incoming HTTP traffic on TCP port 80.

### 5.5 Baseline HTTP test

```bash
curl -I http://127.0.0.1/
curl -I http://192.168.1.154/
```

A working default server should normally return an HTTP response such as `200 OK`. If the response is `403`, inspect the configured document root, index file, permissions, and SELinux context before continuing.

### 5.6 Back up Nginx configuration and current content

Confirm the user-owned backup directory:

```bash
mkdir -p "$LAB_ROOT/backups"
```

Create a reusable timestamp:

```bash
timestamp="$(date '+%Y-%m-%d-%H-%M-%S')"
```

Back up Nginx configuration:

```bash
sudo tar -C /etc -czf - nginx > \
  "$LAB_ROOT/backups/nginx-config-$timestamp.tar.gz"
```

Back up the existing website root if it exists:

```bash
if [ -d /var/www/lawfirm.com ]; then
  sudo tar -C /var/www -czf - lawfirm.com > \
    "$LAB_ROOT/backups/lawfirm-webroot-$timestamp.tar.gz"
fi
```

Verify the backup archives without restoring them:

```bash
ls -lh "$LAB_ROOT/backups/"
tar -tzf "$LAB_ROOT/backups/nginx-config-$timestamp.tar.gz" | head -20
```

`tar -tzf` lists the contents of a gzip-compressed archive. It is a safe verification step because it does not extract or overwrite files.

---

## 6. Download and Prepare the Website Templates

### 6.1 Enter the download directory

```bash
mkdir -p "$LAB_ROOT/downloads"
cd "$LAB_ROOT/downloads"
```

### 6.2 Download the templates

```bash
wget -O space-science.zip \
  'https://freewebsitetemplates.com/download/space-science/'
```

```bash
wget -O frozen-yogurt.zip \
  'https://freewebsitetemplates.com/download/frozenyogurtshop/'
```

`wget -O filename` saves the downloaded response using the specified local filename.

### 6.3 Verify the archives

```bash
ls -lh *.zip
file *.zip
unzip -t space-science.zip
unzip -t frozen-yogurt.zip
```

`unzip -t` tests archive integrity without extracting files.

### 6.4 Inspect the archives

```bash
unzip -l space-science.zip | less
unzip -l frozen-yogurt.zip | less
```

Press `q` to leave `less`.

### 6.5 Extract the archives

```bash
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"

unzip -q "$LAB_ROOT/downloads/space-science.zip" \
  -d "$LAB_ROOT/extracted/space"

unzip -q "$LAB_ROOT/downloads/frozen-yogurt.zip" \
  -d "$LAB_ROOT/extracted/yogurt"
```

`-q` uses quiet mode and `-d` specifies the extraction destination.

### 6.6 Locate each homepage

```bash
find "$LAB_ROOT/extracted/space" -name index.html -print
find "$LAB_ROOT/extracted/yogurt" -name index.html -print
```

Use the directory that contains the deployable `index.html` together with its CSS, JavaScript, image and font directories.

For the archives used in this lab, the expected roots are:

```text
$LAB_ROOT/extracted/space/space-science/upload/
$LAB_ROOT/extracted/yogurt/frozenyogurtshop/
```

Confirm their sizes and contents:

```bash
du -sh "$LAB_ROOT/extracted/space/space-science/upload"
du -sh "$LAB_ROOT/extracted/yogurt/frozenyogurtshop"

find "$LAB_ROOT/extracted/space/space-science/upload" \
  -maxdepth 1 -mindepth 1 -printf '%f\n' | sort

find "$LAB_ROOT/extracted/yogurt/frozenyogurtshop" \
  -maxdepth 1 -mindepth 1 -printf '%f\n' | sort
```

### 6.7 Create clean prepared copies

Do not edit the extracted source directly. Create clean deployment copies:

```bash
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"
```

```bash
cp -a "$LAB_ROOT/extracted/space/space-science/upload/." \
  "$LAB_ROOT/prepared/space-science/"

cp -a "$LAB_ROOT/extracted/yogurt/frozenyogurtshop/." \
  "$LAB_ROOT/prepared/frozen-yogurt/"
```

The Frozen Yogurt archive contains a large Photoshop source file that the website does not need at runtime. Remove it only from the prepared copy:

```bash
rm -f -- \
  "$LAB_ROOT/prepared/frozen-yogurt/frozenyogurtshop.psd"
```

Verify:

```bash
test ! -e \
  "$LAB_ROOT/prepared/frozen-yogurt/frozenyogurtshop.psd" \
  && echo "PASS: PSD file excluded"

ls -l "$LAB_ROOT/prepared/space-science/index.html"
ls -l "$LAB_ROOT/prepared/frozen-yogurt/index.html"
```

The `/.` suffix in `source/.` copies the contents of the source directory, including hidden entries, without creating an extra nested source directory.

---

## 7. Method 1: URL Subdirectories

Both websites will use the same Nginx server block and document root, but each site will have a separate subdirectory.

### 7.1 Create the destination directories

```bash
sudo mkdir -p /var/www/lawfirm.com/html/space-science
sudo mkdir -p /var/www/lawfirm.com/html/frozen-yogurt
```

### 7.2 Copy the Space Science files

Copy from the clean prepared directory:

```bash
sudo cp -a "$LAB_ROOT/prepared/space-science/." \
  /var/www/lawfirm.com/html/space-science/
```

### 7.3 Copy the Frozen Yogurt files

```bash
sudo cp -a "$LAB_ROOT/prepared/frozen-yogurt/." \
  /var/www/lawfirm.com/html/frozen-yogurt/
```

Do not copy only `index.html`. Its CSS, JavaScript, images and fonts must also be copied.

### 7.4 Confirm the final layout

```bash
ls -l /var/www/lawfirm.com/html/space-science/index.html
ls -l /var/www/lawfirm.com/html/frozen-yogurt/index.html
```

Required mapping:

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

### 7.5 Set ownership and permissions

```bash
sudo chown -R root:root /var/www/lawfirm.com/html/space-science
sudo chown -R root:root /var/www/lawfirm.com/html/frozen-yogurt

sudo find /var/www/lawfirm.com/html/space-science \
-type d -exec chmod 755 {} +

sudo find /var/www/lawfirm.com/html/space-science \
-type f -exec chmod 644 {} +

sudo find /var/www/lawfirm.com/html/frozen-yogurt \
-type d -exec chmod 755 {} +

sudo find /var/www/lawfirm.com/html/frozen-yogurt \
-type f -exec chmod 644 {} +
```

Directories require the execute permission so Nginx can traverse them. Static files normally require read permission.

The `+` form passes multiple matched paths to each `chmod` process and is more efficient than running one `chmod` per path with `\;`.

Verify ownership and identify unexpected permissions:

```bash
find /var/www/lawfirm.com/html/space-science \
  -type d ! -perm 0755 -print
find /var/www/lawfirm.com/html/space-science \
  -type f ! -perm 0644 -print

find /var/www/lawfirm.com/html/frozen-yogurt \
  -type d ! -perm 0755 -print
find /var/www/lawfirm.com/html/frozen-yogurt \
  -type f ! -perm 0644 -print
```

No output means the selected files and directories use the intended modes.

### 7.6 Restore SELinux contexts

```bash
sudo restorecon -Rv /var/www/lawfirm.com/html/space-science
sudo restorecon -Rv /var/www/lawfirm.com/html/frozen-yogurt
```

Confirm that every parent directory is traversable:

```bash
namei -l /var/www/lawfirm.com/html/space-science/index.html
namei -l /var/www/lawfirm.com/html/frozen-yogurt/index.html
```

---

## 8. Method 1 Verification

### 8.1 Check the HTTP status

```bash
curl -I http://localhost/space-science/
curl -I http://localhost/frozen-yogurt/
```

Expected result:

```text
HTTP/1.1 200 OK
```

Test important internal pages and assets as well:

```bash
curl -I http://localhost/space-science/about.html
curl -I http://localhost/space-science/projects.html
curl -I http://localhost/space-science/css/style.css

curl -I http://localhost/frozen-yogurt/blog.html
curl -I http://localhost/frozen-yogurt/contact.html
curl -I http://localhost/frozen-yogurt/css/style.css
```

Confirm each website's identity:

```bash
curl -fsS http://localhost/space-science/ | grep -i '<title>'
curl -fsS http://localhost/frozen-yogurt/ | grep -i '<title>'
```

### 8.2 Check the SELinux contexts

```bash
ls -ldZ /var/www/lawfirm.com/html/space-science
ls -ldZ /var/www/lawfirm.com/html/frozen-yogurt
```

Look for:

```text
httpd_sys_content_t
```

Explain the SELinux result:

- Unix permissions answer whether the Nginx process can read and traverse the path.
- SELinux policy independently answers whether a web-server domain may access the labeled content.
- Both checks must allow access.

### 8.3 Browser verification

```text
http://192.168.1.154/space-science/
http://192.168.1.154/frozen-yogurt/
```

Inspect the main logs after browser testing:

```bash
sudo tail -n 30 /var/log/nginx/access.log
sudo tail -n 30 /var/log/nginx/error.log
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/access.log | tail -20
```

A lone `/favicon.ico` `404` is usually harmless. Browsers request it automatically for the tab icon. Missing HTML, CSS, JavaScript, image, or font files require investigation.

---

## 9. Method 2: Separate Hostnames

This method uses two Nginx server blocks. Both websites share `192.168.1.154:80`, but Nginx selects the website by reading the HTTP `Host` header.

### 9.1 Create separate document roots

```bash
sudo mkdir -p /var/www/space/html
sudo mkdir -p /var/www/yogurt/html
```

### 9.2 Copy the prepared website files

```bash
sudo cp -a /var/www/lawfirm.com/html/space-science/. \
/var/www/space/html/

sudo cp -a /var/www/lawfirm.com/html/frozen-yogurt/. \
/var/www/yogurt/html/
```

### 9.3 Apply ownership and permissions

```bash
sudo chown -R root:root /var/www/space /var/www/yogurt

sudo find /var/www/space -type d -exec chmod 755 {} +
sudo find /var/www/space -type f -exec chmod 644 {} +

sudo find /var/www/yogurt -type d -exec chmod 755 {} +
sudo find /var/www/yogurt -type f -exec chmod 644 {} +
```

Verify:

```bash
ls -ld /var/www/space/html /var/www/yogurt/html
ls -l /var/www/space/html/index.html /var/www/yogurt/html/index.html

find /var/www/space /var/www/yogurt \
  -type d ! -perm 0755 -print
find /var/www/space /var/www/yogurt \
  -type f ! -perm 0644 -print
```

### 9.4 Configure persistent SELinux mappings

The paths under `/var/www/space` and `/var/www/yogurt` are custom document roots. Add persistent SELinux file-context rules:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t \
'/var/www/space(/.*)?'

sudo semanage fcontext -a -t httpd_sys_content_t \
'/var/www/yogurt(/.*)?'
```

Apply the mappings:

```bash
sudo restorecon -Rv /var/www/space
sudo restorecon -Rv /var/www/yogurt
```

If a mapping already exists, modify it with `-m` instead of adding it with `-a`:

```bash
sudo semanage fcontext -m -t httpd_sys_content_t \
'/var/www/space(/.*)?'

sudo semanage fcontext -m -t httpd_sys_content_t \
'/var/www/yogurt(/.*)?'
```

### 9.5 Create the Space Science server block

```bash
sudo vim /etc/nginx/conf.d/space.conf
```

Add:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name space.nitclasses.com;

    root /var/www/space/html;
    index index.html index.htm;

    access_log /var/log/nginx/space-access.log;
    error_log  /var/log/nginx/space-error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 9.6 Create the Frozen Yogurt server block

```bash
sudo vim /etc/nginx/conf.d/yogurt.conf
```

Add:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name yogurt.nitclasses.com;

    root /var/www/yogurt/html;
    index index.html index.htm;

    access_log /var/log/nginx/yogurt-access.log;
    error_log  /var/log/nginx/yogurt-error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 9.7 Validate and reload Nginx

Always validate before reloading:

```bash
sudo nginx -t
```

Reload only after a successful test:

```bash
sudo systemctl reload nginx
```

Verify:

```bash
systemctl is-active nginx
sudo ss -tlnp | grep ':80'
echo $?
```

Safe configuration workflow:

```text
Edit -> Test -> Reload -> Verify
```

Use `reload` for a valid configuration change so Nginx can load new workers without an unnecessary full stop and start.

### 9.8 Configure client hostname resolution

Because `node1` is a remote Rocky Linux VM reached over the lab network or VPN, the Windows hosts file must map both names to the VM address `192.168.1.154`, not to `127.0.0.1`.

On the Windows computer running the browser, open PowerShell as Administrator.

Back up the hosts file first:

```powershell
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupFile = "$hostsFile.backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Backup created: $backupFile"
```

Check for old entries:

```powershell
Select-String -Path $hostsFile \
  -Pattern 'space\.nitclasses\.com|yogurt\.nitclasses\.com'
```

Then edit this file as Administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Add:

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

Flush the Windows DNS cache:

```powershell
ipconfig /flushdns
```

Verify from Windows:

```powershell
curl.exe -I http://space.nitclasses.com/
curl.exe -I http://yogurt.nitclasses.com/
```

For a Linux or WSL client, add the same entries to:

```text
/etc/hosts
```

---

## 10. Method 2 Verification

### 10.1 Test the Host headers locally

```bash
curl -I -H 'Host: space.nitclasses.com' \
http://127.0.0.1/

curl -I -H 'Host: yogurt.nitclasses.com' \
http://127.0.0.1/
```

Both commands should return `HTTP/1.1 200 OK`.

Also verify that the correct content is selected:

```bash
curl -fsS -H 'Host: space.nitclasses.com' \
  http://127.0.0.1/ | grep -i '<title>'

curl -fsS -H 'Host: yogurt.nitclasses.com' \
  http://127.0.0.1/ | grep -i '<title>'
```

Expected titles:

```text
Space Science Website Template
Frozen Yogurt Shop
```

### 10.2 Test through the browser

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

### 10.3 How Nginx selects the website

The browser sends one of these headers:

```text
Host: space.nitclasses.com
```

```text
Host: yogurt.nitclasses.com
```

Nginx compares the `Host` value with `server_name` and uses the matching server block.

### 10.4 Verify the dedicated logs

After opening both websites in the browser:

```bash
sudo tail -n 20 /var/log/nginx/space-access.log
sudo tail -n 20 /var/log/nginx/yogurt-access.log

sudo tail -n 20 /var/log/nginx/space-error.log
sudo tail -n 20 /var/log/nginx/yogurt-error.log
```

Search for important HTTP error statuses:

```bash
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/space-access.log | tail -20

sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/yogurt-access.log | tail -20
```

Separate logs make it easier to identify which virtual host received a request or experienced an error.

### 10.5 Verify firewall and SELinux after deployment

```bash
sudo firewall-cmd --zone=public --query-service=http
getenforce
ls -ldZ /var/www/space/html /var/www/yogurt/html
sudo semanage fcontext -l | grep -E '/var/www/(space|yogurt)'
```

Expected results include:

- HTTP service allowed by firewalld.
- SELinux may remain `Enforcing`.
- Website content labeled `httpd_sys_content_t`.
- Persistent custom mappings listed by `semanage`.

---

## 11. Troubleshooting

### 11.1 `403 Forbidden`

Check the Nginx error log:

```bash
sudo tail -n 30 /var/log/nginx/error.log
```

Check the homepage, permissions and SELinux context:

```bash
ls -lZ /var/www/space/html/index.html
namei -l /var/www/space/html/index.html
```

Common causes:

- `index.html` is missing;
- a parent directory lacks execute permission;
- the SELinux context is incorrect;
- the configured Nginx `root` points to the wrong directory.

Do not solve this by applying `chmod 777`. That grants unnecessary write permission and can hide the real ownership, path-traversal, or SELinux problem.

### 11.2 `404 Not Found`

Confirm that the URL path matches the filesystem path and that `index.html` is located at the expected top level.

```bash
find /var/www -name index.html -print
sudo nginx -T | less
```

Understand how Nginx builds the path:

```text
root /var/www/space/html;
request /about.html
final path /var/www/space/html/about.html
```

### 11.3 Wrong website appears

Check:

- the client hosts file;
- browser cache;
- the request's `Host` header;
- Nginx `server_name` values;
- duplicate or default server blocks.

```bash
sudo nginx -T
```

Test server selection explicitly:

```bash
curl -I -H 'Host: space.nitclasses.com' http://127.0.0.1/
curl -I -H 'Host: yogurt.nitclasses.com' http://127.0.0.1/
```

### 11.4 Nginx reload fails

```bash
sudo nginx -t
sudo journalctl -u nginx --no-pager -n 30
```

Correct the configuration error before attempting another reload.

Typical causes include a missing semicolon, unmatched brace, misspelled directive, duplicate listener, or invalid referenced path.

### 11.5 Port 80 is already in use

```bash
ss -tlnp | grep ':80'
```

Do not start a second web server on the same address and port unless the services are intentionally configured to use different addresses or ports.

Identify the owner of port 80 before taking action:

```bash
sudo ss -tlnp '( sport = :80 )'
sudo systemctl status nginx httpd --no-pager
```

### 11.6 SELinux mapping already exists

If `semanage fcontext -a` says that a mapping already exists, inspect custom rules:

```bash
sudo semanage fcontext -l -C
```

Modify the existing rule instead of adding a duplicate:

```bash
sudo semanage fcontext -m -t httpd_sys_content_t \
  '/var/www/space(/.*)?'
```

Then apply it:

```bash
sudo restorecon -Rv /var/www/space
```

### 11.7 Client cannot reach the VM

Check each layer:

```bash
ip -4 address
ip -4 route
sudo firewall-cmd --zone=public --query-service=http
sudo ss -tlnp | grep ':80'
curl -I http://127.0.0.1/
curl -I http://192.168.1.154/
```

From Windows:

```powershell
Test-NetConnection 192.168.1.154 -Port 80
curl.exe -I http://192.168.1.154/
```

This distinguishes a local Nginx problem from firewall, routing, VPN, or hostname-resolution problems.

---

## 12. Safe Cleanup

> These commands permanently remove the listed lab directories. Verify every path before pressing Enter.

Before cleanup, confirm that the backup archives exist and are readable:

```bash
ls -lh "$LAB_ROOT/backups/"
```

Select the exact timestamped archive you intend to use. Avoid passing a wildcard to `tar` when multiple backups may exist.

### 12.1 Preview the targets

```bash
ls -ld /var/www/lawfirm.com/html/space-science
ls -ld /var/www/lawfirm.com/html/frozen-yogurt
ls -ld /var/www/space
ls -ld /var/www/yogurt
ls -l /etc/nginx/conf.d/space.conf
ls -l /etc/nginx/conf.d/yogurt.conf
```

### 12.2 Remove Method 1 resources

```bash
sudo rm -rf -- /var/www/lawfirm.com/html/space-science
sudo rm -rf -- /var/www/lawfirm.com/html/frozen-yogurt
```

### 12.3 Remove Method 2 resources

```bash
sudo rm -rf -- /var/www/space
sudo rm -rf -- /var/www/yogurt

sudo rm -f -- /etc/nginx/conf.d/space.conf
sudo rm -f -- /etc/nginx/conf.d/yogurt.conf
```

### 12.4 Remove persistent SELinux mappings

```bash
sudo semanage fcontext -d '/var/www/space(/.*)?'
sudo semanage fcontext -d '/var/www/yogurt(/.*)?'
```

If a rule does not exist, `semanage` may report an error for that rule. Confirm the current custom mappings with:

```bash
sudo semanage fcontext -l -C
```

### 12.5 Validate and reload the remaining configuration

```bash
sudo nginx -t && sudo systemctl reload nginx
```

The `&&` means Nginx reloads only if `nginx -t` succeeds.

### 12.6 Remove the user-owned staging copies

These commands remove only the extracted and prepared working copies under the lab workspace. They keep the downloaded archives and backups for future practice.

```bash
rm -rf -- "$LAB_ROOT/extracted"
rm -rf -- "$LAB_ROOT/prepared"
```

Recreate the empty workspace directories when you want to repeat the lab:

```bash
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"
```

### 12.7 Verify cleanup

```bash
test ! -e /var/www/space && echo "Space document root removed"
test ! -e /var/www/yogurt && echo "Yogurt document root removed"
sudo nginx -t
```

### 12.8 Restore a backup when rollback is required

Do not guess the archive name. List the available backups and select the exact timestamped file:

```bash
ls -lh "$LAB_ROOT/backups/"
```

Inspect it before restoration:

```bash
tar -tzf \
  "$LAB_ROOT/backups/nginx-config-YYYY-MM-DD-HH-MM-SS.tar.gz" \
  | head -20
```

Restore the selected Nginx configuration only when rollback is intentionally required:

```bash
sudo tar -C /etc -xzf \
  "$LAB_ROOT/backups/nginx-config-YYYY-MM-DD-HH-MM-SS.tar.gz"
```

Validate immediately:

```bash
sudo nginx -t
sudo systemctl reload nginx
systemctl is-active nginx
```

Archive extraction restores archived files but does not automatically remove unrelated files created after the backup. Plan a complete reset carefully.

---

## 13. Command Summary

| Command | Purpose |
|---|---|
| `scp` | Copies archives to the server through SSH |
| `file` | Identifies a file's type |
| `unzip -l` | Lists a ZIP archive without extracting it |
| `unzip` | Extracts a ZIP archive |
| `find` | Locates files and applies permissions by file type |
| `cp -a` | Copies directories while preserving their structure |
| `chown` | Changes ownership |
| `chmod` | Changes permission bits |
| `restorecon` | Applies the expected SELinux context |
| `semanage fcontext` | Defines persistent SELinux file-context mappings |
| `nginx -t` | Validates Nginx configuration syntax |
| `systemctl reload nginx` | Reloads Nginx without a full stop and start |
| `curl -I` | Retrieves HTTP response headers |
| `ss -tlnp` | Shows listening TCP sockets and processes |
| `namei -l` | Shows ownership and permissions for every path component |
| `tar -czf` | Creates a gzip-compressed backup archive |
| `tar -tzf` | Lists a compressed archive without extracting it |
| `unzip -t` | Tests ZIP archive integrity |
| `semanage fcontext -l -C` | Lists locally customized SELinux file contexts |
| `journalctl -u nginx` | Shows Nginx service journal messages |

---

## 14. Key Learning Points

1. A single Nginx server can host multiple static websites.
2. A URL path can map to a subdirectory under one document root.
3. Named virtual hosts can share an IP address and port.
4. Nginx uses the HTTP `Host` header to select a named virtual host.
5. `index.html` normally acts as the homepage of a directory.
6. Website assets must remain in the directory structure expected by the HTML files.
7. Linux permissions and SELinux contexts must both allow Nginx to read the content.
8. `nginx -t` should always succeed before Nginx is reloaded.
9. Manual deployment helps explain what Ansible modules automate.
10. Cleanup should remove only the resources created for the lab.

---

## 15. Nginx Directives and Blocks

### 15.1 What is a directive?

A directive is one instruction that tells Nginx what to do.

```nginx
listen 80;
server_name space.nitclasses.com;
root /var/www/space/html;
index index.html;
```

General form:

```text
directive-name value;
```

A simple directive ends with a semicolon.

### 15.2 What is a block?

A block groups related directives inside braces:

```nginx
server {
    listen 80;
    server_name space.nitclasses.com;
}
```

A block creates a configuration context. Directives inside it apply within that context.

### 15.3 Nginx hierarchy

```nginx
events {
    # Connection-processing settings
}

http {
    # General HTTP settings

    server {
        # One virtual website

        location / {
            # Rules for matching request URIs
        }
    }
}
```

On Rocky Linux, `/etc/nginx/nginx.conf` normally includes `/etc/nginx/conf.d/*.conf` inside the `http` context.

Confirm with:

```bash
sudo nginx -T | less
```

### 15.4 Directive reference

| Directive | Purpose |
|---|---|
| `listen 80;` | Accept IPv4 HTTP connections on port 80 |
| `listen [::]:80;` | Accept IPv6 HTTP connections on port 80 |
| `server_name` | Match the hostname from the HTTP Host header |
| `root` | Define the filesystem document root |
| `index` | Define the default file for a directory request |
| `access_log` | Record requests for this virtual host |
| `error_log` | Record errors for this virtual host |
| `location /` | Match all URI paths beginning with `/` |
| `try_files` | Check possible files or directories in order |

### 15.5 Understanding `try_files`

```nginx
try_files $uri $uri/ =404;
```

Nginx checks from left to right:

1. `$uri`: Does the requested file exist?
2. `$uri/`: Does the requested directory exist?
3. `=404`: If neither exists, return `404 Not Found`.

Example:

```text
root: /var/www/space/html
URI:  /about.html
path: /var/www/space/html/about.html
```

---

## 16. Request Flow and Log Interpretation

### 16.1 Complete remote-VM request flow

```text
Browser requests http://space.nitclasses.com/
  -> Windows hosts file returns 192.168.1.154
  -> Traffic crosses the local network or VPN
  -> Rocky Linux firewalld permits HTTP
  -> Nginx accepts TCP port 80
  -> Nginx reads Host: space.nitclasses.com
  -> server_name selects space.conf
  -> root selects /var/www/space/html
  -> SELinux and Unix permissions allow read access
  -> Nginx returns index.html and its assets
```

### 16.2 Understanding an access-log entry

Example:

```text
192.168.1.50 ... "GET /css/style.css HTTP/1.1" 200 27373 ...
```

| Field | Meaning |
|---|---|
| `192.168.1.50` | Client source address |
| `GET` | Request method for the complete resource |
| `/css/style.css` | Requested URI |
| `HTTP/1.1` | HTTP protocol version |
| `200` | Successful response |
| `27373` | Response-body size in bytes |

`curl -I` sends a `HEAD` request. The log may show a successful status with a zero response-body size because HEAD returns headers without the resource body.

### 16.3 Why a favicon 404 is normally harmless

Browsers commonly request:

```text
/favicon.ico
```

If the template does not provide it at the web root, Nginx returns `404`. This does not break HTML, CSS, JavaScript, images, or fonts. A favicon can be added later if required.

---

## 17. Interview-Ready Summary

> I manually deployed two static websites on a Rocky Linux 9.8 virtual machine using Nginx. I first collected system, network, firewall, port, and SELinux baselines and backed up the Nginx configuration and existing web root. I transferred and tested both ZIP archives, identified their actual document roots, and removed a non-runtime PSD asset from the prepared deployment copy. I deployed the sites using URL subdirectories and then created two hostname-based server blocks. I applied `root:root` ownership, `755` directory permissions, `644` file permissions, and persistent `httpd_sys_content_t` SELinux mappings. I opened HTTP through firewalld, tested Nginx syntax before reloading, and configured the Windows hosts file to resolve both names to the VM address. Finally, I verified HTTP status, page titles, assets, Host-header routing, dedicated access and error logs, SELinux contexts, and browser rendering. Only the optional favicon request returned a harmless 404.

---

## 18. Final Lab Checklist

| Check | Expected result |
|---|---|
| Correct host | `node1.nitclasses.com` |
| Rocky Linux version | 9.8 |
| Nginx active and enabled | PASS |
| Port 80 owned by Nginx | PASS |
| HTTP allowed by firewalld | PASS |
| SELinux remains enforcing | Preferred |
| ZIP integrity tests | PASS |
| PSD excluded from deployment | PASS |
| Configuration and content backups | PASS |
| Directories owned by `root:root` with `755` | PASS |
| Files owned by `root:root` with `644` | PASS |
| Persistent SELinux mappings | PASS |
| Method 1 URLs | `200 OK` |
| Method 2 Host-header tests | `200 OK` |
| Windows hostname mappings | Resolve to `192.168.1.154` |
| Browser HTML, CSS, JS, images, fonts | PASS |
| Dedicated error logs | Empty or explained |
| Optional `/favicon.ico` | Harmless 404 if absent |

The same manual workflow can later be converted into an Ansible playbook for repeatable deployment across multiple Rocky Linux nodes.
