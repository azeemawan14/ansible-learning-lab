# Ansible `lineinfile` Ad-Hoc Demo Lab — Roman Urdu

## Fehrist (Table of Contents)

1. [Lab ka maqsad](#1-lab-ka-maqsad)
2. [Lab environment](#2-lab-environment)
3. [`lineinfile` ki definition](#3-lineinfile-ki-definition)
4. [Aham corrections](#4-aham-corrections)
5. [Command ka structure](#5-command-ka-structure)
6. [Step-by-step demo](#6-step-by-step-demo)
7. [Idempotency test](#7-idempotency-test)
8. [Regular expression ki wazahat](#8-regular-expression-ki-wazahat)
9. [Verification commands](#9-verification-commands)
10. [Cleanup](#10-cleanup)
11. [Troubleshooting](#11-troubleshooting)
12. [Quick-reference table](#12-quick-reference-table)
13. [Practice assignment](#13-practice-assignment)

---

## 1. Lab ka maqsad

Is lab mein hum Ansible ke `lineinfile` module ko ad-hoc commands ke zariye istemal karenge. Hum seekhenge ke:

- File ke bilkul shuru mein line kaise add karte hain
- File ke end mein line kaise add karte hain
- Kisi specific keyword ke baad line kaise add karte hain
- Existing line ko kaise replace karte hain
- Matching line ko kaise remove karte hain
- Exact line ko kaise remove karte hain
- Idempotency kaise test karte hain
- Commented aur active SSH `Banner` directives ko regex se kaise match karte hain
- Puri practice file ko sahi module se kaise delete karte hain

---

## 2. Lab environment

| Item | Value |
|---|---|
| Control node | `ansible-server` |
| Inventory group | `three_tier_app` |
| Managed nodes | `node1`, `node2`, `node3` |
| Remote user | `ansibleadmin` |
| Practice directory | `/tmp/ansible-module-lab` |
| Practice file | `/tmp/ansible-module-lab/lineinfile-demo.txt` |

Sab se pehle managed nodes ki connectivity check karein:

```bash
ansible three_tier_app -m ping
```

---

## 3. `lineinfile` ki definition

Ansible ka `lineinfile` module text file ke andar individual lines ko manage karta hai. Yeh ek line ko add, replace ya remove kar sakta hai aur aam tor par idempotency maintain karta hai.

Complete documentation:

```bash
ansible-doc lineinfile
```

Short syntax reference:

```bash
ansible-doc -s lineinfile
```

---

## 4. Aham corrections

### File ke beginning mein line add karna

Sahi option:

```text
insertbefore=BOF
```

Yeh istemal na karein:

```text
insertafter=BOF
```

`BOF` ka matlab **Beginning of File** hai.

### File ke end mein line add karna

```text
insertafter=EOF
```

`EOF` ka matlab **End of File** hai.

### Puri file delete karna

`lineinfile` lines ko remove karta hai, puri file ko nahi. Puri file delete karne ke liye `file` module istemal karein:

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt state=absent"
```

---

## 5. Command ka structure

```bash
ansible <host-pattern> -m lineinfile -a \
'path=<file> line="<text>" <position-or-regexp> state=present'
```

| Hissa | Matlab |
|---|---|
| `three_tier_app` | Target inventory group |
| `-m lineinfile` | `lineinfile` module select karta hai |
| `-a` | Module arguments provide karta hai |
| `path=` | Managed node par target file ka path |
| `line=` | Woh line jo file mein honi chahiye |
| `regexp=` | Existing line ko identify karne ka pattern |
| `insertbefore=` | Matching line ya `BOF` se pehle line insert karta hai |
| `insertafter=` | Matching line ya `EOF` ke baad line insert karta hai |
| `state=present` | Yaqeeni banata hai ke line mojood ho |
| `state=absent` | Yaqeeni banata hai ke matching line mojood na ho |
| `backup=yes` | Change se pehle file ka backup banata hai |

---

## 6. Step-by-step demo

### Step 1: Practice directory banayein

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab state=directory mode=0755"
```

### Step 2: Initial practice file banayein

```bash
ansible three_tier_app -m copy -a \
'content="This is the starting line.\nCourse: Ansible Basics\n" dest=/tmp/ansible-module-lab/lineinfile-demo.txt mode=0644'
```

### Step 3: Initial content verify karein

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
This is the starting line.
Course: Ansible Basics
```

> `command` module `CHANGED` report kar sakta hai, halanke `cat` sirf file read kar raha hai. Is ka matlab yeh nahi ke `cat` ne file change ki hai.

### Step 4: Beginning mein line add karein

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Welcome to the Ansible lab." insertbefore=BOF state=present backup=yes'
```

Verify karein:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
```

### Step 5: End mein line add karein

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Thanks for completing the practice." insertafter=EOF state=present'
```

Verify karein:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
Thanks for completing the practice.
```

### Step 6: Specific keyword ke baad line add karein

`Course:` se shuru hone wali line ke baad nayi line add karein:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt insertafter="^Course:" line="Lab group: three_tier_app" state=present'
```

Verify karein:

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Basics
Lab group: three_tier_app
Thanks for completing the practice.
```

### Step 7: Existing line replace karein

Existing `Course:` line ko replace karein:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt regexp="^Course:" line="Course: Ansible Automation" state=present backup=yes'
```

Expected line:

```text
Course: Ansible Automation
```

### Step 8: Regular expression se line remove karein

`Lab group:` se shuru hone wali line remove karein:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt regexp="^Lab group:" state=absent'
```

### Step 9: Exact line remove karein

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Thanks for completing the practice." state=absent'
```

### Step 10: Final content dekhein

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected content:

```text
Welcome to the Ansible lab.
This is the starting line.
Course: Ansible Automation
```

---

## 7. Idempotency test

Ek hi `lineinfile` command ko do martaba chalayein:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/lineinfile-demo.txt line="Welcome to the Ansible lab." insertbefore=BOF state=present'
```

Pehli execution yeh report kar sakti hai:

```text
changed: true
```

Doosri execution ko yeh report karna chahiye:

```text
changed: false
```

Ansible line ko duplicate nahi karta kyun ke required line pehle se requested state mein mojood hai.

---

## 8. Regular expression ki wazahat

Is pattern ko dekhein:

```text
^Course:
```

| Hissa | Matlab |
|---|---|
| `^` | Line ka beginning |
| `Course:` | Woh exact text jo beginning ke foran baad hona chahiye |

Yeh match karega:

```text
Course: Ansible Basics
```

Yeh match nahi karega:

```text
My Course: Ansible Basics
```

Doosri misaal:

```text
^Lab group:
```

Yeh har us line ko match karega jo `Lab group:` se shuru hoti hai.

> Configuration line replace karte waqt aisa pattern likhna behtar hai jo purani aur desired dono forms ko match kar sake. Is se idempotency maintain karne mein madad milti hai.

### SSH `Banner` ka practical regex

Yeh pattern aam SSH `Banner` directive ko match karta hai, chahe line commented ho ya active:

```regex
^\s*#?\s*Banner\s+.*$
```

| Regex ka hissa | Matlab |
|---|---|
| `^` | Line ka start |
| `\s*` | Zero ya zyada whitespace characters |
| `#?` | Optional `#` comment character |
| `\s*` | `#` ke baad zero ya zyada spaces |
| `Banner` | Exact SSH directive ka naam |
| `\s+` | `Banner` ke baad ek ya zyada whitespace characters |
| `.*` | Line ki baqi value |
| `$` | Line ka end |

Yeh examples match honge:

```text
#Banner none
# Banner /etc/issue.net
Banner none
    Banner /etc/ssh/banner.txt
```

Yeh examples match nahin honge:

```text
BannerFile /tmp/banner.txt
MyBanner none
```

Anchors `^` aur `$` unrelated text mein maujood sirf `Banner` lafz ko match hone se rokte hain.

Pehle sirf `node1` par change test karein:

```bash
ansible three_tier_app -b --limit node1 -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

`node1` verify karne ke baad tamam managed nodes par apply karein:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Aham behavior:

- Ek line match ho to `lineinfile` usay required line se replace karega.
- Koi line match na ho to Ansible required line ko aam tor par file ke end mein add karega.
- Kai lines match hon to `lineinfile` aam tor par aakhri matching line change karta hai. Har matching line change karni ho to `replace` module use karein.
- `backup=yes` file change hone par backup banata hai.
- `validate` live file replace karne se pehle temporary SSH configuration check karta hai.
- `%s` Ansible ke banaye huay temporary candidate file ko represent karta hai.
- Required line pehle se correct ho to second run par `changed=false` aana chahiye.

Change se pehle possible matches inspect karein:

```bash
ansible three_tier_app -b -m shell -a \
"grep -nE '^[[:space:]]*#?[[:space:]]*Banner[[:space:]]+.*$' /etc/ssh/sshd_config"
```

`grep` example POSIX character classes use karta hai. Ansible ka `regexp` Python-style `\s` use karta hai; dono apne tools mein whitespace describe karte hain.

---

## 9. Verification commands

### File display karein

```bash
ansible three_tier_app -m command -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt"
```

### Ek specific line search karein

Is command ko pipe ki zaroorat nahi, is liye `command` module istemal karein:

```bash
ansible three_tier_app -m command -a \
"grep ^Course: /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Jab pipe ya koi aur shell feature waqai zaroori ho tab `shell` module istemal karein. Misaal:

```bash
ansible three_tier_app -m shell -a \
"cat /tmp/ansible-module-lab/lineinfile-demo.txt | grep '^Course:'"
```

### File metadata check karein

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt"
```

### Check karein ke line ek se zyada martaba to nahi hai

```bash
ansible three_tier_app -m shell -a \
"grep -c '^Course:' /tmp/ansible-module-lab/lineinfile-demo.txt"
```

Expected count:

```text
1
```

---

## 10. Cleanup

### Sirf practice file remove karein

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt state=absent"
```

### Verify karein ke file remove ho gayi hai

```bash
ansible three_tier_app -m stat -a \
"path=/tmp/ansible-module-lab/lineinfile-demo.txt"
```

Output mein yeh dekhein:

```text
"exists": false
```

### Puri practice directory remove karein

```bash
ansible three_tier_app -m file -a \
"path=/tmp/ansible-module-lab state=absent"
```

Idempotency test karne ke liye cleanup command dobara chalayein. Doosri execution ko `changed: false` report karna chahiye.

---

## 11. Troubleshooting

### Error: destination file mojood nahi hai

Default tor par `lineinfile` target file ke mojood hone ki umeed karta hai. Module ko file banane ki ijazat dene ke liye yeh add karein:

```text
create=yes
```

Misaal:

```bash
ansible three_tier_app -m lineinfile -a \
'path=/tmp/ansible-module-lab/new-file.txt line="First line" create=yes mode=0644'
```

### Permission denied

`/etc` jaisi protected location ki files modify karte waqt `-b` istemal karein:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/example.conf regexp="^Option" line="Option enabled" backup=yes'
```

### Line ghalat jagah add ho gayi

Check karein ke `insertbefore` ya `insertafter` ko diya gaya expression file ki kisi line ko match karta hai ya nahi.

### Multiple matching lines

`lineinfile` zyada tar ek line manage karne ke liye hai. Agar multiple matching occurrences ko replace karna ho to `replace` module zyada munasib hai.

### Important configuration file validate karein

Jahan application validation command provide karti ho, `validate` parameter istemal karein. Is se Ansible changed file ko install karne se pehle uska syntax check karta hai. Misaal ke tor par SSH configuration ko `sshd -t` se validate kiya ja sakta hai.

---

## 12. Quick-reference table

| Requirement | Recommended arguments |
|---|---|
| Beginning mein add karein | `line="Text" insertbefore=BOF state=present` |
| End mein add karein | `line="Text" insertafter=EOF state=present` |
| Keyword ke baad add karein | `insertafter="^Keyword" line="Text" state=present` |
| Keyword se pehle add karein | `insertbefore="^Keyword" line="Text" state=present` |
| Line replace karein | `regexp="^Keyword" line="Replacement" state=present` |
| Matching line remove karein | `regexp="^Keyword" state=absent` |
| Exact line remove karein | `line="Exact text" state=absent` |
| Missing file create karein | `line="Text" create=yes` |
| Change se pehle backup | `backup=yes` |
| SSH Banner directive manage karein | `regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt"` |
| Puri file delete karein | `file` module ke saath `state=absent` |

---

## 13. Practice assignment

Completed commands ko copy kiye baghair pehle sirf `node1` par yeh tasks perform karein:

1. `/tmp/student-lineinfile-lab.txt` file banayein.
2. File ke beginning mein `Ansible Practice Lab` add karein.
3. File ke end mein `End of Lab` add karein.
4. `Owner:` se shuru hone wali line ke baad `Managed by Ansible` add karein.
5. `Environment: Test` ko `Environment: Production` se replace karein.
6. `Temporary:` se shuru hone wali line remove karein.
7. Har state-management command do martaba chalayein aur `changed` values compare karein.
8. Final file display karein.
9. Practice file ko correct module se remove karein.
10. Successful test ke baad puri exercise `three_tier_app` par repeat karein.
11. Advanced exercise mein `^\s*#?\s*Banner\s+.*$` ke har hisse ko explain karein aur SSH Banner command ko `--limit node1` ke saath test karein.

Pehle test mein `--limit node1` istemal karein:

```bash
ansible three_tier_app --limit node1 -m <module> -a '<arguments>'
```

Test successful hone ke baad `--limit node1` remove karke complete group ko target karein.
