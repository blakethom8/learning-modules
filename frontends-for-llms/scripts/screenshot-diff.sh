#!/usr/bin/env bash

################################################################################
# screenshot-diff.sh — Visual Regression Testing for Quick Iterations
#
# Takes screenshots of a URL and compares them to track visual changes.
# Perfect for iterating on LLM-generated frontends.
#
# USAGE:
#   ./screenshot-diff.sh <url> [name] [action]
#
# ACTIONS:
#   before      - Capture initial "before" screenshot (default if none exists)
#   after       - Capture "after" screenshot and show diff
#   compare     - Compare existing before/after screenshots
#   clean       - Remove all screenshots for this name
#   list        - List all saved screenshots
#
# EXAMPLES:
#   # First iteration: capture baseline
#   ./screenshot-diff.sh http://localhost:8000 dashboard
#   
#   # After making changes: capture new version and compare
#   ./screenshot-diff.sh http://localhost:8000 dashboard after
#   
#   # Compare existing screenshots
#   ./screenshot-diff.sh http://localhost:8000 dashboard compare
#   
#   # Clean up
#   ./screenshot-diff.sh http://localhost:8000 dashboard clean
#
# REQUIREMENTS:
#   Choose ONE of the following (script auto-detects):
#   
#   Option 1: playwright (recommended)
#     npm install -g playwright
#     playwright install chromium
#   
#   Option 2: puppeteer-cli
#     npm install -g puppeteer-cli
#   
#   Option 3: screenshot (macOS utility, basic)
#     brew install screenshot
#   
#   Option 4: webkit2png (macOS, fallback)
#     brew install webkit2png
#
# OUTPUT:
#   Screenshots saved to: ./screenshots/
#   - {name}-before.png
#   - {name}-after.png
#   - {name}-diff.png (if ImageMagick available)
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCREENSHOT_DIR="./screenshots"
DEFAULT_WIDTH=1920
DEFAULT_HEIGHT=1080

# Parse arguments
URL="${1:-}"
NAME="${2:-page}"
ACTION="${3:-auto}"

# Show usage if no URL provided
if [ -z "$URL" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📸 Screenshot Diff — Visual Comparison Tool${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./screenshot-diff.sh <url> [name] [action]"
    echo ""
    echo -e "${YELLOW}Actions:${NC}"
    echo -e "  before   - Capture 'before' screenshot"
    echo -e "  after    - Capture 'after' screenshot and compare"
    echo -e "  compare  - Compare existing screenshots"
    echo -e "  clean    - Remove screenshots for this name"
    echo -e "  list     - List all screenshots"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ./screenshot-diff.sh http://localhost:8000 dashboard"
    echo -e "  ./screenshot-diff.sh http://localhost:8000 dashboard after"
    echo ""
    exit 1
fi

# Handle list action
if [ "$ACTION" = "list" ]; then
    echo -e "${BLUE}📋 Saved screenshots:${NC}"
    if [ -d "$SCREENSHOT_DIR" ]; then
        ls -lh "$SCREENSHOT_DIR"
    else
        echo -e "${YELLOW}No screenshots directory found${NC}"
    fi
    exit 0
fi

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"

# Define file paths
BEFORE_FILE="$SCREENSHOT_DIR/${NAME}-before.png"
AFTER_FILE="$SCREENSHOT_DIR/${NAME}-after.png"
DIFF_FILE="$SCREENSHOT_DIR/${NAME}-diff.png"

# Detect available screenshot tool
detect_tool() {
    if command -v playwright &> /dev/null; then
        echo "playwright"
    elif command -v puppeteer &> /dev/null; then
        echo "puppeteer"
    elif command -v shot &> /dev/null; then
        echo "shot"
    elif command -v webkit2png &> /dev/null; then
        echo "webkit2png"
    else
        echo "none"
    fi
}

TOOL=$(detect_tool)

if [ "$TOOL" = "none" ]; then
    echo -e "${RED}❌ No screenshot tool found!${NC}"
    echo ""
    echo -e "${YELLOW}Install one of:${NC}"
    echo -e "  • playwright: ${BLUE}npm install -g playwright && playwright install chromium${NC}"
    echo -e "  • puppeteer:  ${BLUE}npm install -g puppeteer-cli${NC}"
    echo -e "  • shot:       ${BLUE}brew install shot${NC}"
    echo -e "  • webkit2png: ${BLUE}brew install webkit2png${NC}"
    echo ""
    exit 1
fi

# Take screenshot based on tool
take_screenshot() {
    local url=$1
    local output=$2
    
    echo -e "${GREEN}📸 Capturing screenshot with $TOOL...${NC}"
    
    case "$TOOL" in
        playwright)
            npx playwright screenshot \
                --viewport-size="${DEFAULT_WIDTH},${DEFAULT_HEIGHT}" \
                --full-page \
                "$url" "$output"
            ;;
        puppeteer)
            puppeteer screenshot \
                --viewport "${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}" \
                "$url" "$output"
            ;;
        shot)
            shot --width "$DEFAULT_WIDTH" --height "$DEFAULT_HEIGHT" \
                "$url" --output "$output"
            ;;
        webkit2png)
            webkit2png -F -W "$DEFAULT_WIDTH" -H "$DEFAULT_HEIGHT" \
                --output="$output" "$url"
            # webkit2png adds suffix, rename it
            if [ -f "${output}-full.png" ]; then
                mv "${output}-full.png" "$output"
            fi
            ;;
    esac
    
    if [ -f "$output" ]; then
        local size=$(du -h "$output" | cut -f1)
        echo -e "${GREEN}✓ Saved: ${BLUE}$output${NC} (${size})"
    else
        echo -e "${RED}❌ Failed to capture screenshot${NC}"
        exit 1
    fi
}

# Compare images (if ImageMagick available)
compare_screenshots() {
    if ! command -v compare &> /dev/null; then
        echo -e "${YELLOW}⚠ ImageMagick not found (brew install imagemagick)${NC}"
        echo -e "${YELLOW}Skipping visual diff...${NC}"
        return
    fi
    
    if [ ! -f "$BEFORE_FILE" ] || [ ! -f "$AFTER_FILE" ]; then
        echo -e "${YELLOW}⚠ Need both before and after screenshots to compare${NC}"
        return
    fi
    
    echo -e "${GREEN}🔍 Generating diff...${NC}"
    
    # Generate diff with ImageMagick
    compare -metric AE -fuzz 5% \
        "$BEFORE_FILE" "$AFTER_FILE" "$DIFF_FILE" 2>/dev/null || true
    
    if [ -f "$DIFF_FILE" ]; then
        local size=$(du -h "$DIFF_FILE" | cut -f1)
        echo -e "${GREEN}✓ Diff saved: ${BLUE}$DIFF_FILE${NC} (${size})"
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}📊 Comparison complete!${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  Before: ${YELLOW}$BEFORE_FILE${NC}"
        echo -e "  After:  ${YELLOW}$AFTER_FILE${NC}"
        echo -e "  Diff:   ${YELLOW}$DIFF_FILE${NC}"
        echo ""
        echo -e "${BLUE}Open these files to see the differences.${NC}"
        
        # Try to open diff automatically (macOS)
        if command -v open &> /dev/null; then
            echo -e "\n${YELLOW}Opening diff in preview...${NC}"
            open "$DIFF_FILE"
        fi
    fi
}

# Handle clean action
if [ "$ACTION" = "clean" ]; then
    echo -e "${YELLOW}🧹 Cleaning screenshots for: $NAME${NC}"
    rm -f "$BEFORE_FILE" "$AFTER_FILE" "$DIFF_FILE"
    echo -e "${GREEN}✓ Cleaned${NC}"
    exit 0
fi

# Handle compare action
if [ "$ACTION" = "compare" ]; then
    echo -e "${BLUE}🔍 Comparing existing screenshots: $NAME${NC}"
    compare_screenshots
    exit 0
fi

# Determine action automatically if needed
if [ "$ACTION" = "auto" ]; then
    if [ -f "$BEFORE_FILE" ]; then
        ACTION="after"
    else
        ACTION="before"
    fi
    echo -e "${BLUE}Auto-detected action: ${YELLOW}$ACTION${NC}"
fi

# Banner
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📸 Screenshot Diff${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  URL:  ${YELLOW}$URL${NC}"
echo -e "  Name: ${YELLOW}$NAME${NC}"
echo -e "  Tool: ${YELLOW}$TOOL${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Execute action
case "$ACTION" in
    before)
        echo -e "\n${GREEN}Taking 'before' screenshot...${NC}"
        take_screenshot "$URL" "$BEFORE_FILE"
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✨ Baseline captured!${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Make your changes, then run:"
        echo -e "  ${YELLOW}./screenshot-diff.sh $URL $NAME after${NC}"
        ;;
        
    after)
        if [ ! -f "$BEFORE_FILE" ]; then
            echo -e "${YELLOW}⚠ No 'before' screenshot found. Taking one now...${NC}"
            take_screenshot "$URL" "$BEFORE_FILE"
            echo ""
            echo -e "${BLUE}Now make your changes and run this command again.${NC}"
            exit 0
        fi
        
        echo -e "\n${GREEN}Taking 'after' screenshot...${NC}"
        take_screenshot "$URL" "$AFTER_FILE"
        echo ""
        compare_screenshots
        ;;
        
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        echo -e "Valid actions: before, after, compare, clean, list"
        exit 1
        ;;
esac
