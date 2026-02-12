# JavaScript Async and the Event Loop

**Understanding Asynchronous JavaScript: From Callbacks to Async/Await**

JavaScript is single-threaded but non-blocking. This sounds impossible, but it's the secret to how browsers stay responsive while making API calls. Let's understand how.

---

## Table of Contents

1. [The Event Loop: JavaScript's Magic](#the-event-loop-javascripts-magic)
2. [Callbacks: The Original Async Pattern](#callbacks-the-original-async-pattern)
3. [Promises: A Better Way](#promises-a-better-way)
4. [Async/Await: The Modern Way](#asyncawait-the-modern-way)
5. [The fetch() API](#the-fetch-api)
6. [Promise.all and Promise.race](#promiseall-and-promiserace)
7. [Error Handling in Async Code](#error-handling-in-async-code)
8. [Real Examples from Provider Search](#real-examples-from-provider-search)

---

## The Event Loop: JavaScript's Magic

### Python: Threads and asyncio

```python
# Python: Blocking call (thread waits)
import requests
response = requests.get("https://api.example.com/data")
print("Got response!")  # This line waits for the request

# Python asyncio: Explicit async/await
import asyncio
import httpx

async def fetch_data():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()

# Have to run in an event loop
asyncio.run(fetch_data())
```

### JavaScript: Always Non-Blocking

```javascript
// JavaScript: Non-blocking by default
fetch("https://api.example.com/data")
console.log("Request started, but moving on!")  // Runs immediately!

// The response arrives later, in a callback:
fetch("https://api.example.com/data")
    .then(response => response.json())
    .then(data => console.log("Got response!", data))
```

### Why Is JavaScript Different?

**Python:** Multi-threaded by nature. Blocking I/O is the default. You opt-in to async with `asyncio`.

**JavaScript:** Single-threaded by design. It MUST be non-blocking or the browser UI would freeze on every network request.

### The Event Loop Model

```
┌─────────────────────────────────────┐
│       JavaScript Execution          │
│       (Call Stack)                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Your synchronous code      │   │
│  │  runs here, line by line    │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│       Web APIs                      │
│  ┌──────────┐  ┌──────────┐        │
│  │  setTimeout │  fetch()   │       │
│  │  DOM events │  etc.      │       │
│  └──────────┘  └──────────┘        │
└─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│       Callback Queue                │
│  ┌──────────────────────────────┐  │
│  │ Waiting callbacks            │  │
│  │ (to run when stack is empty) │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
                │
                ▼ (when call stack empty)
          Back to top!
```

**How it works:**

1. **Call Stack:** Your code runs synchronously, line by line
2. **Web APIs:** Async operations (fetch, setTimeout, etc.) are handed off to the browser
3. **Callback Queue:** When async operations complete, their callbacks wait here
4. **Event Loop:** Continuously checks: "Is the call stack empty? If yes, move next callback from queue to stack."

### Example: setTimeout

```javascript
console.log("1: Start")

setTimeout(() => {
    console.log("2: Inside timeout")
}, 0)  // Zero delay!

console.log("3: End")

// Output:
// 1: Start
// 3: End
// 2: Inside timeout   <-- Even with 0ms delay, runs last!
```

**Why?** The callback goes to the queue and waits for the call stack to be empty.

### Compare to Python

| Python | JavaScript |
|--------|------------|
| Multi-threaded runtime | Single-threaded runtime |
| Blocking I/O by default | Non-blocking I/O by default |
| Opt-in async with `asyncio` | Always async for I/O |
| GIL limits true parallelism | True single-thread (no GIL) |
| Thread.sleep() blocks thread | setTimeout() doesn't block |

---

## Callbacks: The Original Async Pattern

### Python: Callbacks Are Rare

```python
# Python doesn't use callbacks much
# More common: just return values or use asyncio
def process_data(data):
    return data * 2

result = process_data(5)
```

### JavaScript: Callbacks Everywhere (Historically)

```javascript
// Old-style callback pattern
function fetchData(callback) {
    setTimeout(() => {
        const data = { name: "Blake" }
        callback(data)  // Call the callback with result
    }, 1000)
}

// Using it:
fetchData((data) => {
    console.log("Got data:", data)
})

console.log("Request started")  // Runs immediately
```

### Callback Hell (Why Callbacks Suck)

```javascript
// Nested callbacks = "Pyramid of Doom"
fetchUser((user) => {
    fetchPosts(user.id, (posts) => {
        fetchComments(posts[0].id, (comments) => {
            console.log("Finally got comments:", comments)
        })
    })
})
```

**Problem:** Hard to read, hard to handle errors, hard to maintain. This is why Promises were invented.

---

## Promises: A Better Way

### What Is a Promise?

A **Promise** is an object representing a value that will be available in the future (or an error).

**States:**
- **Pending:** Operation in progress
- **Fulfilled:** Operation succeeded, value available
- **Rejected:** Operation failed, error available

```javascript
// Creating a promise
const promise = new Promise((resolve, reject) => {
    setTimeout(() => {
        const success = true
        if (success) {
            resolve("Operation succeeded!")  // Fulfill
        } else {
            reject("Operation failed!")      // Reject
        }
    }, 1000)
})

// Using a promise
promise
    .then(result => {
        console.log(result)  // "Operation succeeded!"
    })
    .catch(error => {
        console.log(error)   // "Operation failed!"
    })
```

### Promise Chaining

```javascript
fetch("/api/user")
    .then(response => response.json())    // Parse JSON
    .then(user => fetch(`/api/posts/${user.id}`))  // Fetch posts
    .then(response => response.json())    // Parse JSON
    .then(posts => {
        console.log("User posts:", posts)
    })
    .catch(error => {
        console.error("Something failed:", error)
    })
```

**Better than callbacks:** Linear, not nested. Errors bubble up to one `.catch()`.

### Python asyncio Comparison

| Python asyncio | JavaScript Promises |
|---------------|---------------------|
| `async def func()` | Returns a Promise |
| `await func()` | `.then()` or `await` |
| `try/except` | `.catch()` or `try/catch` |

```python
# Python
async def fetch_data():
    response = await httpx.get("/api/data")
    return response.json()

try:
    data = await fetch_data()
except Exception as e:
    print(f"Error: {e}")
```

```javascript
// JavaScript (Promise style)
function fetchData() {
    return fetch("/api/data")
        .then(response => response.json())
}

fetchData()
    .then(data => console.log(data))
    .catch(error => console.error(error))
```

---

## Async/Await: The Modern Way

### Python-Style Async in JavaScript

```javascript
// Modern JavaScript looks like Python asyncio!
async function fetchData() {
    const response = await fetch("/api/data")
    const data = await response.json()
    return data
}

// Using it:
try {
    const data = await fetchData()
    console.log(data)
} catch (error) {
    console.error("Error:", error)
}
```

**Key rule:** You can only use `await` inside an `async` function.

### Converting Promises to Async/Await

**Promise style:**
```javascript
function getUser() {
    return fetch("/api/user")
        .then(response => response.json())
        .then(user => {
            return fetch(`/api/posts/${user.id}`)
        })
        .then(response => response.json())
        .then(posts => {
            return { user, posts }
        })
}
```

**Async/await style:**
```javascript
async function getUser() {
    const userResponse = await fetch("/api/user")
    const user = await userResponse.json()
    
    const postsResponse = await fetch(`/api/posts/${user.id}`)
    const posts = await postsResponse.json()
    
    return { user, posts }
}
```

**Much more readable!** Looks like synchronous code, but it's non-blocking.

### Async Functions Always Return Promises

```javascript
async function getValue() {
    return 42  // Wrapped in a Promise automatically
}

// This is equivalent to:
function getValue() {
    return Promise.resolve(42)
}

// Using it:
getValue().then(value => console.log(value))  // 42

// Or:
const value = await getValue()  // 42
```

---

## The fetch() API

### Making HTTP Requests

```python
# Python requests library
import requests

response = requests.get("https://api.example.com/data")
data = response.json()

# With headers
response = requests.get(
    "https://api.example.com/data",
    headers={"Authorization": "Bearer token"}
)

# POST request
response = requests.post(
    "https://api.example.com/create",
    json={"name": "Blake"}
)
```

```javascript
// JavaScript fetch API

// GET request
const response = await fetch("https://api.example.com/data")
const data = await response.json()

// With headers
const response = await fetch("https://api.example.com/data", {
    headers: {
        "Authorization": "Bearer token"
    }
})

// POST request
const response = await fetch("https://api.example.com/create", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ name: "Blake" })
})
```

### fetch() Options

```javascript
const response = await fetch(url, {
    method: "GET",           // GET, POST, PUT, DELETE, etc.
    headers: { },            // Request headers
    body: JSON.stringify(),  // Request body (not for GET)
    credentials: "include",  // Include cookies
    signal: abortController.signal  // For cancellation
})
```

### Response Object

```javascript
const response = await fetch("/api/data")

// Status
console.log(response.ok)        // true if 200-299
console.log(response.status)    // 200, 404, 500, etc.
console.log(response.statusText)  // "OK", "Not Found", etc.

// Parse body
const data = await response.json()     // Parse JSON
const text = await response.text()     // Get as text
const blob = await response.blob()     // Get as binary

// Headers
const contentType = response.headers.get("Content-Type")
```

### Error Handling with fetch()

**Important:** `fetch()` only rejects on network errors, NOT on HTTP errors (404, 500, etc.)!

```javascript
// BAD: Doesn't catch HTTP errors
try {
    const response = await fetch("/api/data")
    const data = await response.json()
} catch (error) {
    console.error(error)  // Only catches network errors!
}

// GOOD: Check response.ok
try {
    const response = await fetch("/api/data")
    
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
    }
    
    const data = await response.json()
} catch (error) {
    console.error("Fetch failed:", error)
}
```

---

## Promise.all and Promise.race

### Running Multiple Promises in Parallel

```python
# Python: asyncio.gather
import asyncio

async def fetch_multiple():
    results = await asyncio.gather(
        fetch_users(),
        fetch_posts(),
        fetch_comments()
    )
    return results
```

```javascript
// JavaScript: Promise.all
const results = await Promise.all([
    fetch("/api/users"),
    fetch("/api/posts"),
    fetch("/api/comments")
])

const [usersResponse, postsResponse, commentsResponse] = results

const users = await usersResponse.json()
const posts = await postsResponse.json()
const comments = await commentsResponse.json()
```

**When to use:** When you have multiple independent async operations that can run in parallel.

### Promise.race (First to Finish Wins)

```javascript
// Timeout pattern: race between fetch and timeout
const fetchWithTimeout = async (url, timeout = 5000) => {
    const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Timeout")), timeout)
    )
    
    const response = await Promise.race([
        fetch(url),
        timeoutPromise
    ])
    
    return response
}
```

---

## Error Handling in Async Code

### Try/Catch with Async/Await

```javascript
async function fetchData() {
    try {
        const response = await fetch("/api/data")
        
        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`)
        }
        
        const data = await response.json()
        return data
        
    } catch (error) {
        console.error("Fetch failed:", error.message)
        throw error  // Re-throw if you want caller to handle
    }
}
```

### Handling Errors in Promise Chains

```javascript
fetch("/api/data")
    .then(response => {
        if (!response.ok) {
            throw new Error("HTTP error")
        }
        return response.json()
    })
    .then(data => {
        console.log(data)
    })
    .catch(error => {
        console.error("Error:", error)
    })
    .finally(() => {
        console.log("Cleanup (runs regardless of success/failure)")
    })
```

---

## Real Examples from Provider Search

### Our API Client (web/src/api/client.ts)

```javascript
export async function apiCall<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  // Get auth token
  let token: string | null = null
  try {
    token = await getAccessToken()
  } catch {
    token = null
  }

  // Build headers
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> || {}),
  }

  if (options.body && !(options.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json'
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  // Make request
  let response: Response
  try {
    response = await fetch(`/api${endpoint}`, {
      ...options,
      headers,
    })
  } catch (err) {
    // Handle network errors
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw new Error('Request was cancelled')
    }
    throw err
  }

  // Check for HTTP errors
  if (!response.ok) {
    const errorBody = await response.json().catch(() => null)
    const detail = errorBody?.detail || errorBody?.message || null
    const message = detail || `Request failed: ${response.status}`
    throw new ApiError(response.status, message, detail)
  }

  // Handle 204 No Content
  if (response.status === 204) {
    return undefined as T
  }

  return response.json()
}
```

**What's happening:**
1. Get auth token (async)
2. Build request with headers
3. Make fetch call (async)
4. Check for errors (HTTP and network)
5. Parse response (async)

### Using Our API Client (web/src/api/search.ts)

```javascript
import { useQuery } from '@tanstack/react-query'
import { apiCall } from './client'

export function useSearchQuery(query: string, radius: number) {
  return useQuery({
    queryKey: ['search', query, radius],
    queryFn: async () => {
      const response = await apiCall<SearchResponse>('/search', {
        method: 'POST',
        body: JSON.stringify({
          query,
          radius_miles: radius,
          max_results: 100
        })
      })
      return response
    },
    enabled: query.length > 0,  // Don't run if query empty
    staleTime: 5 * 60 * 1000,   // Cache for 5 minutes
  })
}
```

**Pattern:**
- React Query hook wraps our async API call
- Returns loading state, data, and error automatically
- Handles caching and refetching

### In a Component

```javascript
function SearchPage() {
  const [query, setQuery] = useState("")
  const [radius, setRadius] = useState(25)
  
  const { data, isLoading, error } = useSearchQuery(query, radius)
  
  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>
  
  return (
    <div>
      {data.providers.map(provider => (
        <ProviderCard key={provider.place_id} provider={provider} />
      ))}
    </div>
  )
}
```

**The async complexity is hidden:** Component doesn't use `async`/`await` directly. React Query handles it.

---

## Summary: Python ↔ JavaScript Async

| Python asyncio | JavaScript |
|---------------|------------|
| `async def func()` | `async function func()` |
| `await func()` | `await func()` |
| `asyncio.gather()` | `Promise.all()` |
| `asyncio.wait()` with timeout | `Promise.race()` |
| `async with` | Not built-in (use try/finally) |
| `httpx.AsyncClient` | `fetch()` API |

### Key Differences

1. **JavaScript is async by default for I/O** — you don't opt in, you opt out
2. **Event loop is always running** — browser manages it, you don't call `asyncio.run()`
3. **Promises are first-class** — returned by all async APIs
4. **Async/await is syntactic sugar** — over Promises (which are sugar over callbacks)

---

## Why This Matters for Provider Search

**Every API call in our app is async:**
- Searching for providers: `fetch()` → Promise → async/await
- Loading auth state: `getSession()` → async
- Fetching provider details: `apiCall()` → async

**React Query handles most of it:**
- We write async functions (`queryFn`)
- React Query manages loading states, errors, caching
- Components just use the data

**Understanding async is critical for:**
- Debugging loading states
- Understanding component re-renders (when data arrives)
- Writing new API calls
- Handling errors properly

---

## Next Steps

- **[03-typescript-essentials.md](03-typescript-essentials.md)** — Add types to async code
- **[11-data-fetching-and-server-state.md](11-data-fetching-and-server-state.md)** — Deep dive into React Query

Or try:
- **[browser-tools/network-inspector.html](browser-tools/network-inspector.html)** — Make API calls and see requests/responses

---

**You now understand async JavaScript. This is the foundation for all API interactions in modern web apps.**
