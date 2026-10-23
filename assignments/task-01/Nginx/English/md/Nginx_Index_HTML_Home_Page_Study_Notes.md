# Nginx `index.html` Home Page — Study Notes

## Table of Contents

1. [What Is index.html?](#1-what-is-indexhtml)
2. [How Nginx Finds the Home Page](#2-how-nginx-finds-the-home-page)
3. [Root URL Mapping](#3-root-url-mapping)
4. [Subdirectory URL Mapping](#4-subdirectory-url-mapping)
5. [403 vs 404](#5-403-vs-404)
6. [The Nginx index Directive](#6-the-nginx-index-directive)
7. [Useful Verification Commands](#7-useful-verification-commands)
8. [Quick Summary](#8-quick-summary)

---

## 1. What Is `index.html`?

Yes, `index.html` is usually the default home page of a static website.

When a user opens a website without entering a filename, the web server searches for a default index file inside the matching document directory.

For example:

```text
http://192.168.1.154/
```

Nginx may automatically serve:

```text
/var/www/lawfirm.com/html/index.html
```

The user does not need to type `index.html` in the browser.

These URLs usually display the same page:

```text
http://192.168.1.154/
http://192.168.1.154/index.html
```

---

## 2. How Nginx Finds the Home Page

Nginx uses two important configuration directives:

```nginx
root /var/www/lawfirm.com/html;
index index.html index.htm;
```

The `root` directive tells Nginx where the website files are stored.

The `index` directive tells Nginx which default filenames to search for when the URL points to a directory.

For this configuration, Nginx searches in this order:

1. `index.html`
2. `index.htm`

---

## 3. Root URL Mapping

If the browser requests:

```text
http://192.168.1.154/
```

Nginx combines the document root with the default index filename:

```text
Browser URL
http://192.168.1.154/
        ↓
Nginx document root
/var/www/lawfirm.com/html/
        ↓
Default home page
/var/www/lawfirm.com/html/index.html
```

Therefore, the website file must exist at:

```text
/var/www/lawfirm.com/html/index.html
```

---

## 4. Subdirectory URL Mapping

If the browser requests:

```text
http://192.168.1.154/space-science/
```

Nginx searches for:

```text
/var/www/lawfirm.com/html/space-science/index.html
```

The complete mapping is:

```text
http://192.168.1.154/space-science/
                      ↓
/var/www/lawfirm.com/html/space-science/index.html
```

If the files were copied directly into:

```text
/var/www/lawfirm.com/html/
```

then use the root URL:

```text
http://192.168.1.154/
```

If the files were copied into:

```text
/var/www/lawfirm.com/html/space-science/
```

then use:

```text
http://192.168.1.154/space-science/
```

The browser URL and filesystem deployment path must match.

---

## 5. `403` vs `404`

### `403 Forbidden`

Nginx may return `403 Forbidden` when:

- the requested directory exists;
- no configured index file exists inside it;
- directory listing is disabled; or
- permissions or SELinux prevent access.

Example:

```text
/var/www/lawfirm.com/html/       ← directory exists
/var/www/lawfirm.com/html/index.html  ← missing
```

### `404 Not Found`

Nginx normally returns `404 Not Found` when the requested path does not exist.

Example request:

```text
http://192.168.1.154/space-science/
```

Missing path:

```text
/var/www/lawfirm.com/html/space-science/
```

### Quick comparison

| Status | Basic meaning | Common lab cause |
|---|---|---|
| `403 Forbidden` | Nginx found the location but cannot serve it | Missing index, permissions, or SELinux |
| `404 Not Found` | Requested location does not exist | URL does not match the deployed directory |

---

## 6. The Nginx `index` Directive

Example:

```nginx
index index.html index.htm;
```

This tells Nginx:

1. Search for `index.html` first.
2. If it is missing, search for `index.htm`.

The directive can use other filenames:

```nginx
index home.html index.html;
```

Now Nginx checks `home.html` before `index.html`.

After changing Nginx configuration, validate and reload it:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Static website file changes alone normally do not require an Nginx reload.

---

## 7. Useful Verification Commands

### Confirm the index file exists

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/index.html"
```

### List the website directory

```bash
ansible node1 -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

### Check configured document roots and index directives

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*(root|index)[[:space:]]'"
```

### Test the root URL

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200"
```

### Test the subdirectory URL

```bash
ansible node1 -m uri -a \
"url=http://localhost/space-science/ status_code=200"
```

Use only the URL that matches the actual deployment directory.

### Check Nginx errors

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"
```

---

## 8. Quick Summary

- `index.html` is commonly the default home page of a static website.
- Nginx serves it automatically when a directory URL is requested.
- The `root` directive identifies the website directory.
- The `index` directive defines default page filenames.
- `/` maps to the index file in the document root.
- `/space-science/` maps to the index file inside the `space-science` subdirectory.
- A missing index in an existing directory may produce `403`.
- A nonexistent requested path normally produces `404`.
- The browser URL must match the directory where the website was deployed.
