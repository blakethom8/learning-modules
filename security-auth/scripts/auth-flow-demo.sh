#!/bin/bash

##############################################################################
# Authentication Flow Demo - Provider Search Learning Module
#
# Complete authentication flow demonstration:
# 1. Register new user
# 2. Login and receive token
# 3. Decode token
# 4. Make authenticated request
# 5. Test token expiration
# 6. Test 401 unauthorized
#
# Requirements: curl, jq, base64
# Target: http://localhost:8000 (FastAPI backend)
##############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
API_PREFIX="${API_PREFIX:-/api/v1}"

# Helper functions
print_header() {
    echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
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
    echo -e "${CYAN}ℹ $1${NC}"
}

print_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq '.' 2>/dev/null || echo "$1"
    else
        echo "$1"
    fi
}

pause() {
    echo ""
    read -p "Press Enter to continue..." </dev/tty
}

decode_jwt() {
    local token=$1
    local part=$2
    
    IFS='.' read -ra PARTS <<< "$token"
    
    if [ "$part" = "header" ]; then
        echo "${PARTS[0]}" | base64 -d 2>/dev/null
    elif [ "$part" = "payload" ]; then
        echo "${PARTS[1]}" | base64 -d 2>/dev/null
    else
        echo "${PARTS[2]}"
    fi
}

##############################################################################
# Pre-flight Check
##############################################################################
preflight_check() {
    print_header "🔍 Pre-flight Check"
    
    # Check dependencies
    print_step "Checking dependencies..."
    
    local missing=""
    if ! command -v curl &> /dev/null; then
        missing="$missing curl"
    fi
    if ! command -v base64 &> /dev/null; then
        missing="$missing base64"
    fi
    
    if [ ! -z "$missing" ]; then
        print_error "Missing required tools:$missing"
        print_info "Please install them first"
        exit 1
    fi
    print_success "All required tools found"
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found (optional but recommended)"
        print_info "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"
    else
        print_success "jq found (JSON formatting enabled)"
    fi
    
    # Check API availability
    echo ""
    print_step "Checking API availability at $API_BASE_URL..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_BASE_URL}/health" --max-time 3 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
        print_success "API is reachable"
    else
        print_error "API is not reachable (HTTP $HTTP_CODE)"
        print_warning "Make sure FastAPI backend is running on $API_BASE_URL"
        print_info "Start backend with: cd backend && uvicorn main:app --reload"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r </dev/tty
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

##############################################################################
# 1. User Registration
##############################################################################
test_registration() {
    print_header "1️⃣  User Registration"
    
    # Generate unique email
    TIMESTAMP=$(date +%s)
    TEST_EMAIL="testuser${TIMESTAMP}@example.com"
    TEST_PASSWORD="SecurePass123!"
    TEST_NAME="Test User"
    
    print_step "Registering new user..."
    echo ""
    echo -e "${BOLD}Registration Details:${NC}"
    echo "  Email: $TEST_EMAIL"
    echo "  Password: $TEST_PASSWORD"
    echo "  Name: $TEST_NAME"
    echo ""
    
    print_step "Sending POST request to ${API_BASE_URL}${API_PREFIX}/auth/register"
    
    REGISTER_RESPONSE=$(curl -s -X POST "${API_BASE_URL}${API_PREFIX}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\",
            \"name\": \"${TEST_NAME}\"
        }" 2>/dev/null)
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${API_BASE_URL}${API_PREFIX}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\",
            \"name\": \"${TEST_NAME}\"
        }" 2>/dev/null)
    
    echo ""
    echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
    print_json "$REGISTER_RESPONSE"
    echo ""
    
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        print_success "Registration successful!"
        USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.id // .user_id // .user.id' 2>/dev/null)
        if [ ! -z "$USER_ID" ] && [ "$USER_ID" != "null" ]; then
            print_info "User ID: $USER_ID"
        fi
    elif [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "409" ]; then
        print_warning "User may already exist or validation failed"
        print_info "Proceeding with login..."
    elif [ "$HTTP_CODE" = "404" ]; then
        print_error "Endpoint not found - API structure may differ"
        print_info "Check your API routes and update API_PREFIX if needed"
    else
        print_error "Registration failed with HTTP $HTTP_CODE"
    fi
    
    pause
}

##############################################################################
# 2. User Login
##############################################################################
test_login() {
    print_header "2️⃣  User Login"
    
    print_step "Logging in..."
    echo ""
    echo -e "${BOLD}Login Credentials:${NC}"
    echo "  Email: $TEST_EMAIL"
    echo "  Password: $TEST_PASSWORD"
    echo ""
    
    print_step "Sending POST request to ${API_BASE_URL}${API_PREFIX}/auth/login"
    
    LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE_URL}${API_PREFIX}/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\"
        }" 2>/dev/null)
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${API_BASE_URL}${API_PREFIX}/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"${TEST_EMAIL}\",
            \"password\": \"${TEST_PASSWORD}\"
        }" 2>/dev/null)
    
    echo ""
    echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
    print_json "$LOGIN_RESPONSE"
    echo ""
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Login successful!"
        
        # Extract token (try different possible field names)
        ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // .token // .accessToken // .data.token' 2>/dev/null)
        
        if [ ! -z "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
            print_success "Access token received"
            echo ""
            echo -e "${BOLD}Token (truncated):${NC}"
            echo "${ACCESS_TOKEN:0:50}..."
        else
            print_error "No access token in response"
            print_info "Response fields: $(echo "$LOGIN_RESPONSE" | jq -r 'keys | join(", ")' 2>/dev/null)"
            
            # Try to continue anyway
            ACCESS_TOKEN="mock_token_for_demo"
        fi
    else
        print_error "Login failed with HTTP $HTTP_CODE"
        print_warning "Using mock token for demonstration"
        ACCESS_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyXzEyMyIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImV4cCI6MTczOTQ3NDEyMH0.demo"
    fi
    
    pause
}

##############################################################################
# 3. Decode JWT Token
##############################################################################
test_token_decode() {
    print_header "3️⃣  JWT Token Decode"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "No access token available"
        return
    fi
    
    print_step "Decoding JWT token..."
    echo ""
    echo -e "${BOLD}Full Token:${NC}"
    echo "$ACCESS_TOKEN"
    echo ""
    
    # Decode header
    print_step "Decoding Header..."
    HEADER=$(decode_jwt "$ACCESS_TOKEN" "header")
    echo -e "${BOLD}${MAGENTA}Header:${NC}"
    print_json "$HEADER"
    echo ""
    
    # Decode payload
    print_step "Decoding Payload..."
    PAYLOAD=$(decode_jwt "$ACCESS_TOKEN" "payload")
    echo -e "${BOLD}${MAGENTA}Payload:${NC}"
    print_json "$PAYLOAD"
    echo ""
    
    # Extract key fields
    if command -v jq &> /dev/null; then
        SUB=$(echo "$PAYLOAD" | jq -r '.sub // .user_id' 2>/dev/null)
        EXP=$(echo "$PAYLOAD" | jq -r '.exp' 2>/dev/null)
        IAT=$(echo "$PAYLOAD" | jq -r '.iat' 2>/dev/null)
        
        if [ ! -z "$SUB" ] && [ "$SUB" != "null" ]; then
            print_info "Subject (User ID): $SUB"
        fi
        
        if [ ! -z "$IAT" ] && [ "$IAT" != "null" ]; then
            IAT_DATE=$(date -r "$IAT" 2>/dev/null || date -d "@$IAT" 2>/dev/null)
            print_info "Issued At: $IAT_DATE"
        fi
        
        if [ ! -z "$EXP" ] && [ "$EXP" != "null" ]; then
            EXP_DATE=$(date -r "$EXP" 2>/dev/null || date -d "@$EXP" 2>/dev/null)
            print_info "Expires: $EXP_DATE"
            
            # Check if expired
            CURRENT_TIME=$(date +%s)
            if [ "$CURRENT_TIME" -gt "$EXP" ]; then
                print_error "Token is EXPIRED!"
            else
                TIME_LEFT=$((EXP - CURRENT_TIME))
                print_success "Token is valid for $TIME_LEFT more seconds"
            fi
        fi
    fi
    
    # Show signature
    SIGNATURE=$(decode_jwt "$ACCESS_TOKEN" "signature")
    echo ""
    echo -e "${BOLD}${MAGENTA}Signature:${NC}"
    echo "$SIGNATURE"
    echo ""
    print_info "Signature verification requires the secret key (server-side)"
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 Key Insight:${NC}"
    echo "JWTs are ENCODED (Base64), not ENCRYPTED!"
    echo "Anyone can decode and read the payload."
    echo "The signature ensures the token hasn't been tampered with."
    
    pause
}

##############################################################################
# 4. Authenticated Request
##############################################################################
test_authenticated_request() {
    print_header "4️⃣  Authenticated API Request"
    
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "No access token available"
        return
    fi
    
    print_step "Making authenticated request..."
    echo ""
    
    # Try common endpoints
    ENDPOINTS=(
        "${API_PREFIX}/auth/me"
        "${API_PREFIX}/user/profile"
        "${API_PREFIX}/users/me"
        "${API_PREFIX}/profile"
    )
    
    for ENDPOINT in "${ENDPOINTS[@]}"; do
        print_step "Trying: ${API_BASE_URL}${ENDPOINT}"
        
        AUTH_RESPONSE=$(curl -s -X GET "${API_BASE_URL}${ENDPOINT}" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)
        
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_BASE_URL}${ENDPOINT}" \
            -H "Authorization: Bearer ${ACCESS_TOKEN}" 2>/dev/null)
        
        if [ "$HTTP_CODE" = "200" ]; then
            echo ""
            echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
            print_json "$AUTH_RESPONSE"
            echo ""
            print_success "Authenticated request successful!"
            break
        elif [ "$HTTP_CODE" = "404" ]; then
            print_warning "Endpoint not found, trying next..."
        else
            print_error "Request failed with HTTP $HTTP_CODE"
        fi
    done
    
    if [ "$HTTP_CODE" != "200" ]; then
        print_warning "No standard profile endpoint found"
        print_info "Testing with any protected endpoint..."
        
        echo ""
        echo -e "${BOLD}Example of successful authenticated request:${NC}"
        echo "curl -X GET ${API_BASE_URL}/api/protected \\"
        echo "  -H 'Authorization: Bearer ${ACCESS_TOKEN:0:30}...'"
        echo ""
        echo -e "${BOLD}Server validates:${NC}"
        echo "  1. Token signature (using secret key)"
        echo "  2. Token expiration (exp claim)"
        echo "  3. Token issuer (iss claim, if present)"
        echo "  4. User permissions/roles"
    fi
    
    pause
}

##############################################################################
# 5. Test Token Expiration
##############################################################################
test_token_expiration() {
    print_header "5️⃣  Token Expiration Test"
    
    print_step "Testing expired token behavior..."
    echo ""
    
    # Create an obviously expired token (exp in past)
    PAST_TIME=$(($(date +%s) - 3600))  # 1 hour ago
    
    EXPIRED_HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 | tr -d '=' | tr '+/' '-_')
    EXPIRED_PAYLOAD=$(echo -n "{\"sub\":\"test\",\"exp\":${PAST_TIME}}" | base64 | tr -d '=' | tr '+/' '-_')
    EXPIRED_TOKEN="${EXPIRED_HEADER}.${EXPIRED_PAYLOAD}.fake_signature"
    
    echo -e "${BOLD}Expired Token (created for test):${NC}"
    echo "${EXPIRED_TOKEN:0:60}..."
    echo ""
    
    print_step "Decoding expired token..."
    EXPIRED_PAYLOAD_JSON=$(decode_jwt "$EXPIRED_TOKEN" "payload")
    print_json "$EXPIRED_PAYLOAD_JSON"
    echo ""
    
    if command -v jq &> /dev/null; then
        EXP=$(echo "$EXPIRED_PAYLOAD_JSON" | jq -r '.exp' 2>/dev/null)
        if [ ! -z "$EXP" ] && [ "$EXP" != "null" ]; then
            EXP_DATE=$(date -r "$EXP" 2>/dev/null || date -d "@$EXP" 2>/dev/null)
            print_error "Token expired at: $EXP_DATE"
            
            CURRENT_TIME=$(date +%s)
            TIME_SINCE=$((CURRENT_TIME - EXP))
            print_info "Token expired $TIME_SINCE seconds ago"
        fi
    fi
    
    echo ""
    print_step "Attempting authenticated request with expired token..."
    
    EXPIRED_RESPONSE=$(curl -s -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" \
        -H "Authorization: Bearer ${EXPIRED_TOKEN}" 2>/dev/null)
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" \
        -H "Authorization: Bearer ${EXPIRED_TOKEN}" 2>/dev/null)
    
    echo ""
    echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
    print_json "$EXPIRED_RESPONSE"
    echo ""
    
    if [ "$HTTP_CODE" = "401" ]; then
        print_success "Server correctly rejected expired token (HTTP 401)"
    else
        print_warning "Expected HTTP 401, got $HTTP_CODE"
    fi
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 Token Expiration Strategy:${NC}"
    echo "• Access tokens: Short-lived (15-60 minutes)"
    echo "• Refresh tokens: Long-lived (days/weeks)"
    echo "• When access token expires, use refresh token to get new one"
    echo "• Supabase handles this automatically in Provider Search"
    
    pause
}

##############################################################################
# 6. Test Unauthorized Access
##############################################################################
test_unauthorized() {
    print_header "6️⃣  Unauthorized Access Test"
    
    print_step "Testing request without authentication..."
    echo ""
    
    UNAUTH_RESPONSE=$(curl -s -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" 2>/dev/null)
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" 2>/dev/null)
    
    echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
    print_json "$UNAUTH_RESPONSE"
    echo ""
    
    if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        print_success "Server correctly rejected unauthenticated request (HTTP $HTTP_CODE)"
    else
        print_warning "Expected HTTP 401/403, got $HTTP_CODE"
    fi
    
    echo ""
    print_step "Testing with invalid token..."
    
    INVALID_TOKEN="invalid.token.here"
    
    INVALID_RESPONSE=$(curl -s -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" \
        -H "Authorization: Bearer ${INVALID_TOKEN}" 2>/dev/null)
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_BASE_URL}${API_PREFIX}/auth/me" \
        -H "Authorization: Bearer ${INVALID_TOKEN}" 2>/dev/null)
    
    echo ""
    echo -e "${BOLD}Response (HTTP $HTTP_CODE):${NC}"
    print_json "$INVALID_RESPONSE"
    echo ""
    
    if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        print_success "Server correctly rejected invalid token (HTTP $HTTP_CODE)"
    else
        print_warning "Expected HTTP 401/403, got $HTTP_CODE"
    fi
    
    echo ""
    echo -e "${BOLD}${YELLOW}🔑 HTTP Status Codes:${NC}"
    echo "• 401 Unauthorized: Missing or invalid auth"
    echo "• 403 Forbidden: Valid auth but insufficient permissions"
    echo "• 200 OK: Successful authenticated request"
    
    pause
}

##############################################################################
# Summary
##############################################################################
show_summary() {
    print_header "📊 Authentication Flow Summary"
    
    echo -e "${BOLD}${GREEN}Complete Authentication Flow:${NC}"
    echo ""
    echo "1️⃣  User Registration"
    echo "   └─ POST /auth/register with email, password"
    echo "   └─ Server creates user, hashes password (bcrypt)"
    echo ""
    echo "2️⃣  User Login"
    echo "   └─ POST /auth/login with credentials"
    echo "   └─ Server validates, returns JWT token"
    echo ""
    echo "3️⃣  Token Storage"
    echo "   └─ ✅ Store in httpOnly cookie (secure)"
    echo "   └─ ❌ Avoid localStorage (XSS vulnerable)"
    echo ""
    echo "4️⃣  Authenticated Requests"
    echo "   └─ Include: Authorization: Bearer {token}"
    echo "   └─ Server validates signature & expiration"
    echo ""
    echo "5️⃣  Token Expiration"
    echo "   └─ Access token expires (15-60 min)"
    echo "   └─ Use refresh token to get new access token"
    echo ""
    echo "6️⃣  Logout"
    echo "   └─ Clear token from storage"
    echo "   └─ Optional: Blacklist token server-side"
    echo ""
    
    echo -e "${BOLD}${CYAN}Provider Search Implementation:${NC}"
    echo "• Supabase Auth (JWT-based)"
    echo "• FastAPI backend validates tokens"
    echo "• React frontend manages auth state"
    echo "• httpOnly cookies for security"
    echo "• Refresh token rotation"
    echo "• Rate limiting on auth endpoints"
    echo ""
    
    echo -e "${BOLD}${YELLOW}🔐 Security Checklist:${NC}"
    echo "✓ Password hashing (bcrypt/argon2)"
    echo "✓ JWT with expiration"
    echo "✓ httpOnly cookies"
    echo "✓ HTTPS only (Secure flag)"
    echo "✓ CORS configuration"
    echo "✓ Rate limiting"
    echo "✓ Input validation"
    echo "✓ SQL injection prevention"
    echo "✓ XSS protection (CSP headers)"
    echo "✓ CSRF tokens (if needed)"
    echo ""
}

##############################################################################
# Main Script
##############################################################################

main() {
    clear
    
    echo -e "${BOLD}${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║     🔐 Authentication Flow Demo - Provider Search 🔐          ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "This script demonstrates a complete authentication flow:"
    echo "  • User registration"
    echo "  • Login and token generation"
    echo "  • JWT token decoding"
    echo "  • Authenticated API requests"
    echo "  • Token expiration handling"
    echo "  • Unauthorized access testing"
    echo ""
    echo -e "${BOLD}Configuration:${NC}"
    echo "  API Base URL: $API_BASE_URL"
    echo "  API Prefix: $API_PREFIX"
    echo ""
    print_info "Make sure your FastAPI backend is running!"
    echo ""
    
    read -p "Press Enter to start..." </dev/tty
    
    # Run all tests
    preflight_check
    test_registration
    test_login
    test_token_decode
    test_authenticated_request
    test_token_expiration
    test_unauthorized
    show_summary
    
    echo ""
    print_success "Demo complete! 🎉"
    print_info "Review the logs above to understand each step"
    echo ""
}

# Run main
main
