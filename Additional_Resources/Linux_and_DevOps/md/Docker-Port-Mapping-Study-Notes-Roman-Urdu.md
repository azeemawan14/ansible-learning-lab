# Docker Port Mapping — Roman Urdu Study Notes

## Index

1. [Lab output](#1-lab-output)
2. [`0.0.0.0:8080->80/tcp` ka matlab](#2-00008080-80tcp-ka-matlab)
3. [Har hissa alag se](#3-har-hissa-alag-se)
4. [Request ka complete flow](#4-request-ka-complete-flow)
5. [`-p` publish syntax](#5--p-publish-syntax)
6. [Host port aur container port mein farq](#6-host-port-aur-container-port-mein-farq)
7. [`0.0.0.0` aur `127.0.0.1` mein farq](#7-0000-aur-127001-mein-farq)
8. [IPv4 aur IPv6 port output](#8-ipv4-aur-ipv6-port-output)
9. [Container start karne ke examples](#9-container-start-karne-ke-examples)
10. [Port mapping verify karna](#10-port-mapping-verify-karna)
11. [Firewall aur remote access](#11-firewall-aur-remote-access)
12. [Common errors aur troubleshooting](#12-common-errors-aur-troubleshooting)
13. [`EXPOSE` aur `-p` mein farq](#13-expose-aur--p-mein-farq)
14. [Docker Compose example](#14-docker-compose-example)
15. [Security aur best practices](#15-security-aur-best-practices)
16. [Quick reference](#16-quick-reference)
17. [Interview-style answer](#17-interview-style-answer)

---

## 1. Lab output

```text
CONTAINER ID   IMAGE          STATUS         PORTS                  NAMES
a31bc92df521   nginx:latest   Up 10 minutes  0.0.0.0:8080->80/tcp   web
```

Is row ka matlab:

| Field | Value | Matlab |
|---|---|---|
| Container ID | `a31bc92df521` | Container ki short unique ID |
| Image | `nginx:latest` | Container Nginx ki latest image se bana hai |
| Status | `Up 10 minutes` | Container pichlay 10 minutes se running hai |
| Ports | `0.0.0.0:8080->80/tcp` | Host port `8080` container port `80` par forward ho raha hai |
| Name | `web` | Container ka naam `web` hai |

---

## 2. `0.0.0.0:8080->80/tcp` ka matlab

```text
0.0.0.0:8080 -> 80/tcp
```

Simple meaning:

> Docker host ke tamam IPv4 interfaces par port `8080` ke zariye aane wali TCP traffic ko container ke port `80` par forward kar raha hai.

Browser mein service access karne ke liye:

```text
http://HOST_IP:8080
```

Example:

```text
http://192.168.1.219:8080
```

---

## 3. Har hissa alag se

| Hissa | Matlab |
|---|---|
| `0.0.0.0` | Host ke tamam IPv4 network interfaces |
| `8080` | Docker host ka published port |
| `->` | Traffic container ki taraf forward ho rahi hai |
| `80` | Container ke andar application ka listening port |
| `/tcp` | TCP transport protocol use ho raha hai |

### `0.0.0.0`

Host ke paas multiple addresses ho sakte hain:

```text
127.0.0.1
192.168.1.219
10.0.0.20
```

`0.0.0.0:8080` ka matlab hai ke port `8080` in tamam IPv4 interfaces par bind hai. Network aur firewall allow karein to doosri machines bhi service access kar sakti hain.

### `8080`

Yeh host machine ka port hai. Browser ya client isi port par request bhejta hai.

### `80`

Yeh container ka internal port hai. Nginx normally container ke andar TCP port `80` par HTTP requests receive karta hai.

### `/tcp`

HTTP normally TCP use karta hai, is liye mapping `/tcp` show kar rahi hai.

---

## 4. Request ka complete flow

```text
Browser
   ↓
http://192.168.1.219:8080
   ↓
Docker host ka port 8080
   ↓
Docker port forwarding
   ↓
web container ka port 80
   ↓
Nginx HTTP response
```

Important point:

> Client host ka port `8080` use karta hai. Nginx container ke andar port `80` par request receive karta hai.

---

## 5. `-p` publish syntax

Container likely is command se start hua:

```bash
docker run -d --name web -p 8080:80 nginx:latest
```

General syntax:

```text
docker run -p HOST_PORT:CONTAINER_PORT IMAGE
```

Is example mein:

```text
-p 8080:80
   │    └── Container port
   └─────── Host port
```

Options:

| Option | Matlab |
|---|---|
| `docker run` | Naya container create aur start karta hai |
| `-d` | Container ko background mein chalata hai |
| `--name web` | Container ka naam `web` rakhta hai |
| `-p 8080:80` | Host `8080` ko container `80` ke saath map karta hai |
| `nginx:latest` | Use hone wali image aur tag |

---

## 6. Host port aur container port mein farq

| Host port | Container port |
|---|---|
| Host operating system par available hota hai | Container ke apne network namespace mein hota hai |
| Client is port ko access karta hai | Application is port par listen karti hai |
| Example: `8080` | Example: `80` |
| Ek host port ek waqt mein aam tor par ek hi listening service ko milta hai | Alag containers same internal port use kar sakte hain |

Example: do Nginx containers dono internal port `80` use kar sakte hain, lekin host ports different honge:

```bash
docker run -d --name web1 -p 8080:80 nginx
docker run -d --name web2 -p 8081:80 nginx
```

Access:

```text
http://HOST_IP:8080  → web1:80
http://HOST_IP:8081  → web2:80
```

---

## 7. `0.0.0.0` aur `127.0.0.1` mein farq

### Tamam IPv4 interfaces par publish karna

```bash
docker run -d --name web -p 8080:80 nginx
```

Output:

```text
0.0.0.0:8080->80/tcp
```

Network aur firewall allow karein to doosri machines access kar sakti hain.

### Sirf localhost par publish karna

```bash
docker run -d --name web-local -p 127.0.0.1:8081:80 nginx
```

Output:

```text
127.0.0.1:8081->80/tcp
```

Ab service sirf Docker host se accessible hogi:

```text
http://127.0.0.1:8081
```

Remote machines is port ko directly access nahi kar sakti.

---

## 8. IPv4 aur IPv6 port output

Kabhi `docker ps` output mein dono mappings nazar aati hain:

```text
0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```

| Output | Matlab |
|---|---|
| `0.0.0.0:8080` | Tamam IPv4 interfaces par port `8080` |
| `[::]:8080` | Tamam IPv6 interfaces par port `8080` |

Yeh host aur Docker networking configuration par depend karta hai.

---

## 9. Container start karne ke examples

### Normal mapping

```bash
docker run -d --name web -p 8080:80 nginx:latest
```

### Host aur container dono par port 80

```bash
docker run -d --name web -p 80:80 nginx:latest
```

Access:

```text
http://HOST_IP
```

### Host port automatically select karwana

```bash
docker run -d --name web -p 80 nginx:latest
```

Docker random available host port ko container port `80` ke saath map karega. Assigned port dekhein:

```bash
docker port web
```

### UDP mapping

```bash
docker run -d --name app -p 5353:5353/udp IMAGE_NAME
```

Nginx HTTP ke liye TCP example hi relevant hai.

---

## 10. Port mapping verify karna

### Running containers

```bash
docker ps
```

### Specific container ki mapping

```bash
docker port web
```

Expected:

```text
80/tcp -> 0.0.0.0:8080
```

### Container inspection

```bash
docker inspect web
```

Sirf port bindings:

```bash
docker inspect web --format '{{json .HostConfig.PortBindings}}'
```

### Host se HTTP test

```bash
curl -I http://127.0.0.1:8080
```

Expected status:

```text
HTTP/1.1 200 OK
```

### Remote machine se test

```bash
curl -I http://HOST_IP:8080
```

### Host listening socket check

```bash
sudo ss -tlnp | grep ':8080'
```

---

## 11. Firewall aur remote access

`0.0.0.0:8080` dikhne ka matlab yeh nahi ke remote access lazmi kaam karega. Host firewall ya upstream network traffic block kar sakta hai.

Rocky Linux/firewalld par current rules check karein:

```bash
sudo firewall-cmd --list-all
```

Lab mein TCP port `8080` permanently allow karna ho:

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

Verify:

```bash
sudo firewall-cmd --query-port=8080/tcp
```

Expected:

```text
yes
```

Production mein port sirf required sources ke liye allow karna zyada secure hota hai.

---

## 12. Common errors aur troubleshooting

### Error: port already allocated

```text
Bind for 0.0.0.0:8080 failed: port is already allocated
```

Matlab host port `8080` pehle se use ho raha hai.

Check:

```bash
sudo ss -tlnp | grep ':8080'
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Solution: existing service ko investigate karein ya different host port use karein:

```bash
docker run -d --name web2 -p 8081:80 nginx
```

### Container running hai lekin page open nahi hota

Step-by-step checks:

```bash
docker ps
docker logs web
docker port web
curl -I http://127.0.0.1:8080
sudo ss -tlnp | grep ':8080'
sudo firewall-cmd --list-all
```

### Connection refused

Possible reasons:

- Container stopped hai.
- Port publish nahi hua.
- Application container ke expected port par listen nahi kar rahi.
- Ghalat host port use ho raha hai.

### Connection timed out

Possible reasons:

- Firewall traffic drop kar raha hai.
- Host unreachable hai.
- VPN ya network route missing hai.
- Cloud security group ya upstream firewall port block kar raha hai.

---

## 13. `EXPOSE` aur `-p` mein farq

Dockerfile example:

```dockerfile
EXPOSE 80
```

`EXPOSE 80` documentation/metadata ki tarah batata hai ke application port `80` use karti hai. Yeh apne aap host port publish nahi karta.

Actual host mapping ke liye:

```bash
docker run -p 8080:80 nginx
```

| `EXPOSE 80` | `-p 8080:80` |
|---|---|
| Image metadata/documentation | Runtime port publishing |
| Host port create nahi karta | Host port `8080` publish karta hai |
| Dockerfile mein hota hai | `docker run` ya Compose mein hota hai |

---

## 14. Docker Compose example

```yaml
services:
  web:
    image: nginx:latest
    container_name: web
    ports:
      - "8080:80"
```

Start:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

Compose mein bhi format wahi hai:

```text
HOST_PORT:CONTAINER_PORT
```

Sirf localhost binding:

```yaml
ports:
  - "127.0.0.1:8080:80"
```

---

## 15. Security aur best practices

- Public access required na ho to `127.0.0.1` par bind karein.
- Sirf required ports publish karein.
- Host firewall rules verify karein.
- Database ports ko bila-zarurat public interfaces par publish na karein.
- Production mein `latest` ke bajaye specific image version/tag use karna reproducibility ke liye behtar hai.
- Port conflict se bachne ke liye host ports plan karein.
- Container logs aur application health verify karein.

Example specific tag:

```bash
docker run -d --name web -p 8080:80 nginx:1.28
```

---

## 16. Quick reference

```bash
# Nginx ko host port 8080 par publish karein
docker run -d --name web -p 8080:80 nginx:latest

# Running containers aur ports dekhein
docker ps

# Specific container ki published ports dekhein
docker port web

# HTTP response test karein
curl -I http://127.0.0.1:8080

# Host listening port dekhein
sudo ss -tlnp | grep ':8080'

# Container logs dekhein
docker logs web

# Sirf localhost par publish karein
docker run -d --name web-local -p 127.0.0.1:8081:80 nginx
```

Easy formula:

```text
0.0.0.0:8080 -> 80/tcp
│       │       │  └── Protocol
│       │       └───── Container port
│       └───────────── Host port
└───────────────────── Tamam IPv4 interfaces
```

---

## 17. Interview-style answer

> `0.0.0.0:8080->80/tcp` ka matlab hai ke Docker host ke tamam IPv4 interfaces par TCP port `8080` publish hua hai aur us port par aane wali traffic container ke port `80` par forward hoti hai. Client `HOST_IP:8080` access karta hai, jabke Nginx container ke andar port `80` par listen karta hai. Agar service ko sirf local host tak restrict karna ho to main mapping ko `127.0.0.1:8080:80` ke saath bind karunga. Remote access ke liye main Docker mapping ke saath host firewall aur network rules bhi verify karunga.

