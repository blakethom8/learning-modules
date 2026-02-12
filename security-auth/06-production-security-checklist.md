# Production Security Checklist

## Table of Contents

1. [Introduction](#introduction)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Authentication & Authorization](#authentication--authorization)
4. [Security Headers](#security-headers)
5. [Secrets Management](#secrets-management)
6. [API Security](#api-security)
7. [Database Security](#database-security)
8. [Logging & Monitoring](#logging--monitoring)
9. [Incident Response](#incident-response)
10. [Provider Search Specific Items](#provider-search-specific-items)
11. [Continuous Security](#continuous-security)
12. [Further Reading](#further-reading)

---

## Introduction

This checklist is your **final security audit** before deploying to production. Use it before every major release, and review quarterly for ongoing security.

**How to use this checklist**:
- ✅ Check off completed items
- ⚠️ Mark items that need attention
- 🔄 Note items for future improvement
- 📝 Document any deviations with justification

**Remember**: Security is about **risk management**, not perfection. Some items may not apply to your stage or risk profile. The goal is to make **informed decisions**.

---

## Pre-Deployment Checklist

### Environment Configuration

- [ ] **Production environment variables are set**
  - No hardcoded secrets in code
  - `.env.production` or environment-specific config
  - Secrets stored securely (see [Secrets Management](#secrets-management))

- [ ] **Debug mode is disabled**
  ```python
  # FastAPI
  DEBUG = False
  
  # Django
  DEBUG = False
  ALLOWED_HOSTS = ['providersearch.com']
  ```

- [ ] **Database credentials are production-only**
  - Separate database for prod
  - Strong password (use password manager)
  - Limited access (only production servers)

- [ ] **HTTPS is enforced**
  - SSL certificate installed and valid
  - HTTP redirects to HTTPS
  - HSTS header enabled (see [Security Headers](#security-headers))

- [ ] **CORS is properly configured**
  ```python
  # Only allow your frontend domain
  ALLOWED_ORIGINS = [
      "https://providersearch.com",
      "https://www.providersearch.com",
  ]
  # NOT: ["*"]  # Never use wildcard in production!
  ```

### Code Quality & Vulnerabilities

- [ ] **Dependencies are up to date**
  ```bash
  # Python
  pip list --outdated
  pip-audit  # Check for known vulnerabilities
  
  # JavaScript
  npm outdated
  npm audit
  ```

- [ ] **No secrets in version control**
  ```bash
  # Check git history
  git log -p | grep -i "password\|secret\|api_key"
  
  # Use git-secrets or truffleHog
  trufflehog --regex --entropy=False .
  ```

- [ ] **Code review completed**
  - Security-focused review by another developer
  - Check for SQL injection risks
  - Check for XSS vulnerabilities
  - Verify input validation

- [ ] **Static analysis passed**
  ```bash
  # Python
  bandit -r app/
  
  # JavaScript
  npm run lint
  ```

### Testing

- [ ] **Security tests pass**
  - Authentication tests (invalid tokens, expired tokens)
  - Authorization tests (can users access others' data?)
  - Input validation tests (SQL injection, XSS)
  - Rate limiting tests

- [ ] **Penetration testing (if budget allows)**
  - Professional security audit
  - Or at minimum: OWASP ZAP automated scan

---

## Authentication & Authorization

### User Authentication

- [ ] **Passwords are hashed securely**
  - bcrypt, scrypt, or PBKDF2 (NOT MD5 or SHA-1)
  - Supabase handles this automatically ✅
  
  ```python
  # If implementing your own:
  from passlib.context import CryptContext
  
  pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
  hashed = pwd_context.hash("user_password")
  ```

- [ ] **Password requirements enforced**
  - Minimum 8 characters (12+ recommended)
  - Complexity requirements (optional, but consider passphrase approach)
  - Check against common passwords (Have I Been Pwned API)

- [ ] **Account lockout after failed attempts**
  ```python
  # After 5 failed login attempts
  if failed_attempts >= 5:
      lock_account(user_id, duration=timedelta(minutes=15))
  ```

- [ ] **Multi-factor authentication available** (optional but recommended)
  - TOTP (Google Authenticator, Authy)
  - SMS (less secure but better than nothing)
  - Supabase supports MFA

### Session Management

- [ ] **JWT secret is strong and unique**
  ```bash
  # Generate strong secret
  openssl rand -base64 32
  
  # Store in environment variable
  export SUPABASE_JWT_SECRET="your-strong-secret-here"
  ```

- [ ] **Token expiration is configured**
  - Access token: 1 hour (or less)
  - Refresh token: 30 days (or less)
  - Absolute session limit: 90 days

- [ ] **Refresh token rotation is enabled**
  - Supabase does this automatically ✅
  - If custom implementation: issue new refresh token on each refresh

- [ ] **Session invalidation works**
  - User can log out (clear tokens)
  - "Logout everywhere" option (revoke all refresh tokens)

### Authorization

- [ ] **All API endpoints require authentication**
  ```python
  # Every protected route
  @app.get("/api/protected")
  async def protected(user: dict = Depends(get_current_user)):
      # user is required
  ```

- [ ] **Authorization checks are enforced**
  ```python
  # User can only access their own data
  @app.get("/api/users/{user_id}/profile")
  async def get_profile(user_id: str, current_user: dict = Depends(get_current_user)):
      if user_id != current_user["sub"]:
          raise HTTPException(403, "Forbidden")
      
      return get_user_profile(user_id)
  ```

- [ ] **Role-based access control (if needed)**
  ```python
  def require_role(role: str):
      def decorator(user: dict = Depends(get_current_user)):
          if user.get("role") != role:
              raise HTTPException(403, "Insufficient permissions")
          return user
      return decorator
  
  @app.delete("/api/admin/users/{user_id}")
  async def delete_user(user_id: str, admin: dict = Depends(require_role("admin"))):
      # Only admins can delete users
  ```

---

## Security Headers

**Security headers protect against common attacks**. Implement these in your backend or reverse proxy (NGINX, Cloudflare).

### Required Headers

- [ ] **Strict-Transport-Security (HSTS)**
  ```python
  # FastAPI middleware
  @app.middleware("http")
  async def add_security_headers(request: Request, call_next):
      response = await call_next(request)
      
      # HSTS: Force HTTPS for 1 year
      response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
      
      return response
  ```
  
  Or in NGINX:
  ```nginx
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
  ```

- [ ] **X-Content-Type-Options**
  ```python
  # Prevent MIME type sniffing
  response.headers["X-Content-Type-Options"] = "nosniff"
  ```

- [ ] **X-Frame-Options**
  ```python
  # Prevent clickjacking
  response.headers["X-Frame-Options"] = "DENY"
  # Or "SAMEORIGIN" if you need to embed your own site in iframes
  ```

- [ ] **Content-Security-Policy (CSP)**
  ```python
  # Start with a basic policy, tighten over time
  response.headers["Content-Security-Policy"] = (
      "default-src 'self'; "
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com; "
      "style-src 'self' 'unsafe-inline'; "
      "img-src 'self' data: https:; "
      "font-src 'self' data:; "
      "connect-src 'self' https://api.providersearch.com https://*.supabase.co"
  )
  ```
  
  **CSP is complex**—start permissive, use CSP report-only mode to find violations, then tighten:
  ```python
  # Report violations without blocking (for testing)
  response.headers["Content-Security-Policy-Report-Only"] = "default-src 'self'; report-uri /csp-report"
  ```

- [ ] **Referrer-Policy**
  ```python
  # Control what referrer information is sent
  response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
  ```

- [ ] **Permissions-Policy**
  ```python
  # Disable unnecessary browser features
  response.headers["Permissions-Policy"] = (
      "geolocation=(), "
      "microphone=(), "
      "camera=()"
  )
  ```

### Provider Search Implementation

```python
# api/app/middleware/security_headers.py
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        
        # HSTS
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        
        # Prevent MIME sniffing
        response.headers["X-Content-Type-Options"] = "nosniff"
        
        # Clickjacking protection
        response.headers["X-Frame-Options"] = "DENY"
        
        # XSS protection (legacy, but doesn't hurt)
        response.headers["X-XSS-Protection"] = "1; mode=block"
        
        # CSP (adjust based on your needs)
        if request.url.path.startswith("/api/"):
            # API endpoints: strict CSP
            response.headers["Content-Security-Policy"] = "default-src 'none'"
        else:
            # Web pages: allow necessary resources
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "connect-src 'self' https://*.supabase.co"
            )
        
        # Referrer policy
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        
        # Permissions policy
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        return response

# Add to app
app.add_middleware(SecurityHeadersMiddleware)
```

**Test your headers**:
- https://securityheaders.com/ — Scan your site
- https://observatory.mozilla.org/ — Mozilla Observatory
- Browser DevTools → Network tab → Response Headers

---

## Secrets Management

### Environment Variables

- [ ] **All secrets in environment variables**
  ```bash
  # .env.production (NOT committed to git)
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_KEY=your-supabase-key
  SUPABASE_JWT_SECRET=your-jwt-secret
  OPENAI_API_KEY=sk-your-openai-key
  DATABASE_URL=postgresql://user:pass@host:5432/db
  ```

- [ ] **.env files are in .gitignore**
  ```gitignore
  # .gitignore
  .env
  .env.*
  !.env.example  # Example file is OK (no real secrets)
  ```

- [ ] **.env.example provided (without values)**
  ```bash
  # .env.example
  SUPABASE_URL=
  SUPABASE_KEY=
  SUPABASE_JWT_SECRET=
  OPENAI_API_KEY=
  DATABASE_URL=
  ```

### Secret Rotation

- [ ] **Secrets can be rotated without code changes**
  - Update environment variable
  - Restart application
  - No code deployment needed

- [ ] **Rotation plan documented**
  - JWT secret: Rotate every 90 days (or after breach)
  - API keys: Rotate every 90 days
  - Database passwords: Rotate every 180 days

### Production Secret Storage

For enhanced security (beyond .env files):

- [ ] **Consider a secret manager** (optional but recommended)
  - AWS Secrets Manager
  - Google Cloud Secret Manager
  - HashiCorp Vault
  - Doppler
  - 1Password for Teams

**Example** (AWS Secrets Manager):
```python
import boto3
import json

def get_secret(secret_name: str) -> dict:
    """
    Retrieve secret from AWS Secrets Manager.
    """
    client = boto3.client('secretsmanager', region_name='us-east-1')
    
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

# Usage
secrets = get_secret('provider-search/production')
SUPABASE_KEY = secrets['SUPABASE_KEY']
```

---

## API Security

### Input Validation

- [ ] **All inputs are validated**
  ```python
  from pydantic import BaseModel, validator, Field
  
  class SearchRequest(BaseModel):
      query: str = Field(..., min_length=1, max_length=500)
      limit: int = Field(10, ge=1, le=100)
      
      @validator('query')
      def validate_query(cls, v):
          # Strip dangerous characters
          if any(char in v for char in ['<', '>', ';', '--']):
              raise ValueError("Invalid characters in query")
          return v
  
  @app.post("/api/search")
  async def search(request: SearchRequest):
      # request.query is validated
  ```

- [ ] **SQL injection prevented**
  - Use parameterized queries
  - ORM (SQLAlchemy, Django ORM) handles this ✅
  
  ```python
  # BAD: Never do this
  query = f"SELECT * FROM users WHERE email = '{email}'"
  
  # GOOD: Parameterized query
  query = "SELECT * FROM users WHERE email = :email"
  result = db.execute(query, {"email": email})
  ```

- [ ] **File upload validation** (if applicable)
  ```python
  from fastapi import UploadFile
  
  ALLOWED_EXTENSIONS = {'.jpg', '.png', '.pdf'}
  MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
  
  async def validate_upload(file: UploadFile):
      # Check extension
      ext = os.path.splitext(file.filename)[1].lower()
      if ext not in ALLOWED_EXTENSIONS:
          raise HTTPException(400, "Invalid file type")
      
      # Check size
      contents = await file.read()
      if len(contents) > MAX_FILE_SIZE:
          raise HTTPException(400, "File too large")
      
      # Check MIME type
      if file.content_type not in ['image/jpeg', 'image/png', 'application/pdf']:
          raise HTTPException(400, "Invalid content type")
      
      await file.seek(0)  # Reset file pointer
  ```

### Rate Limiting

- [ ] **Rate limiting is enabled**
  - See [05-rate-limiting-and-abuse-protection.md](./05-rate-limiting-and-abuse-protection.md)
  - IP-based: 100 req/min for public endpoints
  - User-based: Plan-specific limits for authenticated endpoints
  - LLM endpoints: Strict limits (e.g., 10/day for free tier)

- [ ] **Rate limit headers included**
  ```python
  response.headers["X-RateLimit-Limit"] = "100"
  response.headers["X-RateLimit-Remaining"] = "87"
  response.headers["X-RateLimit-Reset"] = "1704067200"
  ```

### API Keys (if applicable)

- [ ] **API keys are rotatable**
- [ ] **API keys have expiration dates**
- [ ] **API keys have permission scopes** (read-only, write, admin)
- [ ] **API key usage is logged**

---

## Database Security

### Access Control

- [ ] **Database has firewall rules**
  - Only production servers can connect
  - No public access (unless using connection pooler)

- [ ] **Least privilege for database users**
  ```sql
  -- Application user: read/write on tables only
  CREATE USER app_user WITH PASSWORD 'strong-password';
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
  
  -- Read-only analytics user
  CREATE USER analytics_user WITH PASSWORD 'strong-password';
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;
  ```

- [ ] **Row-level security (if using Supabase)**
  ```sql
  -- Users can only access their own data
  ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
  
  CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);
  
  CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);
  ```

### Backups

- [ ] **Automated backups enabled**
  - Daily backups at minimum
  - Retention: 30 days
  - Supabase Pro/Enterprise includes automatic backups ✅

- [ ] **Backup restoration tested**
  - Actually try restoring from a backup
  - Document the process
  - Test at least quarterly

- [ ] **Backups are encrypted**
- [ ] **Backups are stored off-site**

### Data Encryption

- [ ] **Data at rest is encrypted**
  - Supabase encrypts by default ✅
  - AWS RDS: Enable encryption
  - Self-hosted: Use encrypted disks (LUKS, dm-crypt)

- [ ] **Data in transit is encrypted**
  - Use SSL/TLS for database connections
  ```python
  # Supabase uses TLS by default
  DATABASE_URL = "postgresql://user:pass@host:5432/db?sslmode=require"
  ```

- [ ] **Sensitive fields are encrypted** (optional)
  ```python
  from cryptography.fernet import Fernet
  
  # Encrypt SSN, credit card numbers, etc.
  cipher = Fernet(settings.ENCRYPTION_KEY)
  encrypted_ssn = cipher.encrypt(ssn.encode())
  ```

---

## Logging & Monitoring

### Logging

- [ ] **Application logs are configured**
  ```python
  import logging
  
  logging.basicConfig(
      level=logging.INFO,
      format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
      handlers=[
          logging.FileHandler('app.log'),
          logging.StreamHandler()
      ]
  )
  
  logger = logging.getLogger(__name__)
  ```

- [ ] **Security events are logged**
  - Failed login attempts
  - Authorization failures (403 errors)
  - Rate limit violations
  - Suspicious patterns (e.g., SQL injection attempts)
  
  ```python
  logger.warning(
      f"Failed login attempt for {email} from {ip}",
      extra={"event": "auth_failure", "ip": ip, "email": email}
  )
  ```

- [ ] **Logs do NOT contain secrets**
  ```python
  # BAD
  logger.info(f"User authenticated with token {token}")
  
  # GOOD
  logger.info(f"User authenticated", extra={"user_id": user_id})
  ```

- [ ] **Logs are centralized** (optional but recommended)
  - Cloudwatch Logs (AWS)
  - Google Cloud Logging
  - Datadog, Logtail, Papertrail
  - Self-hosted: ELK stack (Elasticsearch, Logstash, Kibana)

### Monitoring

- [ ] **Uptime monitoring enabled**
  - Pingdom, UptimeRobot, Datadog
  - Alert if site is down for >2 minutes

- [ ] **Error tracking enabled**
  - Sentry, Rollbar, Bugsnag
  - Alert on new errors or error spikes

- [ ] **Performance monitoring** (optional)
  - New Relic, Datadog APM
  - Track slow API endpoints

- [ ] **Security monitoring**
  - Alert on repeated failed logins (possible brute force)
  - Alert on unusual traffic patterns (possible DDoS)
  - Alert on high rate limit violations

**Example alert** (Sentry + Slack):
```python
# Send Slack alert on critical errors
import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration

sentry_sdk.init(
    dsn=settings.SENTRY_DSN,
    environment="production",
    integrations=[LoggingIntegration(level=logging.WARNING, event_level=logging.ERROR)],
    traces_sample_rate=0.1,
)
```

---

## Incident Response

### Preparation

- [ ] **Incident response plan documented**
  - Who to contact (on-call engineer, security team, management)
  - Escalation path
  - Communication channels (Slack, PagerDuty)

- [ ] **Security contacts identified**
  - security@providersearch.com email alias
  - Responsible disclosure policy on website

- [ ] **Runbook for common incidents**
  - Data breach
  - DDoS attack
  - Compromised credentials
  - Service outage

### Detection

- [ ] **Alerts are configured** (see Monitoring above)
- [ ] **Security scanning enabled**
  ```bash
  # Automated vulnerability scanning
  npm audit  # Daily via CI/CD
  pip-audit  # Daily via CI/CD
  
  # OWASP ZAP scan
  zap-cli quick-scan https://providersearch.com
  ```

### Response

**When a security incident occurs**:

1. **Contain**: Limit the damage
   - Block attacking IPs
   - Revoke compromised credentials
   - Take affected systems offline if necessary

2. **Investigate**: Understand what happened
   - Review logs
   - Identify affected systems/users
   - Determine attack vector

3. **Remediate**: Fix the vulnerability
   - Patch the vulnerability
   - Rotate compromised secrets
   - Update firewall rules

4. **Communicate**: Inform stakeholders
   - Internal team
   - Affected users (if data breach)
   - Authorities (if required by law, e.g., GDPR)

5. **Post-mortem**: Learn and improve
   - Document what happened
   - Update security measures
   - Improve detection for future incidents

**Example incident**: Compromised database credentials

```bash
# 1. Contain
- Rotate database password immediately
- Update environment variables on production servers
- Restart application

# 2. Investigate
- Check database logs for unauthorized access
- Review application logs for unusual queries
- Scan for data exfiltration

# 3. Remediate
- Update password policy (longer, more complex)
- Enable IP whitelisting for database
- Add alerts for unusual database activity

# 4. Communicate
- Inform team via Slack
- If data breach: email affected users
- Report to authorities if required

# 5. Post-mortem
- Document timeline
- Update runbook
- Add to incident log
```

---

## Provider Search Specific Items

### Supabase Configuration

- [ ] **Supabase project settings reviewed**
  - JWT expiration: 3600 seconds (1 hour)
  - Email auth enabled
  - Email templates customized
  - RLS policies enabled on all tables

- [ ] **Supabase API keys secured**
  - `anon` key: OK to expose (public, limited access)
  - `service_role` key: NEVER expose (full access, backend only)

- [ ] **Database migrations are tested**
  - Test migrations on staging before production
  - Have rollback plan

### FastAPI Configuration

- [ ] **CORS properly configured** (production domains only)
  ```python
  from fastapi.middleware.cors import CORSMiddleware
  
  app.add_middleware(
      CORSMiddleware,
      allow_origins=[
          "https://providersearch.com",
          "https://www.providersearch.com",
      ],
      allow_credentials=True,
      allow_methods=["GET", "POST", "PUT", "DELETE"],
      allow_headers=["*"],
  )
  ```

- [ ] **Docs disabled in production** (or protected)
  ```python
  # Disable Swagger UI in production
  app = FastAPI(
      docs_url=None if settings.ENVIRONMENT == "production" else "/docs",
      redoc_url=None if settings.ENVIRONMENT == "production" else "/redoc",
  )
  ```

### React Frontend

- [ ] **Build is optimized**
  ```bash
  npm run build  # Production build with minification
  ```

- [ ] **No console.logs in production**
  ```javascript
  // Use a logger that respects NODE_ENV
  const logger = process.env.NODE_ENV === 'production' ? {
    log: () => {},
    error: console.error,  // Keep errors
  } : console;
  ```

- [ ] **Source maps are NOT deployed** (optional)
  - Source maps help debugging but expose code structure
  - If deployed, restrict access (e.g., require authentication)

### LLM Integration

- [ ] **OpenAI API key secured**
  - Backend only (never in frontend)
  - Environment variable
  - Rotated quarterly

- [ ] **LLM usage limits enforced**
  - Per-user daily limits
  - Cost caps
  - See [05-rate-limiting-and-abuse-protection.md](./05-rate-limiting-and-abuse-protection.md)

- [ ] **Prompt injection defenses**
  ```python
  def sanitize_user_input(user_input: str) -> str:
      """
      Remove potential prompt injection attempts.
      """
      # Remove system-like instructions
      dangerous_patterns = [
          "ignore previous instructions",
          "disregard above",
          "system:",
          "assistant:",
      ]
      
      cleaned = user_input
      for pattern in dangerous_patterns:
          cleaned = cleaned.replace(pattern, "")
      
      return cleaned[:1000]  # Limit length
  ```

---

## Continuous Security

Security is ongoing, not one-time:

### Weekly

- [ ] Review logs for suspicious activity
- [ ] Check error tracking (Sentry) for new issues

### Monthly

- [ ] Review user access (remove former employees, unused accounts)
- [ ] Check dependency updates (`npm audit`, `pip-audit`)
- [ ] Review and adjust rate limits based on usage patterns

### Quarterly

- [ ] Run full security scan (OWASP ZAP or professional pentest)
- [ ] Rotate API keys and JWT secrets
- [ ] Review and update this checklist
- [ ] Test backup restoration
- [ ] Review security headers (https://securityheaders.com/)
- [ ] Security training for team (OWASP Top 10, common vulnerabilities)

### Annually

- [ ] Professional security audit (if budget allows)
- [ ] Review and update incident response plan
- [ ] Review and update privacy policy / terms of service
- [ ] Compliance audit (GDPR, HIPAA, etc. if applicable)

---

## Further Reading

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Security Headers**: https://securityheaders.com/
- **Mozilla Observatory**: https://observatory.mozilla.org/
- **CWE Top 25**: https://cwe.mitre.org/top25/
- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **Google's Security Best Practices**: https://cloud.google.com/security/best-practices
- **FastAPI Security**: https://fastapi.tiangolo.com/tutorial/security/
- **Supabase Security**: https://supabase.com/docs/guides/platform/going-into-prod

---

## Final Thoughts

**Security is a journey, not a destination**. This checklist gets you production-ready, but security requires ongoing attention.

**Prioritize based on your risk profile**:
- **Early startup**: Focus on the basics (HTTPS, auth, input validation)
- **Growing SaaS**: Add rate limiting, monitoring, automated backups
- **Enterprise**: Full security program (audits, compliance, dedicated security team)

**Remember**: Perfect security doesn't exist. The goal is to make attacking your application **more expensive than the value of the data**.

---

**You've completed the Security & Auth learning module!** 🎉

Next steps:
- Implement missing checklist items for Provider Search
- Run `scripts/security-demo.sh` to test your setup
- Use `browser-tools/security-inspector.html` to audit frontend security
- Review this checklist before every major release
