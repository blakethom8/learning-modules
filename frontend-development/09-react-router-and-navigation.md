# React Router and Navigation

**Single-Page Apps: No Page Reloads**

React Router lets you build single-page applications (SPAs) where navigation happens without page reloads. URLs change, but the browser never requests a new HTML document.

---

## Table of Contents

1. [Single-Page Apps (SPAs)](#single-page-apps-spas)
2. [React Router Basics](#react-router-basics)
3. [Our App.tsx Routing Structure](#our-apptsx-routing-structure)
4. [Protected Routes](#protected-routes)
5. [Nested Routes and Layouts](#nested-routes-and-layouts)
6. [URL Parameters and Query Strings](#url-parameters-and-query-strings)
7. [Navigation Patterns](#navigation-patterns)

---

## Single-Page Apps (SPAs)

### Traditional Multi-Page App

```
User clicks link
        ↓
Browser requests new HTML from server
        ↓
Server renders full page
        ↓
Browser loads and renders new page
        ↓
Page reloads (flash, lose client state)
```

### Single-Page App (SPA)

```
User clicks link
        ↓
React Router intercepts
        ↓
URL changes (browser history API)
        ↓
React renders new component
        ↓
No page reload (instant, keep client state)
```

**Benefits:**
- Instant navigation (no page reload)
- Maintain client state (no re-initialization)
- Better UX (feels like a native app)
- Browser back/forward works

---

## React Router Basics

### Installation

```bash
npm install react-router-dom
```

### Basic Setup

```javascript
// main.tsx
import { BrowserRouter } from 'react-router-dom'

ReactDOM.createRoot(document.getElementById('root')).render(
    <BrowserRouter>
        <App />
    </BrowserRouter>
)

// App.tsx
import { Routes, Route, Link } from 'react-router-dom'

function App() {
    return (
        <div>
            <nav>
                <Link to="/">Home</Link>
                <Link to="/about">About</Link>
            </nav>
            
            <Routes>
                <Route path="/" element={<HomePage />} />
                <Route path="/about" element={<AboutPage />} />
            </Routes>
        </div>
    )
}
```

### Key Components

| Component | Purpose | Example |
|-----------|---------|---------|
| `<BrowserRouter>` | Wrap entire app | In `main.tsx` |
| `<Routes>` | Container for routes | In `App.tsx` |
| `<Route>` | Map URL to component | `<Route path="/about" element={<About />} />` |
| `<Link>` | Navigation link | `<Link to="/about">About</Link>` |
| `<Navigate>` | Redirect | `<Navigate to="/login" />` |

---

## Our App.tsx Routing Structure

### Provider Search Routes

```typescript
// web/src/App.tsx (simplified)
import { Routes, Route, Navigate } from 'react-router-dom'
import MainLayout from './layouts/MainLayout'
import DevLayout from './layouts/DevLayout'
import ProtectedRoute from './components/ProtectedRoute'

// Pages
import AppSearch from './app/AppSearch'
import AppLists from './app/AppLists'
import AppProviders from './app/AppProviders'
import LoginPage from './pages/LoginPage'

function App() {
    return (
        <Routes>
            {/* Public routes with MainLayout */}
            <Route element={<MainLayout />}>
                <Route path="/" element={<AppSearch />} />
                <Route path="/about" element={<AboutPage />} />
                <Route path="/provider/:placeId" element={<AppProviderOverview />} />
                
                {/* Protected routes */}
                <Route path="/lists" element={
                    <ProtectedRoute>
                        <AppLists />
                    </ProtectedRoute>
                } />
                
                <Route path="/providers" element={
                    <ProtectedRoute requiredPlan="pro">
                        <AppProviders />
                    </ProtectedRoute>
                } />
            </Route>
            
            {/* Auth (no layout) */}
            <Route path="/login" element={<LoginPage />} />
            
            {/* Dev section (protected, different layout) */}
            <Route path="/dev" element={
                <ProtectedRoute requiredPlan="pro">
                    <DevLayout />
                </ProtectedRoute>
            }>
                <Route index element={<DevHome />} />
                <Route path="prototypes" element={<DevPrototypes />} />
            </Route>
            
            {/* Redirects */}
            <Route path="/app" element={<Navigate to="/" replace />} />
            
            {/* Catch-all */}
            <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
    )
}
```

**Route structure:**
```
/ → AppSearch (public)
/about → AboutPage (public)
/provider/:placeId → AppProviderOverview (public)
/lists → AppLists (protected: any user)
/providers → AppProviders (protected: pro plan)
/login → LoginPage (public, no layout)
/dev → DevHome (protected: pro plan, different layout)
/dev/prototypes → DevPrototypes (nested under /dev)
* → Redirect to /
```

---

## Protected Routes

### Basic Protected Route

```typescript
// web/src/components/ProtectedRoute.tsx
import { Navigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

interface ProtectedRouteProps {
    children: ReactNode
    requiredPlan?: 'free' | 'pro'
}

export default function ProtectedRoute({ children, requiredPlan }: ProtectedRouteProps) {
    const { user, loading } = useAuth()
    
    if (loading) {
        return <div>Loading...</div>
    }
    
    if (!user) {
        return <Navigate to="/login" />
    }
    
    if (requiredPlan === 'pro' && user.plan !== 'pro') {
        return <Navigate to="/pro" />  // Upsell page
    }
    
    return children
}
```

**Usage:**
```typescript
<Route path="/lists" element={
    <ProtectedRoute>
        <AppLists />
    </ProtectedRoute>
} />
```

---

## Nested Routes and Layouts

### Layout Routes

```typescript
// MainLayout.tsx
import { Outlet } from 'react-router-dom'

export default function MainLayout() {
    return (
        <div>
            <Header />
            <Outlet />  {/* Child route renders here */}
            <Footer />
        </div>
    )
}

// App.tsx
<Route element={<MainLayout />}>
    <Route path="/" element={<HomePage />} />
    <Route path="/about" element={<AboutPage />} />
</Route>
```

**Result:**
- `/` → `<MainLayout><HomePage /></MainLayout>`
- `/about` → `<MainLayout><AboutPage /></MainLayout>`

### Nested Routes

```typescript
// App.tsx
<Route path="/dev" element={<DevLayout />}>
    <Route index element={<DevHome />} />  {/* /dev */}
    <Route path="prototypes" element={<DevPrototypes />} />  {/* /dev/prototypes */}
    <Route path="enrichment" element={<EnrichmentHome />} />  {/* /dev/enrichment */}
</Route>

// DevLayout.tsx
export default function DevLayout() {
    return (
        <div>
            <DevNavigation />
            <Outlet />  {/* Nested route renders here */}
        </div>
    )
}
```

---

## URL Parameters and Query Strings

### Route Parameters

```typescript
// Define route with parameter
<Route path="/provider/:placeId" element={<ProviderDetails />} />

// Access in component
import { useParams } from 'react-router-dom'

function ProviderDetails() {
    const { placeId } = useParams()  // Get :placeId from URL
    
    // If URL is /provider/abc123, placeId = "abc123"
    
    return <div>Provider ID: {placeId}</div>
}
```

### Query Strings

```typescript
// URL: /search?query=cardiology&radius=25

import { useSearchParams } from 'react-router-dom'

function SearchPage() {
    const [searchParams, setSearchParams] = useSearchParams()
    
    const query = searchParams.get('query')      // "cardiology"
    const radius = searchParams.get('radius')    // "25"
    
    // Update query params
    function updateQuery(newQuery: string) {
        setSearchParams({ query: newQuery, radius: searchParams.get('radius') })
    }
    
    return <input value={query || ""} onChange={e => updateQuery(e.target.value)} />
}
```

---

## Navigation Patterns

### Link Component

```typescript
import { Link } from 'react-router-dom'

<Link to="/">Home</Link>
<Link to="/about">About</Link>
<Link to={`/provider/${provider.id}`}>View Provider</Link>

// With state (passed to next page)
<Link to="/search" state={{ from: 'homepage' }}>Search</Link>
```

### Programmatic Navigation

```typescript
import { useNavigate } from 'react-router-dom'

function LoginForm() {
    const navigate = useNavigate()
    
    async function handleSubmit() {
        await signIn(email, password)
        navigate('/')  // Redirect to home
    }
    
    return <form onSubmit={handleSubmit}>...</form>
}

// Navigate with options
navigate('/search', { replace: true })  // Replace history entry
navigate(-1)  // Go back
navigate(1)   // Go forward
```

### Navigate Component (Redirect)

```typescript
import { Navigate } from 'react-router-dom'

function ProtectedRoute({ user, children }) {
    if (!user) {
        return <Navigate to="/login" />
    }
    return children
}
```

### NavLink (Active Link Styling)

```typescript
import { NavLink } from 'react-router-dom'

<NavLink
    to="/about"
    className={({ isActive }) => isActive ? 'active' : ''}
>
    About
</NavLink>

// Or with style
<NavLink
    to="/about"
    style={({ isActive }) => ({ color: isActive ? 'red' : 'black' })}
>
    About
</NavLink>
```

---

## Why This Matters for Provider Search

**Our routing structure:**

```
Public routes (MainLayout)
├── / (AppSearch)
├── /about
└── /provider/:placeId (ProviderDetails)

Protected routes (MainLayout)
├── /lists (any user)
├── /summary (pro plan)
└── /providers (pro plan)

Dev section (DevLayout, pro plan)
├── /dev
├── /dev/prototypes
├── /dev/enrichment
└── /dev/summary-builder

Auth (no layout)
└── /login

Legacy redirects
├── /app/* → /
└── /prototype/* → /dev/prototype/*
```

**Key patterns:**
1. **Layout routes:** MainLayout and DevLayout wrap groups of routes
2. **Protected routes:** ProtectedRoute checks auth before rendering
3. **Plan-based access:** Some routes require pro plan
4. **Nested routes:** Dev section has nested routes under /dev
5. **Redirects:** Legacy URLs redirect to new structure

**Navigation in components:**
```typescript
// Link to provider details
<Link to={`/provider/${provider.place_id}`}>View Provider</Link>

// Navigate after search
const navigate = useNavigate()
function handleSearch() {
    performSearch()
    navigate('/')  // Go to results
}

// Redirect if not authorized
if (!user) return <Navigate to="/login" />
```

---

## Next Steps

- **[10-build-tools-and-bundling.md](10-build-tools-and-bundling.md)** — How TypeScript becomes browser-runnable JavaScript
- **[13-application-architecture.md](13-application-architecture.md)** — See full app structure

---

**You now understand React Router. Our app is a SPA with client-side routing.**
