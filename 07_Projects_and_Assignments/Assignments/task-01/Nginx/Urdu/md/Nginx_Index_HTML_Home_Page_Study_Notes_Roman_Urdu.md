# Nginx `index.html` Home Page — Roman Urdu Study Notes

## Fehrist

1. [index.html Kya Hai?](#1-indexhtml-kya-hai)
2. [Nginx Home Page Kaise Dhoondta Hai?](#2-nginx-home-page-kaise-dhoondta-hai)
3. [Root URL Mapping](#3-root-url-mapping)
4. [Subdirectory URL Mapping](#4-subdirectory-url-mapping)
5. [403 vs 404](#5-403-vs-404)
6. [Nginx index Directive](#6-nginx-index-directive)
7. [Useful Verification Commands](#7-useful-verification-commands)
8. [Quick Summary](#8-quick-summary)

---

## 1. `index.html` Kya Hai?

Ji haan, `index.html` aam tor par static website ka default home page hota hai.

Jab user browser mein filename likhe baghair website open karta hai, to web server matching directory ke andar default index file search karta hai.

Misal:

```text
http://192.168.1.154/
```

Nginx automatically yeh file serve kar sakta hai:

```text
/var/www/lawfirm.com/html/index.html
```

User ko browser mein `index.html` likhne ki zaroorat nahi hoti.

Yeh dono URLs aam tor par same page display karte hain:

```text
http://192.168.1.154/
http://192.168.1.154/index.html
```

---

## 2. Nginx Home Page Kaise Dhoondta Hai?

Nginx do important configuration directives use karta hai:

```nginx
root /var/www/lawfirm.com/html;
index index.html index.htm;
```

`root` directive Nginx ko batati hai ke website files kis directory mein rakhi hui hain.

`index` directive Nginx ko batati hai ke jab URL kisi directory ko point kare to kaun se default filenames search karne hain.

Is configuration mein Nginx is order mein check karega:

1. `index.html`
2. `index.htm`

---

## 3. Root URL Mapping

Agar browser yeh request kare:

```text
http://192.168.1.154/
```

to Nginx document root ko default index filename ke saath combine karta hai:

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

Is liye website file yahan maujood honi chahiye:

```text
/var/www/lawfirm.com/html/index.html
```

---

## 4. Subdirectory URL Mapping

Agar browser yeh request kare:

```text
http://192.168.1.154/space-science/
```

to Nginx yeh file search karega:

```text
/var/www/lawfirm.com/html/space-science/index.html
```

Complete mapping:

```text
http://192.168.1.154/space-science/
                      ↓
/var/www/lawfirm.com/html/space-science/index.html
```

Agar website files seedha yahan copy hui hain:

```text
/var/www/lawfirm.com/html/
```

to root URL use karein:

```text
http://192.168.1.154/
```

Agar files yahan copy hui hain:

```text
/var/www/lawfirm.com/html/space-science/
```

to yeh URL use karein:

```text
http://192.168.1.154/space-science/
```

Browser URL aur filesystem deployment path ka aapas mein match hona zaroori hai.

---

## 5. `403` vs `404`

### `403 Forbidden`

Nginx `403 Forbidden` return kar sakta hai jab:

- requested directory maujood ho;
- us mein configured index file maujood na ho;
- directory listing disabled ho; ya
- permissions ya SELinux access block kar raha ho.

Misal:

```text
/var/www/lawfirm.com/html/             ← directory maujood hai
/var/www/lawfirm.com/html/index.html   ← file missing hai
```

### `404 Not Found`

Nginx aam tor par `404 Not Found` tab return karta hai jab requested path maujood na ho.

Browser request:

```text
http://192.168.1.154/space-science/
```

Missing filesystem path:

```text
/var/www/lawfirm.com/html/space-science/
```

### Quick comparison

| Status | Basic matlab | Common lab wajah |
|---|---|---|
| `403 Forbidden` | Nginx ko location mili lekin woh content serve nahi kar saka | Missing index, permissions ya SELinux |
| `404 Not Found` | Requested location maujood nahi | URL deployed directory se match nahi karti |

---

## 6. Nginx `index` Directive

Misal:

```nginx
index index.html index.htm;
```

Is ka matlab:

1. Pehle `index.html` search karo.
2. Agar woh na mile to `index.htm` search karo.

Doosre filenames bhi use ho sakte hain:

```nginx
index home.html index.html;
```

Ab Nginx pehle `home.html` aur phir `index.html` check karega.

Nginx configuration change karne ke baad validate aur reload karein:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Sirf static website files change karne par aam tor par Nginx reload ki zaroorat nahi hoti.

---

## 7. Useful Verification Commands

### Index file ka existence confirm karein

```bash
ansible node1 -m stat -a \
"path=/var/www/lawfirm.com/html/index.html"
```

### Website directory list karein

```bash
ansible node1 -m command -a \
"ls -laZ /var/www/lawfirm.com/html"
```

### Configured roots aur index directives check karein

```bash
ansible node1 -b -m shell -a \
"nginx -T 2>/dev/null | grep -E '^[[:space:]]*(root|index)[[:space:]]'"
```

### Root URL test karein

```bash
ansible node1 -m uri -a \
"url=http://localhost status_code=200"
```

### Subdirectory URL test karein

```bash
ansible node1 -m uri -a \
"url=http://localhost/space-science/ status_code=200"
```

Sirf woh URL use karein jo actual deployment directory se match karti ho.

### Nginx errors check karein

```bash
ansible node1 -b -m command -a \
"tail -n 20 /var/log/nginx/error.log"
```

---

## 8. Quick Summary

- `index.html` aam tor par static website ka default home page hota hai.
- Directory URL request hone par Nginx is file ko automatically serve karta hai.
- `root` directive website directory define karti hai.
- `index` directive default page filenames define karti hai.
- `/` document root ke index file ko map karta hai.
- `/space-science/` space-science subdirectory ke index file ko map karta hai.
- Existing directory mein missing index ki wajah se `403` aa sakta hai.
- Nonexistent requested path ki wajah se aam tor par `404` aata hai.
- Browser URL ko website ke deployment path ke saath match karna zaroori hai.
