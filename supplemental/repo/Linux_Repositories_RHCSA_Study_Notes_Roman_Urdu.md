# RHCSA Software Repository Configuration — Mukammal Roman Urdu Study Notes

<img src="Linux-Repositories.png" width="700">


Yeh notes Linux software repositories ko bilkul bunyaad se samjhati hain aur phir RHEL ya Rocky Linux 9 par RHCSA-style repository configuration task solve karwati hain.

> RHCSA practice mein diye gaye domain names aur URLs aksar sirf exam ya training network ke andar kaam karte hain. `repo.eight.example.com` jaise example addresses ka home lab se reachable hona zaroori nahi.

## Fehrist (Table of Contents)

1. [Learning objectives](#1-learning-objectives)
2. [Software repository kya hoti hai?](#2-software-repository-kya-hoti-hai)
3. [DNF, YUM aur RPM](#3-dnf-yum-aur-rpm)
4. [BaseOS aur AppStream](#4-baseos-aur-appstream)
5. [DNF packages kaise dhoondta hai?](#5-dnf-packages-kaise-dhoondta-hai)
6. [Repository configuration files](#6-repository-configuration-files)
7. [Aham repository directives](#7-aham-repository-directives)
8. [Current repository state inspect karna](#8-current-repository-state-inspect-karna)
9. [RHCSA-style repository task](#9-rhcsa-style-repository-task)
10. [Safe step-by-step solution](#10-safe-step-by-step-solution)
11. [Sirf new repositories validate karna](#11-sirf-new-repositories-validate-karna)
12. [Selected repositories se package install karna](#12-selected-repositories-se-package-install-karna)
13. [DNF cache commands](#13-dnf-cache-commands)
14. [Troubleshooting workflow](#14-troubleshooting-workflow)
15. [Security aur GPG verification](#15-security-aur-gpg-verification)
16. [Backup aur rollback](#16-backup-aur-rollback)
17. [Real-job scenario](#17-real-job-scenario)
18. [Common mistakes](#18-common-mistakes)
19. [Command reference](#19-command-reference)
20. [Interview-ready jawab](#20-interview-ready-jawab)
21. [Practice exercises](#21-practice-exercises)
22. [Completion checklist](#22-completion-checklist)
23. [Review questions](#23-review-questions)

---

## 1. Learning objectives

Is project ke end tak aap yeh kar sakenge:

- Linux software repository ko asaan alfaaz mein explain karna.
- DNF, YUM aur RPM ka role samajhna.
- BaseOS aur AppStream ka difference batana.
- `.repo` file read aur create karna.
- `mirrorlist`, `baseurl`, `enabled`, `gpgcheck` aur `gpgkey` samajhna.
- Supplied URLs ke saath do repositories configure karna.
- Package install kiye baghair repository metadata validate karna.
- DNF ko sirf selected repositories use karne par majboor karna.
- Network, DNS, HTTP, metadata aur configuration problems troubleshoot karna.
- Repository configuration ka backup aur rollback safely karna.

---

## 2. Software repository kya hoti hai?

Software repository ek managed location hoti hai jahan yeh cheezen rakhi jati hain:

- RPM packages;
- package metadata;
- package versions;
- dependency information;
- checksums aur digital-signature information.

Repository ko ek software warehouse samjhein. RPM files warehouse ke products hain, jabke repository metadata us warehouse ka catalog hai.

Jab aap chalate hain:

```bash
sudo dnf install httpd
```

to DNF random internet search nahi karta. Woh enabled repository definitions read karta hai, metadata download ya cached metadata use karta hai, requested package aur dependencies locate karta hai, phir required RPM files download karta hai.

---

## 3. DNF, YUM aur RPM

| Tool | Kaam |
|---|---|
| `rpm` | Individual RPM package ko low level par install, query, verify ya remove karta hai |
| `dnf` | Repositories use karta hai aur dependencies resolve karta hai |
| `yum` | Modern RHEL/Rocky systems par compatibility command; aam tor par DNF ko use karta hai |

Examples:

```bash
rpm -q nginx
dnf info nginx
sudo dnf install nginx -y
```

- `rpm -q nginx`: check karta hai ke package installed hai ya nahi.
- `dnf info nginx`: installed ya repository metadata se package information show karta hai.
- `dnf install nginx`: dependencies resolve karke package install karta hai.

---

## 4. BaseOS aur AppStream

RHEL aur Rocky Linux 9 mein BaseOS aur AppStream major repository groups hain.

| Repository | Kya provide karti hai | Asaan misaal |
|---|---|---|
| **BaseOS** | Kernel, core libraries, boot components aur essential OS tools | Ghar ki bunyaad |
| **AppStream** | Applications, languages, runtimes, databases aur additional services | Ghar ke andar tools aur services |

Complete system ke liye aam tor par dono repositories required hoti hain. Ek package ek repository mein ho sakta hai, jabke uski dependencies doosri repository se aa sakti hain.

Package kis repository se mil raha hai:

```bash
dnf info bash
dnf info python3
dnf info nginx
```

Output mein `From repo` ya `Repository` field dekhein.

---

## 5. DNF packages kaise dhoondta hai?

Simplified flow:

1. Administrator DNF command chalata hai.
2. DNF `/etc/dnf/` aur `/etc/yum.repos.d/` ki configuration read karta hai.
3. DNF enabled repositories select karta hai.
4. DNF `mirrorlist` ya direct `baseurl` se repository metadata leta hai.
5. Metadata mein requested package search karta hai.
6. Required dependencies calculate karta hai.
7. RPM packages download karta hai.
8. GPG verification enabled ho to signatures check karta hai.
9. RPM packages install karke local RPM database update karta hai.

```text
dnf command
    ↓
.repo configuration
    ↓
mirrorlist ya baseurl
    ↓
repository metadata
    ↓
RPM packages aur dependencies
    ↓
signature verification
    ↓
installation
```

---

## 6. Repository configuration files

Repository definitions aam tor par yahan hoti hain:

```text
/etc/yum.repos.d/
```

Files list karein:

```bash
ls -l /etc/yum.repos.d/
```

Aham rule:

> Repository configuration filename ka extension `.repo` hona chahiye.

Examples:

```text
/etc/yum.repos.d/rocky.repo
/etc/yum.repos.d/redhat.repo
/etc/yum.repos.d/eight.repo
```

Ek `.repo` file ke andar multiple repository blocks ho sakte hain. Har block square brackets mein repository ID se start hota hai.

```ini
[example-baseos]
name=Example BaseOS
baseurl=http://repo.example.com/BaseOS
enabled=1
gpgcheck=0

[example-appstream]
name=Example AppStream
baseurl=http://repo.example.com/AppStream
enabled=1
gpgcheck=0
```

Tamam `.repo` files mein repository IDs unique hone chahiye. Agar `[baseos]` ID pehle se configured hai to dobara `[baseos]` create na karein.

---

## 7. Aham repository directives

| Directive | Matlab |
|---|---|
| `[repo-id]` | DNF commands mein use hone wali unique ID |
| `name=` | Insanon ke liye readable repository name |
| `baseurl=` | Repository server ka direct URL |
| `mirrorlist=` | Possible mirror addresses dene wali service ka URL |
| `enabled=1` | Repository enabled hai aur DNF use kar sakta hai |
| `enabled=0` | Repository configured hai lekin default mein disabled hai |
| `gpgcheck=1` | RPM package signatures verify karo |
| `gpgcheck=0` | RPM package signatures verify na karo |
| `gpgkey=` | Trusted public signing key ka location |
| `metadata_expire=` | Cached metadata kitni der current samjha jaye |

### `mirrorlist` aur `baseurl` ka difference

`mirrorlist=` aisi service ko point karta hai jo DNF ko suitable package servers ki list deti hai. Mirror-list service khud package warehouse hona zaroori nahi.

`baseurl=` DNF ko seedha ek specific repository location par bhejta hai.

```ini
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?...
```

```ini
baseurl=http://repo.eight.example.com/BaseOS
```

Agar exam exact repository URLs deta hai, unhein `baseurl` values ke taur par use karein.

### DNF variables

| Variable | Matlab |
|---|---|
| `$releasever` | DNF ka OS release, jaise `9` |
| `$basearch` | System architecture, jaise `x86_64` ya `aarch64` |

DNF in variables ko automatically substitute karta hai. Vendor-provided repository file mein inhein manually replace karna aam tor par zaroori nahi.

---

## 8. Current repository state inspect karna

### 8.1 Enabled repositories

```bash
dnf repolist
```

Example:

```text
repo id              repo name
appstream            Rocky Linux 9 - AppStream
baseos               Rocky Linux 9 - BaseOS
extras               Rocky Linux 9 - Extras
```

### 8.2 Enabled aur disabled repositories

```bash
dnf repolist --all
```

### 8.3 Detailed repository information

```bash
dnf repoinfo
```

### 8.4 Important directives inspect karein

```bash
sudo grep -R --line-number --extended-regexp \
  '^\[|^name=|^baseurl=|^mirrorlist=|^enabled=|^gpgcheck=|^gpgkey=' \
  /etc/yum.repos.d/
```

Yeh command tamam comments print karne ke bajaye important active directives show karti hai.

### 8.5 Sahi machine confirm karein

```bash
hostnamectl
whoami
cat /etc/os-release
```

Package sources modify karne se pehle hamesha target system confirm karein.

---

## 9. RHCSA-style repository task

Example task:

> In URLs par available repositories configure karein:
>
> `http://repo.eight.example.com/BaseOS`
>
> `http://repo.eight.example.com/AppStream`

Task ke requirements:

- Valid `.repo` file;
- do unique repository IDs;
- question mein diye gaye exact `baseurl` values;
- enabled repositories;
- exam instructions aur available key ke mutabiq GPG configuration;
- successful metadata validation.

Example domain sirf exam environment ke andar reachable ho sakta hai.

---

## 10. Safe step-by-step solution

### Step 1: Existing IDs confirm karein

```bash
dnf repolist --all
```

Existing `baseos` ya `appstream` IDs reuse na karein. Is guide mein new IDs hain:

```text
eight-baseos
eight-appstream
```

### Step 2: Current configuration ka backup

```bash
timestamp="$(date '+%Y-%m-%d-%H-%M-%S')"
sudo cp -a /etc/yum.repos.d \
  "/root/yum.repos.d.backup-$timestamp"
```

Verify:

```bash
sudo ls -ld "/root/yum.repos.d.backup-$timestamp"
```

### Step 3: Supplied locations test karein

```bash
curl -I --max-time 10 http://repo.eight.example.com/BaseOS/
curl -I --max-time 10 http://repo.eight.example.com/AppStream/
```

HTTP response web server ki reachability dikhata hai, lekin repository metadata ki final validation phir bhi zaroori hai. Kuch servers `HEAD` request support nahi karte; aisi surat mein `dnf makecache` ka exact error dekhein.

### Step 4: Repository file create karein

```bash
sudo vi /etc/yum.repos.d/eight.repo
```

Add karein:

```ini
[eight-baseos]
name=Eight BaseOS
baseurl=http://repo.eight.example.com/BaseOS
enabled=1
gpgcheck=0

[eight-appstream]
name=Eight AppStream
baseurl=http://repo.eight.example.com/AppStream
enabled=1
gpgcheck=0
```

> `gpgcheck=0` yahan sirf controlled exercise ke liye dikhaya gaya hai jahan key supply nahi ki gayi aur task yahi configuration expect karta hai. Real environment mein signed packages aur trusted key available hon to `gpgcheck=1` aur approved `gpgkey` use karein.

### Step 5: File details check karein

```bash
sudo cat /etc/yum.repos.d/eight.repo
sudo stat /etc/yum.repos.d/eight.repo
```

Confirm karein:

- filename `.repo` par end hota hai;
- IDs ki spelling aur case sahi hai;
- URLs task se exact match karte hain;
- directives `key=value` format use karti hain;
- duplicate IDs nahi hain.

### Step 6: Metadata refresh karein

```bash
sudo dnf clean all
sudo dnf makecache
```

### Step 7: Repositories confirm karein

```bash
dnf repolist --all | grep -E 'eight-(baseos|appstream)'
```

Expected concept:

```text
eight-appstream    Eight AppStream    enabled
eight-baseos       Eight BaseOS       enabled
```

---

## 11. Sirf new repositories validate karna

Tamam repositories temporarily disable karke sirf new IDs enable karein:

```bash
sudo dnf makecache \
  --disablerepo='*' \
  --enablerepo='eight-baseos,eight-appstream'
```

Sirf selected repositories list karein:

```bash
dnf repolist \
  --disablerepo='*' \
  --enablerepo='eight-baseos,eight-appstream'
```

> Repository IDs exact strings hoti hain. Har command mein `eight-baseos` aur `eight-appstream` isi spelling, case aur hyphen ke saath use karein.

---

## 12. Selected repositories se package install karna

Pehle package availability check karein:

```bash
dnf info httpd \
  --disablerepo='*' \
  --enablerepo='eight-baseos,eight-appstream'
```

Successful checks ke baad install karein:

```bash
sudo dnf install -y httpd \
  --disablerepo='*' \
  --enablerepo='eight-baseos,eight-appstream'
```

Installed RPM verify karein:

```bash
rpm -q httpd
```

`rpm -q` local RPM database mein installation confirm karta hai. Latest DNF transaction ki detail ke liye:

```bash
sudo dnf history info last
```

---

## 13. DNF cache commands

Cache ko DNF ka saved store catalog samjhein.

| Command | Kaam |
|---|---|
| `dnf clean all` | Cached repository metadata aur cached packages clear karta hai |
| `dnf makecache` | Enabled repositories ka fresh metadata download karta hai |
| `dnf repolist` | Enabled repositories list karta hai |
| `dnf repolist --all` | Enabled aur disabled repositories list karta hai |
| `dnf info PACKAGE` | Package information show karta hai |

Repository definition create ya change karne ke baad:

```bash
sudo dnf clean all
sudo dnf makecache
```

Har installation se pehle `dnf clean all` chalana zaroori nahi. DNF normally metadata freshness khud manage karta hai.

---

## 14. Troubleshooting workflow

System se bahar ki taraf step-by-step troubleshoot karein. Ek waqt mein multiple layers change na karein.

### 14.1 Interface state

```bash
nmcli device status
ip -br address
```

Actual interface name ke saath:

```bash
sudo ethtool enX0 | grep 'Link detected'
```

### 14.2 Routing

```bash
ip -4 route
```

Valid default route dekhein:

```text
default via 192.168.1.254 dev enX0
```

Configured gateway test karein:

```bash
ping -c 2 192.168.1.254
```

### 14.3 DNS configuration

```bash
cat /etc/resolv.conf
getent hosts repo.eight.example.com
```

`getent hosts` system ki normal name-resolution configuration use karta hai, jis mein `/etc/hosts` aur DNS shamil ho sakte hain.

Available hon to:

```bash
dig repo.eight.example.com
nslookup repo.eight.example.com
```

Rocky Linux par yeh commands `bind-utils` package se milti hain:

```bash
sudo dnf install bind-utils -y
```

Yeh installation tabhi hogi jab kam az kam ek repository kaam kar rahi ho.

### 14.4 HTTP connectivity

```bash
curl -I --max-time 10 http://repo.eight.example.com/BaseOS/
curl -I --max-time 10 http://repo.eight.example.com/AppStream/
```

| Result | Mumkin wajah |
|---|---|
| `Could not resolve host` | DNS ya hostname problem |
| `Connection timed out` | Routing, firewall, VPN ya remote-server problem |
| `Connection refused` | Host reachable hai lekin service us port par listen nahi kar rahi |
| `404 Not Found` | URL path ghalat ho sakta hai |
| `200`, `301`, `302` | Web endpoint ne jawab diya; ab DNF metadata test karein |

### 14.5 IDs aur URLs check karein

```bash
sudo cat /etc/yum.repos.d/eight.repo
dnf repolist --all
```

### 14.6 Verbose DNF diagnostics

```bash
sudo dnf -v makecache \
  --disablerepo='*' \
  --enablerepo='eight-baseos,eight-appstream'
```

Sab se pehla meaningful error padhein. Baad ke errors aksar pehle error ke consequences hote hain.

### 14.7 `repomd.xml` error

Agar DNF `repomd.xml` download nahi kar sake to possible causes:

- `baseurl` ghalat hai;
- server par repository metadata missing hai;
- DNS fail hai;
- routing ya firewall issue hai;
- exam VPN/network connected nahi;
- proxy required hai;
- repository server unavailable hai.

---

## 15. Security aur GPG verification

`gpgcheck=1` DNF ko RPM ki trusted digital signature verify karne ka hukm deta hai.

Secure example:

```ini
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
```

`file://` ka matlab key local system par stored hai.

Aham rules:

- Real environment mein signature verification prefer karein.
- Sirf asaani ke liye GPG checking disable na karein.
- Question mein key print na hona yeh prove nahi karta ke system par suitable key maujood nahi.
- Task instructions follow karein aur available keys inspect karein.
- `gpgcheck=0` wali approved exception ko document karein.

Available keys:

```bash
ls -l /etc/pki/rpm-gpg/
```

---

## 16. Backup aur rollback

### 16.1 Backup

```bash
timestamp="$(date '+%Y-%m-%d-%H-%M-%S')"
sudo cp -a /etc/yum.repos.d \
  "/root/yum.repos.d.backup-$timestamp"
```

### 16.2 Custom file rollback

Target preview karein:

```bash
sudo ls -l /etc/yum.repos.d/eight.repo
```

Sirf custom file remove karein:

```bash
sudo rm -f -- /etc/yum.repos.d/eight.repo
sudo dnf clean all
sudo dnf makecache
```

### 16.3 Complete directory restore

Backups list karein:

```bash
sudo ls -ld /root/yum.repos.d.backup-*
```

Exact timestamp select karke restore karein:

```bash
sudo cp -a \
  /root/yum.repos.d.backup-YYYY-MM-DD-HH-MM-SS/. \
  /etc/yum.repos.d/

sudo dnf clean all
sudo dnf makecache
```

Multiple backups hon to unresolved wildcard ko source na banayein. Restore backup ke baad create hui unrelated `.repo` files ko automatically remove nahi karta.

---

## 17. Real-job scenario

### Business requirement

Company sirf approved internal repositories se software installation allow karti hai. Infrastructure team repository server bana chuki hai. Linux administration team ko managed servers approved sources par point karne hain.

### Implementation stages

1. URLs aur configuration ko ek non-production VM par test karein.
2. Original repository state record karein.
3. Current configuration ka backup banayein.
4. Unique name wali repository file create karein.
5. Sirf new repository IDs ke saath metadata validate karein.
6. Test package query ya install karein.
7. Evidence aur application health checks collect karein.
8. Proven manual process ko Ansible automation mein convert karein.
9. Chhote host group par pilot karein.
10. Controlled batches mein rollout karein.
11. Failures monitor karein aur rollback instructions ready rakhein.

Syntactically correct `.repo` file bhi ghalat content, architecture, release ya security key ko point kar sakti hai. Isi liye company-wide change se pehle pilot zaroori hai.

---

## 18. Common mistakes

### Mistake 1: Duplicate IDs

Agar `[baseos]` pehle se hai to custom file mein yeh use karein:

```ini
[eight-baseos]
```

### Mistake 2: ID spelling change karna

Configured:

```ini
[eight-baseos]
```

Ghalat:

```bash
--enablerepo=Eightbaseos
```

Sahi:

```bash
--enablerepo=eight-baseos
```

### Mistake 3: Example URL ko har network par working samajhna

Exam/training domain private ho sakta hai. Correct exam ya VPN network se test karein.

### Mistake 4: GPG checking bila wajah disable karna

`gpgcheck=0` sirf controlled exercise ya approved design ke mutabiq use karein.

### Mistake 5: Tamam repositories ke saath test karna

Package purani repository se aa sakta hai aur new repository ki failure chhup sakti hai. Is liye:

```bash
--disablerepo='*' --enablerepo='eight-baseos,eight-appstream'
```

### Mistake 6: Backup aur rollback skip karna

Package sources edit karne se pehle original state preserve karein.

### Mistake 7: Vendor file ko directly edit karna

Alag aur clearly named custom `.repo` file audit aur cleanup ke liye behtar hoti hai.

---

## 19. Command reference

| Command | Maqsad |
|---|---|
| `dnf repolist` | Enabled repositories list karna |
| `dnf repolist --all` | Enabled aur disabled repositories list karna |
| `dnf repoinfo` | Repository details dikhana |
| `dnf info PACKAGE` | Package information dikhana |
| `dnf clean all` | DNF cache clear karna |
| `dnf makecache` | Fresh metadata download karna |
| `dnf -v makecache` | Verbose diagnostics ke saath metadata refresh |
| `--disablerepo='*'` | Ek command ke liye tamam repositories disable karna |
| `--enablerepo='ID1,ID2'` | Selected repository IDs enable karna |
| `rpm -q PACKAGE` | Local RPM database query karna |
| `dnf history info last` | Latest DNF transaction inspect karna |
| `getent hosts NAME` | System-level name resolution test karna |
| `curl -I URL` | HTTP headers request karna |
| `ip -4 route` | IPv4 routes aur default gateway dekhna |
| `nmcli device status` | NetworkManager devices ki state dekhna |

---

## 20. Interview-ready jawab

> Sab se pehle main correct server, operating-system version, network connectivity aur current repository state verify karunga. Changes se pehle `/etc/yum.repos.d` ka backup banaunga. Phir unique repository IDs, task mein diye gaye exact BaseOS aur AppStream URLs, `enabled=1`, aur appropriate GPG settings ke saath separate `.repo` file create karunga. File save karne ke baad zaroorat par stale metadata clear karke `dnf makecache` chalaunga. Phir tamam doosri repositories temporarily disable karke sirf new IDs enable karunga, taake prove ho ke new repositories independently kaam karti hain. Aakhir mein test package query ya install, evidence collection aur tested rollback procedure complete karunga.

---

## 21. Practice exercises

### Exercise 1: Repository discovery

```bash
dnf repolist
dnf repolist --all
dnf repoinfo
```

Jawab dein:

1. Kaunsi repositories enabled hain?
2. Kaunsi disabled hain?
3. `bash` package kaunsi repository provide karti hai?

### Exercise 2: Configuration reading

Ek `.repo` file select karke identify karein:

- repository ID;
- readable name;
- `mirrorlist` ya `baseurl`;
- enabled state;
- GPG-check state;
- GPG-key location.

### Exercise 3: Controlled custom repository

Authorized lab mein instructor ke URLs ke saath do unique repository blocks create karein. Phir tamam doosri repositories disable karke validate karein.

### Exercise 4: Failure simulation

Disposable test configuration mein ek waqt mein ek error create karein:

- hostname misspell karein;
- URL path ghalat karein;
- `--enablerepo` mein wrong ID use karein;
- ek required repository disable karein.

Har failure ka exact error aur root-cause identify karne wali command record karein.

---

## 22. Completion checklist

- [ ] Correct VM confirm ki
- [ ] OS aur release confirm ki
- [ ] Current repositories record ki
- [ ] Modification se pehle backup banaya
- [ ] Repository IDs unique hain
- [ ] BaseOS URL task se exact match karta hai
- [ ] AppStream URL task se exact match karta hai
- [ ] Repositories enabled hain
- [ ] GPG configuration appropriate aur documented hai
- [ ] `dnf makecache` successful hai
- [ ] New repositories doosri repos disabled hone par kaam karti hain
- [ ] Test package query ya install hota hai
- [ ] DNF transaction evidence collect ki
- [ ] SELinux enforcing rehta hai jab tak task kuch aur na kahe
- [ ] Firewall required state mein hai
- [ ] Rollback steps samajh kar safely verify kiye

---

## 23. Review questions

1. Repository aur RPM package mein kya difference hai?
2. DNF aur RPM ka role kya hai?
3. BaseOS aur AppStream mein kya farq hai?
4. `mirrorlist` aur `baseurl` mein kya difference hai?
5. Repository IDs unique kyun honi chahiye?
6. `enabled=1` ka kya matlab hai?
7. `gpgcheck=1` kaunsa security control provide karta hai?
8. `dnf clean all` kya remove karta hai?
9. `dnf makecache` kya download karta hai?
10. Unrelated repositories disable karke test kyun karna chahiye?
11. DNS problem ko HTTP-path problem se kaise alag karenge?
12. RHCSA example URL home lab mein kyun fail ho sakta hai?
13. Kaunsi command package installation confirm karti hai?
14. Custom repository configuration rollback kaise karenge?
15. Company-wide automation se pehle pilot kyun zaroori hai?

---

## Final summary

Repository configuration DNF ko batati hai ke software aur metadata kahan maujood hain. Reliable administrator sirf `.repo` file create nahi karta; woh correct system confirm karta hai, original state preserve karta hai, unique IDs use karta hai, connectivity aur metadata validate karta hai, exact repositories ko independently test karta hai, mumkin ho to signature verification enabled rakhta hai, aur clear rollback plan maintain karta hai.
