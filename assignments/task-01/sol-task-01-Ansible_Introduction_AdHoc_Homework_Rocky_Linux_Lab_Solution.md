# Ansible Introduction and Ad-Hoc Commands — Instructor Solution

> This answer key matches the 15-task Rocky Linux homework. Command output such as uptime, memory, disk usage, package versions, and timestamps will vary. Students should submit their actual output, not copy the samples.

## Lab Reference

| Role | Inventory name | Address | Group |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | — |
| Web node | `node1` | `192.168.1.154` | `web` |
| Application node | `node2` | `192.168.1.185` | `app` |
| Database node | `node3` | `192.168.1.190` | `db` |

---

## Solution 1 — Understand Ansible

1. **Configuration management** is the automated process of defining, applying, and maintaining the desired state of systems.
2. It provides consistent configuration across many servers, reduces manual mistakes, saves time, and makes changes repeatable.
3. **Ansible** is an automation tool used for configuration management, application deployment, orchestration, and administrative tasks.
4. **Agentless** means a permanent Ansible agent normally does not need to be installed or continuously run on Linux managed nodes.
5. Ansible normally connects to Linux nodes through SSH, transfers or invokes the required module, receives its result, and closes the connection.
6. A **push-based** controller initiates and sends changes to nodes. In a **pull-based** model, an agent on each node periodically contacts a central service and retrieves its desired configuration.
7. Ansible is normally agentless and uses YAML playbooks. Traditional Puppet or Chef deployments commonly require agents and use their own domain-specific languages.
8. **Idempotency** means repeatedly applying the same desired state produces no additional change after that state has already been reached.
9. Playbooks are version-controllable, reviewable, reusable, consistent, and safer than repeatedly entering manual commands.

### Architecture components

| Component | Correct description | Example in this lab |
|---|---|---|
| Control node | System where Ansible is installed and commands run | `ansible-server` |
| Managed nodes | Systems Ansible configures | `node1`, `node2`, `node3` |
| Inventory | Defines hosts, groups, and related variables | `~/automation/inventory/nodes` |
| Configuration | Controls Ansible behavior and defaults | `~/automation/ansible.cfg` |
| Module | Performs a particular operation | `ping`, `command`, `copy`, `dnf` |
| Module argument | Supplies details required by a module | `name=tree state=present` |
| Ad-hoc command | Runs a quick, one-time task | `ansible all -m ping` |
| Playbook | YAML automation containing plays and tasks | A reusable package-installation playbook |

The administrator runs Ansible on the control node. Ansible reads the inventory and configuration, selects the requested hosts, connects over SSH, runs modules, and reports the results.

---

## Solution 2 — Verify the Control Node

Expected values:

| Item | Expected result |
|---|---|
| Current user | `ansibleadmin` |
| Control-node hostname | `ansible-server.nitclasses.com` |
| Ansible core version | `2.14.18` |
| Active configuration | `/home/ansibleadmin/automation/ansible.cfg` when run from `~/automation` |
| Ansible executable | `/usr/bin/ansible` |
| Control-node Python | `Python 3.9.25` |

Ansible is installed on the control node because this machine reads automation instructions and initiates connections. Managed nodes normally do not require Ansible because the control node sends work through SSH. Python is required on most Linux managed nodes because most transferred Ansible modules execute through Python.

> Accept the student's actual version output if their system has been legitimately updated.

---

## Solution 3 — Verify the Existing Configuration

The expected active project configuration is:

```text
/home/ansibleadmin/automation/ansible.cfg
```

| Setting | Explanation |
|---|---|
| `inventory` | Default path to the inventory, such as `./inventory/nodes` |
| `remote_user` | Default SSH login account, `ansibleadmin` |
| `ask_pass = False` | Do not request an SSH password; use key authentication |
| `host_key_checking = True` | Verify the server identity against SSH `known_hosts` |
| `become_method = sudo` | Use `sudo` for privilege escalation |
| `become_user = root` | Escalate to `root` |
| `become_ask_pass = False` | Do not prompt for a sudo password |

Host-key checking reduces the risk of connecting to an impersonated or unexpected host. Password prompting is unnecessary because SSH keys and passwordless sudo are configured for this lab.

---

## Solution 4 — Verify the Existing Inventory

Expected table:

| Inventory host | `ansible_host` | Group | SSH user | Python interpreter |
|---|---|---|---|---|
| `node1` | `192.168.1.154` | `web` | `ansibleadmin` | `/usr/bin/python3` |
| `node2` | `192.168.1.185` | `app` | `ansibleadmin` | `/usr/bin/python3` |
| `node3` | `192.168.1.190` | `db` | `ansibleadmin` | `/usr/bin/python3` |

- `inventory_hostname` is the name written in inventory, such as `node1`. `ansible_host` is the actual DNS name or IP used for the connection.
- `[three_tier_app:children]` creates a parent group containing the `web`, `app`, and `db` groups.
- `[all:vars]` assigns variables inherited by every inventory host.
- Friendly aliases make commands readable. Ansible maps each alias to its `ansible_host` value.

Expected graph structure:

```text
@all:
  |--@three_tier_app:
  |  |--@web:
  |  |  |--node1
  |  |--@app:
  |  |  |--node2
  |  |--@db:
  |  |  |--node3
```

The exact ordering may differ without affecting correctness.

---

## Solution 5 — Test SSH and Ansible Connectivity

The three BatchMode SSH commands should return the appropriate hostnames without requesting passwords. The Ansible result should resemble:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

The same result should appear for `node2` and `node3`.

- `SUCCESS` means Ansible connected, executed the module, and received a successful response.
- `pong` is the successful response of the Ansible `ping` module.
- It is not an ICMP network ping. It verifies Ansible connectivity, authentication, and usable Python/module execution.
- `changed: false` means the test did not alter the managed node.
- `-v` provides additional connection and execution information.

---

## Solution 6 — Read-Only Ad-Hoc Commands

| Command purpose | Target | Module | Arguments |
|---|---|---|---|
| Uptime | `three_tier_app` | `command` | `uptime` |
| Memory | `web` | `command` | `free -h` |
| Disk usage | `three_tier_app` | `command` | `df -h` |
| Kernel | `three_tier_app` | `command` | `uname -r` |
| Remote user | `three_tier_app` | `command` | `whoami` |
| Hostname | `three_tier_app` | `command` | `hostname -f` |

`-m` selects the module and `-a` supplies its arguments. Older Ansible versions may report `CHANGED` for successful `command` executions because the module cannot always determine whether an arbitrary command changed the system. In a playbook, use:

```yaml
changed_when: false
```

for a command known to be read-only.

---

## Solution 7 — Facts and Variables

Expected values include:

| Host | Distribution | Version | Architecture | Python |
|---|---|---|---|---|
| `node1` | Rocky | Node's installed Rocky 9 version | `x86_64` | Node's Python 3 version |
| `node2` | Rocky | Node's installed Rocky 9 version | `x86_64` | Node's Python 3 version |
| `node3` | Rocky | Node's installed Rocky 9 version | `x86_64` | Node's Python 3 version |

Students must enter versions actually reported by `setup`.

- An **inventory variable** is defined by the administrator in inventory, configuration-related variable files, or another variable source. A **fact** is discovered from the managed node.
- The `setup` module gathers facts.
- `discovered_interpreter_python` may not be returned when `ansible_python_interpreter=/usr/bin/python3` explicitly selects the interpreter; discovery is unnecessary.
- Expected mappings: `node1 → 192.168.1.154`, `node2 → 192.168.1.185`, and `node3 → 192.168.1.190`.

---

## Solution 8 — Inventory Groups and Patterns

| Pattern | Expected hosts |
|---|---|
| `web` | `node1` |
| `app` | `node2` |
| `db` | `node3` |
| `web:app` | `node1`, `node2` |
| `three_tier_app` | `node1`, `node2`, `node3` |
| `three_tier_app:!db` | `node1`, `node2` |

The colon performs a union, while the exclamation mark excludes a group or host. If the optional groups are added, `application` contains `node1` and `node2`, while `all_servers` contains all three nodes.

---

## Solution 9 — Create and Copy Temporary Content

- `hello.txt` is first created locally on the control node.
- The `copy` module transfers it from the control node to each managed node.
- `0644` gives the owner read/write permission and gives the group and others read-only permission.
- `-b` is not required because `/tmp` is writable and the directory is created as the SSH user.

Expected state:

```text
/tmp/ansible-homework/hello.txt
```

The remote content should be:

```text
Hello from ansibleadmin
```

The `stat` result should include `exists: true`, `isreg: true`, and mode `0644`.

---

## Solution 10 — Package Management and Become

- `-b` and `--become` enable privilege escalation according to the Ansible configuration.
- Package installation changes the system package database and protected directories, so root privileges are required.
- The `dnf` module understands package state, returns structured results, and supports idempotency. A shell command is less reliable and harder for Ansible to evaluate.
- `state=present` means the package must be installed, but it does not necessarily force the newest available version.

After installation, verification should resemble:

```text
tree-<version>.el9.x86_64
```

The exact package version may differ.

---

## Solution 11 — Demonstrate Idempotency

| Operation | First run | Second run | Explanation |
|---|---|---|---|
| Install `tree` | Usually `changed=true` | `changed=false` | Package already satisfies `state=present` |
| Copy `hello.txt` | Usually `changed=true` | `changed=false` | Source and destination content/mode already match |

`changed` means Ansible modified the target to reach the requested state. `ok` or `changed: false` means the desired state already existed. Ansible did not blindly skip the second task; it checked the current state and determined that no modification was required.

---

## Solution 12 — Compare Command and Shell

| Feature | `command` | `shell` |
|---|---|---|
| Runs through a shell | No | Yes |
| Supports `|` | No | Yes |
| Supports `>` | No | Yes |
| Safer default | Yes | No |

The pipeline requires `shell` because the pipe is a shell operator. Prefer `command` when shell parsing is unnecessary because it reduces quoting problems and command-injection risk. If untrusted input is included in a shell command, it may inject and execute unintended commands.

---

## Solution 13 — Troubleshooting

| Symptom | Investigation and likely correction |
|---|---|
| `Permission denied (publickey)` | Run `ssh -v node1`; verify `ansible_user`, private-key selection, key permissions, and that the matching public key exists in the remote `authorized_keys`. |
| `Connection timed out` | Confirm the IP/DNS value, node power state, routing/VPN, port 22 reachability, firewall, and SSH service. A timeout normally occurs before authentication. |
| Python interpreter not found | Check `python3 --version` over SSH and inspect `ansible_python_interpreter`. Install Python through an approved bootstrap method or correct the interpreter path. |
| `Missing sudo password` | Verify NOPASSWD sudo for `ansibleadmin`; otherwise use `-K` only when the lab policy expects a sudo password. Check `become_ask_pass`. |
| Pattern matches no hosts | Run `ansible TARGET --list-hosts` and `ansible-inventory --graph`; correct spelling, quoting, group membership, or the active inventory path. |
| Host-key verification failure after rebuild | Independently verify the VM's new fingerprint first. Then remove only the obsolete entry with `ssh-keygen -R node1` and/or `ssh-keygen -R 192.168.1.154`, and reconnect to store the verified key. |

`ansible node1 -m ping -vvv` provides detailed Ansible/SSH diagnosis. It may expose paths and connection details, so sanitize output before sharing publicly.

---

## Solution 14 — Cleanup

Expected results:

- Removing `tree` normally reports `changed=true` if it was installed.
- Removing `/tmp/ansible-homework` normally reports `changed=true` if it existed.
- `rpm -q tree` returns a non-zero code and reports that the package is not installed.
- The `stat` output reports:

```text
"exists": false
```

- The local `hello.txt` should no longer exist on the control node.

Re-running the two Ansible removal tasks should report `changed=false`, which also demonstrates idempotency for the absent state.

---

## Solution 15 — Final Reflection

Answers will vary. A strong sample response is:

1. The most important concept was idempotency because it allows automation to be run repeatedly without making unnecessary changes.
2. `ansible three_tier_app -m ping` was especially useful because it quickly verified inventory selection, SSH authentication, remote Python, and module execution.
3. A module defines the type of operation; arguments define the details of that operation.
4. Inventory defines hosts, groups, and host-related variables. `ansible.cfg` defines Ansible's operating defaults and behavior.
5. Use a playbook when work must be repeated, reviewed, version-controlled, or performed through multiple ordered tasks.
6. Verification proves that the requested state was reached and helps catch partial failures or targeting mistakes.
7. Example: a public-key error was investigated with `ssh -v`, inventory variables were checked, and the correct private key was selected.

---


