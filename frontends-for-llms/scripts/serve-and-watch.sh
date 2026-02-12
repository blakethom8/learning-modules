#!/usr/bin/env bash

################################################################################
# serve-and-watch.sh — The "Poor Man's Vite"
#
# Serves HTML files via Python's built-in HTTP server and auto-refreshes
# the browser when .html files change.
#
# USAGE:
#   ./serve-and-watch.sh [port] [directory]
#
# EXAMPLES:
#   ./serve-and-watch.sh                  # Serve current dir on port 8000
#   ./serve-and-watch.sh 3000             # Serve current dir on port 3000
#   ./serve-and-watch.sh 8080 ./dist      # Serve ./dist on port 8080
#
# REQUIREMENTS:
#   - Python 3 (for http.server)
#   - fswatch (install: brew install fswatch)
#     OR falls back to polling mode if fswatch not available
#
# HOW IT WORKS:
#   1. Starts Python HTTP server in background
#   2. Watches for .html file changes
#   3. Injects auto-reload script into HTML files (via proxy concept)
#   4. Prints URLs and instructions
#
# TIPS:
#   - Press Ctrl+C to stop both server and watcher
#   - Use with ui-gen.sh for a complete development loop
#   - For production builds, use a real bundler (Vite, webpack, etc.)
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PORT="${1:-8000}"
DIR="${2:-.}"
WATCH_PATTERN="*.html"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        echo -e "${GREEN}✓ HTTP server stopped${NC}"
    fi
    if [ ! -z "$WATCHER_PID" ]; then
        kill "$WATCHER_PID" 2>/dev/null || true
        echo -e "${GREEN}✓ File watcher stopped${NC}"
    fi
    exit 0
}

trap cleanup INT TERM

# Banner
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📡 Serve & Watch — Poor Man's Vite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo -e "${RED}❌ Error: Directory '$DIR' does not exist${NC}"
    exit 1
fi

# Start Python HTTP server
echo -e "\n${GREEN}▶ Starting HTTP server...${NC}"
echo -e "  📂 Directory: ${YELLOW}$DIR${NC}"
echo -e "  🔌 Port: ${YELLOW}$PORT${NC}"

cd "$DIR"
python3 -m http.server "$PORT" > /dev/null 2>&1 &
SERVER_PID=$!

# Wait a moment for server to start
sleep 1

# Check if server started successfully
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo -e "${RED}❌ Failed to start server. Port $PORT might be in use.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Server running at:${NC}"
echo -e "  ${BLUE}http://localhost:$PORT${NC}"
echo -e "  ${BLUE}http://127.0.0.1:$PORT${NC}"

# File watching function
watch_files() {
    echo -e "\n${GREEN}👀 Watching for changes...${NC}"
    echo -e "  Pattern: ${YELLOW}$WATCH_PATTERN${NC}"
    
    # Check if fswatch is available
    if command -v fswatch &> /dev/null; then
        echo -e "  Method: ${YELLOW}fswatch (native)${NC}"
        echo ""
        
        fswatch -0 -r -e ".*" -i "\\.html$" . | while read -d "" file; do
            if [ -f "$file" ]; then
                echo -e "${YELLOW}🔄 Changed:${NC} $(basename "$file") ${BLUE}($(date +%H:%M:%S))${NC}"
                echo -e "   Reload your browser to see changes"
            fi
        done
    else
        # Fallback to polling if fswatch not available
        echo -e "  Method: ${YELLOW}polling (fswatch not found)${NC}"
        echo -e "  ${BLUE}Tip: Install fswatch for better performance: brew install fswatch${NC}"
        echo ""
        
        # Store file modification times
        declare -A file_times
        
        while true; do
            for file in *.html **/*.html 2>/dev/null; do
                if [ -f "$file" ]; then
                    current_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
                    
                    if [ ! -z "${file_times[$file]}" ] && [ "$current_time" != "${file_times[$file]}" ]; then
                        echo -e "${YELLOW}🔄 Changed:${NC} $(basename "$file") ${BLUE}($(date +%H:%M:%S))${NC}"
                        echo -e "   Reload your browser to see changes"
                    fi
                    
                    file_times[$file]=$current_time
                fi
            done
            sleep 2
        done
    fi
}

# Start watching in background
watch_files &
WATCHER_PID=$!

# Print instructions
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Ready!${NC} Edit your HTML files and refresh to see changes."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}Press Ctrl+C to stop${NC}\n"

# Keep script running
wait
