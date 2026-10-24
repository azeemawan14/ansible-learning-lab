# Ansible `uri` Module aur `status_code` — Roman Urdu Study Notes

## Fehrist

1. [`uri` module kya hai?](#1-uri-module-kya-hai)
2. [Basic command](#2-basic-command)
3. [`status_code=200` ka matlab](#3-status_code200-ka-matlab)
4. [Command ki line-by-line wazahat](#4-command-ki-line-by-line-wazahat)
5. [`localhost` ka aham matlab](#5-localhost-ka-aham-matlab)
6. [Success aur failure kaise decide hote hain?](#6-success-aur-failure-kaise-decide-hote-hain)
7. [Common HTTP status codes](#7-common-http-status-codes)
8. [Multiple accepted status codes](#8-multiple-accepted-status-codes)
9. [Website ka content dekhna](#9-website-ka-content-dekhna)
10. [Control node se test karna](#10-control-node-se-test-karna)
11. [`uri` aur `curl` ka farq](#11-uri-aur-curl-ka-farq)
12. [Practice commands](#12-practice-commands)
13. [Quick revision](#13-quick-revision)

---

## 1. `uri` module kya hai?

Ansible ka **`uri` module** HTTP ya HTTPS request bhejne ke liye use hota hai. Is se hum:

- Website check kar sakte hain
- HTTP status code verify kar sakte hain
- REST API call kar sakte hain
- Response ka content dekh sakte hain
- Login ya API ke liye data bhej sakte hain

**Ek line ki definition:**

> `uri` module website ya web API ko HTTP/HTTPS request bhejta hai aur uska response check karta hai.

---

## 2. Basic command

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

Is command ka maqsad `three_tier_app` group ke har managed node par local web server ko test karna hai.

---

## 3. `status_code=200` ka matlab

`status_code=200` ka matlab hai:

> Ansible ko umeed hai ke website HTTP status code **`200 OK`** return karegi.

HTTP code `200` batata hai ke:

- Server ne request receive kar li
- Request ko successfully process kiya
- Requested page ya content available hai

```text
Expected response: 200 OK
Actual response:   200 OK
Ansible result:    SUCCESS
```

Yahan `status_code=200` website ka status code **set** nahi karta. Yeh sirf Ansible ko batata hai ke successful test ke liye kaunsa response **expected** hai.

---

## 4. Command ki line-by-line wazahat

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

| Hissa | Wazahat |
|---|---|
| `ansible` | Ansible ad-hoc command chalata hai |
| `three_tier_app` | Inventory ka target host group hai |
| `-m uri` | HTTP/HTTPS request ke liye `uri` module select karta hai |
| `-a` | Module arguments provide karta hai |
| `url=http://localhost` | Har node apne local web server ko request bhejta hai |
| `status_code=200` | Expected successful HTTP response `200` hai |

---

## 5. `localhost` ka aham matlab

Is command mein `localhost` se murad Ansible control node nahi hai:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

Module har managed node par execute hota hai. Is liye har node apne aap ko test karega:

```text
node1 → http://localhost on node1
node2 → http://localhost on node2
node3 → http://localhost on node3
```

Agar Nginx teeno nodes par installed aur running hai, teeno ka expected result `SUCCESS` hoga.

---

## 6. Success aur failure kaise decide hote hain?

### Successful example

```text
Expected: 200
Received: 200
Result:   SUCCESS
```

Example output:

```text
node1 | SUCCESS => {
    "status": 200
}
```

### Failed example

Agar requested page maujood na ho to server `404` de sakta hai:

```text
Expected: 200
Received: 404
Result:   FAILED
```

Is situation mein website ne response diya, lekin woh expected `200` response nahi tha.

### Connection failure

Agar Nginx band ho ya port `80` listen na kar raha ho, to HTTP status code ke bajaye connection error aa sakta hai:

```text
Connection refused
```

Is ka matlab `404` nahi hai. Is ka matlab hai ke requested port par web service se connection hi establish nahi hua.

---

## 7. Common HTTP status codes

| Code | Naam | Roman Urdu mein matlab |
|---:|---|---|
| `200` | OK | Request successfully complete hui |
| `201` | Created | Naya resource successfully create hua |
| `204` | No Content | Request successful, lekin response body nahi hai |
| `301` | Moved Permanently | Resource permanently doosre URL par move hua |
| `302` | Found | Temporary redirect hua |
| `400` | Bad Request | Client ki request ghalat thi |
| `401` | Unauthorized | Authentication required ya invalid hai |
| `403` | Forbidden | Server ne access deny kar diya |
| `404` | Not Found | Requested page ya resource nahi mila |
| `500` | Internal Server Error | Server ya application ke andar error hai |
| `502` | Bad Gateway | Nginx backend application se valid response nahi le saka |
| `503` | Service Unavailable | Service filhal available nahi hai |

HTTP status code categories:

| Range | Category |
|---:|---|
| `1xx` | Information |
| `2xx` | Success |
| `3xx` | Redirection |
| `4xx` | Client-side request problem |
| `5xx` | Server-side problem |

---

## 8. Multiple accepted status codes

Kabhi application ek se zyada valid codes return kar sakti hai. Misal ke tor par page `200` de sakta hai ya login page par `302` redirect kar sakta hai.

Ad-hoc command mein list ko JSON syntax ke sath dena zyada reliable hai:

```bash
ansible three_tier_app -m uri \
  -a '{"url":"http://localhost","status_code":[200,302]}'
```

Ab `200` ya `302`, dono mein command successful samjhi jayegi.

---

## 9. Website ka content dekhna

By default, `uri` module zaroori nahi ke poora HTML content output mein dikhaye. Response body dekhne ke liye:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200 return_content=yes"
```

Important arguments:

| Argument | Maqsad |
|---|---|
| `url` | Website ya API address |
| `status_code` | Expected HTTP response code |
| `return_content=yes` | Response body output mein dikhata hai |
| `method=GET` | HTTP method specify karta hai |
| `timeout=10` | Request ka timeout seconds mein set karta hai |
| `validate_certs=yes` | HTTPS certificate verify karta hai |

---

## 10. Control node se test karna

Yeh command control node par execute hoti hai aur managed node ka IP test karti hai:

```bash
ansible localhost -m uri \
  -a "url=http://192.168.1.154 status_code=200"
```

Ya Linux ka `curl` command use karein:

```bash
curl -I http://192.168.1.154
curl -I http://192.168.1.185
curl -I http://192.168.1.190
```

Farq yaad rakhein:

```text
ansible three_tier_app -m uri -a "url=http://localhost status_code=200"
→ Request har managed node se usi node ke localhost ko jati hai.

ansible localhost -m uri -a "url=http://192.168.1.154 status_code=200"
→ Request control node se node1 ke IP ko jati hai.
```

---

## 11. `uri` aur `curl` ka farq

| `uri` module | `curl` command |
|---|---|
| Ansible module hai | Linux command-line tool hai |
| Multiple inventory hosts par chal sakta hai | Aam tor par local machine se chalta hai |
| Structured Ansible result deta hai | Terminal mein HTTP output deta hai |
| Playbooks mein idempotent checks ke liye useful hai | Manual troubleshooting ke liye bohat useful hai |
| Expected status code automatically verify kar sakta hai | Status ko command options ya script se check karna hota hai |

---

## 12. Practice commands

### Practice 1: Nginx ko locally test karein

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

### Practice 2: HTML content return karein

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200 return_content=yes"
```

### Practice 3: Missing page test karein

Yahan hum jaan-boojh kar `404` expect kar rahe hain:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost/missing-page status_code=404"
```

Agar page waqai missing hai aur server `404` deta hai, Ansible result `SUCCESS` hoga, kyun ke expected aur received codes match karte hain.

### Practice 4: Nginx stop karke connection failure dekhein

Sirf lab environment mein:

```bash
ansible node1 -b -m service -a "name=nginx state=stopped"
ansible node1 -m uri -a "url=http://localhost status_code=200"
ansible node1 -b -m service -a "name=nginx state=started"
```

---

## 13. Quick revision

| Sawal | Mukhtasar jawab |
|---|---|
| `uri` module kya karta hai? | HTTP/HTTPS request bhejta hai |
| `status_code=200` kya karta hai? | `200` ko expected successful response maanta hai |
| Kya yeh website ka status code set karta hai? | Nahi, sirf returned code verify karta hai |
| `200` ka matlab? | Request successful |
| `404` ka matlab? | Resource nahi mila |
| `500` ka matlab? | Server ke andar error |
| Managed node par `localhost` kis ko kehta hai? | Usi managed node ko |
| Response body kaise dikhayenge? | `return_content=yes` |
| Control node se node1 kaise test hoga? | `ansible localhost -m uri -a "url=http://192.168.1.154 status_code=200"` |

## Asaan misaal

Restaurant ki misaal:

- `url=http://localhost` = aapka order
- Nginx = restaurant
- `200` = order successfully mil gaya
- `404` = mangi hui cheez menu ya counter par nahi mili
- `500` = restaurant ke internal system mein problem hai

Is liye `status_code=200` ka seedha matlab hai:

> **Ansible, command ko tab successful samjho jab website `200 OK` response de.**
