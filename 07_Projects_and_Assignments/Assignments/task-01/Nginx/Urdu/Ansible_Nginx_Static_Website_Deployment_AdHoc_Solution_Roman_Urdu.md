# Ansible Ad-Hoc Lab: Nginx par Static Website Deploy Karein — Roman Urdu

Yeh File B ka structured Roman Urdu version hai. Is mein wohi commands use ki gayi hain jo Rocky Linux lab mein successfully kaam kar chuki hain. Pehle `node1` par pilot test karein, phir `three_tier_app` group par deploy karein.

## Fehrist

1. [Lab Environment](#1-lab-environment)
2. [Active Document Root](#2-active-document-root)
3. [Prechecks](#3-prechecks)
4. [Nginx Install Aur Start Karein](#4-nginx-install-aur-start-karein)
5. [403 Forbidden Diagnose Karein](#5-403-forbidden-diagnose-karein)
6. [Website Archive Inspect Karein](#6-website-archive-inspect-karein)
7. [Website Deploy Karein](#7-website-deploy-karein)
8. [Deployment Verify Karein](#8-deployment-verify-karein)
9. [Root URL Aur space-science URL](#9-root-url-aur-space-science-url)
10. [Teenon Nodes Par Deploy Karein](#10-teenon-nodes-par-deploy-karein)
11. [Idempotency](#11-idempotency)
12. [Troubleshooting](#12-troubleshooting)
13. [Cleanup](#13-cleanup)
14. [Ahm Learning Points](#14-ahm-learning-points)

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

Project directory mein jayein:

```bash
cd /home/ansibleadmin/automation
```

---

## 2. Active Document Root

Rocky Linux mein Nginx ka default document root aam tor par yeh hota hai:

```text
/usr/share/nginx/html
```

Lekin is lab ka active `lawfirm.com` server block yeh root use karta hai:

```text
/var/www/lawfirm.com/html
```

Active Nginx configuration ko priority milti hai. Is liye website ko `/var/www/lawfirm.com/html` mein deploy karna hai.

Configured document roots check karein:

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

---

## 3. Prechecks

### Step 1: Active Ansible configuration check karein

```bash
ansible --version
ansible-config dump --only-changed
```

Confirm karein ke Ansible expected `ansible.cfg` aur inventory use kar raha hai.

### Step 2: Inventory inspect karein

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

### Step 3: Connectivity test karein

```bash
ansible three_tier_app -m ping
```

Har host se `SUCCESS` aur `pong` milna chahiye.

---

## 4. Nginx Install Aur Start Karein

### Step 1: Nginx aur unzip install karein

```bash
ansible node1 -b -m dnf -a "name=nginx,unzip state=present"
```

`state=present` missing package install karta hai aur already installed package ko dobara install nahi karta.

### Step 2: Nginx start aur enable karein

```bash
ansible node1 -b -m service -a \
"name=nginx state=started enabled=yes"
```

- `state=started`: Nginx abhi running ho.
- `enabled=yes`: reboot ke baad automatically start ho.

### Step 3: Current service state verify karein

```bash
ansible node1 -m command -a "systemctl is-active nginx"
```

Expected result:

```text
active
```

### Step 4: Firewall mein HTTP allow karein

```bash
ansible node1 -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=enabled"
```

Agar `changed=false` aaye to HTTP rule pehle se enabled tha. Yeh sahi idempotent behavior hai.

### Step 5: Active website root test karein

```bash
ansible node1 -m uri -a "url=http://localhost status_code=200"
```

Is lab mein pehle test par `403 Forbidden` mila kyun ke active document root khaali tha aur us mein `index.html` nahi thi.

[index.html explanation](md/Nginx_Index_HTML_Home_Page_Study_Notes_Roman_Urdu.md)

---

## 5. 403 Forbidden Diagnose Karein

### Step 1: Standard Nginx directory inspect karein

```bash
ansible node1 -b -m command -a "ls -laZ /usr/share/nginx/html"
```

Yeh Rocky Linux ki standard directory thi, lekin `lawfirm.com` ki active root nahi thi.

### Step 2: Nginx error log dekhein

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"
```

Important error:

```text
directory index of "/var/www/lawfirm.com/html/" is forbidden
```

Is error se active document root maloom hua.

### Step 3: Active document root inspect karein

```bash
ansible node1 -b -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

### Step 4: Temporary test page banayein

```bash
ansible node1 -b -m copy -a \
'content="<h1>Welcome to lawfirm.com</h1>\n<p>Deployed using Ansible.</p>\n" dest=/var/www/lawfirm.com/html/index.html owner=root group=root mode=0644'
```

### Step 5: SELinux context restore karein

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

### Step 6: Temporary page test karein

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200 return_content=yes"
```

[URI explanation](md/Ansible_URI_Status_Code_Study_Notes_Roman_Urdu.md)

Status `200` prove karta hai ke Nginx, document root, permissions aur SELinux access sahi hain.

---

## 6. Website Archive Inspect Karein

### Step 1: Template download karein

```bash
ansible node1 -m get_url -a \
"url=https://freewebsitetemplates.com/download/space-science/ dest=/tmp/space-science.zip mode=0644"
```

### Step 2: Archive ka existence check karein

```bash
ansible node1 -m stat -a "path=/tmp/space-science.zip"
```

Result mein `exists: true` aur `mimetype: application/zip` dekhna chahiye.

### Step 3: File type check karein

```bash
ansible node1 -m command -a "file /tmp/space-science.zip"
```

Output `Zip archive data` hona chahiye, `HTML document` nahi.

### Step 4: Archive layout inspect karein

```bash
ansible node1 -m command -a \
"unzip -l /tmp/space-science.zip"
```

Asal website yahan hai:

```text
space-science/upload/
```

Main page:

```text
space-science/upload/index.html
```

Archive ke license aur design-source folders ko Nginx document root mein deploy karne ki zaroorat nahi.

---

## 7. Website Deploy Karein

### Step 1: Temporary extraction directory banayein

```bash
ansible node1 -b -m file -a \
"path=/tmp/space-science-extracted state=directory mode=0755"
```

### Step 2: Archive extract karein

```bash
ansible node1 -b -m unarchive -a \
"src=/tmp/space-science.zip dest=/tmp/space-science-extracted remote_src=yes creates=/tmp/space-science-extracted/space-science/upload/index.html"
```

- `remote_src=yes`: archive managed node par pehle se maujood hai.
- `creates=`: expected file ho to extraction dobara nahi hogi.

### Step 3: Sirf website contents copy karein

```bash
ansible node1 -b -m copy -a \
"src=/tmp/space-science-extracted/space-science/upload/ dest=/var/www/lawfirm.com/html/ remote_src=yes owner=root group=root mode=preserve"
```

`upload/` ke aakhir ka trailing slash us directory ke **contents** copy karta hai, `upload` directory khud nahi.

### Step 4: SELinux contexts restore karein

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```
[restorecon explanation](md/Ansible_Restorecon_AdHoc_Command_Study_Notes_Roman_Urdu.md)


### Step 5: Deployed index verify karein

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/index.html"

ansible node1 -b -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

---

## 8. Deployment Verify Karein

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200"
```

Successful response mein `status: 200`, `server: nginx/1.20.1` aur `changed: false` milta hai.

Browser mein kholein:

```text
http://192.168.1.154/
```

Mazeed checks:

```bash
ansible node1 -m command -a "systemctl is-active nginx"
ansible node1 -m shell -a "ss -tln | grep ':80 '"
ansible node1 -m uri -a "url=http://localhost status_code=200"
```

Browser ka **Not secure** message expected hai kyun ke yeh lab HTTP use karti hai, HTTPS nahi.

---

## 9. Root URL Aur space-science URL

Website ki browser URL aur filesystem directory ko ek doosre se match karna zaroori hai.

### Option A: Root URL — current aur recommended deployment

Website files seedha yahan copy hui hain:

```text
/var/www/lawfirm.com/html/
```

Is liye sahi URL hai:

```text
http://192.168.1.154/
             ↓
/var/www/lawfirm.com/html/index.html
```

Agar aap yeh URL kholein:

```text
http://192.168.1.154/space-science/
```

to Nginx yeh directory search karega:

```text
/var/www/lawfirm.com/html/space-science/
```

Current deployment mein yeh directory maujood nahi, is liye `404 Not Found` milta hai.

### Option B: Website ko `/space-science/` se serve karein

Agar specifically yeh URL chahiye:

```text
http://192.168.1.154/space-science/
```

to files ko matching subdirectory mein deploy karein:

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

Ab mapping hogi:

```text
http://192.168.1.154/space-science/
                      ↓
/var/www/lawfirm.com/html/space-science/index.html
```

Ek deployment layout choose karein aur us ke matching URL ko use karein.

---

## 10. Teenon Nodes Par Deploy Karein

Pehle confirm karein ke teenon nodes `/var/www/lawfirm.com/html` use karte hain.

### Step 1: Nginx aur unzip install karein

```bash
ansible three_tier_app -b -m dnf -a \
"name=nginx,unzip state=present"
```

### Step 2: Nginx start aur enable karein

```bash
ansible three_tier_app -b -m service -a \
"name=nginx state=started enabled=yes"
```

### Step 3: HTTP allow karein

```bash
ansible three_tier_app -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=enabled"
```

### Step 4: Archive download karein

```bash
ansible three_tier_app -m get_url -a \
"url=https://freewebsitetemplates.com/download/space-science/ dest=/tmp/space-science.zip mode=0644"
```

### Step 5: Extraction directory banayein

```bash
ansible three_tier_app -b -m file -a \
"path=/tmp/space-science-extracted state=directory mode=0755"
```

### Step 6: Archive extract karein

```bash
ansible three_tier_app -b -m unarchive -a \
"src=/tmp/space-science.zip dest=/tmp/space-science-extracted remote_src=yes creates=/tmp/space-science-extracted/space-science/upload/index.html"
```

### Step 7: Website copy karein

```bash
ansible three_tier_app -b -m copy -a \
"src=/tmp/space-science-extracted/space-science/upload/ dest=/var/www/lawfirm.com/html/ remote_src=yes owner=root group=root mode=preserve"
```

### Step 8: SELinux contexts restore karein

```bash
ansible three_tier_app -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

### Step 9: HTTP verify karein

```bash
ansible three_tier_app -m uri -a \
"url=http://localhost status_code=200"
```

Browser URLs:

```text
http://192.168.1.154/
http://192.168.1.185/
http://192.168.1.190/
```

---

## 11. Idempotency

| Operation | Second run par expected result |
|---|---|
| `dnf state=present` | Packages installed hon to `changed=false` |
| `service state=started enabled=yes` | Running aur enabled ho to `changed=false` |
| `firewalld state=enabled` | HTTP pehle se allowed ho to `changed=false` |
| `get_url` | Remote file same ho to aam tor par `changed=false` |
| `unarchive creates=...` | Marker file ho to extraction skip |
| `copy` | Contents same hon to `changed=false` |
| `uri` | Verification; aam tor par `changed=false` |

`command` module read-only command par bhi aksar `CHANGED` dikhata hai. Is ka matlab zaroori nahi ke host modify hua hai.

---

## 12. Troubleshooting

### HTTP 403 Forbidden

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"

ansible node1 -b -m command -a \
"ls -laZ /var/www/lawfirm.com/html"

ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*root[[:space:]]'"
```

403 missing index, directory permissions ya ghalat SELinux context ki wajah se aa sakta hai.

### `/space-science/` par 404

Current root deployment ke liye yeh URL use karein:

```text
http://192.168.1.154/
```

### Port 80 pehle se use ho

```bash
ansible node1 -b -m shell -a "ss -tlnp | grep ':80 '"
```

### ZIP ke bajaye HTML download ho

```bash
ansible node1 -m command -a "file /tmp/space-science.zip"
```

### Nginx configuration validate karein

```bash
ansible node1 -b -m command -a "nginx -t"
```

---

## 13. Cleanup

Cleanup mein `all` ke bajaye `three_tier_app` use karein. `all` group mein control node bhi shamil ho sakta hai.

### Option 1: Sirf website lab reset karein — recommended

Is option se website aur temporary files remove hongi, lekin Nginx aur `lawfirm.com` configuration next practice ke liye rahengi.

#### Step 1: Current website content remove karein

```bash
ansible three_tier_app -b -m file -a \
"path=/var/www/lawfirm.com/html state=absent"
```

#### Step 2: Khaali document root dobara banayein

```bash
ansible three_tier_app -b -m file -a \
"path=/var/www/lawfirm.com/html state=directory owner=root group=root mode=0755"
```

Nayi `index.html` deploy hone tak root URL `403` de sakti hai. Yeh expected hai.

#### Step 3: Extraction directory remove karein

```bash
ansible three_tier_app -b -m file -a \
"path=/tmp/space-science-extracted state=absent"
```

#### Step 4: Archive remove karein

```bash
ansible three_tier_app -b -m file -a \
"path=/tmp/space-science.zip state=absent"
```

#### Step 5: Cleanup verify karein

```bash
ansible three_tier_app -m stat -a \
"path=/var/www/lawfirm.com/html/index.html"

ansible three_tier_app -m stat -a \
"path=/tmp/space-science.zip"

ansible three_tier_app -m stat -a \
"path=/tmp/space-science-extracted"
```

Removed items ke liye `exists: false` aana chahiye.

### Option 2: Full Nginx reset

Sirf tab use karein jab kisi doosri website ko Nginx ya port 80 ki zaroorat na ho.

#### Step 1: Nginx stop aur disable karein

```bash
ansible three_tier_app -b -m service -a \
"name=nginx state=stopped enabled=no"
```

#### Step 2: Nginx packages remove karein

```bash
ansible three_tier_app -b -m dnf -a \
"name=nginx,nginx-core,nginx-filesystem state=absent"
```

#### Step 3: Optional unzip remove karein

```bash
ansible three_tier_app -b -m dnf -a "name=unzip state=absent"
```

#### Step 4: Firewalld mein HTTP disable karein

```bash
ansible three_tier_app -b -m firewalld -a \
"service=http permanent=yes immediate=yes state=disabled"
```

#### Step 5: Full reset verify karein

```bash
ansible three_tier_app -m command -a \
"rpm -q nginx nginx-core nginx-filesystem"

ansible three_tier_app -b -m shell -a \
"ss -tlnp | grep ':80 ' || true"
```

Packages `not installed` report karein aur port 80 par Nginx listen na kare.

### Optional destructive configuration cleanup

Normal cleanup mein `/etc/nginx` remove na karein. Is mein `lawfirm.com` configuration hoti hai.

Agar complete configuration dobara banana ho to:

```bash
ansible three_tier_app -b -m file -a \
"path=/etc/nginx state=absent"
```

Is ke baad Nginx reinstall karna custom `lawfirm.com` server block ko automatically recreate nahi karega. Aap ko configuration dobara banani hogi.

---

## 14. Ahm Learning Points

1. Default root assume karne ke bajaye active Nginx configuration inspect karein.
2. `403` ka matlab server ne jawab diya lekin content serve nahi kar saka.
3. `404` ka matlab requested URL ka matching path nahi mila.
4. Archive extract karne se pehle us ka layout inspect karein.
5. Sirf `space-science/upload/` ke website contents deploy karein.
6. Browser URL ko filesystem deployment path ke saath match karein.
7. Trailing slash directory aur us ke contents copy karne mein farq karta hai.
8. SELinux system par `/tmp` se copy ke baad `restorecon` chalayein.
9. Sab nodes se pehle `node1` par pilot test karein.
10. Cleanup ke liye `three_tier_app` use karein taa-ke control node affect na ho.
