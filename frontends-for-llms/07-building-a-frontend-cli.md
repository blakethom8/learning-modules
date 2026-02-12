# Building a Frontend CLI

## Table of Contents
- [The Idea](#the-idea)
- [Architecture](#architecture)
- [Simple Implementation: Bash + Templates](#simple-implementation-bash--templates)
- [Advanced Implementation: Node.js + Watch](#advanced-implementation-nodejs--watch)
- [Integration with LLMs](#integration-with-llms)
- [What Tools Like v0 and Bolt Do](#what-tools-like-v0-and-bolt-do)
- [Building for Provider Search](#building-for-provider-search)

## The Idea

**A command-line tool that generates and serves frontend apps.**

Instead of manually:
1. Creating files
2. Writing boilerplate
3. Starting dev server
4. Opening browser

You do:
```bash
./ui-gen "dashboard with charts" --dark --port 3000
```

And get:
- Generated HTML/React app
- Dev server running
- Browser opened to localhost:3000

**Automation = speed.**

## Architecture

### Core Components

```
┌─────────────────────────────────────────┐
│           Frontend CLI Tool             │
├─────────────────────────────────────────┤
│                                         │
│  1. Input Parser                        │
│     - Parse description                 │
│     - Parse flags (--dark, --port)      │
│                                         │
│  2. Template Engine                     │
│     - Load base template                │
│     - Fill in variables                 │
│     - Add requested libraries           │
│                                         │
│  3. LLM Integration (Optional)          │
│     - Send description to LLM           │
│     - Get generated code                │
│     - Post-process output               │
│                                         │
│  4. File Generator                      │
│     - Write files to disk               │
│     - Create directory structure        │
│                                         │
│  5. Dev Server                          │
│     - Start HTTP server                 │
│     - Watch for file changes            │
│     - Auto-reload browser               │
│                                         │
└─────────────────────────────────────────┘
```

### Data Flow

```
User Input → Parse → Template/LLM → Generate Files → Serve → Browser
```

## Simple Implementation: Bash + Templates

**Goal:** Minimal viable CLI in pure bash.

### File Structure

```
ui-gen/
├── ui-gen.sh              # Main CLI script
├── templates/
│   ├── base.html          # Base template
│   ├── dark-theme.html    # Dark theme template
│   └── with-chart.html    # Template with Chart.js
└── output/                # Generated files go here
```

### Main Script: `ui-gen.sh`

```bash
#!/bin/bash

# ui-gen.sh - Generate single-file HTML apps

set -e

# Default values
DESCRIPTION=""
DARK_MODE=false
WITH_CHART=false
WITH_MAP=false
WITH_TABLE=false
OUTPUT_DIR="./output"
TEMPLATE_DIR="./templates"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dark)
      DARK_MODE=true
      shift
      ;;
    --with-chart)
      WITH_CHART=true
      shift
      ;;
    --with-map)
      WITH_MAP=true
      shift
      ;;
    --with-table)
      WITH_TABLE=true
      shift
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      DESCRIPTION="$1"
      shift
      ;;
  esac
done

# Validate description
if [ -z "$DESCRIPTION" ]; then
  echo "Usage: ./ui-gen.sh \"description\" [flags]"
  echo ""
  echo "Flags:"
  echo "  --dark          Use dark theme"
  echo "  --with-chart    Include Chart.js"
  echo "  --with-map      Include Leaflet maps"
  echo "  --with-table    Include table styling"
  echo "  --output DIR    Output directory (default: ./output)"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate filename from description
FILENAME=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '-').html
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

# Start with base template
TEMPLATE="$TEMPLATE_DIR/base.html"
if [ "$DARK_MODE" = true ]; then
  TEMPLATE="$TEMPLATE_DIR/dark-theme.html"
fi

# Copy template
cp "$TEMPLATE" "$OUTPUT_FILE"

# Add Chart.js if requested
if [ "$WITH_CHART" = true ]; then
  sed -i '' '/<\/head>/i\
    <script src="https://cdn.jsdelivr.net/npm/chart.js"><\/script>
' "$OUTPUT_FILE"
fi

# Add Leaflet if requested
if [ "$WITH_MAP" = true ]; then
  sed -i '' '/<\/head>/i\
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />\
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"><\/script>
' "$OUTPUT_FILE"
fi

# Replace title with description
sed -i '' "s/<title>.*<\/title>/<title>$DESCRIPTION<\/title>/" "$OUTPUT_FILE"

# Replace h1 with description
sed -i '' "s/<h1>.*<\/h1>/<h1>$DESCRIPTION<\/h1>/" "$OUTPUT_FILE"

echo "✓ Generated: $OUTPUT_FILE"

# Open in browser
open "$OUTPUT_FILE"

echo "✓ Opened in browser"
```

### Base Template: `templates/base.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="min-h-screen p-8">
    
    <div x-data="app()" class="max-w-6xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">My App</h1>
        
        <!-- Add your content here -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="border rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 1</h2>
                <p class="text-gray-600">Description here</p>
            </div>
            <div class="border rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 2</h2>
                <p class="text-gray-600">Description here</p>
            </div>
            <div class="border rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 3</h2>
                <p class="text-gray-600">Description here</p>
            </div>
        </div>
        
    </div>
    
    <script>
        function app() {
            return {
                message: 'Hello, World!'
            };
        }
    </script>
    
</body>
</html>
```

### Dark Theme Template: `templates/dark-theme.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-900 text-white min-h-screen p-8">
    
    <div x-data="app()" class="max-w-6xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">My App</h1>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
                <h2 class="text-xl font-bold mb-2">Feature 1</h2>
                <p class="text-gray-400">Description here</p>
            </div>
            <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
                <h2 class="text-xl font-bold mb-2">Feature 2</h2>
                <p class="text-gray-400">Description here</p>
            </div>
            <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
                <h2 class="text-xl font-bold mb-2">Feature 3</h2>
                <p class="text-gray-400">Description here</p>
            </div>
        </div>
        
    </div>
    
    <script>
        function app() {
            return {
                message: 'Hello, World!'
            };
        }
    </script>
    
</body>
</html>
```

### Usage

```bash
# Basic usage
./ui-gen.sh "Admin Dashboard"

# With flags
./ui-gen.sh "Analytics Dashboard" --dark --with-chart

# With map
./ui-gen.sh "Provider Locations" --dark --with-map

# All options
./ui-gen.sh "Data Explorer" --dark --with-chart --with-table
```

**Result:** Instant single-file HTML apps with CDN libraries.

## Advanced Implementation: Node.js + Watch

**Goal:** More powerful CLI with file watching and hot reload.

### Setup

```bash
mkdir frontend-cli
cd frontend-cli
npm init -y
npm install express chokidar open chalk commander
```

### Main Script: `cli.js`

```javascript
#!/usr/bin/env node

const { Command } = require('commander');
const fs = require('fs');
const path = require('path');
const express = require('express');
const chokidar = require('chokidar');
const open = require('open');
const chalk = require('chalk');

const program = new Command();

program
  .name('ui-gen')
  .description('Generate and serve frontend apps')
  .argument('<description>', 'App description')
  .option('-d, --dark', 'Use dark theme')
  .option('-p, --port <port>', 'Dev server port', '3000')
  .option('-o, --output <dir>', 'Output directory', './output')
  .option('--no-serve', 'Generate files only, don\'t serve')
  .option('--with-chart', 'Include Chart.js')
  .option('--with-map', 'Include Leaflet maps')
  .action((description, options) => {
    generateApp(description, options);
  });

program.parse();

function generateApp(description, options) {
  const { dark, port, output, serve, withChart, withMap } = options;
  
  // Create output directory
  if (!fs.existsSync(output)) {
    fs.mkdirSync(output, { recursive: true });
  }
  
  // Generate filename
  const filename = description.toLowerCase().replace(/\s+/g, '-') + '.html';
  const filepath = path.join(output, filename);
  
  // Load template
  const templateName = dark ? 'dark-theme.html' : 'base.html';
  const templatePath = path.join(__dirname, 'templates', templateName);
  let content = fs.readFileSync(templatePath, 'utf8');
  
  // Replace title and heading
  content = content.replace(/<title>.*<\/title>/, `<title>${description}</title>`);
  content = content.replace(/<h1>.*<\/h1>/, `<h1 class="text-4xl font-bold mb-8">${description}</h1>`);
  
  // Add libraries
  const additions = [];
  if (withChart) {
    additions.push('<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>');
  }
  if (withMap) {
    additions.push('<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />');
    additions.push('<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>');
  }
  
  if (additions.length > 0) {
    content = content.replace('</head>', additions.join('\n    ') + '\n</head>');
  }
  
  // Write file
  fs.writeFileSync(filepath, content);
  console.log(chalk.green('✓') + ` Generated: ${filepath}`);
  
  if (serve) {
    startDevServer(output, port, filepath);
  }
}

function startDevServer(dir, port, initialFile) {
  const app = express();
  
  // Serve static files
  app.use(express.static(dir));
  
  // Auto-reload script injector
  app.get('*.html', (req, res, next) => {
    const filePath = path.join(dir, req.path);
    if (fs.existsSync(filePath)) {
      let content = fs.readFileSync(filePath, 'utf8');
      
      // Inject auto-reload script
      const reloadScript = `
        <script>
          const ws = new WebSocket('ws://localhost:${parseInt(port) + 1}');
          ws.onmessage = () => location.reload();
        </script>
      `;
      content = content.replace('</body>', reloadScript + '</body>');
      
      res.send(content);
    } else {
      next();
    }
  });
  
  // Start server
  app.listen(port, () => {
    console.log(chalk.green('✓') + ` Server running at http://localhost:${port}`);
    open(`http://localhost:${port}/${path.basename(initialFile)}`);
  });
  
  // Watch for changes
  const watcher = chokidar.watch(dir, {
    ignored: /node_modules/,
    persistent: true
  });
  
  // WebSocket server for reload notifications
  const WebSocket = require('ws');
  const wss = new WebSocket.Server({ port: parseInt(port) + 1 });
  
  watcher.on('change', (filepath) => {
    console.log(chalk.yellow('↻') + ` File changed: ${path.basename(filepath)}`);
    wss.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send('reload');
      }
    });
  });
  
  console.log(chalk.blue('👀') + ' Watching for changes...');
}
```

### Make it executable

```bash
chmod +x cli.js
npm link  # Install globally
```

### Usage

```bash
# Generate and serve
ui-gen "Dashboard" --dark --with-chart

# Generate only (no server)
ui-gen "Dashboard" --no-serve

# Custom port
ui-gen "Dashboard" --port 8080
```

**Result:** 
- Generated file
- Dev server running
- Browser opens automatically
- Auto-reloads on file changes

## Integration with LLMs

**Level up:** Pipe user descriptions through an LLM before templating.

### Enhanced CLI with LLM

```bash
#!/bin/bash

DESCRIPTION="$1"

# Send to Claude
PROMPT="Create a single-file HTML app: $DESCRIPTION. 
Use Tailwind CSS via CDN. Include Alpine.js for interactivity.
Make it dark themed. Return only the HTML code, no explanation."

# Call Claude (requires claude-cli)
claude -p "$PROMPT" > output/app.html

echo "✓ Generated with Claude: output/app.html"
open output/app.html
```

### Node.js with LLM Integration

```javascript
const { Anthropic } = require('@anthropic-ai/sdk');

async function generateWithLLM(description, options) {
  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });
  
  const prompt = `Create a single-file HTML app: ${description}.
Requirements:
- Use Tailwind CSS via CDN
- ${options.dark ? 'Dark theme (bg-gray-900)' : 'Light theme'}
- ${options.withChart ? 'Include Chart.js via CDN and add a sample chart' : ''}
- ${options.withMap ? 'Include Leaflet via CDN and add a sample map' : ''}
- Use Alpine.js for interactivity
- Modern, professional design

Return only the HTML code, no explanation or markdown.`;

  const response = await anthropic.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 4000,
    messages: [{
      role: 'user',
      content: prompt
    }]
  });
  
  return response.content[0].text;
}

// Modify generateApp function:
async function generateApp(description, options) {
  console.log(chalk.blue('🤖') + ' Generating with Claude...');
  
  const content = await generateWithLLM(description, options);
  
  const filename = description.toLowerCase().replace(/\s+/g, '-') + '.html';
  const filepath = path.join(options.output, filename);
  
  fs.writeFileSync(filepath, content);
  console.log(chalk.green('✓') + ` Generated: ${filepath}`);
  
  if (options.serve) {
    startDevServer(options.output, options.port, filepath);
  }
}
```

**Usage:**
```bash
ui-gen "Analytics dashboard with revenue chart and user metrics" --dark
```

**Result:** LLM generates a fully custom app based on your description.

## What Tools Like v0 and Bolt Do

**Under the hood, these tools follow the same pattern:**

### v0 by Vercel

```
1. User describes UI in web interface
2. Send description to LLM (GPT-4/Claude)
3. LLM generates React/Next.js code
4. Post-process: format, add imports, wrap in page structure
5. Render preview in iframe (WebContainer)
6. User can copy code or deploy to Vercel
```

### Bolt.new by StackBlitz

```
1. User describes full-stack app
2. Send to LLM with system prompt for file structure
3. LLM generates multiple files (frontend + backend)
4. Run in WebContainer (Node.js in browser)
5. Render live preview
6. User iterates with follow-up prompts
```

### Key Components

**All these tools use:**
1. **LLM API** (OpenAI, Anthropic, or custom)
2. **Template engine** (base structure + LLM fills details)
3. **Code post-processor** (format, add imports, inject reload script)
4. **Isolated runtime** (iframe, WebContainer, or Docker)
5. **File watcher** (detect changes, trigger reload)

**You can build a simpler version with:**
- Claude Code (LLM)
- Express (dev server)
- Chokidar (file watcher)
- Open (browser launcher)

## Building for Provider Search

**Custom CLI for internal tool generation:**

### `ui-gen` for Provider Search

```bash
#!/bin/bash

# ui-gen - Generate Provider Search internal tools

TOOL_NAME="$1"

case $TOOL_NAME in
  "debug-panel")
    claude -p "Create a single-file HTML debug panel for Provider Search API.
    Include: request builder, response viewer, auth token input,
    endpoint selector (GET /api/providers, POST /api/bookings, etc).
    Dark theme, Tailwind CSS." > tools/debug-panel.html
    open tools/debug-panel.html
    ;;
    
  "data-viewer")
    claude -p "Create a single-file HTML data viewer for Provider Search.
    Table showing all providers with: name, specialty, rating, status.
    Search and filter functionality.
    Export to CSV button.
    Dark theme, Tailwind CSS." > tools/data-viewer.html
    open tools/data-viewer.html
    ;;
    
  "map-tester")
    claude -p "Create a single-file HTML map testing tool.
    Leaflet map with ability to add/remove markers manually.
    Test clustering, popups, styling.
    Dark theme." > tools/map-tester.html
    open tools/map-tester.html
    ;;
    
  *)
    echo "Unknown tool: $TOOL_NAME"
    echo "Available tools: debug-panel, data-viewer, map-tester"
    exit 1
    ;;
esac

echo "✓ Generated: tools/$TOOL_NAME.html"
```

### Usage

```bash
# Generate debug panel
./ui-gen debug-panel

# Generate data viewer
./ui-gen data-viewer

# Generate map tester
./ui-gen map-tester
```

**Benefit:** Team members can generate internal tools on-demand without writing code.

## Key Takeaways

1. **A frontend CLI automates generation and serving**
2. **Simple version: Bash + templates + HTTP server**
3. **Advanced version: Node.js + file watcher + hot reload**
4. **LLM integration: pipe descriptions through Claude/GPT**
5. **v0/Bolt/Replit use the same pattern** at larger scale
6. **Build custom CLI for your project** — generate internal tools fast
7. **The goal: reduce "idea to running code" time to seconds**

---

**Try This Now:**

Build the simple bash version:

1. Create `ui-gen.sh` from the script above
2. Create `templates/` directory with base.html
3. Run: `./ui-gen.sh "My Dashboard" --dark`
4. See instant results

Then extend it:
- Add more templates (with-form.html, with-modal.html)
- Add more flags (--with-auth, --with-api)
- Integrate Claude for custom generation

**Goal:** Your own personal frontend generator in under an hour.

→ That's all 8 guides! Now explore the interactive tools and scripts.
