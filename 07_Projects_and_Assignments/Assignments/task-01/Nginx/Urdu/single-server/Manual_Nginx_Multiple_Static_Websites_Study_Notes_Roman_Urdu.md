# Manual Nginx Deployment: Do Static Websites — Roman Urdu Study Notes

Yeh study notes Rocky Linux 9.8 ke `node1.nitclasses.com` server par **Space Science** aur **Frozen Yogurt Shop** websites manually deploy karna sikhati hain. Lab workspace WSL wali directory structure follow karta hai, jabke Rocky Linux ke system paths apni standard locations par rehte hain.

## Fehrist (Table of Contents)

1. [Lab ka maqsad](#1-lab-ka-maqsad)
2. [Manual Linux aur Ansible ka talluq](#2-manual-linux-aur-ansible-ka-talluq)
3. [Lab environment](#3-lab-environment)
4. [Node1 se connect aur workspace tayar karna](#4-node1-se-connect-aur-workspace-tayar-karna)
5. [Nginx install aur configure karna](#5-nginx-install-aur-configure-karna)
6. [Website templates download aur prepare karna](#6-website-templates-download-aur-prepare-karna)
7. [Method 1: URL subdirectories](#7-method-1-url-subdirectories)
8. [Method 1 ki verification](#8-method-1-ki-verification)
9. [Method 2: Alag hostnames](#9-method-2-alag-hostnames)
10. [Method 2 ki verification](#10-method-2-ki-verification)
11. [Troubleshooting](#11-troubleshooting)
12. [Safe cleanup aur rollback](#12-safe-cleanup-aur-rollback)
13. [Command summary](#13-command-summary)
14. [Aham learning points](#14-aham-learning-points)
15. [Nginx directives aur blocks](#15-nginx-directives-aur-blocks)
16. [Request flow aur logs](#16-request-flow-aur-logs)
17. [Interview-ready jawab](#17-interview-ready-jawab)
18. [Final checklist](#18-final-checklist)

---

## 1. Lab ka maqsad

Ek Rocky Linux server par do static websites deploy karni hain:

1. Space Science
2. Frozen Yogurt Shop

Do hosting methods practice kiye jayenge:

| Method | Space Science | Frozen Yogurt |
|---|---|---|
| URL subdirectories | `http://192.168.1.154/space-science/` | `http://192.168.1.154/frozen-yogurt/` |
| Alag hostnames | `http://space.nitclasses.com/` | `http://yogurt.nitclasses.com/` |

Pehle method mein dono websites ek hi document root ke andar alag directories mein hongi. Doosre method mein har website ka apna document root aur Nginx `server` block hoga.

---

## 2. Manual Linux aur Ansible ka talluq

Manual commands se samajh aata hai ke operating system par asal mein kya changes hote hain. Ansible inhi steps ko repeatable aur automated banata hai.

| Manual command | Ansible module | Maqsad |
|---|---|---|
| `dnf install` | `dnf` | Packages install karna |
| `systemctl` | `systemd` ya `service` | Service manage karna |
| `firewall-cmd` | `firewalld` | Firewall rule manage karna |
| `mkdir`, `chmod`, `chown` | `file` | Directories, ownership aur permissions |
| `cp` | `copy` | Files deploy karna |
| `restorecon` | `command` | SELinux context apply karna |
| `curl` | `uri` | HTTP response test karna |

Manual lab complete karne ke baad isi kaam ko Ansible playbook mein convert karna zyada asaan hota hai.

---

## 3. Lab environment

| Item | Value |
|---|---|
| FQDN | `node1.nitclasses.com` |
| Short hostname | `node1` |
| IP address | `192.168.1.154` |
| Operating system | Rocky Linux 9.8 |
| Normal user | `ansibleadmin` |
| User workspace | `/home/ansibleadmin/nginx-multisite-lab` |
| Web server | Nginx |
| HTTP port | `80` |
| Existing document root | `/var/www/lawfirm.com/html` |

Environment confirm karein:

```bash
hostnamectl
hostname -s
hostname -f
cat /etc/os-release
uname -r
uname -m
```

Farq samjhein:

```text
Short hostname: node1
FQDN:           node1.nitclasses.com
Domain:         nitclasses.com
```

Changes se pehle baseline collect karein:

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

In checks se sahi server, available disk space, SELinux, firewall aur port 80 ka owner confirm hota hai.

---

## 4. Node1 se connect aur workspace tayar karna

SSH se connect karein:

```bash
ssh ansibleadmin@192.168.1.154
```

Server aur user verify karein:

```bash
hostname
whoami
```

Expected:

```text
node1.nitclasses.com
ansibleadmin
```

Normal user `ansibleadmin` ke taur par logged in rahein. Sirf system locations modify karte waqt `sudo` use karein. Is se `$HOME` `/home/ansibleadmin` hi rahega.

Lab root variable define karein:

```bash
LAB_ROOT="$HOME/nginx-multisite-lab"
export LAB_ROOT
```

Complete directory structure banayein:

```bash
mkdir -p "$LAB_ROOT/downloads"
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"
mkdir -p "$LAB_ROOT/backups"
```

Verify karein:

```bash
printf 'LAB_ROOT=%s\n' "$LAB_ROOT"
find "$LAB_ROOT" -maxdepth 2 -type d -print | sort
```

Final structure:

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

Naya shell ya nayi SSH session open karne ke baad `LAB_ROOT` variable dobara define karna hoga.

---

## 5. Nginx install aur configure karna

### 5.1 Packages install karein

```bash
sudo dnf install nginx unzip policycoreutils-python-utils -y
```

| Package | Kaam |
|---|---|
| `nginx` | Websites serve karta hai |
| `unzip` | ZIP archives extract karta hai |
| `policycoreutils-python-utils` | `semanage` command provide karta hai |

Rocky Linux 9 mein Nginx aam tor par standard repositories mein available hota hai. Sirf Nginx install karne ke liye EPEL lazmi nahi hota.

```bash
sudo dnf info nginx
```

### 5.2 Port 80 conflict check karein

```bash
sudo ss -tlnp | grep -E ':80\b' || true
sudo systemctl is-active httpd
```

Agar Apache/httpd pehle se port 80 par listen kar raha ho, to Nginx usi IP aur port ko use nahi kar sakta. Pehle decide karein ke port 80 kis service ko dena hai.

### 5.3 Nginx start aur enable karein

```bash
sudo systemctl enable --now nginx
```

- `--now` service ko foran start karta hai.
- `enable` boot ke waqt automatic start configure karta hai.

```bash
systemctl is-active nginx
systemctl is-enabled nginx
sudo nginx -t
sudo ss -tlnp | grep -E ':80\b'
```

### 5.4 Firewall mein HTTP allow karein

```bash
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
```

Yeh TCP port 80 par incoming HTTP traffic allow karta hai.

### 5.5 Baseline HTTP test

```bash
curl -I http://127.0.0.1/
curl -I http://192.168.1.154/
```

`200 OK` ka matlab web server request kaamiyabi se serve kar raha hai. `403` aaye to document root, index file, permissions aur SELinux check karein.

### 5.6 Backup banayein

```bash
mkdir -p "$LAB_ROOT/backups"
timestamp="$(date '+%Y-%m-%d-%H-%M-%S')"
```

Nginx configuration backup:

```bash
sudo tar -C /etc -czf - nginx > \
  "$LAB_ROOT/backups/nginx-config-$timestamp.tar.gz"
```

Existing website ka backup:

```bash
if [ -d /var/www/lawfirm.com ]; then
  sudo tar -C /var/www -czf - lawfirm.com > \
    "$LAB_ROOT/backups/lawfirm-webroot-$timestamp.tar.gz"
fi
```

Backup verify karein:

```bash
ls -lh "$LAB_ROOT/backups/"
tar -tzf "$LAB_ROOT/backups/nginx-config-$timestamp.tar.gz" | head -20
```

`tar -tzf` compressed archive ke contents list karta hai; files extract ya overwrite nahi karta.

---

## 6. Website templates download aur prepare karna

### 6.1 Download directory mein jayein

```bash
mkdir -p "$LAB_ROOT/downloads"
cd "$LAB_ROOT/downloads"
```

### 6.2 Templates download karein

```bash
wget -O space-science.zip \
  'https://freewebsitetemplates.com/download/space-science/'

wget -O frozen-yogurt.zip \
  'https://freewebsitetemplates.com/download/frozenyogurtshop/'
```

`wget -O filename` downloaded response ko diye gaye local filename se save karta hai.

### 6.3 Archives verify karein

```bash
ls -lh *.zip
file *.zip
unzip -t space-science.zip
unzip -t frozen-yogurt.zip
```

`file` actual file type identify karta hai. `unzip -t` extraction ke baghair ZIP integrity test karta hai.

Archive contents dekhein:

```bash
unzip -l space-science.zip | less
unzip -l frozen-yogurt.zip | less
```

`less` se bahar aane ke liye `q` press karein.

### 6.4 Archives extract karein

```bash
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"

unzip -q "$LAB_ROOT/downloads/space-science.zip" \
  -d "$LAB_ROOT/extracted/space"

unzip -q "$LAB_ROOT/downloads/frozen-yogurt.zip" \
  -d "$LAB_ROOT/extracted/yogurt"
```

- `-q`: quiet mode
- `-d`: extraction destination

### 6.5 Homepage locate karein

```bash
find "$LAB_ROOT/extracted/space" -name index.html -print
find "$LAB_ROOT/extracted/yogurt" -name index.html -print
```

Expected deployable roots:

```text
$LAB_ROOT/extracted/space/space-science/upload/
$LAB_ROOT/extracted/yogurt/frozenyogurtshop/
```

Size aur top-level contents check karein:

```bash
du -sh "$LAB_ROOT/extracted/space/space-science/upload"
du -sh "$LAB_ROOT/extracted/yogurt/frozenyogurtshop"

find "$LAB_ROOT/extracted/space/space-science/upload" \
  -maxdepth 1 -mindepth 1 -printf '%f\n' | sort

find "$LAB_ROOT/extracted/yogurt/frozenyogurtshop" \
  -maxdepth 1 -mindepth 1 -printf '%f\n' | sort
```

### 6.6 Clean prepared copies banayein

Extracted source ko directly edit na karein. Deployment ke liye clean copies banayein:

```bash
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"

cp -a "$LAB_ROOT/extracted/space/space-science/upload/." \
  "$LAB_ROOT/prepared/space-science/"

cp -a "$LAB_ROOT/extracted/yogurt/frozenyogurtshop/." \
  "$LAB_ROOT/prepared/frozen-yogurt/"
```

Runtime ke liye zaroori na hone wali Photoshop file prepared copy se remove karein:

```bash
rm -f -- \
  "$LAB_ROOT/prepared/frozen-yogurt/frozenyogurtshop.psd"
```

Verify karein:

```bash
test ! -e "$LAB_ROOT/prepared/frozen-yogurt/frozenyogurtshop.psd" \
  && echo "PASS: PSD file excluded"

ls -l "$LAB_ROOT/prepared/space-science/index.html"
ls -l "$LAB_ROOT/prepared/frozen-yogurt/index.html"
```

Source ke end par `/.` lagane se directory ke contents—including hidden entries—copy hote hain, extra nested directory nahi banti.

---

## 7. Method 1: URL subdirectories

Dono websites existing document root ke andar alag subdirectories se serve hongi.

### 7.1 Destination directories banayein

```bash
sudo mkdir -p /var/www/lawfirm.com/html/space-science
sudo mkdir -p /var/www/lawfirm.com/html/frozen-yogurt
```

### 7.2 Website files copy karein

```bash
sudo cp -a "$LAB_ROOT/prepared/space-science/." \
  /var/www/lawfirm.com/html/space-science/

sudo cp -a "$LAB_ROOT/prepared/frozen-yogurt/." \
  /var/www/lawfirm.com/html/frozen-yogurt/
```

Sirf `index.html` copy na karein. CSS, JavaScript, images aur fonts bhi required hain.

### 7.3 Layout confirm karein

```bash
ls -l /var/www/lawfirm.com/html/space-science/index.html
ls -l /var/www/lawfirm.com/html/frozen-yogurt/index.html
```

Mapping:

```text
URL:  http://192.168.1.154/space-science/
File: /var/www/lawfirm.com/html/space-science/index.html

URL:  http://192.168.1.154/frozen-yogurt/
File: /var/www/lawfirm.com/html/frozen-yogurt/index.html
```

### 7.4 Ownership aur permissions

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

Directories ko execute permission chahiye taake Nginx path traverse kar sake. Static files ko read permission chahiye.

Unexpected modes check karein:

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

Koi output na aaye to selected paths intended permissions use kar rahe hain.

### 7.5 SELinux contexts apply karein

```bash
sudo restorecon -Rv /var/www/lawfirm.com/html/space-science
sudo restorecon -Rv /var/www/lawfirm.com/html/frozen-yogurt
```

Complete path permissions dekhein:

```bash
namei -l /var/www/lawfirm.com/html/space-science/index.html
namei -l /var/www/lawfirm.com/html/frozen-yogurt/index.html
```

---

## 8. Method 1 ki verification

HTTP status test:

```bash
curl -I http://localhost/space-science/
curl -I http://localhost/frozen-yogurt/
```

Expected:

```text
HTTP/1.1 200 OK
```

Internal pages aur assets test karein:

```bash
curl -I http://localhost/space-science/about.html
curl -I http://localhost/space-science/projects.html
curl -I http://localhost/space-science/css/style.css

curl -I http://localhost/frozen-yogurt/blog.html
curl -I http://localhost/frozen-yogurt/contact.html
curl -I http://localhost/frozen-yogurt/css/style.css
```

Website title confirm karein:

```bash
curl -fsS http://localhost/space-science/ | grep -i '<title>'
curl -fsS http://localhost/frozen-yogurt/ | grep -i '<title>'
```

SELinux context:

```bash
ls -ldZ /var/www/lawfirm.com/html/space-science
ls -ldZ /var/www/lawfirm.com/html/frozen-yogurt
```

Expected type:

```text
httpd_sys_content_t
```

Linux permissions aur SELinux dono ko access allow karna hota hai. Sirf `chmod` sahi hona kafi nahi.

Browser URLs:

```text
http://192.168.1.154/space-science/
http://192.168.1.154/frozen-yogurt/
```

Logs check karein:

```bash
sudo tail -n 30 /var/log/nginx/access.log
sudo tail -n 30 /var/log/nginx/error.log
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/access.log | tail -20
```

Sirf `/favicon.ico` ka `404` aam tor par harmless hota hai. HTML, CSS, JS, image ya font ka `404` investigate karna chahiye.

---

## 9. Method 2: Alag hostnames

Is method mein dono websites same `192.168.1.154:80` use karti hain, lekin Nginx HTTP `Host` header ki bunyaad par sahi website select karta hai.

### 9.1 Separate document roots banayein

```bash
sudo mkdir -p /var/www/space/html
sudo mkdir -p /var/www/yogurt/html
```

### 9.2 Files copy karein

```bash
sudo cp -a /var/www/lawfirm.com/html/space-science/. \
  /var/www/space/html/

sudo cp -a /var/www/lawfirm.com/html/frozen-yogurt/. \
  /var/www/yogurt/html/
```

### 9.3 Ownership aur permissions

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
```

### 9.4 Persistent SELinux mappings

Custom document roots ke liye permanent file-context rules add karein:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t \
  '/var/www/space(/.*)?'

sudo semanage fcontext -a -t httpd_sys_content_t \
  '/var/www/yogurt(/.*)?'

sudo restorecon -Rv /var/www/space
sudo restorecon -Rv /var/www/yogurt
```

Agar mapping pehle se maujood ho to `-a` ki jagah `-m` use karein.

### 9.5 Space Science server block

```bash
sudo vim /etc/nginx/conf.d/space.conf
```

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

### 9.6 Frozen Yogurt server block

```bash
sudo vim /etc/nginx/conf.d/yogurt.conf
```

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

### 9.7 Configuration test aur reload

```bash
sudo nginx -t
sudo systemctl reload nginx
systemctl is-active nginx
sudo ss -tlnp | grep ':80'
```

Safe workflow:

```text
Edit → Test → Reload → Verify
```

Valid configuration ke liye `reload` workers ko gracefully replace karta hai; unnecessary stop/start ki zaroorat nahi hoti.

### 9.8 Windows hosts file

Browser chalane wale Windows computer par PowerShell **Run as Administrator** karein.

Backup:

```powershell
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupFile = "$hostsFile.backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Backup created: $backupFile"
```

Hosts file mein add karein:

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

DNS cache flush aur verification:

```powershell
ipconfig /flushdns
curl.exe -I http://space.nitclasses.com/
curl.exe -I http://yogurt.nitclasses.com/
```

Remote VM ke liye names ko `127.0.0.1` par map na karein; VM ka actual/VPN IP use karein.

---

## 10. Method 2 ki verification

Host headers locally test karein:

```bash
curl -I -H 'Host: space.nitclasses.com' http://127.0.0.1/
curl -I -H 'Host: yogurt.nitclasses.com' http://127.0.0.1/
```

Dono ko `HTTP/1.1 200 OK` return karna chahiye.

Correct content verify karein:

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

Dedicated logs:

```bash
sudo tail -n 20 /var/log/nginx/space-access.log
sudo tail -n 20 /var/log/nginx/yogurt-access.log
sudo tail -n 20 /var/log/nginx/space-error.log
sudo tail -n 20 /var/log/nginx/yogurt-error.log
```

HTTP errors search karein:

```bash
sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/space-access.log | tail -20

sudo grep -E ' (400|403|404|500|502|503|504) ' \
  /var/log/nginx/yogurt-access.log | tail -20
```

Firewall aur SELinux final check:

```bash
sudo firewall-cmd --zone=public --query-service=http
getenforce
ls -ldZ /var/www/space/html /var/www/yogurt/html
sudo semanage fcontext -l | grep -E '/var/www/(space|yogurt)'
```

---

## 11. Troubleshooting

### 11.1 `403 Forbidden`

`403` ka matlab Nginx ko request mili, lekin woh requested content serve nahi kar saka ya access allow nahi tha.

```bash
sudo tail -n 30 /var/log/nginx/error.log
ls -lZ /var/www/space/html/index.html
namei -l /var/www/space/html/index.html
```

Common causes:

- `index.html` missing hai.
- Parent directory par execute permission nahi hai.
- SELinux context ghalat hai.
- Nginx ka `root` ghalat path ko point kar raha hai.
- Directory listing allowed nahi aur index file nahi mili.

`chmod 777` solution nahi hai. Yeh unnecessary write permission deta hai aur asal ownership, traversal ya SELinux issue chhupa deta hai.

### 11.2 `404 Not Found`

`404` ka matlab requested path par resource nahi mila.

```bash
find /var/www -name index.html -print
sudo nginx -T | less
```

Path mapping samjhein:

```text
root /var/www/space/html;
request /about.html
final file /var/www/space/html/about.html
```

### 11.3 Ghalat website nazar aaye

Check karein:

- Client hosts file
- Browser cache
- Request ka `Host` header
- Nginx ke `server_name` values
- Duplicate/default server blocks

```bash
sudo nginx -T
curl -I -H 'Host: space.nitclasses.com' http://127.0.0.1/
curl -I -H 'Host: yogurt.nitclasses.com' http://127.0.0.1/
```

### 11.4 Nginx reload fail ho

```bash
sudo nginx -t
sudo journalctl -u nginx --no-pager -n 30
```

Pehle syntax/configuration error fix karein, phir reload karein. Common errors:

- Semicolon missing
- Opening/closing brace missing
- Directive ki spelling ghalat
- Invalid path
- Duplicate listener ya conflicting configuration

### 11.5 Port 80 busy ho

```bash
sudo ss -tlnp '( sport = :80 )'
sudo systemctl status nginx httpd --no-pager
```

Ek hi IP address aur port par do alag services simultaneously bind nahi kar sakti, jab tak woh intentionally alag addresses ya ports use na karein.

### 11.6 SELinux mapping pehle se ho

```bash
sudo semanage fcontext -l -C
```

Existing rule ko modify karein:

```bash
sudo semanage fcontext -m -t httpd_sys_content_t \
  '/var/www/space(/.*)?'
sudo restorecon -Rv /var/www/space
```

### 11.7 Client VM tak na pohanch sake

Server par har layer test karein:

```bash
ip -4 address
ip -4 route
sudo firewall-cmd --zone=public --query-service=http
sudo ss -tlnp | grep ':80'
curl -I http://127.0.0.1/
curl -I http://192.168.1.154/
```

Windows se:

```powershell
Test-NetConnection 192.168.1.154 -Port 80
curl.exe -I http://192.168.1.154/
```

Is tarah local Nginx issue ko firewall, routing, VPN aur name-resolution issue se alag kiya ja sakta hai.

---

## 12. Safe cleanup aur rollback

> Yeh commands lab resources permanently remove kar sakti hain. Har target path ko command chalane se pehle verify karein.

Nayi shell mein pehle variable define karein:

```bash
LAB_ROOT="$HOME/nginx-multisite-lab"
export LAB_ROOT
```

Backups check karein:

```bash
ls -lh "$LAB_ROOT/backups/"
```

Wildcard ko `tar` ke saath use karne ke bajaye exact timestamped archive select karein.

### 12.1 Targets preview karein

```bash
ls -ld /var/www/lawfirm.com/html/space-science
ls -ld /var/www/lawfirm.com/html/frozen-yogurt
ls -ld /var/www/space
ls -ld /var/www/yogurt
ls -l /etc/nginx/conf.d/space.conf
ls -l /etc/nginx/conf.d/yogurt.conf
```

### 12.2 Method 1 resources remove karein

```bash
sudo rm -rf -- /var/www/lawfirm.com/html/space-science
sudo rm -rf -- /var/www/lawfirm.com/html/frozen-yogurt
```

### 12.3 Method 2 resources remove karein

```bash
sudo rm -rf -- /var/www/space
sudo rm -rf -- /var/www/yogurt

sudo rm -f -- /etc/nginx/conf.d/space.conf
sudo rm -f -- /etc/nginx/conf.d/yogurt.conf
```

### 12.4 SELinux mappings remove karein

```bash
sudo semanage fcontext -d '/var/www/space(/.*)?'
sudo semanage fcontext -d '/var/www/yogurt(/.*)?'
```

Custom mappings check karein:

```bash
sudo semanage fcontext -l -C
```

### 12.5 Configuration validate aur reload karein

```bash
sudo nginx -t && sudo systemctl reload nginx
```

`&&` ka matlab doosri command sirf pehli command successful hone par chalegi.

### 12.6 User workspace ki working copies clean karein

Yeh commands sirf extracted aur prepared working copies remove karti hain. Downloaded archives aur backups safe rehte hain.

```bash
rm -rf -- "$LAB_ROOT/extracted"
rm -rf -- "$LAB_ROOT/prepared"
```

Lab repeat karne ke liye directories dobara banayein:

```bash
mkdir -p "$LAB_ROOT/extracted/space"
mkdir -p "$LAB_ROOT/extracted/yogurt"
mkdir -p "$LAB_ROOT/prepared/space-science"
mkdir -p "$LAB_ROOT/prepared/frozen-yogurt"
```

### 12.7 Cleanup verify karein

```bash
test ! -e /var/www/space && echo "Space document root removed"
test ! -e /var/www/yogurt && echo "Yogurt document root removed"
sudo nginx -t
```

### 12.8 Backup restore karein

Available files list karein:

```bash
ls -lh "$LAB_ROOT/backups/"
```

Selected archive inspect karein:

```bash
tar -tzf \
  "$LAB_ROOT/backups/nginx-config-YYYY-MM-DD-HH-MM-SS.tar.gz" \
  | head -20
```

`YYYY-MM-DD-HH-MM-SS` ko actual timestamp se replace karein.

Intentional rollback ke waqt restore karein:

```bash
sudo tar -C /etc -xzf \
  "$LAB_ROOT/backups/nginx-config-YYYY-MM-DD-HH-MM-SS.tar.gz"

sudo nginx -t
sudo systemctl reload nginx
systemctl is-active nginx
```

Archive restore purani files wapas lata hai, lekin backup ke baad create hui unrelated files automatically remove nahi karta.

---

## 13. Command summary

| Command | Roman Urdu mein maqsad |
|---|---|
| `ssh` | Remote server par secure login |
| `wget -O` | Download ko specified filename se save karna |
| `file` | Actual file type identify karna |
| `unzip -t` | ZIP integrity test karna |
| `unzip -l` | Extraction ke baghair contents list karna |
| `unzip -d` | Selected directory mein extract karna |
| `find` | Files/directories locate ya permissions apply karna |
| `du -sh` | Directory ka total used size dekhna |
| `cp -a` | Attributes preserve karte hue recursive copy |
| `install -d` | Ownership/mode ke saath directory banana |
| `chown` | Owner aur group change karna |
| `chmod` | Permissions change karna |
| `namei -l` | Complete path ke har component ki permissions |
| `semanage fcontext` | Persistent SELinux mapping manage karna |
| `restorecon` | SELinux labels apply karna |
| `nginx -t` | Nginx syntax aur referenced configuration test |
| `systemctl reload nginx` | Valid config ko graceful reload karna |
| `curl -I` | Sirf HTTP response headers dekhna |
| `curl -H 'Host: ...'` | Virtual host selection test karna |
| `ss -tlnp` | Listening TCP ports aur processes dekhna |
| `tail` | Log ki latest lines dekhna |
| `tar -czf` | Gzip-compressed backup banana |
| `tar -tzf` | Archive ko extract kiye baghair inspect karna |

---

## 14. Aham learning points

- User-owned lab files `/home/ansibleadmin/nginx-multisite-lab` mein rehte hain.
- Live website content standard system locations `/var/www/...` mein deploy hota hai.
- Nginx configuration `/etc/nginx/...` mein hoti hai.
- Nginx logs `/var/log/nginx/...` mein rehte hain.
- Normal user ke taur par kaam karein; system changes ke liye `sudo` use karein.
- Configuration edit ke baad hamesha `nginx -t` chalayein.
- Valid test ke baad hi Nginx reload karein.
- `chmod 777` production solution nahi hai.
- Unix permissions aur SELinux dono access control karte hain.
- Ek IP aur port par multiple websites `Host` header se select ho sakti hain.
- Cleanup se pehle backup aur exact target paths verify karein.

---

## 15. Nginx directives aur blocks

### 15.1 Directive kya hoti hai?

Directive Nginx ko di hui ek instruction hoti hai. Simple directive semicolon `;` par end hoti hai.

```nginx
listen 80;
server_name space.nitclasses.com;
root /var/www/space/html;
index index.html;
```

| Directive | Kaam |
|---|---|
| `listen` | Nginx kis IP/port par request receive kare |
| `server_name` | Kaunsa hostname is server block se match hoga |
| `root` | Website files kis directory mein hain |
| `index` | Directory request par kaunsi default file serve ho |
| `access_log` | Successful/request activity ka log path |
| `error_log` | Errors aur diagnostic messages ka log path |
| `try_files` | Request ke liye possible filesystem paths test karna |

### 15.2 Block kya hota hai?

Block curly braces `{ }` ke andar related directives ka group hota hai.

```nginx
server {
    listen 80;
    server_name space.nitclasses.com;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

- `server` block ek virtual website define karta hai.
- `location` block URL path ke liye rules define karta hai.

### 15.3 Nginx hierarchy

```text
nginx.conf
└── http block
    └── server block
        └── location block
```

Rocky Linux mein `/etc/nginx/nginx.conf` aam tor par `/etc/nginx/conf.d/*.conf` files include karta hai.

### 15.4 `try_files` samjhein

```nginx
try_files $uri $uri/ =404;
```

Nginx is order mein check karta hai:

1. `$uri` — requested path file hai?
2. `$uri/` — requested path directory hai?
3. `=404` — kuch na mile to 404 return karo.

Example:

```text
Request: /about.html
Root:    /var/www/space/html
File:    /var/www/space/html/about.html
```

---

## 16. Request flow aur logs

### 16.1 Complete request flow

1. Browser `space.nitclasses.com` request karta hai.
2. Hosts file ya DNS naam ko `192.168.1.154` mein resolve karta hai.
3. Client TCP port 80 se connect karta hai.
4. Firewall HTTP traffic allow karta hai.
5. Nginx request ka `Host` header padhta hai.
6. Matching `server_name` wala block select hota hai.
7. `root` aur URI mil kar filesystem path banate hain.
8. Unix permissions aur SELinux access allow karte hain.
9. Nginx HTTP response client ko return karta hai.
10. Request access log mein record hoti hai.

### 16.2 Access log entry

Example:

```text
127.0.0.1 - - [28/Sep/2026:19:11:51 -0500] "GET /css/style.css HTTP/1.1" 200 27373
```

| Field | Matlab |
|---|---|
| `127.0.0.1` | Client IP |
| `GET` | HTTP method |
| `/css/style.css` | Requested resource |
| `HTTP/1.1` | Protocol version |
| `200` | HTTP status code |
| `27373` | Response bytes |

### 16.3 Favicon 404

Browsers aksar automatically `/favicon.ico` request karte hain. Agar website mein favicon nahi hai to yeh request `404` return kar sakti hai. Agar baqi HTML, CSS, JavaScript, images aur fonts `200` return kar rahe hon to single favicon 404 aam tor par serious problem nahi hota.

---

## 17. Interview-ready jawab

> Main pehle server identity, disk space, SELinux, firewall aur port 80 ka owner verify karunga. Phir Nginx aur required tools install karke service enable karunga aur HTTP firewall rule add karunga. Configuration aur existing website ka timestamped backup user-owned lab workspace mein banaunga. Website archives download, verify aur extract karke clean prepared copies tayar karunga. Live files `/var/www` mein deploy karke correct ownership, directory mode `755`, file mode `644` aur SELinux `httpd_sys_content_t` context apply karunga. Har Nginx change ke baad `nginx -t` chalaunga aur successful result par service reload karunga. Aakhir mein `curl`, browser, dedicated access/error logs, firewall aur SELinux se deployment verify karunga.

---

## 18. Final checklist

- [ ] Sahi server aur `ansibleadmin` user confirm kiya
- [ ] `LAB_ROOT` define aur export kiya
- [ ] Downloads, extracted, prepared aur backups directories banayi
- [ ] Nginx packages install kiye
- [ ] Port 80 conflict check kiya
- [ ] Nginx active aur enabled hai
- [ ] Firewall mein HTTP allowed hai
- [ ] Existing configuration ka backup banaya
- [ ] ZIP archives ka type aur integrity verify ki
- [ ] Prepared copies mein `index.html`, CSS, JS, images aur fonts maujood hain
- [ ] Live document roots `/var/www` mein create kiye
- [ ] Ownership aur permissions apply ki
- [ ] SELinux mappings aur contexts apply kiye
- [ ] Nginx server blocks create kiye
- [ ] `sudo nginx -t` successful hai
- [ ] Nginx reload successful hai
- [ ] Windows hosts file mein VM IP use hua
- [ ] Dono websites `200 OK` return karti hain
- [ ] Titles se correct websites verify hui
- [ ] Access aur error logs inspect kiye
- [ ] Cleanup aur rollback procedure samajh liya

---

## Short conclusion

Is lab mein user workspace aur system paths ko alag rakha gaya hai:

```text
User work:     /home/ansibleadmin/nginx-multisite-lab
Website data:  /var/www
Nginx config:  /etc/nginx
Nginx logs:    /var/log/nginx
```

Yeh structure practice ko organized, repeatable aur safer banata hai.
