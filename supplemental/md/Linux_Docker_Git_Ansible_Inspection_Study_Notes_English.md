# Linux, Docker, Git, and Ansible Inspection — Study Notes

> **Language:** English  
> **Purpose:** Hands-on practice, troubleshooting, and interview revision

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
5. [Exercise 4 — Ansible Connection Test](#5-exercise-4--ansible-connection-test)
6. [Quick Revision Table](#6-quick-revision-table)
7. [Practice Questions](#7-practice-questions)
8. [Interview Summary](#8-interview-summary)
9. [Final Command Cheat Sheet](#9-final-command-cheat-sheet)

---

# 1. Important Note About `svg`

If this word appears after a command block:

```bash
svg
```

do not run it in the terminal. `svg` is not part of these Linux commands. It appears to be a document-formatting error.

---

# 2. Exercise 1 — System Baseline

A **system baseline** is an initial snapshot of the system's health. It helps you check disk space, memory, load, processes, and listening ports. If a problem occurs later, you can compare the current condition with the normal baseline.

## 2.1 `df -h` — Disk Usage

```bash
df -h
```

### What does it check?

It shows the total, used, and available space on mounted filesystems.

- `df` = disk filesystem usage
- `-h` = human-readable units such as MB and GB

### Example output

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        50G   31G   19G  63% /
/dev/sda1       960M  250M  710M  27% /boot
```

### Important fields

| Field | Meaning |
|---|---|
| `Size` | Total filesystem size |
| `Used` | Space already used |
| `Avail` | Space still available |
| `Use%` | Percentage of space used |
| `Mounted on` | Directory where the filesystem is mounted |

The most important fields are `Use%` and `Mounted on`, viewed together.

### Normal example

```text
/dev/sda2   50G   31G   19G   63%   /
```

The root filesystem is 63% used, which is normally acceptable.

### Abnormal example

```text
/dev/sda2   50G   50G   100M   100%   /
```

If the root filesystem is full:

- Applications may be unable to create files.
- Logs may stop being written.
- A database may fail.
- Services may crash.

### Next troubleshooting commands

```bash
du -xhd1 / | sort -h
du -xhd1 /var | sort -h
df -i
```

`df -i` checks inode usage. A filesystem can have free disk space but still reject new files because all inodes have been used by a very large number of small files.

---

## 2.2 `free -h` — Memory and Swap

```bash
free -h
```

### What does it check?

It displays RAM and swap usage in human-readable units.

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
| `used` | Memory currently in use |
| `free` | Completely unused memory |
| `buff/cache` | Memory used for buffers and cache |
| `available` | Memory realistically available to new programs |
| `Swap used` | Data currently stored in swap |

The most useful field is usually `available`, not just `free`.

Linux uses otherwise-idle RAM as cache. Therefore, low `free` memory does not automatically mean the server has a memory problem.

### Normal interpretation

```text
free = 1.1Gi
available = 9.2Gi
```

Only 1.1 GiB is completely unused, but 9.2 GiB can be made available to applications. This does not indicate memory pressure.

### Abnormal example

```text
        total   used   used    free    available
Mem:    15Gi    14Gi   100Mi   500Mi   300Mi
Swap:   2.0Gi   1.9Gi  100Mi
```

Possible warning signs:

- Available memory is extremely low.
- Swap is almost full.
- The system is becoming slow.
- The kernel may invoke the OOM killer.

### Important swap concept

Swap usage alone does not prove that RAM is currently insufficient. The kernel may leave old, inactive pages in swap. Check available memory, active swapping, application behavior, and logs.

```bash
vmstat 1
```

- `si` = swap in
- `so` = swap out

Check for OOM events:

```bash
sudo journalctl -k | grep -iE 'oom|out of memory'
```

---

## 2.3 `uptime` — Uptime and Load Average

```bash
uptime
```

### What does it check?

- How long the system has been running
- Number of active login sessions
- Load averages for the last 1, 5, and 15 minutes

### Example output

```text
14:30:10 up 12 days, 3:25, 2 users, load average: 0.25, 0.40, 0.35
```

| Part | Meaning |
|---|---|
| `14:30:10` | Current system time |
| `up 12 days` | System uptime |
| `2 users` | Two active login sessions |
| `0.25` | 1-minute load average |
| `0.40` | 5-minute load average |
| `0.35` | 15-minute load average |

### Compare load with CPU count

```bash
nproc
```

If the server has four logical CPUs:

- Load `1.00` → substantial capacity remains.
- Load `4.00` → the CPUs are approximately fully occupied.
- Load `8.00` → work may be waiting for CPU time or uninterruptible I/O.

Linux load average is not simply CPU percentage. It includes runnable tasks and tasks waiting in uninterruptible state, commonly because of I/O.

### Abnormal example

```text
load average: 12.50, 10.20, 8.70
```

On a four-CPU system, this is high. Because the one-minute value is greater than the five- and fifteen-minute values, the load appears to be increasing recently.

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

- `ps -ef` lists all running processes in full format.
- `|` sends the first command's output to the second command.
- `head` displays only the first ten lines.

### Example output

```text
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 09:20 ?        00:00:03 /usr/lib/systemd/systemd
root         641       1  0 09:20 ?        00:00:01 /usr/sbin/sshd -D
```

| Field | Meaning |
|---|---|
| `UID` | User that owns the process |
| `PID` | Process ID |
| `PPID` | Parent process ID |
| `C` | CPU utilization indicator |
| `STIME` | Process start time |
| `TIME` | Accumulated CPU time |
| `CMD` | Process command |

### Important limitation

`ps -ef | head` does not display the highest CPU- or memory-consuming processes. It only displays the first lines of the process list.

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

The Java process is using almost four CPU cores and 72% of memory. Do not kill it based only on these numbers. First investigate the application, workload, logs, and business impact.

---

## 2.5 `sudo ss -tlnp` — Listening Ports

```bash
sudo ss -tlnp
```

### What does it check?

It displays listening TCP ports and the processes that own them.

| Option | Meaning |
|---|---|
| `-t` | TCP sockets |
| `-l` | Listening sockets only |
| `-n` | Numeric addresses and ports |
| `-p` | Process and PID information |

### Example output

```text
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      128    0.0.0.0:22          0.0.0.0:*     users:(("sshd",pid=641,fd=3))
LISTEN 0      511    0.0.0.0:80          0.0.0.0:*     users:(("nginx",pid=920,fd=6))
LISTEN 0      4096   127.0.0.1:5432      0.0.0.0:*     users:(("postgres",pid=980,fd=7))
```

| Address | Meaning |
|---|---|
| `0.0.0.0:80` | Port 80 listens on all IPv4 interfaces |
| `127.0.0.1:5432` | Port is accessible only from the local machine |
| `[::]:22` | Listening on IPv6; IPv4 behavior depends on system configuration |

### Abnormal cases

If Nginx should be running but ports 80 and 443 are absent:

```bash
sudo systemctl status nginx
sudo journalctl -u nginx --since '15 minutes ago'
```

If a database intended only for local applications listens on `0.0.0.0:5432`, it may be unnecessarily exposed on external interfaces.

If an application reports `Address already in use`:

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

This workflow answers:

1. Is disk space or inode capacity exhausted?
2. Is available memory low?
3. Is load greater than CPU capacity?
4. Which processes are consuming resources?
5. Are the required services listening on the expected ports?

---

# 3. Exercise 2 — Docker Inspection

## 3.1 `docker ps` — Running Containers

```bash
docker ps
```

This command displays only currently running containers.

```text
CONTAINER ID   IMAGE          STATUS         PORTS                  NAMES
a31bc92df521   nginx:latest   Up 10 minutes  0.0.0.0:8080->80/tcp   web
```
[More information about this command](./Docker-Port-Mapping-Study-Notes-English.md)

| Field | Meaning |
|---|---|
| `CONTAINER ID` | Short container ID |
| `IMAGE` | Image used to create the container |
| `STATUS` | Current state and duration |
| `PORTS` | Host-to-container port mapping |
| `NAMES` | Container name |

If only the headings appear, no containers are currently running. This does not prove that no containers exist.

---

## 3.2 `docker ps -a` — All Containers

```bash
docker ps -a
```

This displays running, stopped, failed, and created containers.

```text
CONTAINER ID   IMAGE          STATUS                     NAMES
a31bc92df521   nginx:latest   Up 10 minutes              web
cb14ef128920   myapp:1.0      Exited (1) 20 seconds ago  backend
d78ef731a221   postgres:16    Exited (137) 1 minute ago  database
```

### Common states and exit codes

| Status | Possible meaning |
|---|---|
| `Up` | Container is running |
| `Exited (0)` | Main command completed successfully |
| `Exited (1)` | Generic application error |
| `Exited (126)` | Command was found but could not be executed |
| `Exited (127)` | Command was not found |
| `Exited (137)` | Process received `SIGKILL`; possible OOM or forced stop |
| `Restarting` | Container is in a crash/restart loop |
| `Created` | Container was created but not started |
| `Dead` | Docker cannot properly manage the container |

### Follow-up commands

```bash
docker logs --tail 50 backend
docker inspect backend
docker inspect backend --format '{{.State.ExitCode}}'
docker inspect backend --format '{{.State.OOMKilled}}'
```

---

## 3.3 Why `docker ps -a` Is More Useful During Failure

A container stops when its main process exits. Once stopped, it disappears from `docker ps`, but remains visible in `docker ps -a` with its status and exit code.

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

You can now inspect its logs:

```bash
docker logs broken
```

**Conclusion:** During container-failure troubleshooting, `docker ps -a` is usually more useful because failed containers are no longer running.

---

## 3.4 `docker images` — Local Images

```bash
docker images
```

Displays images downloaded or built locally.

```text
REPOSITORY      TAG       IMAGE ID       CREATED        SIZE
nginx           latest    a72860cb95fd   2 weeks ago    192MB
myapp           1.0       b8219e290abc   1 hour ago     450MB
<none>          <none>    c9234c71acde   3 days ago     450MB
```

Important fields include repository, tag, image ID, and size.

An image shown as `<none>:<none>` is called a dangling image. It may be an old untagged image left after a rebuild.

```bash
docker images --filter dangling=true
docker system df -v
```

Very large images slow pulls, pushes, and deployments and may consume host disk space quickly.

---

## 3.5 `docker volume ls` — Persistent Volumes

```bash
docker volume ls
```

Displays Docker-managed persistent volumes.

```text
DRIVER    VOLUME NAME
local     postgres_data
local     app_uploads
local     8f29acb09d4f...
```

Inspect a volume:

```bash
docker volume inspect postgres_data
```

Anonymous or unused volumes may consume disk space. However, a volume may contain important database data, so never delete it before confirming its purpose and backups.

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
| `host` | Uses the host network directly |
| `none` | External networking is disabled |
| `myapp_default` | Application network automatically created by Compose |

Inspect a network:

```bash
docker network inspect myapp_default
```

If the frontend and backend do not share a network, container-name resolution may fail:

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

Ask these questions:

1. Is the container running, exited, or restarting?
2. What is the exit code?
3. What do the application logs report?
4. Was the process killed because of OOM?
5. Are the expected volumes mounted?
6. Are the containers on the same required network?
7. Is the host disk full?

---

# 4. Exercise 3 — Git Branch Practice

## 4.1 `git status`

```bash
git status
```

Displays the current branch, staged changes, unstaged changes, untracked files, and the relationship with the remote branch.

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

- `README.md` is already tracked and has been modified.
- `notes.txt` is new and is not yet tracked by Git.

### Important state

```text
HEAD detached at a1b2c3d
```

You are not on a normal branch. To preserve work made in this state, create a branch:

```bash
git switch -c recovery-work
```

## 4.2 `git switch -c lesson-01`

```bash
git switch -c lesson-01
```

This performs two actions:

1. Creates a branch named `lesson-01`.
2. Switches to the new branch.

```text
Switched to a new branch 'lesson-01'
```

Older equivalent:

```bash
git checkout -b lesson-01
```

If the branch already exists:

```text
fatal: a branch named 'lesson-01' already exists
```

Switch to it without `-c`:

```bash
git switch lesson-01
```

## 4.3 `git branch --show-current`

```bash
git branch --show-current
```

Prints only the current branch name:

```text
lesson-01
```

A blank result may indicate detached HEAD. Confirm with:

```bash
git status
```

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

Practice a commit:

```bash
touch lesson-01-notes.md
git status
git add lesson-01-notes.md
git commit -m "Add lesson 01 notes"
git log --oneline -5
```

---

# 5. Exercise 4 — Ansible Connection Test

Before running these commands, confirm the inventory, hostname or IP address, SSH user, private key, and remote Python interpreter.

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

If Ansible does not automatically find the inventory, supply it explicitly:

```bash
ansible all -i inventory --list-hosts
```

## 5.2 `ansible all --list-hosts`

```bash
ansible all --list-hosts
```

Displays inventory hosts that match the `all` pattern. It does not test SSH; it only verifies inventory parsing and host selection.

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

Possible causes:

- Inventory is in the wrong location.
- The inventory path in `ansible.cfg` is incorrect.
- Inventory syntax is invalid.
- An unexpected configuration file is active.

```bash
ansible all -i inventory --list-hosts
ansible-config dump --only-changed
```

## 5.3 Ansible Ping Module

```bash
ansible all -m ansible.builtin.ping
```

This is not a normal ICMP ping. It checks:

1. Inventory resolution
2. SSH connectivity
3. SSH authentication
4. Remote Python and module execution
5. Ansible response

### Successful output

```text
web-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

- `SUCCESS` = SSH and execution succeeded.
- `pong` = successful Ansible ping-module response.
- `changed: false` = the remote system was not modified.

### ICMP ping versus Ansible ping

```bash
ping -c 2 192.168.1.101
```

This checks basic ICMP/network reachability.

```bash
ansible all -m ansible.builtin.ping
```

This checks SSH, authentication, Python, and remote module execution.

### Connection timeout

```text
Failed to connect to the host via ssh: Connection timed out
```

Possible causes include a wrong IP, powered-off VM, routing problem, firewall rule, or unavailable SSH port.

```bash
ping -c 2 192.168.1.101
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Permission denied

```text
Permission denied (publickey,password)
```

Possible causes include the wrong user or key, a missing public key in `authorized_keys`, or incorrect permissions.

```bash
chmod 600 ~/.ssh/ansible-key
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Host key verification failed

Verify the server's fingerprint first. If this is a confirmed lab-machine reinstall or IP reuse:

```bash
ssh-keygen -R 192.168.1.101
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
```

### Python missing

```text
/usr/bin/python3: not found
```

```bash
ssh -i ~/.ssh/ansible-key ansibleadmin@192.168.1.101
which python3
```

Set the correct interpreter path in inventory if necessary.

## 5.4 Ansible Setup/Facts Module

```bash
ansible all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

| Part | Meaning |
|---|---|
| `ansible all` | Target all inventory hosts |
| `-m ansible.builtin.setup` | Use the fact-gathering module |
| `-a` | Supply module arguments |
| `filter=ansible_distribution*` | Return only distribution-related facts |

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

| Fact | Meaning |
|---|---|
| `ansible_distribution` | Operating-system distribution name |
| `ansible_distribution_version` | Complete distribution version |
| `ansible_distribution_major_version` | Major version, such as `9` |
| `ansible_distribution_release` | Distribution release name |

### Playbook example

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

## 5.5 Recommended Ansible Testing Order

```bash
ansible all --list-hosts
ansible all -m ansible.builtin.ping
ansible all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

### Why this order?

1. **List hosts:** Confirms inventory parsing and host selection.
2. **Ping module:** Confirms SSH, user, key, and Python/module execution.
3. **Setup module:** Confirms remote fact gathering.

If step 1 fails, fix inventory or configuration. If step 2 fails, investigate the network, SSH, credentials, and Python. If step 3 fails, inspect fact-gathering and interpreter errors.

---

# 6. Quick Revision Table

| Command | Primary check | Important field | Warning sign |
|---|---|---|---|
| `df -h` | Disk usage | `Use%` | Root filesystem at 95–100% |
| `df -i` | Inodes | `IUse%` | Inodes at 100% |
| `free -h` | RAM and swap | `available` | Very low available memory |
| `uptime` | Uptime and load | Load averages | Sustained load above CPU capacity |
| `ps -ef \| head` | Initial process list | `PID`, `CMD` | Limited health insight |
| `ss -tlnp` | Listening TCP ports | `Local Address:Port` | Missing or unexpectedly exposed port |
| `docker ps` | Running containers | `STATUS` | Expected container missing |
| `docker ps -a` | All containers | Status/exit code | `Exited`, `Restarting`, or `Dead` |
| `docker images` | Local images | `TAG`, `SIZE` | Huge or dangling images |
| `docker volume ls` | Persistent volumes | Volume name | Unknown or unused volumes |
| `docker network ls` | Docker networks | Name and driver | Required containers separated |
| `git status` | Repository state | Branch/status | Detached HEAD or unexpected changes |
| `git switch -c` | Create a branch | Branch name | Branch already exists |
| `git branch --show-current` | Current branch | Printed name | Blank output in detached HEAD |
| `ansible ... --list-hosts` | Inventory selection | Host count | `hosts (0)` |
| Ansible `ping` | SSH/module execution | `SUCCESS`, `pong` | `UNREACHABLE` or `FAILED` |
| Ansible `setup` | OS facts | Distribution/version | Python or fact-gathering failure |

---

# 7. Practice Questions

## System baseline

1. What is the difference between `free` and `available` memory?
2. What can a load average of `12.00` indicate on a four-CPU system?
3. Why can file creation fail even when disk space remains available?
4. Why might `0.0.0.0:5432` be a security concern?
5. Why is `ps -ef | head` not ideal for identifying high-CPU processes?

## Docker

1. Why might a failed container not appear in `docker ps`?
2. What are two possible reasons for exit code `137`?
3. Why must you verify a volume before deleting it?
4. What may happen if application containers do not share the required network?

## Git

1. What two actions does `git switch -c lesson-01` perform?
2. What can a blank result from `git branch --show-current` indicate?
3. What is the difference between a modified file and an untracked file?

## Ansible

1. What is the difference between ICMP ping and the Ansible ping module?
2. Why is `--list-hosts` not an SSH test?
3. What does `changed: false` mean?
4. How can distribution facts be used in playbook conditions?

---

# 8. Interview Summary

In an interview, explain your troubleshooting process rather than listing commands without context:

> “I first establish a system baseline. I use `df -h` for filesystem usage, `free -h` for available memory, `uptime` for the load trend, a CPU- or memory-sorted `ps` command for resource consumers, and `ss -tlnp` for required listening ports. For a Docker issue, I use `docker ps -a` to find stopped containers and exit codes, then inspect logs and container state. For Ansible, I verify inventory selection first, then SSH and module execution, and finally fact gathering.”

This demonstrates that you understand not only the commands, but also their purpose, correct order, and next troubleshooting steps.

---

# 9. Final Command Cheat Sheet

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

