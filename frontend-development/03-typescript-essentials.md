# TypeScript Essentials

**JavaScript + Types = Fewer Bugs**

TypeScript is JavaScript with a type system. Think of it as Python with type hints, but enforced at compile time. Our entire Provider Search frontend is written in TypeScript.

---

## Table of Contents

1. [Why TypeScript Exists](#why-typescript-exists)
2. [Basic Types](#basic-types)
3. [Interfaces and Type Aliases](#interfaces-and-type-aliases)
4. [Generics](#generics)
5. [Union Types and Optionals](#union-types-and-optionals)
6. [Type Inference](#type-inference)
7. [Our Types: web/src/types/provider.ts](#our-types-websrctypesproviderts)
8. [tsconfig.json](#tsconfigjson)
9. [When to Use `any`](#when-to-use-any)

---

## Why TypeScript Exists

### JavaScript: Dynamically Typed

```javascript
// JavaScript: No type checking
function add(a, b) {
    return a + b
}

add(5, 10)        // 15 ✅
add("5", "10")    // "510" 🤔
add(5, "10")      // "510" 😱
add({}, [])       // "[object Object]" 💀
```

**Problem:** No compile-time safety. Errors happen at runtime, often in production.

### Python: Dynamic with Optional Type Hints

```python
# Python with type hints (not enforced)
def add(a: int, b: int) -> int:
    return a + b

add(5, 10)        # Works
add("5", "10")    # mypy would warn, but Python allows it!
```

**Python type hints are optional:** The interpreter ignores them. Tools like `mypy` check them separately.

### TypeScript: Types Are Enforced

```typescript
// TypeScript: Compile-time type checking
function add(a: number, b: number): number {
    return a + b
}

add(5, 10)        // ✅ Compiles
add("5", "10")    // ❌ Compile error!
add(5, "10")      // ❌ Compile error!
```

**TypeScript won't compile** if types don't match. Errors are caught before the code runs.

### The Compilation Step

```
TypeScript (.ts, .tsx)
        ↓
   Type Checking
        ↓
JavaScript (.js, .jsx)
        ↓
   Browser runs it
```

**You write TypeScript, but browsers run JavaScript.** The TypeScript compiler (tsc) checks types and strips them out.

---

## Basic Types

### Python Type Hints vs TypeScript

| Python | TypeScript | Example |
|--------|------------|---------|
| `int` | `number` | `const x: number = 5` |
| `float` | `number` | `const y: number = 5.5` |
| `str` | `string` | `const name: string = "Blake"` |
| `bool` | `boolean` | `const active: boolean = true` |
| `None` | `null` or `undefined` | `const value: null = null` |
| `list[str]` | `string[]` or `Array<string>` | `const names: string[] = ["Blake"]` |
| `dict[str, int]` | `Record<string, number>` or `{[key: string]: number}` | `const ages: Record<string, number> = {"Blake": 30}` |

### Primitive Types

```typescript
// Numbers (JavaScript has only one number type)
const age: number = 30
const price: number = 19.99
const hex: number = 0xFF

// Strings
const name: string = "Blake"
const greeting: string = `Hello, ${name}`

// Booleans
const isActive: boolean = true
const hasAccess: boolean = false

// Null and undefined
const nothing: null = null
const notDefined: undefined = undefined

// Arrays
const numbers: number[] = [1, 2, 3]
const names: Array<string> = ["Blake", "Alex"]  // Same thing

// Objects
const user: { name: string; age: number } = {
    name: "Blake",
    age: 30
}
```

---

## Interfaces and Type Aliases

### Python: TypedDict and dataclasses

```python
from typing import TypedDict
from dataclasses import dataclass

# TypedDict (like interface)
class User(TypedDict):
    name: str
    age: int
    email: str

user: User = {
    "name": "Blake",
    "age": 30,
    "email": "blake@example.com"
}

# dataclass (like interface with methods)
@dataclass
class Point:
    x: float
    y: float
    
    def distance(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5
```

### TypeScript: Interfaces

```typescript
// Interface (like Python TypedDict)
interface User {
    name: string
    age: number
    email: string
}

const user: User = {
    name: "Blake",
    age: 30,
    email: "blake@example.com"
}

// Optional properties
interface Profile {
    name: string
    bio?: string  // Optional (can be undefined)
}

const profile: Profile = { name: "Blake" }  // ✅ bio is optional

// Readonly properties
interface Point {
    readonly x: number
    readonly y: number
}

const point: Point = { x: 5, y: 10 }
point.x = 20  // ❌ Compile error! x is readonly
```

### Type Aliases (Alternative to Interfaces)

```typescript
// Type alias (alternative syntax)
type User = {
    name: string
    age: number
    email: string
}

// Same as interface for object types
const user: User = {
    name: "Blake",
    age: 30,
    email: "blake@example.com"
}
```

### Interface vs Type: When to Use Which

| Feature | Interface | Type |
|---------|-----------|------|
| Object shapes | ✅ Preferred | ✅ Works |
| Unions (`string \| number`) | ❌ | ✅ Only types |
| Intersections | ✅ `extends` | ✅ `&` operator |
| Declaration merging | ✅ | ❌ |
| Tuples | ❌ | ✅ Only types |

**Convention:** Use `interface` for object shapes, `type` for unions, aliases, and complex types.

### Extending Interfaces

```python
# Python: Inheritance
class Animal(TypedDict):
    name: str
    age: int

class Dog(Animal):
    breed: str
```

```typescript
// TypeScript: Extending interfaces
interface Animal {
    name: string
    age: number
}

interface Dog extends Animal {
    breed: string
}

const myDog: Dog = {
    name: "Buddy",
    age: 5,
    breed: "Golden Retriever"
}
```

---

## Generics

### Python: Generic Types

```python
from typing import List, Dict, Optional, TypeVar, Generic

# Generic list
names: List[str] = ["Blake", "Alex"]
numbers: List[int] = [1, 2, 3]

# Generic dict
ages: Dict[str, int] = {"Blake": 30}

# Generic function
T = TypeVar('T')

def first(items: List[T]) -> Optional[T]:
    return items[0] if items else None

first([1, 2, 3])  # Returns int
first(["a", "b"])  # Returns str
```

### TypeScript: Generics

```typescript
// Generic array
const names: Array<string> = ["Blake", "Alex"]
const numbers: Array<number> = [1, 2, 3]

// Or shorthand
const names: string[] = ["Blake", "Alex"]
const numbers: number[] = [1, 2, 3]

// Generic function
function first<T>(items: T[]): T | undefined {
    return items[0]
}

first([1, 2, 3])  // Returns number | undefined
first(["a", "b"])  // Returns string | undefined

// Generic Promise
async function fetchData(): Promise<User> {
    const response = await fetch("/api/user")
    return response.json()  // Returns Promise<User>
}
```

### Common Generic Types

```typescript
// Promise<T> - async result
const promise: Promise<string> = fetch("/api/data").then(r => r.text())

// Array<T> - list of items
const users: Array<User> = []

// Record<K, V> - dictionary/object
const ages: Record<string, number> = { "Blake": 30 }

// Partial<T> - all properties optional
interface User {
    name: string
    age: number
}
const partialUser: Partial<User> = { name: "Blake" }  // age is optional

// Pick<T, K> - subset of properties
const nameOnly: Pick<User, "name"> = { name: "Blake" }  // Only name

// Omit<T, K> - exclude properties
const withoutAge: Omit<User, "age"> = { name: "Blake" }  // No age
```

---

## Union Types and Optionals

### Python: Union and Optional

```python
from typing import Union, Optional

# Union: can be multiple types
def format_value(value: Union[str, int]) -> str:
    return str(value)

format_value("hello")  # ✅
format_value(42)       # ✅

# Optional: can be None
def greet(name: Optional[str] = None) -> str:
    if name is None:
        return "Hello, stranger"
    return f"Hello, {name}"
```

### TypeScript: Union Types

```typescript
// Union: can be multiple types
function formatValue(value: string | number): string {
    return String(value)
}

formatValue("hello")  // ✅
formatValue(42)       // ✅

// Optional: can be undefined
function greet(name?: string): string {
    if (name === undefined) {
        return "Hello, stranger"
    }
    return `Hello, ${name}`
}

// Or explicitly:
function greet(name: string | undefined): string {
    // Same as above
}
```

### Literal Types

```typescript
// Literal types: specific values
type Status = "active" | "inactive" | "pending"

function setStatus(status: Status) {
    console.log(status)
}

setStatus("active")     // ✅
setStatus("inactive")   // ✅
setStatus("deleted")    // ❌ Not in union!

// Numbers too
type DiceRoll = 1 | 2 | 3 | 4 | 5 | 6

const roll: DiceRoll = 3  // ✅
const roll: DiceRoll = 7  // ❌
```

### Discriminated Unions (Tagged Unions)

```typescript
// Like Python's Union with type field
interface SuccessResult {
    type: "success"
    data: string
}

interface ErrorResult {
    type: "error"
    message: string
}

type Result = SuccessResult | ErrorResult

function handleResult(result: Result) {
    if (result.type === "success") {
        console.log(result.data)  // TypeScript knows it's SuccessResult
    } else {
        console.log(result.message)  // TypeScript knows it's ErrorResult
    }
}
```

---

## Type Inference

### TypeScript Is Smart: Often No Annotations Needed

```typescript
// Type is inferred from value
const name = "Blake"  // TypeScript knows: string
const age = 30        // TypeScript knows: number
const active = true   // TypeScript knows: boolean

// Arrays inferred from elements
const numbers = [1, 2, 3]  // number[]
const mixed = [1, "two", 3]  // (number | string)[]

// Functions inferred from return
function double(x: number) {
    return x * 2  // Return type inferred as number
}

// Generics inferred from arguments
function first<T>(arr: T[]) {
    return arr[0]
}

const num = first([1, 2, 3])  // TypeScript knows: number | undefined
const str = first(["a", "b"])  // TypeScript knows: string | undefined
```

### When to Annotate

**Annotate when:**
1. Function parameters (always)
2. Function return types (good practice, not required)
3. Unclear inference (rare)

**Don't annotate when:**
1. Variable assignment is obvious: `const x = 5`
2. Return type can be inferred correctly

```typescript
// Good: Parameters annotated, return inferred
function add(a: number, b: number) {
    return a + b  // Return type inferred as number
}

// Better: Explicit return type (good practice)
function add(a: number, b: number): number {
    return a + b
}

// Unnecessary: Return type is obvious
const name: string = "Blake"  // Don't do this
const name = "Blake"          // Do this
```

---

## Our Types: web/src/types/provider.ts

### Real Example from Provider Search

```typescript
// Status types (union of string literals)
export type PlaceStatus = 'hard_lead' | 'soft_lead' | 'existing' | 'non_target' | 'does_not_exist'

// Type alias
export type ProviderStatus = PlaceStatus
export type ProviderStatusMap = Record<string, PlaceStatus>

// Interface for search results
export interface SearchResult {
    name: string
    specialty: string
    address: string
    city: string
    state: string
    zip_code: string
    phone: string
    rating: number | null  // Can be null
    review_count: number
    lat: number
    lng: number
    place_id: string
    website: string | null
    description: string | null
    entity_type: EntityType
    affiliated_providers: string[]
    affiliated_places: string[]
    place_types?: string[]  // Optional
    opening_hours?: OpeningHours | null
}

// Type alias (another name for the same thing)
export type Provider = SearchResult

// Search request interface
export interface SearchRequest {
    query: string
    radius_miles: number
    search_type?: SearchType  // Optional
    max_results?: number
    map_center_lat?: number
    map_center_lng?: number
    map_radius_miles?: number
}

// Generic API response
export interface SearchResponse {
    query: string
    location: string
    total_results: number
    filtered_count: number
    providers: SearchResult[]  // Array of SearchResult
    search_id: string
    searched_at: string
    parsed: ParsedTerms
    search_type: SearchType
    location_source: 'query' | 'ip' | 'unknown'  // Literal union
    ip_city: string | null
    ip_state: string | null
}
```

### How We Use These Types

```typescript
// In api/search.ts
import type { SearchResponse, SearchRequest } from '../types/provider'

export async function search(request: SearchRequest): Promise<SearchResponse> {
    const response = await apiCall<SearchResponse>('/search', {
        method: 'POST',
        body: JSON.stringify(request)
    })
    return response
}

// In a component
import type { Provider } from '../types/provider'

function ProviderCard({ provider }: { provider: Provider }) {
    return (
        <div>
            <h3>{provider.name}</h3>
            <p>{provider.specialty}</p>
            <p>{provider.address}, {provider.city}, {provider.state}</p>
        </div>
    )
}
```

**Benefits:**
- Autocomplete in VS Code
- Compile-time errors if we misspell a property
- Refactoring is safe (rename propagates everywhere)
- Self-documenting code

---

## tsconfig.json

### Configuration File

```json
{
  "compilerOptions": {
    "target": "ES2020",           // JavaScript version to compile to
    "lib": ["ES2020", "DOM"],     // Built-in type definitions
    "jsx": "react-jsx",           // JSX transformation
    "module": "ESNext",           // Module system
    "moduleResolution": "bundler", // How to resolve imports
    
    "strict": true,               // Enable all strict checks
    "noUnusedLocals": true,       // Error on unused variables
    "noUnusedParameters": true,   // Error on unused parameters
    "noFallthroughCasesInSwitch": true,
    
    "skipLibCheck": true,         // Skip type checking of .d.ts files
    "esModuleInterop": true,      // Better CommonJS interop
  },
  "include": ["src"],             // Which files to compile
  "exclude": ["node_modules"]     // Which to skip
}
```

### Key Settings

| Setting | Meaning |
|---------|---------|
| `strict: true` | Enable all strict type checks (recommended) |
| `noImplicitAny: true` | Error on variables with implicit `any` type |
| `strictNullChecks: true` | `null` and `undefined` must be explicit |
| `jsx: "react-jsx"` | How to transform JSX (React 17+ doesn't need `import React`) |

---

## When to Use `any`

### The Escape Hatch

```typescript
// any: Disables type checking
let value: any = 5
value = "string"  // ✅ No error
value = {}        // ✅ No error
value.nonExistent()  // ✅ No compile error (but runtime error!)
```

**Problem:** `any` defeats the entire purpose of TypeScript.

### When It's OK

1. **Third-party library with no types** (rare, most have @types packages)
2. **Prototyping** (come back and fix it later)
3. **Truly dynamic data** (but consider `unknown` instead)

### Better: Use `unknown`

```typescript
// unknown: Type-safe any
let value: unknown = 5

// Must check type before using
if (typeof value === "number") {
    console.log(value * 2)  // ✅ Safe
}

value.toString()  // ❌ Error! Must check type first
```

### Type Assertions (Use Sparingly)

```typescript
// When you know more than TypeScript
const element = document.getElementById("root") as HTMLDivElement

// Or old syntax (avoid in JSX)
const element = <HTMLDivElement>document.getElementById("root")

// Non-null assertion (risky!)
const value = getValue()!  // I promise it's not null!
```

**Rule:** Avoid `any`, prefer `unknown`, use type assertions only when necessary.

---

## Summary: Python ↔ TypeScript Types

| Python | TypeScript |
|--------|------------|
| `int`, `float` | `number` |
| `str` | `string` |
| `bool` | `boolean` |
| `None` | `null`, `undefined` |
| `List[int]` | `number[]` or `Array<number>` |
| `Dict[str, int]` | `Record<string, number>` |
| `Union[str, int]` | `string \| number` |
| `Optional[str]` | `string \| undefined` or `string?` |
| `TypedDict` | `interface` |
| `dataclass` | `interface` |
| `TypeVar` | Generic `<T>` |
| Type hints (optional) | Types (enforced) |

---

## Why This Matters for Provider Search

**Our entire codebase is typed:**
- `web/src/types/provider.ts` — Domain types (Provider, SearchResponse, etc.)
- Every component prop is typed
- Every API call has typed request/response
- React hooks have typed returns

**Benefits we get:**
- Autocomplete shows available properties
- Refactoring is safe (rename works everywhere)
- Bugs caught at compile time, not runtime
- Self-documenting code (types are the docs)

**Example:** Change `SearchResult.name` to `SearchResult.providerName`
→ TypeScript errors everywhere that uses it
→ Fix them all, guaranteed to work

---

## Next Steps

- **[04-how-browsers-work.md](04-how-browsers-work.md)** — Understanding the runtime environment
- **[06-react-fundamentals.md](06-react-fundamentals.md)** — Using TypeScript with React

---

**You now understand TypeScript. Our codebase makes much more sense with types.**
