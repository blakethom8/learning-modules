# 13. Application Architecture

**Goal:** Understand how a real frontend application is organized, how data flows through it, and why architecture matters.

---

## Why Architecture Matters

In Python, you might organize a project like this:

```
my_project/
  __init__.py
  models.py        # Database models
  views.py         # Request handlers
  utils.py         # Helper functions
  tests.py         # Tests
```

That works for small projects. But as it grows, you realize:
- `views.py` becomes 3000 lines
- `utils.py` has unrelated functions mixed together
- You can't tell what parts of the code belong to which feature

**Architecture is about organizing code so:**
1. You can find things quickly
2. Changes to one feature don't break others
3. New developers can understand the system
4. Testing is straightforward

Frontend apps face the same problems, but with additional complexity:
- **UI state:** What's visible, what's selected, what's loading
- **Server state:** Data fetched from APIs
- **Navigation:** Which page you're on
- **User interactions:** Clicks, typing, drag-and-drop
- **Real-time updates:** WebSockets, polling

Let's see how Provider Search handles this.

---

## Provider Search Directory Structure

```
web/src/
├── api/                      # API client layer
│   ├── client.ts             # Base HTTP client (fetch wrapper)
│   ├── search.ts             # Search endpoints
│   ├── providers.ts          # Provider CRUD
│   ├── lists.ts              # List management
│   ├── reports.ts            # Report generation
│   └── user.ts               # Authentication
│
├── app/                      # Main application (search, lists, providers)
│   ├── AppSearch.tsx         # Search page (main entry point)
│   ├── AppLists.tsx          # Lists management page
│   ├── AppProviders.tsx      # Provider overview page
│   ├── components/           # App-specific components
│   │   ├── StatusIndicator.tsx
│   │   ├── ProviderModal.tsx
│   │   ├── ListSidebar.tsx
│   │   └── ...
│   └── hooks/                # App-specific hooks
│       ├── useProviderStatuses.ts
│       └── useActiveCampaign.ts
│
├── components/               # Shared/reusable components
│   ├── ProtectedRoute.tsx    # Auth wrapper
│   ├── ErrorBoundary.tsx     # Error handling
│   └── ...
│
├── contexts/                 # Global state (React Context)
│   └── AuthContext.tsx       # User authentication state
│
├── hooks/                    # Shared custom hooks
│   ├── useProviderSearch.ts  # Search logic
│   └── ...
│
├── layouts/                  # Page layouts
│   ├── MainLayout.tsx        # Nav bar + footer
│   └── DevLayout.tsx         # Dev tools layout
│
├── pages/                    # Top-level pages
│   ├── LoginPage.tsx
│   ├── ProPage.tsx
│   └── ...
│
├── types/                    # TypeScript type definitions
│   └── provider.ts
│
├── utils/                    # Helper functions
│
├── App.tsx                   # Route definitions (React Router)
└── main.tsx                  # Application entry point
```

### Key Principles

**1. Feature-based organization (app/ directory)**

Instead of putting all components in one folder, related features live together:

```
app/
  AppSearch.tsx          # The main search page
  components/            # Components only used in search
    StatusIndicator.tsx
    ProviderModal.tsx
  hooks/                 # Hooks only used in search
    useProviderStatuses.ts
```

**Python analogy:**
```python
# Instead of:
views.py  # All views mixed together

# You do:
search/
  views.py
  models.py
  utils.py
orders/
  views.py
  models.py
  utils.py
```

**2. Layer-based separation (api/, components/, hooks/)**

Code is also organized by **what it does**:
- `api/` — Talks to the backend
- `components/` — UI building blocks
- `hooks/` — Reusable logic
- `contexts/` — Global state

**Python analogy:**
```python
models/      # Data layer
views/       # Presentation layer
services/    # Business logic layer
```

**3. Shared vs. feature-specific**

- `components/` — Shared across the app (buttons, modals, layouts)
- `app/components/` — Only used in the search feature

This prevents:
- One feature's change breaking another
- Giant files with unrelated code
- Circular dependencies

---

## The API Layer Pattern

The `api/` directory is the **single source of truth** for backend communication.

### api/client.ts (Base HTTP Client)

```typescript
// api/client.ts
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

export async function apiRequest<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const token = localStorage.getItem('access_token')
  
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options?.headers,
    },
  })
  
  if (!response.ok) {
    throw new Error(`API error: ${response.status}`)
  }
  
  return response.json()
}
```

**Python analogy:**
```python
# Like a shared requests session
import requests

session = requests.Session()
session.headers.update({'Authorization': f'Bearer {token}'})

def api_request(endpoint):
    response = session.get(f'{API_BASE_URL}{endpoint}')
    response.raise_for_status()
    return response.json()
```

### api/search.ts (Feature-specific API)

```typescript
// api/search.ts
import { apiRequest } from './client'
import type { SearchParams, SearchResponse } from '../types/search'

export async function searchProviders(params: SearchParams): Promise<SearchResponse> {
  return apiRequest<SearchResponse>('/api/search', {
    method: 'POST',
    body: JSON.stringify(params),
  })
}

export async function getSearchStatus(searchId: string): Promise<SearchStatus> {
  return apiRequest<SearchStatus>(`/api/search/${searchId}/status`)
}
```

**Python analogy:**
```python
# search/client.py
from .base import api_request
from .types import SearchParams, SearchResponse

def search_providers(params: SearchParams) -> SearchResponse:
    return api_request('/api/search', method='POST', json=params)

def get_search_status(search_id: str) -> SearchStatus:
    return api_request(f'/api/search/{search_id}/status')
```

### Why This Pattern?

**Without an API layer:**
```typescript
// Component directly calls fetch (❌ bad)
function SearchResults() {
  const [results, setResults] = useState([])
  
  useEffect(() => {
    fetch('http://localhost:8000/api/search', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, ... },
      body: JSON.stringify(params),
    })
      .then(res => res.json())
      .then(data => setResults(data))
  }, [])
}
```

**Problems:**
1. Every component needs to know the base URL
2. Every component needs to handle auth headers
3. If the API changes, you update 20 files
4. Hard to mock for testing

**With an API layer:**
```typescript
// Component uses the API layer (✅ good)
import { searchProviders } from '../api/search'

function SearchResults() {
  const [results, setResults] = useState([])
  
  useEffect(() => {
    searchProviders(params).then(setResults)
  }, [])
}
```

**Benefits:**
1. Components don't know about HTTP details
2. Auth, base URL, error handling in one place
3. API changes? Update one file
4. Easy to mock: `jest.mock('../api/search')`

---

## Separation of Concerns

Different types of code belong in different places.

### 1. Components (UI)

**Job:** Render UI, handle user input, display data

```typescript
// app/components/StatusIndicator.tsx
interface StatusIndicatorProps {
  status: 'pending' | 'complete' | 'error'
  message?: string
}

export function StatusIndicator({ status, message }: StatusIndicatorProps) {
  const icon = status === 'pending' ? '⏳' : status === 'complete' ? '✅' : '❌'
  
  return (
    <div className={`status-${status}`}>
      {icon} {message}
    </div>
  )
}
```

**Python analogy:**
```python
# Like a Jinja2 template or React component
def render_status_indicator(status: str, message: str = None):
    icon = '⏳' if status == 'pending' else '✅' if status == 'complete' else '❌'
    return f'<div class="status-{status}">{icon} {message}</div>'
```

### 2. Hooks (Logic)

**Job:** Encapsulate reusable logic (state, side effects, data fetching)

```typescript
// hooks/useProviderSearch.ts
import { useState, useEffect } from 'react'
import { searchProviders } from '../api/search'

export function useProviderSearch(params: SearchParams) {
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  
  useEffect(() => {
    setLoading(true)
    searchProviders(params)
      .then(setResults)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [params])
  
  return { results, loading, error }
}
```

**Python analogy:**
```python
# Like a service layer or repository
class ProviderSearchService:
    def __init__(self, params: SearchParams):
        self.params = params
        self.results = []
        self.loading = False
        self.error = None
    
    def execute(self):
        self.loading = True
        try:
            self.results = search_providers(self.params)
        except Exception as e:
            self.error = e
        finally:
            self.loading = False
```

### 3. Contexts (Global State)

**Job:** Share state across many components without prop drilling

```typescript
// contexts/AuthContext.tsx
import { createContext, useContext, useState, ReactNode } from 'react'

interface AuthContextValue {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  
  const login = async (email: string, password: string) => {
    const response = await apiRequest('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
    setUser(response.user)
    localStorage.setItem('access_token', response.token)
  }
  
  const logout = () => {
    setUser(null)
    localStorage.removeItem('access_token')
  }
  
  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}
```

**Python analogy:**
```python
# Like a global singleton or Flask's g object
from flask import g

class AuthContext:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.user = None
        return cls._instance
    
    def login(self, email, password):
        response = api_request('/api/auth/login', json={'email': email, 'password': password})
        self.user = response['user']
        g.user = self.user
    
    def logout(self):
        self.user = None
        g.user = None

# Global instance
auth = AuthContext()
```

### 4. Utils (Pure Functions)

**Job:** Stateless helper functions (formatting, calculations, validation)

```typescript
// utils/formatting.ts
export function formatPhoneNumber(phone: string): string {
  const cleaned = phone.replace(/\D/g, '')
  const match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/)
  if (match) {
    return `(${match[1]}) ${match[2]}-${match[3]}`
  }
  return phone
}

export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}
```

**Python analogy:**
```python
# utils.py
import re
from datetime import datetime

def format_phone_number(phone: str) -> str:
    cleaned = re.sub(r'\D', '', phone)
    match = re.match(r'^(\d{3})(\d{3})(\d{4})$', cleaned)
    if match:
        return f'({match.group(1)}) {match.group(2)}-{match.group(3)}'
    return phone

def format_date(date: str) -> str:
    dt = datetime.fromisoformat(date)
    return dt.strftime('%b %d, %Y')
```

---

## State Flow: A Search in Provider Search

Let's trace how data flows through the app when a user searches for providers.

### Step-by-Step Flow

```
┌─────────────┐
│   User      │  Types "cardiologist" + "San Francisco"
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  AppSearch.tsx (Main search page)                   │
│  - Renders SearchBar component                      │
│  - Passes onSearch callback                         │
└──────┬──────────────────────────────────────────────┘
       │
       │ User clicks "Search" button
       ▼
┌─────────────────────────────────────────────────────┐
│  SearchBar component                                │
│  - Calls onSearch({ specialty: '...', location: ... })│
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  AppSearch.tsx                                      │
│  - Receives search params                          │
│  - Calls useProviderSearch(params) hook            │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  useProviderSearch hook                             │
│  - useState: loading = true, results = []           │
│  - Calls searchProviders(params) from api/search.ts │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  api/search.ts                                      │
│  - Calls apiRequest('/api/search', { POST, body })  │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  api/client.ts                                      │
│  - Gets auth token from localStorage                │
│  - Adds headers (Authorization, Content-Type)       │
│  - fetch(API_BASE_URL + '/api/search', ...)         │
└──────┬──────────────────────────────────────────────┘
       │
       │ HTTP POST request over network
       ▼
┌─────────────────────────────────────────────────────┐
│  Backend API (FastAPI)                              │
│  - Validates request                                │
│  - Queries database                                 │
│  - Returns JSON response                            │
└──────┬──────────────────────────────────────────────┘
       │
       │ HTTP response
       ▼
┌─────────────────────────────────────────────────────┐
│  api/client.ts                                      │
│  - Checks response.ok                               │
│  - Calls response.json()                            │
│  - Returns parsed data                              │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  useProviderSearch hook                             │
│  - Receives data                                    │
│  - setResults(data)                                 │
│  - setLoading(false)                                │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  AppSearch.tsx                                      │
│  - Hook returns { results, loading, error }         │
│  - Component re-renders with new results            │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  ResultsList component                              │
│  - Receives results prop                            │
│  - Maps over results, renders ProviderCard for each │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  ProviderCard component                             │
│  - Renders provider info (name, address, phone)     │
│  - User sees results on screen                      │
└─────────────────────────────────────────────────────┘
```

### State Changes

```
Initial state:
  loading: false
  results: []
  error: null

User clicks "Search":
  loading: true    ← UI shows spinner
  results: []
  error: null

Backend responds:
  loading: false   ← Spinner disappears
  results: [...]   ← Results appear
  error: null

If backend fails:
  loading: false
  results: []
  error: "Network error"  ← Error message appears
```

---

## Real Code Example: AppSearch.tsx

Let's look at the actual implementation:

```typescript
// app/AppSearch.tsx (simplified)
import { useState } from 'react'
import { useProviderSearch } from '../hooks/useProviderSearch'
import SearchBar from './components/SearchBar'
import ResultsList from './components/ResultsList'
import StatusIndicator from './components/StatusIndicator'

export default function AppSearch() {
  const [searchParams, setSearchParams] = useState(null)
  const { results, loading, error } = useProviderSearch(searchParams)
  
  const handleSearch = (params) => {
    setSearchParams(params)  // Triggers useProviderSearch
  }
  
  return (
    <div className="search-page">
      <SearchBar onSearch={handleSearch} />
      
      {loading && <StatusIndicator status="pending" message="Searching..." />}
      {error && <StatusIndicator status="error" message={error} />}
      {results.length > 0 && <ResultsList results={results} />}
    </div>
  )
}
```

**Python analogy:**
```python
# views.py (Flask or Django)
from flask import render_template, request
from services.search import ProviderSearchService

@app.route('/search')
def search_page():
    params = request.args.to_dict()
    
    if not params:
        return render_template('search.html', results=None, loading=False, error=None)
    
    service = ProviderSearchService(params)
    try:
        service.execute()
        return render_template(
            'search.html',
            results=service.results,
            loading=False,
            error=None
        )
    except Exception as e:
        return render_template(
            'search.html',
            results=None,
            loading=False,
            error=str(e)
        )
```

---

## Error Boundaries

React has a special component type for catching errors: **Error Boundaries**.

```typescript
// components/ErrorBoundary.tsx
import { Component, ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error }
  }
  
  componentDidCatch(error: Error, errorInfo: any) {
    console.error('Error caught by boundary:', error, errorInfo)
    // Could send to error tracking service (Sentry, etc.)
  }
  
  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="error-message">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      )
    }
    
    return this.props.children
  }
}
```

**Usage:**

```typescript
// App.tsx
import { ErrorBoundary } from './components/ErrorBoundary'

function App() {
  return (
    <ErrorBoundary>
      <AppSearch />
    </ErrorBoundary>
  )
}
```

**Why?**

If any component inside `<ErrorBoundary>` throws an error, instead of the whole app crashing, it shows the fallback UI.

**Python analogy:**
```python
# Like a try/except wrapper for views
def error_boundary(view_func):
    def wrapper(*args, **kwargs):
        try:
            return view_func(*args, **kwargs)
        except Exception as e:
            logger.error(f'Error in {view_func.__name__}: {e}')
            return render_template('error.html', error=str(e))
    return wrapper

@app.route('/search')
@error_boundary
def search_page():
    # If this raises an exception, error_boundary catches it
    results = search_providers(request.args)
    return render_template('results.html', results=results)
```

---

## Data Flow: Map Updates

When a user clicks on a provider, the map should center on that location. How does this work?

### Scenario: User clicks provider card

```
┌─────────────────────────────────────────────────────┐
│  ProviderCard (clicked)                             │
│  - onClick={() => onSelect(provider.id)}            │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  ResultsList                                        │
│  - Receives onSelect from parent                    │
│  - Calls onSelect(providerId)                       │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  AppSearch                                          │
│  - const [selectedId, setSelectedId] = useState()   │
│  - onSelect={(id) => setSelectedId(id)}             │
└──────┬──────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  MapView (receives selectedId prop)                 │
│  - useEffect(() => {                                │
│      if (selectedId) {                              │
│        const provider = results.find(p => p.id === selectedId)│
│        map.flyTo(provider.location)                 │
│      }                                               │
│    }, [selectedId])                                 │
└─────────────────────────────────────────────────────┘
```

**Key concept:** State lives in the parent, behavior is passed down via props.

**Python analogy:**
```python
# Parent manages state
class SearchView:
    def __init__(self):
        self.selected_provider_id = None
    
    def on_provider_selected(self, provider_id):
        self.selected_provider_id = provider_id
        self.update_map()
    
    def render(self):
        # Pass callback to child
        results_list = ResultsList(
            providers=self.results,
            on_select=self.on_provider_selected
        )
        map_view = MapView(selected_id=self.selected_provider_id)
        return render_template('search.html', results=results_list, map=map_view)
```

---

## Full Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                              USER INTERACTION                          │
│                         (clicks, types, navigates)                     │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          COMPONENTS (UI Layer)                         │
│  - AppSearch, SearchBar, ResultsList, MapView                          │
│  - Render UI based on props/state                                      │
│  - Call event handlers (onClick, onSearch, etc.)                       │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        HOOKS (Logic Layer)                             │
│  - useProviderSearch, useProviderStatuses                              │
│  - Manage component state (useState)                                   │
│  - Handle side effects (useEffect)                                     │
│  - Call API layer                                                      │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          API LAYER                                     │
│  - api/client.ts (base HTTP client)                                    │
│  - api/search.ts, api/providers.ts (feature APIs)                      │
│  - Add auth headers, format requests                                   │
│  - Return typed responses                                              │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     │ HTTP REQUEST (POST /api/search)
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          BACKEND API (FastAPI)                         │
│  - Authenticate request                                                │
│  - Validate input                                                      │
│  - Query database                                                      │
│  - Return JSON response                                                │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     │ HTTP RESPONSE (JSON)
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          API LAYER                                     │
│  - Check response.ok                                                   │
│  - Parse JSON                                                          │
│  - Return typed data                                                   │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        HOOKS (Logic Layer)                             │
│  - Update state: setResults(data)                                      │
│  - Trigger re-render                                                   │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        COMPONENTS (UI Layer)                           │
│  - Re-render with new data                                             │
│  - Display results to user                                             │
└────────────────────┬───────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              BROWSER (DOM)                             │
│  - Updates visible UI                                                  │
│  - User sees results                                                   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Provider Search: Specific Flows

### 1. Search Flow

```
User types "cardiologist" in SearchBar
  └─> SearchBar.onChange updates local state
  └─> User clicks "Search"
      └─> SearchBar.onSubmit calls props.onSearch(params)
          └─> AppSearch.handleSearch(params)
              └─> setSearchParams(params)  // This triggers useProviderSearch
                  └─> useProviderSearch(params) runs
                      └─> useEffect sees params changed
                          └─> Calls api/search.searchProviders(params)
                              └─> Backend returns results
                                  └─> setResults(data), setLoading(false)
                                      └─> AppSearch re-renders
                                          └─> ResultsList receives new results
                                              └─> User sees provider cards
```

### 2. Status Update Flow (Real-time Updates)

Provider Search polls for status updates on providers (checking if they're accepting new patients, etc.).

```
AppSearch mounts
  └─> useProviderStatuses() hook runs
      └─> useEffect sets up interval:
          └─> Every 30 seconds:
              └─> Call api/providers.getStatuses()
                  └─> Backend checks external APIs
                      └─> Returns updated statuses
                          └─> setStatuses(data)
                              └─> ProviderCard re-renders with new status badge
                                  └─> User sees "✅ Accepting new patients" update
```

### 3. List Management Flow

```
User clicks "Add to list" on provider
  └─> ProviderCard.onClick
      └─> AppSearch.handleAddToList(providerId)
          └─> api/lists.addProvider(listId, providerId)
              └─> Backend updates database
                  └─> Returns updated list
                      └─> Update local state: setLists(data)
                          └─> ListSidebar re-renders
                              └─> User sees provider added to list
```

---

## App.tsx: The Route Manager

`App.tsx` is the top-level component that defines all routes.

```typescript
// App.tsx (simplified)
import { Routes, Route } from 'react-router-dom'

function App() {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/" element={<AppSearch />} />
      <Route path="/about" element={<AboutPage />} />
      <Route path="/login" element={<LoginPage />} />
      
      {/* Protected routes (require auth) */}
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
    </Routes>
  )
}
```

**How routing works:**

1. User navigates to `/lists`
2. React Router matches the path to the route definition
3. Renders `<ProtectedRoute>`
4. `ProtectedRoute` checks if user is authenticated
5. If yes, renders `<AppLists />`
6. If no, redirects to `/login`

**Python analogy:**
```python
# Flask routing
from flask import redirect, url_for
from functools import wraps

def protected_route(required_plan=None):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            if not current_user.is_authenticated:
                return redirect(url_for('login'))
            if required_plan and current_user.plan != required_plan:
                return redirect(url_for('upgrade'))
            return f(*args, **kwargs)
        return wrapper
    return decorator

@app.route('/')
def search_page():
    return render_template('search.html')

@app.route('/lists')
@protected_route()
def lists_page():
    return render_template('lists.html')

@app.route('/providers')
@protected_route(required_plan='pro')
def providers_page():
    return render_template('providers.html')
```

---

## AppProviders.tsx: A Feature Module

This is a standalone page that lets pro users browse all providers in the system.

```typescript
// app/AppProviders.tsx
import { useState, useEffect } from 'react'
import { getAllProviders } from '../api/providers'
import ProviderTable from './components/ProviderTable'
import FilterBar from './components/FilterBar'

export default function AppProviders() {
  const [providers, setProviders] = useState([])
  const [filters, setFilters] = useState({})
  const [loading, setLoading] = useState(true)
  
  useEffect(() => {
    setLoading(true)
    getAllProviders(filters)
      .then(setProviders)
      .finally(() => setLoading(false))
  }, [filters])
  
  return (
    <div className="providers-page">
      <h1>Provider Database</h1>
      <FilterBar onFilterChange={setFilters} />
      {loading ? <Spinner /> : <ProviderTable data={providers} />}
    </div>
  )
}
```

**Key patterns:**
1. Page component manages state
2. Child components are "dumb" (receive props, emit events)
3. API calls happen in hooks or useEffect
4. Loading states are explicit

---

## Summary

**Architecture is about:**
1. **Organization:** Where does code live? (feature-based + layer-based)
2. **Separation:** What does each piece do? (components, hooks, API, utils)
3. **Flow:** How does data move? (user → UI → logic → API → backend → back)
4. **Boundaries:** How do we contain errors? (ErrorBoundary, try/catch)

**Provider Search architecture:**
```
api/           ← Talks to backend
hooks/         ← Business logic
components/    ← Reusable UI
app/           ← Feature-specific code
contexts/      ← Global state
```

**Data flow pattern:**
```
User Input → Component → Hook → API → Backend
                ↓          ↓      ↓
              State    Side Effects  HTTP
                ↓          ↓      ↓
            Re-render ← Update State ← Response
```

**Next:** Now that you understand the architecture, let's look at how to test it (guide 14).
