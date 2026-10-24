# Assignment: Ansible aur Nginx se Do Static Websites Deploy Karna

## Fehrist (Table of Contents)

1. [Scenario](#1-scenario)
2. [Learning Objectives](#2-learning-objectives)
3. [Lab Environment](#3-lab-environment)
4. [Rules aur Safety](#4-rules-aur-safety)
5. [Templates ki Tayari](#5-templates-ki-tayari)
6. [Method 1: URL Subdirectories](#6-method-1-url-subdirectories)
7. [Method 2: Separate Hostnames](#7-method-2-separate-hostnames)
8. [Verification Requirements](#8-verification-requirements)
9. [Idempotency Test](#9-idempotency-test)
10. [Cleanup Requirements](#10-cleanup-requirements)
11. [Submit Karne Wala Evidence](#11-submit-karne-wala-evidence)
12. [Hints](#12-hints)
13. [Assessment Rubric](#13-assessment-rubric)

---

## 1. Scenario

Aap Ansible ke zariye Rocky Linux 9 server manage kar rahe hain. Aapka task Nginx par do static website templates deploy karna hai:

1. Space Science
2. Frozen Yogurt Shop

Aapko deployment do mukhtalif Nginx designs ke saath complete karni hai:

- **Method 1:** Dono websites ek IP address ke neeche alag URL paths se access hongi.
- **Method 2:** Dono websites port 80 share karengi, lekin unke hostnames alag honge.

Mazeed managed nodes ko target karne se pehle `node1` par pilot deployment karein.

---

## 2. Learning Objectives

Is assignment ko complete karne ke baad aap:

- static website source files tayar kar sakein ge;
- Ansible se Nginx install aur manage kar sakein ge;
- `copy` module se multiple websites deploy kar sakein ge;
- URL aur filesystem ke darmiyan mapping samajh sakein ge;
- Nginx virtual hosts configure kar sakein ge;
- reload se pehle Nginx configuration validate kar sakein ge;
- SELinux-compatible document roots use kar sakein ge;
- HTTP status codes se websites verify kar sakein ge;
- Ansible idempotency test kar sakein ge;
- control node ko affect kiye baghair lab cleanup kar sakein ge.

---

## 3. Lab Environment

| Item | Value |
|---|---|
| Control node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Pilot managed node | `node1` |
| node1 IP | `192.168.1.154` |
| Managed-node group | `three_tier_app` |
| Operating system | Rocky Linux 9 |
| Web server | Nginx |
| HTTP port | `80` |

Recommended local project structure:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
├── files/
│   ├── sites/
│   │   ├── space-science/
│   │   └── frozen-yogurt/
│   └── nginx/
│       ├── space.conf
│       └── yogurt.conf
└── evidence/
```

---

## 4. Rules aur Safety

1. Pilot deployment ke liye `node1` ya `--limit node1` use karein.
2. Destructive cleanup ke liye `ansible all` use na karein, kyun ke `all` mein control node bhi shamil ho sakta hai.
3. Pilot successful hone ke baad hi `three_tier_app` use karein.
4. Nginx reload karne se pehle `nginx -t` run karein.
5. SELinux disable na karein.
6. Firewalld disable na karein; sirf zaroori HTTP service allow karein.
7. Downloaded template source ke copyright notices ko barqarar rakhein.
8. Original template files ko redistribute ya sell na karein.

Use se pehle current template terms review karein:

```text
https://freewebsitetemplates.com/about/terms
```

---

## 5. Templates ki Tayari

Official website se yeh templates download karein:

```text
https://freewebsitetemplates.com/
```

- Space Science Template
- Frozen Yogurt Shop Template

### Task 1: Local source directories banayein

Yeh directories create karein:

```text
/home/ansibleadmin/automation/files/sites/space-science/
/home/ansibleadmin/automation/files/sites/frozen-yogurt/
```

### Task 2: Dono ZIP archives inspect karein

Munāsib commands use karke:

- confirm karein ke har download ZIP archive hai;
- archive ke contents list karein;
- deploy hone wali `index.html` locate karein;
- HTML, CSS, JavaScript, fonts aur images wali directory identify karein.

### Task 3: Clean source directories tayar karein

Sirf deploy hone wali website files ko dono local source directories mein copy karein.

Har directory ke top level par uski apni `index.html` honi chahiye:

```text
files/sites/space-science/index.html
files/sites/frozen-yogurt/index.html
```

PSD design sources ya ghair-zaroori archive folders ko deployment directories mein copy na karein.

---

## 6. Method 1: URL Subdirectories

Dono websites ko ek active Nginx document root ke neeche deploy karein.

### Required filesystem layout

```text
/var/www/lawfirm.com/html/
├── space-science/
│   └── index.html
└── frozen-yogurt/
    └── index.html
```

### Required browser URLs

```text
http://192.168.1.154/space-science/
http://192.168.1.154/frozen-yogurt/
```

### Tasks

1. `nginx` install karein.
2. Nginx service ko start aur enable karein.
3. Firewalld mein HTTP allow karein.
4. Dono remote website directories create karein.
5. Control node se Space Science site copy karein.
6. Control node se Frozen Yogurt Shop site copy karein.
7. Munāsib ownership aur permissions set karein.
8. SELinux contexts restore karein.
9. Verify karein ke dono remote `index.html` files maujood hain.
10. Dono URLs ke liye HTTP status `200` verify karein.

### Written question

Explain karein ke yeh URL:

```text
http://192.168.1.154/space-science/
```

is file se kyun map hota hai:

```text
/var/www/lawfirm.com/html/space-science/index.html
```

---

## 7. Method 2: Separate Hostnames

Do Nginx virtual hosts configure karein jo same IP address aur TCP port 80 share karein.

### Required design

| Hostname | Document root |
|---|---|
| `space.nitclasses.com` | `/var/www/space/html` |
| `yogurt.nitclasses.com` | `/var/www/yogurt/html` |

### Tasks

1. Dono document roots create karein.
2. Har root mein sahi website deploy karein.
3. Har hostname ke liye separate Nginx server block banayein.
4. `root` aur `index` ko sahi configure karein.
5. Dono server-block files ko `/etc/nginx/conf.d/` mein copy karein.
6. Complete Nginx configuration validate karein.
7. Validation successful hone ke baad hi Nginx reload karein.
8. Client par DNS ya hosts file se hostname resolution add karein.
9. Dono websites ko unke hostnames ke zariye verify karein.

### Client hosts-file entries

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

### Required browser URLs

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

### Written question

Dono websites `192.168.1.154:80` use karti hain. Explain karein ke Nginx kis tarah decide karta hai ke kaunsi website serve karni hai.

---

## 8. Verification Requirements

Yeh tamam cheezein verify karein:

- Nginx active hai.
- Nginx boot par enabled hai.
- TCP port 80 listening state mein hai.
- Firewalld mein HTTP allowed hai.
- Tamam required `index.html` files maujood hain.
- Website files ke SELinux contexts web-readable hain.
- `nginx -t` successful configuration test report karta hai.
- Munāsib stage par tamam chaar required URLs HTTP `200` return karte hain.

---

## 9. Idempotency Test

Har state-management ad-hoc command ko doosri martaba run karein.

Document karein ke kaun se commands yeh report karte hain:

```text
changed=false
```

Explain karein ke `command` task sirf verification perform karne ke bawajood `CHANGED` kyun report kar sakta hai.

---

## 10. Cleanup Requirements

Ek safe cleanup procedure banayein jo sirf lab resources remove kare:

- `/var/www/lawfirm.com/html/space-science`
- `/var/www/lawfirm.com/html/frozen-yogurt`
- `/var/www/space`
- `/var/www/yogurt`
- `/etc/nginx/conf.d/space.conf`
- `/etc/nginx/conf.d/yogurt.conf`

Server blocks remove karne ke baad:

1. baqi Nginx configuration validate karein;
2. Nginx reload karein;
3. confirm karein ke lab URLs ab deployed sites return nahi kar rahe.

`/etc/nginx` ya doosri unrelated websites remove na karein.

---

## 11. Submit Karne Wala Evidence

Yeh evidence submit karein:

1. inventory host list;
2. successful Ansible ping output;
3. archive inspection output;
4. locally prepared directory trees;
5. use kiye gaye important ad-hoc commands;
6. `nginx -t` output;
7. har document root ka `ls -lZ` output;
8. HTTP verification output;
9. dono methods ke liye dono sites ke browser screenshots;
10. second-run idempotency results;
11. cleanup verification.

---

## 12. Hints

- Directories create aur remove karne ke liye `file` use karein.
- Control node se prepared website directories transfer karne ke liye `copy` use karein.
- `src=directory/` mein trailing slash directory ke contents copy karta hai.
- Package management ke liye `dnf` use karein.
- Nginx state ke liye `service` use karein.
- HTTP allow karne ke liye `firewalld` use karein.
- Files verify karne ke liye `stat` use karein.
- HTTP status check karne ke liye `uri` use karein.
- Web content copy karne ke baad `restorecon -Rv` use karein.
- `validate` tabhi use karein jab validation command complete configuration ke liye munāsib ho; warna temporary path par copy karke reload se pehle `nginx -t` run karein.
- Named virtual hosts HTTP `Host` header ke zariye select hote hain.

---

## 13. Assessment Rubric

| Area | Points |
|---|---:|
| Prechecks aur safe pilot workflow | 10 |
| Template preparation | 15 |
| Method 1 deployment | 20 |
| Method 2 virtual-host deployment | 25 |
| SELinux, firewall aur permissions | 10 |
| Verification aur troubleshooting | 10 |
| Idempotency aur cleanup | 10 |
| **Total** | **100** |
