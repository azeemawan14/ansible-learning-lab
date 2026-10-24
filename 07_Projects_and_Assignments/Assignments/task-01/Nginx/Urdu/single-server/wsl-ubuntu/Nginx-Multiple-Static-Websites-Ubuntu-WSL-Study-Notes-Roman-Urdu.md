# Nginx Multiple Static Websites on Ubuntu WSL

## Mukammal Roman Urdu Study Notes

Yeh notes Ubuntu 24.04 WSL2 par Nginx 1.24.0 use karte hue do static websites deploy karne ki complete practical lab record karti hain.

Hum ne do methods practice kiye:

1. URL subdirectories ke zariye hosting
2. Alag hostnames aur Nginx server blocks ke zariye hosting

> Commands English mein bilkul same rakhi gayi hain taa-ke aap unhein seedha terminal mein chala sakein. Tamam explanations Roman Urdu mein hain.

---

## Index

1. [Lab ke objectives](#1-lab-ke-objectives)
2. [Final architecture](#2-final-architecture)
3. [Aham terminology](#3-aham-terminology)
4. [Environment aur baseline checks](#4-environment-aur-baseline-checks)
5. [Firewall configuration](#5-firewall-configuration)
6. [Website templates download karna](#6-website-templates-download-karna)
7. [Archives extract aur inspect karna](#7-archives-extract-aur-inspect-karna)
8. [Clean deployment copies tayyar karna](#8-clean-deployment-copies-tayyar-karna)
9. [Existing web root ka backup](#9-existing-web-root-ka-backup)
10. [Method 1: URL paths ke zariye hosting](#10-method-1-url-paths-ke-zariye-hosting)
11. [Method 1 verification](#11-method-1-verification)
12. [Nginx directives aur blocks](#12-nginx-directives-aur-blocks)
13. [Method 2: Alag hostnames ke zariye hosting](#13-method-2-alag-hostnames-ke-zariye-hosting)
14. [Server blocks enable aur apply karna](#14-server-blocks-enable-aur-apply-karna)
15. [curl se virtual hosts test karna](#15-curl-se-virtual-hosts-test-karna)
16. [Windows hosts file configure karna](#16-windows-hosts-file-configure-karna)
17. [Browser aur logs verification](#17-browser-aur-logs-verification)
18. [Naye commands ki tafseeli explanation](#18-naye-commands-ki-tafseeli-explanation)
19. [Troubleshooting guide](#19-troubleshooting-guide)
20. [Safe rollback aur cleanup](#20-safe-rollback-aur-cleanup)
21. [Interview-ready jawab](#21-interview-ready-jawab)
22. [Final lab results](#22-final-lab-results)

---

## 1. Lab ke objectives

Is lab ke goals yeh thay:

- Nginx service aur configuration verify karna.
- Do free static website templates download karna.
- ZIP archives ko extract karne se pehle test karna.
- Website ka asal document root identify karna.
- Unnecessary PSD source file ko deployment se exclude karna.
- Existing `/var/www/html` ka backup banana.
- Dono websites ko URL subdirectories ke zariye host karna.
- Dono websites ko alag hostnames aur server blocks ke zariye host karna.
- Ownership aur permissions ko safely configure karna.
- `server_name`, `root`, `location`, `try_files`, directives aur blocks samajhna.
- `curl`, Windows browser aur Nginx logs se deployment verify karna.
- Rollback aur troubleshooting practice karna.

Websites:

- Space Science
- Frozen Yogurt Shop

---

## 2. Final architecture

### Method 1: URL subdirectories

```text
http://localhost/space-science/
http://localhost/frozen-yogurt/
```

Document roots:

```text
/var/www/html/space-science/
/var/www/html/frozen-yogurt/
```

### Method 2: Alag hostnames

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

Document roots:

```text
/var/www/space/html/
/var/www/yogurt/html/
```

### Request ka complete flow

```text
Browser mein URL enter hota hai
  -> Windows hosts file hostname ko 127.0.0.1 par resolve karti hai
  -> Windows localhost traffic WSL tak pohanchta hai
  -> Nginx TCP port 80 par request receive karta hai
  -> Nginx HTTP Host header read karta hai
  -> server_name correct server block select karta hai
  -> root correct document directory batata hai
  -> Nginx requested static file return karta hai
```

---

## 3. Aham terminology

### Static website

Static website mein ready-made files hoti hain jinhein Nginx directly browser ko return karta hai:

- HTML
- CSS
- JavaScript
- Images
- Fonts

Har request ke liye backend application se page generate karwana zaroori nahi hota.

### Document root

Document root woh directory hai jahan website ki asal files mojood hoti hain.

```nginx
root /var/www/space/html;
```

### Server block ya virtual host

Server block ek virtual website ki configuration hoti hai. Ek hi Nginx service, IP address aur port ke zariye multiple websites serve ki ja sakti hain.

### Host header

Browser request mein hostname bhejta hai:

```http
Host: space.nitclasses.com
```

Nginx is value ko configured `server_name` ke saath compare karta hai.

### Windows hosts file

Hosts file local hostname-to-IP mapping banati hai. Yeh mapping sirf us Windows computer par kaam karti hai; yeh public DNS record nahi banati.

---

## 4. Environment aur baseline checks

### Nginx service check karein

```bash
systemctl is-active nginx
systemctl is-enabled nginx
```

Expected:

```text
active
enabled
```

Sahi command `is-enabled` hai, `is-enable` nahi.

### Nginx version check karein

```bash
nginx -v
```

Lab result:

```text
nginx version: nginx/1.24.0 (Ubuntu)
```

### Configuration syntax test karein

```bash
sudo nginx -t
```

Successful output:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

`nginx -t` configuration ko apply nahi karta. Yeh sirf syntax aur referenced files test karta hai.

### Port 80 check karein

```bash
sudo ss -tlnp | grep ':80'
```

Lab mein Nginx yahan listen kar raha tha:

```text
0.0.0.0:80
[::]:80
```

- `0.0.0.0:80`: tamam IPv4 interfaces
- `[::]:80`: tamam IPv6 interfaces

### Default site test karein

```bash
curl -I http://127.0.0.1/
```

Expected:

```text
HTTP/1.1 200 OK
```

---

## 5. Firewall configuration

Ubuntu aam tor par UFW use karta hai aur Rocky Linux aam tor par firewalld. Is WSL lab mein firewalld practice ke liye install aur use kiya gaya.

```bash
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
```

Lab output:

```text
dhcpv6-client http ssh
```

Explanation:

- `--permanent`: rule ko permanent configuration mein save karta hai.
- `--reload`: permanent changes ko running firewall par apply karta hai.
- `--zone=public`: public zone select karta hai.
- `--add-service=http`: TCP port 80 allow karta hai.

WSL networking ek normal VM se mukhtalif ho sakti hai, lekin commands firewalld practice ke liye useful hain.

---

## 6. Website templates download karna

### Lab directory banayein

```bash
mkdir -p "$HOME/nginx-multisite-lab/downloads"
cd "$HOME/nginx-multisite-lab/downloads"
```

### Templates download karein

```bash
wget -O space-science.zip \
  'https://freewebsitetemplates.com/download/space-science/'
```

```bash
wget -O frozen-yogurt.zip \
  'https://freewebsitetemplates.com/download/frozenyogurtshop/'
```

`wget -O filename` download hone wale response ko specified local filename ke saath save karta hai.

### Archives verify karein

```bash
ls -lh *.zip
file *.zip
unzip -t space-science.zip
unzip -t frozen-yogurt.zip
```

- `ls -lh`: size human-readable format mein dikhata hai.
- `file`: file ka actual type identify karta hai.
- `unzip -t`: archive ko extract kiye baghair integrity test karta hai.

---

## 7. Archives extract aur inspect karna

```bash
cd "$HOME/nginx-multisite-lab"
mkdir -p extracted/space
mkdir -p extracted/yogurt
```

```bash
unzip -q downloads/space-science.zip \
  -d extracted/space
```

```bash
unzip -q downloads/frozen-yogurt.zip \
  -d extracted/yogurt
```

- `-q`: quiet mode
- `-d`: destination directory

### Asal website roots identify karein

```bash
find extracted -type f -name index.html -print
```

Output:

```text
extracted/yogurt/frozenyogurtshop/index.html
extracted/space/space-science/upload/index.html
```

Jis directory ke andar `index.html`, CSS, images aur JavaScript hon, woh aam tor par deployable website root hoti hai.

### Directory sizes check karein

```bash
du -sh extracted/space/space-science/upload
du -sh extracted/yogurt/frozenyogurtshop
```

Output:

```text
1.9M extracted/space/space-science/upload
52M  extracted/yogurt/frozenyogurtshop
```

Yogurt template mein `frozenyogurtshop.psd` naam ki taqreeban 52 MB Photoshop source file thi. Browser ko is file ki zaroorat nahi thi, is liye ise deployment copy se exclude kiya gaya.

---

## 8. Clean deployment copies tayyar karna

```bash
mkdir -p prepared/space-science
mkdir -p prepared/frozen-yogurt
```

```bash
cp -a extracted/space/space-science/upload/. \
  prepared/space-science/
```

```bash
cp -a extracted/yogurt/frozenyogurtshop/. \
  prepared/frozen-yogurt/
```

`source/.` ka matlab source directory ke andar ka tamam content copy karna hai. Is se extra nested directory create nahi hoti.

### PSD file ko prepared copy se remove karein

```bash
rm -f -- prepared/frozen-yogurt/frozenyogurtshop.psd
```

Is command ne original extracted copy ko touch nahi kiya; sirf prepared deployment copy clean ki.

### Verify karein

```bash
ls -l prepared/space-science/index.html
ls -l prepared/frozen-yogurt/index.html
```

```bash
test ! -e prepared/frozen-yogurt/frozenyogurtshop.psd \
  && echo "PASS: PSD file excluded"
```

Top-level content list karein:

```bash
find prepared/space-science \
  -maxdepth 1 \
  -mindepth 1 \
  -printf '%f\n' |
sort
```

Isi tarah `prepared/frozen-yogurt` ko bhi inspect karein.

---

## 9. Existing web root ka backup

### Current content inspect karein

```bash
sudo find /var/www/html \
  -maxdepth 2 \
  -printf '%M %u:%g %p\n'
```

### Backup directory aur timestamped variable banayein

```bash
mkdir -p "$HOME/nginx-multisite-lab/backups"
```

```bash
backup_file="$HOME/nginx-multisite-lab/backups/var-www-html-before-deployment-$(date '+%Y-%m-%d-%H-%M-%S').tar.gz"
```

```bash
printf 'Backup destination: %s\n' "$backup_file"
```

### Backup create karein

```bash
sudo tar -C /var/www -czf - html > "$backup_file"
```

Explanation:

- `sudo tar`: protected files ko root permission ke saath read karta hai.
- `-C /var/www`: archive start karne se pehle working directory `/var/www` banata hai.
- `-c`: naya archive create karta hai.
- `-z`: gzip compression use karta hai.
- `-f -`: archive standard output par bhejta hai.
- `> "$backup_file"`: shell output ko user-owned backup file mein save karti hai.

### Backup verify karein

```bash
ls -lh "$backup_file"
tar -tzf "$backup_file" | head -20
```

Output:

```text
html/
html/index.nginx-debian.html
html/index.html
```

`tar -tzf` archive ko restore kiye baghair uske contents list karta hai:

- `-t`: contents list karein
- `-z`: gzip archive process karein
- `-f`: named archive file read karein
- `head -20`: pehli 20 lines dikhayein

---

## 10. Method 1: URL paths ke zariye hosting

### Destination directories banayein

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

`install -d` ek hi command se directory, owner, group aur permissions set karta hai.

### Website files copy karein

```bash
sudo cp -a prepared/space-science/. \
  /var/www/html/space-science/
```

```bash
sudo cp -a prepared/frozen-yogurt/. \
  /var/www/html/frozen-yogurt/
```

### Ownership set karein

```bash
sudo chown -R root:root \
  /var/www/html/space-science \
  /var/www/html/frozen-yogurt
```

Static files ke liye Nginx ko owner banana zaroori nahi. Nginx ko sirf directories traverse aur files read karne ki permission chahiye.

### Directory permissions `755`

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

### File permissions `644`

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

Permissions ka matlab:

```text
Directory 755: owner rwx, group r-x, others r-x
File      644: owner rw-, group r--, others r--
```

Directory par execute `x` permission ka matlab directory ke andar traverse ya enter karna hai.

### Structure inspect karein

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

### Entry files aur PSD exclusion verify karein

```bash
ls -l \
  /var/www/html/space-science/index.html \
  /var/www/html/frozen-yogurt/index.html
```

```bash
test ! -e /var/www/html/frozen-yogurt/frozenyogurtshop.psd \
  && echo "PASS: PSD file was not deployed"
```

### Complete path permissions check karein

```bash
namei -l /var/www/html/space-science/index.html
namei -l /var/www/html/frozen-yogurt/index.html
```

`namei -l` path ke har component ki ownership aur permissions dikhata hai. Yeh parent directory ki missing execute permission ki wajah se aane wale `403 Forbidden` ko diagnose karne mein bohat useful hai.

---

## 11. Method 1 verification

```bash
sudo nginx -t
```

Home pages:

```bash
curl -I http://127.0.0.1/space-science/
curl -I http://127.0.0.1/frozen-yogurt/
```

Dono ne return kiya:

```text
HTTP/1.1 200 OK
```

Website title check:

```bash
curl -fsS http://127.0.0.1/space-science/ |
grep -i '<title>'
```

Result:

```html
<title>Space Science Website Template</title>
```

CSS files:

```bash
curl -I http://127.0.0.1/space-science/css/style.css
curl -I http://127.0.0.1/frozen-yogurt/css/style.css
```

Internal pages:

```bash
curl -I http://127.0.0.1/space-science/about.html
curl -I http://127.0.0.1/space-science/projects.html
curl -I http://127.0.0.1/frozen-yogurt/blog.html
curl -I http://127.0.0.1/frozen-yogurt/contact.html
```

Sab ne `200 OK` return kiya.

Logs:

```bash
sudo tail -n 30 /var/log/nginx/error.log
sudo tail -n 30 /var/log/nginx/access.log
sudo grep ' 404 ' /var/log/nginx/access.log | tail -20
```

Error log empty tha. HTML, CSS, JavaScript, images aur fonts `200` return kar rahe thay. Sirf automatic `/favicon.ico` request ne `404` return kiya, jo harmless tha.

---

## 12. Nginx directives aur blocks

### Directive kya hoti hai?

Directive Nginx ko diya gaya ek instruction hota hai.

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

Semicolon `;` simple directive ko end karta hai.

Misal:

```nginx
listen 80;
```

Is ka simple matlab hai: “Nginx, port 80 par listen karo.”

### Block kya hota hai?

Block related directives ka group hota hai jo curly braces `{ }` ke andar likha jata hai.

```nginx
server {
    listen 80;
    server_name space.nitclasses.com;
}
```

Block ek configuration context banata hai. Uske andar ki settings us context mein apply hoti hain.

### Simple aur block directive

Simple directive:

```nginx
root /var/www/space/html;
```

Block directive:

```nginx
location / {
    try_files $uri $uri/ =404;
}
```

### Nginx hierarchy

```nginx
events {
    # Connection settings
}

http {
    # General HTTP settings

    server {
        # Ek virtual website

        location / {
            # URI matching rules
        }
    }
}
```

Ubuntu mein main `/etc/nginx/nginx.conf` apne `http` context ke andar `/etc/nginx/sites-enabled/*` ko include karta hai.

### Directives ki explanation

| Directive | Roman Urdu matlab |
|---|---|
| `listen 80;` | IPv4 HTTP connections port 80 par accept karo |
| `listen [::]:80;` | IPv6 HTTP connections port 80 par accept karo |
| `server_name` | Request ke hostname se server block select karo |
| `root` | Website files ki filesystem directory |
| `index` | Directory request ke liye default file |
| `access_log` | HTTP requests ka record |
| `error_log` | Website-specific errors ka record |
| `location /` | `/` se shuru hone wali tamam URIs ke rules |
| `try_files` | Possible files/directories ko order mein check karo |

### `server_name` request ko kaise select karta hai?

Browser bhejta hai:

```http
Host: space.nitclasses.com
```

Nginx compare karta hai:

```nginx
server_name space.nitclasses.com;
```

Match milne par Space Science wala `server` block select hota hai.

### `root` aur URI

```text
root: /var/www/space/html
URI:  /about.html
final filesystem path: /var/www/space/html/about.html
```

### `index index.html;`

Agar user `/` request kare, Nginx document root ke andar `index.html` dhoondta hai. Index file na ho aur directory listing disabled ho to `403 Forbidden` aa sakta hai.

### `location /`

`/` prefix tamam website paths ko match karta hai:

```text
/
/about.html
/css/style.css
/images/logo.png
```

### `try_files`

```nginx
try_files $uri $uri/ =404;
```

Nginx left se right check karta hai:

1. `$uri`: requested file exist karti hai?
2. `$uri/`: requested directory exist karti hai?
3. `=404`: dono na milen to exact `404 Not Found` return karo.

---

## 13. Method 2: Alag hostnames ke zariye hosting

### Separate document roots create karein

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

### Prepared content copy karein

```bash
sudo cp -a prepared/space-science/. \
  /var/www/space/html/
```

```bash
sudo cp -a prepared/frozen-yogurt/. \
  /var/www/yogurt/html/
```

`cp -a` ne source ownership `khalid:khalid` preserve ki, is liye baad mein owner standardize kiya gaya.

### Ownership aur permissions

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

Incorrect permissions search karein:

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

Dono commands ka no output matlab tamam selected objects expected permissions use kar rahe hain.

### Space Science server block

File:

```text
/etc/nginx/sites-available/space
```

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

Configurations safely display karein:

```bash
sudo sed -n '1,120p' /etc/nginx/sites-available/space
sudo sed -n '1,120p' /etc/nginx/sites-available/yogurt
```

`sed -n '1,120p'` file ko modify kiye baghair lines 1 se 120 tak print karta hai.

---

## 14. Server blocks enable aur apply karna

Ubuntu structure:

```text
/etc/nginx/sites-available/ -> configurations jo mojood hain
/etc/nginx/sites-enabled/   -> configurations jo Nginx actively load karta hai
```

### Symbolic links banayein

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

Symbolic link doosri file ka reference ya shortcut hota hai. Asal configuration `sites-available` mein rehti hai aur `sites-enabled` ka link use active banata hai.

### Syntax test karein

```bash
sudo nginx -t
```

Successful output:

```text
syntax is ok
test is successful
```

### Nginx reload karein

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

| Command | Matlab |
|---|---|
| `nginx -t` | Configuration ko apply kiye baghair test karta hai |
| `systemctl reload nginx` | Service completely stop kiye baghair valid changes load karta hai |
| `systemctl restart nginx` | Service ko stop karke dobara start karta hai |

---

## 15. curl se virtual hosts test karna

Windows hosts file change karne se pehle custom Host header ke saath test kiya gaya.

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

Correct content verify karein:

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

Options:

| Option | Matlab |
|---|---|
| `-I` | HEAD request bhej kar sirf headers dikhata hai |
| `-H` | Custom HTTP header add ya replace karta hai |
| `-f` | HTTP error status par command fail karta hai |
| `-s` | Progress meter hide karta hai |
| `-S` | Silent mode ke bawajood errors dikhata hai |

Connection `127.0.0.1:80` par gayi, lekin Host header ne Nginx ko bataya ke kaunsa server block use karna hai.

---

## 16. Windows hosts file configure karna

Yeh commands Administrator PowerShell mein chalayi gayi.

### Hosts file path variable

```powershell
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
```

### Timestamped backup

```powershell
$backupFile = "$hostsFile.backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Backup created: $backupFile"
```

Lab backup:

```text
C:\Windows\System32\drivers\etc\hosts.backup-2026-09-28-19-08-52
```

### Existing entries search karein

```powershell
Select-String -Path $hostsFile \
  -Pattern 'space\.nitclasses\.com|yogurt\.nitclasses\.com'
```

No output ka matlab entries pehle se mojood nahi thin.

### Mappings add karein

```powershell
Add-Content -Path $hostsFile -Encoding ascii \
  -Value "`r`n127.0.0.1 space.nitclasses.com"
```

```powershell
Add-Content -Path $hostsFile -Encoding ascii \
  -Value "127.0.0.1 yogurt.nitclasses.com"
```

Final entries:

```text
127.0.0.1 space.nitclasses.com
127.0.0.1 yogurt.nitclasses.com
```

Yeh mappings sirf local Windows laptop ke liye hain. In se public DNS record create nahi hota.

### Entries verify aur cache flush karein

```powershell
Get-Content $hostsFile |
    Select-String 'space\.nitclasses\.com|yogurt\.nitclasses\.com'
```

```powershell
ipconfig /flushdns
```

Expected:

```text
Successfully flushed the DNS Resolver Cache.
```

### Windows se test karein

```powershell
curl.exe -I http://space.nitclasses.com/
curl.exe -I http://yogurt.nitclasses.com/
```

Dono ne `HTTP/1.1 200 OK` return kiya.

Browser URLs:

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

Browser ne `Not secure` is liye dikhaya kyun ke lab plain HTTP use kar rahi thi. HTTPS ke liye port 443 aur trusted TLS certificate chahiye. Yeh Nginx error nahi tha.

---

## 17. Browser aur logs verification

Dono websites browser mein sahi render hui. HTML, CSS, JavaScript, images, fonts aur navigation load hue.

### Separate access logs

```bash
sudo tail -n 20 /var/log/nginx/space-access.log
sudo tail -n 20 /var/log/nginx/yogurt-access.log
```

Space access log mein successful requests nazar aayi:

- `/`
- `/css/style.css`
- `/css/mobile.css`
- `/js/mobile.js`
- Images
- Web fonts

Required assets ne `200` return kiya.

### Error logs

```bash
sudo tail -n 20 /var/log/nginx/space-error.log
sudo tail -n 20 /var/log/nginx/yogurt-error.log
```

Empty output achha result hai: koi website-specific Nginx error record nahi hua.

### Important HTTP errors search karein

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

Sirf yeh optional browser request fail hui:

```text
GET /favicon.ico -> 404
```

Browser tab icon ke liye automatically `/favicon.ico` request karta hai. Template ne web root par yeh file provide nahi ki. Website functionality par koi asar nahi hua.

### Access log line samjhein

```text
127.0.0.1 ... "GET /css/style.css HTTP/1.1" 200 27373 ...
```

| Field | Matlab |
|---|---|
| `127.0.0.1` | Nginx ko nazar aane wala client address |
| `GET` | Complete resource request ki gayi |
| `/css/style.css` | Requested URI |
| `HTTP/1.1` | Protocol version |
| `200` | Request successful |
| `27373` | Response body ka size bytes mein |

`curl -I` HEAD request bhejta hai. Access log mein successful HEAD response ka body size `0` ho sakta hai kyun ke sirf headers return hote hain.

---

## 18. Naye commands ki tafseeli explanation

### `find` mein parentheses escape karna

```bash
find "$HOME" /mnt/c/Users \
  -type f \
  \( -iname '*space*.zip' -o -iname '*frozen*.zip' -o -iname '*yogurt*.zip' \) \
  2>/dev/null
```

Parentheses ko `\(` aur `\)` likhna zaroori hai taa-ke Bash unhein khud interpret na kare aur `find` command ko pass kar de. Unescaped `(` Bash syntax error deta hai.

### `cp -a source/. destination/`

- `cp`: copy
- `-a`: archive mode; structure, timestamps aur permissions preserve karta hai
- `source/.`: source ke andar ka tamam content, hidden entries samait
- `destination/`: target directory

### `find ... -exec chmod ... {} +`

```bash
find /var/www/space -type d -exec chmod 755 {} +
```

- `-type d`: sirf directories select karein
- `-exec`: results par command chalayein
- `{}`: matched paths ka placeholder
- `+`: multiple paths ek saath `chmod` ko pass karein

### `find -printf`

```bash
find PATH -printf '%M %u:%g %p\n'
```

- `%M`: symbolic permissions
- `%u`: owner
- `%g`: group
- `%p`: complete path
- `\n`: new line

### `test ! -e`

```bash
test ! -e FILE && echo "PASS"
```

- `-e`: path exist karta hai
- `!`: condition ko reverse karta hai
- `&&`: pehli condition successful ho to next command chalata hai

Is liye message tab print hota hai jab file exist nahi karti.

### `namei -l`

Path ke har component ki ownership aur permissions dikhata hai. `403 Forbidden` troubleshooting ke liye useful hai.

### `curl -I`

HEAD request bhejta hai. Status aur headers verify hote hain lekin response body download nahi hoti.

### Pipe `|`

Left command ka standard output right command ke standard input mein bhejta hai:

```bash
curl -fsS URL | grep -i '<title>'
```

### `echo $?`

Sab se recent command ka exit status dikhata hai:

- `0`: success
- Nonzero: failure ya command-specific condition

### Accidental `[200~`

Kabhi paste karte waqt command ke start mein yeh aa sakta hai:

```text
[200~sudo grep ...
```

`[200~` terminal bracketed-paste control sequence se related artifact hai; asal command ka hissa nahi. `Ctrl+C` se malformed command safely cancel karke correct command dobara chalayi gayi.

---

## 19. Troubleshooting guide

### `nginx -t` fail ho

```bash
sudo nginx -t
```

Reported filename aur line number check karein. Common reasons:

- Semicolon missing
- Brace missing ya extra
- Directive spelling incorrect
- Duplicate/conflicting configuration
- Invalid path

Jab tak test successful na ho, reload na karein.

### `403 Forbidden`

```bash
namei -l /var/www/space/html/index.html
ls -l /var/www/space/html/index.html
sudo tail -n 50 /var/log/nginx/space-error.log
```

Possible causes:

- `index.html` missing
- Parent directory par execute/traverse permission nahi
- File readable nahi
- `root` path galat
- Directory request hai lekin index file nahi
- RHEL-family systems par SELinux restriction

`chmod 777` na lagayein. Yeh unnecessary write access deta hai aur asal problem ko hide kar sakta hai.

### `404 Not Found`

`root` aur URI ko combine karke final path samjhein:

```text
root /var/www/space/html;
request /about.html
final path /var/www/space/html/about.html
```

```bash
ls -l /var/www/space/html/about.html
```

### Wrong website open ho

```bash
curl -I -H 'Host: space.nitclasses.com' http://127.0.0.1/
sudo nginx -T | grep -n 'server_name'
```

Windows hosts file entries aur request Host header verify karein.

### Port 80 busy ho

```bash
sudo ss -tlnp | grep ':80'
```

Ek hi IP aur port combination ko aam tor par ek process bind kar sakta hai. Apache/httpd ya doosri conflicting service ko stop ya reconfigure karein.

### Browser `Not secure` dikhaye

Website HTTP use kar rahi hai. HTTPS ke liye TLS configuration aur requested hostname ke liye trusted certificate chahiye.

### Favicon `404`

Yeh harmless hai. Agar tab icon chahiye to suitable favicon file web root mein rakhein aur HTML mein reference add karein.

### Windows hostname resolve na ho

```powershell
Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" |
  Select-String 'nitclasses'
```

```powershell
ipconfig /flushdns
curl.exe -I http://space.nitclasses.com/
```

Hosts file modify karne ke liye PowerShell Administrator mode mein kholna zaroori hai.

---

## 20. Safe rollback aur cleanup

Cleanup sirf tab karein jab lab ki zaroorat na rahe.

### Method 2 sites disable karein

Sirf symbolic links remove karein; source configurations preserved rahengi:

```bash
sudo unlink /etc/nginx/sites-enabled/space
sudo unlink /etc/nginx/sites-enabled/yogurt
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Windows hosts entries remove karein

Administrator mode mein file open karein:

```text
C:\Windows\System32\drivers\etc\hosts
```

Sirf yeh entries remove karein:

```text
127.0.0.1 space.nitclasses.com
127.0.0.1 yogurt.nitclasses.com
```

Phir:

```powershell
ipconfig /flushdns
```

Timestamped hosts backup restore karne se pehle confirm karein ke backup banne ke baad ki unrelated changes overwrite nahi hongi.

### Website targets pehle inspect karein

```bash
sudo find /var/www/space /var/www/yogurt -maxdepth 2 -print
```

Deletion se pehle exact paths confirm karna zaroori hai. Broad ya unresolved path ke saath destructive command na chalayein.

### Method 1 backup restore karna

Pehle archive inspect karein:

```bash
tar -tzf "$backup_file" | head -20
```

Jab rollback waqai intended ho tab exact verified archive restore karein:

```bash
sudo tar -C /var/www -xzf "$backup_file"
```

Restore ke baad:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -I http://127.0.0.1/
```

Important: archive extract karna archived files restore karta hai, lekin backup ke baad create hui extra files automatically delete nahi karta. Complete reset ko carefully plan karein.

---

## 21. Interview-ready jawab

> Main ne ek Ubuntu Nginx server par do static websites ko do methods se deploy kiya: URL-path hosting aur hostname-based virtual hosting. Sab se pehle main ne Nginx service, port 80 aur configuration verify ki. Phir ZIP archives ki integrity test ki, correct website roots identify kiye, unnecessary PSD asset ko prepared copy se remove kiya aur existing web root ka backup banaya. Deployment ke liye main ne ownership `root:root`, directory permissions `755` aur file permissions `644` set ki. Hostname routing ke liye separate server blocks banaye jin mein unique `server_name`, `root`, access log aur error log configure kiye. Configurations ko symbolic links ke zariye enable kiya, `nginx -t` se test kiya aur service reload ki. Main ne custom Host headers, Windows hosts-file mappings, browser rendering aur separate Nginx logs se verification ki. Tamam required resources ne `200 OK` return kiya; sirf optional favicon request ne harmless `404` return kiya.

---

## 22. Final lab results

| Check | Result |
|---|---|
| Nginx active aur enabled | PASS |
| Nginx syntax test | PASS |
| ZIP archives valid | PASS |
| Correct document roots identify hue | PASS |
| PSD file deployment se exclude hui | PASS |
| Existing `/var/www/html` backup bana | PASS |
| Ownership aur directory permissions | PASS |
| File permissions | PASS |
| Method 1 Space Science | PASS |
| Method 1 Frozen Yogurt | PASS |
| Space server block | PASS |
| Yogurt server block | PASS |
| Host-header routing | PASS |
| Windows hosts-file routing | PASS |
| Browser rendering aur assets | PASS |
| Separate access logs | PASS |
| Website-specific error logs | Clean |
| Optional `/favicon.ico` | Harmless 404 |

Is lab ne successfully demonstrate kiya ke ek hi Nginx service, IP address aur port par multiple static websites ko URL paths aur separate hostnames dono ke zariye host kiya ja sakta hai.

