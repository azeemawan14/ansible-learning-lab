# Automation Workspace

This directory is the working Ansible project.

```text
09_Automation_Workspace/
├── ansible.cfg
├── inventory
└── playbooks/
```

## Usage

```bash
cd 09_Automation_Workspace
ansible --version
ansible-inventory --graph
ansible all -m ping
ansible-playbook playbooks/01-connectivity-check.yml --syntax-check
ansible-playbook playbooks/01-connectivity-check.yml
```

Ansible reads the project-level `ansible.cfg` when commands are run from this directory. Review inventory addresses, usernames, and private-key paths before using the project on another system.

## Current Inventory Groups

- `web` — `node1`
- `app` — `node2`
- `db` — `node3`
- `application` — child group containing `web` and `app`
- `three_tier_app` — child group containing all three managed-node groups

Return to the [main repository guide](../README.md).
