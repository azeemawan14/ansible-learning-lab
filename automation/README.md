# Automation Workspace

This directory is the working Ansible project.

```text
automation/
├── ansible.cfg
├── inventory
└── playbooks/
```

## Usage

```bash
cd automation
ansible --version
ansible-inventory --graph
ansible all -m ping
ansible-playbook playbooks/01-connectivity-check.yml --syntax-check
ansible-playbook playbooks/01-connectivity-check.yml
```

Ansible reads the project-level `ansible.cfg` when commands are run from this directory. Review inventory addresses, usernames, and private-key paths before using the project on another system.
