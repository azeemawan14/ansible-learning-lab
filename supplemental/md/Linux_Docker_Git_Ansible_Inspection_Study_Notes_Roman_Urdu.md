# Linux, Docker, Git aur Ansible Inspection — Study Notes

> **Language:** Roman Urdu with English technical terms  
> **Purpose:** Hands-on practice, troubleshooting aur interview revision

---

## Table of Contents

1. [Important Note About `svg`](#1-important-note-about-svg)
2. [Exercise 1 — System Baseline](#2-exercise-1--system-baseline)
   - [`df -h` — Disk Usage](#21-df--h--disk-usage)
   - [`free -h` — Memory and Swap](#22-free--h--memory-and-swap)
   - [`uptime` — Uptime and Load Average](#23-uptime--uptime-and-load-average)
   - [`ps -ef | head` — Process List](#24-ps--ef--head--process-list)
   - [`sudo ss -tlnp` — Listening Ports](#25-sudo-ss--tlnp--listening-ports)
   - [Recommended Baseline Workflow](#26-recommended-baseline-workflow)
3. [Exercise 2 — Docker Inspection](#3-exercise-2--docker-inspection)
   - [`docker ps` — Running Containers](#31-docker-ps--running-containers)
   - [`docker ps -a` — All Containers](#32-docker-ps--a--all-containers)
   - [Why `docker ps -a` Is More Useful During Failure](#33-why-docker-ps--a-is-more-useful-during-failure)
   - [`docker images` — Local Images](#34-docker-images--local-images)
   - [`docker volume ls` — Persistent Volumes](#35-docker-volume-ls--persistent-volumes)
   - [`docker network ls` — Docker Networks](#36-docker-network-ls--docker-networks)
   - [Docker Failure Workflow](#37-docker-failure-workflow)
4. [Exercise 3 — Git Branch Practice](#4-exercise-3--git-branch-practice)
   - [`git status`](#41-git-status)
   - [`git switch -c lesson-01`](#42-git-switch--c-lesson-01)
   - [`git branch --show-current`](#43-git-branch---show-current)
   - [Complete Git Practice](#44-complete-git-practice)
5. [Exercise 4 — Ansible Connection Test](#5-exercise-4--ansible-connection-test)
   - [Example Inventory](#51-example-inventory)
   - [`ansible all --list-hosts`](#52-ansible-all---list-hosts)
   - [Ansible Ping Module](#53-ansible-ping-module)
   - [Ansible Setup/Facts Module](#54-ansible-setupfacts-module)
   - [Recommended Ansible Testing Order](#55-recommended-ansible-testing-order)
6. [Quick Revision Table](#6-quick-revision-table)
7. [Practice Questions](#7-practice-questions)
8. [Interview Summary](#8-interview-summary)

---

# 1. Important Note About `svg`

Practice commands ke end mein agar yeh word nazar aaye:

```bash
svg
```

to isay terminal mein run na karein. `svg` in exercises ka Linux command nahi hai. Yeh document formatting ki mistake lagti hai.

---

# 2. Exercise 1 — System Baseline

**System baseline** ka matlab system ki current health ka initial snapshot lena hai. Hum disk, memory, load, processes aur listening ports check karte hain. Baad mein problem aaye to current state ko normal baseline ke saath compare kar sakte hain.

## 2.1 `df -h` — Disk Usage

```bash
df -h
```

### Yeh kya check karti hai?

Mounted filesystems ki total, used aur available disk space dikhati hai.

- `df` = disk filesystem usage
- `-h` = human-readable units, jaise MB aur GB

### Example output

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        50G   31G   19G  63% /
/dev/sda1       960M  250M  710M  27% /boot
```

### Important fields

| Field | Meaning |
|---|---|
| `Size` | Filesystem ka total size |
| `Used` | Kitni storage use ho chuki hai |
| `Avail` | Kitni storage available hai |
| `Use%` | Percentage mein disk usage |
| `Mounted on` | Filesystem kis directory par mounted hai |

**Sab se important:** `Use%` aur `Mounted on` ko saath dekhein.

### Normal example

```text
/dev/sda2   50G   31G   19G   63%   /
```

Root filesystem 63% used hai; aam tor par yeh acceptable hai.

### Abnormal example

```text
/dev/sda2   50G   50G   100M   100%   /
```

Root filesystem full hone par:

- Applications files create nahi kar sakti.
- Logs write hona band ho sakte hain.
- Database fail ho sakta hai.
- Services crash ho sakti hain.

### Next troubleshooting commands

```bash
du -xhd1 / | sort -h
du -xhd1 /var | sort -h
df -i
```

`df -i` inode usage check karta hai. Kabhi storage available hoti hai, lekin bohat zyada small files ki wajah se inodes 100% ho jate hain.

---

## 2.2 `free -h` — Memory and Swap

```bash
free -h
```

### Yeh kya check karti hai?

System ki RAM aur swap usage dikhati hai.

### Example output

```text
               total        used        free      shared  buff/cache   available
Mem:            15Gi        5.2Gi       1.1Gi       500Mi       8.7Gi       9.2Gi
Swap:          2.0Gi        200Mi       1.8Gi
```

### Important fields

| Field | Meaning |
|---|---|
| `total` | Total installed memory |
| `used` | Currently used memory |
| `free` | Bilkul unused memory |
| `buff/cache` | Cache aur buffers ke liye RAM |
| `available` | New programs ke liye realistically available memory |
| `Swap used` | Swap mein kitna data mojood hai |

**Sab se important:** Sirf `free` nahi, `available` memory dekhein.

Linux unused RAM ko cache ke liye use karta hai. Is liye low `free` RAM hamesha problem nahi hoti.

### Normal interpretation

```text
free = 1.1Gi
available = 9.2Gi
```

`free` kam hai, lekin `available` 9.2 GiB hai. System par memory pressure nahi hai.

### Abnormal example

```text
        total   used   used    free    available
Mem:    15Gi    14Gi   100Mi   500Mi   300Mi
Swap:   2.0Gi   1.9Gi  100Mi
```

Warning signs:

- Available memory bohat kam hai.
- Swap almost full hai.
- System slow ho sakta hai.
- Kernel OOM killer process terminate kar sakta hai.

### Important swap concept

Swap used hona akela proof nahi ke current RAM shortage hai. Kernel purane inactive pages swap mein rehne de sakta hai. Current pressure samajhne ke liye `available`, `vmstat` ke `si/so`, application behavior aur logs dekhein.

```bash
vmstat 1
```

- `si` = swap in
- `so` = swap out

OOM messages:

```bash
sudo journalctl -k | grep -iE 'oom|out of memory'
```

---

## 2.3 `uptime` — Uptime and Load Average

```bash
uptime
```

### Yeh kya check karti hai?

- System kitni der se running hai
- Kitne login sessions active hain
- 1, 5 aur 15 minutes ka load average

### Example output

```text
14:30:10 up 12 days, 3:25, 2 users, load average: 0.25, 0.40, 0.35
```

### Output breakdown

| Part | Meaning |
|---|---|
| `14:30:10` | Current system time |
| `up 12 days` | System 12 din se running hai |
| `2 users` | Do login sessions active hain |
| `0.25` | Last 1 minute load |
| `0.40` | Last 5 minutes load |
| `0.35` | Last 15 minutes load |

### Load ko CPU count ke saath compare karein

```bash
nproc
```

Agar `nproc` ka output `4` ho:

- Load `1.00` → capacity available hai.
- Load `4.00` → system ke 4 logical CPUs roughly fully occupied hain.
- Load `8.00` → kaam CPU ya uninterruptible I/O ke liye queue mein wait kar sakta hai.

Load average sirf CPU usage nahi hota; Linux mein runnable aur uninterruptible tasks bhi load mein count hote hain.

### Abnormal example

```text
load average: 12.50, 10.20, 8.70
```

Agar sirf 4 CPUs hain, to load high hai. `1-minute > 5-minute > 15-minute` ka pattern batata hai ke recent load barh raha hai.

### Next commands

```bash
top
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head
vmstat 1
```

---

## 2.4 `ps -ef | head` — Process List

```bash
ps -ef | head
```

### Command breakdown

- `ps -ef` sab running processes detailed format mein dikhata hai.
- `|` pehli command ka output doosri command ko deta hai.
- `head` sirf first 10 lines dikhata hai.

### Example output

```text
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 09:20 ?        00:00:03 /usr/lib/systemd/systemd
root         641       1  0 09:20 ?        00:00:01 /usr/sbin/sshd -D
```

### Important fields

| Field | Meaning |
|---|---|
| `UID` | Process kis user ke under run ho raha hai |
| `PID` | Process ID |
| `PPID` | Parent process ID |
| `C` | CPU utilization indicator |
| `STIME` | Process start time |
| `TIME` | Accumulated CPU time |
| `CMD` | Process command |

### Important limitation

`ps -ef | head` highest CPU ya memory processes nahi dikhata; sirf process list ki first lines dikhata hai.

High ***CPU*** processes:

```bash
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head
```

High-***memory*** processes:

```bash
ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head
```

### Abnormal example

```text
PID   USER   COMMAND   %CPU   %MEM
8321  app    java      395.0  72.0
```

Java process nearly 4 CPU cores aur 72% memory use kar raha hai. Lekin sirf number dekh kar process kill na karein—pehle application, workload, logs aur business impact confirm karein.

---

## 2.5 `sudo ss -tlnp` — Listening Ports

```bash
sudo ss -tlnp
```

### Yeh kya check karti hai?

TCP listening ports aur unhein own karne wale processes dikhati hai.

| Option | Meaning |
|---|---|
| `-t` | TCP sockets |
| `-l` | Sirf listening sockets |
| `-n` | Numeric IP addresses aur ports |
| `-p` | Process/PID information |

### Example output

```text
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      128    0.0.0.0:22          0.0.0.0:*     users:(("sshd",pid=641,fd=3))
LISTEN 0      511    0.0.0.0:80          0.0.0.0:*     users:(("nginx",pid=920,fd=6))
LISTEN 0      4096   127.0.0.1:5432      0.0.0.0:*     users:(("postgres",pid=980,fd=7))
```

### Address meanings

| Address | Meaning |
|---|---|
| `0.0.0.0:80` | Port 80 tamam IPv4 interfaces par listening |
| `127.0.0.1:5432` | Port sirf local machine se accessible |
| `[::]:22` | IPv6 interfaces par listening; configuration ke mutabiq IPv4 bhi ho sakta hai |

### Abnormal cases

**Expected port missing:** Nginx running hona chahiye, lekin port 80/443 absent hai.

```bash
sudo systemctl status nginx
sudo journalctl -u nginx --since '15 minutes ago'
```

**Unexpected exposure:**

```text
0.0.0.0:5432
```

Agar database ko sirf local application use karti hai, to public interfaces par listen karna security concern ho sakta hai.

**Port conflict:**

```text
Address already in use
```

```bash
sudo ss -tlnp | grep ':80'
```

---

## 2.6 Recommended Baseline Workflow

```bash
df -h
df -i
free -h
uptime
nproc
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head
ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head
sudo ss -tlnp
```

Is workflow se hum poochte hain:

1. Disk ya inodes full hain?
2. Available memory kam hai?
3. Load CPU capacity se zyada hai?
4. Kaunsa process resources use kar raha hai?
5. Required port listen kar raha hai?

---

# 3. Exercise 2 — Docker Inspection

## 3.1 `docker ps` — Running Containers

```bash
docker ps
```

Sirf **currently running** containers dikhata hai.

```text
CONTAINER ID   IMAGE          STATUS         PORTS                  NAMES
a31bc92df521   nginx:latest   Up 10 minutes  0.0.0.0:8080->80/tcp   web
```
[For more explanation, click here](./Docker-Port-Mapping-Study-Notes-Roman-Urdu.md)

| Field | Meaning |
|---|---|
| `CONTAINER ID` | Container ka short ID |
| `IMAGE` | Container kis image se bana |
| `STATUS` | Current state aur duration |
| `PORTS` | Host-to-container port mapping |
| `NAMES` | Container name |

Agar sirf headings aayein, koi container currently running nahi hai. Is ka matlab yeh nahi ke container create hi nahi hua.

---

## 3.2 `docker ps -a` — All Containers

```bash
docker ps -a
```

Running, stopped, failed aur created—tamam containers dikhata hai.

```text
CONTAINER ID   IMAGE          STATUS                     NAMES
a31bc92df521   nginx:latest   Up 10 minutes              web
cb14ef128920   myapp:1.0      Exited (1) 20 seconds ago  backend
d78ef731a221   postgres:16    Exited (137) 1 minute ago  database
```

### Common states and exit codes

| Status | Possible meaning |
|---|---|
| `Up` | Container running hai |
| `Exited (0)` | Main command successfully complete hui |
| `Exited (1)` | Generic application error |
| `Exited (126)` | Command mili, lekin execute nahi ho saki |
| `Exited (127)` | Command nahi mili |
| `Exited (137)` | Process ko `SIGKILL` mila; OOM ya force-stop possible |
| `Restarting` | Container crash/restart loop mein hai |
| `Created` | Container create hua, start nahi hua |
| `Dead` | Docker container ko properly manage nahi kar pa raha |

### Follow-up commands

```bash
docker logs --tail 50 backend
docker inspect backend
docker inspect backend --format '{{.State.ExitCode}}'
docker inspect backend --format '{{.State.OOMKilled}}'
```

---

## 3.3 Why `docker ps -a` Is More Useful During Failure

Container ka main process fail hote hi container stop ho jata hai. Stopped container `docker ps` mein disappear ho jata hai, lekin `docker ps -a` mein status aur exit code ke saath nazar aata hai.

```bash
docker ps
```

```text
CONTAINER ID   IMAGE   COMMAND   STATUS   PORTS   NAMES
```

```bash
docker ps -a
```

```text
CONTAINER ID   IMAGE   STATUS                     NAMES
ab1234567890   nginx   Exited (127) 5 seconds ago broken
```

Ab hum logs check kar sakte hain:

```bash
docker logs broken
```

**Conclusion:** Container failure troubleshooting mein `docker ps -a` pehla important command hai kyun ke failed containers running list mein nahi rehte.

---

## 3.4 `docker images` — Local Images

```bash
docker images
```

Local machine par downloaded ya built images dikhata hai.

```text
REPOSITORY      TAG       IMAGE ID       CREATED        SIZE
nginx           latest    a72860cb95fd   2 weeks ago    192MB
myapp           1.0       b8219e290abc   1 hour ago     450MB
<none>          <none>    c9234c71acde   3 days ago     450MB
```

Important fields: repository, tag, image ID aur size.

`<none>:<none>` ko dangling image kaha jata hai. Yeh rebuild ke baad old untagged image ho sakti hai.

```bash
docker images --filter dangling=true
docker system df -v
```

Bohat bari image pull/push aur deployment slow karti hai aur disk jaldi fill kar sakti hai.

---

## 3.5 `docker volume ls` — Persistent Volumes

```bash
docker volume ls
```

Docker-managed persistent volumes dikhata hai.

```text
DRIVER    VOLUME NAME
local     postgres_data
local     app_uploads
local     8f29acb09d4f...
```

Inspect:

```bash
docker volume inspect postgres_data
```

Anonymous ya unused volumes disk use kar sakte hain. Lekin volume mein important database data ho sakta hai, is liye verify kiye baghair delete na karein.

```bash
docker system df -v
```

---

## 3.6 `docker network ls` — Docker Networks

```bash
docker network ls
```

```text
NETWORK ID     NAME              DRIVER    SCOPE
720cf30e8321   bridge            bridge    local
e2730a864501   host              host      local
ac516b20bd70   none              null      local
c819d30af321   myapp_default     bridge    local
```

| Network | Purpose |
|---|---|
| `bridge` | Default isolated container network |
| `host` | Host networking directly use karta hai |
| `none` | External networking disabled |
| `myapp_default` | Docker Compose-created application network |

Inspect:

```bash
docker network inspect myapp_default
```

Agar frontend aur backend kisi shared network par nahi, to name resolution fail ho sakti hai:

```text
host not found in upstream "backend"
```

---

## 3.7 Docker Failure Workflow

```bash
docker ps -a
docker logs --tail 100 CONTAINER_NAME
docker inspect CONTAINER_NAME
docker inspect CONTAINER_NAME --format '{{.State.ExitCode}}'
docker inspect CONTAINER_NAME --format '{{.State.OOMKilled}}'
docker network ls
docker network inspect NETWORK_NAME
docker system df -v
```

Troubleshooting questions:

1. Container running, exited ya restarting hai?
2. Exit code kya hai?
3. Application logs kya keh rahe hain?
4. OOM kill hua?
5. Correct volume mount hai?
6. Containers same network par hain?
7. Host disk full to nahi?

---

# 4. Exercise 3 — Git Branch Practice

## 4.1 `git status`

```bash
git status
```

Current branch, staged changes, unstaged changes, untracked files aur remote relation dikhata hai.

### Clean example

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

### Changed files example

```text
Changes not staged for commit:
  modified:   README.md

Untracked files:
  notes.txt
```

- `README.md` tracked file hai jo modify hui.
- `notes.txt` new file hai jo abhi Git track nahi kar raha.

### Abnormal/important state

```text
HEAD detached at a1b2c3d
```

Aap normal branch par nahi hain. Current work preserve karne ke liye branch create kar sakte hain:

```bash
git switch -c recovery-work
```

---

## 4.2 `git switch -c lesson-01`

```bash
git switch -c lesson-01
```

Do actions:

1. `lesson-01` naam ki branch create karta hai.
2. New branch par switch karta hai.

```text
Switched to a new branch 'lesson-01'
```

Purana equivalent:

```bash
git checkout -b lesson-01
```

Agar branch already exist karti ho:

```text
fatal: a branch named 'lesson-01' already exists
```

Existing branch par switch:

```bash
git switch lesson-01
```

---

## 4.3 `git branch --show-current`

```bash
git branch --show-current
```

Sirf current branch ka naam print karta hai:

```text
lesson-01
```

Agar output blank ho, detached `HEAD` possible hai. Confirm karein:

```bash
git status
```

---

## 4.4 Complete Git Practice

```bash
git status
git switch -c lesson-01
git branch --show-current
git status
```

Expected final state:

```text
On branch lesson-01
nothing to commit, working tree clean
```

Practice commit:

```bash
touch lesson-01-notes.md
git status
git add lesson-01-notes.md
git commit -m "Add lesson 01 notes"
git log --oneline -5
```

---

# 5. Exercise 4 — Ansible Connection Test

Ansible commands se pehle inventory, hostname/IP, SSH user, private key aur remote Python confirm hone chahiye.

## 5.1 Example Inventory

```ini
[web]
web-server ansible_host=192.168.1.101

[app]
app-server ansible_host=192.168.1.102

[db]
db-server ansible_host=192.168.1.103

[all:vars]
ansible_user=ansibleadmin
ansible_ssh_private_key_file=/home/ansibleadmin/.ssh/ansible-key
ansible_python_interpreter=/usr/bin/python3
```

Agar inventory auto-detect na ho, explicit path dein:

```bash
ansible all -i inventory --list-hosts
```

---

## 5.2 `ansible all --list-hosts`

```bash
ansible all --list-hosts
```

Inventory se `all` pattern ke matching hosts dikhata hai. Yeh SSH test nahi karta; sirf inventory parsing aur host selection check karta hai.

```text
  hosts (3):
    web-server
    app-server
    db-server
```

### Abnormal output

```text
[WARNING]: No inventory was parsed, only implicit localhost is available
  hosts (0):
```

Possible reasons:

- Inventory wrong location par hai.
- `ansible.cfg` mein inventory path incorrect hai.
- Inventory syntax error hai.
- Wrong working directory/configuration use ho rahi hai.

```bash
ansible all -i inventory --list-hosts
ansible-config dump --only-changed
```

---

## 5.3 Ansible Ping Module

```bash
ansible all -m ansible.builtin.ping
```

Yeh normal ICMP ping nahi hai. Yeh test karta hai:

1. Inventory resolution
2. SSH connectivity
3. SSH authentication
4. Remote Python/module execution
5. Ansible response

### Successful output

```text
web-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

- `SUCCESS` = SSH aur execution successful
- `pong` = Ansible ping module response
- `changed: false` = Remote system modify nahi hua

### ICMP ping vs Ansible ping

```bash
ping -c 2 192.168.1.101
```

ICMP/network reachability test karta hai.

```bash
ansible all -m ansible.builtin.ping
```

SSH, authentication aur remote module execution test karta hai.

### Error: Connection timeout

```text
Failed to connect to the host via ssh: Connection timed out
```

Possible causes: wrong IP, VM off, routing/firewall issue, SSH port unavailable.

```bash
ping -c 2 192.168.1.101
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Error: Permission denied

```text
Permission denied (publickey,password)
```

Possible causes: wrong user/key, public key missing from `authorized_keys`, permissions issue.

```bash
chmod 600 ~/.ssh/ansible-key
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Error: Host key verification failed

Pehle fingerprint verify karein. Agar lab host reinstall/IP reuse confirmed hai:

```bash
ssh-keygen -R 192.168.1.101
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Error: Python missing

```text
/usr/bin/python3: not found
```

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
which python3
```

Inventory mein correct interpreter path set karein.

---

## 5.4 Ansible Setup/Facts Module

```bash
ansible all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

### Command breakdown

| Part | Meaning |
|---|---|
| `ansible all` | Tamam inventory hosts target karo |
| `-m ansible.builtin.setup` | Facts collection module use karo |
| `-a` | Module arguments do |
| `filter=ansible_distribution*` | Sirf distribution-related facts return karo |

### Example output

```text
web-server | SUCCESS => {
    "ansible_facts": {
        "ansible_distribution": "Rocky",
        "ansible_distribution_major_version": "9",
        "ansible_distribution_release": "Blue Onyx",
        "ansible_distribution_version": "9.8"
    },
    "changed": false
}
```

### Important facts

| Fact | Meaning |
|---|---|
| `ansible_distribution` | OS name, e.g. Rocky/Ubuntu |
| `ansible_distribution_version` | Complete version |
| `ansible_distribution_major_version` | Major version, e.g. `9` |
| `ansible_distribution_release` | Release name |

### Playbook use example

```yaml
- name: Install Nginx on Rocky 9
  ansible.builtin.dnf:
    name: nginx
    state: present
  when:
    - ansible_distribution == "Rocky"
    - ansible_distribution_major_version == "9"
```

Ubuntu example:

```yaml
- name: Install Nginx on Ubuntu
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true
  when: ansible_distribution == "Ubuntu"
```

---

## 5.5 Recommended Ansible Testing Order

```bash
ansible all --list-hosts
ansible all -m ansible.builtin.ping
ansible all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

### WHY this order?

1. **List hosts:** Inventory parsing aur host pattern confirm hota hai.
2. **Ping module:** SSH, key, user aur Python execution confirm hoti hai.
3. **Setup module:** Remote facts collection verify hoti hai.

Agar step 1 fail ho to inventory/configuration fix karein. Step 2 fail ho to network, SSH, credentials aur Python check karein. Step 3 fail ho to fact collection aur interpreter error inspect karein.

---

# 6. Quick Revision Table

| Command | Primary check | Important field | Warning sign |
|---|---|---|---|
| `df -h` | Disk usage | `Use%` | Root filesystem 95–100% |
| `df -i` | Inodes | `IUse%` | 100% inodes |
| `free -h` | RAM/swap | `available` | Very low available memory |
| `uptime` | Uptime/load | Load averages | Sustained load above CPU capacity |
| `ps -ef \| head` | Initial process list | `PID`, `CMD` | Limited health insight |
| `ss -tlnp` | Listening TCP ports | `Local Address:Port` | Missing/unexpected public port |
| `docker ps` | Running containers | `STATUS` | Expected container missing |
| `docker ps -a` | All containers | Status/exit code | `Exited`, `Restarting`, `Dead` |
| `docker images` | Local images | `TAG`, `SIZE` | Huge or dangling images |
| `docker volume ls` | Persistent volumes | Volume name | Unknown/unused volumes |
| `docker network ls` | Docker networks | Name/driver | App containers separated |
| `git status` | Repository state | Branch/status | Detached HEAD/unexpected changes |
| `git switch -c` | Create new branch | Branch name | Branch already exists |
| `git branch --show-current` | Current branch | Printed name | Blank in detached HEAD |
| `ansible ... --list-hosts` | Inventory selection | Host count | `hosts (0)` |
| Ansible `ping` | SSH/module execution | `SUCCESS`, `pong` | `UNREACHABLE`/`FAILED` |
| Ansible `setup` | OS facts | Distribution/version | Python/fact failure |

---

# 7. Practice Questions

## System baseline

1. `free -h` mein `free` aur `available` memory mein kya difference hai?
2. 4 CPUs ke system par load average `12.00` kya indicate kar sakta hai?
3. Disk mein space available hone ke bawajood file create kyun fail ho sakti hai?
4. `0.0.0.0:5432` security concern kyun ho sakta hai?
5. `ps -ef | head` high CPU process identify karne ke liye ideal kyun nahi?

## Docker

1. Failed container `docker ps` mein kyun nahi dikh sakta?
2. Exit code `137` ke do possible reasons kya hain?
3. Docker volume delete karne se pehle verify karna kyun zaroori hai?
4. Containers different networks par hon to application par kya effect ho sakta hai?

## Git

1. `git switch -c lesson-01` ke do actions kya hain?
2. Blank `git branch --show-current` kis state ko indicate kar sakta hai?
3. Modified aur untracked file mein kya farq hai?

## Ansible

1. ICMP ping aur Ansible ping mein kya difference hai?
2. `--list-hosts` SSH test kyun nahi hai?
3. `changed: false` ka kya matlab hai?
4. Setup module ke distribution facts playbook conditions mein kaise use hote hain?

---

# 8. Interview Summary

Interview mein sirf command ka naam nahi, apna troubleshooting thought process batayein:

> “Main pehle system baseline leta hoon: `df -h` se filesystem usage, `free -h` se available memory, `uptime` se load trend, process-sorted `ps` se resource consumers, aur `ss -tlnp` se required listening ports verify karta hoon. Docker issue mein `docker ps -a` se stopped container aur exit code dekhta hoon, phir logs aur inspect use karta hoon. Ansible mein pehle inventory selection, phir SSH/module connectivity, aur aakhir mein facts collection test karta hoon.”

Yeh answer dikhata hai ke aap commands yaad karne ke saath unka **WHY**, correct order aur next troubleshooting step bhi samajhte hain.

---

## Final Command Cheat Sheet

```bash
# Linux baseline
df -h
df -i
free -h
uptime
nproc
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head
ps -eo pid,user,comm,%cpu,%mem --sort=-%mem | head
sudo ss -tlnp

# Docker inspection
docker ps
docker ps -a
docker images
docker volume ls
docker network ls
docker system df -v

# Git branch practice
git status
git switch -c lesson-01
git branch --show-current
git status

# Ansible connection test
ansible all --list-hosts
ansible all -m ansible.builtin.ping
ansible all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

