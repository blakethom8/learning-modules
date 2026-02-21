# Web-MCP: Building Agent-Friendly Web Applications

## Table of Contents
- [The Shift: From UI-First to Agent-First](#the-shift-from-ui-first-to-agent-first)
- [What is MCP and Why It Matters for Web Apps](#what-is-mcp-and-why-it-matters-for-web-apps)
- [The Cross-Browser Challenge](#the-cross-browser-challenge)
- [Making Your Web App Agent-Friendly](#making-your-web-app-agent-friendly)
- [Practical Architecture: The CRUD/CRM Case Study](#practical-architecture-the-crudcrm-case-study)
- [Implementation Patterns](#implementation-patterns)
- [The Spectrum: When to Use What](#the-spectrum-when-to-use-what)
- [Real-World Example: mydoclist](#real-world-example-mydoclist)
- [Next Steps](#next-steps)

## The Shift: From UI-First to Agent-First

**A fundamental question is emerging:** If Claude and OpenAI's native agents are getting good enough to browse, search, and interact with web apps — why build custom UIs at all?

For decades, the workflow was:
1. Build a database
2. Build an API
3. Build a UI for humans to interact with the API
4. Build integrations for other systems

Now, with powerful agents like Claude Code, ChatGPT browsing, and MCP-enabled systems, a new pattern emerges:

**What if your web app was designed for agents _first_, and humans used those same agents to interact with it?**

This doesn't mean "no UI" — it means rethinking the relationship between:
- Your web application (the source of truth)
- Native AI agents (Claude, ChatGPT, local LLMs)
- Human users (who might use the agent _or_ the UI)

## What is MCP and Why It Matters for Web Apps

### Model Context Protocol (MCP) in 30 Seconds

**MCP = USB-C for AI agents.**

MCP is an open protocol that standardizes how AI applications connect to external systems. Instead of every AI tool building custom connectors for every data source, MCP provides a common interface.

**Key Components:**
- **MCP Servers** — Expose data sources, tools, or workflows to agents
- **MCP Clients** — AI applications (Claude Desktop, ChatGPT, custom agents) that connect to servers
- **Standardized Interface** — Resources (data), Tools (actions), Prompts (workflows)

**Example:**
```
Claude Desktop → MCP Client
mydoclist API → MCP Server
User: "Find all providers in Santa Monica with cardiology specialty"
Claude → Calls mydoclist MCP server → Returns structured results
```

### Why This Matters for Web Apps

Traditionally, web apps are built for _human interaction via browsers_. You navigate, click, type, scroll.

**But agents interact differently:**
- They don't "see" visual layouts
- They want structured data (JSON, not HTML)
- They need clear affordances (what actions are possible?)
- They struggle with complex navigation

**The opportunity:** Structure your web app so agents can interact with it _as effectively as humans_, but through a different channel.

## The Cross-Browser Challenge

Here's the problem Blake identified: **How do Claude/OpenAI native agents (running in _their_ browser) interact with your web app (running in _your_ browser)?**

### The Challenge

```
┌──────────────────────┐        ┌──────────────────────┐
│  Claude Desktop      │        │   Your Browser       │
│  (Agent's Browser)   │  ????  │   (Your Web App)     │
│                      │◄──────►│                      │
│  Running claude.ai   │        │  Running myapp.com   │
└──────────────────────┘        └──────────────────────┘
```

**Challenges:**
1. **Cross-origin restrictions** — Browsers block cross-domain communication by default (CORS)
2. **No shared state** — Two separate browser instances can't directly talk
3. **Authentication** — How does the agent authenticate as you?
4. **Context** — The agent needs to know what's possible (schema, actions, state)

### Solutions

#### 1. **MCP Server as API Gateway**

Instead of agent ↔ browser, go agent ↔ your backend:

```
┌──────────────────────┐
│  Claude Desktop      │
│                      │
│  Calls mydoclist     │
│  MCP Server          │
└───────────┬──────────┘
            │
            ▼
┌───────────────────────┐
│  mydoclist Backend    │
│  (FastAPI + DB)       │
│                       │
│  Exposes MCP Server   │
└───────────┬───────────┘
            │
            ▼
    ┌───────────────┐
    │   Database    │
    └───────────────┘
```

**Pros:**
- ✅ No browser involved for agent
- ✅ Full API control
- ✅ Agent gets structured data
- ✅ Authentication via API keys/OAuth

**Cons:**
- ❌ User's web session state not accessible
- ❌ Agent can't see what user sees in UI
- ❌ Two parallel interfaces (API + Web) to maintain

#### 2. **Web App as MCP-Aware Interface**

Build your web app to _expose an MCP interface in the same browser_:

```
┌─────────────────────────────────────────────────┐
│            User's Browser                       │
│                                                 │
│  ┌─────────────────┐    ┌──────────────────┐  │
│  │  Web UI         │    │  MCP Interface   │  │
│  │  (React App)    │◄───┤  (Web Worker/    │  │
│  │                 │    │   Service Worker)│  │
│  └─────────────────┘    └────────┬─────────┘  │
│                                   │            │
└───────────────────────────────────┼────────────┘
                                    │
                           ┌────────▼────────┐
                           │  Backend API    │
                           └─────────────────┘
```

**Pros:**
- ✅ Agent sees same state as user
- ✅ Single source of truth (your web app)
- ✅ Web Workers/Service Workers can act as MCP servers

**Cons:**
- ❌ Complex to implement
- ❌ Still requires cross-browser bridge
- ❌ Browser security restrictions

#### 3. **WebMCP: Direct Browser Integration** (Simplest!)

**NEW:** The simplest solution is [WebMCP](https://webmcp.dev) - a JavaScript library that exposes MCP directly from your web page.

```javascript
// Load WebMCP in your web app
<script src="webmcp.js"></script>

<script>
  const mcp = new WebMCP();

  // Register tools (actions)
  mcp.registerTool(
    'search_providers',
    'Search for healthcare providers',
    {
      specialty: { type: "string" },
      location: { type: "string" }
    },
    async function(args) {
      const results = await fetch('/api/search', {
        method: 'POST',
        body: JSON.stringify(args)
      }).then(r => r.json());
      
      return {
        content: [{
          type: "text",
          text: JSON.stringify(results, null, 2)
        }]
      };
    }
  );

  // Register resources (data)
  mcp.registerResource(
    'current-results',
    'Currently displayed search results',
    { uri: 'results://current', mimeType: 'application/json' },
    function(uri) {
      return {
        contents: [{
          uri: uri,
          mimeType: 'application/json',
          text: JSON.stringify(window.currentResults)
        }]
      };
    }
  );
</script>
```

**How it works:**
- Your web page exposes MCP interface via JavaScript
- Agent (Claude Desktop) connects directly to your page
- Agent can call tools, read resources, use prompts
- All happening in real-time in your browser

**Pros:**
- ✅ Zero backend changes needed
- ✅ Agent sees exactly what user sees
- ✅ Real-time state sync (same browser session)
- ✅ Simple JavaScript API

**Cons:**
- ❌ Requires user to have your page open
- ❌ Limited to browser capabilities

#### 4. **Browser Extension Bridge** (Advanced Hybrid)

The most practical approach: **bridge the two browsers via a backend MCP server that reflects browser state**:

```
┌────────────────────┐
│  Claude Desktop    │
│  (Agent Browser)   │
└─────────┬──────────┘
          │
          ▼
┌─────────────────────┐      ┌──────────────────────┐
│  MCP Server         │      │  User's Browser      │
│  (Backend)          │◄─────┤  + Extension/        │
│                     │      │    WebSocket         │
│  Syncs state from   │      │                      │
│  user's browser     │      │  Streams UI state    │
└─────────────────────┘      └──────────────────────┘
```

**How it works:**
1. User browses your web app normally
2. Browser extension/WebSocket streams current UI state to MCP server
3. Agent queries MCP server for context
4. Agent sends actions back through MCP server
5. Web app receives actions, updates UI
6. Loop repeats

**Pros:**
- ✅ Agent has real-time context
- ✅ User sees immediate feedback
- ✅ Web app remains primary interface
- ✅ Agent augments, doesn't replace

**Cons:**
- ❌ Requires browser extension or WebSocket integration
- ❌ State sync complexity

## Making Your Web App Agent-Friendly

Whether you use MCP or not, there are architectural patterns that make web apps easier for agents to use:

### 1. **Expose a Clear Data Schema**

Agents need to know _what data exists_ and _what shape it has_.

**Bad (agent-hostile):**
```html
<div class="provider-card">
  <span>Dr. Smith</span>
  <span>Cardiology</span>
</div>
```

**Good (agent-friendly):**
```json
{
  "resource": "provider",
  "id": "123",
  "schema": {
    "name": "string",
    "specialty": "string",
    "location": "object",
    "contact": "object"
  }
}
```

**How to expose:**
- Serve a `/schema` or `/api/schema` endpoint
- Embed schema in HTML as JSON-LD or `<script type="application/json">`
- Provide an OpenAPI spec for your API

### 2. **Make Actions Discoverable**

Agents need to know _what actions are possible_.

**Pattern: Action Manifest**
```json
{
  "actions": [
    {
      "id": "search_providers",
      "description": "Search for healthcare providers",
      "parameters": {
        "specialty": "string (optional)",
        "location": "string (optional)",
        "radius_miles": "number (optional)"
      },
      "endpoint": "/api/providers/search",
      "method": "POST"
    },
    {
      "id": "export_results",
      "description": "Export search results to CSV",
      "parameters": {
        "search_id": "string (required)"
      },
      "endpoint": "/api/export",
      "method": "GET"
    }
  ]
}
```

Expose this at `/api/actions` or embed it in your page.

### 3. **Provide Semantic HTML + ARIA**

If agents _do_ browse your UI, semantic HTML helps:

```html
<!-- Agent-friendly -->
<nav aria-label="Primary navigation">
  <a href="/providers" aria-label="Browse providers">Providers</a>
  <a href="/search" aria-label="Search">Search</a>
</nav>

<main>
  <section aria-label="Search results">
    <article role="listitem" aria-label="Provider: Dr. Smith">
      <h2>Dr. Jane Smith</h2>
      <p>Specialty: Cardiology</p>
      <button aria-label="View profile for Dr. Smith">View Profile</button>
    </article>
  </section>
</main>
```

**Why this helps:**
- Agents can navigate by aria-label
- Semantic tags (nav, main, article) provide structure
- Roles (listitem, button) clarify intent

### 4. **Use Stable IDs and Selectors**

If agents interact with your UI (via browser automation), give them stable targets:

**Bad:**
```html
<div class="styles__card__3x4a2">
  <button class="btn-primary-small">Save</button>
</div>
```

**Good:**
```html
<div data-entity="provider" data-id="123">
  <button data-action="save" aria-label="Save provider">Save</button>
</div>
```

Use `data-*` attributes or stable classes for agent targeting.

### 5. **Build a State Machine, Not Just a UI**

Instead of thinking "what does the UI show?", think "what states can the system be in?"

**Example: Provider Search**

States:
- `idle` → No search yet
- `searching` → Query in progress
- `results_loaded` → Search complete, results available
- `result_selected` → User/agent selected a specific provider
- `error` → Something went wrong

**Why this matters:**
Agents can query: "What state is the app in?" and make decisions based on that.

**How to expose:**
```json
GET /api/state
{
  "current_state": "results_loaded",
  "search_id": "abc123",
  "result_count": 42,
  "actions_available": ["export", "refine_search", "select_result"]
}
```

## Practical Architecture: The CRUD/CRM Case Study

Let's apply this to a real scenario: **mydoclist**, a provider search tool (CRUD/CRM for healthcare providers).

### Traditional Architecture

```
User → Browser → React UI → FastAPI → PostgreSQL
```

User interacts via UI. UI talks to API. API talks to database.

### Agent-Friendly Architecture

```
                    ┌──────────────────┐
                    │  Human User      │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Browser UI      │
                    │  (React App)     │
                    └────────┬─────────┘
                             │
                ┌────────────▼──────────────┐
                │    FastAPI Backend        │
                │                           │
                │  /api/* (REST)            │
                │  /mcp   (MCP Server)      │
                │  /schema (OpenAPI spec)   │
                │  /state  (App state)      │
                └────────────┬──────────────┘
                             │
                    ┌────────▼─────────┐
                    │   PostgreSQL     │
                    └──────────────────┘
                             ▲
                             │
                    ┌────────┴─────────┐
                    │  MCP Client      │
                    │  (Claude/ChatGPT)│
                    └──────────────────┘
```

### What Changes?

#### 1. **Add MCP Server Endpoint**

Your backend exposes an MCP-compatible interface:

**Example (FastAPI):**
```python
from fastapi import FastAPI
from mcp_server import MCPServer

app = FastAPI()
mcp = MCPServer(name="mydoclist")

# Regular REST endpoints
@app.get("/api/providers")
async def get_providers(specialty: str = None):
    # Normal API logic
    ...

# MCP endpoints
@app.post("/mcp")
async def handle_mcp_request(request: MCPRequest):
    return await mcp.handle(request)

# Register MCP resources
@mcp.resource("provider")
async def provider_resource(provider_id: str):
    # Return provider data in structured format
    ...

# Register MCP tools
@mcp.tool("search_providers")
async def search_tool(specialty: str, location: str):
    # Execute search, return results
    ...
```

#### 2. **Expose Schema**

Make your data model transparent:

```python
@app.get("/api/schema")
async def get_schema():
    return {
        "version": "1.0",
        "resources": {
            "provider": {
                "fields": {
                    "id": "uuid",
                    "name": "string",
                    "specialty": "string",
                    "location": {
                        "address": "string",
                        "city": "string",
                        "zip": "string"
                    },
                    "contact": {
                        "phone": "string",
                        "email": "string"
                    }
                }
            }
        },
        "actions": [
            {
                "name": "search_providers",
                "parameters": ["specialty", "location", "radius"]
            }
        ]
    }
```

#### 3. **Make UI State Observable**

If you want agents to know what the user is seeing:

**Frontend (React):**
```javascript
// Hook to sync UI state to backend
useEffect(() => {
  // Send current state via WebSocket or POST
  fetch('/api/ui-state', {
    method: 'POST',
    body: JSON.stringify({
      current_view: 'search_results',
      search_query: searchParams,
      selected_items: selectedProviders,
      timestamp: Date.now()
    })
  });
}, [searchParams, selectedProviders]);
```

**Backend:**
```python
# Store latest UI state in memory/Redis
ui_state_store = {}

@app.post("/api/ui-state")
async def update_ui_state(state: UIState, user_id: str):
    ui_state_store[user_id] = state
    return {"status": "updated"}

@app.get("/api/ui-state/{user_id}")
async def get_ui_state(user_id: str):
    return ui_state_store.get(user_id, {})
```

Now agents can query: _"What is the user currently looking at?"_

## Implementation Patterns

### Pattern 0: WebMCP (Frontend-Only Solution)

**When to use:** You want agents to interact with your web app without backend changes.

**How it works:** Add WebMCP JavaScript library to your page and register tools/resources directly from the frontend.

#### Step 1: Add WebMCP to Your Page

```html
<!DOCTYPE html>
<html>
<head>
  <title>mydoclist - Provider Search</title>
  <script src="https://unpkg.com/webmcp@latest/dist/webmcp.js"></script>
</head>
<body>
  <div id="app"></div>
  
  <script>
    // Initialize WebMCP
    const mcp = new WebMCP({
      color: '#4CAF50',
      position: 'bottom-right'
    });
  </script>
  
  <!-- Your React app loads here -->
  <script src="./app.js"></script>
</body>
</html>
```

#### Step 2: Register Tools

```javascript
// In your React app or main JS file

// Tool: Search providers
mcp.registerTool(
  'search_providers',
  'Search for healthcare providers by specialty and location',
  {
    specialty: { 
      type: "string",
      description: "Medical specialty (e.g. cardiology, pediatrics)"
    },
    location: { 
      type: "string",
      description: "City or zip code"
    },
    radius: {
      type: "number",
      description: "Search radius in miles (default: 10)"
    }
  },
  async function(args) {
    // Call your existing API
    const response = await fetch('/api/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        specialty: args.specialty,
        location: args.location,
        radius: args.radius || 10
      })
    });
    
    const results = await response.json();
    
    // Update UI (if using React state)
    setSearchResults(results);
    
    // Return to agent
    return {
      content: [{
        type: "text",
        text: `Found ${results.length} providers:\n\n` +
              results.map(p => 
                `- ${p.name} (${p.specialty})\n  ${p.address}\n  ${p.phone}`
              ).join('\n\n')
      }]
    };
  }
);

// Tool: Export results
mcp.registerTool(
  'export_results',
  'Export current search results to CSV',
  {},
  async function(args) {
    const csv = generateCSV(window.currentResults);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    
    // Trigger download
    const a = document.createElement('a');
    a.href = url;
    a.download = 'providers.csv';
    a.click();
    
    return {
      content: [{
        type: "text",
        text: `Exported ${window.currentResults.length} providers to CSV`
      }]
    };
  }
);
```

#### Step 3: Register Resources

```javascript
// Resource: Current search results
mcp.registerResource(
  'search-results',
  'Currently displayed search results',
  {
    uri: 'mydoclist://search-results',
    mimeType: 'application/json'
  },
  function(uri) {
    return {
      contents: [{
        uri: uri,
        mimeType: 'application/json',
        text: JSON.stringify(window.currentResults || [], null, 2)
      }]
    };
  }
);

// Resource: Current filters
mcp.registerResource(
  'active-filters',
  'Currently active search filters',
  {
    uri: 'mydoclist://filters',
    mimeType: 'application/json'
  },
  function(uri) {
    return {
      contents: [{
        uri: uri,
        mimeType: 'application/json',
        text: JSON.stringify(window.activeFilters || {}, null, 2)
      }]
    };
  }
);
```

#### Step 4: Register Prompts

```javascript
// Prompt: Generate search query
mcp.registerPrompt(
  'smart-search',
  'Generate an optimized provider search query',
  [
    {
      name: 'user_intent',
      description: 'What the user is looking for',
      required: true
    }
  ],
  function(args) {
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Parse this user intent into a structured provider search:\n\n"${args.user_intent}"\n\nExtract:\n- Specialty\n- Location\n- Any other criteria`
          }
        }
      ]
    };
  }
);
```

#### Agent Usage Example

Once WebMCP is integrated, users can:

```
User (to Claude Desktop):
"Search for cardiologists in Santa Monica within 5 miles"

Claude:
1. Calls search_providers tool via WebMCP
2. Your frontend executes search
3. Results appear in UI
4. Claude receives structured results
5. Claude formats and presents to user

User: "Export these to CSV"

Claude:
1. Calls export_results tool
2. CSV download triggers
3. User gets file
```

**Advantages of WebMCP:**
- No backend changes required
- Works with existing REST APIs
- Real-time state synchronization
- Agent sees what user sees

**Limitations:**
- User must have page open
- Limited to browser capabilities
- Can't run when browser closed

### Pattern 1: MCP Server Wrapping Your API

**When to use:** You already have a REST API and want to add agent access.

**Steps:**
1. Install MCP Python/TypeScript SDK
2. Create MCP server that calls your existing API internally
3. Register resources (data) and tools (actions)
4. Deploy MCP server alongside your API

**Example:**
```python
# mcp_server.py
from mcp import Server

server = Server("mydoclist")

@server.resource("provider/{id}")
async def get_provider(id: str):
    # Call your existing API internally
    provider = await api_client.get(f"/api/providers/{id}")
    return provider

@server.tool("search")
async def search_providers(specialty: str, location: str):
    results = await api_client.post("/api/search", {
        "specialty": specialty,
        "location": location
    })
    return results
```

### Pattern 2: Dual Interface (REST + MCP)

**When to use:** Building from scratch or refactoring.

**Architecture:**
```
┌────────────────────────────────┐
│        FastAPI Backend         │
│                                │
│  ┌──────────┐   ┌───────────┐ │
│  │ REST API │   │ MCP Server│ │
│  │ Endpoints│   │ Interface │ │
│  └────┬─────┘   └─────┬─────┘ │
│       │               │       │
│       └───────┬───────┘       │
│               │               │
│      ┌────────▼────────┐      │
│      │  Business Logic │      │
│      │  (Shared Layer) │      │
│      └────────┬────────┘      │
│               │               │
│      ┌────────▼────────┐      │
│      │    Database     │      │
│      └─────────────────┘      │
└────────────────────────────────┘
```

**Key insight:** Share business logic. REST and MCP are just different interfaces to the same core functionality.

**Example:**
```python
# core/provider_service.py
class ProviderService:
    async def search(self, specialty: str, location: str):
        # Core search logic
        ...
    
    async def get_by_id(self, id: str):
        # Core retrieval logic
        ...

# Expose via REST
@app.get("/api/providers/search")
async def rest_search(specialty: str, location: str):
    service = ProviderService()
    return await service.search(specialty, location)

# Expose via MCP
@mcp.tool("search_providers")
async def mcp_search(specialty: str, location: str):
    service = ProviderService()
    return await service.search(specialty, location)
```

### Pattern 3: WebSocket Bridge for Real-Time Context

**When to use:** Agent needs to know what user is doing in real-time.

**Architecture:**
```
┌──────────────────┐       WebSocket        ┌──────────────────┐
│  User's Browser  │◄───────────────────────┤   Backend        │
│                  │                        │                  │
│  Sends UI events │                        │  Stores state    │
│  (search, click) │                        │  in memory/Redis │
└──────────────────┘                        └────────┬─────────┘
                                                     │
                                            ┌────────▼─────────┐
                                            │   MCP Server     │
                                            │                  │
                                            │  Exposes state   │
                                            │  to agents       │
                                            └──────────────────┘
```

**Frontend:**
```javascript
const ws = new WebSocket('ws://localhost:8000/ws');

// Send UI events
ws.send(JSON.stringify({
  event: 'search',
  data: { specialty: 'cardiology', location: 'Santa Monica' }
}));

ws.send(JSON.stringify({
  event: 'result_selected',
  data: { provider_id: '123' }
}));
```

**Backend:**
```python
from fastapi import WebSocket

active_sessions = {}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    
    while True:
        data = await websocket.receive_json()
        
        # Update session state
        active_sessions[user_id] = {
            "last_event": data["event"],
            "data": data["data"],
            "timestamp": time.time()
        }

# MCP endpoint to query session state
@mcp.resource("session/{user_id}")
async def get_session_state(user_id: str):
    return active_sessions.get(user_id, {})
```

Now agents can query: _"What search is the user currently viewing?"_

## The Spectrum: When to Use What

Not every interaction needs an agent. Here's how to think about the spectrum:

### Use Traditional UI When:
- ✅ Visual layout matters (dashboards, charts)
- ✅ User needs to browse/explore (not goal-directed)
- ✅ Real-time interaction (drag-and-drop, live editing)
- ✅ Complex workflows with many decision points

### Use Agent-Assisted UI When:
- ✅ Power users want shortcuts ("Find all new providers in LA this week")
- ✅ Bulk operations ("Update status for all pending records")
- ✅ Natural language queries over structured data
- ✅ Users already comfortable with AI assistants

### Use Pure Agent Access When:
- ✅ API/programmatic access is primary use case
- ✅ Data integration between systems
- ✅ Automation and scheduled tasks
- ✅ Users are technical and prefer CLI/chat interfaces

### The Sweet Spot: Hybrid

Most real-world apps sit in the middle:

**Human uses UI for:**
- Initial setup and configuration
- Visual exploration and discovery
- Complex edits that benefit from direct manipulation

**Agent uses API/MCP for:**
- Bulk operations
- Natural language queries
- Cross-system workflows
- Automation

**Example workflow:**
1. User opens mydoclist UI
2. User: "Show me all cardiologists in Santa Monica"
3. UI loads results
4. User (to Claude): "Export these results and email them to me"
5. Claude (via MCP): Calls export API, retrieves CSV, emails user
6. User continues in UI

## Real-World Example: mydoclist

Let's bring it together with a concrete example:

### Current State
- FastAPI backend
- React frontend
- PostgreSQL database
- Google Places API integration
- Provider search functionality

### Making It Agent-Friendly

Two approaches: **WebMCP (frontend-only)** or **Backend MCP Server**.

#### Approach A: WebMCP (Simplest)

Add to your React frontend (`src/index.html` or `public/index.html`):

```html
<!DOCTYPE html>
<html>
<head>
  <title>mydoclist - Provider Search</title>
  <script src="https://unpkg.com/webmcp@latest/dist/webmcp.js"></script>
</head>
<body>
  <div id="root"></div>
  
  <script>
    // Initialize WebMCP before React loads
    window.mcp = new WebMCP({
      color: '#667eea',
      position: 'bottom-right'
    });
  </script>
  
  <script src="/static/js/bundle.js"></script>
</body>
</html>
```

Then in your React app (`src/App.jsx`):

```javascript
import { useEffect, useState } from 'react';

function App() {
  const [results, setResults] = useState([]);
  
  useEffect(() => {
    // Register MCP tools once component mounts
    const mcp = window.mcp;
    
    // Search tool
    mcp.registerTool(
      'search_providers',
      'Search healthcare providers',
      {
        specialty: { type: "string" },
        location: { type: "string" },
        radius: { type: "number" }
      },
      async (args) => {
        const res = await fetch('/api/search', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(args)
        });
        
        const data = await res.json();
        setResults(data); // Update React state
        
        return {
          content: [{
            type: "text",
            text: `Found ${data.length} providers`
          }]
        };
      }
    );
    
    // Export tool
    mcp.registerTool(
      'export_csv',
      'Export current results to CSV',
      {},
      async () => {
        const csv = convertToCSV(results);
        downloadFile(csv, 'providers.csv');
        return {
          content: [{ type: "text", text: "CSV exported" }]
        };
      }
    );
    
    // Current results resource
    mcp.registerResource(
      'current-results',
      'Currently displayed search results',
      { uri: 'mydoclist://results', mimeType: 'application/json' },
      () => ({
        contents: [{
          uri: 'mydoclist://results',
          mimeType: 'application/json',
          text: JSON.stringify(results, null, 2)
        }]
      })
    );
    
  }, [results]);
  
  return (
    <div>
      {/* Your existing UI */}
    </div>
  );
}
```

**That's it!** No backend changes needed. Agents can now interact with your app.

#### Approach B: Backend MCP Server

If you need agents to work when the page isn't open, add a backend MCP server:

#### Step 1: Add Schema Endpoint
```python
@app.get("/api/schema")
async def get_schema():
    return {
        "resources": {
            "provider": {
                "description": "Healthcare provider (doctor, clinic, hospital)",
                "fields": {
                    "id": "string (uuid)",
                    "name": "string",
                    "specialty": "string",
                    "address": "string",
                    "phone": "string",
                    "place_id": "string (Google Places ID)"
                }
            }
        },
        "actions": {
            "search": {
                "description": "Search for providers by specialty and location",
                "parameters": {
                    "specialty": "string (e.g. cardiology, dermatology)",
                    "location": "string (city or address)",
                    "radius": "number (optional, miles)"
                },
                "returns": "array of providers"
            },
            "export": {
                "description": "Export search results to CSV",
                "parameters": {
                    "provider_ids": "array of strings"
                },
                "returns": "CSV file URL"
            }
        }
    }
```

#### Step 2: Add MCP Server
```python
from mcp_server import MCPServer

mcp = MCPServer("mydoclist")

@mcp.tool("search_providers")
async def search_providers(specialty: str, location: str, radius: float = 10):
    """
    Search for healthcare providers by specialty and location.
    
    Args:
        specialty: Medical specialty (e.g. "cardiology", "pediatrics")
        location: City or address (e.g. "Santa Monica, CA")
        radius: Search radius in miles (default: 10)
    
    Returns:
        List of matching providers with contact information
    """
    # Use existing search logic
    results = await provider_service.search(specialty, location, radius)
    
    return {
        "count": len(results),
        "providers": [
            {
                "id": p.id,
                "name": p.name,
                "specialty": p.specialty,
                "address": p.address,
                "phone": p.phone
            }
            for p in results
        ]
    }

@mcp.tool("export_results")
async def export_results(provider_ids: list[str]):
    """
    Export provider data to CSV.
    
    Args:
        provider_ids: List of provider IDs to export
    
    Returns:
        URL to download CSV file
    """
    csv_url = await export_service.create_csv(provider_ids)
    return {"download_url": csv_url}

@app.post("/mcp")
async def handle_mcp(request: MCPRequest):
    return await mcp.handle(request)
```

#### Step 3: Document for Users

Create `/docs/agent-usage.md`:

```markdown
# Using mydoclist with AI Agents

## Connect via MCP

1. Install MCP client (Claude Desktop, ChatGPT, etc.)
2. Configure MCP server:
   ```json
   {
     "servers": {
       "mydoclist": {
         "url": "https://mydoclist.com/mcp",
         "api_key": "your_api_key_here"
       }
     }
   }
   ```

## Example Queries

**Search for providers:**
"Find cardiologists in Santa Monica within 5 miles"

**Export results:**
"Export these results to CSV and email me the file"

**Bulk operations:**
"Find all new providers added this week and update their status to 'pending review'"
```

#### Step 4: Test

```bash
# Using Claude Code with MCP
claude "Connect to mydoclist and search for dermatologists in Los Angeles"

# Expected flow:
# 1. Claude calls mydoclist MCP server
# 2. MCP server calls /api/search
# 3. Results returned to Claude
# 4. Claude formats and displays results
```

## WebMCP vs Backend MCP: Which to Choose?

| Factor | WebMCP (Frontend) | Backend MCP Server |
|--------|-------------------|-------------------|
| **Setup Complexity** | ⭐⭐⭐⭐⭐ Add script tag | ⭐⭐ Backend implementation |
| **Backend Changes** | ✅ None needed | ❌ Requires new endpoints |
| **Real-time State** | ✅ Perfect sync | ⚠️ Manual sync needed |
| **Works When Browser Closed** | ❌ No | ✅ Yes |
| **Authentication** | ⚠️ Uses user's session | ✅ API keys/OAuth |
| **Suitable for Production** | ✅ Yes (for live use) | ✅ Yes (for automation) |
| **Best For** | Interactive agent use | Automation & integrations |

### Decision Guide

**Use WebMCP when:**
- ✅ You want quick agent integration (add in <1 hour)
- ✅ Primary use case is user + agent working together
- ✅ Agent needs to see current UI state
- ✅ You don't want to modify backend

**Use Backend MCP Server when:**
- ✅ Agents need 24/7 access (cron jobs, automation)
- ✅ Multiple agents connecting simultaneously
- ✅ Need robust authentication and rate limiting
- ✅ Agent actions shouldn't depend on browser state

**Use Both when:**
- ✅ You want interactive use (WebMCP) + automation (Backend)
- ✅ Different tools for each (UI interactions vs data operations)
- ✅ Building a comprehensive agent-first platform

### Real-World Setup: The Hybrid Approach

Most production apps end up with both:

```
┌─────────────────────────────────────┐
│        mydoclist Web App            │
│                                     │
│  ┌──────────────┐   ┌────────────┐ │
│  │  React UI    │   │  WebMCP    │ │
│  │              │   │  (Live     │ │
│  │              │   │   Use)     │ │
│  └──────────────┘   └────────────┘ │
└─────────────┬───────────────────────┘
              │
    ┌─────────▼──────────┐
    │  FastAPI Backend   │
    │                    │
    │  /api/* (REST)     │
    │  /mcp   (Backend   │
    │         MCP Server)│
    └─────────┬──────────┘
              │
    ┌─────────▼──────────┐
    │    PostgreSQL      │
    └────────────────────┘
```

**Example workflow:**
1. User opens mydoclist (WebMCP loads)
2. User asks Claude: "Find cardiologists in LA" → WebMCP handles it
3. User closes browser
4. Nightly cron job via Backend MCP: "Update provider data from external API"
5. User returns next day, asks: "What changed overnight?" → WebMCP shows updates

## Next Steps

### For Your Web App

**Quick Start (30 minutes):**
1. Add WebMCP script tag to your page
2. Register 2-3 core tools (search, export, etc.)
3. Register resources (current state)
4. Test with Claude Desktop

**Full Implementation (2-4 hours):**
1. **WebMCP first:** Get interactive use working
2. **Add schema endpoint:** Document your data model
3. **Backend MCP server (if needed):** For automation
4. **Test with Claude Desktop:** Connect and try queries
5. **Iterate:** Learn what agents struggle with, improve

### For Learning More

**WebMCP (Frontend):**
- [WebMCP Official Site](https://webmcp.dev) - Interactive demos + docs
- [WebMCP on npm](https://www.npmjs.com/package/webmcp) - Package details
- Add to your page: `<script src="https://unpkg.com/webmcp@latest/dist/webmcp.js"></script>`

**Model Context Protocol (Backend):**
- [MCP Official Docs](https://modelcontextprotocol.io) - Full specification
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk) - For FastAPI/Flask
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk) - For Node/Express
- [MCP Servers Repository](https://github.com/modelcontextprotocol/servers) - Reference implementations

**Related Topics:**
- OpenAPI/Swagger for API documentation
- JSON Schema for data validation
- WebSocket for real-time state sync
- ARIA for semantic web accessibility

### Discussion: Syntax Podcast on Web-UI

*(Blake mentioned a Syntax podcast on this topic — add notes/link here)*

## The Future: Agent-Native Applications

As agents get better, we'll see more applications designed **agent-first, human-optional**:

- **Data platforms** where agents are the primary interface
- **CRMs** where sales reps talk to an agent, not a UI
- **Admin panels** accessed purely via natural language
- **APIs** that expose agent-friendly interfaces by default

The web UI doesn't disappear — it becomes **one interface among many**, alongside CLI, API, and agent access.

**The question for builders:**

> Will your next application be built for humans to click through, or for agents to reason over?

Probably both. But the balance is shifting.

---

**Try This:**

If you have Claude Desktop or ChatGPT Plus:

1. Pick a web app you use regularly
2. Try describing tasks in natural language: "Find X", "Export Y", "Update Z"
3. Notice where the agent succeeds and where it struggles
4. Think: *How could this app be structured to make the agent's job easier?*

That's the core insight of agent-friendly architecture.

→ Next: Build your own MCP server, or explore [OpenClaw's MCP integration](https://docs.openclaw.ai/tools/mcp).
