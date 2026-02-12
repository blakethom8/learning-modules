# Session Management

## Table of Contents

1. [Introduction](#introduction)
2. [What is a Session?](#what-is-a-session)
3. [Token Lifecycle](#token-lifecycle)
   - [Issuance](#issuance)
   - [Validation](#validation)
   - [Refresh](#refresh)
   - [Expiration](#expiration)
4. [Expiration Strategies](#expiration-strategies)
   - [Fixed Expiration](#fixed-expiration)
   - [Sliding Expiration](#sliding-expiration)
   - [Choosing Between Them](#choosing-between-them)
5. [Refresh Tokens](#refresh-tokens)
   - [Why Refresh Tokens Exist](#why-refresh-tokens-exist)
   - [Access Token vs Refresh Token](#access-token-vs-refresh-token)
   - [Refresh Token Rotation](#refresh-token-rotation)
   - [Refresh Token Patterns](#refresh-token-patterns)
6. [Session Attacks](#session-attacks)
   - [Session Fixation](#session-fixation)
   - [Session Hijacking](#session-hijacking)
   - [Session Replay](#session-replay)
   - [Protection Strategies](#protection-strategies)
7. [Supabase Session Management](#supabase-session-management)
   - [How Supabase Handles Sessions](#how-supabase-handles-sessions)
   - [Automatic Token Refresh](#automatic-token-refresh)
   - [Multi-Tab Synchronization](#multi-tab-synchronization)
   - [Provider Search Implementation](#provider-search-implementation)
8. [Framework Comparison](#framework-comparison)
   - [Django Sessions](#django-sessions)
   - [Ruby on Rails Sessions](#ruby-on-rails-sessions)
   - [Next.js Sessions](#nextjs-sessions)
   - [Laravel Sessions](#laravel-sessions)
   - [Comparison Table](#comparison-table)
9. [Provider Search's Approach](#provider-searchs-approach)
   - [Current Architecture](#current-architecture)
   - [Code Walkthrough](#code-walkthrough)
   - [Token Refresh Flow](#token-refresh-flow)
   - [Handling Expired Tokens](#handling-expired-tokens)
10. [Best Practices](#best-practices)
11. [Common Pitfalls](#common-pitfalls)
12. [Further Reading](#further-reading)

---

## Introduction

**Session management** is the process of maintaining stateful interactions between a client and server across multiple HTTP requests. Since HTTP is stateless by design, sessions provide a way to remember who a user is, what they're doing, and when their authentication should expire.

Think of a session like checking into a hotel:
- **Check-in** = Authentication (proving who you are)
- **Room key** = Session token (proof of your authenticated session)
- **Key expiration** = Session timeout (the key stops working after checkout time)
- **Extending your stay** = Token refresh (getting a new key without re-checking in)

This guide explores how sessions work, the different strategies for managing token lifecycles, and how Provider Search implements session management using Supabase Auth.

## What is a Session?

A **session** represents a period of authenticated interaction between a user and an application. It typically includes:

1. **Identity**: Who the user is (user ID, email, metadata)
2. **Duration**: How long the session is valid
3. **State**: Any session-specific data (shopping cart, preferences, etc.)
4. **Proof**: A token or identifier that proves the session is valid

### Session Storage: Server vs Client

**Server-side sessions** (traditional):
```
┌─────────┐                    ┌─────────┐
│ Browser │                    │  Server │
│         │                    │         │
│ Cookie: │◄───────────────────┤ Session │
│ sess123 │                    │  Store  │
│         │                    │         │
│         │  Request + Cookie  │ sess123:│
│         ├───────────────────►│ {user:1,│
│         │                    │  role:  │
│         │◄───────────────────┤  admin} │
└─────────┘  Response          └─────────┘
```

The browser only stores a **session ID**. All session data lives on the server.

**Client-side sessions** (JWT):
```
┌─────────┐                    ┌─────────┐
│ Browser │                    │  Server │
│         │                    │         │
│ JWT:    │                    │         │
│ eyJhbGc │  Request + JWT     │ Verify  │
│ iOiJIUz │───────────────────►│ signature│
│ I1NiIs │                    │         │
│ InR5cC │◄───────────────────┤         │
│ I6IkpX │  Response           │         │
└─────────┘                    └─────────┘
```

The browser stores **all session data** in the JWT. The server only validates the signature.

### Why This Matters

**Server-side sessions**:
- ✅ Can be revoked instantly (just delete from session store)
- ✅ Server has full control
- ✅ Can store large amounts of data
- ❌ Requires backend storage (Redis, database)
- ❌ Harder to scale horizontally
- ❌ Requires session persistence across servers

**Client-side sessions (JWT)**:
- ✅ Stateless (no server-side storage)
- ✅ Easy to scale horizontally
- ✅ Works across multiple domains/services
- ❌ Cannot be revoked before expiration (without additional infrastructure)
- ❌ Larger payload (entire token sent with each request)
- ❌ Token size limits (typically 4KB for cookies, 10MB for localStorage)

**Provider Search uses JWT** (issued by Supabase) for stateless, scalable authentication.

---

## Token Lifecycle

Every authentication token goes through four key phases:

```
┌──────────┐    ┌────────────┐    ┌─────────┐    ┌────────────┐
│ Issuance │───►│ Validation │───►│ Refresh │───►│ Expiration │
└──────────┘    └────────────┘    └─────────┘    └────────────┘
```

### Issuance

**When a user authenticates**, the server creates a token containing:

```json
{
  "sub": "user-id-123",
  "email": "user@example.com",
  "role": "authenticated",
  "iat": 1704067200,  // Issued at (timestamp)
  "exp": 1704153600   // Expires at (timestamp)
}
```

**In Provider Search** (using Supabase Auth):

```typescript
// web/src/lib/auth.ts
export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) throw error;

  // Supabase automatically stores the session
  // Session includes:
  // - access_token (JWT)
  // - refresh_token (opaque token)
  // - expires_at (timestamp)
  // - user (user metadata)

  return data.session;
}
```

**What Supabase gives us**:
- `access_token`: Short-lived JWT (default: 1 hour)
- `refresh_token`: Long-lived opaque token (default: 30 days)
- `expires_at`: Timestamp when access token expires
- `user`: User metadata (id, email, app_metadata, user_metadata)

### Validation

**On every authenticated request**, the server validates the token:

```python
# api/app/auth.py
from jose import jwt, JWTError
from supabase import Client

async def verify_token(token: str) -> dict:
    """
    Validate a JWT token from Supabase Auth.
    
    Two validation approaches:
    1. Local JWT validation (fast, but can't detect revoked tokens)
    2. Supabase API validation (slower, but authoritative)
    """
    
    # Approach 1: Local JWT validation (what we use)
    try:
        # Decode and verify the JWT signature
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,  # From Supabase project settings
            algorithms=["HS256"],
            audience="authenticated",
        )
        
        # Check expiration
        if payload.get("exp") < time.time():
            raise JWTError("Token expired")
        
        return payload
    
    except JWTError as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid token: {str(e)}"
        )
```

**Validation steps**:
1. **Signature verification**: Ensures token wasn't tampered with
2. **Expiration check**: Ensures token is still valid
3. **Audience check**: Ensures token was issued for this application
4. **Issuer check** (optional): Ensures token came from expected auth server

**In Provider Search**, we validate on every protected route:

```python
# api/app/middleware/auth.py
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """
    Dependency that validates the JWT and returns user info.
    
    Usage:
        @app.get("/protected")
        async def protected_route(user: dict = Depends(get_current_user)):
            return {"message": f"Hello {user['email']}"}
    """
    token = credentials.credentials
    return await verify_token(token)
```

### Refresh

**When the access token expires**, the client uses the refresh token to get a new access token **without requiring the user to log in again**.

```typescript
// web/src/lib/auth.ts
export async function refreshSession() {
  const { data, error } = await supabase.auth.refreshSession();
  
  if (error) {
    // Refresh token is invalid/expired
    // User needs to log in again
    throw error;
  }
  
  // New access token and refresh token
  return data.session;
}
```

**Why refresh is important**:
- Short-lived access tokens limit the window of exposure if stolen
- Long-lived refresh tokens allow seamless user experience
- Refresh tokens can be rotated (more on this below)

**Automatic refresh in Supabase**:

```typescript
// Supabase client automatically refreshes tokens
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'TOKEN_REFRESHED') {
    console.log('Token automatically refreshed');
    // New session is automatically stored
  }
  
  if (event === 'SIGNED_OUT') {
    console.log('User signed out (refresh failed or manual logout)');
  }
});
```

### Expiration

**When both tokens expire**, the session ends and the user must log in again.

```
Access Token Lifetime:    [====] 1 hour
                               ↓ refresh
                          [====] 1 hour (new access token)
                               ↓ refresh
                          [====] 1 hour
                               ↓
Refresh Token Lifetime:   [========================] 30 days
                                                    ↓
                                              User must log in again
```

**Expiration handling in Provider Search**:

```typescript
// web/src/hooks/useAuth.ts
export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  
  useEffect(() => {
    // Check initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });
    
    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
        
        // If session is null, user is logged out
        if (!session) {
          // Redirect to login page
          window.location.href = '/login';
        }
      }
    );
    
    return () => subscription.unsubscribe();
  }, []);
  
  return { user };
}
```

---

## Expiration Strategies

How long should a session last? There are two primary approaches:

### Fixed Expiration

**The session expires at a specific time**, regardless of user activity.

```
Login at 9:00 AM, expires at 5:00 PM
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ 9  │ 10 │ 11 │ 12 │ 1  │ 2  │ 3  │ 4  │ ← Active
└────┴────┴────┴────┴────┴────┴────┴────┘
                                          ↓
                                       Expires at 5 PM
                                       (even if user is active)
```

**Pros**:
- Predictable expiration
- Enforces maximum session duration
- Good for high-security applications (banking, admin panels)

**Cons**:
- Can interrupt active users
- Poor UX for long-running tasks

**Example**: Bank session expires after 15 minutes, no matter what.

### Sliding Expiration

**The session expires after a period of inactivity**, but resets with each activity.

```
Login at 9:00 AM, 8-hour inactivity timeout
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ 9  │ 10 │ 11 │ 12 │ 1  │ 2  │ 3  │ 4  │
└────┴─▲──┴────┴─▲──┴────┴─▲──┴────┴────┘
       │         │         │
    Activity  Activity  Activity
    (resets   (resets   (resets
    timeout)  timeout)  timeout)

If inactive from 4 PM → midnight, expires at midnight
```

**Pros**:
- Better UX (active users stay logged in)
- Natural expiration during inactivity
- Common for SaaS applications

**Cons**:
- Can lead to indefinitely long sessions
- Requires updating session on each request (more server load)

**Example**: Gmail keeps you logged in as long as you're active.

### Choosing Between Them

| Use Case | Recommended Strategy | Reason |
|----------|---------------------|--------|
| Banking, admin panels | Fixed | Security > UX |
| SaaS apps, social media | Sliding | UX > strict security |
| Healthcare/HIPAA | Fixed + absolute max | Compliance requirements |
| E-commerce | Sliding (with max cap) | Keep users in checkout flow |
| Internal tools | Sliding | Trust internal users more |

**Provider Search uses fixed expiration** (1 hour for access tokens) with automatic refresh for a sliding-like experience:

```
Access token:    [====] 1 hour (fixed)
                     ↓ auto-refresh if user is active
                 [====] 1 hour (new token, fixed)
                     ↓ continues until refresh token expires
Refresh token:   [========================] 30 days (absolute max)
```

This gives us:
- **Security**: Short-lived access tokens (1 hour max exposure)
- **UX**: Seamless experience via automatic refresh (feels like sliding)
- **Absolute limit**: 30-day refresh token (prevents indefinite sessions)

---

## Refresh Tokens

### Why Refresh Tokens Exist

**The Problem**: We want both security and good UX:
- **Short-lived tokens** = Secure (if stolen, limited damage)
- **Long-lived tokens** = Good UX (don't log users out constantly)

**The Solution**: Use **two tokens**:
1. **Access token** (short-lived, high-privilege): Used for API requests
2. **Refresh token** (long-lived, single-use): Used only to get new access tokens

```
┌──────────────┐                 ┌──────────────┐
│   Client     │                 │    Server    │
│              │                 │              │
│ Access Token │─── API Request ──►             │
│ (1 hour)     │◄─── Response ────              │
│              │                 │              │
│              │  (1 hour later) │              │
│              │                 │              │
│ Refresh      │── Refresh Req ──►             │
│ Token        │◄─ New Tokens ────              │
│ (30 days)    │                 │              │
└──────────────┘                 └──────────────┘
```

### Access Token vs Refresh Token

| Aspect | Access Token | Refresh Token |
|--------|-------------|---------------|
| **Purpose** | Authorize API requests | Get new access tokens |
| **Lifespan** | Short (minutes to hours) | Long (days to months) |
| **Storage** | Memory, localStorage, cookie | Secure httpOnly cookie (ideal) |
| **Exposure** | Sent with every API request | Only sent to token endpoint |
| **Format** | JWT (self-contained) | Opaque token (reference) |
| **Revocable** | Not easily (unless centralized) | Yes (stored in database) |

**Access token** (JWT):
```json
{
  "sub": "user-123",
  "email": "user@example.com",
  "role": "authenticated",
  "iat": 1704067200,
  "exp": 1704070800  // 1 hour from now
}
```

**Refresh token** (opaque):
```
srt_d4f5g6h7j8k9l0m1n2p3q4r5s6t7u8v9w0x1y2z3
```

The refresh token is just a random string. The server looks it up in a database to validate it.

### Refresh Token Rotation

**Problem**: If a refresh token is stolen, the attacker can keep getting new access tokens until the refresh token expires (30 days).

**Solution**: **Rotate** the refresh token on every use:

```
Request 1: Use refresh_token_A → Get access_token_1 + refresh_token_B
                                  (refresh_token_A is now invalid)

Request 2: Use refresh_token_B → Get access_token_2 + refresh_token_C
                                  (refresh_token_B is now invalid)
```

**Rotation benefits**:
1. **Limits replay attacks**: Each refresh token is single-use
2. **Detects token theft**: If refresh_token_A is used twice, the server knows something is wrong
3. **Enables automatic revocation**: Server can invalidate all tokens for that user

**Supabase implements refresh token rotation** automatically:

```typescript
const { data, error } = await supabase.auth.refreshSession();

// data.session.refresh_token is a NEW token
// The old refresh token is now invalid
```

**Detection of stolen tokens**:

```python
# Conceptual implementation (Supabase handles this internally)
def refresh_token(old_refresh_token: str) -> dict:
    # Look up the token in the database
    token_record = db.query(RefreshToken).filter_by(
        token=old_refresh_token
    ).first()
    
    if not token_record:
        raise InvalidTokenError()
    
    if token_record.used:
        # This token was already used!
        # Someone is replaying an old token (possible theft)
        
        # Revoke ALL tokens for this user
        db.query(RefreshToken).filter_by(
            user_id=token_record.user_id
        ).delete()
        
        # Notify security team
        log_security_event("refresh_token_replay", token_record.user_id)
        
        raise TokenReplayDetectedError()
    
    # Mark as used
    token_record.used = True
    db.commit()
    
    # Issue new tokens
    new_access_token = create_access_token(token_record.user_id)
    new_refresh_token = create_refresh_token(token_record.user_id)
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
    }
```

### Refresh Token Patterns

**Pattern 1: Automatic Refresh (what Provider Search uses)**

The client automatically refreshes the token before it expires:

```typescript
// Supabase handles this automatically
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'TOKEN_REFRESHED') {
    console.log('Token refreshed:', session);
  }
});
```

**Pattern 2: On-Demand Refresh**

The client waits for a 401 response, then refreshes:

```typescript
async function apiCall(endpoint: string) {
  try {
    return await fetch(endpoint, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
  } catch (error) {
    if (error.status === 401) {
      // Token expired, refresh it
      await refreshSession();
      
      // Retry the request
      return await fetch(endpoint, {
        headers: { Authorization: `Bearer ${newAccessToken}` }
      });
    }
    throw error;
  }
}
```

**Pattern 3: Hybrid (best UX)**

Automatically refresh 5 minutes before expiration, but also handle 401 responses:

```typescript
// Check expiration every minute
setInterval(() => {
  const session = supabase.auth.session();
  const expiresAt = session?.expires_at;
  
  if (expiresAt && expiresAt - Date.now() < 5 * 60 * 1000) {
    // Less than 5 minutes until expiration
    supabase.auth.refreshSession();
  }
}, 60 * 1000);

// Also handle 401 responses
axios.interceptors.response.use(
  response => response,
  async error => {
    if (error.response?.status === 401) {
      await supabase.auth.refreshSession();
      return axios.request(error.config);  // Retry
    }
    return Promise.reject(error);
  }
);
```

---

## Session Attacks

### Session Fixation

**Attack**: The attacker sets the victim's session ID before they log in.

```
1. Attacker gets session ID: sess123
2. Attacker tricks victim into using sess123 (via URL, XSS, etc.)
3. Victim logs in (using sess123)
4. Attacker uses sess123 to access victim's account
```

**Example**:
```
https://example.com/login?session=sess123
```

**Defense: Regenerate session ID on login**

```python
def login(username: str, password: str):
    # Validate credentials
    user = authenticate(username, password)
    
    # CRITICAL: Generate a NEW session ID
    old_session_id = request.session.id
    new_session_id = generate_session_id()
    
    # Invalidate old session
    delete_session(old_session_id)
    
    # Create new session with new ID
    create_session(new_session_id, user)
    
    return new_session_id
```

**Supabase protects against this** by issuing new tokens on every login (tokens are not reused).

### Session Hijacking

**Attack**: The attacker steals an active session token.

**Methods**:
1. **XSS**: Steal token from localStorage/cookies via JavaScript
2. **Network sniffing**: Intercept unencrypted HTTP traffic
3. **Malware**: Keylogger or screen capture
4. **Social engineering**: Trick user into revealing token

**Defense strategies**:

1. **Use HTTPS** (prevents network sniffing):
```python
# Force HTTPS in production
if not request.is_secure and settings.ENVIRONMENT == "production":
    return redirect(f"https://{request.get_host()}{request.path}")
```

2. **HttpOnly cookies** (prevents XSS theft):
```python
response.set_cookie(
    "session",
    value=session_token,
    httponly=True,  # JavaScript cannot access
    secure=True,    # Only sent over HTTPS
    samesite="Strict"  # CSRF protection
)
```

3. **Token binding** (tie token to specific client):
```python
def create_token(user_id: str, request: Request) -> str:
    payload = {
        "sub": user_id,
        "ip": request.client.host,
        "user_agent": request.headers.get("user-agent"),
    }
    return jwt.encode(payload, SECRET_KEY)

def validate_token(token: str, request: Request):
    payload = jwt.decode(token, SECRET_KEY)
    
    # Verify IP and user agent match
    if payload["ip"] != request.client.host:
        raise InvalidTokenError("IP mismatch")
    
    if payload["user_agent"] != request.headers.get("user-agent"):
        raise InvalidTokenError("User agent mismatch")
```

4. **Short token lifetimes** (limit window of exposure):
```python
# Access token expires in 1 hour
# Even if stolen, attacker only has 1 hour
```

### Session Replay

**Attack**: The attacker captures a request and replays it later.

**Example**:
```bash
# Attacker captures this request
POST /api/transfer
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{"to": "attacker-account", "amount": 1000}

# Attacker replays it multiple times
# Each replay transfers another $1000
```

**Defense: Add request uniqueness**

```python
def transfer(request: Request):
    # Require an idempotency key
    idempotency_key = request.headers.get("Idempotency-Key")
    
    if not idempotency_key:
        raise HTTPException(400, "Idempotency-Key required")
    
    # Check if we've seen this key before
    if redis.exists(f"idempotency:{idempotency_key}"):
        # Return the cached result (don't process again)
        return redis.get(f"idempotency:{idempotency_key}")
    
    # Process the transfer
    result = process_transfer(request.json())
    
    # Cache the result for 24 hours
    redis.setex(
        f"idempotency:{idempotency_key}",
        86400,
        json.dumps(result)
    )
    
    return result
```

**Idempotency keys** ensure that replaying a request has no additional effect.

### Protection Strategies

| Attack | Defense | Priority |
|--------|---------|----------|
| Session Fixation | Regenerate session ID on login | Critical |
| Session Hijacking (XSS) | HttpOnly cookies, CSP | Critical |
| Session Hijacking (Network) | HTTPS only | Critical |
| Session Hijacking (Token theft) | Short lifetimes, token binding | High |
| Session Replay | Idempotency keys, nonces | Medium |

**Provider Search's protections**:
- ✅ HTTPS in production (via Vercel/Railway)
- ✅ Short-lived access tokens (1 hour)
- ✅ Automatic token refresh
- ⚠️ localStorage (vulnerable to XSS, but acceptable for our risk profile)
- 🔄 Could add: HttpOnly cookies, CSP headers, token binding

---

## Supabase Session Management

### How Supabase Handles Sessions

Supabase Auth provides a complete session management system:

```typescript
// When user logs in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
});

// Supabase returns:
{
  session: {
    access_token: "eyJhbGc...",  // JWT (1 hour lifetime)
    refresh_token: "srt_...",    // Opaque token (30 day lifetime)
    expires_at: 1704067200,       // Unix timestamp
    expires_in: 3600,             // Seconds until expiration
    token_type: "bearer",
    user: {
      id: "user-123",
      email: "user@example.com",
      // ... other user metadata
    }
  }
}
```

**Where Supabase stores the session**:

```typescript
// By default, Supabase stores in localStorage
localStorage.getItem('supabase.auth.token')

// You can configure it to use sessionStorage, cookies, or custom storage
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: {
    storage: customStorage,  // Implement your own storage
    autoRefreshToken: true,   // Auto-refresh before expiration
    persistSession: true,     // Save session across browser restarts
    detectSessionInUrl: true, // Handle OAuth redirects
  }
});
```

### Automatic Token Refresh

**Supabase automatically refreshes tokens** 10 seconds before they expire:

```typescript
// You don't need to do anything!
// Supabase handles this in the background

// But you can listen for refresh events:
supabase.auth.onAuthStateChange((event, session) => {
  switch (event) {
    case 'SIGNED_IN':
      console.log('User signed in:', session);
      break;
    
    case 'TOKEN_REFRESHED':
      console.log('Token refreshed:', session);
      // New access_token and refresh_token
      break;
    
    case 'SIGNED_OUT':
      console.log('User signed out');
      // Refresh token expired or manual logout
      break;
  }
});
```

**How it works internally**:

```typescript
// Simplified version of what Supabase does
class Auth {
  private refreshTimer: NodeJS.Timeout | null = null;
  
  private scheduleRefresh(expiresAt: number) {
    // Clear existing timer
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
    
    // Refresh 10 seconds before expiration
    const refreshAt = expiresAt - 10 * 1000;
    const delay = refreshAt - Date.now();
    
    this.refreshTimer = setTimeout(() => {
      this.refreshSession();
    }, delay);
  }
  
  async refreshSession() {
    const refreshToken = this.getRefreshToken();
    
    try {
      const response = await fetch(`${SUPABASE_URL}/auth/v1/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          refresh_token: refreshToken,
        }),
      });
      
      const data = await response.json();
      
      // Store new session
      this.setSession(data);
      
      // Schedule next refresh
      this.scheduleRefresh(data.expires_at * 1000);
      
      // Notify listeners
      this.notifyAuthStateChange('TOKEN_REFRESHED', data);
    } catch (error) {
      // Refresh failed (likely refresh token expired)
      this.signOut();
    }
  }
}
```

### Multi-Tab Synchronization

**Problem**: User opens your app in multiple tabs. If they log out in one tab, the other tabs should also log out.

**Supabase handles this** using `localStorage` events:

```typescript
// Tab 1: User logs out
await supabase.auth.signOut();

// Tab 2: Automatically detects logout
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    console.log('User logged out in another tab');
    // Update UI, redirect to login, etc.
  }
});
```

**How it works**:

```typescript
// Simplified implementation
class Auth {
  constructor() {
    // Listen for changes to localStorage
    window.addEventListener('storage', (event) => {
      if (event.key === 'supabase.auth.token') {
        // Session changed in another tab
        const newSession = JSON.parse(event.newValue);
        
        if (newSession) {
          this.notifyAuthStateChange('SIGNED_IN', newSession);
        } else {
          this.notifyAuthStateChange('SIGNED_OUT', null);
        }
      }
    });
  }
}
```

**Note**: This only works with `localStorage`. If you use `sessionStorage` or memory storage, tabs are isolated.

### Provider Search Implementation

**Frontend session management**:

```typescript
// web/src/hooks/useAuth.ts
import { useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes (login, logout, token refresh)
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  return {
    user,
    loading,
    signIn: (email: string, password: string) =>
      supabase.auth.signInWithPassword({ email, password }),
    signUp: (email: string, password: string) =>
      supabase.auth.signUp({ email, password }),
    signOut: () => supabase.auth.signOut(),
  };
}
```

**Backend session validation**:

```python
# api/app/auth.py
from jose import jwt, JWTError
from fastapi import HTTPException
from app.config import settings
import time

async def verify_supabase_token(token: str) -> dict:
    """
    Verify a JWT token issued by Supabase Auth.
    
    This validates:
    1. Signature (using SUPABASE_JWT_SECRET)
    2. Expiration (exp claim)
    3. Audience (should be "authenticated")
    
    Returns the decoded payload if valid.
    """
    try:
        # Decode and verify
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
        
        # Double-check expiration (jwt.decode should do this, but be explicit)
        if payload.get("exp", 0) < time.time():
            raise JWTError("Token expired")
        
        return payload
    
    except JWTError as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
```

**API request with token**:

```typescript
// web/src/lib/api.ts
export async function apiRequest(endpoint: string, options: RequestInit = {}) {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    throw new Error('Not authenticated');
  }
  
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
  });
  
  if (response.status === 401) {
    // Token expired, refresh it
    const { data: { session: newSession } } = await supabase.auth.refreshSession();
    
    if (!newSession) {
      // Refresh failed, user needs to log in again
      throw new Error('Session expired');
    }
    
    // Retry with new token
    return fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${newSession.access_token}`,
        'Content-Type': 'application/json',
      },
    });
  }
  
  return response;
}
```

---

## Framework Comparison

Different frameworks have different approaches to session management:

### Django Sessions

**Server-side sessions** stored in database, Redis, or file system:

```python
# settings.py
SESSION_ENGINE = 'django.contrib.sessions.backends.db'  # Database
# or 'django.contrib.sessions.backends.cache'  # Redis
# or 'django.contrib.sessions.backends.file'   # File system

SESSION_COOKIE_AGE = 1209600  # 2 weeks
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_SAMESITE = 'Lax'

# Session expiration behavior
SESSION_SAVE_EVERY_REQUEST = False  # False = fixed expiration
                                     # True = sliding expiration
```

**Usage**:

```python
# In a view
def my_view(request):
    # Read from session
    user_id = request.session.get('user_id')
    
    # Write to session
    request.session['last_visit'] = datetime.now()
    
    # The session is automatically saved
    return HttpResponse("Hello")
```

**Session model**:

```python
# Django's session table
class Session(models.Model):
    session_key = models.CharField(max_length=40, primary_key=True)
    session_data = models.TextField()
    expire_date = models.DateTimeField()
```

**Pros**:
- Easy to use
- Can store any Python object (pickled)
- Easy to revoke (just delete from database)
- Secure (httpOnly cookies by default)

**Cons**:
- Requires database query on every request
- Harder to scale horizontally (need shared session store)

### Ruby on Rails Sessions

**Cookie-based sessions** (encrypted client-side storage):

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  expire_after: 2.weeks,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax

# Or use Redis for server-side sessions
# Rails.application.config.session_store :redis_store,
#   servers: ['redis://localhost:6379/0'],
#   expire_after: 90.minutes
```

**Usage**:

```ruby
# In a controller
def my_action
  # Read from session
  user_id = session[:user_id]
  
  # Write to session
  session[:last_visit] = Time.now
  
  # Session is automatically encrypted and stored in a cookie
end
```

**Session cookie**:

```
Set-Cookie: _myapp_session=BAh7CEkiD3Nlc3Npb25faWQGOgZFVEkiJTFhN...;
            path=/; HttpOnly; secure; SameSite=Lax
```

**Pros**:
- No database needed (scales horizontally)
- Fast (no database lookup)
- Automatic encryption

**Cons**:
- 4KB size limit
- Cannot be revoked (client-side)
- Sent with every request (bandwidth)

### Next.js Sessions

**Hybrid approach** using `next-auth` or `iron-session`:

```typescript
// app/api/auth/[...nextauth]/route.ts (next-auth)
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        // Validate credentials
        const user = await validateCredentials(credentials);
        return user;
      }
    })
  ],
  session: {
    strategy: 'jwt',  // or 'database' for server-side sessions
    maxAge: 30 * 24 * 60 * 60,  // 30 days
  },
  callbacks: {
    async jwt({ token, user }) {
      // Add user data to token
      if (user) {
        token.id = user.id;
        token.role = user.role;
      }
      return token;
    },
    async session({ session, token }) {
      // Expose user data in session
      session.user.id = token.id;
      session.user.role = token.role;
      return session;
    }
  }
};

export default NextAuth(authOptions);
```

**Usage in components**:

```typescript
// app/profile/page.tsx
import { getServerSession } from 'next-auth/next';
import { authOptions } from '../api/auth/[...nextauth]/route';

export default async function ProfilePage() {
  const session = await getServerSession(authOptions);
  
  if (!session) {
    redirect('/login');
  }
  
  return <div>Hello {session.user.email}</div>;
}
```

**Client-side**:

```typescript
'use client';
import { useSession } from 'next-auth/react';

export default function ClientComponent() {
  const { data: session, status } = useSession();
  
  if (status === 'loading') return <div>Loading...</div>;
  if (status === 'unauthenticated') return <div>Please log in</div>;
  
  return <div>Hello {session.user.email}</div>;
}
```

**Pros**:
- Flexible (JWT or database sessions)
- Built-in OAuth providers
- Server-side rendering support
- Automatic token refresh

**Cons**:
- Next.js specific
- Learning curve
- Requires configuration for each provider

### Laravel Sessions

**Flexible session drivers** (file, cookie, database, Redis, Memcached):

```php
// config/session.php
return [
    'driver' => env('SESSION_DRIVER', 'file'),
    'lifetime' => 120,  // minutes
    'expire_on_close' => false,
    'encrypt' => false,
    'files' => storage_path('framework/sessions'),
    'connection' => null,
    'table' => 'sessions',
    'store' => null,
    'lottery' => [2, 100],  // Session garbage collection probability
    'cookie' => 'laravel_session',
    'path' => '/',
    'domain' => null,
    'secure' => false,
    'http_only' => true,
    'same_site' => 'lax',
];
```

**Usage**:

```php
// In a controller
public function myAction(Request $request)
{
    // Read from session
    $userId = $request->session()->get('user_id');
    
    // Write to session
    $request->session()->put('last_visit', now());
    
    // Flash data (available only on next request)
    $request->session()->flash('status', 'Profile updated!');
    
    return view('profile');
}
```

**Database sessions**:

```php
// database/migrations/xxxx_create_sessions_table.php
Schema::create('sessions', function (Blueprint $table) {
    $table->string('id')->primary();
    $table->foreignId('user_id')->nullable()->index();
    $table->string('ip_address', 45)->nullable();
    $table->text('user_agent')->nullable();
    $table->text('payload');
    $table->integer('last_activity')->index();
});
```

**Pros**:
- Many storage options
- Easy to use
- Automatic garbage collection
- Can track IP and user agent

**Cons**:
- PHP specific
- Requires Laravel framework

### Comparison Table

| Framework | Default Storage | Expiration | Revocable | Scalability | Security |
|-----------|----------------|------------|-----------|-------------|----------|
| **Django** | Database/Redis | Fixed or sliding | Yes | Medium | High (httpOnly) |
| **Rails** | Encrypted cookie | Fixed | No | High | Medium (4KB limit) |
| **Next.js** | JWT (httpOnly cookie) | Fixed | No | High | High |
| **Laravel** | File/Database/Redis | Fixed or sliding | Yes (if DB) | Medium | High (httpOnly) |
| **Supabase** | JWT (localStorage) | Fixed + refresh | No | High | Medium (XSS risk) |

**Provider Search (Supabase)**:
- Storage: JWT in localStorage
- Expiration: 1 hour (access) + 30 days (refresh)
- Revocable: No (unless we add a token blacklist)
- Scalability: High (stateless)
- Security: Medium (vulnerable to XSS, but acceptable for our risk profile)

---

## Provider Search's Approach

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                             │
│                                                             │
│  ┌─────────────┐         ┌──────────────────────────┐      │
│  │  React App  │◄────────┤   localStorage           │      │
│  │             │         │  - supabase.auth.token  │      │
│  └──────┬──────┘         └──────────────────────────┘      │
│         │                                                    │
│         │ Authorization: Bearer eyJhbGc...                  │
└─────────┼────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                         │
│                                                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │  verify_supabase_token(token)                    │      │
│  │    1. Decode JWT                                 │      │
│  │    2. Verify signature (SUPABASE_JWT_SECRET)     │      │
│  │    3. Check expiration                           │      │
│  │    4. Return user info                           │      │
│  └──────────────────────────────────────────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                   Supabase (PostgreSQL)                     │
│                                                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │  auth.users                                      │      │
│  │  - Stores user credentials (hashed)              │      │
│  │  - Manages refresh tokens                        │      │
│  │  - Issues access tokens (JWT)                    │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Code Walkthrough

**1. User signs up**:

```typescript
// web/src/pages/SignUp.tsx
import { supabase } from '../lib/supabase';

async function handleSignUp(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
  });
  
  if (error) {
    alert(error.message);
    return;
  }
  
  // Supabase automatically sends confirmation email
  alert('Check your email to confirm your account');
}
```

**2. User signs in**:

```typescript
// web/src/pages/SignIn.tsx
async function handleSignIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  
  if (error) {
    alert(error.message);
    return;
  }
  
  // Session is automatically stored in localStorage
  // data.session contains:
  // - access_token (JWT)
  // - refresh_token
  // - expires_at
  // - user
  
  // Redirect to dashboard
  window.location.href = '/dashboard';
}
```

**3. Protected route in frontend**:

```typescript
// web/src/components/ProtectedRoute.tsx
import { useAuth } from '../hooks/useAuth';
import { Navigate } from 'react-router-dom';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <div>Loading...</div>;
  }
  
  if (!user) {
    return <Navigate to="/login" />;
  }
  
  return <>{children}</>;
}
```

**4. Making authenticated API requests**:

```typescript
// web/src/lib/api.ts
import { supabase } from './supabase';

export async function searchProviders(query: string) {
  // Get current session
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    throw new Error('Not authenticated');
  }
  
  // Make API request with access token
  const response = await fetch(`${API_URL}/api/search`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query }),
  });
  
  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }
  
  return response.json();
}
```

**5. Backend validates token**:

```python
# api/app/middleware/auth.py
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.auth import verify_supabase_token

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """
    Extract and validate the JWT token from the Authorization header.
    
    Returns the user info from the token payload.
    """
    token = credentials.credentials
    return await verify_supabase_token(token)


# Usage in a route
@app.get("/api/profile")
async def get_profile(user: dict = Depends(get_current_user)):
    return {
        "user_id": user["sub"],
        "email": user["email"],
        "role": user["role"],
    }
```

### Token Refresh Flow

**Automatic refresh** (handled by Supabase client):

```
1. User logs in at 10:00 AM
   - Access token expires at 11:00 AM
   - Refresh token expires in 30 days

2. At 10:59:50 AM (10 seconds before expiration)
   - Supabase client automatically calls /auth/v1/token
   - Sends refresh token
   - Receives new access token + new refresh token

3. New access token stored in localStorage
   - Old tokens are discarded
   - App continues seamlessly

4. This repeats every hour until refresh token expires (30 days)
```

**Manual refresh** (if needed):

```typescript
// Force a refresh
const { data, error } = await supabase.auth.refreshSession();

if (error) {
  // Refresh failed (refresh token expired)
  // User needs to log in again
  await supabase.auth.signOut();
  window.location.href = '/login';
}
```

### Handling Expired Tokens

**401 interceptor** for API requests:

```typescript
// web/src/lib/api.ts
export async function apiRequest(
  endpoint: string,
  options: RequestInit = {}
): Promise<Response> {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    throw new Error('Not authenticated');
  }
  
  // Make request
  let response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${session.access_token}`,
    },
  });
  
  // If 401, try refreshing token
  if (response.status === 401) {
    const { data: { session: newSession }, error } = 
      await supabase.auth.refreshSession();
    
    if (error || !newSession) {
      // Refresh failed, redirect to login
      await supabase.auth.signOut();
      window.location.href = '/login';
      throw new Error('Session expired');
    }
    
    // Retry request with new token
    response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${newSession.access_token}`,
      },
    });
  }
  
  return response;
}
```

---

## Best Practices

1. **Use short-lived access tokens**: 15 minutes to 1 hour
2. **Use long-lived refresh tokens**: Days to weeks (but not forever)
3. **Rotate refresh tokens**: Issue a new refresh token on every refresh
4. **Bind tokens to client**: Include IP, user agent in token payload (optional)
5. **Monitor for anomalies**: Log unusual session patterns (geo-location changes, etc.)
6. **Implement absolute session limits**: Even with refresh, sessions should eventually expire
7. **Regenerate session IDs on login**: Prevents session fixation
8. **Use HTTPS only**: Never send tokens over unencrypted connections
9. **Consider httpOnly cookies**: For maximum XSS protection (if complexity is justified)
10. **Implement logout everywhere**: Allow users to revoke all their sessions

---

## Common Pitfalls

1. **Infinite token lifetime**: Never-expiring tokens are a security risk
2. **No refresh token rotation**: Stolen refresh tokens can be used indefinitely
3. **Storing tokens in regular cookies**: Vulnerable to CSRF if not using httpOnly + SameSite
4. **Not handling token expiration**: App breaks when token expires
5. **Refreshing on every request**: Creates unnecessary load (refresh only when needed)
6. **Trusting client-side checks**: Always validate tokens on the server
7. **Logging tokens**: Never log full tokens (only first/last few characters)
8. **Not implementing logout**: Users should be able to revoke their sessions
9. **Weak token secrets**: Use strong, random secrets for JWT signing
10. **Not considering mobile apps**: Mobile requires different session strategies (no cookies)

---

## Further Reading

- **JWT Best Practices**: https://datatracker.ietf.org/doc/html/rfc8725
- **OAuth 2.0 Security**: https://datatracker.ietf.org/doc/html/rfc6819
- **OWASP Session Management**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth
- **Django Sessions**: https://docs.djangoproject.com/en/stable/topics/http/sessions/
- **Rails Sessions**: https://guides.rubyonrails.org/action_controller_overview.html#session
- **Next.js Auth**: https://next-auth.js.org/

---

**Next**: [05-rate-limiting-and-abuse-protection.md](./05-rate-limiting-and-abuse-protection.md) — Protecting your LLM-powered app from abuse
