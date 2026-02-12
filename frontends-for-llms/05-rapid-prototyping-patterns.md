# Rapid Prototyping Patterns

## Table of Contents
- [The 10-Minute Prototype](#the-10-minute-prototype)
- [Pattern 1: API-First](#pattern-1-api-first)
- [Pattern 2: Mock-First](#pattern-2-mock-first)
- [Pattern 3: Clone-and-Modify](#pattern-3-clone-and-modify)
- [Pattern 4: Component Library](#pattern-4-component-library)
- [Building Internal Tools Fast](#building-internal-tools-fast)
- [Building Customer Prototypes](#building-customer-prototypes)
- [Real Workflow: Provider Search](#real-workflow-provider-search)
- [The Handoff: Prototype to Production](#the-handoff-prototype-to-production)

## The 10-Minute Prototype

**Goal:** From idea to working UI in 10 minutes or less.

### The Recipe

**Minutes 0-2: Define**
- What does it need to show?
- What can users do with it?
- What's the MVP feature set?

**Minutes 2-4: Prompt**
- Write a clear, detailed prompt
- Include structure, behavior, style
- Specify single-file HTML for speed

**Minutes 4-6: Generate**
- Run through Claude Code or Codex
- Save output to file

**Minutes 6-10: Test & Refine**
- Open in browser
- Click around, test interactions
- One round of refinement prompts

**Result:** Working prototype you can show to someone.

### Example: 10-Minute Analytics Dashboard

**00:00 - Define:**
- Show 3 metrics: Revenue, Users, Conversion
- Show a chart of revenue over time
- Fetch from mock data (hardcoded for now)

**02:00 - Prompt:**
```bash
claude -p "Create a single-file HTML analytics dashboard with:
- 3 metric cards: Revenue ($42,150), Users (1,243), Conversion (3.4%)
- Below: line chart showing revenue over last 7 days
- Use Tailwind CSS dark theme, Chart.js via CDN
- Hardcode data for now"
```

**04:00 - Generate:**
```bash
claude -p "..." > analytics-dashboard.html
```

**06:00 - Test:**
```bash
open analytics-dashboard.html
```

**08:00 - Refine:**
```bash
claude -p "Add a date range selector at the top (buttons: 7d, 30d, 90d) 
that updates the chart data"
```

**10:00 - Done.**

You now have a working dashboard to show your team.

## Pattern 1: API-First

**Build the backend endpoint first, then generate frontend to consume it.**

### When to Use

✅ Backend logic is complex  
✅ You know the data structure  
✅ API can be tested independently  
✅ Frontend is mostly display/interaction  

### Workflow

**Step 1: Build API endpoint**
```python
# backend/api.py
@app.get("/api/providers")
def get_providers(specialty: str = None, radius: int = 10):
    # Query database, return JSON
    return {"providers": [...]}
```

**Step 2: Test API**
```bash
curl "http://localhost:8000/api/providers?specialty=cardiology"
```

**Step 3: Generate frontend**
```bash
claude -p "Create a React component that fetches from 
/api/providers?specialty=X&radius=Y and displays results 
in a grid. Each card shows name, specialty, rating, location.
Use Tailwind CSS dark theme."
```

**Step 4: Wire it up**
```bash
# Save component
claude -p "..." > src/components/ProviderGrid.tsx

# Import and use in your app
```

**Benefit:** Backend and frontend development decoupled. Backend can be production-ready while frontend is still prototype quality.

### Example: Search Results

**API:**
```bash
GET /api/search?q=therapy&location=94110
→ { results: [{ name, specialty, rating, distance, ... }] }
```

**Frontend prompt:**
```
Create a SearchResults component that:
- Accepts searchQuery and location props
- Fetches from /api/search?q={searchQuery}&location={location}
- Displays results in a grid of cards
- Each card: provider photo, name, specialty, rating, distance
- Show loading spinner while fetching
- Show "No results" if empty
Use React + TypeScript + Tailwind
```

**Result:** API-driven UI that adapts to your backend structure.

## Pattern 2: Mock-First

**Build UI with hardcoded data first, connect to real API later.**

### When to Use

✅ Backend isn't ready yet  
✅ You want to validate UX before building backend  
✅ You're prototyping multiple design options  
✅ You want fast iteration without API delays  

### Workflow

**Step 1: Generate with mock data**
```bash
claude -p "Create a provider search results page with mock data.
Show 6 provider cards in a grid. Each card has:
- Photo (use placeholder: https://i.pravatar.cc/150?img=X)
- Name, specialty, rating (4.5 stars), distance (1.2 mi)
- 'View Profile' button

Hardcode the data array. Use Tailwind CSS dark theme."
```

**Step 2: Validate UX**
- Show to stakeholders
- Get feedback on layout, colors, interactions
- Iterate on design without backend dependency

**Step 3: Connect real API**
```bash
claude -p "Update this component to fetch data from /api/providers 
instead of using hardcoded data. Keep everything else the same."
```

**Benefit:** Design and UX decisions made independently of backend. API contract can change without breaking the prototype.

### Example: Dashboard Mockup

**Prompt:**
```
Create a dashboard mockup with hardcoded data:
- 4 metric cards: Revenue ($52,340), Users (3,421), Conversion (4.2%), Churn (1.8%)
- Revenue trend chart (last 30 days, trending up)
- Recent activity feed: 5 items with avatar, name, action, timestamp

Use realistic placeholder data. Tailwind dark theme. Single-file HTML.
```

**Use case:** Show this to your CEO to validate the dashboard idea before building the real thing.

## Pattern 3: Clone-and-Modify

**Screenshot an existing UI, ask LLM to recreate it, then customize.**

### When to Use

✅ You see a design you like (competitor, inspiration)  
✅ You want to recreate a look/feel quickly  
✅ You're not a designer but know what you like  
✅ You want to rapidly test different visual styles  

### Workflow

**Step 1: Find inspiration**
- Screenshot a UI you like (Stripe, Linear, Notion, etc.)

**Step 2: Describe it**
```
I want to recreate the Stripe dashboard layout:
- Top navigation: logo left, tabs center, user menu right
- Main content: 4 metric cards in a row (white bg, subtle shadow)
- Below: large revenue chart with gradient fill
- Color scheme: light gray background, blue accents
- Typography: Clean, modern sans-serif
```

**Step 3: Generate clone**
```bash
claude -p "Create a single-file HTML dashboard that looks like 
Stripe's dashboard. [paste description]"
```

**Step 4: Modify for your needs**
```bash
claude -p "Change the metrics to: MRR, Active Users, Churn Rate, LTV.
Change the accent color from blue to purple."
```

**Benefit:** Designers spend years perfecting UIs. You can clone their work in minutes, then customize.

### Example: Recreating Linear's Task View

**Prompt:**
```
Create a task management UI similar to Linear:
- Left sidebar: project list with icons
- Main area: table view of tasks
- Each row: checkbox, priority icon, task title, assignee avatar, status tag
- Top bar: search, filters, "New Task" button
- Color scheme: dark gray background, subtle borders, purple accents
- Clean, minimal design

Use single-file HTML + Tailwind + Alpine.js
```

**Result:** Linear-inspired task manager in 5 minutes.

## Pattern 4: Component Library

**Build a set of reusable components, then compose them into pages.**

### When to Use

✅ Building multiple pages/features  
✅ Want consistent design across app  
✅ Planning to reuse patterns often  
✅ Working with a team (shared components)  

### Workflow

**Step 1: Generate base components**
```bash
# Button component
claude -p "Create a Button component with variants: primary, 
secondary, outline, ghost. TypeScript + Tailwind" > Button.tsx

# Card component
claude -p "Create a Card component with header, body, footer sections.
TypeScript + Tailwind" > Card.tsx

# Input component
claude -p "Create an Input component with label, error message, 
help text. TypeScript + Tailwind" > Input.tsx
```

**Step 2: Build page using components**
```bash
claude -p "Create a LoginPage using these components:
- Card (contains form)
- Input (for email and password)
- Button (submit button)
[paste Button.tsx and Input.tsx]

Style: dark theme, centered on page"
```

**Step 3: Extend library as needed**
```bash
# Need a new component? Generate it
claude -p "Create a Modal component that matches the style 
of our existing Card component [paste Card.tsx]"
```

**Benefit:** Consistency by default. New pages/features built faster because components already exist.

### Example: Provider Search Component Library

**Components:**
- `ProviderCard` — displays provider info
- `SearchBar` — search input with filters
- `MapView` — Leaflet map with markers
- `StarRating` — displays rating stars
- `Button` — consistent button styles
- `Badge` — specialty/status badges

**Building a new page:**
```bash
claude -p "Create a ProviderProfilePage using:
- ProviderCard for header info
- StarRating for reviews
- Button for 'Book Appointment'
- Badge for specialties

[paste relevant component code]

Layout: centered, max-width, dark theme"
```

**Result:** New page in minutes, guaranteed visual consistency.

## Building Internal Tools Fast

**Internal tools don't need polish — they need speed.**

### The Internal Tool Recipe

1. **Single-file HTML** (no build process)
2. **Mock data first** (iterate on UI)
3. **Connect API later** (when backend ready)
4. **Dark theme** (easier on eyes for devs)
5. **Zero styling beyond Tailwind** (no custom CSS)

### Example Internal Tools

**1. API Tester**
```bash
claude -p "Create an API testing tool (single-file HTML):
- Input: URL, method (GET/POST), headers, body
- Button: Send Request
- Output: response JSON, status code, timing
Dark theme, Tailwind, Alpine.js"
```

**Use case:** Test backend endpoints without Postman.

**2. Database Query Tool**
```bash
claude -p "Create a SQL query runner (single-file HTML):
- Textarea for SQL query
- Button: Run Query
- Table showing results
- Export to CSV button
Mock results for now. Dark theme."
```

**Use case:** Let non-technical team query database.

**3. Log Viewer**
```bash
claude -p "Create a log viewer (single-file HTML):
- Fetch logs from /api/logs
- Display in scrollable list
- Filter by log level (info, warn, error)
- Search box to filter messages
- Auto-refresh every 5 seconds
Dark theme, monospace font for logs"
```

**Use case:** Monitor production logs without SSH.

**4. Feature Flag Dashboard**
```bash
claude -p "Create a feature flag admin panel:
- List all flags with name, description, enabled/disabled toggle
- Toggle sends PATCH to /api/flags/{id}
- Search/filter flags
- Show last modified date and user
Single-file HTML, dark theme"
```

**Use case:** Non-devs can toggle features.

**Time to build each: 10-15 minutes.**

## Building Customer Prototypes

**Customer-facing prototypes need more polish but still prioritize speed.**

### The Customer Prototype Recipe

1. **Mock-first** (validate UX before backend)
2. **React + Tailwind** (easier to convert to production)
3. **Realistic data** (use realistic names, photos, numbers)
4. **Interactive** (show key user flows)
5. **Responsive** (test on mobile)

### Example: Provider Search MVP

**Phase 1: Static Prototype**
```bash
claude -p "Create a provider search page with:
- Search bar: location input, specialty dropdown, search button
- Results: grid of 6 provider cards (hardcoded)
- Each card: photo, name, specialty, rating, distance, 'View Profile' button
Realistic mock data. React + Tailwind, dark theme, responsive."
```

**Phase 2: Add Interactivity**
```bash
claude -p "Add search functionality:
- When user types in search, filter hardcoded results
- When user clicks 'View Profile', navigate to /provider/{id}
Keep existing styling."
```

**Phase 3: Add Real Data**
```bash
claude -p "Connect to API:
- Fetch from /api/search?location=X&specialty=Y
- Show loading spinner while fetching
- Handle empty results
Keep everything else the same."
```

**Result:** Validated UX → working prototype → production-ready feature.

### Prototype Feedback Loop

```
Build prototype (1 day)
↓
Show to 5 customers (2 days)
↓
Collect feedback
↓
Iterate on design (1 day)
↓
Validate changes (1 day)
↓
Build production version (3 days)
```

**Total: 8 days from idea to production**, vs 4-6 weeks traditional.

## Real Workflow: Provider Search

**How we actually built features with LLM assistance:**

### Feature: Map View

**Day 1: Prototype**
```bash
# Generate map with hardcoded markers
claude -p "Create a map component with Leaflet showing 10 provider 
locations in San Francisco. Click marker to show popup with name and 
specialty. Single-file HTML for testing."

# Save and test
> map-prototype.html
open map-prototype.html
```

**Day 2: React Component**
```bash
# Convert to React
claude -p "Convert this map to a React + TypeScript component.
Accept providers array as prop. Use Leaflet React wrapper.
[paste map-prototype.html]"

> src/components/MapView.tsx
```

**Day 3: Polish**
```bash
# Add features
claude -p "Add to MapView component:
- Clustering when zoomed out
- Current location button
- Filter markers by specialty
- Dark theme to match app"
```

**Day 4: Integration**
```bash
# Integrate into app
import MapView from './components/MapView';
<MapView providers={searchResults} />
```

**Total time: 4 days.** Traditional approach: 2-3 weeks.

### Feature: Search Results Cards

**Iteration 1: Basic Card**
```bash
claude -p "Create a ProviderCard component:
- Props: name, specialty, rating, distance, imageUrl
- Layout: horizontal, image left, info middle, button right
- React + TypeScript + Tailwind dark theme"
```

**Iteration 2: Add Features**
```bash
claude -p "Add to ProviderCard:
- Star rating display (convert 4.5 to 5 stars, 4.5 filled)
- 'Accepting New Patients' badge if acceptingPatients prop is true
- Heart icon 'Save' button in top-right
- Hover effect: lift card slightly"
```

**Iteration 3: Polish**
```bash
claude -p "Make ProviderCard mobile-responsive:
- Stack vertically on screens <768px
- Image smaller on mobile
- Button full-width on mobile"
```

**Total time: 2 hours.** Traditional: 1-2 days.

### Feature: Kanban Board (Admin)

**Prototype (single-file HTML):**
```bash
claude -p "Create a kanban board with 3 columns: Pending, In Progress, Done.
Hardcode 5 cards in each column. Each card: title, assigned user, date.
Drag cards between columns. Use Alpine.js for drag-drop.
Single-file HTML, dark theme."
```

**Production (React):**
```bash
claude -p "Convert this kanban board to React with:
- React Beautiful DnD library for drag-drop
- Save column changes to backend via PATCH /api/requests/{id}
- TypeScript types for Request
[paste prototype code]"
```

**Total time: 1 day.** Traditional: 1 week.

## The Handoff: Prototype to Production

**Not all prototypes become production code. Know when to rebuild vs refine.**

### When to Refine Prototype

✅ **Code is reasonable** — readable, not too hacky  
✅ **Architecture is sound** — component boundaries make sense  
✅ **Functionality is complete** — just needs polish  
✅ **Time is tight** — shipping fast matters  

**Refinement process:**
1. Add proper TypeScript types
2. Add error handling and loading states
3. Add tests
4. Extract hardcoded values to config
5. Add accessibility (ARIA labels, keyboard nav)
6. Performance optimization if needed

### When to Rebuild

❌ **Code is messy** — spaghetti logic, poor structure  
❌ **Wrong architecture** — state management is broken  
❌ **Missing foundations** — no error handling, no types  
❌ **Prototype hacks** — quick fixes that won't scale  

**Rebuild process:**
1. Keep the visual design (CSS)
2. Rewrite the logic properly
3. Use the prototype as a spec ("make it work like this")
4. Add proper state management, types, tests from the start

### The 80/20 Decision

**If the prototype is 80% there, refine it.**  
**If it's <50% there, rebuild it.**

**Provider Search rule:** Most LLM-generated components were refined, not rebuilt. The code quality from Claude/GPT is good enough for production with polish.

## Key Takeaways

1. **10-minute prototypes are possible** with single-file HTML + mock data
2. **API-first**: Build backend, then generate frontend
3. **Mock-first**: Build frontend, connect API later
4. **Clone-and-modify**: Recreate designs you like, then customize
5. **Component library**: Build reusable pieces, compose into pages
6. **Internal tools**: Prioritize speed over polish
7. **Customer prototypes**: Validate UX before building production
8. **Prototype → production**: Refine good code, rebuild messy code

---

**Try This Now:**

Pick one of these to build in the next 10 minutes:

1. **API Tester** — single-file HTML tool to test HTTP endpoints
2. **CSV Viewer** — upload CSV, display as sortable table
3. **Color Palette Generator** — input base color, generate palette
4. **Markdown Previewer** — split view: editor left, preview right

Set a timer. See how far you get in 10 minutes.

→ Next: [The Skills You Still Need](06-the-skills-you-still-need.md)
