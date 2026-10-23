# Ansible se `/tmp` Cleanup by Owner — Study Notes (Roman Urdu)

Yeh guide explain karti hai ke Ansible ke zariye managed nodes ke `/tmp` ke andar mojood `ansibleadmin` ki milkiyat wali files aur directories ko safely kaise find, preview, delete aur verify karna hai.

> **Warning:** Deletion destructive hoti hai. Delete command chalane se pehle exact targets ka preview zaroor dekhein. Delete ki hui files automatically recover nahin hotin.

## Index

1. [Maqsad](#1-maqsad)
2. [Cleanup mein ehtiyat kyun zaroori hai?](#2-cleanup-mein-ehtiyat-kyun-zaroori-hai)
3. [`/tmp` entries ko samajhna](#3-tmp-entries-ko-samajhna)
4. [Safe preview-first workflow](#4-safe-preview-first-workflow)
5. [Tamam matching files aur folders delete karna](#5-tamam-matching-files-aur-folders-delete-karna)
6. [Sirf directories delete karna](#6-sirf-directories-delete-karna)
7. [Sirf regular files delete karna](#7-sirf-regular-files-delete-karna)
8. [Ansible payload ko exclude kyun karte hain?](#8-ansible-payload-ko-exclude-kyun-karte-hain)
9. [Payload create kiye baghair verification](#9-payload-create-kiye-baghair-verification)
10. [`find` command ki line-by-line explanation](#10-find-command-ki-line-by-line-explanation)
11. [`CHANGED` status kyun nazar aata hai?](#11-changed-status-kyun-nazar-aata-hai)
12. [`file` module se exact-path cleanup](#12-file-module-se-exact-path-cleanup)
13. [Reusable cleanup playbook](#13-reusable-cleanup-playbook)
14. [`/tmp` permissions aur sticky bit](#14-tmp-permissions-aur-sticky-bit)
15. [Kin directories ko manually remove nahin karna?](#15-kin-directories-ko-manually-remove-nahin-karna)
16. [Troubleshooting](#16-troubleshooting)
17. [Safety checklist](#17-safety-checklist)
18. [Quick command reference](#18-quick-command-reference)
19. [Rozana midnight Central Time par cleanup schedule karna](#19-rozana-midnight-central-time-par-cleanup-schedule-karna)

---

## 1. Maqsad

Maqsad managed nodes se `ansibleadmin` ki temporary lab files aur directories remove karna hai, lekin in cheezon ko preserve karna hai:

- `/tmp` directory khud.
- Root-owned system service directories.
- Ansible ki current active module-payload directory.
- Doosre users ki files.

Remove hone wali example directories:

```text
/tmp/ansible-share
/tmp/ansible-lab
/tmp/ansible_ifrah_lab
/tmp/ansible_lab_ibrahim
```

Ansible command ke dauran exclude ki jane wali example directory:

```text
/tmp/ansible_ansible.legacy.command_payload_r1aihnnt
```

---

## 2. Cleanup mein ehtiyat kyun zaroori hai?

`/tmp` aik shared directory hai. Isay users, applications aur system services sab use karte hain.

Yeh command bohat broad aur dangerous hai:

```bash
rm -rf /tmp/*
```

Yeh ghalti se remove kar sakti hai:

- Doosre users ki temporary files.
- Application runtime data.
- Service-private directories.
- Active sockets ya temporary state.
- Running processes ki required files.

Safe method mein hum:

- Sirf `/tmp` ke andar search karte hain.
- `/tmp` ko khud select nahin karte.
- Sirf `/tmp` ke direct children check karte hain.
- Sirf `ansibleadmin` ki ownership wali entries select karte hain.
- Active Ansible payload ko exclude karte hain.
- Delete karne se pehle preview dekhte hain.

---

## 3. `/tmp` entries ko samajhna

Tamam inventory hosts par listing dekhein:

```bash
ansible all -m command -a "ls -la /tmp"
```

Common categories:

| Entry | Owner | Meaning | Action |
|---|---|---|---|
| `ansible-lab` | `ansibleadmin` | Practice directory | Kaam ke baad remove ki ja sakti hai |
| `ansible-share` | `ansibleadmin` | Shared lab directory | Zaroorat na ho to remove karein |
| `ansible_*payload*` | `ansibleadmin` | Current Ansible module payload | Jaan boojh kar remove na karein |
| `systemd-private-*` | `root` | Service ki private temporary directory | Isay chhor dein |
| `/tmp` | `root` | Shared temporary directory | Kabhi remove na karein |

Long listing mein owner aur group nazar aate hain:

```text
drwxr-xr-x. 2 ansibleadmin ansibleadmin 6 Sep 17 14:53 ansible_ifrah_lab
```

Pehla `ansibleadmin` owner hai aur doosra group hai.

---

## 4. Safe preview-first workflow

### Step 1: `ansibleadmin` ki direct entries ka preview

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

Possible output:

```text
/tmp/ansible-share
/tmp/ansible-lab
/tmp/ansible_ifrah_lab
/tmp/ansible_lab_ibrahim
```

Har managed node ka output carefully review karein.

### Step 2: Unexpected path nazar aaye to ruk jayein

Delete command na chalayein agar preview mein:

- Koi required file ho.
- `/tmp` ke bahar ka path ho.
- Service directory ho.
- Doosre user ka data ho.
- Unexpected mount point ya symbolic link ho.

### Step 3: Sirf verification ke baad delete karein

Preview correct ho to aglay section ki delete command use karein.

---

## 5. Tamam matching files aur folders delete karna

Yeh command `/tmp` ke direct children mein se `ansibleadmin` ki ownership wali files, directories aur symbolic links remove karti hai, lekin active Ansible payload ko exclude karti hai:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

Expected result:

```text
node1 | CHANGED | rc=0 >>
node2 | CHANGED | rc=0 >>
node3 | CHANGED | rc=0 >>
```

Meaning:

- `rc=0` ka matlab command successfully complete hui.
- Blank output normal hai kyun ke successful `rm` aam tor par kuch print nahin karta.
- `CHANGED` shell module ka default status hai.

### `-b` kyun use hua?

```text
-b
```

Privilege escalation enable karta hai. Owner apni `/tmp` entries aksar khud bhi remove kar sakta hai, lekin root privileges nodes par behavior ko consistent banati hain. Selection phir bhi sirf `ansibleadmin` ki entries tak limited hai.

---

## 6. Sirf directories delete karna

Pehle sirf directories ka preview:

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -print'
```

Output verify karne ke baad delete karein:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

`-type d` sirf directories select karta hai.

---

## 7. Sirf regular files delete karna

Regular files ka preview:

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -print'
```

Matching regular files delete karein:

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -delete'
```

`-type f` sirf regular files select karta hai, directories nahin.

Ownership ka matlab yeh nahin ke file zaroor unnecessary hai. Is liye preview phir bhi lazmi hai.

---

## 8. Ansible payload ko exclude kyun karte hain?

Jab `command` ya `shell` module run hota hai, Ansible aam tor par:

1. SSH se managed node par connect karta hai.
2. Temporary directory banata hai.
3. Module payload transfer karta hai.
4. Module execute karta hai.
5. Result collect karta hai.
6. Temporary payload remove karta hai.

Example:

```text
/tmp/ansible_ansible.legacy.command_payload_mvtaoouj
```

Random suffix har command ke saath badal sakta hai. Isi liye har nayi Ansible command aik naya payload dikha sakti hai.

Exclusion condition:

```bash
! -name "ansible_*payload*"
```

Is ka matlab:

- `!` = NOT
- `-name` = filename pattern match karna
- Quoted pattern local shell ke bajaye `find` ko diya jata hai

Active payload ko delete karne se current Ansible operation fail ho sakti hai.

---

## 9. Payload create kiye baghair verification

### Option 1: `raw` module

`raw` module direct SSH command chalata hai aur aam tor par Python module payload transfer nahin karta:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

Payload-style entries ko ignore karna ho:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

Agar koi path list na ho to intended cleanup complete hai.

### Option 2: Direct SSH

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node1 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

Baaki nodes:

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@node2 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'

ssh -i ~/.ssh/ansible-key ansibleadmin@node3 \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin -print'
```

---

## 10. `find` command ki line-by-line explanation

```bash
find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin \
! -name "ansible_*payload*" -exec rm -rf -- {} +
```

| Part | Roman Urdu meaning |
|---|---|
| `find /tmp` | Search `/tmp` se start karo |
| `-mindepth 1` | `/tmp` ko khud select na karo |
| `-maxdepth 1` | Sirf `/tmp` ke direct children select karo |
| `-user ansibleadmin` | Sirf `ansibleadmin` ki ownership wali entries |
| `!` | Agli condition ka ulat, yani NOT |
| `-name "ansible_*payload*"` | Ansible payload name pattern |
| `-exec` | Har matched path par command chalao |
| `rm -rf` | Selected entry ko recursively aur forcefully remove karo |
| `--` | `rm` options yahan khatam; `-` se shuru filename bhi path samjha jaye |
| `{}` | `find` se milne wale paths ka placeholder |
| `+` | Multiple paths ko kam `rm` executions mein pass karo |

### Dono depth options kyun important hain?

`-mindepth 1` starting directory `/tmp` ko selection se bachata hai. `-maxdepth 1` nested content mein recursive selection ke bajaye sirf top-level entries tak scope limit karta hai.

---

## 11. `CHANGED` status kyun nazar aata hai?

Read-only command:

```bash
ansible all -m shell -a "find /tmp -maxdepth 1 -print"
```

Phir bhi yeh return kar sakti hai:

```text
node1 | CHANGED | rc=0
```

Ad-hoc `shell` aur `command` modules arbitrary command ka actual system change automatically determine nahin karte, is liye aam tor par `CHANGED` report karte hain.

- `CHANGED` ka matlab yeh zaroori nahin ke preview ne koi file badli.
- `rc=0` ka matlab command successful thi.
- Actual effect command aur output dekh kar samjhein.

Playbook mein inspection task ko read-only mark karein:

```yaml
changed_when: false
```

Ad-hoc command ke liye general `--changed-when=false` option nahin hota.

---

## 12. `file` module se exact-path cleanup

Jab exact paths maloom hon to owner-based broad command ke bajaye `file` module zyada clear aur safe hai.

```bash
ansible web -b -m file \
-a "path=/tmp/ansible_ifrah_lab state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible-lab state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible_lab_ibrahim state=absent"

ansible web -b -m file \
-a "path=/tmp/ansible-share state=absent"
```

`state=absent` ka matlab hai ke path exist nahin karna chahiye. Agar path pehle se absent ho to Ansible unnecessary change nahin karega.

| Situation | Recommended method |
|---|---|
| Exact paths maloom hain | `file` module use karein |
| Bohat se unknown paths same owner ke hain | Pehle `find` preview, phir limited cleanup |
| Production | Approved path list, retention policy aur tested playbook |

---

## 13. Reusable cleanup playbook

Yeh playbook matching entries find karti hai, display karti hai, confirmation leti hai aur phir selected list remove karti hai.

```bash
vim cleanup-ansibleadmin-tmp.yml
```

```yaml
---
- name: Safely clean ansibleadmin entries from tmp
  hosts: all
  become: true

  tasks:
    - name: Find direct tmp entries owned by ansibleadmin
      shell: >
        find /tmp
        -mindepth 1
        -maxdepth 1
        -user ansibleadmin
        ! -name 'ansible_*payload*'
        -print
      register: cleanup_targets
      changed_when: false

    - name: Display cleanup targets
      debug:
        var: cleanup_targets.stdout_lines

    - name: Confirm cleanup
      pause:
        prompt: "Displayed paths review karein. Delete ke liye Enter, abort ke liye Ctrl+C phir A"
      run_once: true

    - name: Remove approved cleanup targets
      file:
        path: "{{ item }}"
        state: absent
      loop: "{{ cleanup_targets.stdout_lines }}"
      when: cleanup_targets.stdout_lines | length > 0
```

Syntax check:

```bash
ansible-playbook --syntax-check cleanup-ansibleadmin-tmp.yml
```

Run:

```bash
ansible-playbook cleanup-ansibleadmin-tmp.yml
```

Pehli dafa sirf `node1` par test karna behtar hai:

```bash
ansible-playbook cleanup-ansibleadmin-tmp.yml --limit node1
```

Production mein `--limit`, `serial`, change approval, backups aur tested retention policy use karein.

---

## 14. `/tmp` permissions aur sticky bit

Typical `/tmp` permissions:

```text
drwxrwxrwt
```

Numeric form:

```text
1777
```

| Part | Meaning |
|---|---|
| Owner `rwx` | Owner read, write aur directory enter kar sakta hai |
| Group `rwx` | Group read, write aur enter kar sakta hai |
| Others `rwx` | Doosre users read, write aur enter kar sakte hain |
| Last `t` | Sticky bit |

Sticky bit ki wajah se ordinary user doosre user ki files delete nahin kar sakta, chahe `/tmp` world-writable ho.

Aam tor par entry remove kar sakte hain:

- Entry ka owner.
- Directory ka owner.
- Root.

Permissions verify karein:

```bash
ansible all -m command -a "stat -c '%A %a %U:%G %n' /tmp"
```

Expected format:

```text
drwxrwxrwt 1777 root:root /tmp
```

---

## 15. Kin directories ko manually remove nahin karna?

Examples:

```text
systemd-private-*-chronyd.service-*
systemd-private-*-dbus-broker.service-*
systemd-private-*-httpd.service-*
systemd-private-*-nginx.service-*
systemd-private-*-mariadb.service-*
systemd-private-*-systemd-logind.service-*
```

Yeh root-owned directories `systemd` services ko private temporary storage deti hain.

Corresponding services ke run hone ke dauran inhein manually remove na karein. In ka lifecycle `systemd` ko manage karne dein.

Owner-based cleanup inhein select nahin karti kyun ke in ka owner `root` hota hai, `ansibleadmin` nahin.

---

## 16. Troubleshooting

### Command ka output blank hai

Mumkin hai koi matching entry nahin hai. Username aur scope verify karein:

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -printf "%u %y %p\n"'
```

### Permission denied

Privilege escalation use karein:

```bash
ansible all -b -m shell -a '...'
```

Sudo test:

```bash
ansible all -m command -a "sudo -n whoami"
```

Expected:

```text
root
```

### Payload directory abhi bhi dikh rahi hai

Har `command` ya `shell` execution naya payload create kar sakti hai. Final verification ke liye `raw` ya direct SSH use karein.

### Deleted path dobara chahiye

`rm -rf` aur `state=absent` ka automatic undo nahin hota. Data ko in sources se restore karna hoga:

- Backup.
- Source repository.
- VM snapshot.
- Deployment process jo file dobara create kare.

### Preview mein bohat zyada entries aa rahi hain

Delete na karein. Selector ko narrow karein:

```text
-type f
-type d
-name 'ansible-lab*'
-mtime +7
-path '/tmp/specific-name'
```

Nayi selector ko bhi pehle preview karein.

---

## 17. Safety checklist

Cleanup se pehle:

- [ ] Correct inventory aur host pattern confirm karein.
- [ ] Pehli dafa `--limit node1` se test karein.
- [ ] Search path `/tmp` ho, `/` nahin.
- [ ] `-mindepth 1` zaroor ho.
- [ ] Top-level scope ke liye `-maxdepth 1` ho.
- [ ] Owner exactly `ansibleadmin` ho.
- [ ] Active Ansible payload exclude ho.
- [ ] Preview command pehle run ho.
- [ ] Har host ka output review ho.
- [ ] Required data ka backup ho ya usay recreate kiya ja sakta ho.

Cleanup ke baad:

- [ ] Har node par `rc=0` confirm karein.
- [ ] `raw` module ya direct SSH se verify karein.
- [ ] `/tmp` ka mode `1777` confirm karein.
- [ ] Root-owned `systemd-private-*` directories ko chhor dein.
- [ ] Cleanup ko lab notes ya change record mein document karein.

---

## 18. Quick command reference

### Tamam direct entries ka preview

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### Matching files aur folders delete karein

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

### Sirf directories ka preview

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### Sirf directories delete karein

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type d -user ansibleadmin ! -name "ansible_*payload*" -exec rm -rf -- {} +'
```

### Sirf regular files ka preview

```bash
ansible all -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -print'
```

### Sirf regular files delete karein

```bash
ansible all -b -m shell -a \
'find /tmp -mindepth 1 -maxdepth 1 -type f -user ansibleadmin -delete'
```

### `raw` se verification

```bash
ansible all -m raw -a \
'find /tmp -mindepth 1 -maxdepth 1 -user ansibleadmin ! -name "ansible_*payload*" -print'
```

### `/tmp` permissions check karein

```bash
ansible all -m command -a \
"stat -c '%A %a %U:%G %n' /tmp"
```

## 19. Rozana midnight Central Time par cleanup schedule karna

Ansible control node par `cron` ke zariye cleanup playbook rozana schedule ki ja sakti hai. Sirf `CST` likhne ke bajaye `America/Chicago` timezone use karein, kyun ke Chicago mein:

- Standard time ke dauran CST hota hai.
- Daylight-saving time ke dauran CDT hota hai.

`America/Chicago` dono ko automatically handle karta hai. Is liye `0 0 * * *` poore saal current Chicago local time ke mutabiq raat 12:00 baje chalega.

> **Important:** Scheduled cleanup kisi student ka active kaam delete kar sakti hai. Maintenance window pehle announce karein aur sirf known lab-directory patterns ko target karein.

### Step 1: Safer scheduled-cleanup playbook banayein

Playbook banayein:

```bash
mkdir -p /home/ansibleadmin/automation/playbooks
vim /home/ansibleadmin/automation/playbooks/cleanup-tmp.yml
```

Yeh content add karein:

```yaml
---
- name: Remove temporary Ansible lab directories
  hosts: three_tier_app
  become: true

  tasks:
    - name: Find known lab directories owned by ansibleadmin
      find:
        paths: /tmp
        file_type: directory
        recurse: false
        owner: ansibleadmin
        patterns:
          - "ansible-*"
          - "ansible_*_lab"
          - "ansible_lab_*"
          - "ansible-share"
        excludes:
          - "ansible_*payload*"
      register: scheduled_lab_directories

    - name: Remove the matched lab directories
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ scheduled_lab_directories.files }}"
      loop_control:
        label: "{{ item.path }}"
```

Yeh version sirf matching top-level directories remove karti hai. Yeh `ansibleadmin` ki har file delete nahin karti aur Ansible payload directories ko explicitly exclude karti hai.

### Step 2: Validate aur manually test karein

```bash
cd /home/ansibleadmin/automation
ansible-playbook --syntax-check playbooks/cleanup-tmp.yml
ansible-playbook playbooks/cleanup-tmp.yml --check --diff --limit node1
```

Output ko carefully review karein. Check-mode ka result correct ho to pehle ek controlled run karein:

```bash
ansible-playbook playbooks/cleanup-tmp.yml --limit node1
```

Phir tamam managed nodes par test karein:

```bash
ansible-playbook playbooks/cleanup-tmp.yml
```

### Step 3: Cron service confirm karein

```bash
sudo systemctl enable --now crond
sudo systemctl status crond
```

### Step 4: Cron job banayein

`sudo` ke baghair `ansibleadmin` user ka crontab edit karein:

```bash
crontab -e
```

Yeh lines add karein:

```cron
CRON_TZ=America/Chicago
0 0 * * * cd /home/ansibleadmin/automation && /usr/bin/flock -n /tmp/ansible-cleanup.lock /usr/bin/ansible-playbook playbooks/cleanup-tmp.yml >> /home/ansibleadmin/automation/cleanup-tmp.log 2>&1
```

Cron fields ka matlab:

| Field | Value | Matlab |
|---|---:|---|
| Minute | `0` | Zero minute par |
| Hour | `0` | Raat 12:00 baje |
| Day of month | `*` | Mahine ke har din |
| Month | `*` | Har mahine |
| Day of week | `*` | Haftay ke har din |

Command ke parts:

| Hissa | Maqsad |
|---|---|
| `cd /home/ansibleadmin/automation` | Project wala `ansible.cfg` discover hota hai aur relative paths sahi resolve hotay hain |
| `/usr/bin/flock -n ...` | Pehla cleanup abhi chal raha ho to doosra run start nahin hota |
| `/usr/bin/ansible-playbook` | Cron ke limited environment mein absolute executable path use hota hai |
| `>> cleanup-tmp.log` | Normal output log ke end mein append hota hai |
| `2>&1` | Errors bhi isi log file mein save hotay hain |

### Step 5: Schedule aur logs verify karein

```bash
crontab -l
timedatectl
tail -n 100 /home/ansibleadmin/automation/cleanup-tmp.log
sudo journalctl -u crond --since today --no-pager
```

Pehle scheduled run se pehle cleanup log ka empty ya absent hona normal hai.

### Optional: Midnight ka wait kiye baghair cron test karein

Temporary taur par har minute ek non-destructive command schedule karein:

```cron
* * * * * /usr/bin/date >> /home/ansibleadmin/automation/cron-test.log 2>&1
```

Jab confirm ho jaye ke `cron-test.log` update ho rahi hai to test entry remove kar dein. Destructive cleanup schedule ko har minute par change na karein.

### Scheduled-cleanup safety checklist

- Playbook ko pehle `--check`, `--diff` aur `--limit node1` ke saath test karein.
- Owner ki har cheez delete karne ke bajaye known directory-name patterns use karein.
- `ansible_*payload*` ko excluded rakhein.
- `/tmp/*`, `systemd-private-*` ya root-owned service directories ko target na karein.
- Confirm karein ke SSH keys aur passwordless sudo non-interactively kaam karte hain.
- Lab users ko midnight maintenance window pehle bata dein.
- Pehle automatic run ke baad `cleanup-tmp.log` review karein.
- Inventory ya playbook mein major changes se pehle cron entry disable kar dein.

## Final recommendation

Hamesha yeh sequence follow karein:

```text
Preview → Har host ka review → Delete → raw/SSH se verify → Change record karein
```

Jab exact paths maloom hon to Ansible `file` module ke saath `state=absent` ko preference dein. Owner-based `find` cleanup sirf clearly defined scope ke liye use karein. `rm -rf /tmp/*` jaisi broad command kabhi use na karein.
