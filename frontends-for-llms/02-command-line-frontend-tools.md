# Command-Line Frontend Tools

## Table of Contents
- [The Command-Line Frontend Workflow](#the-command-line-frontend-workflow)
- [Claude Code](#claude-code)
- [Codex CLI](#codex-cli)
- [Pi/OpenClaw Agent](#piopenclaw-agent)
- [v0 by Vercel](#v0-by-vercel)
- [Other AI Frontend Builders](#other-ai-frontend-builders)
- [The Spectrum](#the-spectrum)
- [Comparison Table](#comparison-table)
- [Our Workflow](#our-workflow)
- [Setting Up Your Feedback Loop](#setting-up-your-feedback-loop)

## The Command-Line Frontend Workflow

The terminal is the fastest way to work with AI coding tools:

```bash
# Describe what you want
claude "Build a React dashboard component with charts"

# Get code back
# Review, test, iterate

# Refine with follow-up
claude "Add a date range picker to filter the data"
```

**Why command-line beats web interfaces:**

✅ **Faster** — no clicking, no context switching  
✅ **Scriptable** — automate repetitive tasks  
✅ **Version controlled** — integrate with git workflows  
✅ **Composable** — pipe outputs, chain commands  
✅ **Works in your editor** — stay in your flow  

## Claude Code

**Claude Code** is Anthropic's command-line tool for AI-assisted coding.

### Installation

```bash
npm install -g claude-code
# or
brew install claude-code

# Authenticate
claude auth
```

### Basic Usage for Frontend

**Non-interactive mode** (best for quick generation):

```bash
claude -p "Create a React login form with email, password, 
remember me checkbox, and submit button. Use Tailwind CSS. 
Include client-side validation."
```

**Interactive mode** (for back-and-forth refinement):

```bash
claude "Build me a dashboard component"
# Claude responds with questions or code
# You can follow up in the same session
```

### Frontend-Specific Patterns

**Single-file HTML:**
```bash
claude -p "Create a single-file HTML page with a kanban board. 
Use Tailwind via CDN, Alpine.js for interactivity. Include 
3 columns: To Do, In Progress, Done. Make cards draggable."

# Save output
claude -p "..." > kanban.html
```

**React Component:**
```bash
claude -p "Create a TypeScript React component called MetricCard 
that displays a title, value, and percentage change. Use Tailwind. 
Props: title (string), value (number), change (number), isPositive (boolean)."
```

**Iterative refinement:**
```bash
# Start
claude "Create a data table component with sort functionality"

# In the same session:
"Add pagination"
"Add a search box"
"Export the data to CSV when user clicks export button"
```

### Tips for Claude Code

1. **Be specific about framework and styling:** "React + TypeScript + Tailwind"
2. **Request single-file when prototyping:** "Create as single-file HTML"
3. **Specify dark/light theme:** Claude defaults to light unless told
4. **Ask for responsive design:** "Make it responsive, mobile-friendly"
5. **Use `-p` for scripts:** Non-interactive mode plays better with automation

### Example: Building a Provider Search Component

```bash
claude -p "Create a React TypeScript component called ProviderCard.
Props: name, specialty, rating, location, imageUrl, acceptingPatients.
Layout: 
- Left: circular avatar image
- Middle: name (h3), specialty (gray text), location with pin icon
- Right: rating stars and 'View Profile' button
Use Tailwind CSS, dark theme (bg-gray-800), modern card design."

# Output goes to stdout, save to file:
claude -p "..." > src/components/ProviderCard.tsx
```

**Result:** Production-ready component in seconds.

## Codex CLI

**Codex CLI** is OpenAI's command-line interface, powered by GPT models with high reasoning.

### Installation

```bash
# Install via OpenAI CLI tools
pip install openai-codex-cli

# Or use via API wrapper
npm install -g openai-codex
```

### Basic Usage

```bash
codex exec "Create a dashboard page with analytics charts"
```

### Frontend-Specific Patterns

**With context from existing files:**
```bash
codex exec "Look at src/components/SearchBar.tsx and create a 
similar FilterPanel component with category, rating, and distance filters."
```

**Multi-step generation:**
```bash
codex exec "
Step 1: Create a React hook called useProviderSearch that:
- Accepts search query, filters as params
- Fetches from /api/providers endpoint
- Returns { data, loading, error }

Step 2: Create a component that uses this hook and displays results in a grid.
"
```

### Codex vs Claude for Frontend

| Feature | Claude Code | Codex CLI |
|---------|-------------|-----------|
| **Model** | Claude Sonnet/Opus | GPT-4.5/5 |
| **Speed** | Fast | Fast |
| **Code quality** | Excellent | Excellent |
| **Reasoning** | Good | Excellent (xhigh mode) |
| **Context window** | 200K | 128K+ |
| **Best for** | General frontend, React | Complex logic, algorithms |

**Rule of thumb:** Use Claude Code by default, Codex when you need deeper reasoning or algorithmic complexity.

## Pi/OpenClaw Agent

**OpenClaw** is Blake's Pi-based agent harness — a bash-first AI assistant that can invoke tools.

### How It Works

OpenClaw runs as a daemon and responds to commands via:
- Telegram messages
- Web chat
- API calls

For frontend work, OpenClaw acts as an **orchestrator**:

```
You: "Build me a dashboard page for provider analytics"

OpenClaw (Chief):
1. Uses file tools to check existing code structure
2. Invokes Claude Code to generate the component
3. Saves to correct directory
4. Updates imports and routes
5. Runs the dev server
6. Opens browser to preview
7. Reports back: "Done — preview at localhost:3000/analytics"
```

### The "Bash is All You Need" Philosophy

OpenClaw demonstrates that **file I/O + LLM calls = powerful automation**:

```bash
# Traditional approach:
# 1. Open editor
# 2. Create file
# 3. Write/paste code
# 4. Save
# 5. Manually test

# OpenClaw approach:
# 1. Ask: "Create a component for X"
# 2. Done.
```

### Example: Asking OpenClaw to Build a Frontend

**Via Telegram:**
```
You: Build a single-file HTML tool for testing API endpoints. 
     Should have URL input, method dropdown, headers editor, 
     body editor, send button, and response viewer. Dark theme.

Chief: [generates code with Claude]
       [saves to ~/Repo/provider-search/tools/api-tester.html]
       [opens in browser]
       Done — saved to tools/api-tester.html and opened in browser.
```

### When to Use OpenClaw

✅ **You want full automation** — create file + save + test + commit  
✅ **You want context awareness** — OpenClaw knows your project structure  
✅ **You want orchestration** — multiple tools, multiple steps  
✅ **You're on mobile** — Telegram interface works anywhere  

## v0 by Vercel

**v0** is Vercel's web-based AI UI generator.

### How It Works

1. Go to v0.dev
2. Describe your UI in the prompt box
3. Get instant preview
4. Copy code to your project

### Strengths

✅ **Visual preview** — see it immediately, no local setup  
✅ **Vercel-optimized** — generates Next.js components  
✅ **Iteration UI** — built-in refinement flow  
✅ **Sharing** — send link to preview  

### Weaknesses

❌ **Web-only** — not scriptable or command-line friendly  
❌ **Locked to Next.js** — not great for non-Vercel stacks  
❌ **Rate limits** — free tier is limited  
❌ **Context-free** — doesn't know your codebase  

### When to Use v0

✅ Starting a brand new Next.js project  
✅ You want visual feedback before coding  
✅ Sharing prototypes with non-technical stakeholders  

**For Provider Search:** We don't use v0 much because we're not on Next.js and prefer terminal workflows.

## Other AI Frontend Builders

### Bolt.new

**What it is:** Full-stack web app builder by StackBlitz

**How it works:** Describe app → get working full-stack project in WebContainer

**Strengths:**
- Builds entire apps, not just components
- Runs in browser (WebContainer magic)
- Includes backend logic

**Weaknesses:**
- Browser-only, can't export easily
- Free tier limits
- Proprietary platform

### Lovable (formerly GPT Engineer)

**What it is:** AI app builder focused on rapid prototyping

**How it works:** Conversational interface → generates full app → deploy

**Strengths:**
- Multi-page apps
- Deployment included
- Handles routing, state, backend

**Weaknesses:**
- Less control over output
- Platform lock-in
- Not command-line friendly

### Replit Agent

**What it is:** AI coding assistant inside Replit IDE

**How it works:** Chat with agent → it writes code in your Replit project

**Strengths:**
- Integrated dev environment
- Can run and test code instantly
- Collaborative (multi-user)

**Weaknesses:**
- Tied to Replit platform
- Less powerful than Claude/GPT directly
- Monthly subscription required

### GitHub Copilot

**What it is:** AI pair programmer as IDE extension

**How it works:** Autocomplete on steroids + chat panel

**Strengths:**
- Inline suggestions as you type
- Deeply integrated with VS Code
- Great for incremental coding

**Weaknesses:**
- Not great for "generate full component" workflows
- Requires typing to trigger suggestions
- Less effective for beginners who don't know what to type

## The Spectrum

AI frontend tools exist on a spectrum:

```
Fully Manual ←→ AI-Assisted ←→ Fully AI-Generated
```

**Fully Manual:**
- Write every line yourself
- Use docs and Stack Overflow
- Traditional coding

**AI-Assisted:**
- You write structure, AI fills details
- GitHub Copilot autocomplete
- Ask AI for specific functions

**Fully AI-Generated:**
- Describe intent, AI produces everything
- Claude Code, Codex, v0, Bolt
- Review and refine output

**Where Provider Search sits:** AI-Generated with manual refinement

We generate most UI code with AI, then:
- Review for correctness
- Add business logic
- Integrate with backend
- Add tests and error handling

**80% AI-generated, 20% human polish.**

## Comparison Table

| Tool | Speed | Control | Context | Scripting | Best For |
|------|-------|---------|---------|-----------|----------|
| **Claude Code** | ⚡⚡⚡ | ⭐⭐⭐ | ⭐⭐ | ✅ Yes | React components, single-file HTML |
| **Codex CLI** | ⚡⚡⚡ | ⭐⭐⭐ | ⭐⭐ | ✅ Yes | Complex logic, algorithms |
| **OpenClaw** | ⚡⚡ | ⭐⭐⭐ | ⭐⭐⭐ | ✅ Yes | Full automation, orchestration |
| **v0** | ⚡⚡⚡ | ⭐⭐ | ⭐ | ❌ No | Next.js projects, visual preview |
| **Bolt.new** | ⚡⚡ | ⭐ | ⭐ | ❌ No | Full-stack prototypes |
| **Lovable** | ⚡⚡ | ⭐ | ⭐ | ❌ No | MVP apps, fast demos |
| **Replit Agent** | ⚡⚡ | ⭐⭐ | ⭐⭐ | ⚡ Partial | Learning, collaboration |
| **Copilot** | ⚡ | ⭐⭐⭐ | ⭐⭐⭐ | ❌ No | Incremental coding, autocomplete |

## Our Workflow

**Provider Search uses:**

### Primary: Claude Code
```bash
# Generate components
claude -p "Create ProviderCard component..." > src/components/ProviderCard.tsx

# Generate pages
claude -p "Create dashboard page..." > src/pages/Dashboard.tsx

# Generate utilities
claude -p "Create a function that formats addresses..." > src/utils/format.ts
```

### Secondary: OpenClaw (Chief)
```
Via Telegram:
"Chief, build a debug panel for testing auth flows"
"Chief, create a single-file HTML tool for testing map markers"
```

### Fallback: Codex CLI
```bash
# When Claude struggles with complex logic
codex exec "Write an algorithm to cluster nearby providers efficiently..."
```

### Never: Web-only tools (v0, Bolt, Lovable)

Why? **Terminal workflows are faster and more scriptable.**

## Setting Up Your Feedback Loop

The goal: **minimize time between "I want X" and "X is running in my browser"**

### Optimal Setup

**1. Terminal-based code generation:**
```bash
# Generate code
claude -p "..." > component.tsx
```

**2. Dev server with hot reload:**
```bash
# Separate terminal window, always running
npm run dev
```

**3. Browser with auto-refresh:**
```bash
# Browser window positioned next to terminal
# Vite/webpack dev server auto-refreshes on file save
```

**4. Iterate:**
```bash
# Generate → Save → Browser refreshes (1-2 seconds)
# Review → Prompt for changes → Repeat
```

### The Ideal Loop: Under 10 Seconds

```
Prompt → Generate (2s) → Save (1s) → Refresh (2s) → Review (5s) = 10s
```

Compare to traditional:
```
Think → Write (5 min) → Debug (10 min) → Review (2 min) = 17 min
```

**100x faster for prototypes.**

### Pro Tip: Use Aliases

```bash
# Add to ~/.zshrc or ~/.bashrc
alias ui="claude -p"
alias uigen="claude -p"

# Now:
uigen "Create a button component" > Button.tsx
```

### Pro Tip: Serve Script

Create a `serve.sh` in your project:

```bash
#!/bin/bash
# Open browser and start dev server
open http://localhost:3000 &
npm run dev
```

**One command to start everything.**

## Key Takeaways

1. **Command-line tools are faster than web UIs** for AI frontend work
2. **Claude Code is the workhorse** — use it for most React/HTML generation
3. **Codex for complex logic** that requires deep reasoning
4. **OpenClaw for orchestration** — multiple steps, full automation
5. **v0/Bolt/Lovable are for visual demos**, not production workflows
6. **Optimize your feedback loop** — faster iteration = better UIs
7. **Terminal + dev server + browser** = the ideal setup

---

**Try This Now:**

Set up your optimal feedback loop:

```bash
# Terminal 1: Start dev server
cd ~/Repo/provider-search
npm run dev

# Terminal 2: Generate a component
claude -p "Create a React card component with image, title, 
description, and CTA button. Use Tailwind CSS." > src/components/Card.tsx

# Import it in a test page and see it render instantly
```

Time yourself. How fast can you go from prompt to working UI?

→ Next: [Single-File HTML Apps](03-single-file-html-apps.md)
