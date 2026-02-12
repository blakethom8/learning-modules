# The LLM Frontend Workflow

## Table of Contents
- [The Prompt-to-UI Pipeline](#the-prompt-to-ui-pipeline)
- [Single-File HTML Apps](#single-file-html-apps)
- [Multi-File React Apps](#multi-file-react-apps)
- [The Review Cycle](#the-review-cycle)
- [Common Failure Modes](#common-failure-modes)
- [Effective Prompting Patterns](#effective-prompting-patterns)
- [Real Example: Provider Search](#real-example-provider-search)

## The Prompt-to-UI Pipeline

The LLM frontend workflow is fundamentally different from traditional development:

```
Traditional:  Spec → Design → Code → Test → Debug → Deploy
LLM-Assisted: Describe → Generate → Render → Review → Refine → Ship
```

### The Five Steps

**1. Describe** — Write a clear, detailed prompt
```
"Create a user profile card with avatar, name, bio, and social links.
Use Tailwind CSS, make it responsive, add hover effects."
```

**2. Generate** — LLM produces code
```bash
claude -p "Create a user profile card..."
# or
codex exec "Create a user profile card..."
```

**3. Render** — View it in the browser
```bash
# Save to file and open
pbpaste > profile-card.html && open profile-card.html
```

**4. Review** — Check what works, what doesn't
- Does it match your intent?
- Are there bugs or missing features?
- Is the code understandable?

**5. Refine** — Iterate with follow-up prompts
```
"Add a 'Follow' button that changes to 'Following' on click"
"Make the bio text truncate after 3 lines"
"Add a verified badge icon next to the name"
```

**This cycle takes minutes, not hours.**

## Single-File HTML Apps

Single-file HTML is the **fastest feedback loop** for LLM frontend work.

### Why Single-File?

✅ **No build tools** — just open the file in a browser  
✅ **No dependencies** — everything is self-contained  
✅ **Instant iteration** — edit, save, refresh  
✅ **Easy sharing** — one file, anyone can open it  
✅ **Perfect for prototypes** — fast, disposable, focused  

### Anatomy of a Single-File HTML App

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My App</title>
    
    <!-- CSS via CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Optional: Add Alpine.js for reactivity -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-900 text-white p-8">
    
    <!-- HTML structure -->
    <div class="max-w-4xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">Dashboard</h1>
        <!-- Your content here -->
    </div>
    
    <!-- JavaScript -->
    <script>
        // Your logic here
        fetch('https://api.example.com/data')
            .then(r => r.json())
            .then(data => console.log(data));
    </script>
    
</body>
</html>
```

### Single-File is the "Hello World" of LLM Frontend

When prompting LLMs for frontend code, **start with single-file HTML**:

- It forces the LLM to be self-contained
- You can test immediately
- Easier to review (one file vs scattered components)
- CDN imports = no npm, no bundlers

Once it works, you can extract components into a proper React app.

## Multi-File React Apps

Graduate to multi-file React when:

✅ The prototype is validated and needs production polish  
✅ You need proper component boundaries and reusability  
✅ State management gets complex  
✅ You're integrating with an existing React codebase  
✅ You need TypeScript, testing, or build optimization  

### The Graduation Path

**Single-File Prototype → React Component**

1. Build a working single-file HTML prototype
2. Extract the core logic and structure
3. Prompt: "Convert this HTML to a React component with TypeScript"
4. Integrate into your app
5. Add tests, proper state management, error handling

**Example Prompt for Conversion:**

```
I have this working single-file HTML dashboard. Convert it to a 
React component with TypeScript. Use useState for state, props for 
configuration, and Tailwind for styling. Keep the same visual design.

[paste your single-file HTML]
```

The LLM will generate proper React code with imports, props, types, and hooks.

## The Review Cycle

**Critical skill: reviewing generated code quickly and effectively.**

### What to Check (in order of importance)

**1. Does it work?**
- Open it in the browser
- Click all the buttons
- Try different screen sizes
- Check the console for errors

**2. Does it match your intent?**
- Visual design close enough?
- Behavior as expected?
- Missing features?

**3. Is the code reasonable?**
- Readable structure?
- Sensible naming?
- Any obvious code smells?

**4. Security issues?**
- User input sanitized?
- API keys hardcoded? (common LLM mistake)
- XSS vulnerabilities?

**5. Performance concerns?**
- Unnecessary re-renders?
- Blocking operations?
- Large data handled efficiently?

### Review Speed: 80/20 Rule

Spend **80% of review time on functionality and intent-match**, 20% on code quality.

If it works and matches your needs, ship it. Refactor later if needed.

## Common Failure Modes

LLMs are powerful but predictable in their mistakes:

### 1. Hallucinated CSS Classes

**Problem:** Inventing Tailwind classes that don't exist

```html
<!-- LLM might generate: -->
<div class="bg-purple-850 shadow-ultra rounded-large">
```

**Fix:** Check Tailwind docs or ask LLM to use only standard classes

### 2. Invented API Methods

**Problem:** Using framework methods that don't exist

```javascript
// LLM might generate:
this.setState.merge({ user: data }); // React doesn't have .merge
```

**Fix:** Test the code, catch the error, ask LLM to fix it

### 3. Broken State Logic

**Problem:** State updates that don't work as expected

```javascript
// Common mistake:
const [items, setItems] = useState([]);
items.push(newItem); // Doesn't trigger re-render!
```

**Fix:** Prompt for proper immutable updates or review state code carefully

### 4. Missing Error Handling

**Problem:** No loading states, error states, or empty states

```javascript
// Generated code often looks like:
fetch('/api/data')
    .then(r => r.json())
    .then(data => setData(data));
// No error handling, no loading state
```

**Fix:** Add follow-up prompts: "Add loading and error states"

### 5. Hardcoded Data

**Problem:** LLM uses placeholder data instead of real API calls

```javascript
// You asked for a dashboard, you get:
const data = [
    { id: 1, name: "John Doe", revenue: 42000 },
    { id: 2, name: "Jane Smith", revenue: 38000 }
];
```

**Fix:** Be explicit: "Fetch data from /api/analytics endpoint"

### 6. Inline Styles Instead of Classes

**Problem:** Using style={{}} instead of Tailwind classes

```jsx
<div style={{ padding: '20px', backgroundColor: '#1a1a1a' }}>
```

**Fix:** Prompt: "Use Tailwind classes, not inline styles"

## Effective Prompting Patterns

### Pattern 1: Structural Prompts

**Define the layout clearly:**

```
Create a dashboard with:
- Header: logo on left, user menu on right
- Sidebar: navigation links (Dashboard, Analytics, Settings)
- Main content: 3 metric cards in a row, chart below
- Footer: copyright text

Use Tailwind CSS, dark theme, responsive design.
```

### Pattern 2: Behavioral Prompts

**Describe interactions:**

```
When the user clicks "Load More", fetch the next page from 
/api/posts?page=X and append results to the list. Show a loading 
spinner while fetching. If there are no more results, hide the button.
```

### Pattern 3: Style Prompts

**Reference visual styles:**

```
Create a pricing card similar to Stripe's pricing page:
- Large centered price
- Feature list with checkmarks
- Primary CTA button at bottom
- Subtle shadow and border
- Hover effect that lifts the card slightly

Use purple accent color (#7c3aed).
```

### Pattern 4: Reference-Based Prompts

**Point to existing code:**

```
Look at this SearchResults component. Create a similar 
ProviderCard component that shows:
- Provider name and specialty
- Rating stars
- Location with map icon
- "View Profile" button

Keep the same styling and layout patterns.

[paste SearchResults code]
```

### Pattern 5: Iterative Refinement

**Start simple, layer on features:**

```
1st prompt: "Create a data table with name, email, role columns"
2nd prompt: "Add sort functionality to each column"
3rd prompt: "Add a search box that filters rows"
4th prompt: "Add pagination (10 rows per page)"
5th prompt: "Add an 'Export to CSV' button"
```

Each step is small and testable. If something breaks, you know which change caused it.

## Real Example: Provider Search

Here's how components in the Provider Search app were built with AI assistance:

### 1. Map View Component

**Initial prompt to Claude Code:**

```
Create a React component that displays a map using Leaflet with:
- Provider locations as markers
- Popup showing provider name, specialty, rating when clicked
- Current location button to center map on user
- Zoom controls
- Dark theme to match our app

Use TypeScript, accept providers array as props.
```

**Result:** Working map component in ~2 minutes

**Follow-ups:**
- "Add clustering for markers when zoomed out"
- "Color-code markers by provider specialty"
- "Add a 'List View' toggle button"

### 2. Search Results Card

**Initial prompt:**

```
Create a ProviderCard component showing:
- Provider photo (circular avatar)
- Name and credentials
- Specialty badges
- Rating stars (gold) with review count
- Location with distance
- "View Profile" and "Book Appointment" buttons

Use Tailwind, match the dark theme, make it responsive.
```

**Result:** Beautiful card component

**Follow-ups:**
- "Add a 'Save' heart icon button in top-right"
- "Show 'Accepting New Patients' badge if applicable"
- "Add hover effect that lifts the card"

### 3. Kanban Board (for admin)

**Initial prompt:**

```
Create a kanban board with 3 columns: Pending, In Progress, Complete.
Each card shows request ID, requester name, date.
Drag cards between columns to update status.
Use React Beautiful DND library for drag-and-drop.
Dark theme, Tailwind styling.
```

**Result:** Working kanban board with drag-and-drop

**The workflow in each case:**
1. Describe what we wanted (1 minute)
2. Review generated code (2-3 minutes)
3. Test in browser (1 minute)
4. Iterate with 2-3 follow-up prompts (5 minutes)

**Total time per component: ~10 minutes** from idea to working code.

Compare to manual implementation: 1-2 hours per component for someone experienced, longer for a beginner.

## The Feedback Loop

The faster your feedback loop, the more you can iterate:

| Approach | Feedback Time | Best For |
|----------|---------------|----------|
| **Single-file HTML** | 5 seconds | Prototypes, internal tools |
| **React dev server** | 10-30 seconds | Production development |
| **Full build + deploy** | 1-5 minutes | Final testing |

**Optimize for the fastest loop that matches your needs.**

For exploration and prototyping: single-file HTML wins every time.

## Key Takeaways

1. **The LLM workflow is describe → generate → review → refine**
2. **Single-file HTML apps = fastest feedback loop**
3. **Graduate to React when the prototype is validated**
4. **Review for functionality first, code quality second**
5. **LLMs make predictable mistakes — learn to spot them**
6. **Effective prompts are structural, behavioral, and style-focused**
7. **Iterate in small steps — easier to debug, faster to ship**

---

**Try This Now:**

Build a single-file HTML app with an LLM:

```bash
claude "Create a single-file HTML weather app. Show city name input, 
search button, and display temperature, conditions, and 5-day forecast 
below. Use Tailwind CSS dark theme. Add placeholder data for now 
(don't call a real API yet)."
```

Save it, open it, see how fast you can go from idea to working UI.

Then try: "Now connect it to the OpenWeatherMap API using fetch()"

→ Next: [Command-Line Frontend Tools](02-command-line-frontend-tools.md)
