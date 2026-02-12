# React State and Hooks

**Making Components Interactive**

State is what makes React components dynamic. When state changes, React automatically re-renders. Hooks are functions that let you "hook into" React features like state.

---

## Table of Contents

1. [What Is State?](#what-is-state)
2. [useState: Component State](#usestate-component-state)
3. [useEffect: Side Effects and Lifecycle](#useeffect-side-effects-and-lifecycle)
4. [The Rules of Hooks](#the-rules-of-hooks)
5. [useCallback and useMemo](#usecallback-and-usememo)
6. [Custom Hooks](#custom-hooks)
7. [useRef: Accessing DOM Elements](#useref-accessing-dom-elements)
8. [State Management Patterns](#state-management-patterns)
9. [Real Example: useProviderStatuses](#real-example-useproviderstatuses)

---

## What Is State?

### Python Class with Instance Variables

```python
class Counter:
    def __init__(self):
        self.count = 0  # State
    
    def increment(self):
        self.count += 1
        self.render()  # Re-render UI
    
    def render(self):
        return f"<div>Count: {self.count}</div>"

counter = Counter()
counter.increment()  # count = 1, UI updates
```

### React Component with State

```javascript
import { useState } from 'react'

function Counter() {
    const [count, setCount] = useState(0)  // State
    
    function increment() {
        setCount(count + 1)  // Update state → React re-renders
    }
    
    return (
        <div>
            <p>Count: {count}</p>
            <button onClick={increment}>Increment</button>
        </div>
    )
}
```

**Key difference:** React automatically re-renders when state changes. You don't call `render()` manually.

---

## useState: Component State

### Basic Usage

```javascript
import { useState } from 'react'

function Component() {
    // [currentValue, setterFunction] = useState(initialValue)
    const [count, setCount] = useState(0)
    const [name, setName] = useState("Blake")
    const [isLoading, setIsLoading] = useState(false)
    
    return <div>...</div>
}
```

**useState returns an array:**
1. Current state value
2. Function to update the state

### Updating State

```javascript
function Counter() {
    const [count, setCount] = useState(0)
    
    // ✅ Correct: Call setter function
    function increment() {
        setCount(count + 1)
    }
    
    // ❌ Wrong: Don't mutate state directly
    function broken() {
        count = count + 1  // This won't re-render!
    }
    
    return (
        <div>
            <p>Count: {count}</p>
            <button onClick={increment}>Increment</button>
        </div>
    )
}
```

### Functional Updates

```javascript
function Counter() {
    const [count, setCount] = useState(0)
    
    // Problem: Stale closure
    function incrementTwice() {
        setCount(count + 1)  // count is 0
        setCount(count + 1)  // count is still 0! (stale)
        // Result: count becomes 1, not 2
    }
    
    // Solution: Functional update
    function incrementTwiceProperly() {
        setCount(prev => prev + 1)  // prev is current value
        setCount(prev => prev + 1)  // prev is updated value
        // Result: count becomes 2 ✅
    }
    
    return <button onClick={incrementTwiceProperly}>+2</button>
}
```

### State with Objects and Arrays

```javascript
function Form() {
    const [user, setUser] = useState({ name: "", email: "" })
    
    // ❌ Wrong: Mutating state
    function updateName(name) {
        user.name = name  // Don't do this!
        setUser(user)
    }
    
    // ✅ Correct: Create new object
    function updateNameCorrectly(name) {
        setUser({ ...user, name })  // Spread operator
    }
    
    // Arrays: Similar pattern
    const [items, setItems] = useState([])
    
    function addItem(item) {
        setItems([...items, item])  // Create new array
    }
    
    function removeItem(index) {
        setItems(items.filter((_, i) => i !== index))
    }
}
```

**Rule:** State should be treated as immutable. Always create new objects/arrays.

---

## useEffect: Side Effects and Lifecycle

### What Are Side Effects?

**Side effects = operations outside React's rendering:**
- Fetching data from APIs
- Setting up subscriptions
- Timers (setTimeout, setInterval)
- Modifying the DOM directly
- Logging to console

### Basic Usage

```javascript
import { useState, useEffect } from 'react'

function Component() {
    const [data, setData] = useState(null)
    
    useEffect(() => {
        // This runs after render
        console.log("Component rendered")
        
        // Fetch data
        fetch("/api/data")
            .then(r => r.json())
            .then(setData)
    }, [])  // Dependency array (empty = run once)
    
    return <div>{data ? data.message : "Loading..."}</div>
}
```

### Dependency Array

```javascript
// Run once on mount
useEffect(() => {
    console.log("Mounted")
}, [])

// Run on every render
useEffect(() => {
    console.log("Every render")
})  // No dependency array

// Run when specific values change
useEffect(() => {
    console.log("Count changed:", count)
}, [count])  // Re-run when count changes

// Multiple dependencies
useEffect(() => {
    console.log("Query or radius changed")
}, [query, radius])
```

### Python Comparison: __init__ and Cleanup

```python
class Component:
    def __init__(self):
        # Setup (like useEffect on mount)
        self.data = self.fetch_data()
    
    def __del__(self):
        # Cleanup (like useEffect cleanup)
        self.connection.close()
```

```javascript
function Component() {
    useEffect(() => {
        // Setup (on mount)
        const connection = connectToServer()
        
        // Cleanup (on unmount)
        return () => {
            connection.close()
        }
    }, [])
}
```

### Real Example: Fetch Data

```javascript
function ProviderDetails({ providerId }) {
    const [provider, setProvider] = useState(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)
    
    useEffect(() => {
        setLoading(true)
        
        fetch(`/api/providers/${providerId}`)
            .then(response => {
                if (!response.ok) throw new Error("Failed to fetch")
                return response.json()
            })
            .then(data => {
                setProvider(data)
                setLoading(false)
            })
            .catch(err => {
                setError(err.message)
                setLoading(false)
            })
    }, [providerId])  // Re-fetch when providerId changes
    
    if (loading) return <div>Loading...</div>
    if (error) return <div>Error: {error}</div>
    return <div>{provider.name}</div>
}
```

### Cleanup Example: Event Listeners

```javascript
function WindowSize() {
    const [size, setSize] = useState(window.innerWidth)
    
    useEffect(() => {
        // Setup: Add event listener
        function handleResize() {
            setSize(window.innerWidth)
        }
        
        window.addEventListener("resize", handleResize)
        
        // Cleanup: Remove event listener
        return () => {
            window.removeEventListener("resize", handleResize)
        }
    }, [])  // Run once
    
    return <div>Window width: {size}px</div>
}
```

---

## The Rules of Hooks

### Rule 1: Only Call Hooks at Top Level

```javascript
// ❌ Wrong: Hook inside conditional
function Component({ condition }) {
    if (condition) {
        const [state, setState] = useState(0)  // Error!
    }
}

// ✅ Correct: Hook at top level
function Component({ condition }) {
    const [state, setState] = useState(0)
    
    if (condition) {
        // Use state here
    }
}
```

**Why:** React relies on hook call order to track state between renders.

### Rule 2: Only Call Hooks in React Functions

```javascript
// ❌ Wrong: Hook in regular function
function regularFunction() {
    const [state, setState] = useState(0)  // Error!
}

// ✅ Correct: Hook in component
function Component() {
    const [state, setState] = useState(0)  // OK
}

// ✅ Correct: Hook in custom hook
function useCustomHook() {
    const [state, setState] = useState(0)  // OK
}
```

---

## useCallback and useMemo

### useCallback: Memoize Functions

```javascript
function Parent() {
    const [count, setCount] = useState(0)
    
    // Without useCallback: New function on every render
    const handleClick = () => {
        console.log("Clicked")
    }
    
    // With useCallback: Same function reference
    const handleClickMemoized = useCallback(() => {
        console.log("Clicked")
    }, [])  // Dependencies
    
    return <Child onClick={handleClickMemoized} />
}
```

**Use when:** Passing callbacks to optimized child components (with `React.memo`).

### useMemo: Memoize Values

```javascript
function Component({ providers }) {
    // Expensive calculation
    const hardLeads = useMemo(() => {
        return providers.filter(p => p.status === "hard_lead")
    }, [providers])  // Only recalculate when providers change
    
    return <div>Hard leads: {hardLeads.length}</div>
}
```

**Use when:** Expensive calculations that don't need to run on every render.

### When NOT to Use Them

```javascript
// ❌ Premature optimization
const sum = useMemo(() => a + b, [a, b])  // Overkill for simple math

// ✅ Just do it
const sum = a + b
```

**Rule:** Don't optimize until you have a performance problem.

---

## Custom Hooks

### Extracting Reusable Logic

```javascript
// Custom hook: Reusable stateful logic
function useToggle(initialValue = false) {
    const [value, setValue] = useState(initialValue)
    
    const toggle = useCallback(() => {
        setValue(v => !v)
    }, [])
    
    return [value, toggle]
}

// Using it:
function Component() {
    const [isOpen, toggleOpen] = useToggle(false)
    
    return (
        <div>
            {isOpen && <div>Content</div>}
            <button onClick={toggleOpen}>Toggle</button>
        </div>
    )
}
```

### Custom Hook: Fetch Data

```javascript
function useFetch(url) {
    const [data, setData] = useState(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)
    
    useEffect(() => {
        setLoading(true)
        
        fetch(url)
            .then(r => r.json())
            .then(setData)
            .catch(setError)
            .finally(() => setLoading(false))
    }, [url])
    
    return { data, loading, error }
}

// Using it:
function Component() {
    const { data, loading, error } = useFetch("/api/providers")
    
    if (loading) return <div>Loading...</div>
    if (error) return <div>Error</div>
    return <div>{data.length} providers</div>
}
```

**Custom hook rules:**
- Name must start with `use`
- Can call other hooks inside
- Returns whatever you want (array, object, value, etc.)

---

## useRef: Accessing DOM Elements

### Getting Direct DOM Access

```javascript
import { useRef, useEffect } from 'react'

function InputFocus() {
    const inputRef = useRef(null)
    
    useEffect(() => {
        // Focus input on mount
        inputRef.current.focus()
    }, [])
    
    return <input ref={inputRef} type="text" />
}
```

### Storing Mutable Values

```javascript
function Timer() {
    const [count, setCount] = useState(0)
    const intervalRef = useRef(null)
    
    function start() {
        intervalRef.current = setInterval(() => {
            setCount(c => c + 1)
        }, 1000)
    }
    
    function stop() {
        clearInterval(intervalRef.current)
    }
    
    useEffect(() => {
        return () => clearInterval(intervalRef.current)
    }, [])
    
    return (
        <div>
            <p>Count: {count}</p>
            <button onClick={start}>Start</button>
            <button onClick={stop}>Stop</button>
        </div>
    )
}
```

**useRef vs useState:**
- `useState` → triggers re-render when updated
- `useRef` → doesn't trigger re-render (mutable value)

---

## State Management Patterns

### Local State (Component-Level)

```javascript
// State used only in this component
function SearchBar() {
    const [query, setQuery] = useState("")
    
    return <input value={query} onChange={e => setQuery(e.target.value)} />
}
```

### Lifted State (Parent-Child)

```javascript
// State in parent, passed to children
function SearchPage() {
    const [query, setQuery] = useState("")
    
    return (
        <div>
            <SearchBar query={query} setQuery={setQuery} />
            <SearchResults query={query} />
        </div>
    )
}

function SearchBar({ query, setQuery }) {
    return <input value={query} onChange={e => setQuery(e.target.value)} />
}

function SearchResults({ query }) {
    return <div>Searching for: {query}</div>
}
```

### Context (Global State)

```javascript
// State accessible anywhere (covered in next guide)
const ThemeContext = createContext()

function App() {
    const [theme, setTheme] = useState("light")
    
    return (
        <ThemeContext.Provider value={{ theme, setTheme }}>
            <Navigation />
            <Content />
        </ThemeContext.Provider>
    )
}
```

---

## Real Example: useProviderStatuses

### From Provider Search

```typescript
// web/src/hooks/useProviderStatuses.ts (simplified)
import { useState, useEffect, useCallback } from 'react'
import { apiCall } from '../api/client'
import type { PlaceStatusMap } from '../types/provider'

export function useProviderStatuses(placeIds: string[]) {
    const [statuses, setStatuses] = useState<PlaceStatusMap>({})
    const [loading, setLoading] = useState(false)
    
    const fetchStatuses = useCallback(async () => {
        if (placeIds.length === 0) return
        
        setLoading(true)
        try {
            const response = await apiCall<PlaceStatusMap>('/provider/status', {
                method: 'POST',
                body: JSON.stringify({ place_ids: placeIds })
            })
            setStatuses(response)
        } catch (error) {
            console.error("Failed to fetch statuses:", error)
        } finally {
            setLoading(false)
        }
    }, [placeIds])
    
    useEffect(() => {
        fetchStatuses()
    }, [fetchStatuses])
    
    return { statuses, loading, refetch: fetchStatuses }
}

// Usage in component:
function ProviderList({ providers }) {
    const placeIds = providers.map(p => p.place_id)
    const { statuses, loading } = useProviderStatuses(placeIds)
    
    return (
        <div>
            {providers.map(provider => (
                <ProviderCard
                    key={provider.place_id}
                    provider={provider}
                    status={statuses[provider.place_id]}
                />
            ))}
        </div>
    )
}
```

**What's happening:**
1. Custom hook manages provider status state
2. Fetches statuses when `placeIds` change
3. Returns statuses and loading state
4. Component uses hook, displays results

---

## Why This Matters for Provider Search

**State is everywhere in our app:**

```
AppSearch.tsx
├── useState(query)           → Search query
├── useState(radius)          → Search radius
├── useState(selectedProvider) → Map selection
└── useSearchQuery()          → React Query hook (API state)

AuthContext.tsx
├── useState(session)         → Auth session
└── useState(loading)         → Loading state

ProviderMap.tsx
├── useState(mapCenter)       → Map position
└── useRef(mapRef)            → Leaflet map instance
```

**Understanding state means understanding:**
- When components re-render
- How data flows through the app
- Where to put new state
- How to debug state-related issues

---

## Next Steps

- **[08-react-context-and-global-state.md](08-react-context-and-global-state.md)** — Share state across components
- **[11-data-fetching-and-server-state.md](11-data-fetching-and-server-state.md)** — React Query (server state management)

---

**You now understand React state and hooks. This is the key to interactive UIs.**
