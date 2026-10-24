# Ansible Introduction aur Ad-Hoc Commands — Instructor Solution (Roman Urdu)

> Yeh answer key 15-task Rocky Linux homework ke mutabiq hai. Uptime, memory, disk usage, package version aur timestamps har machine par mukhtalif ho sakte hain. Students ko apni asal output submit karni chahiye.

## Lab Reference

| Role | Inventory name | IP address | Group |
|---|---|---|---|
| Control node | `ansible-server` | `192.168.1.233` | — |
| Web node | `node1` | `192.168.1.154` | `web` |
| Application node | `node2` | `192.168.1.185` | `app` |
| Database node | `node3` | `192.168.1.190` | `db` |

---

## Solution 1 — Ansible ko Samajhna

1. **Configuration management** systems ki desired state ko define, apply aur maintain karne ka automated process hai.
2. Bohat se servers par yeh configuration ko consistent rakhta, manual mistakes kam karta aur waqt bachata hai.
3. **Ansible** configuration management, deployment, orchestration aur system-administration automation ka tool hai.
4. **Agentless** ka matlab hai ke Linux managed nodes par aam tor par permanent Ansible agent install ya run nahi karna parta.
5. Ansible SSH se connect hota hai, required module execute karta hai, result wapas leta hai aur connection close kar deta hai.
6. **Push-based** model mein control node changes nodes ko bhejta hai. **Pull-based** model mein har node ka agent central server se apni configuration leta hai.
7. Ansible aam tor par agentless hai aur YAML playbooks use karta hai. Puppet aur Chef ke traditional setups agents aur apni configuration languages use kar sakte hain.
8. **Idempotency** ka matlab hai ke desired state hasil hone ke baad wohi automation dobara chalane se unnecessary change nahi hoti.
9. Playbooks reusable, reviewable, version-controlled aur manual commands ke muqablay mein zyada consistent hoti hain.

### Architecture ke components

| Component | Wazahat | Is lab ki misaal |
|---|---|---|
| Control node | Jahan Ansible install hai aur commands chalti hain | `ansible-server` |
| Managed nodes | Jin systems ko Ansible manage karta hai | `node1`, `node2`, `node3` |
| Inventory | Hosts, groups aur connection variables define karti hai | `~/automation/inventory/nodes` |
| Configuration | Ansible ke defaults aur behavior control karti hai | `~/automation/ansible.cfg` |
| Module | Koi khaas operation perform karta hai | `ping`, `command`, `copy`, `dnf` |
| Module argument | Module ko operation ki details deta hai | `name=tree state=present` |
| Ad-hoc command | Ek quick, one-time task chalati hai | `ansible all -m ping` |
| Playbook | Plays aur tasks wali repeatable YAML automation | Package-installation playbook |

Administrator control node par Ansible command chalata hai. Ansible configuration aur inventory parhta hai, target hosts select karta hai, SSH se connect hota hai, modules chalata hai aur result report karta hai.

---

## Solution 2 — Control Node Verify Karna

| Item | Expected result |
|---|---|
| Current user | `ansibleadmin` |
| Control-node hostname | `ansible-server.nitclasses.com` |
| Ansible core version | `2.14.18` |
| Active configuration | `/home/ansibleadmin/automation/ansible.cfg`, jab command `~/automation` se chale |
| Ansible executable | `/usr/bin/ansible` |
| Control-node Python | `Python 3.9.25` |

Ansible control node par is liye install hota hai kyun ke yahi machine automation ko control karke connections start karti hai. Managed nodes par Ansible install karna aam tor par zaroori nahi, kyun ke kaam SSH ke zariye bheja jata hai. Zyada tar Linux Ansible modules Python mein execute hote hain, is liye managed nodes par Python chahiye.

> Agar system legitimately update hua ho to student ka actual version different ho sakta hai.

---

## Solution 3 — Existing Configuration Verify Karna

Expected active project configuration:

```text
/home/ansibleadmin/automation/ansible.cfg
```

| Setting | Roman Urdu explanation |
|---|---|
| `inventory` | Default inventory file ka path, jaise `./inventory/nodes` |
| `remote_user` | Default SSH login user, yani `ansibleadmin` |
| `ask_pass = False` | SSH password na poochna; key authentication use karna |
| `host_key_checking = True` | Server ki identity ko SSH `known_hosts` se verify karna |
| `become_method = sudo` | Privilege escalation ke liye `sudo` use karna |
| `become_user = root` | `root` user ke privileges hasil karna |
| `become_ask_pass = False` | Sudo password prompt na karna |

Host-key checking kisi nakli ya unexpected server se connection ka risk kam karti hai. Is lab mein SSH keys aur passwordless sudo configured hain, is liye password prompts ki zaroorat nahi.

---

## Solution 4 — Existing Inventory Verify Karna

| Inventory host | `ansible_host` | Group | SSH user | Python interpreter |
|---|---|---|---|---|
| `node1` | `192.168.1.154` | `web` | `ansibleadmin` | `/usr/bin/python3` |
| `node2` | `192.168.1.185` | `app` | `ansibleadmin` | `/usr/bin/python3` |
| `node3` | `192.168.1.190` | `db` | `ansibleadmin` | `/usr/bin/python3` |

- `inventory_hostname` inventory mein likha hua naam hai, jaise `node1`. `ansible_host` asal IP ya DNS name hai jis par connection banta hai.
- `[three_tier_app:children]` parent group hai jismein `web`, `app` aur `db` child groups shamil hain.
- `[all:vars]` ki variables har inventory host ko inherit hoti hain.
- Friendly names commands ko readable banate hain; Ansible inhein `ansible_host` se map karta hai.

Expected graph:

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

Graph ki ordering mukhtalif ho sakti hai.

---

## Solution 5 — SSH aur Ansible Connectivity

Teenon `BatchMode` SSH commands ko password poochay baghair relevant hostname return karna chahiye. Ansible ka sample result:

```text
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Yahi result `node2` aur `node3` ke liye bhi aana chahiye.

- `SUCCESS` ka matlab connection aur module execution kamyab rahe.
- `pong`, Ansible `ping` module ka successful response hai.
- Yeh ICMP `ping` nahi; yeh SSH authentication, connectivity, Python aur module execution test karta hai.
- `changed: false` batata hai ke managed node mein koi change nahi hui.
- `-v` extra connection aur execution details dikhata hai.

---

## Solution 6 — Read-Only Ad-Hoc Commands

| Maqsad | Target | Module | Argument |
|---|---|---|---|
| Uptime | `three_tier_app` | `command` | `uptime` |
| Memory | `web` | `command` | `free -h` |
| Disk usage | `three_tier_app` | `command` | `df -h` |
| Kernel | `three_tier_app` | `command` | `uname -r` |
| Remote user | `three_tier_app` | `command` | `whoami` |
| Hostname | `three_tier_app` | `command` | `hostname -f` |

`-m` module select karta hai aur `-a` module arguments deta hai. Purane Ansible versions successful `command` ko `CHANGED` report kar sakte hain, kyun ke arbitrary command ke effect ka hamesha pata nahi lagaya ja sakta. Playbook mein known read-only command ke liye use karein:

```yaml
changed_when: false
```

---

## Solution 7 — Facts aur Variables

| Host | Distribution | Version | Architecture | Python |
|---|---|---|---|---|
| `node1` | Rocky | Node par installed Rocky 9 version | `x86_64` | Node ka Python 3 version |
| `node2` | Rocky | Node par installed Rocky 9 version | `x86_64` | Node ka Python 3 version |
| `node3` | Rocky | Node par installed Rocky 9 version | `x86_64` | Node ka Python 3 version |

Students actual `setup` output se versions likhein.

- **Inventory variable** administrator define karta hai. **Fact** managed node se discover hota hai.
- `setup` module facts gather karta hai.
- Agar `ansible_python_interpreter=/usr/bin/python3` pehle se defined ho to interpreter discovery ki zaroorat nahi; is liye `discovered_interpreter_python` nazar na aaye.
- Expected mapping: `node1 → 192.168.1.154`, `node2 → 192.168.1.185`, `node3 → 192.168.1.190`.

---

## Solution 8 — Inventory Groups aur Patterns

| Pattern | Expected hosts |
|---|---|
| `web` | `node1` |
| `app` | `node2` |
| `db` | `node3` |
| `web:app` | `node1`, `node2` |
| `three_tier_app` | `node1`, `node2`, `node3` |
| `three_tier_app:!db` | `node1`, `node2` |

Colon groups ka union banata hai aur exclamation mark group ya host ko exclude karta hai. Optional groups add hon to `application` mein `node1` aur `node2`, jab ke `all_servers` mein teenon nodes hongay.

---

## Solution 9 — Temporary Content Create aur Copy Karna

- `hello.txt` pehle control node par locally create hoti hai.
- `copy` module file control node se managed nodes ko bhejta hai.
- `0644` mein owner ko read/write aur group/others ko read-only permission milti hai.
- `-b` ki zaroorat nahi, kyun ke SSH user `/tmp` ke andar directory bana sakta hai.

Remote path:

```text
/tmp/ansible-homework/hello.txt
```

Expected content:

```text
Hello from ansibleadmin
```

`stat` result mein `exists: true`, `isreg: true` aur mode `0644` expected hai.

---

## Solution 10 — Package Management aur Become

- `-b` ya `--become` configured method ke mutabiq privilege escalation enable karta hai.
- Package installation system package database aur protected paths change karti hai, is liye root privileges chahiye.
- `dnf` module package state samajhta, structured result deta aur idempotency support karta hai. Shell command kam reliable hai.
- `state=present` ka matlab package installed hona chahiye; yeh lazmi nahi ke newest version force kare.

Verification ka result is tarah ho sakta hai:

```text
tree-<version>.el9.x86_64
```

Exact version mukhtalif ho sakta hai.

---

## Solution 11 — Idempotency Demonstrate Karna

| Operation | Pehli run | Doosri run | Wajah |
|---|---|---|---|
| `tree` install | Aam tor par `changed=true` | `changed=false` | Package pehle hi present hai |
| `hello.txt` copy | Aam tor par `changed=true` | `changed=false` | Content aur mode pehle hi match karte hain |

`changed` ka matlab Ansible ne desired state hasil karne ke liye modification ki. `ok` ya `changed: false` ka matlab desired state pehle se mojood thi. Ansible ne task ko andha-dhund skip nahi kiya; us ne current state check karke decide kiya ke change zaroori nahi.

---

## Solution 12 — `command` aur `shell` ka Muqabla

| Feature | `command` | `shell` |
|---|---|---|
| Shell ke through chalta hai | Nahi | Haan |
| Pipe `|` support | Nahi | Haan |
| Redirection `>` support | Nahi | Haan |
| Ordinary commands ke liye safer default | Haan | Nahi |

Pipeline ko `shell` chahiye kyun ke pipe shell operator hai. Jab shell features ki zaroorat na ho to `command` prefer karein; yeh quoting issues aur command-injection risk kam karta hai. Untrusted input shell mein dene se unintended commands execute ho sakti hain.

---

## Solution 13 — Troubleshooting

| Masla | Investigation aur mumkin hal |
|---|---|
| `Permission denied (publickey)` | `ssh -v node1` run karein; `ansible_user`, private key, key permissions aur remote `authorized_keys` verify karein. |
| `Connection timed out` | IP/DNS, VM power, VPN/routing, port 22, firewall aur SSH service check karein. |
| Python interpreter nahi mila | SSH se `python3 --version` aur `ansible_python_interpreter` check karein; approved method se Python install ya path correct karein. |
| `Missing sudo password` | `ansibleadmin` ka NOPASSWD sudo verify karein; policy ke mutabiq zaroorat ho to `-K` use karein. |
| Pattern kisi host se match nahi karta | `ansible TARGET --list-hosts` aur `ansible-inventory --graph` se spelling, quoting, membership aur inventory path check karein. |
| VM rebuild ke baad host-key failure | Pehle new fingerprint independently verify karein; phir sirf old entry ko `ssh-keygen -R node1` aur/or `ssh-keygen -R 192.168.1.154` se remove karke reconnect karein. |

`ansible node1 -m ping -vvv` detailed diagnosis deta hai. Public sharing se pehle sensitive connection details hata dein.

---

## Solution 14 — Cleanup

Expected results:

- `tree` installed ho to removal aam tor par `changed=true` dikhayegi.
- `/tmp/ansible-homework` mojood ho to removal `changed=true` dikhayegi.
- `rpm -q tree` non-zero return code aur package not installed ka message dega.
- `stat` output mein:

```text
"exists": false
```

- Control node par local `hello.txt` bhi mojood nahi honi chahiye.

Removal tasks dobara run karne par `changed=false` aana chahiye. Yeh absent state ki idempotency demonstrate karta hai.

---

## Solution 15 — Final Reflection

Answers mukhtalif ho sakte hain. Strong sample answers:

1. Sab se important concept idempotency tha, kyun ke automation ko baar baar run karne par unnecessary changes nahi hotin.
2. `ansible three_tier_app -m ping` useful tha kyun ke is ne inventory selection, SSH authentication, remote Python aur module execution ko jaldi verify kiya.
3. Module operation ki type define karta hai; arguments us operation ki details dete hain.
4. Inventory hosts, groups aur host variables define karti hai. `ansible.cfg` Ansible ke defaults aur behavior define karti hai.
5. Jab kaam repeat, review, version-control ya multiple ordered tasks mein karna ho to ad-hoc command ke bajaye playbook use karein.
6. Verification confirm karti hai ke desired state hasil hui aur partial failure ya wrong target ka pata chalati hai.
7. Misaal: public-key error ko `ssh -v` se investigate kiya, inventory variables check ki aur correct private key select ki.

---

## Instructor Notes

- Correct concepts aur genuine machine output ko marks dein, chahe formatting ya versions sample se mukhtalif hon.
- Output ko sample se character-by-character match karna zaroori nahi.
- Confirm karein ke har student ne cleanup complete ki.
- Optional inventory challenge ko bonus practice samjhein jab tak woh formally assign na kiya gaya ho.
- Students kabhi password ya private SSH key ka content submit na karein.
