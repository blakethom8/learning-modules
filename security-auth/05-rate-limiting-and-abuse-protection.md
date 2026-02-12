# Rate Limiting & Abuse Protection

## Table of Contents

1. [Introduction](#introduction)
2. [Why Rate Limiting Matters](#why-rate-limiting-matters)
   - [The LLM Cost Problem](#the-llm-cost-problem)
   - [API Abuse Scenarios](#api-abuse-scenarios)
   - [Business Impact](#business-impact)
3. [Rate Limiting Strategies](#rate-limiting-strategies)
   - [Fixed Window](#fixed-window)
   - [Sliding Window](#sliding-window)
   - [Token Bucket](#token-bucket)
   - [Leaky Bucket](#leaky-bucket)
   - [Comparison](#comparison)
4. [Identification Methods](#identification-methods)
   - [IP-Based Rate Limiting](#ip-based-rate-limiting)
   - [User-Based Rate Limiting](#user-based-rate-limiting)
   - [API Key-Based](#api-key-based)
   - [Hybrid Approaches](#hybrid-approaches)
5. [Provider Search Implementation](#provider-search-implementation)
   - [slowapi Integration](#slowapi-integration)
   - [Usage Tracking System](#usage-tracking-system)
   - [Plan-Based Limits](#plan-based-limits)
   - [Code Walkthrough](#code-walkthrough)
6. [Infrastructure Protection](#infrastructure-protection)
   - [Cloudflare](#cloudflare)
   - [WAF (Web Application Firewall)](#waf-web-application-firewall)
   - [fail2ban](#fail2ban)
   - [NGINX Rate Limiting](#nginx-rate-limiting)
7. [DDoS Protection Basics](#ddos-protection-basics)
   - [Types of DDoS Attacks](#types-of-ddos-attacks)
   - [Layer 3/4 vs Layer 7](#layer-34-vs-layer-7)
   - [Mitigation Strategies](#mitigation-strategies)
8. [LLM Cost Control](#llm-cost-control)
   - [Cost Analysis](#cost-analysis)
   - [Budget Enforcement](#budget-enforcement)
   - [User Education](#user-education)
   - [Caching Strategies](#caching-strategies)
9. [Monitoring & Alerts](#monitoring--alerts)
10. [Best Practices](#best-practices)
11. [Common Pitfalls](#common-pitfalls)
12. [Further Reading](#further-reading)

---

## Introduction

**Rate limiting** is the practice of restricting how many requests a client can make to your API within a given time period. It's one of the most important protections for modern web applications, especially those powered by expensive LLM APIs.

Think of rate limiting like a nightclub bouncer:
- **Fixed capacity**: Only 100 people allowed inside
- **Entry rate**: Maximum 10 people per minute can enter
- **VIP pass**: Premium members get higher limits
- **Troublemaker detection**: Ban abusive patrons

This guide covers rate limiting strategies, how Provider Search implements protection, and how to defend against abuse—especially critical when each API call costs money.

---

## Why Rate Limiting Matters

### The LLM Cost Problem

**LLMs are expensive**. A single OpenAI GPT-4 call can cost:
- Input: $0.01 per 1K tokens (~750 words)
- Output: $0.03 per 1K tokens

**Example abuse scenario**:
```
Attacker runs script:
  while True:
    POST /api/llm/analyze {"text": "a" * 10000}

Cost per request: ~$0.40 (10K input tokens + 2K output tokens)
Requests per minute: 1000

Total cost: $400/minute = $24,000/hour = $576,000/day
```

**Without rate limiting**, a single malicious user (or even a buggy script) can bankrupt your startup in hours.

### API Abuse Scenarios

**1. Credential Stuffing**
```bash
# Attacker tries stolen credentials
for email, password in stolen_credentials:
    POST /api/auth/login {"email": email, "password": password}

# Goal: Find valid accounts
# Rate limiting: Block after 5 failed attempts per IP
```

**2. Web Scraping**
```bash
# Competitor scrapes your provider database
for id in range(1, 100000):
    GET /api/providers/{id}

# Goal: Steal your data
# Rate limiting: 100 requests/minute per user
```

**3. Denial of Service**
```bash
# Attacker overwhelms your server
while True:
    POST /api/search {"query": "test"}

# Goal: Make your site unavailable
# Rate limiting: 10 requests/second per IP
```

**4. LLM Abuse**
```bash
# User generates excessive LLM content
for i in range(10000):
    POST /api/llm/generate {"prompt": "Write a long essay about..."}

# Goal: Use your LLM quota (malicious or accidental)
# Rate limiting: 50 LLM calls/day for free tier
```

### Business Impact

| Without Rate Limiting | With Rate Limiting |
|-----------------------|---------------------|
| ❌ Unpredictable costs | ✅ Controlled spending |
| ❌ Service outages | ✅ Stable performance |
| ❌ Data theft | ✅ Protected data |
| ❌ Poor user experience | ✅ Fair resource sharing |
| ❌ Security vulnerabilities | ✅ Brute-force protection |

**Real-world example**: GitHub Actions (free tier)
- Limit: 2,000 minutes/month
- Without limits: Users could mine crypto, costing GitHub millions
- With limits: Sustainable free tier for legitimate users

---

## Rate Limiting Strategies

### Fixed Window

**Count requests within fixed time windows**.

```
Window 1: 10:00:00 - 10:00:59  |  Window 2: 10:01:00 - 10:01:59
───────────────────────────────────────────────────────────────
Requests: 5                         Requests: 3
Status:   ✅ Under limit             Status:   ✅ Under limit
```

**Algorithm**:
```python
def fixed_window(user_id: str, limit: int = 100) -> bool:
    """
    Allow `limit` requests per minute (fixed 60-second window).
    """
    current_minute = int(time.time() / 60)
    key = f"rate_limit:{user_id}:{current_minute}"
    
    # Increment counter
    count = redis.incr(key)
    
    # Set expiration on first request
    if count == 1:
        redis.expire(key, 60)
    
    # Check if over limit
    return count <= limit
```

**Pros**:
- Simple to implement
- Memory efficient (one counter per window)
- Fast lookups

**Cons**:
- **Boundary problem**: User can make 2x limit by timing requests around window boundary

```
10:00:59 ─────────┬───────── 10:01:00
      [99 requests] [99 requests]
      └─────┬──────┘ └────┬─────┘
        Window 1       Window 2

Within 1 second: 198 requests (should be 100 max)
```

### Sliding Window

**Count requests within a rolling time window**.

```
10:00:00                  10:01:00
├─────────────────────────┤
│     100 requests        │
└─────────────────────────┘
          ↓ 1 second passes
     10:00:01                  10:01:01
     ├─────────────────────────┤
     │     100 requests        │
     └─────────────────────────┘
```

**Algorithm (simple approach)**:
```python
def sliding_window(user_id: str, limit: int = 100, window: int = 60) -> bool:
    """
    Allow `limit` requests per `window` seconds (sliding).
    """
    now = time.time()
    key = f"rate_limit:{user_id}"
    
    # Remove requests older than window
    redis.zremrangebyscore(key, 0, now - window)
    
    # Count requests in current window
    count = redis.zcard(key)
    
    if count >= limit:
        return False
    
    # Add current request
    redis.zadd(key, {str(uuid.uuid4()): now})
    redis.expire(key, window)
    
    return True
```

**Pros**:
- No boundary problem
- Accurate limit enforcement
- Fair distribution

**Cons**:
- More memory (stores timestamp for each request)
- Slightly slower (needs to clean old entries)

**Hybrid approach** (approximate sliding window):
```python
def sliding_window_approximate(user_id: str, limit: int = 100) -> bool:
    """
    Approximate sliding window using two fixed windows.
    Much more memory-efficient than true sliding window.
    """
    now = time.time()
    current_minute = int(now / 60)
    previous_minute = current_minute - 1
    
    # Weight of previous window (how much of it overlaps with current window)
    elapsed = now % 60
    weight = 1 - (elapsed / 60)
    
    # Count from both windows
    current_count = redis.get(f"rate_limit:{user_id}:{current_minute}") or 0
    previous_count = redis.get(f"rate_limit:{user_id}:{previous_minute}") or 0
    
    # Weighted total
    total = current_count + (previous_count * weight)
    
    if total >= limit:
        return False
    
    # Increment current window
    redis.incr(f"rate_limit:{user_id}:{current_minute}")
    redis.expire(f"rate_limit:{user_id}:{current_minute}", 120)
    
    return True
```

This is what Cloudflare uses—90% as accurate as true sliding window, but much more efficient.

### Token Bucket

**Tokens regenerate at a fixed rate; requests consume tokens**.

```
Bucket capacity: 100 tokens
Refill rate: 10 tokens/second

  [██████████] 100/100 tokens
       ↓ User makes 50 requests (50 tokens consumed)
  [█████     ] 50/100 tokens
       ↓ 5 seconds pass (50 tokens refilled)
  [██████████] 100/100 tokens (capped at capacity)
```

**Algorithm**:
```python
def token_bucket(user_id: str, capacity: int = 100, refill_rate: float = 10) -> bool:
    """
    Token bucket algorithm.
    
    Args:
        capacity: Maximum tokens in bucket
        refill_rate: Tokens added per second
    """
    now = time.time()
    key = f"token_bucket:{user_id}"
    
    # Get bucket state
    bucket = redis.hgetall(key)
    tokens = float(bucket.get('tokens', capacity))
    last_refill = float(bucket.get('last_refill', now))
    
    # Refill tokens based on elapsed time
    elapsed = now - last_refill
    tokens = min(capacity, tokens + (elapsed * refill_rate))
    
    # Check if we have a token
    if tokens < 1:
        # Save state
        redis.hset(key, 'tokens', tokens)
        redis.hset(key, 'last_refill', now)
        redis.expire(key, 3600)
        return False
    
    # Consume token
    tokens -= 1
    
    # Save state
    redis.hset(key, 'tokens', tokens)
    redis.hset(key, 'last_refill', now)
    redis.expire(key, 3600)
    
    return True
```

**Pros**:
- Handles bursts well (user can "save up" tokens)
- Smooth rate limiting (no hard window boundaries)
- Flexible (can adjust capacity and refill rate independently)

**Cons**:
- More complex state management
- Requires floating-point math
- Needs periodic updates (even when idle)

**Best for**: APIs that benefit from allowing bursts (image processing, LLM calls)

### Leaky Bucket

**Requests queued and processed at a fixed rate**.

```
Requests arrive →  [Queue: 10 requests] → Processed at 1/second
                         ↓
                   [█████░░░░░] 5/10 capacity
                         ↓
                   Process 1 request/second
```

**Algorithm**:
```python
def leaky_bucket(user_id: str, rate: int = 10, capacity: int = 100) -> bool:
    """
    Leaky bucket algorithm.
    
    Args:
        rate: Requests processed per second
        capacity: Maximum queue size
    """
    now = time.time()
    key = f"leaky_bucket:{user_id}"
    
    # Get queue
    queue_size = redis.llen(key)
    
    # Remove processed requests (leak)
    last_leak = float(redis.get(f"{key}:last_leak") or now)
    elapsed = now - last_leak
    to_leak = int(elapsed * rate)
    
    if to_leak > 0:
        # Remove processed requests
        for _ in range(min(to_leak, queue_size)):
            redis.lpop(key)
        redis.set(f"{key}:last_leak", now)
    
    # Check capacity
    queue_size = redis.llen(key)
    if queue_size >= capacity:
        return False
    
    # Add to queue
    redis.rpush(key, now)
    redis.expire(key, 3600)
    
    return True
```

**Pros**:
- Smooths traffic spikes
- Predictable output rate
- Fair queuing (FIFO)

**Cons**:
- Adds latency (requests are queued)
- Complex to implement correctly
- Doesn't work well for synchronous APIs

**Best for**: Background job processing, message queues

### Comparison

| Algorithm | Complexity | Memory | Burst Support | Boundary Issues | Best For |
|-----------|------------|--------|---------------|-----------------|----------|
| **Fixed Window** | Low | Low | Poor | Yes | Simple APIs, MVP |
| **Sliding Window** | Medium | High | Good | No | Fair distribution |
| **Approx. Sliding** | Medium | Low | Good | Minimal | Production (best trade-off) |
| **Token Bucket** | High | Medium | Excellent | No | Bursty workloads, LLMs |
| **Leaky Bucket** | High | Medium | None (smooth) | No | Background processing |

**Provider Search uses**: Fixed window (via slowapi) + token bucket (for LLM calls)

---

## Identification Methods

How do you identify which user/client to rate limit?

### IP-Based Rate Limiting

**Limit requests per IP address**.

```python
from fastapi import Request

def get_client_ip(request: Request) -> str:
    """
    Get client IP, considering proxies.
    """
    # Check for forwarded IP (if behind proxy/CDN)
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        # X-Forwarded-For: client, proxy1, proxy2
        return forwarded.split(",")[0].strip()
    
    return request.client.host
```

**Pros**:
- Works for anonymous users
- Simple to implement
- Protects against distributed attacks

**Cons**:
- Shared IPs (corporate networks, VPNs) get rate limited together
- IPv6 rotation can bypass limits
- NAT/CGNAT users share limits

**When to use**:
- Login endpoints (prevent credential stuffing)
- Public APIs (no authentication required)
- DDoS protection

### User-Based Rate Limiting

**Limit requests per authenticated user**.

```python
from fastapi import Depends
from app.auth import get_current_user

@app.get("/api/search")
async def search(user: dict = Depends(get_current_user)):
    user_id = user["sub"]
    
    # Rate limit based on user ID
    if not check_rate_limit(user_id):
        raise HTTPException(429, "Rate limit exceeded")
    
    return {"results": [...]}
```

**Pros**:
- Fair (each user gets their own limit)
- Accurate (can't be bypassed by IP rotation)
- Enables tiered plans (free/pro/enterprise)

**Cons**:
- Requires authentication
- Doesn't protect login endpoint
- Can't protect against account creation abuse

**When to use**:
- Authenticated APIs
- SaaS applications
- Per-user quotas

### API Key-Based

**Limit requests per API key**.

```python
@app.get("/api/data")
async def get_data(api_key: str = Header(...)):
    # Validate API key
    key_info = validate_api_key(api_key)
    
    # Rate limit based on key
    if not check_rate_limit(f"key:{api_key}"):
        raise HTTPException(429, "Rate limit exceeded")
    
    return {"data": [...]}
```

**Pros**:
- Easy to track usage per customer
- Can revoke keys independently
- Common for B2B APIs

**Cons**:
- Keys can be stolen/shared
- Requires key management
- Need separate limits for testing vs production keys

**When to use**:
- Public APIs for developers
- B2B integrations
- Third-party access

### Hybrid Approaches

**Combine multiple methods for layered protection**:

```python
@app.post("/api/llm/generate")
async def generate(
    request: Request,
    user: dict = Depends(get_current_user)
):
    client_ip = get_client_ip(request)
    user_id = user["sub"]
    user_tier = user.get("tier", "free")
    
    # Layer 1: Global IP limit (prevent DDoS)
    if not check_rate_limit(f"ip:{client_ip}", limit=100, window=60):
        raise HTTPException(429, "Too many requests from your IP")
    
    # Layer 2: User limit based on tier
    tier_limits = {
        "free": 10,
        "pro": 100,
        "enterprise": 1000,
    }
    
    if not check_rate_limit(
        f"user:{user_id}",
        limit=tier_limits[user_tier],
        window=86400  # daily limit
    ):
        raise HTTPException(
            429,
            f"Daily limit exceeded. Upgrade to Pro for higher limits."
        )
    
    # Layer 3: Cost-based limit (token bucket for LLM budget)
    estimated_cost = estimate_llm_cost(request.json())
    if not consume_tokens(user_id, estimated_cost):
        raise HTTPException(
            429,
            "LLM budget exceeded. Resets tomorrow."
        )
    
    # All checks passed
    return await call_llm(request.json())
```

**Layers**:
1. **IP-based**: Broad protection (100 req/min)
2. **User-based**: Fair quotas (10-1000 req/day depending on tier)
3. **Cost-based**: Budget protection ($10/day LLM spending cap)

---

## Provider Search Implementation

### slowapi Integration

**slowapi** is a FastAPI rate limiter based on Flask-Limiter.

```python
# api/app/middleware/rate_limit.py
from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Request

# Create limiter instance
limiter = Limiter(
    key_func=get_remote_address,  # Use IP address by default
    default_limits=["100/minute"],  # Global default
    storage_uri="redis://localhost:6379",  # Or "memory://" for testing
)

# Usage in routes
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/api/public")
@limiter.limit("10/minute")  # Override default for this endpoint
async def public_endpoint(request: Request):
    return {"message": "Hello world"}
```

**Custom key functions**:

```python
# Rate limit by user ID instead of IP
def get_user_id(request: Request) -> str:
    """
    Extract user ID from JWT token.
    """
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return get_remote_address(request)  # Fall back to IP
    
    token = auth_header.replace("Bearer ", "")
    
    try:
        payload = jwt.decode(token, settings.SUPABASE_JWT_SECRET, algorithms=["HS256"])
        return payload["sub"]
    except:
        return get_remote_address(request)

# Use custom key function
limiter = Limiter(
    key_func=get_user_id,
    default_limits=["1000/hour"],
)
```

**Dynamic limits based on user tier**:

```python
def get_user_limit(request: Request) -> str:
    """
    Return rate limit string based on user tier.
    """
    user = get_current_user_sync(request)  # Synchronous helper
    
    if not user:
        return "10/minute"  # Anonymous
    
    tier = user.get("tier", "free")
    limits = {
        "free": "50/hour",
        "pro": "500/hour",
        "enterprise": "5000/hour",
    }
    
    return limits.get(tier, "50/hour")

@app.get("/api/search")
@limiter.limit(get_user_limit)
async def search(request: Request):
    return {"results": [...]}
```

### Usage Tracking System

**Provider Search tracks LLM usage** to enforce plan-based limits:

```python
# api/app/core/usage.py
from sqlalchemy import Column, Integer, String, Float, DateTime
from datetime import datetime, timedelta
from app.database import Base

class Usage(Base):
    __tablename__ = "usage"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    resource = Column(String, nullable=False)  # "llm", "api", "storage"
    amount = Column(Float, nullable=False)     # tokens, requests, bytes
    cost = Column(Float, default=0.0)          # USD
    created_at = Column(DateTime, default=datetime.utcnow)

def track_usage(user_id: str, resource: str, amount: float, cost: float = 0.0):
    """
    Track resource usage.
    """
    usage = Usage(
        user_id=user_id,
        resource=resource,
        amount=amount,
        cost=cost,
    )
    
    db.add(usage)
    db.commit()

def get_usage_today(user_id: str, resource: str) -> dict:
    """
    Get usage for today.
    """
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    usage = db.query(Usage).filter(
        Usage.user_id == user_id,
        Usage.resource == resource,
        Usage.created_at >= today,
    ).all()
    
    return {
        "count": len(usage),
        "total_amount": sum(u.amount for u in usage),
        "total_cost": sum(u.cost for u in usage),
    }

def check_usage_limit(user_id: str, resource: str, plan: str) -> bool:
    """
    Check if user is within their plan limits.
    """
    limits = {
        "free": {"llm": 10, "api": 100},
        "pro": {"llm": 1000, "api": 10000},
        "enterprise": {"llm": -1, "api": -1},  # Unlimited
    }
    
    limit = limits[plan].get(resource, 0)
    
    if limit == -1:
        return True  # Unlimited
    
    usage = get_usage_today(user_id, resource)
    return usage["count"] < limit
```

**Usage in LLM endpoint**:

```python
@app.post("/api/llm/analyze")
async def analyze_with_llm(
    request: Request,
    data: dict,
    user: dict = Depends(get_current_user)
):
    user_id = user["sub"]
    user_plan = user.get("plan", "free")
    
    # Check usage limit
    if not check_usage_limit(user_id, "llm", user_plan):
        raise HTTPException(
            429,
            detail=f"Daily LLM limit reached. Current plan: {user_plan}. Upgrade for more."
        )
    
    # Estimate cost before calling
    estimated_tokens = estimate_tokens(data["prompt"])
    estimated_cost = estimated_tokens * 0.00001  # $0.01 per 1K tokens
    
    # Make LLM call
    response = await call_openai(data["prompt"])
    
    # Track actual usage
    track_usage(
        user_id=user_id,
        resource="llm",
        amount=response["usage"]["total_tokens"],
        cost=estimated_cost,
    )
    
    return {"result": response["choices"][0]["message"]["content"]}
```

### Plan-Based Limits

```python
# api/app/models/user.py
from enum import Enum

class Plan(str, Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"

class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True)
    email = Column(String, unique=True)
    plan = Column(Enum(Plan), default=Plan.FREE)
    plan_limits = Column(JSON, default=lambda: {
        "llm_calls_per_day": 10,
        "api_calls_per_hour": 100,
        "storage_mb": 100,
    })

# Middleware to enforce limits
@app.middleware("http")
async def enforce_plan_limits(request: Request, call_next):
    # Skip for public endpoints
    if request.url.path in ["/", "/health", "/login"]:
        return await call_next(request)
    
    # Get user
    user = await get_current_user_from_request(request)
    
    if not user:
        return await call_next(request)
    
    # Check if endpoint requires limit check
    if "/api/llm/" in request.url.path:
        if not check_usage_limit(user.id, "llm", user.plan):
            return JSONResponse(
                status_code=429,
                content={
                    "error": "Plan limit exceeded",
                    "plan": user.plan,
                    "upgrade_url": "/pricing",
                }
            )
    
    return await call_next(request)
```

### Code Walkthrough

**Full implementation**:

```python
# api/app/main.py
from fastapi import FastAPI, Request, HTTPException, Depends
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import redis

# Initialize FastAPI app
app = FastAPI()

# Initialize Redis
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Initialize rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100/minute"],
    storage_uri="redis://localhost:6379",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Helper: Get user from token
def get_user_id_for_rate_limit(request: Request) -> str:
    """
    Get user ID from JWT, fall back to IP if not authenticated.
    """
    auth = request.headers.get("Authorization")
    
    if auth and auth.startswith("Bearer "):
        try:
            token = auth.split(" ")[1]
            payload = jwt.decode(token, settings.SUPABASE_JWT_SECRET, algorithms=["HS256"])
            return f"user:{payload['sub']}"
        except:
            pass
    
    return f"ip:{get_remote_address(request)}"

# Public endpoint: Strict IP-based limit
@app.post("/api/auth/login")
@limiter.limit("5/minute")  # Prevent brute force
async def login(request: Request, credentials: dict):
    email = credentials["email"]
    password = credentials["password"]
    
    # Attempt authentication
    user = authenticate(email, password)
    
    if not user:
        raise HTTPException(401, "Invalid credentials")
    
    return {"token": create_token(user)}

# Authenticated endpoint: User-based limit
@app.get("/api/search")
@limiter.limit("100/hour", key_func=get_user_id_for_rate_limit)
async def search(request: Request, q: str, user: dict = Depends(get_current_user)):
    return {"query": q, "results": [...]}

# Expensive endpoint: Multi-tier protection
@app.post("/api/llm/generate")
async def llm_generate(
    request: Request,
    data: dict,
    user: dict = Depends(get_current_user)
):
    user_id = user["sub"]
    user_plan = user.get("plan", "free")
    
    # Layer 1: IP-based (prevent single-IP spam)
    ip = get_remote_address(request)
    ip_key = f"rate_limit:ip:{ip}"
    ip_count = redis_client.incr(ip_key)
    if ip_count == 1:
        redis_client.expire(ip_key, 60)
    if ip_count > 50:
        raise HTTPException(429, "Too many requests from your IP")
    
    # Layer 2: User daily limit
    daily_key = f"usage:llm:{user_id}:{datetime.utcnow().date()}"
    daily_count = int(redis_client.get(daily_key) or 0)
    
    plan_limits = {"free": 10, "pro": 100, "enterprise": 1000}
    limit = plan_limits.get(user_plan, 10)
    
    if daily_count >= limit:
        raise HTTPException(
            429,
            detail=f"Daily limit reached ({limit} LLM calls). Plan: {user_plan}"
        )
    
    # Make LLM call
    result = await call_llm(data["prompt"])
    
    # Track usage
    redis_client.incr(daily_key)
    redis_client.expire(daily_key, 86400)
    
    track_usage(user_id, "llm", result["usage"]["total_tokens"])
    
    return {"result": result["choices"][0]["message"]["content"]}
```

---

## Infrastructure Protection

### Cloudflare

**Cloudflare provides DDoS protection and rate limiting** at the edge (before traffic hits your server).

**Features**:
- **DDoS protection**: Absorbs attacks up to 172 Tbps
- **Rate limiting**: Configurable rules (e.g., 100 req/10s per IP)
- **Bot detection**: Challenges suspicious traffic
- **Caching**: Reduces backend load
- **WAF**: Web Application Firewall rules

**Setting up Cloudflare**:

1. Add your domain to Cloudflare
2. Update DNS to point to Cloudflare nameservers
3. Configure rate limiting rules:

```
Rule: Protect API
  If: hostname equals api.providersearch.com
  And: URI path starts with /api/
  Then: Rate limit
    - 100 requests per 10 seconds
    - Per IP address
    - Block for 1 hour on violation
```

**Cloudflare Workers** (programmable edge):

```javascript
// Cloudflare Worker: Block suspicious requests
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const ip = request.headers.get('CF-Connecting-IP')
  const country = request.headers.get('CF-IPCountry')
  
  // Block traffic from certain countries (e.g., high-abuse regions)
  if (country === 'XX') {
    return new Response('Forbidden', { status: 403 })
  }
  
  // Rate limit expensive endpoints
  if (request.url.includes('/api/llm/')) {
    const rateLimitKey = `rate:${ip}`
    const count = await KV.get(rateLimitKey)
    
    if (count && parseInt(count) > 10) {
      return new Response('Rate limit exceeded', { status: 429 })
    }
    
    await KV.put(rateLimitKey, (parseInt(count) || 0) + 1, { expirationTtl: 60 })
  }
  
  // Pass through to origin
  return fetch(request)
}
```

### WAF (Web Application Firewall)

**Rules to block common attacks**:

```yaml
# AWS WAF example
Rules:
  - Name: BlockSQLInjection
    Condition: Request body matches SQL patterns
    Action: Block
  
  - Name: BlockXSS
    Condition: Query string contains <script>
    Action: Block
  
  - Name: RateLimitAPI
    Condition: Path starts with /api/
    Action: Rate limit (1000 req/5min per IP)
  
  - Name: GeoBlock
    Condition: Source country not in [US, CA, UK]
    Action: Block (if your users are regional)
```

**Cloudflare WAF managed rules**:

```
Cloudflare Managed Ruleset
  ✅ OWASP Core Rule Set
  ✅ Cloudflare Specials
  ✅ Cloudflare SQLi and XSS

Custom Rules:
  - Block requests with User-Agent containing "curl" (API abuse)
  - Block requests with >1000 query string parameters
  - Block POST requests without Content-Type header
```

### fail2ban

**Automatically ban IPs after repeated failed attempts** (login, 404s, etc.).

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
action = iptables-multiport[name=ReqLimit, port="http,https"]

[api-abuse]
enabled = true
filter = api-abuse
logpath = /var/log/api/access.log
maxretry = 100
findtime = 60
bantime = 24h
```

**Custom filter for API abuse**:

```ini
# /etc/fail2ban/filter.d/api-abuse.conf
[Definition]
failregex = ^<HOST> .* "POST /api/llm/generate .*" 429
            ^<HOST> .* "POST /api/auth/login .*" 401
ignoreregex =
```

**How it works**:
1. fail2ban monitors log files
2. Counts failed attempts per IP
3. After threshold, adds iptables rule to block IP
4. Auto-unbans after `bantime`

### NGINX Rate Limiting

**NGINX has built-in rate limiting**:

```nginx
# /etc/nginx/nginx.conf

# Define rate limit zones
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

server {
    listen 80;
    server_name api.providersearch.com;
    
    # Apply rate limit to /api/ endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://backend;
    }
    
    # Strict rate limit for login
    location /api/auth/login {
        limit_req zone=login burst=5;
        proxy_pass http://backend;
    }
}
```

**Parameters**:
- `rate=10r/s`: 10 requests per second
- `burst=20`: Allow bursts up to 20 requests
- `nodelay`: Process burst immediately (don't queue)

**Response when rate limited**:
```
HTTP/1.1 503 Service Temporarily Unavailable
```

---

## DDoS Protection Basics

### Types of DDoS Attacks

**1. Volumetric Attacks** (flood network)
- **UDP flood**: Send massive UDP packets
- **ICMP flood**: Ping flood
- **DNS amplification**: Abuse open DNS resolvers

**Goal**: Saturate bandwidth

**2. Protocol Attacks** (exhaust server resources)
- **SYN flood**: Send TCP SYN without completing handshake
- **Ping of Death**: Send malformed packets
- **Smurf attack**: ICMP echo with spoofed source IP

**Goal**: Exhaust connection table, CPU, memory

**3. Application Layer Attacks** (target application logic)
- **HTTP flood**: Legitimate-looking requests overwhelming server
- **Slowloris**: Open many connections, send data slowly
- **API abuse**: Expensive operations (LLM calls)

**Goal**: Make application unavailable

### Layer 3/4 vs Layer 7

| Layer | Type | Examples | Volume | Detection |
|-------|------|----------|--------|-----------|
| **3/4** | Network/Transport | UDP flood, SYN flood | Very high (Tbps) | Easy (unusual patterns) |
| **7** | Application | HTTP flood, API abuse | Lower (Gbps) | Hard (looks legitimate) |

**Layer 3/4 attacks**: Cloudflare/AWS Shield handle automatically

**Layer 7 attacks**: Require application-level protection (rate limiting, CAPTCHAs)

### Mitigation Strategies

**1. Use a CDN** (Cloudflare, AWS CloudFront)
- Absorbs traffic before it reaches your origin
- Global distribution
- Built-in DDoS protection

**2. Rate limiting** (discussed above)
- Limit requests per IP
- Challenge suspicious IPs (CAPTCHA)

**3. Autoscaling**
- Automatically add servers during attack
- Requires cloud infrastructure (AWS, GCP)

**4. Blackhole routing**
- Null-route attacking IPs at network level
- Fast but blunt (might block legitimate users)

**5. CAPTCHA challenges**
- For suspicious IPs
- Cloudflare Turnstile, hCaptcha, reCAPTCHA

**Example**: Cloudflare Under Attack Mode
```
If: Request rate > 1000/minute from single IP
Then: Challenge with CAPTCHA
If pass: Allow for 24 hours
If fail: Block
```

---

## LLM Cost Control

### Cost Analysis

**OpenAI GPT-4 Pricing** (as of 2024):
- Input: $0.01 per 1K tokens
- Output: $0.03 per 1K tokens

**Example scenario** (Provider Search):
```
Average query:
  User prompt: 200 tokens
  System prompt: 500 tokens
  Response: 300 tokens
  
Cost per query: 
  (200 + 500) * $0.01 / 1000 = $0.007 input
  300 * $0.03 / 1000 = $0.009 output
  Total: $0.016 per query

Users per day: 1000
Queries per user: 10
Total cost: 1000 * 10 * $0.016 = $160/day = $4,800/month
```

**Without limits**:
- Single abusive user: 10,000 queries = $160
- 10 abusive users: $1,600/day = $48,000/month

### Budget Enforcement

**1. Per-user daily limits**:

```python
def check_llm_budget(user_id: str, plan: str) -> bool:
    """
    Check if user has budget remaining today.
    """
    budgets = {
        "free": 10,      # 10 calls/day = $0.16/day
        "pro": 500,      # 500 calls/day = $8/day
        "enterprise": 10000,  # 10K calls/day = $160/day
    }
    
    today = datetime.utcnow().date()
    usage_key = f"llm_usage:{user_id}:{today}"
    
    usage = int(redis.get(usage_key) or 0)
    limit = budgets.get(plan, 10)
    
    return usage < limit
```

**2. Organization-wide budget caps**:

```python
def check_org_budget(org_id: str) -> bool:
    """
    Check if organization has budget remaining this month.
    """
    # Get org budget from database
    org = db.query(Organization).filter_by(id=org_id).first()
    monthly_budget = org.llm_budget_usd  # e.g., $1000
    
    # Get current month's spending
    month_start = datetime.utcnow().replace(day=1, hour=0, minute=0, second=0)
    spending = db.query(func.sum(Usage.cost)).filter(
        Usage.org_id == org_id,
        Usage.created_at >= month_start,
    ).scalar() or 0
    
    return spending < monthly_budget
```

**3. Pre-flight cost estimation**:

```python
def estimate_cost(prompt: str, max_tokens: int = 500) -> float:
    """
    Estimate cost before making LLM call.
    """
    input_tokens = len(prompt.split()) * 1.3  # Rough estimate
    output_tokens = max_tokens
    
    input_cost = input_tokens * 0.00001  # $0.01/1K
    output_cost = output_tokens * 0.00003  # $0.03/1K
    
    return input_cost + output_cost

@app.post("/api/llm/generate")
async def generate(data: dict, user: dict = Depends(get_current_user)):
    estimated_cost = estimate_cost(data["prompt"])
    
    # Warn if expensive
    if estimated_cost > 0.10:
        return {
            "warning": f"This request will cost ~${estimated_cost:.2f}. Confirm?",
            "estimated_cost": estimated_cost,
        }
    
    # Continue with LLM call...
```

### User Education

**Show usage dashboard**:

```typescript
// web/src/pages/Usage.tsx
function UsageDashboard() {
  const { usage } = useUsage();
  
  return (
    <div>
      <h2>Your Usage</h2>
      <div>
        <strong>LLM Calls Today:</strong> {usage.llm_calls} / {usage.plan_limit}
        <ProgressBar value={usage.llm_calls} max={usage.plan_limit} />
      </div>
      
      <div>
        <strong>Estimated Cost Today:</strong> ${usage.estimated_cost.toFixed(2)}
      </div>
      
      {usage.llm_calls >= usage.plan_limit * 0.8 && (
        <Alert>
          You've used 80% of your daily limit. Consider upgrading to Pro.
        </Alert>
      )}
    </div>
  );
}
```

**Email alerts**:

```python
def send_usage_alert(user_id: str, usage: int, limit: int):
    """
    Send email when user reaches 80% of limit.
    """
    if usage >= limit * 0.8:
        send_email(
            to=user.email,
            subject="LLM Usage Alert",
            body=f"""
            You've used {usage}/{limit} LLM calls today ({usage/limit*100:.0f}%).
            
            Upgrade to Pro for higher limits: {PRICING_URL}
            """
        )
```

### Caching Strategies

**Cache common queries** to reduce LLM calls:

```python
def llm_generate_cached(prompt: str, user_id: str) -> str:
    """
    Check cache before calling LLM.
    """
    # Generate cache key from prompt
    cache_key = f"llm_cache:{hashlib.md5(prompt.encode()).hexdigest()}"
    
    # Check cache
    cached = redis.get(cache_key)
    if cached:
        logger.info(f"Cache hit for user {user_id}")
        return cached
    
    # Cache miss, call LLM
    response = call_llm(prompt)
    
    # Cache for 24 hours
    redis.setex(cache_key, 86400, response)
    
    # Track usage
    track_usage(user_id, "llm", 1)
    
    return response
```

**Smart caching**:
- Cache identical prompts globally
- Cache similar prompts per user
- Use semantic similarity (embeddings) to find cached responses

```python
def find_similar_cached_response(prompt: str) -> Optional[str]:
    """
    Find cached response for similar prompts using embeddings.
    """
    # Get embedding for current prompt
    embedding = get_embedding(prompt)
    
    # Search vector database for similar prompts
    similar = vector_db.search(embedding, top_k=1, threshold=0.95)
    
    if similar:
        logger.info(f"Found similar cached response (similarity: {similar[0].score})")
        return similar[0].response
    
    return None
```

---

## Monitoring & Alerts

**Key metrics to track**:

```python
# Prometheus metrics
from prometheus_client import Counter, Histogram, Gauge

# Request counts
requests_total = Counter(
    'api_requests_total',
    'Total API requests',
    ['endpoint', 'status', 'user_tier']
)

# Rate limit hits
rate_limit_hits = Counter(
    'rate_limit_hits_total',
    'Total rate limit violations',
    ['endpoint', 'limit_type']
)

# LLM usage
llm_calls = Counter(
    'llm_calls_total',
    'Total LLM API calls',
    ['model', 'user_tier']
)

llm_cost = Counter(
    'llm_cost_usd_total',
    'Total LLM cost in USD',
    ['model']
)

# Request latency
request_duration = Histogram(
    'api_request_duration_seconds',
    'API request duration',
    ['endpoint']
)
```

**Grafana dashboard**:

```yaml
Dashboard: API Health
  Panels:
    - Requests/sec by endpoint (last 1h)
    - Rate limit violations (last 24h)
    - LLM calls by tier (last 24h)
    - LLM cost (today, this week, this month)
    - Top users by request count
    - Top IPs hitting rate limits
    
  Alerts:
    - Rate limit hits > 100/min → Slack alert
    - LLM cost > $50/hour → Email + Slack
    - Single user > 10K requests/hour → Security alert
```

**Real-time alerts**:

```python
# Check for abuse patterns
def check_abuse_patterns():
    """
    Run hourly to detect abuse.
    """
    # Check for users hitting rate limits repeatedly
    abuse_users = redis.keys("rate_limit:user:*")
    
    for key in abuse_users:
        count = int(redis.get(key) or 0)
        
        if count > 100:  # Hit rate limit 100+ times in an hour
            user_id = key.split(":")[2]
            alert_security_team(
                f"User {user_id} hit rate limit {count} times in the last hour"
            )
```

---

## Best Practices

1. **Layer your defenses**: IP + user + cost-based limits
2. **Start strict, loosen gradually**: Easier to raise limits than lower them
3. **Provide clear error messages**: Tell users when they'll be unblocked
4. **Offer upgrade paths**: Turn rate limiting into revenue (freemium → paid)
5. **Monitor and adjust**: Review metrics weekly, adjust limits based on actual usage
6. **Whitelist trusted users**: VIP/enterprise customers get higher limits
7. **Use exponential backoff**: Increase penalties for repeated violations
8. **Cache aggressively**: Reduce backend load and costs
9. **Educate users**: Show usage dashboards, send proactive alerts
10. **Test your limits**: Simulate attacks to ensure protections work

---

## Common Pitfalls

1. **Rate limiting authenticated endpoints only**: Public endpoints need protection too
2. **Using only IP-based limits**: Easy to bypass with VPN/proxy rotation
3. **No retry-after header**: Clients don't know when to retry
4. **Blocking permanently**: Always provide a path to unblock (time-based or CAPTCHA)
5. **Not accounting for legitimate bursts**: Allow some burst capacity
6. **Same limits for all endpoints**: Expensive endpoints need stricter limits
7. **Ignoring costs**: Rate limiting requests but not cost (LLM tokens, compute time)
8. **No monitoring**: Can't optimize limits without data
9. **Overly aggressive limits**: Frustrates legitimate users
10. **Not testing under load**: Limits that work in dev might not work in production

---

## Further Reading

- **Rate Limiting Strategies**: https://cloud.google.com/architecture/rate-limiting-strategies-techniques
- **Redis Rate Limiting**: https://redis.io/docs/manual/patterns/rate-limiter/
- **OWASP API Security**: https://owasp.org/www-project-api-security/
- **Cloudflare Rate Limiting**: https://developers.cloudflare.com/waf/rate-limiting-rules/
- **AWS Shield (DDoS)**: https://aws.amazon.com/shield/
- **slowapi Documentation**: https://github.com/laurents/slowapi

---

**Next**: [06-production-security-checklist.md](./06-production-security-checklist.md) — Your pre-deployment security audit
