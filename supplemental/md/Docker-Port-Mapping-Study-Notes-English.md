# Docker Port Mapping — English Study Notes

## Index

1. [Lab output](#1-lab-output)
2. [Meaning of `0.0.0.0:8080->80/tcp`](#2-meaning-of-00008080-80tcp)
3. [Explanation of each part](#3-explanation-of-each-part)
4. [Complete request flow](#4-complete-request-flow)
5. [`-p` publish syntax](#5--p-publish-syntax)
6. [Host port versus container port](#6-host-port-versus-container-port)
7. [`0.0.0.0` versus `127.0.0.1`](#7-0000-versus-127001)
8. [IPv4 and IPv6 output](#8-ipv4-and-ipv6-output)
9. [Container startup examples](#9-container-startup-examples)
10. [Verifying the port mapping](#10-verifying-the-port-mapping)
11. [Firewall and remote access](#11-firewall-and-remote-access)
12. [Common errors and troubleshooting](#12-common-errors-and-troubleshooting)
13. [`EXPOSE` versus `-p`](#13-expose-versus--p)
14. [Docker Compose example](#14-docker-compose-example)
15. [Security and best practices](#15-security-and-best-practices)
16. [Quick reference](#16-quick-reference)
17. [Interview-style answer](#17-interview-style-answer)

---

## 1. Lab output

```text
CONTAINER ID   IMAGE          STATUS         PORTS                  NAMES
a31bc92df521   nginx:latest   Up 10 minutes  0.0.0.0:8080->80/tcp   web
```

The row provides the following information:

| Field | Value | Meaning |
|---|---|---|
| Container ID | `a31bc92df521` | Short unique identifier of the container |
| Image | `nginx:latest` | The container was created from the latest Nginx image |
| Status | `Up 10 minutes` | The container has been running for 10 minutes |
| Ports | `0.0.0.0:8080->80/tcp` | Host port `8080` forwards TCP traffic to container port `80` |
| Name | `web` | The container is named `web` |

---

## 2. Meaning of `0.0.0.0:8080->80/tcp`

```text
0.0.0.0:8080 -> 80/tcp
```

Simple meaning:

> Docker accepts TCP traffic on port `8080` of every IPv4 interface on the host and forwards it to port `80` inside the container.

The service can be accessed with:

```text
http://HOST_IP:8080
```

Example:

```text
http://192.168.1.219:8080
```

---

## 3. Explanation of each part

| Part | Meaning |
|---|---|
| `0.0.0.0` | All IPv4 network interfaces on the Docker host |
| `8080` | Published port on the host |
| `->` | Traffic is forwarded toward the container |
| `80` | Port used by the application inside the container |
| `/tcp` | The mapping uses the TCP transport protocol |

### `0.0.0.0`

A host can have several IPv4 addresses, for example:

```text
127.0.0.1
192.168.1.219
10.0.0.20
```

Binding to `0.0.0.0:8080` means that Docker listens on port `8080` across all IPv4 interfaces. Other systems may reach it if routing and firewall rules permit access.

### `8080`

This is the host port. A browser or another client sends its request to this port.

### `80`

This is the internal container port. Nginx normally listens for HTTP requests on TCP port `80` inside the container.

### `/tcp`

HTTP normally uses TCP, so the mapping is marked as `/tcp`.

---

## 4. Complete request flow

```text
Browser
   ↓
http://192.168.1.219:8080
   ↓
Docker host port 8080
   ↓
Docker port forwarding
   ↓
Port 80 of the web container
   ↓
Nginx HTTP response
```

The important distinction is:

> The client connects to host port `8080`, while Nginx receives the request on port `80` inside the container.

---

## 5. `-p` publish syntax

The container was likely started with:

```bash
docker run -d --name web -p 8080:80 nginx:latest
```

General syntax:

```text
docker run -p HOST_PORT:CONTAINER_PORT IMAGE
```

For this example:

```text
-p 8080:80
   │    └── Container port
   └─────── Host port
```

| Option | Meaning |
|---|---|
| `docker run` | Creates and starts a new container |
| `-d` | Runs the container in the background |
| `--name web` | Assigns the container name `web` |
| `-p 8080:80` | Maps host port `8080` to container port `80` |
| `nginx:latest` | Specifies the image and tag |

---

## 6. Host port versus container port

| Host port | Container port |
|---|---|
| Exists on the Docker host | Exists within the container's network namespace |
| Used by external clients | Used by the application inside the container |
| Example: `8080` | Example: `80` |
| One host port can normally belong to only one listening service at a time | Different containers can use the same internal port |

Two Nginx containers can both use internal port `80`, provided they use different host ports:

```bash
docker run -d --name web1 -p 8080:80 nginx
docker run -d --name web2 -p 8081:80 nginx
```

Access paths:

```text
http://HOST_IP:8080  → web1:80
http://HOST_IP:8081  → web2:80
```

---

## 7. `0.0.0.0` versus `127.0.0.1`

### Publish on every IPv4 interface

```bash
docker run -d --name web -p 8080:80 nginx
```

Output:

```text
0.0.0.0:8080->80/tcp
```

Other systems can potentially connect if the network and firewall permit it.

### Publish only on localhost

```bash
docker run -d --name web-local -p 127.0.0.1:8081:80 nginx
```

Output:

```text
127.0.0.1:8081->80/tcp
```

The service is then directly accessible only from the Docker host:

```text
http://127.0.0.1:8081
```

Remote machines cannot directly connect to this binding.

---

## 8. IPv4 and IPv6 output

`docker ps` may show both mappings:

```text
0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
```

| Output | Meaning |
|---|---|
| `0.0.0.0:8080` | Port `8080` on all IPv4 interfaces |
| `[::]:8080` | Port `8080` on all IPv6 interfaces |

The exact display depends on the host and Docker networking configuration.

---

## 9. Container startup examples

### Standard mapping

```bash
docker run -d --name web -p 8080:80 nginx:latest
```

### Port 80 on both host and container

```bash
docker run -d --name web -p 80:80 nginx:latest
```

The browser can use:

```text
http://HOST_IP
```

### Let Docker select an available host port

```bash
docker run -d --name web -p 80 nginx:latest
```

Docker selects an available host port and maps it to container port `80`. Display the selected port with:

```bash
docker port web
```

### UDP mapping

```bash
docker run -d --name app -p 5353:5353/udp IMAGE_NAME
```

The Nginx HTTP example uses TCP rather than UDP.

---

## 10. Verifying the port mapping

### Display running containers

```bash
docker ps
```

### Display the mapping for one container

```bash
docker port web
```

Expected output:

```text
80/tcp -> 0.0.0.0:8080
```

### Inspect the container

```bash
docker inspect web
```

Display only the port bindings:

```bash
docker inspect web --format '{{json .HostConfig.PortBindings}}'
```

### Test HTTP from the Docker host

```bash
curl -I http://127.0.0.1:8080
```

Expected status:

```text
HTTP/1.1 200 OK
```

### Test from another machine

```bash
curl -I http://HOST_IP:8080
```

### Check the host listening socket

```bash
sudo ss -tlnp | grep ':8080'
```

---

## 11. Firewall and remote access

Seeing `0.0.0.0:8080` does not guarantee that remote access will succeed. The host firewall or an upstream network device can still block the traffic.

On Rocky Linux with firewalld, inspect the active rules:

```bash
sudo firewall-cmd --list-all
```

To permit TCP port `8080` permanently in a lab:

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

Verify the rule:

```bash
sudo firewall-cmd --query-port=8080/tcp
```

Expected output:

```text
yes
```

In production, restrict access to only the sources that actually require it.

---

## 12. Common errors and troubleshooting

### Port is already allocated

```text
Bind for 0.0.0.0:8080 failed: port is already allocated
```

This means another service or container is already using host port `8080`.

Investigate:

```bash
sudo ss -tlnp | grep ':8080'
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

After understanding the existing listener, use a different host port if appropriate:

```bash
docker run -d --name web2 -p 8081:80 nginx
```

### Container is running but the page does not open

Check each layer:

```bash
docker ps
docker logs web
docker port web
curl -I http://127.0.0.1:8080
sudo ss -tlnp | grep ':8080'
sudo firewall-cmd --list-all
```

### Connection refused

Possible causes:

- The container has stopped.
- The port was not published.
- The application is not listening on the expected container port.
- The client is using the wrong host port.

### Connection timed out

Possible causes:

- A firewall is dropping the traffic.
- The host is unreachable.
- A VPN or network route is missing.
- A cloud security group or upstream firewall blocks the port.

---

## 13. `EXPOSE` versus `-p`

Dockerfile example:

```dockerfile
EXPOSE 80
```

`EXPOSE 80` provides image metadata documenting that the application uses port `80`. It does not publish a host port by itself.

Runtime publishing requires:

```bash
docker run -p 8080:80 nginx
```

| `EXPOSE 80` | `-p 8080:80` |
|---|---|
| Image metadata and documentation | Runtime port publishing |
| Does not create a host port | Publishes host port `8080` |
| Usually appears in a Dockerfile | Used with `docker run` or Compose |

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

Start the service:

```bash
docker compose up -d
```

Check it:

```bash
docker compose ps
```

Compose uses the same mapping format:

```text
HOST_PORT:CONTAINER_PORT
```

Bind only to localhost:

```yaml
ports:
  - "127.0.0.1:8080:80"
```

---

## 15. Security and best practices

- Bind to `127.0.0.1` when external access is unnecessary.
- Publish only the ports that are required.
- Verify host firewall and upstream network rules.
- Do not publish database ports on public interfaces unless there is a clear requirement and proper protection.
- Prefer a specific image version over `latest` in production for reproducibility.
- Plan host ports to prevent conflicts.
- Review container logs and application health.

Example using a specific tag:

```bash
docker run -d --name web -p 8080:80 nginx:1.28
```

---

## 16. Quick reference

```bash
# Publish Nginx on host port 8080
docker run -d --name web -p 8080:80 nginx:latest

# Display running containers and mappings
docker ps

# Display one container's published ports
docker port web

# Test the HTTP response
curl -I http://127.0.0.1:8080

# Check the host listening port
sudo ss -tlnp | grep ':8080'

# Display container logs
docker logs web

# Publish only on localhost
docker run -d --name web-local -p 127.0.0.1:8081:80 nginx
```

Easy formula:

```text
0.0.0.0:8080 -> 80/tcp
│       │       │  └── Protocol
│       │       └───── Container port
│       └───────────── Host port
└───────────────────── All IPv4 interfaces
```

---

## 17. Interview-style answer

> `0.0.0.0:8080->80/tcp` means Docker has published TCP port `8080` on every IPv4 interface of the host and forwards traffic received there to port `80` inside the container. A client connects to `HOST_IP:8080`, while Nginx listens on port `80` inside the container. If the service should be restricted to the local host, I would bind it as `127.0.0.1:8080:80`. For remote access, I would verify the Docker mapping, host firewall and upstream network rules.

