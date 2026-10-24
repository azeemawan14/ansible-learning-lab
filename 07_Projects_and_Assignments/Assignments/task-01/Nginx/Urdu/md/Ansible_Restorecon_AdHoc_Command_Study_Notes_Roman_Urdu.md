# Ansible `restorecon` Ad-Hoc Command — Roman Urdu Study Notes

## Fehrist

1. [Command](#1-command)
2. [Command ka Maqsad](#2-command-ka-maqsad)
3. [Command Breakdown](#3-command-breakdown)
4. [restorecon ki Zaroorat Kyun Hai](#4-restorecon-ki-zaroorat-kyun-hai)
5. [R aur v Options](#5-r-aur-v-options)
6. [SELinux Context Verify Karein](#6-selinux-context-verify-karein)
7. [restorecon vs chmod vs chown](#7-restorecon-vs-chmod-vs-chown)
8. [Expected Ansible Result](#8-expected-ansible-result)
9. [Troubleshooting](#9-troubleshooting)
10. [Quick Summary](#10-quick-summary)

---

## 1. Command

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

Yeh Ansible ad-hoc command Nginx website directory aur us ke andar tamam files aur directories ke SELinux security contexts restore karti hai.

---

## 2. Command ka Maqsad

Website files temporary directory se copy hui thin, misal ke taur par:

```text
/tmp/space-science-extracted/
```

`/tmp` se aane wali files par temporary SELinux context ho sakta hai:

```text
user_tmp_t
```

Nginx ko static website content par aam tor par yeh web-readable SELinux type chahiye:

```text
httpd_sys_content_t
```

`restorecon` policy ke mutabiq sahi context restore karta hai:

```text
user_tmp_t
    ↓ restorecon
httpd_sys_content_t
```

Agar Linux permissions sahi hon lekin SELinux context ghalat ho, to SELinux Nginx ko file read karne se rok sakta hai. Is surat mein `403 Forbidden` aa sakta hai.

---

## 3. Command Breakdown

| Hissa | Wazahat |
|---|---|
| `ansible` | Ansible ad-hoc command chalata hai |
| `node1` | Command sirf inventory host `node1` par chalegi |
| `-b` | Privilege escalation yani aam tor par `sudo` use karta hai |
| `-m command` | Ansible ka `command` module use karta hai |
| `-a` | Module ko arguments deta hai |
| `restorecon` | SELinux policy ke mutabiq security context restore karta hai |
| `-R` | Directory ke tamam contents ko recursively process karta hai |
| `-v` | Relabeled files ki details display karta hai |
| `/var/www/lawfirm.com/html` | Website directory jis par command chal rahi hai |

### `-b` kyun zaroori hai?

System web directories ke SELinux labels change ya restore karne ke liye aam tor par root privileges chahiye hoti hain. `-b` Ansible ko `sudo` use karne ke liye kehta hai.

### `command` module kyun use hua?

`restorecon` ek operating-system command hai. Is command mein pipe, redirect, wildcard ya command substitution ki zaroorat nahi, is liye `command` module suitable hai.

---

## 4. `restorecon` ki Zaroorat Kyun Hai?

SELinux standard Linux ownership aur permissions ke ilawa apni security checking bhi karta hai.

Misal ke taur par file ki permissions readable ho sakti hain:

```text
-rw-r--r-- root root index.html
```

Lekin agar SELinux type ghalat ho to Nginx phir bhi file read nahi kar sakega.

Access ke liye teen cheezen check hoti hain:

1. File ownership
2. Standard Linux permissions
3. SELinux security context

Nginx ke website serve karne ke liye teenon sahi honi chahiye.

---

## 5. `-R` aur `-v` Options

### `-R` — Recursive

Specified directory aur us ke andar tamam files aur subdirectories ko process karta hai:

```text
/var/www/lawfirm.com/html/
├── index.html
├── css/
├── images/
└── js/
```

Agar `-R` na lagaya jaye to andar ke tamam contents recursively process nahi honge.

### `-v` — Verbose

Yeh display karta hai ke kin files ke contexts restore hue. Misal:

```text
Relabeled /var/www/lawfirm.com/html/index.html from user_tmp_t to httpd_sys_content_t
```

Agar tamam contexts pehle se sahi hon to `restorecon` koi output na bhi de sakta hai.

---

## 6. SELinux Context Verify Karein

### Website directory aur files check karein

```bash
ansible node1 -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

Output mein yeh type dekhein:

```text
httpd_sys_content_t
```

### Sirf index file check karein

```bash
ansible node1 -m command -a \
"ls -lZ /var/www/lawfirm.com/html/index.html"
```

### Context restore karne ke baad website test karein

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200"
```

HTTP status `200` ka matlab Nginx ne page successfully serve kar diya.

---

## 7. `restorecon` vs `chmod` vs `chown`

| Command | Kya change karta hai | Misal |
|---|---|---|
| `restorecon` | SELinux security context | `httpd_sys_content_t` |
| `chmod` | Standard file permissions | `0644`, `0755` |
| `chown` | File owner aur group | `root:root` |

Yeh teenon commands mukhtalif problems solve karti hain:

```bash
# SELinux context restore karein
restorecon -Rv /var/www/lawfirm.com/html

# Permissions set karein
chmod -R u=rwX,g=rX,o=rX /var/www/lawfirm.com/html

# Ownership set karein
chown -R root:root /var/www/lawfirm.com/html
```

`restorecon` ownership, standard permissions ya website content ko change nahi karta.

---

## 8. Expected Ansible Result

Agar files ko relabel karna zaroori ho to output is tarah aa sakta hai:

```text
node1 | CHANGED | rc=0 >>
Relabeled /var/www/lawfirm.com/html/index.html ...
```

| Field | Matlab |
|---|---|
| `CHANGED` | `command` module execute hua; yeh lazmi nahi ke label change hua ho |
| `rc=0` | Command successfully complete hui |
| `Relabeled ...` | File ka SELinux context asal mein correct hua |

`command` module run hone par aam tor par `CHANGED` report karta hai. Is liye command dobara chalane par bhi `CHANGED` aa sakta hai, chahe koi label change na hua ho.

### Playbook mein accurate change reporting

```yaml
- name: Restore SELinux contexts on website files
  command: restorecon -Rv /var/www/lawfirm.com/html
  register: restorecon_result
  changed_when: restorecon_result.stdout | length > 0
```

Is tarah task sirf us waqt `changed` report karega jab `restorecon -v` relabeling output produce kare.

---

## 9. Troubleshooting

### Website ab bhi `403 Forbidden` de

Nginx error log check karein:

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"
```

Path ke tamam directories ki permissions check karein:

```bash
ansible node1 -m command -a \
"namei -l /var/www/lawfirm.com/html/index.html"
```

SELinux context check karein:

```bash
ansible node1 -m command -a \
"ls -lZ /var/www/lawfirm.com/html/index.html"
```

### `restorecon` command na mile

```bash
ansible node1 -m command -a "which restorecon"
```

Rocky Linux mein yeh command SELinux utility package provide karta hai.

### Context dobara ghalat ho jaye

Expected policy context check karein:

```bash
ansible node1 -b -m command -a \
"matchpathcon /var/www/lawfirm.com/html/index.html"
```

Custom path ke liye persistent mapping maujood na ho to `semanage fcontext` se mapping define karein, phir `restorecon` chalayein.

---

## 10. Quick Summary

```bash
ansible node1 -b -m command -a \
"restorecon -Rv /var/www/lawfirm.com/html"
```

- Command sirf `node1` par chalti hai.
- `-b` ke zariye `sudo` use hota hai.
- SELinux contexts recursively restore hote hain.
- Nginx ko static website files read karne mein madad milti hai.
- Ownership, standard permissions aur website content change nahi hote.
- SELinux ki wajah se aane wale `403 Forbidden` ko solve karne mein madad mil sakti hai.
