# Nginx Learning Lab

A structured, bilingual learning repository for studying **Nginx**, practicing manual web-server administration, and automating static website deployment with **Ansible**.

The repository includes English and Roman Urdu study notes, practical assignments, complete solutions, ad-hoc command labs, a playbook-based solution, SELinux guidance, HTTP verification exercises, and an interactive 25-question quiz.

![Nginx Learning Lab](Nginx.png)

## Live Interactive Quiz

Test your Nginx knowledge through the published interactive quiz:

### [Launch the Nginx Concepts — 25 MCQs Quiz](https://khalidkhan.me/mcqs/nginx-web-server/nginx-concepts-25-mcqs-interactive-quiz.html)

Quiz features:

- 25 Nginx multiple-choice questions
- 25-minute countdown timer
- 80% passing score
- Questions and choices shuffled on every attempt
- Live progress and answered-question counter
- Automatic scoring and timeout submission
- Topic-wise performance breakdown
- Correct-answer review and explanations
- Incorrect-only review option
- Responsive offline-friendly interface

---

## Table of Contents

1. [Learning Objectives](#learning-objectives)
2. [Repository Structure](#repository-structure)
3. [English Resources](#english-resources)
4. [Roman Urdu Resources](#roman-urdu-resources)
5. [Interactive MCQ](#interactive-mcq)
6. [Recommended Learning Path](#recommended-learning-path)
7. [How to Use the Repository](#how-to-use-the-repository)
8. [Lab Environment](#lab-environment)
9. [Important Safety Notes](#important-safety-notes)
10. [Suggested Repository Improvement](#suggested-repository-improvement)

---

## Learning Objectives

After working through this repository, you should be able to:

- explain what Nginx is and where it is used;
- install, start, enable, reload, and verify Nginx;
- understand document roots and the role of `index.html`;
- deploy static website templates manually;
- automate static website deployment with Ansible ad-hoc commands;
- deploy the same website through an Ansible playbook;
- host multiple websites through URL subdirectories;
- configure multiple websites through separate hostnames;
- understand Nginx server blocks and `server_name`;
- verify websites with the Ansible `uri` module and `curl`;
- interpret HTTP status codes such as `200`, `403`, and `404`;
- manage Linux ownership, permissions, firewalld, and SELinux contexts;
- use `restorecon` and persistent SELinux file-context mappings;
- troubleshoot common Nginx deployment failures;
- perform safe cleanup after completing a lab.

---

## Repository Structure

```text
Nginx/
├── README.md
├── Nginx.png
├── English/
│   ├── Ansible_Nginx_Static_Website_Deployment_Challenge.md
│   ├── Ansible_Nginx_Static_Website_Deployment_AdHoc_Solution.md
│   ├── Ansible_Nginx_Static_Website_Deployment_Playbook_Solution.md
│   ├── Nginx_Introduction_and_Usage_Study_Notes.md
│   ├── md/
│   │   ├── Ansible_Restorecon_AdHoc_Command_Study_Notes.md
│   │   ├── Ansible_URI_Status_Code_Study_Notes_English.md
│   │   └── Nginx_Index_HTML_Home_Page_Study_Notes.md
│   ├── Multiple-templets/
│   │   ├── Ansible_Multiple_Nginx_Websites_Assignment.md
│   │   └── Ansible_Multiple_Nginx_Websites_Solution.md
│   └── single-server/
│       └── Manual_Nginx_Multiple_Static_Websites_Study_Notes.md
├── Urdu/
│   ├── Ansible_Nginx_Static_Website_Deployment_Challenge_Roman_Urdu.md
│   ├── Ansible_Nginx_Static_Website_Deployment_AdHoc_Solution_Roman_Urdu.md
│   ├── Ansible_Nginx_Static_Website_Deployment_Playbook_Solution_Roman_Urdu.md
│   ├── Nginx_Introduction_and_Usage_Study_Notes_Roman_Urdu.md
│   ├── md/
│   │   ├── Ansible_Restorecon_AdHoc_Command_Study_Notes_Roman_Urdu.md
│   │   ├── Ansible_URI_Status_Code_Study_Notes_Roman_Urdu.md
│   │   └── Nginx_Index_HTML_Home_Page_Study_Notes_Roman_Urdu.md
│   ├── multiple-templates/
│   │   ├── Ansible_Multiple_Nginx_Websites_Assignment_Roman_Urdu.md
│   │   └── Ansible_Multiple_Nginx_Websites_Solution_Roman_Urdu.md
│   └── single-server/
│       └── Manual_Nginx_Multiple_Static_Websites_Study_Notes_Roman_Urdu.md
└── MCQS/
    └── nginx-concepts-25-mcqs-interactive-quiz.html
```

---

## English Resources

### Introduction and Core Concepts

- [Nginx Introduction and Usage Study Notes](English/Nginx_Introduction_and_Usage_Study_Notes.md)
- [Understanding index.html as a Homepage](English/md/Nginx_Index_HTML_Home_Page_Study_Notes.md)
- [Ansible URI and HTTP Status Code Notes](English/md/Ansible_URI_Status_Code_Study_Notes_English.md)
- [Ansible restorecon Ad-Hoc Command Notes](English/md/Ansible_Restorecon_AdHoc_Command_Study_Notes.md)

### Static Website Deployment Lab

- [Deployment Challenge](English/Ansible_Nginx_Static_Website_Deployment_Challenge.md)
- [Ad-Hoc Command Solution](English/Ansible_Nginx_Static_Website_Deployment_AdHoc_Solution.md)
- [Playbook Solution](English/Ansible_Nginx_Static_Website_Deployment_Playbook_Solution.md)

### Multiple Websites

- [Multiple Nginx Websites Assignment](English/Multiple-templets/Ansible_Multiple_Nginx_Websites_Assignment.md)
- [Multiple Nginx Websites Solution](English/Multiple-templets/Ansible_Multiple_Nginx_Websites_Solution.md)

### Manual Deployment Without Ansible

- [Manual Nginx Multiple Websites Study Notes](English/single-server/Manual_Nginx_Multiple_Static_Websites_Study_Notes.md)

---

## Roman Urdu Resources

### Introduction aur Core Concepts

- [Nginx Introduction aur Usage Study Notes](Urdu/Nginx_Introduction_and_Usage_Study_Notes_Roman_Urdu.md)
- [index.html ko Homepage ke Taur par Samajhna](Urdu/md/Nginx_Index_HTML_Home_Page_Study_Notes_Roman_Urdu.md)
- [Ansible URI aur HTTP Status Code Notes](Urdu/md/Ansible_URI_Status_Code_Study_Notes_Roman_Urdu.md)
- [Ansible restorecon Ad-Hoc Command Notes](Urdu/md/Ansible_Restorecon_AdHoc_Command_Study_Notes_Roman_Urdu.md)

### Static Website Deployment Lab

- [Deployment Challenge — Roman Urdu](Urdu/Ansible_Nginx_Static_Website_Deployment_Challenge_Roman_Urdu.md)
- [Ad-Hoc Command Solution — Roman Urdu](Urdu/Ansible_Nginx_Static_Website_Deployment_AdHoc_Solution_Roman_Urdu.md)
- [Playbook Solution — Roman Urdu](Urdu/Ansible_Nginx_Static_Website_Deployment_Playbook_Solution_Roman_Urdu.md)

### Multiple Websites

- [Multiple Nginx Websites Assignment — Roman Urdu](Urdu/multiple-templates/Ansible_Multiple_Nginx_Websites_Assignment_Roman_Urdu.md)
- [Multiple Nginx Websites Solution — Roman Urdu](Urdu/multiple-templates/Ansible_Multiple_Nginx_Websites_Solution_Roman_Urdu.md)

### Ansible ke Baghair Manual Deployment

- [Manual Nginx Multiple Websites Study Notes — Roman Urdu](Urdu/single-server/Manual_Nginx_Multiple_Static_Websites_Study_Notes_Roman_Urdu.md)

---

## Interactive MCQ

The quiz file can also be opened locally without a web server:

```text
MCQS/nginx-concepts-25-mcqs-interactive-quiz.html
```

Open it by double-clicking the HTML file or through a terminal:

```bash
xdg-open MCQS/nginx-concepts-25-mcqs-interactive-quiz.html
```

Windows PowerShell:

```powershell
start .\MCQS\nginx-concepts-25-mcqs-interactive-quiz.html
```

Live version:

<https://khalidkhan.me/mcqs/nginx-web-server/nginx-concepts-25-mcqs-interactive-quiz.html>

---

## Recommended Learning Path

Follow this order for better understanding:

1. Read the Nginx introduction and usage notes.
2. Study how `index.html` becomes a website homepage.
3. Install Nginx manually and verify the service.
4. Complete the deployment challenge without reading the solution.
5. Compare your work with the Ansible ad-hoc solution.
6. Repeat the deployment through the playbook solution.
7. Study `uri`, HTTP status codes, and `restorecon`.
8. Practice hosting Space Science and Frozen Yogurt Shop as multiple websites.
9. Complete the same multiple-website lab manually without Ansible.
10. Take the 25-question interactive quiz.
11. Review incorrect answers and repeat the quiz.

---

## How to Use the Repository

### Extract the Downloaded Archive

```bash
unzip Nginx.zip
cd Nginx
```

### Read Markdown Files

Markdown files can be viewed through:

- GitHub;
- Visual Studio Code;
- Obsidian;
- Typora;
- any text editor with Markdown preview support.

### Run the Practical Labs

Use a dedicated practice environment. Review every command before running it, especially commands that:

- install or remove packages;
- modify `/etc/nginx`;
- modify firewalld;
- change SELinux mappings;
- recursively change permissions;
- use `rm -rf` for cleanup.

---

## Lab Environment

The examples are designed around the following environment:

| Component | Example |
|---|---|
| Control node | Rocky Linux 9 with Ansible |
| Control user | `ansibleadmin` |
| Managed node | `node1` |
| Managed-node IP | `192.168.1.154` |
| Inventory group | `three_tier_app` |
| Web server | Nginx |
| HTTP service | TCP port `80` |
| SELinux | Enforcing and enabled |
| Firewall | firewalld enabled |

Update IP addresses, usernames, inventory groups, hostnames, SSH keys, and document roots according to your own lab.

---

## Important Safety Notes

- Pilot automation on `node1` before targeting a group.
- Do not use `ansible all` for destructive cleanup when the control node might be part of `all`.
- Run `nginx -t` before every reload.
- Keep SELinux enabled and correct the file contexts instead of disabling it.
- Keep firewalld enabled and allow only the required services.
- Preview paths before using `rm -rf`.
- Do not remove `/etc/nginx` when cleaning only a lab website.
- Take a backup before replacing an existing production configuration.
- Use these exercises in a personal lab, not directly on a production server.

---

## Suggested Repository Improvement

For consistent naming, consider renaming the English directory:

```text
English/Multiple-templets/
```

to:

```text
English/multiple-templates/
```

If you rename it, also update the relative links in this README.

---

## Author

**Muhammad Khalid Khan**

- Website: [khalidkhan.me](https://khalidkhan.me/)
- Nginx Quiz: [Launch Interactive Quiz](https://khalidkhan.me/mcqs/nginx-web-server/nginx-concepts-25-mcqs-interactive-quiz.html)

---

## Feedback

If you find an issue, improve a command, or add another useful Nginx exercise, document the change clearly so other learners can reproduce it safely.

Happy learning and keep practicing!
