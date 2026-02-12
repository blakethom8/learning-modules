# React Fundamentals

**Components: Functions That Return UI**

React is a library for building user interfaces with reusable components. Think of components as Python functions that return HTML-like structures instead of data.

---

## Table of Contents

1. [What Is React?](#what-is-react)
2. [Components: Functions That Return JSX](#components-functions-that-return-jsx)
3. [JSX: HTML in JavaScript](#jsx-html-in-javascript)
4. [Props: Function Arguments for Components](#props-function-arguments-for-components)
5. [Rendering: How React Updates the DOM](#rendering-how-react-updates-the-dom)
6. [Lists and Keys](#lists-and-keys)
7. [Conditional Rendering](#conditional-rendering)
8. [Event Handling](#event-handling)
9. [Real Example: StatusIndicator.tsx](#real-example-statusindicatortsx)

---

## What Is React?

### The Problem: Manual DOM Manipulation Is Tedious

```javascript
// Vanilla JavaScript: Imperative
const container = document.getElementById("root")
const heading = document.createElement("h1")
heading.textContent = "Search Providers"
container.appendChild(heading)

const input = document.createElement("input")
input.placeholder = "Enter specialty..."
container.appendChild(input)

// Update when data changes:
function updateResults(providers) {
    const list = document.getElementById("results")
    list.innerHTML = ""  // Clear
    providers.forEach(provider => {
        const item = document.createElement("div")
        item.textContent = provider.name
        list.appendChild(item)
    })
}
```

**Problems:**
- Verbose and error-prone
- Hard to maintain
- Easy to get out of sync with state
- No reusability

### React: Declarative UI

```javascript
// React: Declarative
function SearchPage({ providers }) {
    return (
        <div>
            <h1>Search Providers</h1>
            <input placeholder="Enter specialty..." />
            <div id="results">
                {providers.map(provider => (
                    <div key={provider.id}>{provider.name}</div>
                ))}
            </div>
        </div>
    )
}
```

**Benefits:**
- Declare what UI should look like
- React handles DOM updates
- Composable and reusable
- State changes → automatic re-renders

### Python Analogy: Templates

```python
# Python (Jinja2 template)
def render_search_page(providers):
    return """
        <div>
            <h1>Search Providers</h1>
            <input placeholder="Enter specialty..." />
            <div id="results">
                {% for provider in providers %}
                    <div>{{ provider.name }}</div>
                {% endfor %}
            </div>
        </div>
    """
```

**React is like this, but:**
- Templates are written in JavaScript (JSX)
- Components are functions
- Updates are automatic (no manual re-renders)

---

## Components: Functions That Return JSX

### Function Components

```javascript
// A component is just a function
function Greeting() {
    return <h1>Hello, World!</h1>
}

// With parameters (props)
function Greeting(props) {
    return <h1>Hello, {props.name}!</h1>
}

// Using ES6 destructuring (preferred)
function Greeting({ name }) {
    return <h1>Hello, {name}!</h1>
}
```

### Python Comparison

```python
# Python function that returns data
def greeting(name: str) -> dict:
    return {
        "tag": "h1",
        "text": f"Hello, {name}!"
    }

# React component returns JSX (HTML-like)
function Greeting({ name }) {
    return <h1>Hello, {name}!</h1>
}
```

**Key difference:** React components return UI elements, not data structures.

### Component Rules

1. **Name must start with capital letter:** `Greeting`, not `greeting`
2. **Must return JSX** (or `null`, string, number, etc.)
3. **Can only return one root element** (or Fragment)

```javascript
// ❌ Wrong: Multiple root elements
function BadComponent() {
    return (
        <h1>Title</h1>
        <p>Paragraph</p>
    )
}

// ✅ Correct: One root element
function GoodComponent() {
    return (
        <div>
            <h1>Title</h1>
            <p>Paragraph</p>
        </div>
    )
}

// ✅ Also correct: Fragment (no extra div)
function AlsoGood() {
    return (
        <>
            <h1>Title</h1>
            <p>Paragraph</p>
        </>
    )
}
```

---

## JSX: HTML in JavaScript

### What Is JSX?

```javascript
// This looks like HTML...
const element = <h1 className="title">Hello</h1>

// ...but it's actually JavaScript!
// React transforms it to:
const element = React.createElement(
    'h1',
    { className: 'title' },
    'Hello'
)
```

**JSX is syntactic sugar** for `React.createElement()` calls.

### JavaScript Expressions in JSX

```javascript
function Greeting({ name, age }) {
    const greeting = "Hello"
    
    return (
        <div>
            <h1>{greeting}, {name}!</h1>  {/* Variables */}
            <p>Age: {age}</p>
            <p>Next year: {age + 1}</p>  {/* Expressions */}
            <p>Status: {age >= 18 ? "Adult" : "Minor"}</p>  {/* Ternary */}
        </div>
    )
}
```

**Curly braces `{}` = JavaScript expression**

### Attributes in JSX

```javascript
// HTML attributes → camelCase
<div className="container">  {/* class → className */}
<label htmlFor="input">     {/* for → htmlFor */}
<input tabIndex={1} />      {/* tabindex → tabIndex */}

// Style attribute = JavaScript object
<div style={{ color: "red", fontSize: "20px" }}>
    Styled text
</div>

// Dynamic attributes
<input
    type="text"
    value={searchQuery}
    placeholder="Enter specialty..."
    disabled={isLoading}
/>
```

### JSX vs HTML Differences

| HTML | JSX | Why |
|------|-----|-----|
| `class="..."` | `className="..."` | `class` is JavaScript keyword |
| `for="..."` | `htmlFor="..."` | `for` is JavaScript keyword |
| `tabindex="1"` | `tabIndex={1}` | CamelCase convention |
| `onclick="..."` | `onClick={() => {}}` | CamelCase + function |
| `<br>` | `<br />` | Self-closing tags need `/` |
| `style="color: red"` | `style={{color: "red"}}` | Object, not string |

---

## Props: Function Arguments for Components

### Passing Data to Components

```javascript
// Parent component
function App() {
    return (
        <div>
            <Greeting name="Blake" age={30} />
            <Greeting name="Alex" age={25} />
        </div>
    )
}

// Child component
function Greeting({ name, age }) {
    return (
        <div>
            <h1>Hello, {name}!</h1>
            <p>Age: {age}</p>
        </div>
    )
}
```

### Python Comparison

```python
# Python: Function arguments
def greeting(name: str, age: int) -> str:
    return f"<div><h1>Hello, {name}!</h1><p>Age: {age}</p></div>"

greeting("Blake", 30)
greeting("Alex", 25)
```

```javascript
// React: Props (same concept)
function Greeting({ name, age }) {
    return <div>...</div>
}

<Greeting name="Blake" age={30} />
<Greeting name="Alex" age={25} />
```

### Props Are Read-Only

```javascript
function Greeting({ name }) {
    // ❌ Don't modify props!
    name = "Someone Else"
    
    // ✅ Props are for reading only
    return <h1>Hello, {name}!</h1>
}
```

**Props flow down** (parent → child), never up.

### Children Prop

```javascript
// Special prop: children
function Card({ children }) {
    return (
        <div className="card">
            {children}
        </div>
    )
}

// Using it:
<Card>
    <h1>Title</h1>
    <p>Content goes here</p>
</Card>

// children = everything between tags
```

### Default Props

```javascript
function Greeting({ name = "Guest", age = 0 }) {
    return <div>Hello, {name}! Age: {age}</div>
}

<Greeting />  // "Hello, Guest! Age: 0"
<Greeting name="Blake" />  // "Hello, Blake! Age: 0"
```

---

## Rendering: How React Updates the DOM

### Virtual DOM

```
User updates state
        ↓
React creates new Virtual DOM tree
        ↓
React diffs old vs new Virtual DOM
        ↓
React updates only what changed in real DOM
```

**Example:**

```javascript
// State changes
const [count, setCount] = useState(0)

// Before: count = 0
<div>
    <h1>Counter</h1>
    <p>Count: 0</p>  {/* This element */}
    <button>Increment</button>
</div>

// After: count = 1
<div>
    <h1>Counter</h1>
    <p>Count: 1</p>  {/* Only this text node updates! */}
    <button>Increment</button>
</div>
```

**React only updates the text "0" → "1", not the entire DOM.**

### The Render Cycle

```
1. Props or state changes
2. React calls component function
3. Component returns new JSX
4. React diffs Virtual DOM
5. React updates real DOM (minimal changes)
6. Browser repaints
```

---

## Lists and Keys

### Rendering Arrays

```python
# Python: List comprehension
providers = [{"id": 1, "name": "Dr. Smith"}, {"id": 2, "name": "Dr. Jones"}]
html = "\n".join(f"<div>{p['name']}</div>" for p in providers)
```

```javascript
// React: .map()
const providers = [
    { id: 1, name: "Dr. Smith" },
    { id: 2, name: "Dr. Jones" }
]

function ProviderList({ providers }) {
    return (
        <div>
            {providers.map(provider => (
                <div key={provider.id}>{provider.name}</div>
            ))}
        </div>
    )
}
```

### The `key` Prop (Critical!)

```javascript
// ❌ Bad: No key
{providers.map(provider => (
    <div>{provider.name}</div>
))}

// ❌ Bad: Index as key (only if list never changes)
{providers.map((provider, index) => (
    <div key={index}>{provider.name}</div>
))}

// ✅ Good: Unique ID as key
{providers.map(provider => (
    <div key={provider.id}>{provider.name}</div>
))}
```

**Why keys matter:** React uses keys to track which items changed, were added, or removed. Without keys, React can't optimize updates.

---

## Conditional Rendering

### If/Else

```javascript
function Greeting({ isLoggedIn, name }) {
    if (isLoggedIn) {
        return <h1>Welcome back, {name}!</h1>
    } else {
        return <h1>Please log in</h1>
    }
}
```

### Ternary Operator (Common)

```javascript
function Greeting({ isLoggedIn, name }) {
    return (
        <div>
            {isLoggedIn ? (
                <h1>Welcome back, {name}!</h1>
            ) : (
                <h1>Please log in</h1>
            )}
        </div>
    )
}
```

### Logical AND (For One Branch)

```javascript
function Notification({ hasNewMessages, count }) {
    return (
        <div>
            {hasNewMessages && (
                <div className="badge">{count} new messages</div>
            )}
        </div>
    )
}

// If hasNewMessages is false, nothing renders
```

### Nullish Coalescing (Fallbacks)

```javascript
function UserProfile({ user }) {
    return (
        <div>
            <p>Email: {user.email ?? "Not provided"}</p>
            <p>Bio: {user.bio || "No bio"}</p>
        </div>
    )
}
```

---

## Event Handling

### Click Events

```javascript
function Button() {
    function handleClick() {
        console.log("Button clicked!")
    }
    
    return <button onClick={handleClick}>Click me</button>
}

// Or inline:
<button onClick={() => console.log("Clicked!")}>Click me</button>
```

### Form Events

```javascript
function SearchForm() {
    function handleSubmit(event) {
        event.preventDefault()  // Don't reload page
        console.log("Form submitted")
    }
    
    function handleChange(event) {
        console.log("Input value:", event.target.value)
    }
    
    return (
        <form onSubmit={handleSubmit}>
            <input
                type="text"
                onChange={handleChange}
                placeholder="Enter specialty..."
            />
            <button type="submit">Search</button>
        </form>
    )
}
```

### Common Events

| Event | When | Example |
|-------|------|---------|
| `onClick` | Element clicked | `<button onClick={fn}>` |
| `onChange` | Input value changed | `<input onChange={fn}>` |
| `onSubmit` | Form submitted | `<form onSubmit={fn}>` |
| `onFocus` | Element focused | `<input onFocus={fn}>` |
| `onBlur` | Element unfocused | `<input onBlur={fn}>` |
| `onMouseEnter` | Mouse enters | `<div onMouseEnter={fn}>` |
| `onKeyDown` | Key pressed | `<input onKeyDown={fn}>` |

### Event Object

```javascript
function handleClick(event) {
    console.log(event.target)  // The element clicked
    console.log(event.type)    // "click"
    event.preventDefault()     // Prevent default behavior
    event.stopPropagation()    // Stop event bubbling
}
```

---

## Real Example: StatusIndicator.tsx

### Our Simple Component

```typescript
// web/src/components/StatusIndicator.tsx (simplified)
import { ProviderStatus, STATUS_CONFIG } from '../types/provider'

interface StatusIndicatorProps {
    status: ProviderStatus
}

export default function StatusIndicator({ status }: StatusIndicatorProps) {
    const config = STATUS_CONFIG[status]
    
    return (
        <span className={`
            inline-flex items-center gap-1
            px-2 py-1 rounded text-xs font-medium
            ${config.bgColor} ${config.color}
        `}>
            <span>{config.icon}</span>
            <span>{config.label}</span>
        </span>
    )
}

// Usage:
<StatusIndicator status="hard_lead" />
<StatusIndicator status="existing" />
```

**What's happening:**
1. Component receives `status` prop
2. Looks up config from `STATUS_CONFIG` constant
3. Returns a `<span>` with dynamic classes and content
4. React renders it to the DOM

**Python analogy:**

```python
def status_indicator(status: str) -> str:
    config = STATUS_CONFIG[status]
    return f'<span class="{config["bgColor"]} {config["color"]}">{config["icon"]} {config["label"]}</span>'
```

---

## Why This Matters for Provider Search

**Our entire app is React components:**

```
App.tsx (routes)
├── AppSearch.tsx (search page)
│   ├── SearchBar (input + button)
│   ├── ProviderList (results)
│   │   └── ProviderCard (individual result)
│   │       └── StatusIndicator (status badge)
│   └── ProviderMap (Leaflet map)
└── AuthContext (auth state provider)
```

**Each component:**
- Is a function that returns JSX
- Receives data via props
- Re-renders when props/state change
- Handles events (clicks, form submissions, etc.)

**To understand a component:**
1. Look at its props (function parameters)
2. See what it returns (JSX structure)
3. Check for event handlers (onClick, onChange, etc.)
4. Look for state (useState) — covered in next guide

---

## Next Steps

- **[07-react-state-and-hooks.md](07-react-state-and-hooks.md)** — Making components interactive with state
- **[08-react-context-and-global-state.md](08-react-context-and-global-state.md)** — Sharing state across components

---

**You now understand React components. Next: making them interactive with state.**
