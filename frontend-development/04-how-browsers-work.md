# How Browsers Work

**The Browser as Your Runtime Environment**

Just as Python runs in an interpreter, JavaScript runs in a browser. Understanding how browsers work is essential for frontend development — it's your runtime environment.

---

## Table of Contents

1. [The DOM: Document Object Model](#the-dom-document-object-model)
2. [How Browsers Render Pages](#how-browsers-render-pages)
3. [JavaScript in the Browser](#javascript-in-the-browser)
4. [The Network Tab](#the-network-tab)
5. [Storage: localStorage, sessionStorage, Cookies](#storage-localstorage-sessionstorage-cookies)
6. [The Console: Your Best Friend](#the-console-your-best-friend)
7. [DevTools Walkthrough](#devtools-walkthrough)

---

## The DOM: Document Object Model

### HTML → Tree Structure

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Provider Search</title>
  </head>
  <body>
    <div id="root">
      <h1>Search Providers</h1>
      <input type="text" placeholder="Enter specialty..." />
      <button>Search</button>
    </div>
  </body>
</html>
```

**The browser parses this into a tree:**

```
Document
└── html
    ├── head
    │   └── title
    │       └── "Provider Search"
    └── body
        └── div#root
            ├── h1
            │   └── "Search Providers"
            ├── input
            └── button
                └── "Search"
```

### Python Analogy: The DOM Is a Data Structure

```python
# Imagine HTML as a Python data structure
document = {
    "tag": "html",
    "children": [
        {
            "tag": "head",
            "children": [
                {"tag": "title", "text": "Provider Search"}
            ]
        },
        {
            "tag": "body",
            "children": [
                {
                    "tag": "div",
                    "id": "root",
                    "children": [
                        {"tag": "h1", "text": "Search Providers"},
                        {"tag": "input", "type": "text"},
                        {"tag": "button", "text": "Search"}
                    ]
                }
            ]
        }
    ]
}
```

**The DOM is exactly this:** A tree of objects you can query and manipulate with JavaScript.

### Accessing the DOM

```javascript
// Get element by ID
const root = document.getElementById("root")

// Get elements by selector (like CSS)
const buttons = document.querySelectorAll("button")
const firstButton = document.querySelector("button")

// Get by tag name
const divs = document.getElementsByTagName("div")

// Get by class name
const cards = document.getElementsByClassName("card")
```

### Manipulating the DOM

```javascript
// Create element
const div = document.createElement("div")
div.textContent = "Hello, world!"
div.className = "card"

// Append to DOM
document.body.appendChild(div)

// Modify existing element
const heading = document.querySelector("h1")
heading.textContent = "New Title"
heading.style.color = "blue"

// Remove element
heading.remove()
```

**React does this for you:** You write JSX, React manipulates the DOM.

---

## How Browsers Render Pages

### The Rendering Pipeline

```
1. HTML → DOM Tree
   (Parse HTML into JavaScript objects)
   
2. CSS → CSSOM Tree
   (Parse CSS into style rules)
   
3. DOM + CSSOM → Render Tree
   (Combine structure and styles)
   
4. Layout (Reflow)
   (Calculate positions and sizes)
   
5. Paint
   (Draw pixels on screen)
   
6. Composite
   (Layer multiple paint operations)
```

### Example: Loading a Page

```html
<html>
  <head>
    <link rel="stylesheet" href="styles.css">
  </head>
  <body>
    <h1>Hello</h1>
    <script src="app.js"></script>
  </body>
</html>
```

**What happens:**
1. Browser fetches HTML
2. Starts parsing, sees `<link>` → fetches `styles.css` (doesn't block rendering)
3. Sees `<h1>` → adds to DOM
4. Sees `<script>` → **stops parsing**, fetches and runs `app.js`
5. Script completes → continues parsing
6. DOM complete → combines with CSSOM → renders page

### Blocking vs Non-Blocking

| Resource | Blocks Parsing? | Blocks Rendering? |
|----------|----------------|-------------------|
| CSS in `<head>` | ❌ No | ✅ Yes |
| `<script>` (normal) | ✅ Yes | ✅ Yes |
| `<script defer>` | ❌ No | ✅ Yes (waits for DOM) |
| `<script async>` | ❌ No | ❌ No (runs ASAP) |
| Images | ❌ No | ❌ No |

**Best practice:** Put `<script>` tags at end of `<body>` or use `defer`/`async`.

---

## JavaScript in the Browser

### Script Tags

```html
<!-- Inline script -->
<script>
  console.log("Hello from inline script")
</script>

<!-- External script -->
<script src="/assets/app.js"></script>

<!-- Defer: load async, execute after DOM ready -->
<script src="/assets/app.js" defer></script>

<!-- Async: load and execute ASAP -->
<script src="/analytics.js" async></script>

<!-- Type module: ES6 modules -->
<script type="module" src="/app.js"></script>
```

### Global Scope

```javascript
// In browser, top-level code runs in global scope
var globalVar = "I'm global"
function globalFunction() {
    console.log("I'm global too")
}

// These are accessible from console:
window.globalVar  // "I'm global"
window.globalFunction()
```

**Modern best practice:** Use ES6 modules (`type="module"`), which have their own scope.

### Browser APIs

```javascript
// Window object (global)
console.log(window.innerWidth)   // Browser width
console.log(window.location.href)  // Current URL

// Document object (DOM)
document.title = "New Title"
document.body.style.backgroundColor = "lightblue"

// Navigator (browser info)
console.log(navigator.userAgent)  // Browser string
console.log(navigator.language)   // User language

// Local storage
localStorage.setItem("token", "abc123")
const token = localStorage.getItem("token")

// Fetch (HTTP requests)
fetch("/api/data").then(r => r.json()).then(console.log)

// Timers
setTimeout(() => console.log("Later"), 1000)
setInterval(() => console.log("Repeating"), 5000)

// Geolocation
navigator.geolocation.getCurrentPosition(pos => {
    console.log(pos.coords.latitude, pos.coords.longitude)
})
```

---

## The Network Tab

### What You See When Your App Loads

**Open DevTools → Network tab → Reload page**

You'll see:
- **Document:** The initial HTML
- **Stylesheet:** CSS files
- **Script:** JavaScript bundles
- **XHR/Fetch:** API calls
- **Image/Media:** Images, fonts, etc.

### Key Columns

| Column | Meaning |
|--------|---------|
| Name | Resource filename/URL |
| Status | HTTP status (200, 404, 500, etc.) |
| Type | Resource type (document, script, xhr, etc.) |
| Initiator | What triggered this request |
| Size | File size (or "from cache") |
| Time | How long it took |
| Waterfall | Visual timeline |

### Inspecting Requests

**Click on any request to see:**
- **Headers:** Request and response headers
- **Preview:** Formatted response (JSON, HTML, etc.)
- **Response:** Raw response body
- **Timing:** Detailed timing breakdown

### Our Provider Search: What You'll See

**When loading the app:**
1. `index.html` — Initial document
2. `assets/index-xyz.js` — Main JavaScript bundle (Vite generates unique hash)
3. `assets/index-xyz.css` — Styles bundle

**When searching:**
1. `POST /api/search` — Search request
   - Request Payload: `{"query": "cardiology", "radius_miles": 25}`
   - Response: `{"providers": [...], "total_results": 50}`

2. `POST /api/provider/status` — Provider status request
   - Request: `{"place_ids": ["abc123", "def456"]}`
   - Response: `{"abc123": "hard_lead", "def456": "existing"}`

### Network Tab Debugging

**Common issues:**
- **404 Not Found:** Wrong URL or file doesn't exist
- **401 Unauthorized:** Missing or invalid auth token
- **403 Forbidden:** Valid token, but no permission
- **500 Internal Server Error:** Backend crashed
- **CORS errors:** Cross-origin request blocked

**Check:**
1. Request URL (is it correct?)
2. Request headers (is auth token present?)
3. Request payload (is data formatted correctly?)
4. Response body (what's the error message?)

---

## Storage: localStorage, sessionStorage, Cookies

### Python Analogy

```python
# Python: Data in memory or files
cache = {}  # Lost when process exits
cache["token"] = "abc123"

# Persist to file
with open("token.txt", "w") as f:
    f.write("abc123")
```

### Browser Storage Options

| Storage | Scope | Lifetime | Size Limit |
|---------|-------|----------|------------|
| `localStorage` | Origin | Forever (until cleared) | ~5-10 MB |
| `sessionStorage` | Tab | Until tab closed | ~5-10 MB |
| `cookies` | Origin | Configurable expiry | ~4 KB per cookie |
| IndexedDB | Origin | Forever | Large (50MB+) |

### localStorage

```javascript
// Set item
localStorage.setItem("token", "abc123")
localStorage.setItem("user", JSON.stringify({name: "Blake"}))

// Get item
const token = localStorage.getItem("token")  // "abc123"
const user = JSON.parse(localStorage.getItem("user") || "{}")

// Remove item
localStorage.removeItem("token")

// Clear all
localStorage.clear()

// Check existence
if (localStorage.getItem("token")) {
    console.log("Token exists")
}
```

**Use case:** Persist data across page reloads (auth tokens, user preferences, cached data)

### sessionStorage

```javascript
// Same API as localStorage
sessionStorage.setItem("tempData", "value")
const data = sessionStorage.getItem("tempData")
```

**Use case:** Temporary data for current tab session (form state, wizard progress)

### Cookies

```javascript
// Set cookie (raw)
document.cookie = "token=abc123; path=/; max-age=3600"

// Get all cookies (messy)
console.log(document.cookie)  // "token=abc123; user=Blake"

// Better: use a library (js-cookie)
```

**Use case:** Server needs to read the value (auth tokens sent automatically with requests)

### Provider Search Storage

```javascript
// web/src/lib/supabase.ts uses localStorage
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: window.localStorage,  // Store Supabase session here
    persistSession: true,
  },
})
```

**Check DevTools → Application → Local Storage** to see:
- `sb-<project>-auth-token` — Supabase session

---

## The Console: Your Best Friend

### Logging

```javascript
// Basic logging
console.log("Hello")
console.log("Value:", value)
console.log("Multiple", "args", 42, {name: "Blake"})

// Different levels
console.info("Info message")
console.warn("Warning!")
console.error("Error occurred!")

// Formatting
console.log("%cStyled text", "color: red; font-size: 20px")

// Objects (expandable)
console.log({user, posts, comments})

// Tables (for arrays of objects)
console.table([
    {name: "Blake", age: 30},
    {name: "Alex", age: 25}
])
```

### Python print() vs JavaScript console.log()

```python
# Python
print("Value:", x)
print(f"Name: {name}, Age: {age}")
```

```javascript
// JavaScript
console.log("Value:", x)
console.log(`Name: ${name}, Age: ${age}`)
```

### Interactive Console

**Try this in browser console:**

```javascript
// Access current page elements
document.title
document.body.innerHTML

// Modify the page
document.body.style.backgroundColor = "lightblue"

// Run functions
fetch("/api/health").then(r => r.json()).then(console.log)

// Access React app (if dev mode)
window.__REACT_DEVTOOLS_GLOBAL_HOOK__

// Check localStorage
localStorage

// Network requests
await fetch("/api/search", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({query: "cardiology", radius_miles: 25})
}).then(r => r.json())
```

---

## DevTools Walkthrough

### Elements Tab

**Inspect any element:**
- Right-click → Inspect Element
- See HTML structure
- Edit HTML live (changes don't persist)
- See computed CSS styles
- Toggle element visibility
- Simulate hover/focus states

**Useful for:**
- Finding element selectors for CSS/JavaScript
- Debugging layout issues
- Testing CSS changes

### Console Tab

**JavaScript REPL:**
- Run arbitrary JavaScript
- Log messages from your code
- Test API calls
- Inspect variables

### Network Tab

**Monitor network activity:**
- See all HTTP requests
- Inspect request/response
- Check timing
- Filter by type (XHR, JS, CSS, etc.)
- Simulate slow connection

### Application Tab

**Storage and PWA features:**
- Local Storage
- Session Storage
- Cookies
- IndexedDB
- Cache Storage
- Service Workers

**Check:** Application → Local Storage → `http://localhost:5173` to see our Supabase session.

### Sources Tab

**Debugging:**
- See loaded JavaScript files
- Set breakpoints
- Step through code
- Watch variables
- Call stack

**Advanced:** Use when `console.log()` isn't enough.

### Performance Tab

**Profile rendering:**
- Record page interactions
- See function call timings
- Identify bottlenecks

**Use when:** App feels slow, need to optimize.

---

## Why This Matters for Provider Search

**The browser is your runtime:**
- React runs in the browser, manipulates the DOM
- API calls go through the browser's fetch API
- Auth tokens stored in localStorage
- DevTools is your primary debugging tool

**Debugging workflow:**
1. **Console:** Check for JavaScript errors
2. **Network:** Verify API calls (status, payload, response)
3. **Application:** Check localStorage for auth token
4. **Elements:** Inspect component rendering

**Common debugging scenarios:**

**Problem:** Search not working
1. Open Network tab
2. Submit search
3. Check `POST /api/search` request
4. Verify request payload
5. Check response status and body

**Problem:** "Unauthorized" error
1. Open Application → Local Storage
2. Check for Supabase session
3. Open Network → Headers
4. Verify `Authorization: Bearer <token>` header

**Problem:** Component not rendering
1. Open Elements tab
2. Verify element exists in DOM
3. Check CSS (display: none? visibility: hidden?)
4. Console → Check for JavaScript errors

---

## Next Steps

- **[05-css-and-styling-essentials.md](05-css-and-styling-essentials.md)** — Styling the DOM
- **[06-react-fundamentals.md](06-react-fundamentals.md)** — Let React manage the DOM for you

---

**You now understand the browser runtime. This is your development environment.**
