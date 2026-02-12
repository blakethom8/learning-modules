# React Context and Global State

**Sharing State Without Prop Drilling**

Context lets you pass data through the component tree without manually passing props at every level. Think of it as "global variables" for React.

---

## Table of Contents

1. [The Problem: Prop Drilling](#the-problem-prop-drilling)
2. [Context API: Global State](#context-api-global-state)
3. [Creating a Context](#creating-a-context)
4. [Provider Pattern](#provider-pattern)
5. [Our AuthContext: Real Example](#our-authcontext-real-example)
6. [When to Use Context vs Props](#when-to-use-context-vs-props)
7. [Alternatives: Redux, Zustand, Jotai](#alternatives-redux-zustand-jotai)

---

## The Problem: Prop Drilling

### Passing Props Through Many Levels

```javascript
// App needs to pass user to deeply nested components
function App() {
    const [user, setUser] = useState({ name: "Blake", role: "admin" })
    
    return <Dashboard user={user} />
}

function Dashboard({ user }) {
    return <Sidebar user={user} />  // Just passing through
}

function Sidebar({ user }) {
    return <Navigation user={user} />  // Just passing through
}

function Navigation({ user }) {
    return <UserMenu user={user} />  // Just passing through
}

function UserMenu({ user }) {
    return <div>Welcome, {user.name}!</div>  // Finally used!
}
```

**Problem:** `Dashboard`, `Sidebar`, and `Navigation` don't use `user` — they just pass it down. This is **prop drilling**.

---

## Context API: Global State

### Solution: Context

```javascript
import { createContext, useContext, useState } from 'react'

// 1. Create context
const UserContext = createContext()

// 2. Provider wraps app
function App() {
    const [user, setUser] = useState({ name: "Blake", role: "admin" })
    
    return (
        <UserContext.Provider value={{ user, setUser }}>
            <Dashboard />
        </UserContext.Provider>
    )
}

// 3. Intermediate components don't need props
function Dashboard() {
    return <Sidebar />  // No user prop!
}

function Sidebar() {
    return <Navigation />
}

function Navigation() {
    return <UserMenu />
}

// 4. Deep component accesses context directly
function UserMenu() {
    const { user } = useContext(UserContext)  // Get from context
    return <div>Welcome, {user.name}!</div>
}
```

**Key insight:** Context "tunnels" through the tree. Intermediate components don't need to know about it.

---

## Creating a Context

### Basic Pattern

```javascript
// 1. Create context
const ThemeContext = createContext()

// 2. Create provider component (common pattern)
function ThemeProvider({ children }) {
    const [theme, setTheme] = useState("light")
    
    const toggleTheme = () => {
        setTheme(t => t === "light" ? "dark" : "light")
    }
    
    return (
        <ThemeContext.Provider value={{ theme, toggleTheme }}>
            {children}
        </ThemeContext.Provider>
    )
}

// 3. Create custom hook (convenience)
function useTheme() {
    const context = useContext(ThemeContext)
    if (!context) {
        throw new Error("useTheme must be used within ThemeProvider")
    }
    return context
}

// 4. Export
export { ThemeProvider, useTheme }
```

### Using It

```javascript
// In App.tsx
import { ThemeProvider } from './contexts/ThemeContext'

function App() {
    return (
        <ThemeProvider>
            <Navigation />
            <Content />
        </ThemeProvider>
    )
}

// In any component
import { useTheme } from './contexts/ThemeContext'

function ThemeToggle() {
    const { theme, toggleTheme } = useTheme()
    
    return (
        <button onClick={toggleTheme}>
            Current theme: {theme}
        </button>
    )
}
```

---

## Provider Pattern

### Wrapping Your App

```javascript
// main.tsx (entry point)
import { QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import { ThemeProvider } from './contexts/ThemeContext'

ReactDOM.createRoot(document.getElementById('root')).render(
    <QueryClientProvider client={queryClient}>
        <BrowserRouter>
            <AuthProvider>
                <ThemeProvider>
                    <App />
                </ThemeProvider>
            </AuthProvider>
        </BrowserRouter>
    </QueryClientProvider>
)
```

**Providers stack:** Each provider wraps its children, creating layers of context.

---

## Our AuthContext: Real Example

### From Provider Search

```typescript
// web/src/contexts/AuthContext.tsx (simplified)
import { createContext, useContext, useEffect, useState } from 'react'
import type { AuthSession, AuthUser } from '../lib/auth'
import * as authClient from '../lib/auth'

interface AuthContextType {
    session: AuthSession | null
    user: AuthUser | null
    loading: boolean
    signIn: (email: string, password: string) => Promise<{ error: string | null }>
    signUp: (email: string, password: string) => Promise<{ error: string | null }>
    signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
    const [session, setSession] = useState<AuthSession | null>(null)
    const [loading, setLoading] = useState(true)
    
    // Load session on mount
    useEffect(() => {
        authClient.getSession()
            .then(setSession)
            .catch(() => setSession(null))
            .finally(() => setLoading(false))
    }, [])
    
    const signIn = async (email: string, password: string) => {
        const { session: newSession, error } = await authClient.signIn(email, password)
        if (newSession) {
            setSession(newSession)
        }
        return { error }
    }
    
    const signOut = async () => {
        await authClient.signOut()
        setSession(null)
    }
    
    const user = session?.user || null
    
    return (
        <AuthContext.Provider value={{ session, user, loading, signIn, signOut }}>
            {children}
        </AuthContext.Provider>
    )
}

export function useAuth() {
    const context = useContext(AuthContext)
    if (context === undefined) {
        throw new Error('useAuth must be used within AuthProvider')
    }
    return context
}
```

### Using AuthContext

```typescript
// In any component
import { useAuth } from '../contexts/AuthContext'

function Navigation() {
    const { user, signOut } = useAuth()
    
    if (!user) {
        return <Link to="/login">Log In</Link>
    }
    
    return (
        <div>
            <span>Welcome, {user.email}</span>
            <button onClick={signOut}>Log Out</button>
        </div>
    )
}

// In ProtectedRoute component
function ProtectedRoute({ children }) {
    const { user, loading } = useAuth()
    
    if (loading) return <div>Loading...</div>
    if (!user) return <Navigate to="/login" />
    return children
}
```

**What's happening:**
1. `AuthProvider` wraps app in `main.tsx`
2. Loads session from Supabase on mount
3. Provides `user`, `session`, and auth methods to all components
4. Any component can call `useAuth()` to get current user

---

## When to Use Context vs Props

### Use Props When

✅ Data only needed by immediate children
✅ Data changes frequently
✅ Data is specific to a feature/component
✅ Clear parent-child relationship

```javascript
// Good: Props for immediate children
function SearchPage() {
    const [query, setQuery] = useState("")
    
    return (
        <div>
            <SearchBar query={query} setQuery={setQuery} />
            <SearchResults query={query} />
        </div>
    )
}
```

### Use Context When

✅ Data needed by many components
✅ Data doesn't change often
✅ Data is truly "global" (theme, auth, language)
✅ Would require prop drilling otherwise

```javascript
// Good: Context for global data
<AuthProvider>
    <ThemeProvider>
        <App />
    </ThemeProvider>
</AuthProvider>
```

### Anti-Pattern: Context for Everything

```javascript
// ❌ Bad: Context for local state
const SearchContext = createContext()

function SearchProvider({ children }) {
    const [query, setQuery] = useState("")
    const [results, setResults] = useState([])
    return (
        <SearchContext.Provider value={{ query, setQuery, results, setResults }}>
            {children}
        </SearchContext.Provider>
    )
}

// This should just be props or lifted state!
```

**Rule:** Context is for truly global/shared state. Don't overuse it.

---

## Alternatives: Redux, Zustand, Jotai

### When You'd Need External State Management

**Context is enough for:**
- Auth state
- Theme/language
- Simple global settings

**You might need more when:**
- Complex state logic (many actions, reducers)
- Performance issues (context re-renders everything)
- Need devtools, time-travel debugging
- Large-scale app with many global states

### Redux (Heavy, Powerful)

```javascript
// Redux: Explicit actions and reducers
const store = createStore(reducer)

// Dispatch actions
store.dispatch({ type: 'INCREMENT' })

// Complex, but scales well for large apps
```

**Use when:** Large team, complex state logic, need strict patterns.

### Zustand (Lightweight, Simple)

```javascript
// Zustand: Simpler than Redux
import create from 'zustand'

const useStore = create((set) => ({
    count: 0,
    increment: () => set(state => ({ count: state.count + 1 }))
}))

// Use in component
function Counter() {
    const { count, increment } = useStore()
    return <button onClick={increment}>{count}</button>
}
```

**Use when:** Need more than Context, don't want Redux complexity.

### Jotai (Atomic State)

```javascript
// Jotai: Atom-based (like Recoil)
import { atom, useAtom } from 'jotai'

const countAtom = atom(0)

function Counter() {
    const [count, setCount] = useAtom(countAtom)
    return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

**Use when:** Fine-grained reactivity, derived state.

---

## Why This Matters for Provider Search

**Our global state:**

```
AuthContext (auth state)
└── Used by: Navigation, ProtectedRoute, API client

React Query (server state)
└── Used by: All data fetching hooks

React Router (routing state)
└── Used by: All navigation
```

**Context usage:**
- **AuthContext:** User session, sign in/out methods
- **React Query Provider:** API cache and state
- **Router Provider:** Current route, navigation

**Pattern:**
1. Wrap app with providers in `main.tsx`
2. Components use `useAuth()`, `useQuery()`, etc.
3. No prop drilling for global concerns

---

## Next Steps

- **[09-react-router-and-navigation.md](09-react-router-and-navigation.md)** — Single-page app routing
- **[11-data-fetching-and-server-state.md](11-data-fetching-and-server-state.md)** — React Query for server state

---

**You now understand Context for global state. Next: routing and navigation.**
