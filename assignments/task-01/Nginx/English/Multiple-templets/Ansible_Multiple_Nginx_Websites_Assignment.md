# Assignment: Deploy Two Static Websites with Ansible and Nginx

## Table of Contents

1. [Scenario](#1-scenario)
2. [Learning Objectives](#2-learning-objectives)
3. [Lab Environment](#3-lab-environment)
4. [Rules and Safety](#4-rules-and-safety)
5. [Template Preparation](#5-template-preparation)
6. [Method 1: URL Subdirectories](#6-method-1-url-subdirectories)
7. [Method 2: Separate Hostnames](#7-method-2-separate-hostnames)
8. [Verification Requirements](#8-verification-requirements)
9. [Idempotency Test](#9-idempotency-test)
10. [Cleanup Requirements](#10-cleanup-requirements)
11. [Evidence to Submit](#11-evidence-to-submit)
12. [Hints](#12-hints)
13. [Assessment Rubric](#13-assessment-rubric)

---

## 1. Scenario

You manage a Rocky Linux 9 server with Ansible. Your task is to deploy two static website templates through Nginx:

1. Space Science
2. Frozen Yogurt Shop

You must complete the deployment using two different Nginx designs:

- Method 1: both websites are accessed through paths under one IP address;
- Method 2: both websites use separate hostnames while sharing port 80.

Perform the pilot deployment on `node1` before targeting additional managed nodes.

---

## 2. Learning Objectives

After completing the assignment, you should be able to:

- prepare static website source files;
- install and manage Nginx with Ansible;
- deploy multiple websites with the `copy` module;
- understand URL-to-filesystem mapping;
- configure Nginx virtual hosts;
- validate Nginx configuration before reloading;
- use SELinux-compatible document roots;
- verify websites with HTTP status codes;
- test Ansible idempotency;
- clean the lab without affecting the control node.

---

## 3. Lab Environment

| Item | Value |
|---|---|
| Control node user | `ansibleadmin` |
| Project directory | `/home/ansibleadmin/automation` |
| Pilot managed node | `node1` |
| node1 IP | `192.168.1.154` |
| Managed-node group | `three_tier_app` |
| Operating system | Rocky Linux 9 |
| Web server | Nginx |
| HTTP port | `80` |

Recommended local project structure:

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
├── files/
│   ├── sites/
│   │   ├── space-science/
│   │   └── frozen-yogurt/
│   └── nginx/
│       ├── space.conf
│       └── yogurt.conf
└── evidence/
```

---

## 4. Rules and Safety

1. Use `node1` or `--limit node1` for the pilot deployment.
2. Do not use `ansible all` for destructive cleanup; the control node may be included in `all`.
3. Use `three_tier_app` only after the pilot succeeds.
4. Run `nginx -t` before reloading Nginx.
5. Do not disable SELinux.
6. Do not disable firewalld; allow only the required HTTP service.
7. Retain copyright notices in the downloaded template source.
8. Do not redistribute or sell the original template files.

Review the current template terms before use:

```text
https://freewebsitetemplates.com/about/terms
```

---

## 5. Template Preparation

Download these templates from the official website:

```text
https://freewebsitetemplates.com/
```

- Space Science Template
- Frozen Yogurt Shop Template

### Task 1: Create the local source directories

Create:

```text
/home/ansibleadmin/automation/files/sites/space-science/
/home/ansibleadmin/automation/files/sites/frozen-yogurt/
```

### Task 2: Inspect both ZIP archives

Use an appropriate command to:

- confirm that each download is a ZIP archive;
- list its contents;
- locate the deployable `index.html`;
- identify the directory containing the HTML, CSS, JavaScript, fonts, and images.

### Task 3: Prepare clean source directories

Copy only the deployable website files into the two local source directories.

Each directory must contain its own `index.html` at the top level:

```text
files/sites/space-science/index.html
files/sites/frozen-yogurt/index.html
```

Do not place PSD design sources or unrelated archive folders in the deployment directories.

---

## 6. Method 1: URL Subdirectories

Deploy both websites under one active Nginx document root.

### Required filesystem layout

```text
/var/www/lawfirm.com/html/
├── space-science/
│   └── index.html
└── frozen-yogurt/
    └── index.html
```

### Required browser URLs

```text
http://192.168.1.154/space-science/
http://192.168.1.154/frozen-yogurt/
```

### Tasks

1. Install `nginx`.
2. Start and enable the Nginx service.
3. Allow HTTP through firewalld.
4. Create both remote website directories.
5. Copy the Space Science site from the control node.
6. Copy the Frozen Yogurt Shop site from the control node.
7. Set appropriate ownership and permissions.
8. Restore SELinux contexts.
9. Verify that both remote `index.html` files exist.
10. Verify HTTP status `200` for both URLs.

### Written question

Explain why this URL:

```text
http://192.168.1.154/space-science/
```

maps to:

```text
/var/www/lawfirm.com/html/space-science/index.html
```

---

## 7. Method 2: Separate Hostnames

Configure two Nginx virtual hosts that share the same IP address and TCP port 80.

### Required design

| Hostname | Document root |
|---|---|
| `space.nitclasses.com` | `/var/www/space/html` |
| `yogurt.nitclasses.com` | `/var/www/yogurt/html` |

### Tasks

1. Create both document roots.
2. Deploy the correct website into each root.
3. Create a separate Nginx server block for each hostname.
4. Configure `root` and `index` correctly.
5. Copy both server-block files to `/etc/nginx/conf.d/`.
6. Validate the complete Nginx configuration.
7. Reload Nginx only after validation succeeds.
8. Add hostname resolution on the client through DNS or its hosts file.
9. Verify both websites through their hostnames.

### Client hosts-file entries

```text
192.168.1.154 space.nitclasses.com
192.168.1.154 yogurt.nitclasses.com
```

### Required browser URLs

```text
http://space.nitclasses.com/
http://yogurt.nitclasses.com/
```

### Written question

Both websites use `192.168.1.154:80`. Explain how Nginx decides which website to serve.

---

## 8. Verification Requirements

Verify all of the following:

- Nginx is active.
- Nginx is enabled at boot.
- TCP port 80 is listening.
- HTTP is allowed through firewalld.
- All required `index.html` files exist.
- Website files have web-readable SELinux contexts.
- `nginx -t` reports a successful configuration test.
- All four required URLs return HTTP `200` during the appropriate stage.

---

## 9. Idempotency Test

Run every state-management ad-hoc command a second time.

Document which commands report:

```text
changed=false
```

Explain why a `command` task may still report `CHANGED` even when it only performs verification.

---

## 10. Cleanup Requirements

Create a safe cleanup procedure that removes only lab resources:

- `/var/www/lawfirm.com/html/space-science`
- `/var/www/lawfirm.com/html/frozen-yogurt`
- `/var/www/space`
- `/var/www/yogurt`
- `/etc/nginx/conf.d/space.conf`
- `/etc/nginx/conf.d/yogurt.conf`

After removing the server blocks:

1. validate the remaining Nginx configuration;
2. reload Nginx;
3. confirm the lab URLs no longer return the deployed sites.

Do not remove `/etc/nginx` or other unrelated websites.

---

## 11. Evidence to Submit

Submit:

1. inventory host list;
2. successful Ansible ping output;
3. archive inspection output;
4. local prepared directory trees;
5. important ad-hoc commands used;
6. `nginx -t` output;
7. `ls -lZ` output for each document root;
8. HTTP verification output;
9. browser screenshots of both sites for each method;
10. second-run idempotency results;
11. cleanup verification.

---

## 12. Hints

- Use `file` to create and remove directories.
- Use `copy` to transfer prepared website directories from the control node.
- A trailing slash in `src=directory/` copies the directory contents.
- Use `dnf` for package management.
- Use `service` for Nginx state.
- Use `firewalld` to allow HTTP.
- Use `stat` to verify files.
- Use `uri` to check HTTP status.
- Use `restorecon -Rv` after copying web content.
- Use `copy` with `validate="/usr/sbin/nginx -t -c %s"` only when the validation command is suitable for the complete configuration; otherwise copy to a temporary path and run `nginx -t` before reload.
- Named virtual hosts are selected through the HTTP `Host` header.

---

## 13. Assessment Rubric

| Area | Points |
|---|---:|
| Prechecks and safe pilot workflow | 10 |
| Template preparation | 15 |
| Method 1 deployment | 20 |
| Method 2 virtual-host deployment | 25 |
| SELinux, firewall, and permissions | 10 |
| Verification and troubleshooting | 10 |
| Idempotency and cleanup | 10 |
| **Total** | **100** |
