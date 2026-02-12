# The Skills You Still Need

## Table of Contents
- [What LLMs Can't Do Well (Yet)](#what-llms-cant-do-well-yet)
- [Reading Generated Code](#reading-generated-code)
- [Debugging](#debugging)
- [Architecture Decisions](#architecture-decisions)
- [Security](#security)
- [Testing](#testing)
- [The 80/20 Rule](#the-8020-rule)
- [Building Your Code Reading Skill](#building-your-code-reading-skill)
- [The Recommended Learning Path](#the-recommended-learning-path)

## What LLMs Can't Do Well (Yet)

LLMs are powerful but have clear limitations for frontend development:

### 1. Complex State Management

**What LLMs struggle with:**
- Multi-component state coordination
- Complex user flows with many steps
- Real-time state synchronization
- State machines and orchestration

**Example problem:**

You ask for: "Multi-step wizard with form validation, where each step depends on previous step's data, with ability to go back and edit, and save draft to backend"

LLM will generate: A working wizard, but with naive state management that breaks when you go back, loses data on refresh, or has race conditions.

**What you need:**
- Understanding of state management patterns (Context, Redux, Zustand)
- Ability to read generated code and spot state bugs
- Knowledge of when to use local vs global state

### 2. Performance Optimization

**What LLMs struggle with:**
- Rendering optimization (React.memo, useMemo)
- Virtual scrolling for large lists
- Code splitting and lazy loading
- Image optimization
- Bundle size optimization

**Example:**

LLM will generate a table that renders 10,000 rows directly into the DOM. It works... but scrolling is janky.

**What you need:**
- Understanding of browser rendering pipeline
- Knowledge of virtualization libraries (react-window, react-virtual)
- Ability to profile and identify performance bottlenecks

### 3. Accessibility (a11y)

**What LLMs struggle with:**
- Semantic HTML
- ARIA labels and roles
- Keyboard navigation
- Screen reader compatibility
- Focus management

**Example:**

LLM generates a beautiful modal, but:
- No focus trap (tab key escapes modal)
- No aria-labelledby or aria-describedby
- Escape key doesn't close it
- Screen reader doesn't announce it

**What you need:**
- Basic accessibility guidelines (WCAG)
- Testing with keyboard-only navigation
- Testing with screen readers (VoiceOver, NVDA)

### 4. Edge Cases

**What LLMs struggle with:**
- Empty states ("No data available")
- Loading states (spinners, skeletons)
- Error states (retry, fallback)
- Network issues (timeout, offline)
- Unusual user inputs

**Example:**

LLM generates a search component that works great... until:
- User searches with no results → blank screen
- API is slow → no loading indicator
- API fails → cryptic error in console
- User types invalid characters → app crashes

**What you need:**
- Defensive coding mindset
- Testing edge cases manually
- Adding proper state handling for loading/error/empty

### 5. Architecture

**What LLMs struggle with:**
- Deciding component boundaries
- Choosing abstraction levels
- Planning for future changes
- Balancing flexibility and simplicity

**Example:**

You ask for several related components. LLM generates each one separately with duplicated logic, inconsistent patterns, and tight coupling.

**What you need:**
- Software design principles (DRY, SOLID, YAGNI)
- Ability to refactor and extract common patterns
- Long-term thinking about maintainability

### 6. Security

**What LLMs struggle with:**
- XSS prevention (sanitizing user input)
- CSRF protection
- Secure authentication flows
- Data leakage through logs/errors
- Dependency vulnerabilities

**Example:**

LLM generates a comment component that displays user input directly:

```jsx
<div dangerouslySetInnerHTML={{ __html: userComment }} />
```

Result: XSS vulnerability. Malicious user can inject `<script>` tags.

**What you need:**
- Basic web security knowledge (OWASP Top 10)
- Input sanitization and validation
- Understanding authentication and authorization

## Reading Generated Code

**Critical skill:** You must understand what the LLM built.

### Why Code Reading Matters

- **Debugging:** You can't fix what you don't understand
- **Maintenance:** You'll need to modify it later
- **Learning:** Generated code is a learning resource
- **Trust:** Blindly using code you don't understand is risky

### How to Read Generated Code Quickly

**1. Start with structure:**
- What components exist?
- How are they organized?
- What are the main sections?

**2. Follow the data flow:**
- Where does data come from? (props, state, API)
- How does it move through components?
- What triggers updates?

**3. Identify key functions:**
- What are the main operations? (fetch data, submit form, update state)
- What do they do?
- When are they called?

**4. Check for patterns:**
- Is it using hooks? Context? Redux?
- Are there repeated patterns?
- Is the style consistent?

**5. Look for red flags:**
- Hardcoded values that should be config
- Missing error handling
- Security issues (unsanitized input)
- Performance issues (unnecessary re-renders)

### Example: Reading a Generated Component

```tsx
// LLM generated this SearchResults component
import React, { useState, useEffect } from 'react';

interface Provider {
  id: string;
  name: string;
  specialty: string;
  rating: number;
}

export function SearchResults({ query }: { query: string }) {
  const [results, setResults] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch(`/api/search?q=${query}`)
      .then(r => r.json())
      .then(data => {
        setResults(data.providers);
        setLoading(false);
      });
  }, [query]);

  return (
    <div>
      {loading && <div>Loading...</div>}
      {results.map(p => (
        <div key={p.id}>
          <h3>{p.name}</h3>
          <p>{p.specialty}</p>
          <p>Rating: {p.rating}</p>
        </div>
      ))}
    </div>
  );
}
```

**Quick read:**
1. **Structure:** Component accepts `query` prop, fetches data, displays results
2. **Data flow:** query prop → fetch API → update results state → render
3. **Key function:** useEffect fetches on query change
4. **Pattern:** Standard useState + useEffect pattern

**Red flags spotted:**
- ❌ No error handling (fetch could fail)
- ❌ setLoading not called if fetch fails (loading stuck)
- ❌ No empty state (0 results shows blank)
- ❌ No cleanup (could cause memory leak if component unmounts during fetch)

**What you'd fix:**
```tsx
useEffect(() => {
  let cancelled = false;
  
  setLoading(true);
  fetch(`/api/search?q=${query}`)
    .then(r => r.json())
    .then(data => {
      if (!cancelled) {
        setResults(data.providers);
        setLoading(false);
      }
    })
    .catch(err => {
      if (!cancelled) {
        console.error(err);
        setLoading(false);
      }
    });

  return () => { cancelled = true; };
}, [query]);
```

**Time to read and identify issues: 2-3 minutes.**

## Debugging

**LLMs generate bugs too. You need to fix them.**

### Common Bugs in LLM-Generated Code

**1. Infinite render loops**
```jsx
// BUG: Missing dependency array
useEffect(() => {
  fetchData();
}); // Runs on every render!

// FIX:
useEffect(() => {
  fetchData();
}, []); // Runs once on mount
```

**2. Stale closures**
```jsx
// BUG: setTimeout captures old state
const [count, setCount] = useState(0);
setTimeout(() => {
  setCount(count + 1); // Always sets to 1
}, 1000);

// FIX: Use functional update
setCount(c => c + 1);
```

**3. Missing key prop**
```jsx
// BUG: No key
{items.map(item => <div>{item.name}</div>)}

// FIX: Add key
{items.map(item => <div key={item.id}>{item.name}</div>)}
```

**4. Race conditions**
```jsx
// BUG: Last request wins, even if it was sent first
async function search(query) {
  const results = await fetch(`/api/search?q=${query}`);
  setResults(results);
}

// FIX: Cancel previous requests
const abortControllerRef = useRef<AbortController>();

async function search(query) {
  abortControllerRef.current?.abort();
  abortControllerRef.current = new AbortController();
  
  const results = await fetch(`/api/search?q=${query}`, {
    signal: abortControllerRef.current.signal
  });
  setResults(results);
}
```

### Debugging Workflow

**1. Reproduce the bug**
- What steps cause it?
- Is it consistent or intermittent?

**2. Locate the issue**
- Add console.logs
- Use React DevTools to inspect state
- Use browser debugger breakpoints

**3. Understand the cause**
- Read the code around the bug
- Check dependencies, useEffect, event handlers

**4. Fix it**
- Try the minimal fix first
- Test that it actually fixes the issue
- Check for similar bugs elsewhere

**5. Prompt LLM to improve**
```
"This component has a bug: [describe bug]. 
Here's the code: [paste]. 
Fix the bug and explain what was wrong."
```

LLM will often identify the issue and provide a fix + explanation.

## Architecture Decisions

**LLMs follow instructions. They don't make strategic choices.**

### Decisions You Must Make

**1. Component boundaries**
- What should be a separate component?
- When to split vs keep together?
- How much to abstract?

**2. State management approach**
- Local state vs global state?
- Context vs Redux vs Zustand?
- Where does each piece of state live?

**3. Data fetching strategy**
- Component-level fetch vs centralized?
- Caching strategy?
- Real-time updates or polling?

**4. Error handling strategy**
- Error boundaries?
- Toast notifications vs inline errors?
- Retry logic?

**5. Code organization**
- File structure?
- Naming conventions?
- Shared utilities location?

### Example: Component Boundary Decision

**Scenario:** Building a provider profile page

**Option 1: Monolithic component**
```tsx
function ProviderProfile() {
  // 500 lines of code handling:
  // - Fetch provider data
  // - Display header, bio, services, reviews
  // - Book appointment form
  // - Review submission form
}
```

**Option 2: Composed components**
```tsx
function ProviderProfile() {
  return (
    <>
      <ProviderHeader />
      <ProviderBio />
      <ServicesList />
      <ReviewsList />
      <BookingForm />
    </>
  );
}
```

**Which is better?** Depends on:
- How often will these pieces be reused?
- How complex is each piece?
- Will different people work on different sections?

**You decide. LLM doesn't.**

## Security

**LLMs don't think about security by default.**

### Common Security Issues in Generated Code

**1. XSS (Cross-Site Scripting)**
```jsx
// UNSAFE: User input rendered as HTML
<div dangerouslySetInnerHTML={{ __html: userComment }} />

// SAFE: React escapes by default
<div>{userComment}</div>
```

**2. Hardcoded secrets**
```javascript
// UNSAFE: API key in frontend code
const API_KEY = 'sk-1234567890abcdef';

// SAFE: Use environment variables, backend proxy
const API_URL = process.env.REACT_APP_API_URL;
```

**3. Unvalidated input**
```javascript
// UNSAFE: Trust user input
const userId = params.id;
fetch(`/api/users/${userId}/delete`);

// SAFE: Validate and sanitize
const userId = parseInt(params.id, 10);
if (!isNaN(userId) && userId > 0) {
  fetch(`/api/users/${userId}/delete`);
}
```

**4. No CSRF protection**
```javascript
// UNSAFE: POST request without CSRF token
fetch('/api/transfer', {
  method: 'POST',
  body: JSON.stringify({ amount: 1000 })
});

// SAFE: Include CSRF token
fetch('/api/transfer', {
  method: 'POST',
  headers: {
    'X-CSRF-Token': getCSRFToken()
  },
  body: JSON.stringify({ amount: 1000 })
});
```

### Security Checklist for Generated Code

✅ User input is sanitized/escaped  
✅ No API keys or secrets in frontend code  
✅ Input validation on all user data  
✅ CSRF protection for state-changing requests  
✅ HTTPS only (no sensitive data over HTTP)  
✅ Authentication tokens stored securely  
✅ Permissions checked before sensitive actions  

**If unsure, ask:**
```
"Review this code for security vulnerabilities. Check for:
- XSS
- CSRF
- Input validation
- Secrets exposure
[paste code]"
```

## Testing

**Generated code rarely includes tests.**

### Why Tests Matter

- **Catch bugs** before production
- **Document behavior** (tests as specs)
- **Enable refactoring** (change code confidently)
- **Prevent regressions** (broken features stay broken)

### What to Test

**1. Critical user flows**
- Can user log in?
- Can user submit a form?
- Can user complete a purchase?

**2. Edge cases**
- Empty state rendering
- Error state handling
- Loading state display

**3. Component behavior**
- Props are respected
- Callbacks are called
- State updates correctly

### Generating Tests with LLMs

**Prompt:**
```
Write React Testing Library tests for this component.
Test:
- Renders correctly with props
- Handles button click
- Shows loading state
- Shows error state
[paste component code]
```

**Result:** Basic tests you can extend.

**But:** You still need to review tests, add edge cases, ensure coverage.

## The 80/20 Rule

**LLMs get you 80% of the way. The last 20% is where your skill matters.**

### The 80% (LLM-Generated)

✅ Basic structure and layout  
✅ Standard patterns (forms, tables, cards)  
✅ Styling with Tailwind  
✅ Simple state management  
✅ API calls and data fetching  
✅ Happy path functionality  

### The 20% (Human-Added)

✅ Complex state orchestration  
✅ Performance optimization  
✅ Accessibility features  
✅ Comprehensive error handling  
✅ Security hardening  
✅ Test coverage  
✅ Edge case handling  
✅ Code organization and architecture  

**The 80% takes 10 minutes. The 20% takes 2 hours.**

Still faster than 8 hours to build from scratch.

## Building Your Code Reading Skill

**How to get better at reading generated code:**

### Practice Routine

**1. Generate a component**
```bash
claude -p "Create a data table with sort functionality"
```

**2. Read it without running**
- What does it do?
- How does sorting work?
- What state is tracked?

**3. Run it and verify**
- Does it work as you expected?
- Any bugs?

**4. Identify improvements**
- What would you change?
- What's missing?

**5. Prompt for improvements**
```
"Add pagination to this table"
```

**6. Read the updated code**
- What changed?
- How was pagination implemented?
- Learn the pattern

**Repeat daily. You'll get faster at reading and spotting issues.**

### Deliberate Practice

- **Generate code for patterns you don't know** (e.g., "Create a drag-and-drop list")
- **Read it to learn the pattern** (how does drag-and-drop work?)
- **Compare multiple implementations** (Claude vs GPT — what's different?)
- **Refactor generated code** (make it cleaner, more maintainable)

**Goal:** Build intuition for what good code looks like.

## The Recommended Learning Path

**How to become effective at LLM-assisted frontend development:**

### Phase 1: Prompt & Review (Weeks 1-2)
- Generate lots of components with LLMs
- Read every line of generated code
- Test everything in the browser
- Don't worry about understanding everything yet

**Goal:** Get comfortable with the workflow.

### Phase 2: Pattern Recognition (Weeks 3-4)
- Start noticing repeated patterns (useState, useEffect, map, etc.)
- Look up patterns you don't recognize
- Read the frontend-development learning module for deeper understanding
- Identify common bugs in generated code

**Goal:** Build mental models of how React works.

### Phase 3: Active Refinement (Weeks 5-8)
- Generate code, then improve it yourself
- Add error handling, loading states, accessibility
- Refactor messy code into cleaner patterns
- Write tests for generated components

**Goal:** Bridge the 80% → 100% gap yourself.

### Phase 4: Architectural Thinking (Weeks 9-12)
- Design component hierarchies before prompting
- Make state management decisions
- Choose when to use generated code vs write manually
- Build your own component library

**Goal:** Use LLMs as a tool, not a crutch.

### Phase 5: Teaching Mode (Ongoing)
- Help others use LLM-assisted workflows
- Review generated code in PRs
- Build prompts and templates for your team
- Share what works and what doesn't

**Goal:** Become the expert on your team.

## Key Takeaways

1. **LLMs can't handle complex state, performance, a11y, or security** (yet)
2. **You must read and understand generated code**
3. **Debugging is still your job** — LLMs make bugs too
4. **Architecture decisions are still your job** — LLMs don't design systems
5. **Security must be added manually** — LLMs don't think defensively
6. **Testing must be added manually** — generated code rarely has tests
7. **80/20 rule: LLMs do 80%, you do the critical 20%**
8. **Build code reading skill through practice**
9. **Learning path: Prompt → Review → Refine → Architect**

---

**Try This Now:**

Generate a component with an LLM, then:

1. Read the code without running it
2. Predict what bugs it might have
3. Run it and see if you were right
4. Fix any bugs you find
5. Add error handling, loading state, and accessibility
6. Write a test for it

This is the 80% → 100% workflow. Practice it.

→ Next: [Building a Frontend CLI](07-building-a-frontend-cli.md)
