#!/bin/bash

################################################################################
# Build Analyzer Script
# 
# Purpose: Build and analyze a frontend project's bundle
# Target: Understanding production builds and optimization
# 
# What this script does:
#   1. Runs production build
#   2. Analyzes bundle size and composition
#   3. Lists dependencies and their sizes
#   4. Checks for common issues (missing source maps, large assets)
#   5. Provides optimization recommendations
#
# Usage: ./build-analyze.sh
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

step() {
    echo -e "\n${MAGENTA}▶ $1${NC}"
}

separator() {
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
}

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              Build & Bundle Analyzer                       ║"
echo "║        Production Build Optimization Report                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

################################################################################
# Step 1: Check if we're in a valid project directory
################################################################################

step "Validating project structure..."

if [ ! -f "package.json" ]; then
    error "No package.json found! Are you in a frontend project directory?"
    echo ""
    echo "  Usage: cd your-project && ../scripts/build-analyze.sh"
    echo ""
    exit 1
fi

PROJECT_NAME=$(node -pe "require('./package.json').name")
success "Found project: ${PROJECT_NAME}"

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
    PACKAGE_MANAGER="pnpm"
elif [ -f "yarn.lock" ]; then
    PACKAGE_MANAGER="yarn"
else
    PACKAGE_MANAGER="npm"
fi

info "Using package manager: ${PACKAGE_MANAGER}"

################################################################################
# Step 2: Clean previous build
################################################################################

step "Cleaning previous build..."

if [ -d "dist" ]; then
    rm -rf dist
    success "Removed old dist/ directory"
else
    info "No previous build found"
fi

################################################################################
# Step 3: Run production build
################################################################################

step "Running production build..."

info "🐍 Think of this like: python -m build (creates optimized output)"
echo ""

BUILD_START=$(date +%s)

if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm run build
elif [ "$PACKAGE_MANAGER" == "yarn" ]; then
    yarn build
else
    npm run build
fi

BUILD_STATUS=$?
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))

echo ""

if [ $BUILD_STATUS -ne 0 ]; then
    error "Build failed!"
    exit 1
fi

success "Build completed in ${BUILD_TIME} seconds"

################################################################################
# Step 4: Analyze build output
################################################################################

step "Analyzing build output..."

if [ ! -d "dist" ]; then
    error "Build directory 'dist' not found!"
    exit 1
fi

# Calculate total size
TOTAL_SIZE=$(du -sh dist | cut -f1)
success "Total bundle size: ${TOTAL_SIZE}"

# Count files
FILE_COUNT=$(find dist -type f | wc -l | tr -d ' ')
info "Total files: ${FILE_COUNT}"

separator

################################################################################
# Step 5: Analyze JavaScript bundles
################################################################################

step "Analyzing JavaScript bundles..."

echo ""
echo -e "${CYAN}JavaScript Files:${NC}"
echo ""

# Find and display JS files with sizes
find dist -name "*.js" -type f -exec ls -lh {} \; | awk '{print $5, $9}' | while read -r size file; do
    # Color code by size
    size_bytes=$(find "$file" -type f -exec stat -f%z {} \;)
    
    if [ $size_bytes -gt 500000 ]; then
        # Large (>500KB) - red
        echo -e "  ${RED}█${NC} $size  $(basename $file)"
    elif [ $size_bytes -gt 200000 ]; then
        # Medium (>200KB) - yellow
        echo -e "  ${YELLOW}█${NC} $size  $(basename $file)"
    else
        # Small - green
        echo -e "  ${GREEN}█${NC} $size  $(basename $file)"
    fi
done

echo ""

# Check for source maps
SOURCE_MAPS=$(find dist -name "*.map" | wc -l | tr -d ' ')
if [ "$SOURCE_MAPS" -gt 0 ]; then
    success "Source maps found: ${SOURCE_MAPS} files"
    info "Source maps help debug production issues (like Python stack traces)"
else
    warning "No source maps found!"
    info "Add 'build.sourcemap: true' to vite.config.ts for debugging"
fi

separator

################################################################################
# Step 6: Analyze CSS bundles
################################################################################

step "Analyzing CSS bundles..."

echo ""
echo -e "${CYAN}CSS Files:${NC}"
echo ""

CSS_COUNT=$(find dist -name "*.css" -type f | wc -l | tr -d ' ')

if [ "$CSS_COUNT" -gt 0 ]; then
    find dist -name "*.css" -type f -exec ls -lh {} \; | awk '{print $5, $9}' | while read -r size file; do
        echo -e "  ${BLUE}█${NC} $size  $(basename $file)"
    done
else
    warning "No CSS files found (might be using CSS-in-JS)"
fi

echo ""
separator

################################################################################
# Step 7: Analyze static assets
################################################################################

step "Analyzing static assets..."

echo ""
echo -e "${CYAN}Images & Assets:${NC}"
echo ""

# Find images
IMAGES=$(find dist -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" -o -name "*.webp" \))

if [ -n "$IMAGES" ]; then
    echo "$IMAGES" | while read -r file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        size_bytes=$(stat -f%z "$file")
        
        # Warn about large images
        if [ $size_bytes -gt 500000 ]; then
            echo -e "  ${RED}█${NC} $size  $(basename $file) ${RED}(Large! Consider optimization)${NC}"
        elif [ $size_bytes -gt 200000 ]; then
            echo -e "  ${YELLOW}█${NC} $size  $(basename $file) ${YELLOW}(Consider compression)${NC}"
        else
            echo -e "  ${GREEN}█${NC} $size  $(basename $file)"
        fi
    done
else
    info "No images found in build"
fi

echo ""
separator

################################################################################
# Step 8: Analyze dependencies
################################################################################

step "Analyzing dependencies..."

echo ""
echo -e "${CYAN}Top 10 Largest Dependencies:${NC}"
echo ""

# Create a temporary analysis (requires node_modules)
if [ -d "node_modules" ]; then
    # Find largest packages
    du -sh node_modules/* 2>/dev/null | sort -rh | head -10 | while read -r size package; do
        package_name=$(basename "$package")
        echo -e "  📦 $size  $package_name"
    done
else
    warning "node_modules not found. Install dependencies to analyze them."
fi

echo ""

# List direct dependencies
DEPS_COUNT=$(node -pe "Object.keys(require('./package.json').dependencies || {}).length")
DEV_DEPS_COUNT=$(node -pe "Object.keys(require('./package.json').devDependencies || {}).length")

info "Dependencies: ${DEPS_COUNT} runtime, ${DEV_DEPS_COUNT} development"

separator

################################################################################
# Step 9: Check for common issues
################################################################################

step "Checking for common issues..."

echo ""

ISSUES_FOUND=0

# Check 1: Large bundle size
TOTAL_JS_SIZE=$(find dist -name "*.js" -type f -exec stat -f%z {} \; | awk '{sum+=$1} END {print sum}')
if [ -n "$TOTAL_JS_SIZE" ] && [ $TOTAL_JS_SIZE -gt 1000000 ]; then
    warning "Large JavaScript bundle (>1MB)"
    echo "  💡 Consider code splitting or lazy loading"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 2: Missing source maps
if [ "$SOURCE_MAPS" -eq 0 ]; then
    warning "No source maps found"
    echo "  💡 Enable source maps for easier debugging"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 3: Large images
LARGE_IMAGES=$(find dist -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -size +500k | wc -l | tr -d ' ')
if [ "$LARGE_IMAGES" -gt 0 ]; then
    warning "Found ${LARGE_IMAGES} large image(s) (>500KB)"
    echo "  💡 Use image optimization (e.g., vite-plugin-imagemin)"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 4: Unminified files
UNMINIFIED=$(find dist -name "*.js" -type f -exec grep -l "console.log" {} \; | wc -l | tr -d ' ')
if [ "$UNMINIFIED" -gt 0 ]; then
    warning "Found ${UNMINIFIED} file(s) with console.log statements"
    echo "  💡 Remove console.log in production builds"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    success "No issues found! Build looks good! 🎉"
else
    echo ""
    warning "Found ${ISSUES_FOUND} potential optimization(s)"
fi

separator

################################################################################
# Step 10: Generate recommendations
################################################################################

step "Optimization Recommendations..."

echo ""
echo -e "${CYAN}🚀 Performance Tips:${NC}"
echo ""

cat << 'EOF'
  1. Code Splitting
     - Split large bundles with dynamic import()
     - Example: const Component = lazy(() => import('./Component'))

  2. Tree Shaking
     - Import only what you need: import { func } from 'lib'
     - Avoid: import * as lib from 'lib'

  3. Compression
     - Enable gzip/brotli on your server
     - Nginx: gzip on; gzip_types text/css application/javascript;

  4. Caching
     - Vite automatically generates hashed filenames
     - Set long cache headers: Cache-Control: max-age=31536000

  5. Image Optimization
     - Use WebP format for better compression
     - Lazy load images: loading="lazy"
     - Consider using next/image or similar

  6. Bundle Analysis
     - Install: npm install -D rollup-plugin-visualizer
     - Add to vite.config.ts for visual bundle analysis

  7. Runtime Performance
     - Use React.memo() for expensive components
     - Implement virtualization for long lists
     - Profile with React DevTools

  8. HTTP/2
     - Use HTTP/2 on your server (reduces overhead of many files)
     - Modern hosting (Vercel, Netlify) enables this by default
EOF

echo ""
separator

################################################################################
# Step 11: Display final summary
################################################################################

step "Build Summary..."

echo ""

cat << EOF
$(echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}")
$(echo -e "${GREEN}║                   Build Complete!                          ║${NC}")
$(echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}")

  📦 Project:           ${PROJECT_NAME}
  📁 Output Directory:  $(pwd)/dist
  📊 Total Size:        ${TOTAL_SIZE}
  📄 Total Files:       ${FILE_COUNT}
  ⏱️  Build Time:        ${BUILD_TIME}s
  
$(echo -e "${CYAN}🚀 Deploy your build:${NC}")

  1. Static hosting (recommended for React apps):
     - Vercel: vercel deploy
     - Netlify: netlify deploy --prod
     - GitHub Pages: (copy dist/ to gh-pages branch)

  2. Traditional server:
     - Upload dist/ folder to your web server
     - Configure server to serve index.html for all routes

  3. Test locally:
     - ${PACKAGE_MANAGER} run preview
     - Opens production build at http://localhost:4173

$(echo -e "${YELLOW}💡 Pro tip: Use 'lighthouse' to audit your deployed site!${NC}")
   npx lighthouse https://your-site.com --view

EOF

separator

success "Analysis complete! 🎉"

echo ""
