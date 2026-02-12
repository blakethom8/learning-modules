# Data Fetching and Server State

**React Query: Declarative Data Fetching with Automatic Caching**

Server state is different from client state. React Query handles the complexity of loading, caching, refetching, and syncing server data.

---

## Table of Contents

1. [The Problem: Managing Server State](#the-problem-managing-server-state)
2. [Evolution: fetch() → Custom Hooks → React Query](#evolution-fetch--custom-hooks--react-query)
3. [React Query Basics](#react-query-basics)
4. [useQuery: Fetching Data](#usequery-fetching-data)
5. [useMutation: Modifying Data](#usemutation-modifying-data)
6. [Query Keys and Cache Invalidation](#query-keys-and-cache-invalidation)
7. [Our Search API: Real Examples](#our-search-api-real-examples)
8. [Loading States and Error Handling](#loading-states-and-error-handling)

---

## The Problem: Managing Server State

### Manual State Management (Hard Mode)

```javascript
function ProviderList() {
    const [providers, setProviders] = useState([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState(null)
    
    useEffect(() => {
        setLoading(true)
        fetch('/api/providers')
            .then(r => r.json())
            .then(data => {
                setProviders(data)
                setLoading(false)
            })
            .catch(err => {
                setError(err.message)
                setLoading(false)
            })
    }, [])
    
    // Problems:
    // - No caching (refetch on every mount)
    // - No refetching (stale data)
    // - No retry logic
    // - No loading/error state management
    // - Race conditions if component unmounts
    // - Duplicate requests if multiple components need same data
}
```

### Python Analogy: Database with No ORM

```python
# Python without ORM (manual state management)
def get_providers():
    conn = psycopg2.connect(...)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM providers")
    results = cursor.fetchall()
    conn.close()
    return results

# Every call = new query, no caching

# vs SQLAlchemy (with caching, relationships, etc.)
providers = session.query(Provider).all()  # Automatic caching, lazy loading, etc.
```

**React Query is like an ORM for API calls.**

---

## Evolution: fetch() → Custom Hooks → React Query

### Stage 1: Raw fetch()

```javascript
fetch('/api/data').then(r => r.json()).then(console.log)
```

### Stage 2: Wrapper Function

```javascript
// api/client.ts
export async function apiCall(endpoint, options) {
    const response = await fetch(`/api${endpoint}`, options)
    if (!response.ok) throw new Error("Failed")
    return response.json()
}
```

### Stage 3: Custom Hook

```javascript
function useFetch(url) {
    const [data, setData] = useState(null)
    const [loading, setLoading] = useState(true)
    
    useEffect(() => {
        apiCall(url).then(setData).finally(() => setLoading(false))
    }, [url])
    
    return { data, loading }
}
```

### Stage 4: React Query (Final Form)

```javascript
function useProviders() {
    return useQuery({
        queryKey: ['providers'],
        queryFn: () => apiCall('/providers')
        // Automatic: caching, refetching, error handling, retries
    })
}
```

---

## React Query Basics

### Setup

```typescript
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,                    // Retry failed requests once
      refetchOnWindowFocus: false, // Don't refetch on window focus
      staleTime: 5 * 60 * 1000,    // Data fresh for 5 minutes
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')).render(
    <QueryClientProvider client={queryClient}>
        <App />
    </QueryClientProvider>
)
```

---

## useQuery: Fetching Data

### Basic Usage

```typescript
import { useQuery } from '@tanstack/react-query'

function Component() {
    const { data, isLoading, error } = useQuery({
        queryKey: ['providers'],
        queryFn: async () => {
            const response = await fetch('/api/providers')
            return response.json()
        }
    })
    
    if (isLoading) return <div>Loading...</div>
    if (error) return <div>Error: {error.message}</div>
    
    return <div>{data.length} providers</div>
}
```

### With Our API Client

```typescript
// api/search.ts
import { useQuery } from '@tanstack/react-query'
import { apiCall } from './client'
import type { SearchResponse } from '../types/provider'

export function useSearchQuery(query: string, radius: number) {
    return useQuery({
        queryKey: ['search', query, radius],
        queryFn: async () => {
            return apiCall<SearchResponse>('/search', {
                method: 'POST',
                body: JSON.stringify({
                    query,
                    radius_miles: radius,
                    max_results: 100
                })
            })
        },
        enabled: query.length > 0,  // Don't run if query empty
        staleTime: 5 * 60 * 1000,   // Cache for 5 minutes
    })
}

// Using it:
function SearchPage() {
    const [query, setQuery] = useState("cardiology")
    const [radius, setRadius] = useState(25)
    
    const { data, isLoading, error, refetch } = useSearchQuery(query, radius)
    
    return (
        <div>
            <input value={query} onChange={e => setQuery(e.target.value)} />
            <button onClick={() => refetch()}>Search</button>
            
            {isLoading && <div>Searching...</div>}
            {error && <div>Error: {error.message}</div>}
            {data && <ProviderList providers={data.providers} />}
        </div>
    )
}
```

### Query Options

| Option | Purpose | Example |
|--------|---------|---------|
| `queryKey` | Unique identifier for cache | `['search', query, radius]` |
| `queryFn` | Function that fetches data | `() => apiCall('/search')` |
| `enabled` | Whether to run query | `enabled: query.length > 0` |
| `staleTime` | How long data is fresh | `5 * 60 * 1000` (5 min) |
| `cacheTime` | How long to keep in cache | `10 * 60 * 1000` (10 min) |
| `refetchInterval` | Auto-refetch interval | `30000` (30 seconds) |
| `retry` | Number of retries | `1` |

---

## useMutation: Modifying Data

### POST/PUT/DELETE Operations

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query'

function useUpdateProviderStatus() {
    const queryClient = useQueryClient()
    
    return useMutation({
        mutationFn: async ({ placeId, status }) => {
            return apiCall('/provider/status', {
                method: 'PUT',
                body: JSON.stringify({ place_id: placeId, status })
            })
        },
        onSuccess: () => {
            // Invalidate and refetch
            queryClient.invalidateQueries({ queryKey: ['providerStatuses'] })
        }
    })
}

// Using it:
function StatusButton({ provider }) {
    const updateStatus = useUpdateProviderStatus()
    
    function handleClick() {
        updateStatus.mutate({
            placeId: provider.place_id,
            status: 'hard_lead'
        })
    }
    
    return (
        <button
            onClick={handleClick}
            disabled={updateStatus.isPending}
        >
            {updateStatus.isPending ? 'Updating...' : 'Mark as Hard Lead'}
        </button>
    )
}
```

---

## Query Keys and Cache Invalidation

### Query Keys = Cache Keys

```typescript
// Same query key = same cache entry
useQuery({ queryKey: ['providers'], queryFn: fetchProviders })
useQuery({ queryKey: ['providers'], queryFn: fetchProviders })  // Uses cache

// Different keys = different cache entries
useQuery({ queryKey: ['search', 'cardiology', 25], queryFn: search })
useQuery({ queryKey: ['search', 'pediatrics', 50], queryFn: search })  // Different cache
```

### Invalidating Cache

```typescript
const queryClient = useQueryClient()

// Invalidate specific query
queryClient.invalidateQueries({ queryKey: ['providers'] })

// Invalidate all queries matching pattern
queryClient.invalidateQueries({ queryKey: ['search'] })  // All search queries

// Set data manually (optimistic update)
queryClient.setQueryData(['providers'], (old) => {
    return [...old, newProvider]
})
```

---

## Our Search API: Real Examples

### useSearchQuery

```typescript
// web/src/api/search.ts
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
        enabled: query.length > 0,
        staleTime: 5 * 60 * 1000,
    })
}
```

### useProviderStatuses

```typescript
export function useProviderStatuses(placeIds: string[]) {
    return useQuery({
        queryKey: ['providerStatuses', placeIds],
        queryFn: async () => {
            if (placeIds.length === 0) return {}
            
            const response = await apiCall<PlaceStatusMap>('/provider/status', {
                method: 'POST',
                body: JSON.stringify({ place_ids: placeIds })
            })
            return response
        },
        enabled: placeIds.length > 0,
        staleTime: 30 * 1000,  // 30 seconds
    })
}
```

### In Components

```typescript
// web/src/app/AppSearch.tsx
function AppSearch() {
    const [query, setQuery] = useState("cardiology")
    const [radius, setRadius] = useState(25)
    
    const { data, isLoading, error } = useSearchQuery(query, radius)
    
    const placeIds = data?.providers.map(p => p.place_id) || []
    const { data: statuses } = useProviderStatuses(placeIds)
    
    return (
        <div>
            {isLoading && <LoadingSpinner />}
            {error && <ErrorMessage error={error} />}
            {data && (
                <ProviderList
                    providers={data.providers}
                    statuses={statuses}
                />
            )}
        </div>
    )
}
```

---

## Loading States and Error Handling

### Status Flags

```typescript
const { data, isLoading, isFetching, isError, error, refetch } = useQuery({...})

// isLoading: First load (no cached data)
// isFetching: Any fetch (including background refetch)
// isError: Query failed
// error: Error object
// refetch: Manual refetch function
```

### Handling States

```typescript
function Component() {
    const { data, isLoading, isError, error } = useQuery({...})
    
    if (isLoading) {
        return <LoadingSpinner />
    }
    
    if (isError) {
        return (
            <div>
                <p>Error: {error.message}</p>
                <button onClick={() => refetch()}>Retry</button>
            </div>
        )
    }
    
    return <div>{data.length} results</div>
}
```

### Optimistic Updates

```typescript
const mutation = useMutation({
    mutationFn: updateProvider,
    onMutate: async (newProvider) => {
        // Cancel outgoing refetches
        await queryClient.cancelQueries({ queryKey: ['providers'] })
        
        // Snapshot previous value
        const previousProviders = queryClient.getQueryData(['providers'])
        
        // Optimistically update
        queryClient.setQueryData(['providers'], (old) => [...old, newProvider])
        
        // Return context for rollback
        return { previousProviders }
    },
    onError: (err, newProvider, context) => {
        // Rollback on error
        queryClient.setQueryData(['providers'], context.previousProviders)
    },
    onSettled: () => {
        // Refetch after mutation
        queryClient.invalidateQueries({ queryKey: ['providers'] })
    }
})
```

---

## Why This Matters for Provider Search

**All API calls use React Query:**
- `useSearchQuery` — Search providers
- `useProviderStatuses` — Get provider statuses
- `useEnrichmentQuery` — Web enrichment data
- `useMutation` — Update provider status

**Benefits we get:**
- **Automatic caching:** Search "cardiology" once, it's cached
- **Background refetching:** Data stays fresh
- **Loading/error states:** Handled automatically
- **Deduplication:** Multiple components can use same query, only one request
- **Retry logic:** Failed requests retry automatically

**Pattern:**
1. Define query hook in `api/*.ts`
2. Use hook in component
3. React Query manages loading, caching, errors
4. Component just renders data

**Compare manual vs React Query:**
```typescript
// Manual: 50 lines of useEffect, useState, error handling
// React Query: 10 lines, all features included
```

---

## Next Steps

- **[13-application-architecture.md](13-application-architecture.md)** — See how data flows through our app
- **[14-testing-frontend-code.md](14-testing-frontend-code.md)** — Test React Query hooks

---

**You now understand React Query. Server state management is solved.**
