#!/bin/bash

##############################################################################
# Security Demo Script - Provider Search Learning Module
# 
# This script demonstrates various security concepts:
# - JWT token decoding
# - Password hashing
# - Security header inspection
# - Rate limiting tests
# - npm security auditing
#
# Requirements: curl, jq, base64 (standard on most systems)
# Optional: npm (for audit demo)
##############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

##############################################################################
# 1. JWT Token Decoding
##############################################################################
jwt_decode_demo() {
    print_header "1. JWT Token Decoding Demo"
    
    # Sample JWT (this is a demo token, not real)
    JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyXzEyMzQ1IiwibmFtZSI6IkpvaG4gRG9lIiwiZW1haWwiOiJqb2huQGV4YW1wbGUuY29tIiwicm9sZSI6InVzZXIiLCJpYXQiOjE3MDk0NzQxMjAsImV4cCI6MTczOTQ3NDEyMH0.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    
    echo -e "${BOLD}Sample JWT Token:${NC}"
    echo "$JWT"
    echo ""
    
    # Split JWT into parts
    IFS='.' read -ra PARTS <<< "$JWT"
    HEADER="${PARTS[0]}"
    PAYLOAD="${PARTS[1]}"
    SIGNATURE="${PARTS[2]}"
    
    # Decode header
    echo -e "${BOLD}${MAGENTA}HEADER (decoded):${NC}"
    if command -v jq &> /dev/null; then
        echo "$HEADER" | base64 -d 2>/dev/null | jq '.' 2>/dev/null || echo "$HEADER" | base64 -d
    else
        echo "$HEADER" | base64 -d 2>/dev/null
    fi
    echo ""
    
    # Decode payload
    echo -e "${BOLD}${MAGENTA}PAYLOAD (decoded):${NC}"
    if command -v jq &> /dev/null; then
        DECODED_PAYLOAD=$(echo "$PAYLOAD" | base64 -d 2>/dev/null)
        echo "$DECODED_PAYLOAD" | jq '.' 2>/dev/null || echo "$DECODED_PAYLOAD"
        
        # Extract expiration time
        EXP=$(echo "$DECODED_PAYLOAD" | jq -r '.exp' 2>/dev/null)
        if [ ! -z "$EXP" ] && [ "$EXP" != "null" ]; then
            EXP_DATE=$(date -r "$EXP" 2>/dev/null || date -d "@$EXP" 2>/dev/null)
            echo ""
            print_info "Token expires: $EXP_DATE"
            
            # Check if expired
            CURRENT_TIME=$(date +%s)
            if [ "$CURRENT_TIME" -gt "$EXP" ]; then
                print_error "Token is EXPIRED!"
            else
                print_success "Token is still valid"
            fi
        fi
    else
        echo "$PAYLOAD" | base64 -d 2>/dev/null
        print_warning "Install 'jq' for better JSON formatting"
    fi
    echo ""
    
    # Show signature (can't verify without secret key)
    echo -e "${BOLD}${MAGENTA}SIGNATURE (raw):${NC}"
    echo "$SIGNATURE"
    echo ""
    print_info "Signature verification requires the secret key (server-side only)"
    
    # Key takeaway
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 Key Takeaway:${NC}"
    echo "JWTs are ENCODED, not ENCRYPTED. Anyone can decode and read the payload!"
    echo "Never store sensitive data in JWT claims."
}

##############################################################################
# 2. Password Hashing Demo
##############################################################################
password_hashing_demo() {
    print_header "2. Password Hashing Demo"
    
    PASSWORD="MySecurePassword123!"
    
    echo -e "${BOLD}Original Password:${NC} $PASSWORD"
    echo ""
    
    # SHA-256 hash (simple example - NOT for production!)
    echo -e "${BOLD}${MAGENTA}SHA-256 Hash:${NC}"
    HASH=$(echo -n "$PASSWORD" | shasum -a 256 | awk '{print $1}')
    echo "$HASH"
    echo ""
    print_warning "SHA-256 alone is TOO FAST for passwords (vulnerable to brute force)"
    print_info "Production systems should use: bcrypt, argon2, or scrypt"
    echo ""
    
    # Demonstrate avalanche effect
    echo -e "${BOLD}${MAGENTA}Avalanche Effect (tiny change = completely different hash):${NC}"
    HASH1=$(echo -n "$PASSWORD" | shasum -a 256 | awk '{print $1}')
    HASH2=$(echo -n "${PASSWORD}X" | shasum -a 256 | awk '{print $1}')
    
    echo "Password: '$PASSWORD'"
    echo "Hash:     ${HASH1:0:32}..."
    echo ""
    echo "Password: '${PASSWORD}X' (one char added)"
    echo "Hash:     ${HASH2:0:32}..."
    echo ""
    print_success "Completely different hashes!"
    
    # Salting demonstration
    echo ""
    echo -e "${BOLD}${MAGENTA}Why Salt Matters:${NC}"
    SALT1=$(openssl rand -hex 16)
    SALT2=$(openssl rand -hex 16)
    
    SALTED1=$(echo -n "${PASSWORD}${SALT1}" | shasum -a 256 | awk '{print $1}')
    SALTED2=$(echo -n "${PASSWORD}${SALT2}" | shasum -a 256 | awk '{print $1}')
    
    echo "Same password, different salts:"
    echo "Salt 1: $SALT1"
    echo "Hash 1: ${SALTED1:0:40}..."
    echo ""
    echo "Salt 2: $SALT2"
    echo "Hash 2: ${SALTED2:0:40}..."
    echo ""
    print_success "Different hashes protect against rainbow table attacks!"
    
    # Timing demonstration
    echo ""
    echo -e "${BOLD}${MAGENTA}Hashing Speed Comparison:${NC}"
    echo "Testing 1000 iterations..."
    
    START=$(date +%s%N)
    for i in {1..1000}; do
        echo -n "test" | shasum -a 256 > /dev/null
    done
    END=$(date +%s%N)
    DIFF=$(( (END - START) / 1000000 ))
    echo "SHA-256: ${DIFF}ms (TOO FAST - attackers can try billions per second)"
    
    print_info "bcrypt/argon2 are intentionally SLOW (~100-300ms per hash)"
    print_info "This makes brute force attacks impractical"
}

##############################################################################
# 3. Security Headers Inspection
##############################################################################
security_headers_demo() {
    print_header "3. Security Headers Inspection"
    
    URLS=(
        "https://www.google.com"
        "https://github.com"
    )
    
    print_info "Checking security headers for popular sites..."
    echo ""
    
    for URL in "${URLS[@]}"; do
        echo -e "${BOLD}${CYAN}Checking: $URL${NC}"
        
        if ! command -v curl &> /dev/null; then
            print_error "curl not found. Please install curl."
            return 1
        fi
        
        # Fetch headers
        HEADERS=$(curl -s -I -L "$URL" 2>/dev/null)
        
        if [ -z "$HEADERS" ]; then
            print_error "Failed to fetch headers"
            continue
        fi
        
        # Check for important security headers
        echo ""
        
        if echo "$HEADERS" | grep -qi "strict-transport-security"; then
            HSTS=$(echo "$HEADERS" | grep -i "strict-transport-security" | head -1 | cut -d: -f2-)
            print_success "HSTS: $HSTS"
        else
            print_error "HSTS: Not found (HTTPS not enforced)"
        fi
        
        if echo "$HEADERS" | grep -qi "x-frame-options"; then
            XFO=$(echo "$HEADERS" | grep -i "x-frame-options" | head -1 | cut -d: -f2-)
            print_success "X-Frame-Options: $XFO"
        else
            print_error "X-Frame-Options: Not found (vulnerable to clickjacking)"
        fi
        
        if echo "$HEADERS" | grep -qi "x-content-type-options"; then
            XCTO=$(echo "$HEADERS" | grep -i "x-content-type-options" | head -1 | cut -d: -f2-)
            print_success "X-Content-Type-Options: $XCTO"
        else
            print_error "X-Content-Type-Options: Not found (vulnerable to MIME sniffing)"
        fi
        
        if echo "$HEADERS" | grep -qi "content-security-policy"; then
            CSP=$(echo "$HEADERS" | grep -i "content-security-policy" | head -1 | cut -d: -f2- | cut -c1-60)
            print_success "CSP: ${CSP}..."
        else
            print_warning "CSP: Not found (no XSS protection)"
        fi
        
        if echo "$HEADERS" | grep -qi "x-xss-protection"; then
            XXP=$(echo "$HEADERS" | grep -i "x-xss-protection" | head -1 | cut -d: -f2-)
            print_success "X-XSS-Protection: $XXP"
        else
            print_warning "X-XSS-Protection: Not found"
        fi
        
        echo ""
        echo "---"
    done
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 Key Security Headers:${NC}"
    echo "• Strict-Transport-Security: Forces HTTPS"
    echo "• X-Frame-Options: Prevents clickjacking"
    echo "• X-Content-Type-Options: Prevents MIME sniffing"
    echo "• Content-Security-Policy: Prevents XSS"
    echo "• X-XSS-Protection: Browser XSS filtering"
}

##############################################################################
# 4. Rate Limiting Test
##############################################################################
rate_limit_demo() {
    print_header "4. Rate Limiting Test"
    
    print_info "Simulating rapid requests to test rate limiting..."
    echo ""
    
    TEST_URL="https://httpbin.org/delay/0"
    REQUEST_COUNT=20
    
    echo -e "${BOLD}Sending $REQUEST_COUNT requests rapidly...${NC}"
    echo ""
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    START=$(date +%s)
    
    for i in $(seq 1 $REQUEST_COUNT); do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL" --max-time 2 2>/dev/null)
        
        if [ "$STATUS" = "200" ]; then
            echo -ne "${GREEN}✓${NC}"
            ((SUCCESS_COUNT++))
        elif [ "$STATUS" = "429" ]; then
            echo -ne "${RED}✗${NC}"
            ((FAIL_COUNT++))
        else
            echo -ne "${YELLOW}?${NC}"
        fi
        
        # Brief pause
        sleep 0.1
    done
    
    END=$(date +%s)
    DURATION=$((END - START))
    
    echo ""
    echo ""
    print_success "Successful: $SUCCESS_COUNT requests"
    if [ $FAIL_COUNT -gt 0 ]; then
        print_error "Rate limited: $FAIL_COUNT requests (HTTP 429)"
    fi
    print_info "Duration: ${DURATION}s"
    print_info "Rate: $((REQUEST_COUNT / DURATION)) req/sec"
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 Rate Limiting Best Practices:${NC}"
    echo "• Limit: 100-1000 req/min per user (depends on endpoint)"
    echo "• Use sliding window or token bucket algorithms"
    echo "• Return HTTP 429 with Retry-After header"
    echo "• Track by user ID or IP address"
    echo "• Provider Search uses fastapi-limiter"
}

##############################################################################
# 5. CORS Testing
##############################################################################
cors_demo() {
    print_header "5. CORS (Cross-Origin Resource Sharing)"
    
    print_info "Understanding CORS with examples..."
    echo ""
    
    echo -e "${BOLD}${MAGENTA}What is CORS?${NC}"
    echo "CORS is a security mechanism that controls which origins can access your API."
    echo ""
    
    echo -e "${BOLD}${MAGENTA}Example CORS Headers:${NC}"
    echo "Access-Control-Allow-Origin: https://provider-search.com"
    echo "Access-Control-Allow-Methods: GET, POST, PUT, DELETE"
    echo "Access-Control-Allow-Headers: Content-Type, Authorization"
    echo "Access-Control-Allow-Credentials: true"
    echo ""
    
    print_info "Testing public API with CORS..."
    TEST_API="https://api.github.com/repos/torvalds/linux"
    
    echo ""
    echo -e "${BOLD}Fetching: $TEST_API${NC}"
    CORS_HEADERS=$(curl -s -I "$TEST_API" 2>/dev/null | grep -i "access-control")
    
    if [ ! -z "$CORS_HEADERS" ]; then
        print_success "CORS headers found:"
        echo "$CORS_HEADERS"
    else
        print_warning "No CORS headers (may use default browser policy)"
    fi
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 CORS Configuration for Provider Search:${NC}"
    echo ""
    echo "# FastAPI CORS Middleware"
    echo "app.add_middleware("
    echo "    CORSMiddleware,"
    echo "    allow_origins=["
    echo "        'http://localhost:3000',  # Development"
    echo "        'https://provider-search.com',  # Production"
    echo "    ],"
    echo "    allow_credentials=True,"
    echo "    allow_methods=['GET', 'POST', 'PUT', 'DELETE'],"
    echo "    allow_headers=['*'],"
    echo ")"
    echo ""
    print_warning "Never use allow_origins=['*'] with allow_credentials=True!"
}

##############################################################################
# 6. npm Audit Demo (if npm available)
##############################################################################
npm_audit_demo() {
    print_header "6. npm Security Audit"
    
    if ! command -v npm &> /dev/null; then
        print_warning "npm not installed. Skipping npm audit demo."
        echo ""
        print_info "npm audit checks for known vulnerabilities in dependencies"
        print_info "Run 'npm audit' in any Node.js project to check security"
        return
    fi
    
    print_info "npm audit scans package.json for known vulnerabilities..."
    echo ""
    
    echo -e "${BOLD}${YELLOW}Example npm audit output:${NC}"
    echo ""
    echo "┌───────────────┬──────────────────────────────────────────────────────────────┐"
    echo "│ Severity      │ Vulnerability                                                │"
    echo "├───────────────┼──────────────────────────────────────────────────────────────┤"
    echo "│ high          │ Cross-Site Scripting in react-dom                            │"
    echo "├───────────────┼──────────────────────────────────────────────────────────────┤"
    echo "│ moderate      │ Inefficient Regular Expression in trim                       │"
    echo "└───────────────┴──────────────────────────────────────────────────────────────┘"
    echo ""
    
    print_info "Commands:"
    echo "  npm audit         # Show vulnerabilities"
    echo "  npm audit fix     # Auto-fix (safe updates)"
    echo "  npm audit fix --force  # Fix breaking changes too"
    echo ""
    
    echo -e "${BOLD}${YELLOW}🔑 Dependency Security:${NC}"
    echo "• Run 'npm audit' regularly (CI/CD pipeline)"
    echo "• Update dependencies promptly"
    echo "• Use 'npm outdated' to check for updates"
    echo "• Enable GitHub Dependabot for alerts"
    echo "• Review security advisories before updating"
}

##############################################################################
# 7. Auth Token Best Practices
##############################################################################
auth_best_practices() {
    print_header "7. Authentication Token Best Practices"
    
    echo -e "${BOLD}${GREEN}✓ DO:${NC}"
    echo "  • Use httpOnly cookies for auth tokens"
    echo "  • Set Secure flag (HTTPS only)"
    echo "  • Use SameSite=Strict or Lax"
    echo "  • Implement token expiration (15-60 min)"
    echo "  • Use refresh tokens (long-lived)"
    echo "  • Validate tokens on every request"
    echo "  • Use strong signing algorithms (RS256, HS256)"
    echo "  • Rotate secrets regularly"
    echo ""
    
    echo -e "${BOLD}${RED}✗ DON'T:${NC}"
    echo "  • Store tokens in localStorage (XSS vulnerable)"
    echo "  • Use tokens without expiration"
    echo "  • Put sensitive data in JWT payload"
    echo "  • Use weak signing algorithms (none, HS256 with weak secret)"
    echo "  • Skip token validation"
    echo "  • Hardcode secrets in source code"
    echo "  • Log tokens (even in debug mode)"
    echo ""
    
    echo -e "${BOLD}${YELLOW}🔑 Provider Search Implementation:${NC}"
    echo "  • Supabase handles token management"
    echo "  • JWT with refresh token flow"
    echo "  • Tokens validated on every API request"
    echo "  • Rate limiting prevents brute force"
    echo "  • CORS restricts origins"
    echo "  • All traffic over HTTPS in production"
}

##############################################################################
# Main Menu
##############################################################################
show_menu() {
    echo -e "${BOLD}${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║       🔐 Security Demo - Provider Search Module 🔐        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Select a demo:"
    echo ""
    echo "  1) JWT Token Decoding"
    echo "  2) Password Hashing"
    echo "  3) Security Headers Inspection"
    echo "  4) Rate Limiting Test"
    echo "  5) CORS Explanation"
    echo "  6) npm Security Audit"
    echo "  7) Auth Best Practices"
    echo ""
    echo "  8) Run All Demos"
    echo "  9) Exit"
    echo ""
}

run_all() {
    jwt_decode_demo
    password_hashing_demo
    security_headers_demo
    rate_limit_demo
    cors_demo
    npm_audit_demo
    auth_best_practices
    
    echo ""
    print_success "All demos completed!"
}

##############################################################################
# Main Script
##############################################################################

# Check dependencies
check_dependencies() {
    MISSING=""
    
    if ! command -v curl &> /dev/null; then
        MISSING="$MISSING curl"
    fi
    
    if ! command -v base64 &> /dev/null; then
        MISSING="$MISSING base64"
    fi
    
    if [ ! -z "$MISSING" ]; then
        print_error "Missing required dependencies:$MISSING"
        print_info "Please install them first"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found (optional but recommended for better output)"
        print_info "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
        echo ""
    fi
}

main() {
    check_dependencies
    
    if [ "$1" = "--all" ]; then
        run_all
        exit 0
    fi
    
    if [ ! -z "$1" ]; then
        case $1 in
            1|jwt) jwt_decode_demo ;;
            2|password) password_hashing_demo ;;
            3|headers) security_headers_demo ;;
            4|rate-limit) rate_limit_demo ;;
            5|cors) cors_demo ;;
            6|npm) npm_audit_demo ;;
            7|best-practices) auth_best_practices ;;
            *)
                echo "Invalid option: $1"
                echo "Usage: $0 [1-7|jwt|password|headers|rate-limit|cors|npm|best-practices|--all]"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Interactive mode
    while true; do
        show_menu
        read -p "Enter your choice: " CHOICE
        
        case $CHOICE in
            1) jwt_decode_demo ;;
            2) password_hashing_demo ;;
            3) security_headers_demo ;;
            4) rate_limit_demo ;;
            5) cors_demo ;;
            6) npm_audit_demo ;;
            7) auth_best_practices ;;
            8) run_all ;;
            9) 
                echo ""
                print_success "Thanks for learning! Stay secure! 🔐"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Run main
main "$@"
