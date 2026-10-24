# Solution: Ansible aur Nginx se Do Static Websites Deploy Karna

## Fehrist (Table of Contents)

1. [Solution ka Khulasa](#1-solution-ka-khulasa)
2. [Project Tayar Karein](#2-project-tayar-karein)
3. [Template Sources Tayar Karein](#3-template-sources-tayar-karein)
4. [Prechecks](#4-prechecks)
5. [Method 1: URL Subdirectories](#5-method-1-url-subdirectories)
6. [Method 1 ki Verification](#6-method-1-ki-verification)
7. [Method 2: Separate Hostnames](#7-method-2-separate-hostnames)
8. [Method 2 ki Verification](#8-method-2-ki-verification)
9. [Idempotency](#9-idempotency)
10. [Troubleshooting](#10-troubleshooting)
11. [Safe Cleanup](#11-safe-cleanup)
12. [Aham Learning Points](#12-aham-learning-points)

---

## 1. Solution ka Khulasa

Inhi do templates ko do mukhtalif tareeqon se deploy kiya jayega:

| Method | Space Science | Frozen Yogurt Shop |
|---|---|---|
| URL paths | `http://192.168.1.154/space-science/` | `http://192.168.1.154/frozen-yogurt/` |
| Hostnames | `http://space.nitclasses.com/` | `http://yogurt.nitclasses.com/` |

Tamam commands pehle `node1` par pilot karein. `node1` ko `three_tier_app` se sirf tab replace karein jab pilot successful ho aur required Nginx configuration tamam target nodes par consistent ho.

---

## 2. Project Tayar Karein

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

## 3. Template Sources Tayar Karein

### Step 1: Dono ZIP files download karein

Official site se yeh templates download karein:

- Space Science Template
- Frozen Yogurt Shop Template

```text
https://freewebsitetemplates.com/
```

Downloaded ZIP files ko yahan rakhein:

```text
/home/ansibleadmin/automation/downloads/
```

Samajhne mein asani ke liye unke naam yeh rakh dein:

```text
space-science.zip
frozen-yogurt.zip
```

### Step 2: File types confirm karein

```bash
file downloads/space-science.zip
file downloads/frozen-yogurt.zip
```

Dono outputs mein ZIP archive data report hona chahiye.

### Step 3: Archives inspect karein

```bash
unzip -l downloads/space-science.zip | less
unzip -l downloads/frozen-yogurt.zip | less
```

### Step 4: Archives ko locally extract karein

```bash
mkdir -p downloads/space-extracted
mkdir -p downloads/yogurt-extracted

unzip downloads/space-science.zip -d downloads/space-extracted
unzip downloads/frozen-yogurt.zip -d downloads/yogurt-extracted
```

### Step 5: Index files locate karein

```bash
find downloads/space-extracted -name index.html -print
find downloads/yogurt-extracted -name index.html -print
```

Space Science archive ki deployable directory aam tor par is jaisi hoti hai:

```text
downloads/space-extracted/space-science/upload/
```

Frozen Yogurt Shop archive ka layout mukhtalif ho sakta hai. Woh directory use karein jisme deployable `index.html`, CSS, images aur JavaScript maujood hon.

### Step 6: Clean local website sources banayein

Space Science example:

```bash
cp -a downloads/space-extracted/space-science/upload/. \
files/sites/space-science/
```

Frozen Yogurt Shop ke liye `<FROZEN_YOGURT_SITE_DIRECTORY>` ko us directory se replace karein jisme deployable `index.html` hai:

```bash
cp -a <FROZEN_YOGURT_SITE_DIRECTORY>/. \
files/sites/frozen-yogurt/
```

Verify karein:

```bash
test -f files/sites/space-science/index.html && echo "Space source ready"
test -f files/sites/frozen-yogurt/index.html && echo "Frozen Yogurt source ready"

find files/sites/space-science -maxdepth 2 -type f | head
find files/sites/frozen-yogurt -maxdepth 2 -type f | head
```

---

## 4. Prechecks

### Ansible configuration aur inventory check karein

```bash
ansible --version
ansible-config dump --only-changed
ansible node1 --list-hosts
ansible node1 -m ping
```

### Active Nginx document root confirm karein

Agar Nginx pehle se installed hai:

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

Yeh solution existing lab root use karta hai:

```text
/var/www/lawfirm.com/html
```

---

## 5. Method 1: URL Subdirectories

### Step 1: Nginx install karein

```bash
ansible node1 -b -m dnf -a "name=nginx state=present"
```

### Step 2: Nginx start aur enable karein

```bash
ansible node1 -b -m service -a \
"name=nginx state=started enabled=yes"
```

### Step 3: Firewalld mein HTTP allow karein

```bash
ansible node1 -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=enabled"
```

### Step 4: Dono website directories create karein

```bash
ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/space-science state=directory owner=root group=root mode=0755"

ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt state=directory owner=root group=root mode=0755"
```

### Step 5: Control node se Space Science copy karein

```bash
ansible node1 -b -m copy -a \
"src=files/sites/space-science/ dest=/var/www/lawfirm.com/html/space-science/ owner=root group=root mode=preserve"
```

### Step 6: Control node se Frozen Yogurt Shop copy karein

```bash
ansible node1 -b -m copy -a \
"src=files/sites/frozen-yogurt/ dest=/var/www/lawfirm.com/html/frozen-yogurt/ owner=root group=root mode=preserve"
```

`remote_src` use nahi hua, is liye yeh source paths Ansible control node se read honge.

### Step 7: SELinux contexts restore karein

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

## 6. Method 1 ki Verification

### Files verify karein

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/space-science/index.html"

ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt/index.html"
```

### SELinux contexts verify karein

```bash
ansible node1 -m command -a \
"ls -Zd /var/www/lawfirm.com/html/space-science"

ansible node1 -m command -a \
"ls -Zd /var/www/lawfirm.com/html/frozen-yogurt"
```

Output mein `httpd_sys_content_t` dekhein.

### HTTP status verify karein

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

### Step 1: Separate document roots create karein

```bash
ansible node1 -b -m file -a \
"path=/var/www/space/html state=directory owner=root group=root mode=0755"

ansible node1 -b -m file -a \
"path=/var/www/yogurt/html state=directory owner=root group=root mode=0755"
```

### Step 2: Har website deploy karein

```bash
ansible node1 -b -m copy -a \
"src=files/sites/space-science/ dest=/var/www/space/html/ owner=root group=root mode=preserve"

ansible node1 -b -m copy -a \
"src=files/sites/frozen-yogurt/ dest=/var/www/yogurt/html/ owner=root group=root mode=preserve"
```

### Step 3: SELinux contexts restore karein

```bash
ansible node1 -b -m command -a "restorecon -Rv /var/www/space"
ansible node1 -b -m command -a "restorecon -Rv /var/www/yogurt"
```

Agar custom paths ko `httpd_sys_content_t` inherit na ho to persistent mappings define karein:

```bash
ansible node1 -b -m command -a \
"semanage fcontext -a -t httpd_sys_content_t '/var/www/space(/.*)?'"

ansible node1 -b -m command -a \
"semanage fcontext -a -t httpd_sys_content_t '/var/www/yogurt(/.*)?'"

ansible node1 -b -m command -a "restorecon -Rv /var/www/space"
ansible node1 -b -m command -a "restorecon -Rv /var/www/yogurt"
```

Agar `semanage` available na ho to uska provider install karein:

```bash
ansible node1 -b -m dnf -a "name=policycoreutils-python-utils state=present"
```

### Step 4: Space Science server block locally banayein

`files/nginx/space.conf` create karein:

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

### Step 5: Frozen Yogurt Shop server block locally banayein

`files/nginx/yogurt.conf` create karein:

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

### Step 6: Dono server blocks copy karein

```bash
ansible node1 -b -m copy -a \
"src=files/nginx/space.conf dest=/etc/nginx/conf.d/space.conf owner=root group=root mode=0644 backup=yes"

ansible node1 -b -m copy -a \
"src=files/nginx/yogurt.conf dest=/etc/nginx/conf.d/yogurt.conf owner=root group=root mode=0644 backup=yes"
```

### Step 7: Nginx configuration validate karein

```bash
ansible node1 -b -m command -a "nginx -t"
```

Agar validation fail ho to Nginx reload na karein.

### Step 8: Nginx reload karein

```bash
ansible node1 -b -m service -a "name=nginx state=reloaded"
```

### Step 9: Client-side hostname resolution configure karein

Jis computer par web browser chal raha hai, uski hosts file mein yeh entries add karein:

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

Windows hosts file:

```text
C:\Windows\System32\drivers\etc\hosts
```

Linux ya WSL hosts file:

```text
/etc/hosts
```

---

## 8. Method 2 ki Verification

### Nginx configuration verify karein

```bash
ansible node1 -b -m command -a "nginx -t"
```

### HTTP Host header ke zariye dono sites verify karein

```bash
ansible node1 -m shell -a \
"curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: space.nitclasses.com' http://127.0.0.1/"

ansible node1 -m shell -a \
"curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: yogurt.nitclasses.com' http://127.0.0.1/"
```

Har site ka expected result:

```text
200
```

### Browser tests

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

### Same IP se do sites kyun serve hoti hain

Browser HTTP `Host` header send karta hai:

```text
Host: space.nitclasses.com
```

ya:

```text
Host: yogurt.nitclasses.com
```

Nginx is value ko har `server_name` ke saath compare karta hai aur matching server block select karta hai.

---

## 9. Idempotency

Deployment commands ko dobara run karein.

Expected behavior:

| Operation | Doosri run par expectation |
|---|---|
| `dnf state=present` | `changed=false` |
| `service state=started enabled=yes` | `changed=false` |
| `firewalld state=enabled` | `changed=false` |
| `file state=directory` | `changed=false` |
| Website content ka `copy` | Files same hon to `changed=false` |
| Server blocks ka `copy` | Configuration same ho to `changed=false` |
| `stat` aur `uri` | Sirf verification |
| `command` | Sirf execute hone ki wajah se `CHANGED` report kar sakta hai |

`service state=reloaded` har dafa Nginx reload karta hai. Playbook mein handlers use karein taa-ke Nginx sirf configuration file change hone par reload ho.

---

## 10. Troubleshooting

### `403 Forbidden`

```bash
ansible node1 -b -m command -a "tail -n 30 /var/log/nginx/error.log"
ansible node1 -m command -a "ls -lZ /var/www/space/html/index.html"
ansible node1 -m command -a "namei -l /var/www/space/html/index.html"
```

Missing index file, directory traversal permissions aur SELinux context check karein.

### `404 Not Found`

Confirm karein ke URL us directory se correspond karta hai jisme `index.html` maujood hai.

### Ghalat website nazar aaye

Yeh cheezein check karein:

- client hostname resolution;
- browser cache;
- request ka `Host` header;
- Nginx `server_name` values;
- duplicate ya default server blocks.

```bash
ansible node1 -b -m command -a "nginx -T"
```

### Nginx reload fail ho

```bash
ansible node1 -b -m command -a "nginx -t"
ansible node1 -b -m command -a "journalctl -u nginx --no-pager -n 30"
```

---

## 11. Safe Cleanup

Pilot cleanup ke liye `node1` use karein. `three_tier_app` sirf us waqt use karein jab deployment tamam managed nodes par ki gayi ho.

### Method 1 websites remove karein

```bash
ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/space-science state=absent"

ansible node1 -b -m file -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt state=absent"
```

### Method 2 document roots remove karein

```bash
ansible node1 -b -m file -a "path=/var/www/space state=absent"
ansible node1 -b -m file -a "path=/var/www/yogurt state=absent"
```

### Dono server blocks remove karein

```bash
ansible node1 -b -m file -a \
"path=/etc/nginx/conf.d/space.conf state=absent"

ansible node1 -b -m file -a \
"path=/etc/nginx/conf.d/yogurt.conf state=absent"
```

### Baqi configuration validate aur reload karein

```bash
ansible node1 -b -m command -a "nginx -t"
ansible node1 -b -m service -a "name=nginx state=reloaded"
```

### Cleanup verify karein

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/space-science"

ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/frozen-yogurt"

ansible node1 -m stat -a "path=/var/www/space"
ansible node1 -m stat -a "path=/var/www/yogurt"
```

Har removed path ko yeh report karna chahiye:

```text
exists: false
```

---

## 12. Aham Learning Points

1. Ek Nginx server multiple static websites host kar sakta hai.
2. URL paths document root ke neeche subdirectories se map hote hain.
3. Named virtual hosts ek IP aur port share karte hain lekin mukhtalif `Host` headers use karte hain.
4. Deployment se pehle clean website sources tayar karein.
5. Jab source control node par ho to `copy` ko `remote_src` ke baghair use karein.
6. Reload se pehle Nginx configuration validate karein.
7. SELinux enabled rakhein aur web-readable contexts assign karein.
8. Wasee deployment se pehle ek node par pilot karein.
9. Dobara chalaye gaye state-management commands idempotent hone chahiye.
10. Cleanup mein sirf lab ke banaye hue resources remove hone chahiye.
