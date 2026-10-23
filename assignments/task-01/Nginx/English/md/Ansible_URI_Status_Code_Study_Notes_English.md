# Ansible `uri` Module and `status_code` — Study Notes

## Table of Contents

1. [What is the `uri` module?](#1-what-is-the-uri-module)
2. [Basic command](#2-basic-command)
3. [Meaning of `status_code=200`](#3-meaning-of-status_code200)
4. [Command breakdown](#4-command-breakdown)
5. [The important meaning of `localhost`](#5-the-important-meaning-of-localhost)
6. [How Ansible decides success or failure](#6-how-ansible-decides-success-or-failure)
7. [Common HTTP status codes](#7-common-http-status-codes)
8. [Accepting multiple status codes](#8-accepting-multiple-status-codes)
9. [Returning website content](#9-returning-website-content)
10. [Testing from the control node](#10-testing-from-the-control-node)
11. [`uri` versus `curl`](#11-uri-versus-curl)
12. [Practice commands](#12-practice-commands)
13. [Quick revision](#13-quick-revision)

---

## 1. What is the `uri` module?

The Ansible **`uri` module** sends HTTP or HTTPS requests. It can be used to:

- Test a website
- Verify an HTTP status code
- Call a REST API
- Return response content
- Submit data to a login page or API

**One-line definition:**

> The `uri` module sends an HTTP/HTTPS request to a website or web API and checks its response.

---

## 2. Basic command

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

This command tests the local web server from every managed node in the `three_tier_app` inventory group.

---

## 3. Meaning of `status_code=200`

`status_code=200` means:

> Ansible expects the website to return HTTP status code **`200 OK`**.

HTTP code `200` indicates that:

- The server received the request.
- The server processed it successfully.
- The requested page or content is available.

```text
Expected response: 200 OK
Actual response:   200 OK
Ansible result:    SUCCESS
```

`status_code=200` does **not** set or change the website's response code. It only tells Ansible which returned response should be considered successful.

---

## 4. Command breakdown

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

| Part | Explanation |
|---|---|
| `ansible` | Runs an Ansible ad-hoc command |
| `three_tier_app` | Selects the target inventory group |
| `-m uri` | Selects the `uri` module for an HTTP/HTTPS request |
| `-a` | Supplies arguments to the module |
| `url=http://localhost` | Makes each node request its local web server |
| `status_code=200` | Defines `200` as the expected response |

---

## 5. The important meaning of `localhost`

In this command, `localhost` does not refer to the Ansible control node:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

The module runs on every managed node. Therefore, each node tests itself:

```text
node1 → http://localhost on node1
node2 → http://localhost on node2
node3 → http://localhost on node3
```

If Nginx is installed and running on all three nodes, all three should return `SUCCESS`.

---

## 6. How Ansible decides success or failure

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

If the requested page does not exist, the server may return `404`:

```text
Expected: 200
Received: 404
Result:   FAILED
```

The website responded, but its response did not match the expected code.

### Connection failure

If Nginx is stopped or port `80` is not listening, you may receive a connection error instead of an HTTP status code:

```text
Connection refused
```

This is not a `404`. It means that Ansible could not establish a connection to a web service on the requested port.

---

## 7. Common HTTP status codes

| Code | Name | Meaning |
|---:|---|---|
| `200` | OK | The request completed successfully |
| `201` | Created | A new resource was created successfully |
| `204` | No Content | Successful request with no response body |
| `301` | Moved Permanently | Resource permanently moved to another URL |
| `302` | Found | Temporary redirection |
| `400` | Bad Request | The client sent an invalid request |
| `401` | Unauthorized | Authentication is required or invalid |
| `403` | Forbidden | The server denied access |
| `404` | Not Found | The requested page or resource was not found |
| `500` | Internal Server Error | A server or application error occurred |
| `502` | Bad Gateway | Nginx did not receive a valid response from the backend |
| `503` | Service Unavailable | The service is temporarily unavailable |

HTTP status-code categories:

| Range | Category |
|---:|---|
| `1xx` | Informational |
| `2xx` | Success |
| `3xx` | Redirection |
| `4xx` | Client-side request problem |
| `5xx` | Server-side problem |

---

## 8. Accepting multiple status codes

An application may have more than one valid response. For example, a page may return `200` or redirect to a login page with `302`.

For an ad-hoc command, JSON argument syntax is a reliable way to pass a list:

```bash
ansible three_tier_app -m uri \
  -a '{"url":"http://localhost","status_code":[200,302]}'
```

Ansible will now consider either `200` or `302` successful.

---

## 9. Returning website content

The `uri` module does not always display the complete response body by default. To return the HTML content, use:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200 return_content=yes"
```

Important arguments:

| Argument | Purpose |
|---|---|
| `url` | Specifies the website or API address |
| `status_code` | Defines the expected HTTP response code |
| `return_content=yes` | Includes the response body in the output |
| `method=GET` | Specifies the HTTP request method |
| `timeout=10` | Sets the request timeout in seconds |
| `validate_certs=yes` | Verifies the HTTPS certificate |

---

## 10. Testing from the control node

The following command runs on the control node and tests the IP address of `node1`:

```bash
ansible localhost -m uri \
  -a "url=http://192.168.1.154 status_code=200"
```

You can also use Linux `curl`:

```bash
curl -I http://192.168.1.154
curl -I http://192.168.1.185
curl -I http://192.168.1.190
```

Remember the difference:

```text
ansible three_tier_app -m uri -a "url=http://localhost status_code=200"
→ Each managed node sends a request to its own localhost.

ansible localhost -m uri -a "url=http://192.168.1.154 status_code=200"
→ The control node sends a request to node1's IP address.
```

---

## 11. `uri` versus `curl`

| `uri` module | `curl` command |
|---|---|
| An Ansible module | A Linux command-line tool |
| Can run across multiple inventory hosts | Normally runs from the local machine |
| Returns structured Ansible results | Prints HTTP results in the terminal |
| Useful in playbooks and automated checks | Very useful for manual troubleshooting |
| Automatically validates expected status codes | Requires options or scripting to evaluate the status |

---

## 12. Practice commands

### Practice 1: Test Nginx locally

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200"
```

### Practice 2: Return the HTML content

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost status_code=200 return_content=yes"
```

### Practice 3: Test a missing page

This example intentionally expects `404`:

```bash
ansible three_tier_app -m uri \
  -a "url=http://localhost/missing-page status_code=404"
```

If the page is missing and the server returns `404`, Ansible reports `SUCCESS` because the expected and received codes match.

### Practice 4: Stop Nginx and observe a connection failure

Use only in your lab environment:

```bash
ansible node1 -b -m service -a "name=nginx state=stopped"
ansible node1 -m uri -a "url=http://localhost status_code=200"
ansible node1 -b -m service -a "name=nginx state=started"
```

---

## 13. Quick revision

| Question | Short answer |
|---|---|
| What does the `uri` module do? | Sends HTTP/HTTPS requests |
| What does `status_code=200` do? | Treats `200` as the expected response |
| Does it set the website's status code? | No, it only validates the returned code |
| What does `200` mean? | The request was successful |
| What does `404` mean? | The requested resource was not found |
| What does `500` mean? | The server encountered an internal error |
| What does `localhost` mean on a managed node? | That managed node itself |
| How do you display the response body? | Use `return_content=yes` |
| How can the control node test node1? | `ansible localhost -m uri -a "url=http://192.168.1.154 status_code=200"` |

## Simple analogy

Think of a restaurant:

- `url=http://localhost` = your order
- Nginx = the restaurant
- `200` = the order was successfully delivered
- `404` = the requested item was not found
- `500` = the restaurant's internal system encountered a problem

Therefore, `status_code=200` simply means:

> **Ansible, consider the command successful when the website returns `200 OK`.**
