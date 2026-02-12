# Authentication Approaches

## Table of Contents
- [Introduction](#introduction)
- [Session-Based Authentication](#session-based-authentication)
  - [How It Works](#how-it-works)
  - [Pros and Cons](#pros-and-cons)
  - [Implementation Example](#implementation-example)
- [Token-Based Authentication (JWT)](#token-based-authentication-jwt)
  - [How JWT Works](#how-jwt-works)
  - [JWT Structure](#jwt-structure)
  - [Pros and Cons](#pros-and-cons-1)
  - [Implementation Example](#implementation-example-1)
- [OAuth 2.0 / OpenID Connect](#oauth-20--openid-connect)
  - [When to Use OAuth](#when-to-use-oauth)
  - [How OAuth Works](#how-oauth-works)
  - [Provider Examples](#provider-examples)
- [API Keys](#api-keys)
  - [When Appropriate](#when-appropriate)
  - [Best Practices](#best-practices)
  - [Implementation](#implementation)
- [Supabase Auth](#supabase-auth)
  - [What Supabase Provides](#what-supabase-provides)
  - [How It Compares](#how-it-compares)
  - [Our Implementation](#our-implementation)
- [Framework Comparison](#framework-comparison)
  - [Django](#django)
  - [Ruby on Rails](#ruby-on-rails)
  - [Next.js](#nextjs)
  - [Laravel (PHP)](#laravel-php)
- [Decision Matrix](#decision-matrix)
- [Summary](#summary)

---

## Introduction

Authentication is about **proving identity**. But there are many ways to do this, each with different tradeoffs:

- **Where do you store state?** Server (sessions) vs client (tokens)
- **How do you validate?** Database lookup vs cryptographic signature
- **What's the UX?** Persistent login vs re-auth vs remember-me
- **What's the scale?** Single server vs distributed system

This guide explores the major approaches, not to declare a "best" option, but to help you understand **when each makes sense**.

---

## Session-Based Authentication

### How It Works

**Traditional approach**: Server stores session state, client stores session ID.

```
┌──────────────────────────────────────────────────────────────┐
│ 1. User logs in with username/password                      │
│    POST /login { username, password }                        │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Server verifies credentials                               │
│    → Queries database for user                               │
│    → Checks password hash                                    │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Server creates session                                    │
│    session_id = random_token()                               │
│    sessions[session_id] = { user_id: 123, ... }              │
│    (stored in memory, Redis, or database)                    │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Server sends session ID to client                         │
│    Set-Cookie: session_id=abc123; HttpOnly; Secure;         │
│               SameSite=Strict; Max-Age=604800                │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Client automatically sends cookie on every request        │
│    GET /api/profile                                          │
│    Cookie: session_id=abc123                                 │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. Server looks up session                                   │
│    session = sessions[request.cookies['session_id']]         │
│    if session: user = get_user(session['user_id'])           │
└──────────────────────────────────────────────────────────────┘
```

**Key insight**: The session ID is meaningless without the server's session store. It's just a lookup key.

### Pros and Cons

| Pros ✅ | Cons ❌ |
|---------|---------|
| **Revocable** - Delete session → user logged out immediately | **Stateful** - Server must track all sessions |
| **Secure** - Session data never leaves server | **Scaling** - Sessions must be shared across servers (sticky sessions or Redis) |
| **Simple** - Browser handles cookies automatically | **CSRF** - Requires CSRF tokens |
| **Fine control** - Can store arbitrary session data | **Mobile unfriendly** - Cookies don't work well in mobile apps |

### Implementation Example

**Python/FastAPI**:
```python
from fastapi import FastAPI, Depends, HTTPException, Request, Response
from fastapi.responses import JSONResponse
import secrets
from datetime import datetime, timedelta

app = FastAPI()

# In-memory session store (use Redis in production)
sessions = {}

@app.post("/login")
async def login(credentials: LoginCredentials, response: Response):
    # Verify credentials
    user = authenticate(credentials.username, credentials.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    # Create session
    session_id = secrets.token_urlsafe(32)
    sessions[session_id] = {
        "user_id": user.id,
        "email": user.email,
        "created_at": datetime.utcnow(),
        "last_activity": datetime.utcnow()
    }
    
    # Set httpOnly cookie
    response.set_cookie(
        key="session_id",
        value=session_id,
        httponly=True,      # JavaScript cannot access
        secure=True,        # HTTPS only
        samesite="strict",  # CSRF protection
        max_age=604800      # 7 days
    )
    
    return {"message": "Logged in successfully"}

async def get_current_user(request: Request):
    session_id = request.cookies.get("session_id")
    if not session_id:
        raise HTTPException(401, "Not authenticated")
    
    session = sessions.get(session_id)
    if not session:
        raise HTTPException(401, "Invalid session")
    
    # Check if session expired (optional)
    if datetime.utcnow() - session["last_activity"] > timedelta(hours=24):
        del sessions[session_id]
        raise HTTPException(401, "Session expired")
    
    # Update last activity (sliding expiration)
    session["last_activity"] = datetime.utcnow()
    
    return get_user(session["user_id"])

@app.get("/api/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user

@app.post("/logout")
async def logout(request: Request, response: Response):
    session_id = request.cookies.get("session_id")
    if session_id and session_id in sessions:
        del sessions[session_id]
    response.delete_cookie("session_id")
    return {"message": "Logged out"}
```

**JavaScript/React**:
```javascript
// No need to store anything - browser handles cookies!

async function login(username, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    credentials: 'include',  // Send cookies
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  })
  
  if (response.ok) {
    // Cookie is set automatically!
    return true
  }
  return false
}

async function getProfile() {
  const response = await fetch('/api/profile', {
    credentials: 'include'  // Send cookies
  })
  return response.json()
}
```

---

## Token-Based Authentication (JWT)

### How JWT Works

**Modern approach**: Server signs a token cryptographically, client stores it.

```
┌──────────────────────────────────────────────────────────────┐
│ 1. User logs in                                              │
│    POST /login { username, password }                        │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Server verifies credentials                               │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Server creates JWT                                        │
│    token = jwt.encode({                                      │
│      "sub": "123",         # user_id                         │
│      "email": "user@example.com",                            │
│      "exp": 1234567890,    # expiration timestamp            │
│    }, SECRET_KEY, algorithm="HS256")                         │
│                                                              │
│    Returns: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...         │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Client stores token                                       │
│    localStorage.setItem('auth_token', token)                 │
│    or sessionStorage or memory                               │
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Client sends token in Authorization header                │
│    GET /api/profile                                          │
│    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...│
└──────────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. Server validates token                                    │
│    payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])│
│    if payload['exp'] > now():                                │
│        user = get_user(payload['sub'])                       │
└──────────────────────────────────────────────────────────────┘
```

**Key insight**: The token contains all the user information. No database lookup needed (stateless).

### JWT Structure

A JWT has three parts, separated by dots:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

│         Header          │           Payload           │        Signature        │
```

**Header** (Base64-encoded JSON):
```json
{
  "alg": "HS256",  // Algorithm
  "typ": "JWT"     // Token type
}
```

**Payload** (Base64-encoded JSON):
```json
{
  "sub": "1234567890",           // Subject (user ID)
  "name": "John Doe",            // Custom claim
  "email": "john@example.com",   // Custom claim
  "exp": 1516239022,             // Expiration timestamp
  "iat": 1516235422              // Issued at timestamp
}
```

**Signature**:
```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  SECRET_KEY
)
```

**Important**: JWT is **not encrypted**—it's just **signed**. Anyone can read the payload. Don't put secrets in JWTs.

```bash
# Decode a JWT:
echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ" | base64 -d
```

### Pros and Cons

| Pros ✅ | Cons ❌ |
|---------|---------|
| **Stateless** - No server-side storage needed | **Not revocable** - Can't invalidate a token before expiry |
| **Scalable** - Works across multiple servers | **Size** - Tokens are large (100-1000+ bytes) |
| **Mobile-friendly** - Easy to use in mobile apps | **XSS risk** - If stored in localStorage, vulnerable to XSS |
| **No CSRF** - Authorization header immune to CSRF | **Secret management** - Must protect signing key |
| **Self-contained** - Includes user info, no DB lookup | **No session state** - Can't track "active sessions" easily |

### Implementation Example

**Python/FastAPI**:
```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from datetime import datetime, timedelta

app = FastAPI()
security = HTTPBearer()

SECRET_KEY = "your-secret-key-keep-this-safe"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@app.post("/login")
async def login(credentials: LoginCredentials):
    user = authenticate(credentials.username, credentials.password)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    access_token = create_access_token(data={
        "sub": str(user.id),
        "email": user.email
    })
    
    return {"access_token": access_token, "token_type": "bearer"}

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(401, "Invalid token")
    except JWTError:
        raise HTTPException(401, "Invalid token")
    
    user = get_user(int(user_id))
    if user is None:
        raise HTTPException(401, "User not found")
    return user

@app.get("/api/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return current_user
```

**JavaScript/React**:
```javascript
// Store token
async function login(username, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  })
  
  if (response.ok) {
    const data = await response.json()
    localStorage.setItem('auth_token', data.access_token)
    return true
  }
  return false
}

// Use token
async function getProfile() {
  const token = localStorage.getItem('auth_token')
  
  const response = await fetch('/api/profile', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })
  
  return response.json()
}

// Clear token on logout
function logout() {
  localStorage.removeItem('auth_token')
}
```

---

## OAuth 2.0 / OpenID Connect

### When to Use OAuth

**OAuth 2.0**: For **authorization** (delegating access to resources)
**OpenID Connect**: For **authentication** (proving identity via third party)

**Use cases**:
- "Sign in with Google/GitHub/Apple"
- Allowing third-party apps to access your API
- Avoiding password management entirely

**Don't use when**:
- You need full control over auth UX
- You're building internal tools (simpler auth works)
- Your users don't have Google/GitHub accounts

### How OAuth Works

**Simplified "Authorization Code" flow**:

```
┌────────┐                                          ┌────────────┐
│        │  1. Click "Sign in with Google"         │            │
│        │─────────────────────────────────────────▶│            │
│        │                                          │            │
│  Your  │  2. Redirect to Google                  │   Google   │
│  App   │─────────────────────────────────────────▶│            │
│        │                                          │            │
│        │  3. User logs in to Google              │            │
│        │◀─────────────────────────────────────────│            │
│        │     Google redirects back with code      │            │
│        │                                          │            │
│        │  4. Exchange code for token             │            │
│        │─────────────────────────────────────────▶│            │
│        │◀─────────────────────────────────────────│            │
│        │     Returns access_token                 │            │
│        │                                          │            │
│        │  5. Use token to get user info          │            │
│        │─────────────────────────────────────────▶│            │
│        │◀─────────────────────────────────────────│            │
│        │     Returns { email, name, ... }         │            │
└────────┘                                          └────────────┘
```

**Key concepts**:
- **Authorization code**: One-time code to exchange for tokens
- **Access token**: Used to access protected resources
- **Refresh token**: Used to get new access tokens
- **Scope**: What permissions the app is requesting

### Provider Examples

**Google OAuth**:
```python
from authlib.integrations.starlette_client import OAuth

oauth = OAuth()
oauth.register(
    name='google',
    client_id='YOUR_CLIENT_ID',
    client_secret='YOUR_CLIENT_SECRET',
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

@app.get('/login/google')
async def login_google(request: Request):
    redirect_uri = request.url_for('auth_google')
    return await oauth.google.authorize_redirect(request, redirect_uri)

@app.get('/auth/google')
async def auth_google(request: Request):
    token = await oauth.google.authorize_access_token(request)
    user_info = token['userinfo']
    
    # Create or update user in your database
    user = upsert_user(
        email=user_info['email'],
        name=user_info['name'],
        avatar=user_info['picture']
    )
    
    # Create your own session/JWT
    session_token = create_access_token({"sub": str(user.id)})
    
    return {"access_token": session_token}
```

**GitHub OAuth**:
```javascript
// Frontend redirect:
const clientId = 'YOUR_GITHUB_CLIENT_ID'
const redirectUri = 'http://localhost:3000/auth/callback'
const scope = 'read:user user:email'

window.location.href = `https://github.com/login/oauth/authorize?` +
  `client_id=${clientId}&redirect_uri=${redirectUri}&scope=${scope}`

// Callback handler:
async function handleCallback() {
  const params = new URLSearchParams(window.location.search)
  const code = params.get('code')
  
  // Send code to your backend
  const response = await fetch('/api/auth/github', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code })
  })
  
  const { access_token } = await response.json()
  localStorage.setItem('auth_token', access_token)
}
```

---

## API Keys

### When Appropriate

**Good for**:
- Machine-to-machine communication
- Long-lived service accounts
- Simple authentication without user login
- Rate limiting third-party API consumers

**Bad for**:
- User authentication (use sessions/JWT instead)
- Short-term access (keys are long-lived)
- Mobile apps (keys can be extracted)

### Best Practices

1. **Prefix keys** for easy identification: `pk_live_abc123`, `sk_test_xyz789`
2. **Hash keys** in database (like passwords)
3. **Allow rotation** without breaking existing integrations
4. **Rate limit per key**
5. **Provide multiple keys** for different environments/services

### Implementation

**Generate API key**:
```python
import secrets
import hashlib

def generate_api_key():
    # Generate random key
    key = f"pk_live_{secrets.token_urlsafe(32)}"
    
    # Hash for storage
    key_hash = hashlib.sha256(key.encode()).hexdigest()
    
    # Store hash in database
    db.execute(
        "INSERT INTO api_keys (key_hash, user_id) VALUES (?, ?)",
        (key_hash, user_id)
    )
    
    # Return plain key (only shown once!)
    return key
```

**Validate API key**:
```python
async def get_api_key_user(api_key: str = Header(..., alias="X-API-Key")):
    # Hash provided key
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    
    # Look up in database
    result = db.query(ApiKey).filter(ApiKey.key_hash == key_hash).first()
    
    if not result:
        raise HTTPException(401, "Invalid API key")
    
    if not result.is_active:
        raise HTTPException(401, "API key revoked")
    
    # Update last_used timestamp
    result.last_used = datetime.utcnow()
    db.commit()
    
    return result.user

@app.get("/api/providers")
async def list_providers(user: User = Depends(get_api_key_user)):
    return get_providers_for_user(user)
```

**Usage**:
```bash
curl -H "X-API-Key: pk_live_abc123..." https://api.example.com/providers
```

---

## Supabase Auth

### What Supabase Provides

**Supabase Auth** is a complete authentication system built on PostgreSQL:

- **User management**: Sign up, login, password reset
- **Email verification**: Confirm email before activation
- **OAuth providers**: Google, GitHub, Azure, etc.
- **Magic links**: Passwordless email login
- **JWT tokens**: Automatic token generation and refresh
- **Row Level Security**: Database-level authorization
- **Session management**: Refresh tokens, automatic renewal

**Architecture**:
```
React App
    ↓
Supabase Client Library
    ↓
Supabase Auth API (GoTrue)
    ↓
PostgreSQL (stores users)
    ↓
Returns JWT (signed with secret)
```

### How It Compares

| Feature | Supabase Auth | Custom JWT | Sessions | OAuth |
|---------|---------------|------------|----------|-------|
| **Setup time** | 5 minutes | 1-2 hours | 2-4 hours | 4-8 hours |
| **User management UI** | ✅ Built-in | ❌ Build it | ❌ Build it | ⚠️ Per provider |
| **Email verification** | ✅ Built-in | ❌ Build it | ❌ Build it | ⚠️ Provider-dependent |
| **Password reset** | ✅ Built-in | ❌ Build it | ❌ Build it | N/A |
| **OAuth providers** | ✅ 10+ built-in | ❌ Build it | ❌ Build it | ✅ But manual |
| **Token refresh** | ✅ Automatic | ⚠️ Manual | N/A | ⚠️ Manual |
| **Stateless** | ✅ Yes (JWT) | ✅ Yes | ❌ No | ✅ Yes |
| **Row-level security** | ✅ PostgreSQL RLS | ❌ App-level | ❌ App-level | ❌ App-level |

**TL;DR**: Supabase Auth gives you 80% of what you need in 5% of the time.

### Our Implementation

**Frontend** (`web/src/lib/auth.ts`):
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

// Sign up
export async function signUp(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({ email, password })
  return { data, error }
}

// Sign in
export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  return { data, error }
}

// Get current session
export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

// Sign out
export async function signOut() {
  await supabase.auth.signOut()
}
```

**Backend** (`api/app/auth.py`):
```python
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import create_client, Client
import os

supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_KEY")  # Service key for backend
)

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        # Verify JWT with Supabase
        user = supabase.auth.get_user(credentials.credentials)
        return user
    except Exception as e:
        raise HTTPException(401, "Invalid or expired token")

@app.get("/api/profile")
async def get_profile(user = Depends(get_current_user)):
    return {"email": user.email, "id": user.id}
```

**Token flow**:
```
1. User signs in → Supabase returns JWT
2. Frontend stores JWT in localStorage
3. Frontend sends: Authorization: Bearer <JWT>
4. Backend validates JWT with Supabase
5. Backend returns protected data
```

**See also**:
- `~/Repo/project_base/reference/learning_module/docs/12b-supabase-auth.md`
- `~/Repo/project_base/reference/learning_module/docs/12c-dev-auth-strategy.md`

---

## Framework Comparison

### Django

**Approach**: Session-based by default

```python
# Built-in user model and session management
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required

def login_view(request):
    user = authenticate(username=username, password=password)
    if user:
        login(request, user)  # Creates session automatically
        return redirect('dashboard')

@login_required  # Checks session automatically
def dashboard(request):
    return render(request, 'dashboard.html', {'user': request.user})
```

**Key features**:
- Session stored in database (or cache)
- `request.user` available everywhere
- CSRF protection built-in
- Middleware handles everything

### Ruby on Rails

**Approach**: Session-based with encrypted cookies

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id  # Rails stores in encrypted cookie
      redirect_to root_path
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_login
  
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
```

**Key features**:
- Session encrypted in cookie (stateless)
- CSRF protection automatic
- `current_user` helper
- Devise gem for full-featured auth

### Next.js

**Approach**: Flexible (supports sessions, JWT, OAuth)

**With next-auth**:
```javascript
// pages/api/auth/[...nextauth].js
import NextAuth from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'

export default NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    })
  ],
  session: {
    strategy: 'jwt',  // or 'database'
  }
})

// pages/profile.js
import { useSession } from 'next-auth/react'

export default function Profile() {
  const { data: session } = useSession()
  
  if (!session) return <p>Not authenticated</p>
  
  return <p>Welcome {session.user.email}</p>
}
```

**Key features**:
- Supports JWT and database sessions
- Built-in OAuth providers
- API routes for auth endpoints
- Edge-compatible (Vercel)

### Laravel (PHP)

**Approach**: Session-based with optional API tokens

```php
// routes/web.php
Route::post('/login', function (Request $request) {
    $credentials = $request->only('email', 'password');
    
    if (Auth::attempt($credentials)) {
        $request->session()->regenerate();  // Prevent session fixation
        return redirect()->intended('dashboard');
    }
    
    return back()->withErrors(['email' => 'Invalid credentials']);
});

// routes/api.php (for API tokens)
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Controller
class DashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');  // Require authentication
    }
    
    public function index()
    {
        return view('dashboard', ['user' => auth()->user()]);
    }
}
```

**Key features**:
- Session for web, Sanctum for API
- CSRF middleware built-in
- `auth()->user()` helper
- Passport for OAuth server

---

## Decision Matrix

### Choosing an Authentication Approach

| Your Situation | Recommended Approach | Reasoning |
|----------------|---------------------|-----------|
| **New project, solo/small team** | Supabase Auth or Firebase Auth | Fastest to market, handles edge cases |
| **Enterprise, compliance requirements** | Custom session-based | Full control, audit trails, immediate revocation |
| **Microservices architecture** | JWT with API gateway | Stateless, works across services |
| **Mobile app + web app** | JWT or OAuth | Mobile apps don't handle cookies well |
| **Internal tools (5-50 users)** | Simple sessions or HTTP Basic | Don't over-engineer |
| **Third-party API** | API keys | Simple, long-lived, revocable |
| **"Sign in with Google/GitHub"** | OAuth 2.0 / OpenID Connect | Users expect it, avoid password management |
| **Multi-tenant SaaS** | JWT with tenant claims | Tenant ID in token, no DB lookup |
| **Real-time features (WebSockets)** | JWT (passed in connection) | Cookies don't work with WebSockets easily |
| **High-security (banking, healthcare)** | Sessions + MFA + short timeouts | Revocable, auditable, supports MFA flows |

### Storage Decision Matrix

| Storage Method | Security | Complexity | XSS Vulnerable | CSRF Vulnerable | Best For |
|----------------|----------|------------|----------------|-----------------|----------|
| **localStorage** | ⚠️ Medium | 🟢 Low | ✅ Yes | ❌ No | MVPs, internal tools |
| **httpOnly cookie** | ✅ High | 🟡 Medium | ❌ No | ✅ Yes (need CSRF tokens) | Production apps |
| **sessionStorage** | ⚠️ Medium | 🟢 Low | ✅ Yes | ❌ No | Single-session apps |
| **Memory (state)** | ✅ Highest | 🔴 High | ❌ No | ❌ No | High-security, but UX suffers (re-login on refresh) |

### Our Choice: Supabase Auth + localStorage

**Why?**
1. **Speed**: Building custom auth would take weeks
2. **Features**: Email verification, OAuth, password reset all built-in
3. **Security**: Supabase handles JWT signing, refresh tokens, etc.
4. **UX**: Persistent login without complex cookie management
5. **Tradeoff**: Accept XSS risk (mitigated by React's escaping) for faster development

**When we'd change**:
- If we get funding and hire a dedicated security engineer
- If we handle PHI (Protected Health Information) requiring HIPAA compliance
- If we experience an XSS vulnerability that exposes tokens
- If we need fine-grained session revocation (e.g., "log out all devices")

**Migration path**: See [03-token-storage-deep-dive.md](./03-token-storage-deep-dive.md)

---

## Summary

### Key Takeaways

1. **Sessions vs Tokens**:
   - **Sessions**: Stateful, revocable, require server storage
   - **Tokens**: Stateless, scalable, not revocable

2. **Framework patterns**:
   - **Django/Rails**: Session-based by default (mature ecosystems)
   - **FastAPI/Express**: Flexible (you choose the approach)
   - **Next.js**: Hybrid (JWT for API, sessions for pages)

3. **Supabase Auth**:
   - Combines JWT (stateless) with refresh tokens (revocable)
   - Provides OAuth, email verification, password reset out of the box
   - Best for teams that want to ship fast without building auth from scratch

4. **Decision criteria**:
   - **Control** → Custom sessions
   - **Scale** → JWT
   - **Speed** → Supabase/Firebase
   - **Third-party** → OAuth
   - **API consumers** → API keys

### Next Steps

1. Read **[03-token-storage-deep-dive.md](./03-token-storage-deep-dive.md)** for localStorage vs httpOnly cookies
2. Review our auth implementation:
   - `web/src/lib/auth.ts`
   - `web/src/hooks/useAuth.ts`
   - `api/app/auth.py`
3. Understand Supabase setup: `~/Repo/project_base/reference/learning_module/docs/12b-supabase-auth.md`
4. Consider when you'd migrate to a different approach

### Resources

- **JWT.io**: https://jwt.io/ (decode JWTs, learn about algorithms)
- **Supabase Auth docs**: https://supabase.com/docs/guides/auth
- **OAuth 2.0 spec**: https://oauth.net/2/
- **next-auth docs**: https://next-auth.js.org/
- **OWASP Auth Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

---

*Part of the [Provider Search Security & Auth Learning Module](./00-overview.md)*
