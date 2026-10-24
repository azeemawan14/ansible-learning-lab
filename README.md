# Ansible Learning Lab

A phase-based, bilingual Ansible study repository for Rocky Linux. It contains English and Roman Urdu study notes, guided labs, assignments, quizzes, troubleshooting cases, and a working three-node automation environment.

## Suggested Study Sequence

Foundations → control node and SSH → inventory and configuration → ad hoc commands → YAML and playbooks → variables and loops → projects → troubleshooting → automation workspace.

## Study and Lab Status

Status describes the material currently documented in this repository. **Completed** means the named notes or lab record exists, **In progress** means useful material exists but more practical evidence is planned, and **Planned** means the next learning milestone has not yet been documented.

| Section | Status | Documented checkpoint / remaining work |
| --- | --- | --- |
| 01. Foundations | Completed — notes available | Core terms and Linux ping versus Ansible ping documented |
| 02. Control Node and SSH | Completed — recorded scope | Rocky Linux setup, SSH keys, SCP, VS Code and Remote SSH documented |
| 03. Inventory and Configuration | Completed — notes and examples | Static inventory, variables and configuration precedence documented |
| 04. Ad Hoc Commands and Modules | Completed — labs available | Common modules, arguments, `get_url` and hands-on labs included |
| 05. YAML and Playbooks | Completed — introductory scope | YAML, playbook structure, reusable task files, quiz and first labs included |
| 06. Variables, Facts and Loops | Completed — introductory scope | Variable sources, facts, loops, posters and six-task lab included |
| 07. Projects and Assignments | In progress | Inventory, SSH banner and Nginx assignments exist; more projects planned |
| 08. Troubleshooting and Maintenance | Completed — existing cases | SSH connection-refused case and controlled `/tmp` cleanup documented |
| 09. Automation Workspace | In progress | Working inventory, configuration and connectivity playbook included |

## Current Lab Environment

| Role | Inventory name | IP address | Purpose |
| --- | --- | --- | --- |
| Control node | `ansible-server` | `192.168.1.233` | Runs Ansible commands and playbooks |
| Managed node | `node1` | `192.168.1.154` | Web-server practice |
| Managed node | `node2` | `192.168.1.185` | Application-server practice |
| Managed node | `node3` | `192.168.1.190` | Database-server practice |

These are private LAN examples from the personal lab. Students should replace them with values from their own environment.

## 01. Foundations

Ansible terminology, architecture and connectivity fundamentals.

[Open topic guide](01_Foundations/README.md)

## 02. Control Node and SSH

Rocky Linux control-node preparation, SSH keys, SCP, VS Code and Remote SSH.

[Open topic guide](02_Control_Node_and_SSH/README.md)

## 03. Inventory and Configuration

Static inventories, groups, variables, `ansible.cfg` and configuration precedence.

[Open topic guide](03_Inventory_and_Configuration/README.md)

## 04. Ad Hoc Commands and Modules

Command structure, common modules, module arguments and guided practice.

[Open topic guide](04_Ad_Hoc_Commands_and_Modules/README.md)

## 05. YAML and Playbooks

YAML data structures, playbook anatomy, reusable task files and validation.

[Open topic guide](05_YAML_and_Playbooks/README.md)

## 06. Variables, Facts and Loops

Variable sources, facts, loops, conditions and combined practical exercises.

[Open topic guide](06_Variables_Facts_and_Loops/README.md)

## 07. Projects and Assignments

Hands-on challenges, solutions, Nginx deployment and SSH banner practice.

[Open topic guide](07_Projects_and_Assignments/README.md)

## 08. Troubleshooting and Maintenance

Real troubleshooting scenarios, verification steps and lab cleanup procedures.

[Open topic guide](08_Troubleshooting_and_Maintenance/README.md)

## 09. Automation Workspace

The active configuration, inventory and executable playbook examples.

[Open workspace guide](09_Automation_Workspace/README.md)

## Additional Resources

Reference material and supporting Linux, Git, Docker and repository notes.

[Browse additional resources](Additional_Resources/README.md)

## Archive

Legacy indexes, unrelated historical material and the earlier organization helper remain available for reference. The numbered folders above are the current reading route.

[Browse archive](Archive/README.md)

## Quick Start

```bash
cd 09_Automation_Workspace
ansible --version
ansible-inventory --graph
ansible all -m ping
ansible-playbook playbooks/01-connectivity-check.yml --syntax-check
ansible-playbook playbooks/01-connectivity-check.yml
```

Review inventory addresses, the SSH username and the private-key path before running commands on another system.

## Repository Rules

- Keep English and Roman Urdu notes under the relevant topic.
- Use a lab for guided practice and an assignment for independent work.
- Keep questions and solutions clearly identified.
- Store screenshots beside the lab or scenario they support.
- Keep superseded material in `Archive/`; do not mix it into the main study route.
- Never commit passwords, private keys, Vault passwords or access tokens.

[File Move Map](FILE_MOVE_MAP.csv) | [Link Review](LINK_REVIEW.md)
