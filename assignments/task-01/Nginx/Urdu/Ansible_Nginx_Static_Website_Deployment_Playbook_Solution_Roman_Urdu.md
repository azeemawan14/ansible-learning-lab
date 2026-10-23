# Roman Urdu Playbook Solution: Nginx par Static Website Deploy Karein

## Fehrist

1. [Playbook kyun?](#1-playbook-kyun)
2. [Project Structure](#2-project-structure)
3. [Deployment Playbook](#3-deployment-playbook)
4. [Playbook ki Wazahat](#4-playbook-ki-wazahat)
5. [Validate aur Run](#5-validate-aur-run)
6. [Pilot aur Full Deployment](#6-pilot-aur-full-deployment)
7. [Verification aur Idempotency](#7-verification-aur-idempotency)
8. [Cleanup Playbook](#8-cleanup-playbook)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Playbook kyun?

Ad-hoc commands demonstration aur one-time work ke liye useful hain. Repeatable deployment ke liye playbook behtar hai kyun ke:

- Desired state YAML file mein save hoti hai.
- Tasks defined order mein chalte hain.
- Variables aur conditions use hoti hain.
- Execution se pehle syntax check ho sakta hai.
- Pilot node par `--limit` lagaya ja sakta hai.
- Git mein version control ho sakta hai.

Is solution mein aap ki preference ke mutabiq short module names use hue hain.

---

## 2. Project Structure

```text
/home/ansibleadmin/automation/
├── ansible.cfg
├── inventory/
│   └── nodes
└── playbooks/
    ├── deploy-space-science.yml
    └── cleanup-space-science.yml
```

Directory banayein:

```bash
mkdir -p /home/ansibleadmin/automation/playbooks
cd /home/ansibleadmin/automation
```

> **Lab prerequisite:** managed nodes par `lawfirm.com` ka Nginx server block `/var/www/lawfirm.com/html` use karta ho. All nodes ko target karne se pehle `nginx -T` se confirm karein. Yeh playbook website content deploy karta hai; server block create nahi karta.

---

## 3. Deployment Playbook

File banayein:

```text
/home/ansibleadmin/automation/playbooks/deploy-space-science.yml
```

Content:

```yaml
---
- name: Install Nginx and deploy the Space Science website
  hosts: three_tier_app
  become: true

  vars:
    website_url: "https://freewebsitetemplates.com/download/space-science/"
    archive_path: "/tmp/space-science.zip"
    extraction_directory: "/tmp/space-science-extracted"
    extracted_website: "/tmp/space-science-extracted/space-science/upload"
    extracted_index: "/tmp/space-science-extracted/space-science/upload/index.html"
    nginx_document_root: "/var/www/lawfirm.com/html"
    website_index: "/var/www/lawfirm.com/html/index.html"
    website_uri: "http://localhost"

  tasks:
    - name: Install Nginx
      dnf:
        name: nginx
        state: present

    - name: Install unzip
      dnf:
        name: unzip
        state: present

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Allow HTTP through firewalld
      firewalld:
        service: http
        permanent: true
        immediate: true
        state: enabled

    - name: Download the website archive
      get_url:
        url: "{{ website_url }}"
        dest: "{{ archive_path }}"
        mode: "0644"

    - name: Create the temporary extraction directory
      file:
        path: "{{ extraction_directory }}"
        state: directory
        mode: "0755"

    - name: Extract the website archive
      unarchive:
        src: "{{ archive_path }}"
        dest: "{{ extraction_directory }}"
        remote_src: true
        creates: "{{ extracted_index }}"

    - name: Verify that the extracted website index exists
      stat:
        path: "{{ extracted_index }}"
      register: extracted_index_status

    - name: Stop when the archive layout is unexpected
      fail:
        msg: >-
          Expected extracted file {{ extracted_index }} par nahi mili.
          Archive ko unzip -l {{ archive_path }} se inspect karein.
      when: not extracted_index_status.stat.exists

    - name: Ensure the active Nginx document root exists
      file:
        path: "{{ nginx_document_root }}"
        state: directory
        owner: root
        group: root
        mode: "0755"

    - name: Copy only the website files into the document root
      copy:
        src: "{{ extracted_website }}/"
        dest: "{{ nginx_document_root }}/"
        remote_src: true
        owner: root
        group: root
        mode: preserve

    - name: Restore SELinux contexts on the website files
      command: "restorecon -Rv {{ nginx_document_root }}"
      register: restorecon_result
      changed_when: restorecon_result.stdout | length > 0

    - name: Verify that the website index exists
      stat:
        path: "{{ website_index }}"
      register: website_index_status

    - name: Stop when the website index is missing
      fail:
        msg: >-
          Expected index file {{ website_index }} par nahi mili.
          ZIP structure inspect karke paths update karein.
      when: not website_index_status.stat.exists

    - name: Verify the custom website
      uri:
        url: "{{ website_uri }}"
        status_code: 200
        return_content: false
      register: website_test
      changed_when: false

    - name: Display deployment result
      debug:
        msg: >-
          {{ inventory_hostname }} ne {{ website_uri }} ke liye
          HTTP {{ website_test.status }} return kiya.
```

---

## 4. Playbook ki Wazahat

### Target group

```yaml
hosts: three_tier_app
```

Yeh parent group ke zariye `node1`, `node2` aur `node3` ko target karta hai.

### Privilege escalation

```yaml
become: true
```

Package, firewall aur document-root tasks `sudo` ke sath chalenge.

### Variables

URL aur paths ek jagah store hain, is liye future changes asaan hain.

### `dnf`, `service` aur `firewalld`

- `dnf` required packages ko present rakhta hai.
- `service` Nginx ko running aur boot par enabled rakhta hai.
- `firewalld` firewall band kiye baghair HTTP allow karta hai.

### `get_url`, `unarchive` aur `copy`

- `get_url` har managed node par ZIP download karta hai.
- `remote_src: true` batata hai ke ZIP managed node par hai.
- Archive `/tmp/space-science-extracted` mein extract hoti hai.
- `creates` repeated extraction ko rokta hai jab expected source index file maujood ho.
- `copy` sirf `space-science/upload/` ke contents active document root mein copy karta hai.

### Document root aur SELinux

`file` task `/var/www/lawfirm.com/html` create karta hai. Source ke aakhir ka trailing slash sirf directory ke contents copy karta hai. `restorecon` `/tmp` se copied files par policy ke mutabiq `httpd_sys_content_t` context restore karta hai.

### Deployment se pehle `uri` test kyun nahi?

Active document root pehle khaali tha, is liye early `uri` test `403` de kar play ko deployment se pehle rok deta. Ab HTTP verification website copy hone ke baad hoti hai.

### `stat`, `fail` aur `uri`

- `stat` expected file check karta hai.
- `fail` wrong archive structure par clear error deta hai.
- `uri` HTTP `200` verify karta hai.

### Nginx reload kyun nahi?

Sirf static files change hui hain, Nginx configuration nahi. Is liye reload zaroori nahi.

---

## 5. Validate aur Run

Syntax check:

```bash
ansible-playbook --syntax-check playbooks/deploy-space-science.yml
```

Target hosts aur tasks dekhein:

```bash
ansible-playbook playbooks/deploy-space-science.yml --list-hosts
ansible-playbook playbooks/deploy-space-science.yml --list-tasks
```

Optional check mode:

```bash
ansible-playbook playbooks/deploy-space-science.yml --check --limit node1
```

Network aur archive operations check mode mein completely simulate na bhi hon; actual verification phir bhi zaroori hai.

---

## 6. Pilot aur Full Deployment

Pehle sirf `node1`:

```bash
ansible-playbook playbooks/deploy-space-science.yml --limit node1
```

Browser test:

```text
http://192.168.1.154/
```

Pilot successful ho to all nodes:

```bash
ansible-playbook playbooks/deploy-space-science.yml
```

Full deployment se pehle confirm karein ke teenon nodes par wohi `lawfirm.com` document root configured hai.

---

## 7. Verification aur Idempotency

```bash
ansible three_tier_app -m command -a "systemctl is-active nginx"
ansible three_tier_app -m stat -a "path=/var/www/lawfirm.com/html/index.html"
ansible three_tier_app -m uri -a "url=http://localhost status_code=200"
```

Playbook dobara chalayein:

```bash
ansible-playbook playbooks/deploy-space-science.yml
```

Ideal second-run recap:

```text
changed=0
failed=0
unreachable=0
```

Yeh dikhata hai ke required state pehle se maujood hai aur unnecessary changes nahi hue.

---

## 8. Cleanup Playbook

File:

```text
/home/ansibleadmin/automation/playbooks/cleanup-space-science.yml
```

Content:

```yaml
---
- name: Remove the Space Science website lab
  hosts: three_tier_app
  become: true

  vars:
    website_root: "/var/www/lawfirm.com"
    archive_path: "/tmp/space-science.zip"
    extraction_directory: "/tmp/space-science-extracted"
    full_reset: false

  tasks:
    - name: Remove the deployed website
      file:
        path: "{{ website_root }}"
        state: absent

    - name: Remove the downloaded archive
      file:
        path: "{{ archive_path }}"
        state: absent

    - name: Remove the temporary extraction directory
      file:
        path: "{{ extraction_directory }}"
        state: absent

    - name: Stop and disable Nginx during a full reset
      service:
        name: nginx
        state: stopped
        enabled: false
      when: full_reset | bool

    - name: Remove Nginx packages during a full reset
      dnf:
        name:
          - nginx
          - nginx-core
          - nginx-filesystem
        state: absent
      when: full_reset | bool

    - name: Disable HTTP firewall access during a full reset
      firewalld:
        service: http
        permanent: true
        immediate: true
        state: disabled
      when: full_reset | bool
```

Website aur temporary deployment files remove karein:

```bash
ansible-playbook playbooks/cleanup-space-science.yml
```

Is se custom Nginx configuration rehti hai taa-ke lab dobara ki ja sake.

Nginx packages aur firewall rule bhi reset karein:

```bash
ansible-playbook playbooks/cleanup-space-science.yml \
-e "full_reset=true"
```

Pehle sirf `node1` par cleanup test karein:

```bash
ansible-playbook playbooks/cleanup-space-science.yml --limit node1
```

---

## 9. Troubleshooting

ZIP structure dekhein:

```bash
ansible three_tier_app --limit node1 -m command -a "unzip -l /tmp/space-science.zip"
```

Actual index path dhoondein:

```bash
ansible three_tier_app --limit node1 -b -m shell -a "find /tmp/space-science-extracted -name index.html -print"
```

HTTP 403 par permissions aur context check karein:

```bash
ansible three_tier_app --limit node1 -m command -a "namei -l /var/www/lawfirm.com/html/index.html"
ansible three_tier_app --limit node1 -m command -a "ls -lZ /var/www/lawfirm.com/html/index.html"
```

Browser connect na kare to Nginx aur firewall check karein:

```bash
ansible three_tier_app --limit node1 -m command -a "systemctl is-active nginx"
ansible three_tier_app --limit node1 -b -m command -a "firewall-cmd --list-services"
```
