# Build Tools and Bundling

**From TypeScript to Browser-Runnable JavaScript**

Browsers can't run TypeScript, JSX, or ES6 modules directly. Build tools transform your code into browser-compatible JavaScript.

---

## Table of Contents

1. [Why You Can't Just Put .tsx Files in the Browser](#why-you-cant-just-put-tsx-files-in-the-browser)
2. [The Build Pipeline](#the-build-pipeline)
3. [Vite: Our Build Tool](#vite-our-build-tool)
4. [package.json](#packagejson)
5. [node_modules](#node_modules)
6. [npm vs yarn vs pnpm](#npm-vs-yarn-vs-pnpm)
7. [Environment Variables](#environment-variables)
8. [Our Build Output](#our-build-output)

---

## Why You Can't Just Put .tsx Files in the Browser

### What Browsers Understand

```html
<!-- Browsers understand: -->
<script src="app.js"></script>  <!-- Plain JavaScript -->
<script type="module" src="app.js"></script>  <!-- ES6 modules (modern) -->
```

```javascript
// Plain JavaScript the browser understands
function greet(name) {
    return "Hello, " + name
}
```

### What Browsers Don't Understand

```typescript
// TypeScript
interface User {
    name: string
    age: number
}

function greet(user: User): string {
    return `Hello, ${user.name}`
}
```

```jsx
// JSX
function Component() {
    return <div>Hello</div>
}
```

```javascript
// Modern imports (need bundling)
import { useState } from 'react'
import { apiCall } from './api/client'
```

**Build tools transform these into browser-compatible JavaScript.**

---

## The Build Pipeline

### Development Mode

```
TypeScript (.tsx, .ts)
        ↓
  [Vite Dev Server]
        ↓
  Transform on-the-fly
        ↓
  Serve to browser
        ↓
  Hot Module Replacement (instant updates)
```

### Production Mode

```
TypeScript (.tsx, .ts)
        ↓
  [TypeScript Compiler]
  ├── Type checking
  └── Strip types
        ↓
  JavaScript (.js)
        ↓
  [Bundler (Rollup)]
  ├── Resolve imports
  ├── Bundle files
  ├── Tree-shake unused code
  ├── Minify
  └── Code-split
        ↓
  dist/assets/index-abc123.js (optimized bundle)
```

---

## Vite: Our Build Tool

### What Is Vite?

**Python analogy:** Like a combination of:
- `python -m http.server` (dev server)
- `pyinstaller` (bundler)
- `pytest` (test runner, via Vitest)

**Vite = Dev server + Build tool**

### Why Vite Is Fast

**Traditional bundlers (Webpack):**
- Bundle entire app on startup (slow)
- Re-bundle on changes (slow)

**Vite:**
- Uses native ES modules in development (instant startup)
- Only transforms files you request (fast)
- Hot Module Replacement (HMR) — update without full reload

### Vite Commands

```bash
# Development (local server with HMR)
npm run dev
# → http://localhost:5173

# Production build
npm run build
# → Creates dist/ folder

# Preview production build
npm run preview
```

### vite.config.ts

```typescript
// web/vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],  // JSX transformation
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8000'  // Proxy API requests to FastAPI
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true  // For debugging production
  }
})
```

---

## package.json

### Python comparison: requirements.txt + setup.py

```python
# Python requirements.txt
fastapi==0.100.0
httpx==0.24.0

# Python setup.py
setup(
    name="my-package",
    version="1.0.0",
    scripts={
        'dev': 'uvicorn main:app --reload'
    }
)
```

```json
// JavaScript package.json
{
  "name": "provider-search-web",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-router-dom": "^6.15.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "typescript": "^5.2.0"
  }
}
```

### Key Sections

| Section | Purpose | Python Equivalent |
|---------|---------|-------------------|
| `name` | Package name | `setup.py name` |
| `version` | Package version | `setup.py version` |
| `scripts` | Commands you can run | `setup.py scripts` |
| `dependencies` | Production dependencies | `requirements.txt` |
| `devDependencies` | Dev-only dependencies | `requirements-dev.txt` |

### Scripts

```bash
# Defined in package.json scripts section
npm run dev      # vite
npm run build    # tsc && vite build
npm run test     # vitest
```

### Semantic Versioning

```json
"react": "^18.2.0"
```

- `^18.2.0` = Allow minor/patch updates (18.2.x, 18.3.0) but not major (19.0.0)
- `~18.2.0` = Allow patch updates only (18.2.x)
- `18.2.0` = Exact version only

---

## node_modules

### Python: venv/site-packages

```python
# Python virtual environment
venv/
└── lib/
    └── python3.11/
        └── site-packages/
            ├── fastapi/
            ├── httpx/
            └── ...
```

### JavaScript: node_modules

```
node_modules/
├── react/
├── react-dom/
├── react-router-dom/
│   └── node_modules/  # Dependencies of dependencies
│       ├── ...
└── ...
```

**Difference:** `node_modules` includes all transitive dependencies (nested). Can be huge (100s of MB).

### Installing Dependencies

```bash
# Python
pip install fastapi

# JavaScript
npm install react

# Install from package.json
npm install
```

### .gitignore

```
# Don't commit node_modules!
node_modules/

# Do commit package.json and package-lock.json
```

**Why:** `node_modules` is huge and reproducible from `package.json`. Like not committing `venv/` in Python.

---

## npm vs yarn vs pnpm

### Package Managers

| Tool | Install Command | Lockfile | Speed |
|------|----------------|----------|-------|
| npm | `npm install` | `package-lock.json` | Medium |
| yarn | `yarn` | `yarn.lock` | Fast |
| pnpm | `pnpm install` | `pnpm-lock.yaml` | Fastest |

**They all do the same thing:** Install dependencies from `package.json`.

### Lockfiles

```json
// package.json (loose versions)
{
  "dependencies": {
    "react": "^18.2.0"  // Could be 18.2.0, 18.2.5, 18.3.0, etc.
  }
}

// package-lock.json (exact versions)
{
  "react": {
    "version": "18.2.0",  // Exact version installed
    "resolved": "https://...",
    "integrity": "sha512-..."
  }
}
```

**Purpose:** Ensure everyone installs the exact same versions (reproducible builds).

---

## Environment Variables

### Python: os.environ

```python
import os

API_KEY = os.environ.get("API_KEY")
DEBUG = os.environ.get("DEBUG", "false") == "true"
```

### JavaScript: import.meta.env (Vite)

```typescript
// .env file
VITE_API_BASE_URL=http://localhost:8000
VITE_SUPABASE_URL=https://...

// In code
const apiBase = import.meta.env.VITE_API_BASE_URL
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL

// Built-in
const isDev = import.meta.env.DEV  // true in dev mode
const isProd = import.meta.env.PROD  // true in production
```

**VITE_ prefix required:** Only variables starting with `VITE_` are exposed to client code (security).

### Environment Files

```
.env                 # All environments
.env.local          # Local overrides (gitignored)
.env.development    # Dev mode only
.env.production     # Production mode only
```

---

## Our Build Output

### Development (npm run dev)

```
No build output!
Vite serves files directly from src/
Hot Module Replacement updates on save
```

### Production (npm run build)

```bash
npm run build

# Output:
dist/
├── index.html                    # Entry point
├── assets/
│   ├── index-a3f5b2c8.js        # Main bundle (hashed filename)
│   ├── index-d4e6f7g8.css       # Styles bundle
│   ├── vendor-b2c3d4e5.js       # Dependencies (React, etc.)
│   └── ProviderMap-c3d4e5f6.js  # Code-split chunk
└── ...
```

**Hashed filenames:** `index-a3f5b2c8.js` changes hash when content changes → browser cache invalidation.

### Bundle Analysis

```bash
# See what's in the bundle
npm run build -- --mode analyze

# Opens visualization showing:
# - Which dependencies are largest
# - What contributes to bundle size
```

### Code Splitting

```typescript
// Lazy load component (split into separate bundle)
const HeavyComponent = lazy(() => import('./HeavyComponent'))

function App() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <HeavyComponent />
        </Suspense>
    )
}
```

**Result:** `HeavyComponent` code only loaded when needed, not in main bundle.

---

## Why This Matters for Provider Search

**Our build process:**

1. **Development:** `npm run dev`
   - Vite dev server on port 5173
   - TypeScript compiled on-the-fly
   - HMR updates components instantly
   - Proxies `/api` to FastAPI backend (port 8000)

2. **Production:** `npm run build`
   - TypeScript type-checks entire codebase
   - Vite bundles and minifies code
   - Outputs to `dist/` folder
   - Ready to serve from nginx/CDN

**When you change code:**
- Dev: Save → Vite transforms → Browser updates (instant)
- Prod: Build → Deploy → Browser downloads new bundle

**Dependencies:**
- `package.json` lists dependencies
- `npm install` downloads to `node_modules/`
- Vite bundles them into final output
- Don't commit `node_modules/` (regenerated from `package.json`)

---

## Next Steps

- **[11-data-fetching-and-server-state.md](11-data-fetching-and-server-state.md)** — React Query and API calls
- **[13-application-architecture.md](13-application-architecture.md)** — Full project structure

---

**You now understand the build pipeline. TypeScript → JavaScript happens transparently.**
