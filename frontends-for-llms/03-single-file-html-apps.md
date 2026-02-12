# Single-File HTML Apps

## Table of Contents
- [The Power of Single-File HTML](#the-power-of-single-file-html)
- [Basic Structure](#basic-structure)
- [Adding Tailwind CSS](#adding-tailwind-css)
- [Adding Alpine.js for Reactivity](#adding-alpinejs-for-reactivity)
- [Adding Visualization Libraries](#adding-visualization-libraries)
- [Fetching from APIs](#fetching-from-apis)
- [Real-World Examples](#real-world-examples)
- [When to Stay Single-File](#when-to-stay-single-file)
- [Starter Template](#starter-template)

## The Power of Single-File HTML

**Zero build tools. Instant feedback. Maximum velocity.**

Single-file HTML apps are the secret weapon for rapid prototyping with LLMs:

✅ **No npm install** — just open in browser  
✅ **No webpack, vite, or build config** — zero setup time  
✅ **No deploy process** — send file, anyone can open it  
✅ **Instant iteration** — edit, save, refresh (1 second)  
✅ **Works anywhere** — local, USB drive, email attachment  
✅ **Perfect for demos** — share with non-technical stakeholders  

### When to Reach for Single-File HTML

- **Internal tools:** Admin dashboards, debug panels, data viewers
- **Prototypes:** Quick mockups to validate ideas
- **Data exploration:** CSV viewers, API testers, log analyzers
- **Demos:** Showing clients/stakeholders a concept
- **Learning:** Understanding how something works
- **Hackathons:** Ship fast, iterate faster

**Rule of thumb:** If it doesn't need a database or user accounts, try single-file first.

## Basic Structure

Every single-file HTML app follows the same pattern:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    
    <!-- External CSS/JS libraries via CDN -->
    <link rel="stylesheet" href="https://cdn.example.com/library.css">
    
    <!-- Inline styles (optional) -->
    <style>
        /* Your custom CSS here */
    </style>
</head>
<body>
    
    <!-- Your HTML structure -->
    <div id="app">
        <!-- Content goes here -->
    </div>
    
    <!-- External JS libraries via CDN -->
    <script src="https://cdn.example.com/library.js"></script>
    
    <!-- Your JavaScript -->
    <script>
        // Your logic here
    </script>
    
</body>
</html>
```

**Three sections:**
1. **Head:** Meta tags, title, CSS imports, inline styles
2. **Body:** HTML structure
3. **Scripts:** JS imports and inline logic

## Adding Tailwind CSS

**Tailwind CSS via CDN** is the fastest way to get modern, professional styling:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    
    <!-- Tailwind CSS via CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-900 text-white min-h-screen p-8">
    
    <div class="max-w-6xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">Dashboard</h1>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <!-- Metric Card -->
            <div class="bg-gray-800 rounded-lg p-6 shadow-lg">
                <div class="text-gray-400 text-sm uppercase mb-2">Revenue</div>
                <div class="text-3xl font-bold">$42,150</div>
                <div class="text-green-500 text-sm mt-2">↑ 12% from last month</div>
            </div>
            
            <!-- More cards... -->
        </div>
    </div>
    
</body>
</html>
```

**One script tag, instant styling.**

### Tailwind Configuration (Optional)

You can customize Tailwind inline:

```html
<script>
    tailwind.config = {
        theme: {
            extend: {
                colors: {
                    primary: '#7c3aed',
                    secondary: '#ec4899'
                }
            }
        }
    }
</script>
```

Now use: `bg-primary`, `text-secondary`

## Adding Alpine.js for Reactivity

**Alpine.js** is "Tailwind for JavaScript" — reactive behavior without React.

### Why Alpine.js?

✅ **Tiny** (15KB gzipped)  
✅ **No build step** — works via CDN  
✅ **Declarative** — behavior in HTML attributes  
✅ **Reactive** — data binding, state management  
✅ **Lightweight** — perfect for single-file apps  

### Basic Setup

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Counter</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-900 text-white p-8">
    
    <!-- Alpine component -->
    <div x-data="{ count: 0 }" class="max-w-md mx-auto text-center">
        <h1 class="text-4xl font-bold mb-4">Counter</h1>
        <div class="text-6xl font-bold my-8" x-text="count"></div>
        
        <button @click="count++" 
                class="bg-blue-600 px-6 py-3 rounded-lg hover:bg-blue-700">
            Increment
        </button>
        
        <button @click="count--" 
                class="bg-red-600 px-6 py-3 rounded-lg hover:bg-red-700 ml-2">
            Decrement
        </button>
    </div>
    
</body>
</html>
```

### Alpine.js Patterns

**Data binding:**
```html
<div x-data="{ name: 'World' }">
    <input x-model="name" class="border p-2">
    <p>Hello, <span x-text="name"></span>!</p>
</div>
```

**Show/hide:**
```html
<div x-data="{ open: false }">
    <button @click="open = !open">Toggle</button>
    <div x-show="open" x-transition>
        Content that shows/hides
    </div>
</div>
```

**Lists:**
```html
<div x-data="{ items: ['Apple', 'Banana', 'Cherry'] }">
    <ul>
        <template x-for="item in items" :key="item">
            <li x-text="item"></li>
        </template>
    </ul>
</div>
```

**Fetch data:**
```html
<div x-data="{ 
    users: [],
    async fetchUsers() {
        const res = await fetch('https://api.example.com/users');
        this.users = await res.json();
    }
}" x-init="fetchUsers()">
    <template x-for="user in users" :key="user.id">
        <div x-text="user.name"></div>
    </template>
</div>
```

**Alpine.js = React hooks without the build step.**

## Adding Visualization Libraries

CDNs make it trivial to add charts, maps, and graphs.

### Chart.js for Charts

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Analytics Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="bg-gray-900 text-white p-8">
    
    <div class="max-w-4xl mx-auto">
        <h1 class="text-3xl font-bold mb-8">Revenue Over Time</h1>
        <canvas id="revenueChart"></canvas>
    </div>
    
    <script>
        const ctx = document.getElementById('revenueChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                datasets: [{
                    label: 'Revenue',
                    data: [12000, 19000, 15000, 25000, 22000, 30000],
                    borderColor: '#7c3aed',
                    backgroundColor: 'rgba(124, 58, 237, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                }
            }
        });
    </script>
    
</body>
</html>
```

**One script tag, instant charts.**

### Leaflet for Maps

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Provider Map</title>
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Leaflet CSS and JS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
</head>
<body class="bg-gray-900">
    
    <div id="map" style="height: 100vh;"></div>
    
    <script>
        // Create map
        const map = L.map('map').setView([37.7749, -122.4194], 12);
        
        // Add tile layer (map tiles)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);
        
        // Add markers
        const providers = [
            { name: 'Dr. Smith', lat: 37.7849, lng: -122.4094 },
            { name: 'Dr. Jones', lat: 37.7649, lng: -122.4294 }
        ];
        
        providers.forEach(p => {
            L.marker([p.lat, p.lng])
                .bindPopup(`<b>${p.name}</b>`)
                .addTo(map);
        });
    </script>
    
</body>
</html>
```

### D3.js for Custom Visualizations

```html
<script src="https://d3js.org/d3.v7.min.js"></script>

<div id="viz"></div>

<script>
    const data = [30, 86, 168, 281, 303, 365];
    
    d3.select("#viz")
        .selectAll("div")
        .data(data)
        .enter()
        .append("div")
        .style("width", d => d + "px")
        .style("height", "20px")
        .style("background", "#7c3aed")
        .style("margin", "2px")
        .text(d => d);
</script>
```

**The pattern:** CDN import → use immediately → no compilation.

## Fetching from APIs

Modern browsers have `fetch()` built-in — no libraries needed.

### Basic GET Request

```javascript
fetch('https://api.example.com/data')
    .then(response => response.json())
    .then(data => {
        console.log(data);
        // Update DOM with data
    })
    .catch(error => console.error('Error:', error));
```

### With Loading and Error States

```html
<div x-data="{
    data: null,
    loading: false,
    error: null,
    async fetchData() {
        this.loading = true;
        this.error = null;
        try {
            const res = await fetch('https://api.example.com/data');
            this.data = await res.json();
        } catch (err) {
            this.error = err.message;
        } finally {
            this.loading = false;
        }
    }
}" x-init="fetchData()">
    
    <div x-show="loading">Loading...</div>
    <div x-show="error" class="text-red-500" x-text="error"></div>
    <div x-show="data">
        <!-- Display data here -->
    </div>
    
</div>
```

### POST Request

```javascript
fetch('https://api.example.com/submit', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ name: 'John', email: 'john@example.com' })
})
    .then(response => response.json())
    .then(data => console.log('Success:', data))
    .catch(error => console.error('Error:', error));
```

### CORS Issues?

If you get CORS errors, you can:
1. **Run a local proxy** (simple Python server)
2. **Use a CORS proxy service** (for testing only!)
3. **Request backend team to add CORS headers**

## Real-World Examples

### Example 1: CSV Viewer

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CSV Viewer</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-900 text-white p-8">
    
    <div x-data="csvViewer()" class="max-w-6xl mx-auto">
        <h1 class="text-3xl font-bold mb-4">CSV Viewer</h1>
        
        <input type="file" @change="loadFile($event)" 
               class="mb-4 p-2 bg-gray-800 rounded">
        
        <div x-show="rows.length > 0" class="overflow-x-auto">
            <table class="w-full border-collapse">
                <thead>
                    <tr>
                        <template x-for="header in headers" :key="header">
                            <th class="border border-gray-700 p-2 bg-gray-800" 
                                x-text="header"></th>
                        </template>
                    </tr>
                </thead>
                <tbody>
                    <template x-for="(row, i) in rows" :key="i">
                        <tr>
                            <template x-for="(cell, j) in row" :key="j">
                                <td class="border border-gray-700 p-2" 
                                    x-text="cell"></td>
                            </template>
                        </tr>
                    </template>
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        function csvViewer() {
            return {
                headers: [],
                rows: [],
                loadFile(event) {
                    const file = event.target.files[0];
                    const reader = new FileReader();
                    reader.onload = (e) => {
                        const text = e.target.result;
                        const lines = text.split('\n').filter(l => l.trim());
                        this.headers = lines[0].split(',');
                        this.rows = lines.slice(1).map(line => line.split(','));
                    };
                    reader.readAsText(file);
                }
            };
        }
    </script>
    
</body>
</html>
```

**Use case:** Quickly inspect CSV files without Excel

### Example 2: API Tester

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>API Tester</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-900 text-white p-8">
    
    <div x-data="apiTester()" class="max-w-4xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">API Tester</h1>
        
        <div class="mb-4">
            <select x-model="method" class="bg-gray-800 p-2 rounded mr-2">
                <option>GET</option>
                <option>POST</option>
                <option>PUT</option>
                <option>DELETE</option>
            </select>
            
            <input x-model="url" type="text" placeholder="https://api.example.com/endpoint"
                   class="bg-gray-800 p-2 rounded flex-1 w-96">
        </div>
        
        <div class="mb-4">
            <textarea x-model="body" placeholder="Request body (JSON)"
                      class="bg-gray-800 p-2 rounded w-full h-24"
                      x-show="method !== 'GET'"></textarea>
        </div>
        
        <button @click="sendRequest()" 
                class="bg-purple-600 px-6 py-2 rounded hover:bg-purple-700">
            Send Request
        </button>
        
        <div x-show="loading" class="mt-4">Loading...</div>
        
        <div x-show="response" class="mt-4">
            <h2 class="text-xl font-bold mb-2">Response:</h2>
            <pre class="bg-gray-800 p-4 rounded overflow-x-auto"
                 x-text="JSON.stringify(response, null, 2)"></pre>
        </div>
    </div>
    
    <script>
        function apiTester() {
            return {
                method: 'GET',
                url: '',
                body: '',
                response: null,
                loading: false,
                async sendRequest() {
                    this.loading = true;
                    this.response = null;
                    try {
                        const options = { method: this.method };
                        if (this.method !== 'GET' && this.body) {
                            options.headers = { 'Content-Type': 'application/json' };
                            options.body = this.body;
                        }
                        const res = await fetch(this.url, options);
                        this.response = await res.json();
                    } catch (err) {
                        this.response = { error: err.message };
                    } finally {
                        this.loading = false;
                    }
                }
            };
        }
    </script>
    
</body>
</html>
```

**Use case:** Test API endpoints without Postman

## When to Stay Single-File

**Stick with single-file HTML when:**

✅ **It's an internal tool** — only you or your team will use it  
✅ **It's a prototype** — validating an idea, not building for production  
✅ **It doesn't need auth** — no user accounts or permissions  
✅ **It's data-light** — not handling thousands of records  
✅ **You want to share it easily** — email attachment, USB drive  
✅ **Speed matters more than polish** — ship in minutes, not days  

**Graduate to React when:**

❌ It becomes customer-facing and needs polish  
❌ State management gets complex (multi-step flows, real-time updates)  
❌ You need proper testing and CI/CD  
❌ The prototype is validated and needs to scale  
❌ You're integrating with a larger React codebase  

**Rule of thumb:** Single-file is for prototypes and tools. React is for products.

## Starter Template

**Copy-paste this to start any single-file HTML project:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Alpine.js for reactivity -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    
    <!-- Optional: Chart.js -->
    <!-- <script src="https://cdn.jsdelivr.net/npm/chart.js"></script> -->
    
    <!-- Optional: Leaflet for maps -->
    <!-- <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" /> -->
    <!-- <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script> -->
</head>
<body class="bg-gray-900 text-white min-h-screen p-8">
    
    <div x-data="app()" class="max-w-6xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">My App</h1>
        
        <!-- Your content here -->
        
    </div>
    
    <script>
        function app() {
            return {
                // Your state and methods here
                message: 'Hello, World!',
                
                async fetchData() {
                    const res = await fetch('https://api.example.com/data');
                    return await res.json();
                }
            };
        }
    </script>
    
</body>
</html>
```

**Save as `template.html`, duplicate and customize for each project.**

## Key Takeaways

1. **Single-file HTML = zero build tools, instant feedback**
2. **Tailwind CSS via CDN** for instant styling
3. **Alpine.js** for reactivity without React
4. **Chart.js, Leaflet, D3** via CDN for visualizations
5. **fetch() is built-in** — no axios needed
6. **Perfect for prototypes and internal tools**
7. **Graduate to React when the prototype is validated**

---

**Try This Now:**

Create a single-file HTML app that fetches data from a public API and displays it:

```bash
claude -p "Create a single-file HTML app that fetches GitHub user info 
from https://api.github.com/users/{username} and displays avatar, name, 
bio, follower count, and repo count. Use Tailwind CSS dark theme and 
Alpine.js. Include an input for username and a search button."

# Save output
claude -p "..." > github-viewer.html

# Open in browser
open github-viewer.html
```

Try searching for different GitHub users. Instant, working app in under 2 minutes.

→ Next: [Prompt Engineering for Frontends](04-prompt-engineering-for-frontends.md)
