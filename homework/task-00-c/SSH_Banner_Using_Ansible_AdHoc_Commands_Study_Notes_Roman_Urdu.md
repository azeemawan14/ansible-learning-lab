# Ansible Ad-Hoc Commands se SSH Banner — Study Notes (Roman Urdu)

Is lab mein hum suitable Ansible ad-hoc commands use karke `node1`, `node2` aur `node3` par SSH pre-login banner configure karenge.

Learning sequence:

```text
Ek node par manual configuration
              ↓
Tamam nodes par ad-hoc commands
              ↓
Handler ke saath reusable playbook
```

## Index

1. [Learning objectives](#1-learning-objectives)
2. [Lab environment](#2-lab-environment)
3. [Yeh suitable ad-hoc demonstration kyun hai?](#3-yeh-suitable-ad-hoc-demonstration-kyun-hai)
4. [Aham safety rules](#4-aham-safety-rules)
5. [Step 1 — Project directory mein jayein](#5-step-1--project-directory-mein-jayein)
6. [Step 2 — Connectivity verify karein](#6-step-2--connectivity-verify-karein)
7. [Step 3 — `copy` se banner banayein](#7-step-3--copy-se-banner-banayein)
8. [Step 4 — Banner inspect karein](#8-step-4--banner-inspect-karein)
9. [Step 5 — `lineinfile` se `sshd_config` configure karein](#9-step-5--lineinfile-se-sshd_config-configure-karein)
10. [Step 6 — SSH configuration validate karein](#10-step-6--ssh-configuration-validate-karein)
11. [Step 7 — Effective setting verify karein](#11-step-7--effective-setting-verify-karein)
12. [Step 8 — `sshd` reload aur verify karein](#12-step-8--sshd-reload-aur-verify-karein)
13. [Step 9 — Banner test karein](#13-step-9--banner-test-karein)
14. [Complete command sequence](#14-complete-command-sequence)
15. [Idempotency behavior](#15-idempotency-behavior)
16. [Ad-hoc commands vs playbook](#16-ad-hoc-commands-vs-playbook)
17. [Rollback](#17-rollback)
18. [Troubleshooting](#18-troubleshooting)
19. [Modules ka summary](#19-modules-ka-summary)
20. [Review questions](#20-review-questions)

---

## 1. Learning objectives

Is lab ke baad aap:

- Multiple managed nodes par SSH banner configure kar sakenge.
- Har operation ke liye suitable Ansible module select kar sakenge.
- `inventory_hostname` se har host ka customized banner bana sakenge.
- `sshd_config` ka backup aur safe validation kar sakenge.
- `reload` aur `restart` ka farq explain kar sakenge.
- Idempotent aur non-idempotent status behavior pehchan sakenge.
- Samajh sakenge ke repeatable automation ke liye playbook behtar kyun hai.

## 2. Lab environment

| Role | Host | IP address |
|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` |
| Managed node | `node1` | `192.168.1.154` |
| Managed node | `node2` | `192.168.1.185` |
| Managed node | `node3` | `192.168.1.190` |

Inventory group:

```text
three_tier_app
```

Remote user:

```text
ansibleadmin
```

Project directory:

```text
/home/ansibleadmin/automation
```

## 3. Yeh suitable ad-hoc demonstration kyun hai?

Is job ka har chhota operation ek suitable module ke saath naturally match hota hai:

| Requirement | Module | Wajah |
|---|---|---|
| Connectivity check | `ping` | Ansible connection aur Python availability test karta hai |
| Banner file banana | `copy` | Content, ownership aur permissions manage karta hai |
| File inspect karna | `command` / `stat` | Content ya metadata read karta hai |
| `sshd_config` edit karna | `lineinfile` | Ek configuration directive idempotently manage karta hai |
| SSH syntax validate karna | `command` | Shell ki zarurat ke baghair `sshd -t` chalata hai |
| Effective setting filter karna | `shell` | Pipe aur `grep` ke liye shell zaroori hai |
| Configuration apply karna | `service` | `sshd` reload karta hai |

Ad-hoc commands individual modules samajhne ke liye achhe hain. Repeated ya production automation ke liye playbook behtar hai.

## 4. Aham safety rules

- Apni current SSH session open rakhein.
- Final banner ko doosri terminal se test karein.
- `sshd_config` change karne se pehle backup banayein.
- Service reload karne se pehle configuration validate karein.
- Validation fail ho to `sshd` reload ya restart na karein.
- Is change ke liye `restart` ke bajaye `reload` prefer karein.
- Nayi command ko pehle sirf `node1` par test karein.

Sirf `node1` target karne ke liye:

```bash
--limit node1
```

## 5. Step 1 — Project directory mein jayein

```bash
cd /home/ansibleadmin/automation
```

Yeh important hai kyun ke current directory mein project wala `ansible.cfg` aur relative inventory path ho sakta hai.

Active configuration check karein:

```bash
ansible --version
ansible-config dump --only-changed
```

## 6. Step 2 — Connectivity verify karein

```bash
ansible three_tier_app -m ping
```

Har node se expected result:

```text
"ping": "pong"
```

Jab tak tamam intended nodes reachable na hon, SSH configuration modify na karein.

## 7. Step 3 — `copy` se banner banayein

Pehle `node1` par test karein:

```bash
ansible three_tier_app -b --limit node1 -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

`node1` verify karne ke baad tamam nodes par run karein:

```bash
ansible three_tier_app -b -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'
```

`inventory_hostname` har host ke liye uska inventory name use karega:

| Host | Banner line |
|---|---|
| `node1` | `Welcome to node1 — NIT Classes Ansible Lab` |
| `node2` | `Welcome to node2 — NIT Classes Ansible Lab` |
| `node3` | `Welcome to node3 — NIT Classes Ansible Lab` |

`copy` module file ka content, destination, owner, group aur mode manage karta hai.

## 8. Step 4 — Banner inspect karein

Content dekhein:

```bash
ansible three_tier_app -m command -a \
"cat /etc/ssh/banner.txt"
```

Metadata inspect karein:

```bash
ansible three_tier_app -m stat -a \
"path=/etc/ssh/banner.txt"
```

Expected important values:

```text
exists: true
mode: 0644
pw_name: root
gr_name: root
```

## 9. Step 5 — `lineinfile` se `sshd_config` configure karein

Pehle `node1` par test karein:

```bash
ansible three_tier_app -b --limit node1 -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Phir tamam managed nodes par run karein:

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Arguments ki explanation:

| Argument | Matlab |
|---|---|
| `path` | Woh file jise Ansible manage karega |
| `regexp` | Commented ya active `Banner` directive ko match karta hai |
| `line` | Exact required directive |
| `state=present` | Required line ko present rakhta hai |
| `backup=yes` | Change se pehle backup banata hai |
| `validate` | Live file replace karne se pehle temporary candidate validate karta hai |
| `%s` | Ansible ke temporary candidate file ka path |

Required final line:

```text
Banner /etc/ssh/banner.txt
```

Agar temporary configuration invalid ho to `validate` usay live configuration replace karne se rok deta hai.

## 10. Step 6 — SSH configuration validate karein

`lineinfile` validation ke bawajood separate demonstration karein:

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"
```

Expected result:

```text
rc=0
```

Aam tor par blank output ka matlab syntax valid hai. Error aaye to reload se pehle usay correct karein.

## 11. Step 7 — Effective setting verify karein

`sshd -T` effective server configuration dikhata hai. Pipe use ho rahi hai, is liye `shell` module chahiye:

```bash
ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"
```

Expected output:

```text
banner /etc/ssh/banner.txt
```

Yeh read-only verification hai, lekin ad-hoc `shell` successful hone par aam tor par `CHANGED` report karta hai.

## 12. Step 8 — `sshd` reload aur verify karein

Sirf successful validation ke baad reload karein:

```bash
ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"
```

`reload` prefer karne ki wajah:

- Service configuration dobara read karti hai.
- Full restart se kam disruptive hai.
- Existing SSH sessions aam tor par connected rehti hain.

Service verify karein:

```bash
ansible three_tier_app -m command -a \
"systemctl is-active sshd"
```

Expected output:

```text
active
```

## 13. Step 9 — Banner test karein

Original session open rakh kar doosri terminal se test karein:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1
ssh -i ~/.ssh/ansible-key ansibleadmin@node2
ssh -i ~/.ssh/ansible-key ansibleadmin@node3
```

Banner authentication complete hone se pehle nazar aana chahiye.

Detailed troubleshooting ke liye:

```bash
ssh -v -i ~/.ssh/ansible-key ansibleadmin@node1
```

## 14. Complete command sequence

```bash
cd /home/ansibleadmin/automation

ansible three_tier_app -m ping

ansible three_tier_app -b -m copy -a \
'content="**************************************************
WARNING: Authorized access only

Welcome to {{ inventory_hostname }} — NIT Classes Ansible Lab
All activities may be monitored.
**************************************************
" dest=/etc/ssh/banner.txt owner=root group=root mode=0644'

ansible three_tier_app -m command -a \
"cat /etc/ssh/banner.txt"

ansible three_tier_app -m stat -a \
"path=/etc/ssh/banner.txt"

ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="Banner /etc/ssh/banner.txt" state=present backup=yes validate="/usr/sbin/sshd -t -f %s"'

ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"

ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"

ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"

ansible three_tier_app -m command -a \
"systemctl is-active sshd"
```

## 15. Idempotency behavior

| Step | Idempotency/status behavior |
|---|---|
| `copy` | Content, owner, group aur mode pehle se correct hon to change report nahin karta |
| `lineinfile` | Correct directive pehle se ho to change report nahin karta |
| `stat` | Read-only module hai; system change nahin karta |
| `command` validation | Command execute karta hai; configuration state manage nahin karta |
| `shell` verification | Read-only hone ke bawajood aam tor par `CHANGED` report karta hai |
| `service state=reloaded` | Har requested reload ko aam tor par change report karta hai |

Idempotency demonstrate karne ke liye `copy` aur `lineinfile` commands do dafa run karein. Second run par aam tor par `changed=false` milna chahiye.

Ad-hoc workflow change result ko automatically conditional reload se connect nahin karta. Playbook handler yeh masla solve karta hai.

## 16. Ad-hoc commands vs playbook

| Feature | Ad-hoc commands | Playbook |
|---|---|---|
| Best use | Quick, one-time kaam | Repeatable automation |
| Multiple steps | Operator manually order mein chalata hai | YAML mein order save hota hai |
| Failure control | Failure ke baad operator ko rukna hota hai | Task flow control ki ja sakti hai |
| Conditional reload | Manual decision | Handler sirf notification par chalta hai |
| Documentation | Command history ya separate notes | Automation khud documentation banti hai |
| Reuse | Limited | High |
| Version control | Mushkil | Natural fit |

Recommended learning order:

```text
Manual method → Ad-hoc modules → Playbook → Handler → Role/AWX Job Template
```

## 17. Rollback

### Backup files dekhein

```bash
ansible three_tier_app -b -m shell -a \
"ls -1t /etc/ssh/sshd_config.*~ 2>/dev/null | head"
```

Restore karne se pehle backup filename aur content zaroor review karein.

### Banner directive disable karein

```bash
ansible three_tier_app -b -m lineinfile -a \
'path=/etc/ssh/sshd_config regexp="^\s*#?\s*Banner\s+.*$" line="#Banner none" backup=yes validate="/usr/sbin/sshd -t -f %s"'
```

Validate karein:

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t"
```

Reload karein:

```bash
ansible three_tier_app -b -m service -a \
"name=sshd state=reloaded"
```

Banner file remove karna ho to:

```bash
ansible three_tier_app -b -m file -a \
"path=/etc/ssh/banner.txt state=absent"
```

## 18. Troubleshooting

### Banner nazar nahin aa raha

```bash
ansible three_tier_app -b -m shell -a \
"/usr/sbin/sshd -T | grep '^banner '"

ansible three_tier_app -m command -a \
"ls -l /etc/ssh/banner.txt"
```

### Validation fail ho rahi hai

```bash
ansible three_tier_app -b -m command -a \
"/usr/sbin/sshd -t" -vv
```

Error resolve hone tak service reload na karein.

### Ek node unreachable hai

```bash
ansible node2 -m ping -vvvv
ssh -v -i ~/.ssh/ansible-key ansibleadmin@node2
```

### `sudo` password maang raha hai

```bash
ansible three_tier_app -m command -a \
"sudo -n whoami"
```

Expected output:

```text
root
```

### Multiple active Banner directives hain

```bash
ansible three_tier_app -b -m shell -a \
"grep -RniE '^[[:space:]]*Banner[[:space:]]+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null"
```

Final effective value ke liye `sshd -T` ko authority samjhein.

## 19. Modules ka summary

| Module | Is lab mein kaam |
|---|---|
| `ping` | Ansible connectivity verify karna |
| `copy` | `/etc/ssh/banner.txt` create aur manage karna |
| `command` | File display, SSH validation aur service-state check |
| `stat` | Banner file ka metadata inspect karna |
| `lineinfile` | `Banner` directive manage karna |
| `shell` | Pipes wali verification commands chalana |
| `service` | `sshd` reload karna |
| `file` | Rollback mein banner remove karna |

## 20. Review questions

1. Banner file banane ke liye `copy`, `shell` se behtar kyun hai?
2. `inventory_hostname` kya value deta hai?
3. `lineinfile` mein `regexp` kya karta hai?
4. `backup=yes` kyun useful hai?
5. Validation command mein `%s` kis cheez ko represent karta hai?
6. `sshd -t` ka blank output aam tor par kya batata hai?
7. `sshd -T | grep ...` ke liye `shell` kyun use hua?
8. `restart` ke bajaye `reload` kyun prefer kiya gaya?
9. Kaun se steps idempotency demonstrate karte hain?
10. Separate ad-hoc reload ke muqablay mein handler kyun behtar hai?

---

## Final recommendation

Ad-hoc lab ko individual modules samajhne ke liye use karein. Regular administration ke liye playbook ko authoritative automation rakhein, kyun ke playbook changes validate karke handler ko sirf zarurat ke waqt `sshd` reload karne ke liye notify kar sakti hai.
