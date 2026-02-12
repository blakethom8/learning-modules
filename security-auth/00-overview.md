# Web Security, Authentication & Session Management

## Introduction

This learning module provides a comprehensive, first-principles understanding of web security, authentication patterns, and session management for the Provider Search application. Rather than just showing you what to do, we'll explore **why** different approaches exist, **when** to use them, and the **real-world tradeoffs** involved.

By the end, you'll understand:
- Core web security vulnerabilities and how to prevent them
- Different authentication approaches and when to use each
- Token storage strategies and their security implications
- Session management patterns across different frameworks
- Rate limiting and abuse protection (especially important for LLM-powered features)
- Production security best practices

## Why This Matters for Provider Search

Provider Search is a FastAPI + React + Supabase application that:
- Uses JWT tokens for authentication (issued by Supabase Auth)
- Stores tokens in localStorage (making specific security tradeoffs)
- Powers LLM-based features (requiring careful rate limiting and cost control)
- Will eventually handle sensitive healthcare provider data
- Needs to scale to production with real users

Understanding security isn't just about following best practices—it's about making informed decisions about **what level of security you need** and **what complexity you're willing to accept**.

## Module Structure

### Part 1: Security Fundamentals
**[01-web-security-fundamentals.md](./01-web-security-fundamentals.md)**

The core vulnerabilities every web developer must understand:
- **XSS (Cross-Site Scripting)** — How attackers inject malicious JavaScript
- **CSRF (Cross-Site Request Forgery)** — Exploiting trusted sessions
- **CORS** — What it protects and common misconfigurations
- **HTTPS/TLS** — What it does (and doesn't) protect
- **Supply Chain Attacks** — npm dependencies as attack vectors
- **OWASP Top 10** — The most critical web security risks

### Part 2: Authentication Approaches
**[02-authentication-approaches.md](./02-authentication-approaches.md)**

A comparative analysis of different authentication strategies:
- **Session-based auth** — Traditional server-side sessions with cookies
- **Token-based auth (JWT)** — How it works, pros/cons
- **OAuth 2.0 / OpenID Connect** — Delegated authentication
- **API keys** — When they're appropriate
- **Supabase Auth** — What it provides and how it compares
- **Framework comparison** — How Django, Rails, Next.js, Laravel handle auth
- **Decision matrix** — Choosing the right approach

### Part 3: Token Storage Deep Dive
**[03-token-storage-deep-dive.md](./03-token-storage-deep-dive.md)**

The most debated topic in modern web security:
- **localStorage vs sessionStorage vs httpOnly cookies vs memory**
- **Provider Search's approach** — localStorage + Supabase JWT (and why)
- **httpOnly cookies** — Implementation walkthrough
- **CSRF protection** — What's needed when using cookies
- **The real-world tradeoff** — Security vs complexity vs UX
- **Code examples** — Both approaches using our actual codebase
- **Decision matrix** — When each approach makes sense

### Part 4: Session Management
**[04-session-management.md](./04-session-management.md)**

How sessions work across different architectures:
- **Token lifecycle** — Issuance, validation, refresh, expiration
- **Sliding vs fixed expiration** — When sessions should end
- **Refresh tokens** — What they are and when to use them
- **Session attacks** — Fixation and hijacking
- **Our approach** — How Supabase handles refresh and validation
- **Framework comparison** — Django sessions, Rails sessions, Next.js middleware

### Part 5: Rate Limiting & Abuse Protection
**[05-rate-limiting-and-abuse-protection.md](./05-rate-limiting-and-abuse-protection.md)**

Critical for LLM-powered applications:
- **Why rate limiting matters** — Especially with LLM costs
- **Strategies** — IP-based, user-based, token-bucket
- **Our implementation** — slowapi + usage tracking + plan limits
- **Infrastructure protection** — Cloudflare, WAF, fail2ban
- **DDoS protection basics**
- **Cost control** — Protecting against LLM abuse

### Part 6: Production Security Checklist
**[06-production-security-checklist.md](./06-production-security-checklist.md)**

Your pre-deployment security audit:
- **Deployment checklist** — What to verify before going live
- **Security headers** — CSP, HSTS, X-Frame-Options, etc.
- **Secrets management** — Environment variables, vault services
- **Logging and monitoring** — What to track for security events
- **Incident response** — Basic procedures when something goes wrong

## Hands-On Components

### Interactive Jupyter Notebook
**[notebooks/auth-deep-dive.ipynb](./notebooks/auth-deep-dive.ipynb)**

Run the code yourself:
- Decode and inspect JWT tokens
- Test password hashing (PBKDF2, bcrypt)
- Validate tokens (HS256 and ES256/JWKS)
- See XSS attacks in action
- Demonstrate CORS behavior
- Explore our usage tracking system

### Browser Tools
**[browser-tools/security-inspector.html](./browser-tools/security-inspector.html)**

A standalone HTML tool (inspired by our AuthDebugPanel) that:
- Shows all cookies, localStorage, sessionStorage
- Decodes JWT tokens automatically
- Tests CORS with configurable endpoints
- Displays security headers
- Simulates XSS attacks (localStorage vs httpOnly cookies)

**[browser-tools/cookie-vs-localstorage-demo.html](./browser-tools/cookie-vs-localstorage-demo.html)**

Side-by-side comparison showing:
- localStorage access (JavaScript can read)
- httpOnly cookie access (JavaScript cannot read)
- Visual request flow diagrams
- Live code editor

### Bash Scripts
**[scripts/security-demo.sh](./scripts/security-demo.sh)**

Terminal demonstrations of:
- JWT decoding with base64 and jq
- Authenticated API calls with curl
- Rate limit testing
- Security header inspection
- Password hashing benchmarks
- Vulnerability scanning (npm audit, pip-audit)

**[scripts/auth-flow-demo.sh](./scripts/auth-flow-demo.sh)**

Walk through the complete auth flow:
- Getting tokens from Supabase
- Inspecting token structure
- Making authenticated requests
- Observing token expiry
- Testing 401 interceptor behavior

## How to Use This Module

### For Learning
1. Read the markdown guides in order (01-06)
2. Run the Jupyter notebook cells to see concepts in action
3. Open the browser tools alongside the Provider Search app
4. Execute the bash scripts to understand command-line interaction

### For Reference
- Each guide stands alone and includes a detailed table of contents
- Code examples reference actual Provider Search files
- Decision matrices help you choose the right approach
- "Why this matters" callouts connect theory to our application

### For Development
- Use the checklist when implementing new features
- Reference the decision matrices when making architecture choices
- Run the security scripts before each deployment
- Keep the browser tools open during development

## The Philosophy

Security is about **informed tradeoffs**, not absolutes. 

For example:
- **localStorage** is "less secure" than **httpOnly cookies**
- But httpOnly cookies require CSRF protection and backend cookie management
- For a small team building an MVP, localStorage might be the right choice
- As you scale, you can migrate to cookies when the complexity is justified

This module teaches you to think critically about these tradeoffs rather than blindly following "best practices."

## Provider Search Context

Our current setup:
```
Frontend (React)
    ↓ (localStorage)
JWT Token (Supabase Auth)
    ↓ (Authorization: Bearer)
Backend (FastAPI)
    ↓ (validates JWT)
Database (Supabase PostgreSQL)
```

Key files:
- **Frontend auth**: `web/src/lib/auth.ts`, `web/src/hooks/useAuth.ts`
- **Backend auth**: `api/app/auth.py`, `api/app/middleware/auth.py`
- **Debug panel**: `web/src/components/AuthDebugPanel.tsx`
- **Rate limiting**: `api/app/middleware/rate_limit.py`

## Related Resources

- **Provider Search Architecture**: See `docs/architecture/` for system design
- **Supabase Auth Setup**: See `../project_base/reference/learning_module/docs/12b-supabase-auth.md`
- **Dev Auth Strategy**: See `../project_base/reference/learning_module/docs/12c-dev-auth-strategy.md`
- **OWASP Resources**: https://owasp.org/www-project-top-ten/
- **JWT Specification**: https://datatracker.ietf.org/doc/html/rfc7519

## Getting Started

Start with **[01-web-security-fundamentals.md](./01-web-security-fundamentals.md)** to build your foundation, or jump directly to the topic you need.

Each guide includes:
- 📋 Table of contents
- 🎯 Learning objectives
- 💡 First-principles explanations
- 🔍 Real-world examples
- ⚠️ Common pitfalls
- ✅ Best practices
- 🔗 Related reading

Ready to dive in? Let's start with the fundamentals.
