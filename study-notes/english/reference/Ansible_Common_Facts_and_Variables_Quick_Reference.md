# Ansible Common Facts and Variables — Quick Reference

## Three categories

| Category | Source | Examples | Needs fact gathering? |
|---|---|---|---|
| Inventory variables | Inventory, `group_vars`, or `host_vars` | `ansible_host`, `ansible_user` | No |
| Magic variables | Automatically maintained by Ansible | `inventory_hostname`, `groups`, `hostvars` | No |
| Gathered facts | Collected from managed nodes by `setup` | OS, kernel, CPU, memory, IP | Yes |

`inventory_hostname` and `ansible_host` are not OS facts. They describe inventory identity and connection information.

## Common inventory and connection variables

| Variable | Meaning | Example |
|---|---|---|
| `ansible_host` | IP address or DNS name used for the connection | `192.168.1.154` |
| `ansible_user` | SSH user on the managed node | `ansibleadmin` |
| `ansible_port` | SSH port | `22` |
| `ansible_connection` | Connection plugin | `ssh` or `local` |
| `ansible_ssh_private_key_file` | Private SSH key | `/home/ansibleadmin/.ssh/ansible-key` |
| `ansible_python_interpreter` | Python used to execute remote modules | `/usr/bin/python3` |
| `ansible_become` | Enables privilege escalation | `true` |
| `ansible_become_method` | Privilege-escalation method | `sudo` |
| `ansible_become_user` | User to become | `root` |
| `ansible_password` | SSH password | Store with Ansible Vault, not plaintext |
| `ansible_become_password` | Become password | Store with Ansible Vault, not plaintext |

### Inventory example

```ini
[web]
node1 ansible_host=192.168.1.154

[app]
node2 ansible_host=192.168.1.185

[db]
node3 ansible_host=192.168.1.190

[three_tier_app:children]
web
app
db

[all:vars]
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=/home/ansibleadmin/.ssh/ansible-key
```

## `inventory_hostname` versus `ansible_host`

| Variable | Represents | Example |
|---|---|---|
| `inventory_hostname` | Name on the left side of the inventory entry | `node1` |
| `inventory_hostname_short` | Inventory name before its first dot | `node1` |
| `ansible_host` | Actual connection address | `192.168.1.154` |
| `ansible_facts['hostname']` | Hostname reported by the managed OS | `node1` |
| `ansible_facts['fqdn']` | FQDN reported by the managed OS | `node1.nitclasses.com` |

Given this inventory entry:

```ini
node1 ansible_host=192.168.1.154
```

the values are:

```text
inventory_hostname = node1
ansible_host        = 192.168.1.154
```

`ansible_host` may not exist when it was not defined. This expression safely falls back to the inventory name:

```jinja2
{{ ansible_host | default(inventory_hostname) }}
```

```bash
ansible all -m debug \
  -a 'msg="Name={{ inventory_hostname }}, Address={{ ansible_host | default(inventory_hostname) }}"'
```

## Common magic variables

| Variable | Meaning | Typical use |
|---|---|---|
| `inventory_hostname` | Current host's inventory name | Identify the current target |
| `inventory_hostname_short` | Short part of the inventory name | Short display name |
| `group_names` | Groups containing the current host | Group-dependent logic |
| `groups` | Dictionary of groups and their members | `groups['web']` |
| `hostvars` | Variables belonging to all inventory hosts | `hostvars['node1']['ansible_host']` |
| `ansible_play_hosts` | Hosts still active in the current play | Excludes failed hosts |
| `ansible_play_hosts_all` | Every host originally targeted | Complete target list |
| `ansible_play_batch` | Hosts in the current serial batch | Rolling changes |
| `inventory_file` | Inventory source file for the current host | Inspect inventory origin |
| `inventory_dir` | Directory containing the inventory source | Inventory-relative paths |
| `playbook_dir` | Directory containing the playbook | Playbook-relative paths |
| `role_name` | Current role name | Role logic and messages |
| `role_path` | Full path of the current role | Locate role resources |

Do not use Ansible magic-variable names for your own custom variables.

## Common OS facts

| Recommended expression | Older top-level name | Meaning | Example |
|---|---|---|---|
| `ansible_facts['distribution']` | `ansible_distribution` | Linux distribution | `Rocky` |
| `ansible_facts['distribution_version']` | `ansible_distribution_version` | Complete OS version | `9.8` |
| `ansible_facts['distribution_major_version']` | `ansible_distribution_major_version` | Major version | `9` |
| `ansible_facts['os_family']` | `ansible_os_family` | OS family | `RedHat` |
| `ansible_facts['kernel']` | `ansible_kernel` | Running kernel | `5.14.0-...el9_8.x86_64` |
| `ansible_facts['architecture']` | `ansible_architecture` | CPU architecture | `x86_64` |
| `ansible_facts['hostname']` | `ansible_hostname` | System hostname | `node1` |
| `ansible_facts['fqdn']` | `ansible_fqdn` | System FQDN | `node1.nitclasses.com` |
| `ansible_facts['virtualization_type']` | `ansible_virtualization_type` | Virtualization type | `xen`, `kvm`, `VMware` |
| `ansible_facts['virtualization_role']` | `ansible_virtualization_role` | Virtualization role | `guest` or `host` |
| `ansible_facts['pkg_mgr']` | `ansible_pkg_mgr` | Package manager | `dnf` |
| `ansible_facts['service_mgr']` | `ansible_service_mgr` | Service manager | `systemd` |
| `ansible_facts['python_version']` | `ansible_python_version` | Remote Python version | `3.9.25` |

## Common network facts

| Fact | Meaning | Example |
|---|---|---|
| `ansible_facts['default_ipv4']['address']` | Primary IPv4 chosen by the default route | `192.168.1.154` |
| `ansible_facts['default_ipv4']['interface']` | Default interface | `eth0` |
| `ansible_facts['default_ipv4']['gateway']` | Default gateway | `192.168.1.1` |
| `ansible_facts['all_ipv4_addresses']` | All discovered IPv4 addresses | Address list |
| `ansible_facts['all_ipv6_addresses']` | All discovered IPv6 addresses | Address list |
| `ansible_facts['interfaces']` | Detected interfaces | `['lo', 'eth0']` |
| `ansible_facts['dns']` | Detected DNS information | Nameservers and search domains |
| `ansible_facts['domain']` | System domain | `nitclasses.com` |

`ansible_host` and `ansible_facts['default_ipv4']['address']` may be different. The first comes from inventory; the second is discovered from the managed OS.

## CPU, memory, storage, and time facts

| Fact | Meaning |
|---|---|
| `ansible_facts['processor_vcpus']` | Number of virtual CPUs |
| `ansible_facts['processor_cores']` | Number of CPU cores |
| `ansible_facts['processor_count']` | Number of processor packages |
| `ansible_facts['memtotal_mb']` | Total memory in MB |
| `ansible_facts['memfree_mb']` | Free memory at collection time |
| `ansible_facts['swaptotal_mb']` | Total swap in MB |
| `ansible_facts['swapfree_mb']` | Free swap at collection time |
| `ansible_facts['mounts']` | Mounted filesystem details |
| `ansible_facts['devices']` | Detected block-device details |
| `ansible_facts['uptime_seconds']` | System uptime in seconds |
| `ansible_facts['date_time']['iso8601']` | Collected date and time |
| `ansible_facts['env']` | Remote process environment |
| `ansible_facts['user_id']` | User running the remote module |

Changing facts such as free memory and time show the value at collection time and can become stale during a long play.

## Commands for viewing facts and variables

| Task | Command |
|---|---|
| Gather every fact | `ansible all -m setup` |
| Gather facts from Node 1 | `ansible node1 -m setup` |
| Display distribution facts | `ansible all -m setup -a 'filter=ansible_distribution*'` |
| Display primary IPv4 facts | `ansible all -m setup -a 'filter=ansible_default_ipv4'` |
| Display memory facts | `ansible all -m setup -a 'filter=ansible_mem*'` |
| Display inventory name | `ansible all -m debug -a 'var=inventory_hostname'` |
| Display connection address | `ansible all -m debug -a 'var=ansible_host'` |
| Display group membership | `ansible all -m debug -a 'var=group_names'` |
| Show variables for Node 1 | `ansible-inventory --host node1` |
| Show inventory hierarchy | `ansible-inventory --graph` |
| Show processed inventory | `ansible-inventory --list` |
| Read setup-module help | `ansible-doc setup` |

When `ansible.cfg` does not select the inventory, specify it explicitly:

```bash
ansible-inventory -i ./automation/inventory/nodes --host node1
```

## Complete facts playbook

```yaml
---
- name: Display important host information
  hosts: all
  gather_facts: true

  tasks:
    - name: Display inventory and system information
      debug:
        msg:
          - "Inventory name: {{ inventory_hostname }}"
          - "Connection address: {{ ansible_host | default(inventory_hostname) }}"
          - "SSH user: {{ ansible_user | default('not explicitly defined') }}"
          - "System hostname: {{ ansible_facts['hostname'] }}"
          - "FQDN: {{ ansible_facts['fqdn'] }}"
          - "OS: {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}"
          - "OS family: {{ ansible_facts['os_family'] }}"
          - "Kernel: {{ ansible_facts['kernel'] }}"
          - "Architecture: {{ ansible_facts['architecture'] }}"
          - "Primary IPv4: {{ ansible_facts['default_ipv4']['address'] }}"
          - "vCPUs: {{ ansible_facts['processor_vcpus'] }}"
          - "Memory: {{ ansible_facts['memtotal_mb'] }} MB"
          - "Package manager: {{ ansible_facts['pkg_mgr'] }}"
          - "Service manager: {{ ansible_facts['service_mgr'] }}"
          - "Python: {{ ansible_facts['python_version'] }}"
```

Run it:

```bash
ansible-playbook display-host-facts.yml
```

## When `gather_facts: false` is used

Inventory and magic variables such as `inventory_hostname`, `ansible_host`, `ansible_user`, `groups`, `group_names`, and `hostvars` normally remain available.

System facts such as distribution, kernel, memory, and discovered IP addresses are not automatically available unless facts were cached or collected separately.

Gather facts later when needed:

```yaml
- name: Gather system facts now
  setup:
```

## Recommended learning order

| Priority | Learn first | Why |
|---|---|---|
| 1 | `inventory_hostname`, `ansible_host`, `ansible_user` | Understand identity and SSH connections |
| 2 | `group_names`, `groups`, `hostvars` | Understand inventory relationships |
| 3 | Distribution, version, OS family, kernel | Create OS-aware tasks |
| 4 | Hostname, FQDN, IPv4, interfaces | Understand identity and networking |
| 5 | CPU, memory, architecture | Apply hardware-based conditions |
| 6 | Package and service managers | Write portable administration tasks |
| 7 | Mounts, devices, virtualization | Handle infrastructure cases |

## Best practice

Do not memorize every available fact. Learn the categories and use these commands when you need details:

```bash
ansible HOST -m setup
ansible HOST -m setup -a 'filter=PATTERN'
ansible-inventory --host HOST
ansible-doc setup
```

For new playbooks, the `ansible_facts[...]` style clearly shows that a value came from fact gathering. Use inventory variables when you specifically need inventory or connection information.
