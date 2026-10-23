# Ansible Inventory and Configuration Challenge — Five-Node Rocky Linux Lab

This homework is adapted for the existing personal Ansible lab. Complete it in a **separate practice directory** so that the working project under `/home/ansibleadmin/automation` is not changed.

## Index

1. [Lab environment](#1-lab-environment)
2. [Learning objectives](#2-learning-objectives)
3. [Task 1 — Verify the control node](#3-task-1--verify-the-control-node)
4. [Task 2 — Create the project structure](#4-task-2--create-the-project-structure)
5. [Task 3 — Create the static inventory](#5-task-3--create-the-static-inventory)
6. [Task 4 — Create the Ansible configuration](#6-task-4--create-the-ansible-configuration)
7. [Task 5 — Validate the configuration](#7-task-5--validate-the-configuration)
8. [Task 6 — Examine the inventory](#8-task-6--examine-the-inventory)
9. [Task 7 — Test connectivity](#9-task-7--test-connectivity)
10. [Expected project structure](#10-expected-project-structure)
11. [Submission checklist](#11-submission-checklist)
12. [Important notes](#12-important-notes)

---

## 1. Lab environment

| Role | Inventory name | IP address | Operating system/user |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | Rocky Linux 9 / `ansibleadmin` |
| Managed node | `node1` | `192.168.1.154` | SSH user: `ansibleadmin` |
| Managed node | `node2` | `192.168.1.185` | SSH user: `ansibleadmin` |
| Managed node | `node3` | `192.168.1.190` | SSH user: `ansibleadmin` |
| Managed node | `node4` | `192.168.1.155` | SSH user: `ansibleadmin` |
| Managed node | `node5` | `192.168.1.156` | SSH user: `ansibleadmin` |

SSH private key:

```text
/home/ansibleadmin/.ssh/ansible-key
```

Python interpreter on the managed nodes:

```text
/usr/bin/python3
```

## 2. Learning objectives

After completing this challenge, you should be able to:

- Create an INI-format static inventory.
- Place hosts in individual groups.
- Create parent groups using `:children`.
- Define variables that apply to all inventory hosts.
- Create a project-specific `ansible.cfg` file.
- Configure inventory, collection, role, SSH, and privilege-escalation settings.
- Validate the effective Ansible configuration.
- Display and test inventory groups and hosts.

---

## 3. Task 1 — Verify the control node

Log in to the control node as `ansibleadmin` and confirm that Ansible is installed.

Your verification must show:

- The Ansible Core version.
- The configuration file currently in use.
- The Ansible executable location.
- The Python version used by Ansible.

Do not reinstall Ansible if it is already available.

---

## 4. Task 2 — Create the project structure

Create the following separate practice directory:

```text
/home/ansibleadmin/ansible-inventory-lab
```

Inside it, create:

- A static inventory file named `inventory`.
- An Ansible configuration file named `ansible.cfg`.
- A directory named `mycollections` for local collections.
- A directory named `roles` for local roles.

Ensure that all files and directories belong to `ansibleadmin`.

---

## 5. Task 3 — Create the static inventory

Create this file:

```text
/home/ansibleadmin/ansible-inventory-lab/inventory
```

Configure it so that:

1. `node1` is a member of the `dev` host group.
2. `node2` is a member of the `test` host group.
3. `node3` and `node4` are members of the `prod` host group.
4. `node5` is a member of the `balancers` host group.
5. The `prod` group is a child of the `webservers` group.
6. The `dev`, `test`, `prod`, and `balancers` groups are children of the `managed_nodes` group so that it contains all five managed nodes.
7. Each host uses its correct IP address from the lab-environment table.
8. Every inventory host uses:

```ini
ansible_user=ansibleadmin
ansible_python_interpreter=/usr/bin/python3
```

Use valid INI group names. Prefer underscores instead of hyphens in group names.

### Required membership summary

| Group | Required direct host or child group |
|---|---|
| `dev` | `node1` |
| `test` | `node2` |
| `prod` | `node3` and `node4` |
| `balancers` | `node5` |
| `webservers` | Child group: `prod` |
| `managed_nodes` | Child groups: `dev`, `test`, `prod`, and `balancers` |

> The `prod` group contains two hosts. The `webservers` parent group inherits both hosts through its `prod` child group. The `managed_nodes` parent group contains all five nodes through its four child groups.

---

## 6. Task 4 — Create the Ansible configuration

Create this project-specific configuration file:

```text
/home/ansibleadmin/ansible-inventory-lab/ansible.cfg
```

Configure it with the following requirements.

### `[defaults]` requirements

1. Use this inventory file:

   ```text
   /home/ansibleadmin/ansible-inventory-lab/inventory
   ```

2. Use this local collections directory:

   ```text
   /home/ansibleadmin/ansible-inventory-lab/mycollections
   ```

3. Use this local roles directory:

   ```text
   /home/ansibleadmin/ansible-inventory-lab/roles
   ```

4. Use `ansibleadmin` as the default remote SSH user.
5. Use this SSH private key:

   ```text
   /home/ansibleadmin/.ssh/ansible-key
   ```

6. Do not ask for an SSH login password.
7. Keep SSH host-key checking enabled for secure connections.

### `[privilege_escalation]` requirements

1. Use `sudo` as the privilege-escalation method.
2. Escalate to the `root` user.
3. Do not ask for a sudo password because the lab account is configured for passwordless sudo.

### Configuration-option reminder

| Purpose | Correct option name |
|---|---|
| Collection search path | `collections_paths` |
| Role search path | `roles_path` |
| Default remote user | `remote_user` |
| SSH private key | `private_key_file` |

Pay attention to the plural `collections_paths` and singular `roles_path`.

---

## 7. Task 5 — Validate the configuration

Change into the project directory before running the checks. This is necessary because Ansible looks for `ansible.cfg` in the current working directory before checking the user-level and system-level locations.

Run appropriate commands to confirm:

1. Ansible is using the new project-specific `ansible.cfg`.
2. The configured inventory path is correct.
3. The collections path is correct.
4. The roles path is correct.
5. The remote SSH user is `ansibleadmin`.
6. The private-key path is correct.
7. The privilege-escalation settings are correct.

Useful validation commands:

```bash
ansible --version
ansible-config dump --only-changed
```

The `config file` line from `ansible --version` must show:

```text
/home/ansibleadmin/ansible-inventory-lab/ansible.cfg
```

---

## 8. Task 6 — Examine the inventory

Use Ansible inventory commands to perform the following checks:

1. Display the complete inventory hierarchy as a graph.
2. Display all variables associated with `node1`.
3. Display all variables associated with `node2`.
4. Display all variables associated with `node3`.
5. Display all variables associated with `node4`.
6. Display all variables associated with `node5`.
7. List the hosts in `dev`.
8. List the hosts in `test`.
9. List the hosts in `prod`.
10. List the hosts inherited by `webservers`.
11. List the hosts inherited by `managed_nodes`.
12. List the hosts in `balancers`.

Useful command forms:

```bash
ansible-inventory --graph
ansible-inventory --host HOSTNAME
ansible GROUP_NAME --list-hosts
```

Replace `HOSTNAME` and `GROUP_NAME` with the required host or group.

---

## 9. Task 7 — Test connectivity

Use the Ansible `ping` module to verify connectivity to:

1. `dev`
2. `test`
3. `prod`
4. `webservers`
5. `managed_nodes`
6. `balancers`

Then run an Ansible command against `managed_nodes` that displays the current user on every managed node.

Finally, use privilege escalation to confirm that Ansible can execute `whoami` as `root` on every host in `managed_nodes`.

Expected successful ping result for each target host:

```text
SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## 10. Expected project structure

When the challenge is complete, the project should have this structure:

```text
/home/ansibleadmin/ansible-inventory-lab/
├── ansible.cfg
├── inventory
├── mycollections/
└── roles/
```

---

## 11. Submission checklist

Submit the following:

- [ ] The completed `inventory` file.
- [ ] The completed `ansible.cfg` file.
- [ ] Output of `ansible --version`.
- [ ] Output of `ansible-config dump --only-changed`.
- [ ] Output of `ansible-inventory --graph`.
- [ ] Output showing the variables for `node1` through `node5`.
- [ ] Output of `ansible managed_nodes --list-hosts`.
- [ ] Successful `ping` output for `managed_nodes`.
- [ ] Output showing the normal remote user on all managed nodes.
- [ ] Output showing `root` after privilege escalation on all managed nodes.
- [ ] A short explanation of the difference between a host group and a parent group created with `:children`.

---

## 12. Important notes

- Complete the work as `ansibleadmin`, not as `root`.
- Do not modify `/home/ansibleadmin/automation` for this challenge.
- Do not place `ansible_python_interpreter` in `ansible.cfg`; it is normally an inventory variable.
- `remote_user` in `ansible.cfg` and `ansible_user` in inventory serve a similar purpose. An inventory value can override the configuration default for the applicable host or group.
- Do not add the same hosts directly under a parent group that already inherits them through `:children`.
- Do not create both a normal group and a `:children` group with the same name.
- Do not disable host-key checking merely to hide an SSH problem. Confirm the fingerprint and manage `known_hosts` correctly.
- The Ansible `ping` module is not the same as the Linux `ping` command. Ansible ping tests Ansible connectivity, SSH authentication, and Python/module execution.
- Run commands from `/home/ansibleadmin/ansible-inventory-lab` so the project configuration is selected automatically and `-i` is not required repeatedly.

## Optional extension

After completing all required tasks, find a command that prints each inventory hostname together with its `ansible_host` IP address. This should help demonstrate the difference between the inventory alias (`node1`) and the actual connection address (`192.168.1.154`).
