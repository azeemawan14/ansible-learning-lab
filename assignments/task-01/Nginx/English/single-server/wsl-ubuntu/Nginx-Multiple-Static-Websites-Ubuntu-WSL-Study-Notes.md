# Nginx Multiple Static Websites on Ubuntu WSL

## Complete Hands-On Study Notes

This document records the complete lab for deploying two static websites on one Nginx server using two different methods:

1. URL subdirectories
2. Hostname-based virtual hosts (Nginx server blocks)

The lab was completed on Ubuntu 24.04 WSL2 with Nginx 1.24.0.

---

## Table of Contents

1. [Lab objectives](#1-lab-objectives)
2. [Final architecture](#2-final-architecture)
3. [Important terminology](#3-important-terminology)
4. [Environment and baseline checks](#4-environment-and-baseline-checks)
5. [Firewall configuration](#5-firewall-configuration)
6. [Download the website templates](#6-download-the-website-templates)
7. [Extract and inspect the archives](#7-extract-and-inspect-the-archives)
8. [Prepare clean deployment copies](#8-prepare-clean-deployment-copies)
9. [Back up the existing web root](#9-back-up-the-existing-web-root)
10. [Method 1: Host websites through URL paths](#10-method-1-host-websites-through-url-paths)
11. [Method 1 verification](#11-method-1-verification)
12. [Nginx directives and blocks](#12-nginx-directives-and-blocks)
13. [Method 2: Host websites with separate hostnames](#13-method-2-host-websites-with-separate-hostnames)
14. [Enable and apply the server blocks](#14-enable-and-apply-the-server-blocks)
15. [Test virtual hosts with curl](#15-test-virtual-hosts-with-curl)
16. [Configure the Windows hosts file](#16-configure-the-windows-hosts-file)
17. [Browser and log verification](#17-browser-and-log-verification)
18. [Command reference and explanations](#18-command-reference-and-explanations)
19. [Troubleshooting guide](#19-troubleshooting-guide)
20. [Safe rollback and cleanup](#20-safe-rollback-and-cleanup)
21. [Interview summary](#21-interview-summary)
22. [Final lab results](#22-final-lab-results)

---

## 1. Lab objectives

The objectives were to:

- Install and validate Nginx on Ubuntu WSL.
- Download two static website templates.
- Inspect archive contents before deployment.
- Remove an unnecessary PSD source file from the deployment copy.
- Back up the existing Nginx document root.
- Deploy both websites under URL subdirectories.
- Deploy the same websites through separate hostnames.
- Configure ownership and permissions safely.
- Understand Nginx directives, blocks, contexts, `server_name`, `root`, `location`, and `try_files`.
- Test with `curl`, a Windows browser, and Nginx logs.
- Document troubleshooting and rollback procedures.

The websites used were:

- Space Science
- Frozen Yogurt Shop

---

## 2. Final architecture

### Method 1: URL paths

```text
http://localhost/space-science/
http://localhost/frozen-yogurt/
```

Document roots:

```text
/var/www/html/space-science/
/var/www/html/frozen-yogurt/
```

### Method 2: Separate hostnames

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

Document roots:

```text
/var/www/space/html/
/var/www/yogurt/html/
```

Request flow:

```text
Browser URL
  -> Windows hosts file resolves the name to 127.0.0.1
  -> Windows localhost forwarding reaches WSL
  -> Nginx accepts the connection on TCP port 80
  -> Nginx reads the HTTP Host header
  -> server_name selects the correct server block
  -> root identifies the correct document root
  -> Nginx returns the requested static file
```

---

## 3. Important terminology

### Static website

A static website contains files that Nginx can return directly, such as:

- HTML
- CSS
- JavaScript
- Images
- Fonts

It does not require a backend application to generate each page dynamically.

### Document root

The document root is the directory containing the files for a website.

Example:

```nginx
root /var/www/space/html;
```

### Virtual host or server block

A server block defines one virtual website in Nginx. Multiple server blocks allow one Nginx service, IP address, and port to host multiple websites.

### Host header

The browser sends an HTTP header identifying the requested hostname:

```http
Host: space.nitclasses.com
```

Nginx compares it with `server_name` to select the website.

### Local hosts file

The Windows hosts file creates hostname-to-IP mappings on one Windows computer. It does not create a public DNS record.

---

## 4. Environment and baseline checks

### Check Nginx service state

```bash
systemctl is-active nginx
systemctl is-enabled nginx
```

Expected:

```text
active
enabled
```

The correct command is `is-enabled`, not `is-enable`.

### Display the Nginx version

```bash
nginx -v
```

Lab result:

```text
nginx version: nginx/1.24.0 (Ubuntu)
```

### Test the current configuration

```bash
sudo nginx -t
```

Successful output:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Check port 80

```bash
sudo ss -tlnp | grep ':80'
```

The lab showed Nginx listening on IPv4 and IPv6:

```text
0.0.0.0:80
[::]:80
```

### Test the default website

```bash
curl -I http://127.0.0.1/
```

Expected:

```text
HTTP/1.1 200 OK
```

---

## 5. Firewall configuration

Ubuntu commonly uses UFW, while Rocky Linux commonly uses firewalld. This WSL lab installed and used firewalld for practice.

### Allow HTTP permanently

```bash
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
```

Lab output included:

```text
dhcpv6-client http ssh
```

Important points:

- `--permanent` saves the rule persistently.
- `--reload` applies permanent configuration to the running firewall.
- `http` represents TCP port 80.
- WSL networking differs from a regular VM, but these commands are useful firewalld practice.

---

## 6. Download the website templates

### Create a lab directory

```bash
mkdir -p "$HOME/nginx-multisite-lab/downloads"
cd "$HOME/nginx-multisite-lab/downloads"
```

### Download with controlled filenames

```bash
wget -O space-science.zip \
  'https://freewebsitetemplates.com/download/space-science/'
```

```bash
wget -O frozen-yogurt.zip \
  'https://freewebsitetemplates.com/download/frozenyogurtshop/'
```

`wget -O` means save the response using the specified local filename.

### Confirm the archives

```bash
ls -lh *.zip
file *.zip
unzip -t space-science.zip
unzip -t frozen-yogurt.zip
```

`unzip -t` tests archive integrity without extracting it.

---

## 7. Extract and inspect the archives

### Create extraction directories

```bash
cd "$HOME/nginx-multisite-lab"
mkdir -p extracted/space
mkdir -p extracted/yogurt
```

### Extract quietly

```bash
unzip -q downloads/space-science.zip \
  -d extracted/space
```

```bash
unzip -q downloads/frozen-yogurt.zip \
  -d extracted/yogurt
```

Options:

- `-q`: quiet extraction
- `-d`: extraction destination

### Find the actual website roots

```bash
find extracted -type f -name index.html -print
```

Lab result:

```text
extracted/yogurt/frozenyogurtshop/index.html
extracted/space/space-science/upload/index.html
```

These parent directories were the deployable website roots.

### Inspect sizes

```bash
du -sh extracted/space/space-science/upload
du -sh extracted/yogurt/frozenyogurtshop
```

Results:

```text
1.9M extracted/space/space-science/upload
52M  extracted/yogurt/frozenyogurtshop
```

The Yogurt directory was much larger because it contained a 52 MB Photoshop source file:

```text
frozenyogurtshop.psd
```

The PSD file was not required by the website and was excluded from deployment.

---

## 8. Prepare clean deployment copies

### Create preparation directories

```bash
mkdir -p prepared/space-science
mkdir -p prepared/frozen-yogurt
```

### Copy the website contents

```bash
cp -a extracted/space/space-science/upload/. \
  prepared/space-science/
```

```bash
cp -a extracted/yogurt/frozenyogurtshop/. \
  prepared/frozen-yogurt/
```

Why use `source/.`?

```text
source/. -> copy everything inside the source directory
```

It avoids adding another unnecessary directory level.

### Exclude the PSD file only from the prepared copy

```bash
rm -f -- prepared/frozen-yogurt/frozenyogurtshop.psd
```

The original extracted archive content remained unchanged.

### Verify preparation

```bash
ls -l prepared/space-science/index.html
ls -l prepared/frozen-yogurt/index.html
```

```bash
test ! -e prepared/frozen-yogurt/frozenyogurtshop.psd \
  && echo "PASS: PSD file excluded"
```

### List top-level website files

```bash
find prepared/space-science \
  -maxdepth 1 \
  -mindepth 1 \
  -printf '%f\n' |
sort
```

Repeat for `prepared/frozen-yogurt`.

---

## 9. Back up the existing web root

### Inspect the current web root

```bash
sudo find /var/www/html \
  -maxdepth 2 \
  -printf '%M %u:%g %p\n'
```

### Create the backup directory and timestamped filename

```bash
mkdir -p "$HOME/nginx-multisite-lab/backups"
```

```bash
backup_file="$HOME/nginx-multisite-lab/backups/var-www-html-before-deployment-$(date '+%Y-%m-%d-%H-%M-%S').tar.gz"
```

```bash
printf 'Backup destination: %s\n' "$backup_file"
```

### Create the compressed backup

```bash
sudo tar -C /var/www -czf - html > "$backup_file"
```

Explanation:

- `sudo tar`: reads protected files with root permission.
- `-C /var/www`: changes tar's working directory before archiving.
- `-c`: creates an archive.
- `-z`: compresses with gzip.
- `-f -`: writes the archive to standard output.
- `> "$backup_file"`: the regular user shell writes the output to the user-owned backup file.
- Archiving from `/var/www` stores paths beginning with `html/`, not a full absolute path.

### Verify the backup

```bash
ls -lh "$backup_file"
tar -tzf "$backup_file" | head -20
```

Lab archive contents began with:

```text
html/
html/index.nginx-debian.html
html/index.html
```

`tar -tzf` explanation:

- `-t`: list archive contents
- `-z`: process gzip compression
- `-f`: read the named archive file
- `head -20`: display only the first 20 lines

This verifies readability without restoring or modifying anything.

---

## 10. Method 1: Host websites through URL paths

### Create destination directories

```bash
sudo install -d \
  -o root \
  -g root \
  -m 0755 \
  /var/www/html/space-science
```

```bash
sudo install -d \
  -o root \
  -g root \
  -m 0755 \
  /var/www/html/frozen-yogurt
```

`install -d` creates directories while setting ownership and permissions in one command.

### Copy both websites

```bash
sudo cp -a prepared/space-science/. \
  /var/www/html/space-science/
```

```bash
sudo cp -a prepared/frozen-yogurt/. \
  /var/www/html/frozen-yogurt/
```

### Standardize ownership

```bash
sudo chown -R root:root \
  /var/www/html/space-science \
  /var/www/html/frozen-yogurt
```

Nginx only needs read and directory-traversal access for static files; it does not need to own them.

### Set safe directory permissions

```bash
sudo find /var/www/html/space-science \
  -type d \
  -exec chmod 755 {} +
```

```bash
sudo find /var/www/html/frozen-yogurt \
  -type d \
  -exec chmod 755 {} +
```

### Set safe file permissions

```bash
sudo find /var/www/html/space-science \
  -type f \
  -exec chmod 644 {} +
```

```bash
sudo find /var/www/html/frozen-yogurt \
  -type f \
  -exec chmod 644 {} +
```

Permissions:

```text
Directories 755: owner rwx, group r-x, others r-x
Files       644: owner rw-, group r--, others r--
```

Directory execute permission allows Nginx to traverse the path.

### Verify the deployed structure

```bash
sudo find /var/www/html/space-science \
  -maxdepth 2 \
  -printf '%M %u:%g %p\n' |
head -30
```

```bash
sudo find /var/www/html/frozen-yogurt \
  -maxdepth 2 \
  -printf '%M %u:%g %p\n' |
head -30
```

### Confirm the entry files and PSD exclusion

```bash
ls -l \
  /var/www/html/space-science/index.html \
  /var/www/html/frozen-yogurt/index.html
```

```bash
test ! -e /var/www/html/frozen-yogurt/frozenyogurtshop.psd \
  && echo "PASS: PSD file was not deployed"
```

### Inspect every path component

```bash
namei -l /var/www/html/space-science/index.html
namei -l /var/www/html/frozen-yogurt/index.html
```

`namei -l` breaks a pathname into components and displays ownership and permissions for each one. It helps diagnose `403 Forbidden` errors caused by a parent directory that Nginx cannot traverse.

---

## 11. Method 1 verification

### Test Nginx syntax

```bash
sudo nginx -t
```

### Test home pages

```bash
curl -I http://127.0.0.1/space-science/
curl -I http://127.0.0.1/frozen-yogurt/
```

Both returned:

```text
HTTP/1.1 200 OK
```

### Confirm website identity

```bash
curl -fsS http://127.0.0.1/space-science/ |
grep -i '<title>'
```

Result:

```html
<title>Space Science Website Template</title>
```

### Test CSS assets

```bash
curl -I http://127.0.0.1/space-science/css/style.css
curl -I http://127.0.0.1/frozen-yogurt/css/style.css
```

Both returned `200 OK`.

### Test internal pages

```bash
curl -I http://127.0.0.1/space-science/about.html
curl -I http://127.0.0.1/space-science/projects.html
curl -I http://127.0.0.1/frozen-yogurt/blog.html
curl -I http://127.0.0.1/frozen-yogurt/contact.html
```

All returned `200 OK`.

### Inspect logs

```bash
sudo tail -n 30 /var/log/nginx/error.log
sudo tail -n 30 /var/log/nginx/access.log
sudo grep ' 404 ' /var/log/nginx/access.log | tail -20
```

The error log was empty. Browser requests for HTML, CSS, images, JavaScript, and fonts returned `200`. Only `/favicon.ico` returned `404`, which was harmless.

---

## 12. Nginx directives and blocks

### What is a directive?

A directive is one instruction that tells Nginx what to do.

```nginx
listen 80;
server_name space.nitclasses.com;
root /var/www/space/html;
index index.html;
```

General syntax:

```text
directive-name value;
```

The semicolon ends a simple directive.

### What is a block?

A block is a group of related directives enclosed by curly braces:

```nginx
server {
    listen 80;
    server_name space.nitclasses.com;
}
```

Blocks create configuration contexts. Directives inside a block apply within that context.

### Common hierarchy

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

On Ubuntu, the main `nginx.conf` includes files from `sites-enabled` inside its `http` context.

### Directive reference

| Directive | Meaning |
|---|---|
| `listen 80;` | Accept IPv4 HTTP connections on port 80 |
| `listen [::]:80;` | Accept IPv6 HTTP connections on port 80 |
| `server_name` | Hostname used to select the server block |
| `root` | Filesystem document root |
| `index` | Default file for a directory request |
| `access_log` | File recording HTTP requests |
| `error_log` | File recording website-specific errors |
| `location /` | Rules matching all URI paths beginning with `/` |
| `try_files` | Checks possible filesystem targets in order |

### Understanding `try_files`

```nginx
try_files $uri $uri/ =404;
```

Nginx checks from left to right:

1. `$uri`: Does the requested file exist?
2. `$uri/`: Does the requested directory exist?
3. `=404`: If neither exists, immediately return `404 Not Found`.

Example:

```text
root: /var/www/space/html
URI:  /about.html
path: /var/www/space/html/about.html
```

---

## 13. Method 2: Host websites with separate hostnames

### Create separate document roots

```bash
sudo install -d \
  -o root \
  -g root \
  -m 0755 \
  /var/www/space/html
```

```bash
sudo install -d \
  -o root \
  -g root \
  -m 0755 \
  /var/www/yogurt/html
```

### Copy the prepared content

```bash
sudo cp -a prepared/space-science/. \
  /var/www/space/html/
```

```bash
sudo cp -a prepared/frozen-yogurt/. \
  /var/www/yogurt/html/
```

`cp -a` preserved the source owner (`khalid:khalid`), so ownership was standardized afterward.

### Apply ownership and permissions

```bash
sudo chown -R root:root \
  /var/www/space \
  /var/www/yogurt
```

```bash
sudo find /var/www/space /var/www/yogurt \
  -type d \
  -exec chmod 755 {} +
```

```bash
sudo find /var/www/space /var/www/yogurt \
  -type f \
  -exec chmod 644 {} +
```

### Check for noncompliant permissions

```bash
sudo find /var/www/space /var/www/yogurt \
  -type d ! -perm 0755 \
  -print
```

```bash
sudo find /var/www/space /var/www/yogurt \
  -type f ! -perm 0644 \
  -print
```

Both commands produced no output, confirming compliance.

### Space Science server block

File:

```text
/etc/nginx/sites-available/space
```

Configuration:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name space.nitclasses.com;

    root /var/www/space/html;
    index index.html;

    access_log /var/log/nginx/space-access.log;
    error_log  /var/log/nginx/space-error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Frozen Yogurt server block

File:

```text
/etc/nginx/sites-available/yogurt
```

Configuration:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name yogurt.nitclasses.com;

    root /var/www/yogurt/html;
    index index.html;

    access_log /var/log/nginx/yogurt-access.log;
    error_log  /var/log/nginx/yogurt-error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Display a configuration safely

```bash
sudo sed -n '1,120p' /etc/nginx/sites-available/space
sudo sed -n '1,120p' /etc/nginx/sites-available/yogurt
```

`sed -n '1,120p'` prints lines 1 through 120 without modifying the file.

---

## 14. Enable and apply the server blocks

Ubuntu separates available configurations from enabled configurations:

```text
/etc/nginx/sites-available/ -> configuration files that exist
/etc/nginx/sites-enabled/   -> configurations Nginx actively loads
```

### Create symbolic links

```bash
sudo ln -s \
  /etc/nginx/sites-available/space \
  /etc/nginx/sites-enabled/space
```

```bash
sudo ln -s \
  /etc/nginx/sites-available/yogurt \
  /etc/nginx/sites-enabled/yogurt
```

A symbolic link is a reference or shortcut to another filesystem path. Editing the real file under `sites-available` changes what Nginx reads through the link under `sites-enabled`.

### Test before applying

```bash
sudo nginx -t
```

Successful result:

```text
syntax is ok
test is successful
```

### Reload Nginx

```bash
sudo systemctl reload nginx
echo $?
systemctl is-active nginx
```

Lab result:

```text
0
active
```

Safe workflow:

```text
Edit -> Test -> Reload -> Verify
```

Difference:

| Command | Purpose |
|---|---|
| `nginx -t` | Test syntax and referenced configuration files |
| `systemctl reload nginx` | Load valid changes without fully stopping the service |
| `systemctl restart nginx` | Stop and start the service |

---

## 15. Test virtual hosts with curl

Before changing name resolution, manually send the required Host header.

### Header-only tests

```bash
curl -I \
  -H 'Host: space.nitclasses.com' \
  http://127.0.0.1/
```

```bash
curl -I \
  -H 'Host: yogurt.nitclasses.com' \
  http://127.0.0.1/
```

Results:

```text
Space:  HTTP/1.1 200 OK, Content-Length: 3538
Yogurt: HTTP/1.1 200 OK, Content-Length: 2601
```

### Confirm content identity

```bash
curl -fsS \
  -H 'Host: space.nitclasses.com' \
  http://127.0.0.1/ |
grep -i '<title>'
```

```bash
curl -fsS \
  -H 'Host: yogurt.nitclasses.com' \
  http://127.0.0.1/ |
grep -i '<title>'
```

Results:

```html
<title>Space Science Website Template</title>
<title>Frozen Yogurt Shop</title>
```

### Curl option reference

| Option | Meaning |
|---|---|
| `-I` | Send a HEAD request and show response headers only |
| `-H` | Add or replace an HTTP request header |
| `-f` | Return failure for HTTP errors |
| `-s` | Silent mode |
| `-S` | Display errors even with silent mode enabled |

The connection went to `127.0.0.1:80`, but the custom Host header told Nginx which server block to select.

---

## 16. Configure the Windows hosts file

This step was performed from an Administrator PowerShell window.

### Define the hosts-file path

```powershell
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
```

### Create a timestamped backup

```powershell
$backupFile = "$hostsFile.backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Backup created: $backupFile"
```

Lab backup:

```text
C:\Windows\System32\drivers\etc\hosts.backup-2026-09-28-19-08-52
```

### Check for existing entries

```powershell
Select-String -Path $hostsFile \
  -Pattern 'space\.nitclasses\.com|yogurt\.nitclasses\.com'
```

No output meant the entries did not already exist.

### Add local mappings

```powershell
Add-Content -Path $hostsFile -Encoding ascii \
  -Value "`r`n127.0.0.1 space.nitclasses.com"
```

```powershell
Add-Content -Path $hostsFile -Encoding ascii \
  -Value "127.0.0.1 yogurt.nitclasses.com"
```

Final mappings:

```text
127.0.0.1 space.nitclasses.com
127.0.0.1 yogurt.nitclasses.com
```

These mappings apply only to the local Windows laptop. They are not public DNS records.

### Verify and flush the DNS cache

```powershell
Get-Content $hostsFile |
    Select-String 'space\.nitclasses\.com|yogurt\.nitclasses\.com'
```

```powershell
ipconfig /flushdns
```

Successful result:

```text
Successfully flushed the DNS Resolver Cache.
```

### Test from Windows

```powershell
curl.exe -I http://space.nitclasses.com/
curl.exe -I http://yogurt.nitclasses.com/
```

Both returned `HTTP/1.1 200 OK` with the expected content lengths.

Browser URLs:

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

The browser displayed `Not secure` because the lab used HTTP, not HTTPS. This is expected and is not an Nginx error.

---

## 17. Browser and log verification

Both websites rendered successfully with their CSS, JavaScript, images, fonts, navigation, and internal content.

### Check separate access logs

```bash
sudo tail -n 20 /var/log/nginx/space-access.log
sudo tail -n 20 /var/log/nginx/yogurt-access.log
```

Space log entries showed successful requests for:

- `/`
- `/css/style.css`
- `/css/mobile.css`
- `/js/mobile.js`
- Images
- Web fonts

The website assets returned `200`.

### Check error logs

```bash
sudo tail -n 20 /var/log/nginx/space-error.log
sudo tail -n 20 /var/log/nginx/yogurt-error.log
```

Empty output indicates that no website-specific Nginx errors were recorded.

### Search access logs for important error statuses

```bash
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/space-access.log |
tail -20
```

```bash
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/yogurt-access.log |
tail -20
```

Only this optional browser request failed:

```text
GET /favicon.ico -> 404
```

Browsers automatically request `/favicon.ico` for a tab icon. Neither template supplied one at the web-root level. This did not affect either website.

### Understanding an access-log line

Example:

```text
127.0.0.1 ... "GET /css/style.css HTTP/1.1" 200 27373 ...
```

| Field | Meaning |
|---|---|
| `127.0.0.1` | Client source address seen by WSL Nginx |
| `GET` | Request the complete resource |
| `/css/style.css` | Requested URI |
| `HTTP/1.1` | HTTP protocol version |
| `200` | Request succeeded |
| `27373` | Response body size in bytes |

`curl -I` creates a `HEAD` request. A successful HEAD entry can show response size `0` in the access log because headers are returned without the file body.

---

## 18. Command reference and explanations

### `find` grouping

Correct Bash syntax:

```bash
find "$HOME" /mnt/c/Users \
  -type f \
  \( -iname '*space*.zip' -o -iname '*frozen*.zip' -o -iname '*yogurt*.zip' \) \
  2>/dev/null
```

The parentheses must be escaped so Bash passes them to `find`. Unescaped `(` causes a Bash syntax error.

### `cp -a source/. destination/`

- `cp`: copy
- `-a`: archive mode; preserve structure, permissions, ownership where possible, and timestamps
- `source/.`: copy contents, including hidden entries
- `destination/`: target directory

Because archive mode preserved `khalid:khalid`, the deployed trees were intentionally changed to `root:root` afterward.

### `find ... -exec chmod ... {} +`

Example:

```bash
find /var/www/space -type d -exec chmod 755 {} +
```

- `-type d`: select directories only
- `-exec`: run a command on results
- `{}`: placeholder for matched paths
- `+`: pass multiple paths per `chmod` execution efficiently

### `find -printf`

```bash
find PATH -printf '%M %u:%g %p\n'
```

- `%M`: symbolic permissions
- `%u`: owner
- `%g`: group
- `%p`: complete matched path
- `\n`: newline

### `test ! -e`

```bash
test ! -e FILE && echo "PASS"
```

- `test`: evaluate a condition
- `-e`: path exists
- `!`: negate the test
- `&&`: run the next command only when the test succeeds

Therefore, the message prints only when the file does not exist.

### `namei -l`

Displays each component of a path with its permissions and ownership. This is especially valuable for troubleshooting Nginx `403 Forbidden` errors.

### `curl -I`

Sends an HTTP HEAD request. It verifies status and headers without downloading the response body.

### `curl -fsS`

Useful in scripts:

- Fail on HTTP errors
- Avoid the progress meter
- Still display actual errors

### Pipeline symbol `|`

The pipe sends standard output from the command on the left into standard input of the command on the right.

Example:

```bash
curl -fsS URL | grep -i '<title>'
```

### Exit status

```bash
echo $?
```

Displays the exit status of the most recently completed command:

- `0`: success
- Nonzero: failure or another condition documented by the command

### Terminal `[200~` paste artifact

An accidental command began with:

```text
[200~sudo grep ...
```

`[200~` is associated with terminal bracketed-paste handling. It is not part of the intended command. Pressing `Ctrl+C` canceled the malformed command safely, after which the correct command was entered again.

---

## 19. Troubleshooting guide

### Configuration test fails

```bash
sudo nginx -t
```

Inspect the reported filename and line number. Common causes include:

- Missing semicolon
- Missing or extra brace
- Misspelled directive
- Duplicate conflicting configuration
- Invalid path

Do not reload until `nginx -t` succeeds.

### `403 Forbidden`

Check:

```bash
namei -l /var/www/space/html/index.html
ls -l /var/www/space/html/index.html
sudo tail -n 50 /var/log/nginx/space-error.log
```

Possible causes:

- Missing `index.html`
- Nginx cannot traverse a parent directory
- File cannot be read
- Wrong document root
- Directory request without an index file
- Distribution security controls such as SELinux on RHEL-family systems

Avoid `chmod 777`. It grants unnecessary write permissions and often hides rather than solves the underlying problem.

### `404 Not Found`

Check how Nginx combines `root` and the requested URI:

```text
root /var/www/space/html;
request /about.html
result /var/www/space/html/about.html
```

Then verify:

```bash
ls -l /var/www/space/html/about.html
```

### Wrong website appears

Check the request Host header and server-name selection:

```bash
curl -I -H 'Host: space.nitclasses.com' http://127.0.0.1/
sudo nginx -T | grep -n 'server_name'
```

Also confirm the Windows hosts-file entries.

### Port 80 is already in use

```bash
sudo ss -tlnp | grep ':80'
```

Only one process can normally bind the same IP address and port combination. Stop or reconfigure the conflicting service, such as Apache/httpd, before starting Nginx on the same listener.

### Browser works but shows `Not secure`

The site uses HTTP. HTTPS requires TLS configuration and a certificate trusted for the requested hostname.

### Favicon 404

This is harmless unless a site icon is required. To resolve it, provide a favicon file and reference it from the HTML, or place a suitable `favicon.ico` at the expected web root.

### Windows hostname does not resolve

Check:

```powershell
Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" |
  Select-String 'nitclasses'
```

Then:

```powershell
ipconfig /flushdns
curl.exe -I http://space.nitclasses.com/
```

Ensure PowerShell was opened as Administrator when editing the hosts file.

---

## 20. Safe rollback and cleanup

Perform cleanup only when the lab is no longer needed.

### Disable Method 2 server blocks

Removing the links disables the sites while preserving their source configurations:

```bash
sudo unlink /etc/nginx/sites-enabled/space
sudo unlink /etc/nginx/sites-enabled/yogurt
```

Test and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Remove Windows hosts entries

Open this file as Administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Remove only:

```text
127.0.0.1 space.nitclasses.com
127.0.0.1 yogurt.nitclasses.com
```

Then run:

```powershell
ipconfig /flushdns
```

Alternatively, restore the timestamped hosts-file backup only after confirming that it does not discard unrelated changes made since the backup.

### Remove website data only after verification

Before deleting anything, inspect the exact targets:

```bash
sudo find /var/www/space /var/www/yogurt -maxdepth 2 -print
```

If intentionally cleaning the lab, remove only the explicitly verified lab directories. Do not use a broad or unresolved path.

### Restore the Method 1 web-root backup

First inspect the archive:

```bash
tar -tzf "$backup_file" | head -20
```

Restoring over `/var/www` changes live content. Use the exact verified archive and perform this only when rollback is intended:

```bash
sudo tar -C /var/www -xzf "$backup_file"
```

After restoration:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -I http://127.0.0.1/
```

Note: extracting the backup restores archived files but does not automatically delete additional files that were created after the backup. A complete reset should be planned carefully rather than performed with a broad deletion command.

---

## 21. Interview summary

> I deployed two static websites on one Ubuntu Nginx server using both URL-path hosting and hostname-based virtual hosting. I first validated Nginx, tested archive integrity, identified the correct document roots, removed a non-runtime PSD asset from the prepared deployment, and backed up the existing web root. I deployed the content with root ownership, `755` directory permissions, and `644` file permissions. For hostname routing, I created separate Nginx server blocks with unique `server_name`, `root`, access-log, and error-log directives, enabled them with symbolic links, tested the configuration with `nginx -t`, and applied it with a reload. I verified routing through custom Host headers, Windows hosts-file mappings, browser tests, and separate Nginx logs. All required resources returned `200 OK`; only the optional favicon request returned `404`.

---

## 22. Final lab results

| Check | Result |
|---|---|
| Nginx active and enabled | PASS |
| Nginx syntax test | PASS |
| Website archives valid | PASS |
| Correct document roots identified | PASS |
| PSD file excluded | PASS |
| Existing `/var/www/html` backed up | PASS |
| Directory ownership and permissions | PASS |
| File ownership and permissions | PASS |
| Method 1 Space Science page | PASS |
| Method 1 Frozen Yogurt page | PASS |
| Space server block | PASS |
| Yogurt server block | PASS |
| Host-header routing | PASS |
| Windows hosts-file routing | PASS |
| Browser rendering and assets | PASS |
| Separate access logs | PASS |
| Website-specific error logs | Clean |
| Optional `/favicon.ico` | Harmless 404 |

The lab successfully demonstrated how one Nginx service can host multiple static websites through URL paths and separate hostnames.

