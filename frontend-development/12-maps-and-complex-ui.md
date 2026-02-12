# Maps and Complex UI

**Integrating Third-Party Libraries and Handling Complex Interactions**

Not everything is built-in. Learn to integrate external libraries (like Leaflet maps) and build complex, performant UIs.

---

## Key Topics

### 1. Leaflet.js Integration (Our Map)

Our `ProviderMap.tsx` uses Leaflet for interactive maps:

```typescript
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'

function ProviderMap({ providers, center }) {
    return (
        <MapContainer center={center} zoom={10} style={{ height: '500px' }}>
            <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
            {providers.map(provider => (
                <Marker key={provider.place_id} position={[provider.lat, provider.lng]}>
                    <Popup>{provider.name}</Popup>
                </Marker>
            ))}
        </MapContainer>
    )
}
```

**Pattern:** Wrapper components bridge external libraries to React.

### 2. Third-Party Library Integration

**Steps:**
1. Install: `npm install leaflet react-leaflet`
2. Import CSS: `import 'leaflet/dist/leaflet.css'`
3. Use provided React components
4. Handle library-specific APIs with `useRef` and `useEffect`

**Example: Direct Leaflet API access**
```typescript
import { useMap } from 'react-leaflet'

function MapController({ center }) {
    const map = useMap()  // Access underlying Leaflet instance
    
    useEffect(() => {
        map.flyTo(center, 12)  // Use Leaflet API directly
    }, [center])
    
    return null
}
```

### 3. Debouncing and Throttling

**Problem:** Too many updates cause performance issues.

```typescript
import { useMemo } from 'react'
import debounce from 'lodash/debounce'

function SearchInput() {
    const [query, setQuery] = useState("")
    
    // Debounce: Wait for user to stop typing
    const debouncedSearch = useMemo(
        () => debounce((value) => {
            performSearch(value)
        }, 500),  // Wait 500ms after last keystroke
        []
    )
    
    function handleChange(e) {
        const value = e.target.value
        setQuery(value)
        debouncedSearch(value)  // Debounced call
    }
    
    return <input value={query} onChange={handleChange} />
}
```

**Debounce vs Throttle:**
- **Debounce:** Wait until user stops (good for search input)
- **Throttle:** Limit to once per time period (good for scroll events)

### 4. Browser APIs

```typescript
// Geolocation
navigator.geolocation.getCurrentPosition((position) => {
    const { latitude, longitude } = position.coords
    console.log(latitude, longitude)
})

// Clipboard
async function copyToClipboard(text) {
    await navigator.clipboard.writeText(text)
    alert("Copied!")
}

// Local storage
localStorage.setItem("key", "value")
const value = localStorage.getItem("key")

// Notifications (if permitted)
new Notification("Provider added!", {
    body: "Dr. Smith added to your list"
})
```

### 5. Performance Optimization

**React.memo: Prevent Unnecessary Re-renders**
```typescript
const ExpensiveComponent = React.memo(({ data }) => {
    // Only re-renders if data changes
    return <div>{/* Complex rendering */}</div>
})
```

**Lazy Loading: Code Splitting**
```typescript
import { lazy, Suspense } from 'react'

const HeavyMap = lazy(() => import('./ProviderMap'))

function App() {
    return (
        <Suspense fallback={<div>Loading map...</div>}>
            <HeavyMap />
        </Suspense>
    )
}
```

**Virtual Scrolling: Large Lists**
```typescript
import { FixedSizeList } from 'react-window'

function LargeList({ items }) {
    return (
        <FixedSizeList
            height={500}
            itemCount={items.length}
            itemSize={50}
            width="100%"
        >
            {({ index, style }) => (
                <div style={style}>{items[index].name}</div>
            )}
        </FixedSizeList>
    )
}
```

### 6. Complex Component Patterns

**Controlled Components (React controls the state):**
```typescript
function ControlledInput() {
    const [value, setValue] = useState("")
    
    return (
        <input
            value={value}  // React controls value
            onChange={e => setValue(e.target.value)}
        />
    )
}
```

**Uncontrolled Components (DOM controls the state):**
```typescript
function UncontrolledInput() {
    const inputRef = useRef()
    
    function handleSubmit() {
        console.log(inputRef.current.value)  // Read from DOM
    }
    
    return <input ref={inputRef} defaultValue="initial" />
}
```

**Compound Components:**
```typescript
function Tabs({ children }) {
    const [activeTab, setActiveTab] = useState(0)
    
    return (
        <TabsContext.Provider value={{ activeTab, setActiveTab }}>
            {children}
        </TabsContext.Provider>
    )
}

Tabs.List = function TabsList({ children }) {
    return <div className="tab-list">{children}</div>
}

Tabs.Tab = function Tab({ index, children }) {
    const { activeTab, setActiveTab } = useContext(TabsContext)
    return (
        <button onClick={() => setActiveTab(index)}>
            {children}
        </button>
    )
}

// Usage:
<Tabs>
    <Tabs.List>
        <Tabs.Tab index={0}>Tab 1</Tabs.Tab>
        <Tabs.Tab index={1}>Tab 2</Tabs.Tab>
    </Tabs.List>
</Tabs>
```

---

## Why This Matters for Provider Search

**Our complex UI features:**
- **ProviderMap:** Leaflet integration, marker clustering, bounds updates
- **Debounced search:** Don't search on every keystroke
- **Lazy-loaded dev tools:** Code-split heavy components
- **Geolocation:** "Use my location" button

**Pattern for third-party libs:**
1. Find React wrapper library (react-leaflet, react-chartjs-2, etc.)
2. If no wrapper exists, use `useRef` + `useEffect` to integrate
3. Handle library lifecycle (initialization, updates, cleanup)

---

## Next Steps

- [13-application-architecture.md](13-application-architecture.md) — Full app architecture
- [15-standalone-frontend-apps.md](15-standalone-frontend-apps.md) — Building without frameworks

---

**You now understand complex UI patterns. You can integrate any library.**
