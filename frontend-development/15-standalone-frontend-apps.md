# 15. Standalone Frontend Apps

**Goal:** Learn to build powerful web applications without React, using only HTML, CSS, and JavaScript. Understand when you DON'T need a framework.

---

## When You Don't Need React

React is powerful, but it's not always necessary. You can build a lot with vanilla JavaScript.

### Use React/frameworks when:
- Large application with many interconnected components
- Complex state management (user data, carts, dashboards)
- Frequent UI updates (real-time collaboration, feeds)
- Team of developers needing shared patterns

### Use vanilla JavaScript when:
- Small tools (calculators, converters, timers)
- Static sites with sprinkles of interactivity
- Widgets embedded in other sites
- Single-page utilities
- Learning (understanding the fundamentals)

---

## Progressive Enhancement

Start with HTML that works without JavaScript, then enhance with JS.

### Example: Form Submission

**Step 1: HTML only (works without JS)**
```html
<form action="/api/search" method="POST">
  <input name="query" type="text" required>
  <button type="submit">Search</button>
</form>
```

**Step 2: Add JavaScript enhancement**
```html
<form id="searchForm" action="/api/search" method="POST">
  <input name="query" type="text" required>
  <button type="submit">Search</button>
  <div id="results"></div>
</form>

<script>
document.getElementById('searchForm').addEventListener('submit', async (e) => {
  e.preventDefault()  // Prevent page reload
  
  const formData = new FormData(e.target)
  const query = formData.get('query')
  
  const response = await fetch('/api/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query })
  })
  
  const results = await response.json()
  
  // Update page without reload
  document.getElementById('results').innerHTML = results
    .map(r => `<div>${r.name}</div>`)
    .join('')
})
</script>
```

**Python analogy:**
```python
# Progressive enhancement in Flask
@app.route('/search', methods=['POST'])
def search():
    query = request.form.get('query') or request.json.get('query')
    results = search_database(query)
    
    # If JavaScript, return JSON
    if request.headers.get('Content-Type') == 'application/json':
        return jsonify(results)
    
    # Otherwise, return full HTML page
    return render_template('search_results.html', results=results)
```

---

## Building a Complete App: To-Do List

Let's build a to-do list app with zero dependencies.

### index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>To-Do List</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: system-ui, sans-serif;
      background: #1a1a1a;
      color: #fff;
      padding: 2rem;
      max-width: 600px;
      margin: 0 auto;
    }
    
    h1 {
      margin-bottom: 2rem;
    }
    
    .input-group {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1rem;
    }
    
    input {
      flex: 1;
      padding: 0.75rem;
      border: 2px solid #333;
      background: #222;
      color: #fff;
      border-radius: 8px;
      font-size: 1rem;
    }
    
    button {
      padding: 0.75rem 1.5rem;
      background: #0066ff;
      color: #fff;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-size: 1rem;
      font-weight: 500;
    }
    
    button:hover {
      background: #0052cc;
    }
    
    .todo-list {
      list-style: none;
    }
    
    .todo-item {
      background: #222;
      padding: 1rem;
      margin-bottom: 0.5rem;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }
    
    .todo-item.completed {
      opacity: 0.5;
    }
    
    .todo-item.completed .todo-text {
      text-decoration: line-through;
    }
    
    .todo-text {
      flex: 1;
    }
    
    .delete-btn {
      background: #ff3b30;
      padding: 0.5rem 1rem;
      font-size: 0.875rem;
    }
    
    .delete-btn:hover {
      background: #cc2f26;
    }
    
    .checkbox {
      width: 20px;
      height: 20px;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <h1>To-Do List</h1>
  
  <div class="input-group">
    <input 
      type="text" 
      id="todoInput" 
      placeholder="What needs to be done?"
      autofocus
    >
    <button id="addBtn">Add</button>
  </div>
  
  <ul class="todo-list" id="todoList"></ul>
  
  <script>
    // State management
    class TodoApp {
      constructor() {
        this.todos = this.loadFromStorage()
        this.render()
        this.attachEventListeners()
      }
      
      loadFromStorage() {
        const stored = localStorage.getItem('todos')
        return stored ? JSON.parse(stored) : []
      }
      
      saveToStorage() {
        localStorage.setItem('todos', JSON.stringify(this.todos))
      }
      
      addTodo(text) {
        const todo = {
          id: Date.now(),
          text: text,
          completed: false,
          createdAt: new Date().toISOString()
        }
        this.todos.push(todo)
        this.saveToStorage()
        this.render()
      }
      
      toggleTodo(id) {
        const todo = this.todos.find(t => t.id === id)
        if (todo) {
          todo.completed = !todo.completed
          this.saveToStorage()
          this.render()
        }
      }
      
      deleteTodo(id) {
        this.todos = this.todos.filter(t => t.id !== id)
        this.saveToStorage()
        this.render()
      }
      
      render() {
        const listEl = document.getElementById('todoList')
        
        if (this.todos.length === 0) {
          listEl.innerHTML = '<li style="text-align: center; padding: 2rem; opacity: 0.5;">No todos yet. Add one above!</li>'
          return
        }
        
        listEl.innerHTML = this.todos
          .map(todo => `
            <li class="todo-item ${todo.completed ? 'completed' : ''}" data-id="${todo.id}">
              <input 
                type="checkbox" 
                class="checkbox" 
                ${todo.completed ? 'checked' : ''}
                data-action="toggle"
              >
              <span class="todo-text">${this.escapeHtml(todo.text)}</span>
              <button class="delete-btn" data-action="delete">Delete</button>
            </li>
          `)
          .join('')
      }
      
      escapeHtml(text) {
        const div = document.createElement('div')
        div.textContent = text
        return div.innerHTML
      }
      
      attachEventListeners() {
        // Add todo
        const addBtn = document.getElementById('addBtn')
        const input = document.getElementById('todoInput')
        
        addBtn.addEventListener('click', () => {
          const text = input.value.trim()
          if (text) {
            this.addTodo(text)
            input.value = ''
            input.focus()
          }
        })
        
        input.addEventListener('keypress', (e) => {
          if (e.key === 'Enter') {
            addBtn.click()
          }
        })
        
        // Toggle/delete todos (event delegation)
        document.getElementById('todoList').addEventListener('click', (e) => {
          const todoItem = e.target.closest('.todo-item')
          if (!todoItem) return
          
          const id = parseInt(todoItem.dataset.id)
          const action = e.target.dataset.action
          
          if (action === 'toggle') {
            this.toggleTodo(id)
          } else if (action === 'delete') {
            this.deleteTodo(id)
          }
        })
      }
    }
    
    // Initialize app
    const app = new TodoApp()
  </script>
</body>
</html>
```

### Key Concepts

**1. Single HTML file**
- Everything in one file (HTML, CSS, JavaScript)
- No build step, no npm, no dependencies
- Just open in browser

**2. Class-based state management**
```javascript
class TodoApp {
  constructor() {
    this.todos = []  // State
  }
  
  addTodo(text) {
    this.todos.push({ text })  // Update state
    this.render()              // Update UI
  }
}
```

**Python analogy:**
```python
class TodoApp:
    def __init__(self):
        self.todos = []
    
    def add_todo(self, text):
        self.todos.append({'text': text})
        self.render()
```

**3. localStorage for persistence**
```javascript
// Save
localStorage.setItem('todos', JSON.stringify(this.todos))

// Load
const todos = JSON.parse(localStorage.getItem('todos'))
```

**Python analogy:**
```python
import json

# Save
with open('todos.json', 'w') as f:
    json.dump(todos, f)

# Load
with open('todos.json', 'r') as f:
    todos = json.load(f)
```

**4. Event delegation**

Instead of adding listeners to every button:
```javascript
// ❌ Doesn't work for dynamically added items
document.querySelectorAll('.delete-btn').forEach(btn => {
  btn.addEventListener('click', ...)
})

// ✅ Works for all current and future items
document.getElementById('todoList').addEventListener('click', (e) => {
  if (e.target.dataset.action === 'delete') {
    // Handle delete
  }
})
```

---

## Web Components (Browser-Native)

Web Components let you create reusable components without React.

### Example: Custom Button Component

```html
<!DOCTYPE html>
<html>
<head>
  <title>Web Components Demo</title>
</head>
<body>
  <custom-button color="blue">Click Me</custom-button>
  <custom-button color="red">Delete</custom-button>
  
  <script>
    class CustomButton extends HTMLElement {
      constructor() {
        super()
        
        // Create shadow DOM (encapsulated styles)
        this.attachShadow({ mode: 'open' })
      }
      
      connectedCallback() {
        // Called when element is added to page
        this.render()
      }
      
      render() {
        const color = this.getAttribute('color') || 'blue'
        
        this.shadowRoot.innerHTML = `
          <style>
            button {
              padding: 0.75rem 1.5rem;
              background: ${this.getColor(color)};
              color: white;
              border: none;
              border-radius: 8px;
              cursor: pointer;
              font-size: 1rem;
              font-weight: 500;
              transition: transform 0.1s;
            }
            
            button:hover {
              filter: brightness(1.1);
            }
            
            button:active {
              transform: scale(0.98);
            }
          </style>
          <button>
            <slot></slot>
          </button>
        `
        
        this.shadowRoot.querySelector('button').addEventListener('click', () => {
          this.dispatchEvent(new CustomEvent('buttonClick'))
        })
      }
      
      getColor(name) {
        const colors = {
          blue: '#0066ff',
          red: '#ff3b30',
          green: '#34c759',
        }
        return colors[name] || colors.blue
      }
    }
    
    // Register custom element
    customElements.define('custom-button', CustomButton)
    
    // Use it
    document.querySelector('custom-button').addEventListener('buttonClick', () => {
      alert('Button clicked!')
    })
  </script>
</body>
</html>
```

**Key concepts:**

1. **Extend HTMLElement**
2. **Shadow DOM** — Styles are scoped (don't leak out)
3. **Lifecycle methods:**
   - `connectedCallback()` — Element added to DOM (like React's `useEffect`)
   - `disconnectedCallback()` — Element removed
   - `attributeChangedCallback()` — Attributes changed

**Python analogy:**
```python
# Web Components are like custom Django template tags
from django import template

register = template.Library()

@register.simple_tag
def custom_button(color, text):
    colors = {'blue': '#0066ff', 'red': '#ff3b30'}
    bg_color = colors.get(color, colors['blue'])
    
    return format_html(
        '<button style="background: {};">{}</button>',
        bg_color,
        text
    )

# Use in template: {% custom_button 'blue' 'Click Me' %}
```

---

## Canvas API: Drawing Graphics

The `<canvas>` element lets you draw graphics with JavaScript.

### Example: Interactive Graph

```html
<!DOCTYPE html>
<html>
<head>
  <title>Canvas Demo</title>
  <style>
    body {
      background: #1a1a1a;
      color: #fff;
      font-family: system-ui;
      padding: 2rem;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    
    canvas {
      border: 2px solid #333;
      border-radius: 8px;
      cursor: crosshair;
    }
  </style>
</head>
<body>
  <h1>Canvas Graph</h1>
  <canvas id="graph" width="800" height="400"></canvas>
  
  <script>
    const canvas = document.getElementById('graph')
    const ctx = canvas.getContext('2d')
    
    const dataPoints = []
    
    function drawGraph() {
      // Clear canvas
      ctx.fillStyle = '#1a1a1a'
      ctx.fillRect(0, 0, canvas.width, canvas.height)
      
      // Draw axes
      ctx.strokeStyle = '#555'
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.moveTo(0, canvas.height / 2)
      ctx.lineTo(canvas.width, canvas.height / 2)
      ctx.stroke()
      
      ctx.beginPath()
      ctx.moveTo(canvas.width / 2, 0)
      ctx.lineTo(canvas.width / 2, canvas.height)
      ctx.stroke()
      
      // Draw data points
      if (dataPoints.length === 0) return
      
      ctx.strokeStyle = '#0066ff'
      ctx.lineWidth = 3
      ctx.beginPath()
      ctx.moveTo(dataPoints[0].x, dataPoints[0].y)
      
      for (let i = 1; i < dataPoints.length; i++) {
        ctx.lineTo(dataPoints[i].x, dataPoints[i].y)
      }
      ctx.stroke()
      
      // Draw points
      dataPoints.forEach(point => {
        ctx.fillStyle = '#0066ff'
        ctx.beginPath()
        ctx.arc(point.x, point.y, 5, 0, Math.PI * 2)
        ctx.fill()
      })
    }
    
    // Add points on click
    canvas.addEventListener('click', (e) => {
      const rect = canvas.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      
      dataPoints.push({ x, y })
      drawGraph()
    })
    
    // Initial draw
    drawGraph()
  </script>
</body>
</html>
```

**Python analogy:**
```python
# Canvas is like matplotlib
import matplotlib.pyplot as plt

data_points = []

def draw_graph():
    plt.clf()  # Clear
    
    if data_points:
        x = [p['x'] for p in data_points]
        y = [p['y'] for p in data_points]
        plt.plot(x, y, 'o-', color='blue')
    
    plt.axhline(0, color='gray')
    plt.axvline(0, color='gray')
    plt.show()

def on_click(event):
    data_points.append({'x': event.xdata, 'y': event.ydata})
    draw_graph()

plt.connect('button_press_event', on_click)
draw_graph()
```

---

## WebSockets: Real-Time Communication

WebSockets enable bidirectional communication between client and server.

### Client Side

```html
<!DOCTYPE html>
<html>
<head>
  <title>Chat App</title>
  <style>
    body {
      font-family: system-ui;
      background: #1a1a1a;
      color: #fff;
      padding: 2rem;
      max-width: 600px;
      margin: 0 auto;
    }
    
    #messages {
      background: #222;
      padding: 1rem;
      border-radius: 8px;
      height: 400px;
      overflow-y: auto;
      margin-bottom: 1rem;
    }
    
    .message {
      padding: 0.5rem;
      margin-bottom: 0.5rem;
      background: #333;
      border-radius: 4px;
    }
    
    .message.own {
      background: #0066ff;
      text-align: right;
    }
    
    .input-group {
      display: flex;
      gap: 0.5rem;
    }
    
    input {
      flex: 1;
      padding: 0.75rem;
      border: 2px solid #333;
      background: #222;
      color: #fff;
      border-radius: 8px;
    }
    
    button {
      padding: 0.75rem 1.5rem;
      background: #0066ff;
      color: #fff;
      border: none;
      border-radius: 8px;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <h1>WebSocket Chat</h1>
  <div id="messages"></div>
  <div class="input-group">
    <input type="text" id="messageInput" placeholder="Type a message...">
    <button id="sendBtn">Send</button>
  </div>
  
  <script>
    class ChatApp {
      constructor() {
        this.ws = new WebSocket('ws://localhost:8000/ws')
        this.setupWebSocket()
        this.attachEventListeners()
      }
      
      setupWebSocket() {
        this.ws.onopen = () => {
          console.log('Connected to chat')
          this.addSystemMessage('Connected')
        }
        
        this.ws.onmessage = (event) => {
          const data = JSON.parse(event.data)
          this.addMessage(data.text, false)
        }
        
        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error)
          this.addSystemMessage('Connection error')
        }
        
        this.ws.onclose = () => {
          console.log('Disconnected')
          this.addSystemMessage('Disconnected')
        }
      }
      
      sendMessage(text) {
        if (this.ws.readyState === WebSocket.OPEN) {
          this.ws.send(JSON.stringify({ text }))
          this.addMessage(text, true)
        }
      }
      
      addMessage(text, isOwn) {
        const messagesEl = document.getElementById('messages')
        const messageEl = document.createElement('div')
        messageEl.className = `message ${isOwn ? 'own' : ''}`
        messageEl.textContent = text
        messagesEl.appendChild(messageEl)
        messagesEl.scrollTop = messagesEl.scrollHeight
      }
      
      addSystemMessage(text) {
        const messagesEl = document.getElementById('messages')
        const messageEl = document.createElement('div')
        messageEl.style.textAlign = 'center'
        messageEl.style.opacity = '0.5'
        messageEl.style.fontSize = '0.875rem'
        messageEl.textContent = `— ${text} —`
        messagesEl.appendChild(messageEl)
      }
      
      attachEventListeners() {
        const sendBtn = document.getElementById('sendBtn')
        const input = document.getElementById('messageInput')
        
        sendBtn.addEventListener('click', () => {
          const text = input.value.trim()
          if (text) {
            this.sendMessage(text)
            input.value = ''
            input.focus()
          }
        })
        
        input.addEventListener('keypress', (e) => {
          if (e.key === 'Enter') {
            sendBtn.click()
          }
        })
      }
    }
    
    const chat = new ChatApp()
  </script>
</body>
</html>
```

**Python backend (FastAPI):**
```python
# server.py
from fastapi import FastAPI, WebSocket
from fastapi.staticfiles import StaticFiles

app = FastAPI()

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(data)
    except:
        manager.disconnect(websocket)
```

---

## Service Workers: Offline Support

Service Workers enable Progressive Web Apps (PWAs) — web apps that work offline.

### Example: Basic Caching

```javascript
// service-worker.js
const CACHE_NAME = 'my-app-v1'
const urlsToCache = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
]

// Install service worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Opened cache')
        return cache.addAll(urlsToCache)
      })
  )
})

// Fetch from cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Cache hit - return response
        if (response) {
          return response
        }
        
        // Clone request
        const fetchRequest = event.request.clone()
        
        return fetch(fetchRequest).then((response) => {
          // Check if valid response
          if (!response || response.status !== 200) {
            return response
          }
          
          // Clone response
          const responseToCache = response.clone()
          
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseToCache)
            })
          
          return response
        })
      })
  )
})

// Clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName)
          }
        })
      )
    })
  )
})
```

**Register service worker:**
```html
<script>
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/service-worker.js')
    .then((registration) => {
      console.log('Service Worker registered:', registration)
    })
    .catch((error) => {
      console.error('Service Worker registration failed:', error)
    })
}
</script>
```

**Python analogy:**
```python
# Service Workers are like Flask caching
from flask import Flask
from flask_caching import Cache

app = Flask(__name__)
cache = Cache(app, config={'CACHE_TYPE': 'simple'})

@app.route('/api/data')
@cache.cached(timeout=300)  # Cache for 5 minutes
def get_data():
    # Expensive operation
    data = fetch_from_database()
    return jsonify(data)

# Service Workers cache in the browser, Flask caches on the server
```

---

## Progressive Web Apps (PWAs)

PWAs are web apps that feel like native apps.

### Features:
1. **Offline support** (Service Workers)
2. **Installable** (Add to home screen)
3. **Fast** (Cached assets)
4. **Responsive** (Works on all devices)
5. **Push notifications**

### manifest.json

```json
{
  "name": "My Todo App",
  "short_name": "Todo",
  "description": "A simple todo list",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1a1a1a",
  "theme_color": "#0066ff",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

**Link in HTML:**
```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0066ff">
<meta name="apple-mobile-web-app-capable" content="yes">
```

---

## Pushing the Browser's Limits

### 1. File System Access API

Read/write local files (with user permission):

```javascript
async function openFile() {
  const [fileHandle] = await window.showOpenFilePicker()
  const file = await fileHandle.getFile()
  const contents = await file.text()
  console.log(contents)
}

async function saveFile() {
  const fileHandle = await window.showSaveFilePicker()
  const writable = await fileHandle.createWritable()
  await writable.write('Hello, world!')
  await writable.close()
}
```

### 2. Web Bluetooth

Connect to Bluetooth devices:

```javascript
async function connectBluetooth() {
  const device = await navigator.bluetooth.requestDevice({
    acceptAllDevices: true,
    optionalServices: ['battery_service']
  })
  
  const server = await device.gatt.connect()
  const service = await server.getPrimaryService('battery_service')
  const characteristic = await service.getCharacteristic('battery_level')
  const value = await characteristic.readValue()
  
  console.log('Battery level:', value.getUint8(0))
}
```

### 3. WebAssembly

Run compiled code (C, Rust) in the browser:

```javascript
// Load WASM module
const response = await fetch('module.wasm')
const buffer = await response.arrayBuffer()
const module = await WebAssembly.instantiate(buffer)

// Call exported function
const result = module.instance.exports.add(5, 3)
console.log(result)  // 8
```

### 4. Web Workers (Background Threads)

Run JavaScript in background threads:

```javascript
// worker.js
self.addEventListener('message', (e) => {
  const result = expensiveCalculation(e.data)
  self.postMessage(result)
})

// main.js
const worker = new Worker('worker.js')

worker.postMessage({ data: largeDataset })

worker.addEventListener('message', (e) => {
  console.log('Result:', e.data)
})
```

**Python analogy:**
```python
# Web Workers are like multiprocessing
from multiprocessing import Process, Queue

def expensive_calculation(data, queue):
    result = process(data)
    queue.put(result)

queue = Queue()
process = Process(target=expensive_calculation, args=(large_dataset, queue))
process.start()

result = queue.get()  # Wait for result
process.join()
```

---

## When to Use What

| Tool | Use Case | Example |
|------|----------|---------|
| **Vanilla JS** | Simple interactivity | Form validation, tooltips |
| **Web Components** | Reusable widgets | Custom buttons, date pickers |
| **Canvas** | Graphics/games | Charts, diagrams, games |
| **WebSockets** | Real-time | Chat, live updates, multiplayer |
| **Service Workers** | Offline apps | PWAs, cached content |
| **Web Workers** | Heavy computation | Image processing, data analysis |
| **WebAssembly** | Performance-critical | Video editing, 3D rendering |
| **React/Vue** | Complex apps | Dashboards, admin panels |

---

## Complete Example: Weather App (No Framework)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Weather App</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: system-ui, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 1rem;
    }
    
    .container {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 20px;
      padding: 2rem;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    }
    
    h1 {
      margin-bottom: 1rem;
      color: #333;
    }
    
    .search-box {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 2rem;
    }
    
    input {
      flex: 1;
      padding: 0.75rem;
      border: 2px solid #ddd;
      border-radius: 10px;
      font-size: 1rem;
    }
    
    button {
      padding: 0.75rem 1.5rem;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      font-size: 1rem;
      font-weight: 500;
    }
    
    button:hover {
      background: #5568d3;
    }
    
    .weather-info {
      text-align: center;
    }
    
    .temp {
      font-size: 4rem;
      font-weight: 700;
      color: #667eea;
      margin: 1rem 0;
    }
    
    .description {
      font-size: 1.5rem;
      color: #666;
      margin-bottom: 1rem;
    }
    
    .details {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
      margin-top: 1.5rem;
    }
    
    .detail-item {
      background: #f5f5f5;
      padding: 1rem;
      border-radius: 10px;
    }
    
    .detail-label {
      font-size: 0.875rem;
      color: #999;
      margin-bottom: 0.25rem;
    }
    
    .detail-value {
      font-size: 1.25rem;
      font-weight: 600;
      color: #333;
    }
    
    .error {
      background: #ff3b30;
      color: white;
      padding: 1rem;
      border-radius: 10px;
      margin-top: 1rem;
    }
    
    .loading {
      text-align: center;
      padding: 2rem;
      color: #999;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Weather App</h1>
    
    <div class="search-box">
      <input 
        type="text" 
        id="cityInput" 
        placeholder="Enter city name..."
        value="San Francisco"
      >
      <button id="searchBtn">Search</button>
    </div>
    
    <div id="weatherDisplay"></div>
  </div>
  
  <script>
    class WeatherApp {
      constructor() {
        this.apiKey = 'YOUR_API_KEY'  // Get free key from openweathermap.org
        this.displayEl = document.getElementById('weatherDisplay')
        this.attachEventListeners()
        this.loadWeather('San Francisco')
      }
      
      attachEventListeners() {
        const btn = document.getElementById('searchBtn')
        const input = document.getElementById('cityInput')
        
        btn.addEventListener('click', () => {
          const city = input.value.trim()
          if (city) this.loadWeather(city)
        })
        
        input.addEventListener('keypress', (e) => {
          if (e.key === 'Enter') btn.click()
        })
      }
      
      async loadWeather(city) {
        this.showLoading()
        
        try {
          const response = await fetch(
            `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${this.apiKey}&units=imperial`
          )
          
          if (!response.ok) {
            throw new Error('City not found')
          }
          
          const data = await response.json()
          this.displayWeather(data)
        } catch (error) {
          this.showError(error.message)
        }
      }
      
      showLoading() {
        this.displayEl.innerHTML = '<div class="loading">Loading...</div>'
      }
      
      displayWeather(data) {
        this.displayEl.innerHTML = `
          <div class="weather-info">
            <h2>${data.name}, ${data.sys.country}</h2>
            <div class="temp">${Math.round(data.main.temp)}°F</div>
            <div class="description">${data.weather[0].description}</div>
            
            <div class="details">
              <div class="detail-item">
                <div class="detail-label">Feels Like</div>
                <div class="detail-value">${Math.round(data.main.feels_like)}°F</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Humidity</div>
                <div class="detail-value">${data.main.humidity}%</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Wind Speed</div>
                <div class="detail-value">${Math.round(data.wind.speed)} mph</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Pressure</div>
                <div class="detail-value">${data.main.pressure} hPa</div>
              </div>
            </div>
          </div>
        `
      }
      
      showError(message) {
        this.displayEl.innerHTML = `
          <div class="error">${message}</div>
        `
      }
    }
    
    const app = new WeatherApp()
  </script>
</body>
</html>
```

---

## Summary

**You don't always need React:**
- Small tools work great with vanilla JS
- Progressive enhancement lets you start simple
- Modern browser APIs are powerful

**Key browser APIs:**
- **Canvas:** Drawing graphics
- **WebSockets:** Real-time communication
- **Service Workers:** Offline support, PWAs
- **Web Components:** Reusable custom elements
- **Web Workers:** Background processing
- **WebAssembly:** High-performance computation

**When to use vanilla JS:**
- Single-purpose tools
- Widgets embedded in other sites
- Learning fundamentals
- Performance-critical apps

**When to use frameworks:**
- Large, complex applications
- Multiple interconnected views
- Team collaboration
- Rich ecosystems (routing, state, testing)

**Next steps:** Build a small tool without a framework. You'll appreciate what frameworks do, and you'll write better code in them.

---

## Practice Projects

1. **Pomodoro Timer** — 25-minute timer with breaks
2. **Calculator** — Basic arithmetic with history
3. **Color Picker** — Interactive color selector with Canvas
4. **Markdown Previewer** — Type markdown, see HTML preview
5. **Local Storage Manager** — View/edit localStorage
6. **Chat Client** — WebSocket-based chat
7. **Offline Notes** — PWA with Service Worker

Each of these can be built in a single HTML file. No build step, no dependencies.
