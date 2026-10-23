# Ansible Learning Lab

A bilingual, hands-on Ansible learning repository for Rocky Linux. It combines study notes, guided labs, assignments, troubleshooting scenarios, quizzes, and reusable automation examples in English and Roman Urdu.

## Start Here

1. Review the [lab environment](#lab-environment).
2. Read the [English study notes](study-notes/english/README.md) or [Roman Urdu study notes](study-notes/urdu-roman/README.md).
3. Open [automation](automation/README.md) to inspect the working inventory and configuration.
4. Practice with the [labs](labs/README.md).
5. Complete the [assignments](assignments/README.md) without reading the solutions first.
6. Use [scenarios](scenarios/README.md) for troubleshooting practice.

## Learning Path and Status

| Phase | Topic | Status |
| --- | --- | --- |
| 1 | Ansible fundamentals | Complete |
| 2 | Control-node setup | Complete |
| 3 | Inventory and configuration | Complete |
| 4 | Ad hoc commands | Complete |
| 5 | YAML and playbooks | Complete |
| 6 | Variables and loops | Complete |
| 7 | Nginx and SSH banner deployments | Complete |
| 8 | Roles, templates, handlers, and Vault | Planned |

## Lab Environment

| Role | Inventory name | IP address | Purpose |
| --- | --- | --- | --- |
| Control node | `ansible-server` | `192.168.1.233` | Runs Ansible |
| Managed node | `node1` | `192.168.1.154` | Web-server practice |
| Managed node | `node2` | `192.168.1.185` | Application-server practice |
| Managed node | `node3` | `192.168.1.190` | Database-server practice |

> These private LAN addresses are examples from the personal lab. Students should replace them with addresses from their own environment.

### Control-node software

- Rocky Linux 9
- Python 3 at `/usr/bin/python3`
- Ansible Core 2.14
- Automation account: `ansibleadmin`

## Repository Map

| Directory | Purpose |
| --- | --- |
| [`automation/`](automation/README.md) | Active `ansible.cfg`, inventory, and playbook workspace |
| [`study-notes/`](study-notes/README.md) | Topic-based English and Roman Urdu notes |
| [`labs/`](labs/README.md) | Guided hands-on exercises |
| [`assignments/`](assignments/README.md) | Challenges, solutions, presentations, PDFs, and quizzes |
| [`scenarios/`](scenarios/README.md) | Real troubleshooting case studies with screenshots |
| [`maintenance/`](maintenance/README.md) | Lab cleanup and maintenance procedures |
| [`supplemental/`](supplemental/README.md) | Supporting Linux, SSH, SCP, and repository notes |
| [`resources/`](resources/README.md) | External reference material |

## Quick Commands

Run these commands from the repository's `automation/` directory:

```bash
cd automation

# Confirm the active configuration file
ansible --version

# Inspect inventory structure and host variables
ansible-inventory --graph
ansible-inventory --host node1

# Test managed-node connectivity
ansible all -m ping

# Run a simple ad hoc command
ansible all -m command -a "hostname"

# Validate a playbook before execution
ansible-playbook playbooks/01-connectivity-check.yml --syntax-check

# Preview supported changes
ansible-playbook playbooks/01-connectivity-check.yml --check --diff
```

## Naming and Organization Rules

- English and Roman Urdu material stays in separate language directories.
- A **lab** is guided practice; an **assignment** is completed independently.
- A **scenario** documents a real problem, diagnosis, fix, and verification.
- Assignment folders keep the question and solution together, with clear filenames.
- Images, PDFs, presentations, and HTML quizzes stay beside the topic they support.
- New playbooks belong under `automation/playbooks/` or inside the relevant lab or assignment.
- Use lowercase directory names with hyphens for new folders.

## Security Notes

- Never commit passwords, private SSH keys, Vault passwords, or access tokens.
- Use SSH key authentication for routine automation.
- Keep private keys outside this repository.
- Review `--check` and `--diff` output before applying important changes.
- Do not run classroom cleanup commands against production systems.

## Roadmap

- [x] Ansible introduction and architecture
- [x] Control-node preparation
- [x] Static inventory and configuration
- [x] Common modules and ad hoc commands
- [x] YAML and playbook fundamentals
- [x] Variables, facts, conditions, and loops
- [x] Nginx and SSH banner practice
- [ ] Handlers and templates
- [ ] Ansible Vault
- [ ] Roles and Ansible Galaxy
- [ ] Multi-role end-to-end project

## Repository Note

This is a learning repository. Commands and IP addresses are designed for an isolated personal or classroom lab and should be reviewed before reuse elsewhere.
