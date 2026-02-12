# Prompt Engineering for Frontends

## Table of Contents
- [The Anatomy of a Good Frontend Prompt](#the-anatomy-of-a-good-frontend-prompt)
- [Structural Prompts](#structural-prompts)
- [Behavioral Prompts](#behavioral-prompts)
- [Style Prompts](#style-prompts)
- [Iterative Refinement](#iterative-refinement)
- [Anti-Patterns](#anti-patterns)
- [Reference-Based Prompts](#reference-based-prompts)
- [Prompt Templates](#prompt-templates)

## The Anatomy of a Good Frontend Prompt

A great frontend prompt has **three components:**

1. **Structure** — What's on the page?
2. **Behavior** — How does it respond to user actions?
3. **Style** — How does it look and feel?

### Bad Prompt (Vague)

```
"Build a dashboard"
```

**Problem:** No structure, behavior, or style details. LLM will guess.

### Good Prompt (Specific)

```
Create a React dashboard component with:

Structure:
- Header: app logo (left), user menu (right)
- Main grid: 4 metric cards (revenue, users, conversion, churn)
- Below: line chart showing revenue over last 30 days

Behavior:
- Fetch data from /api/dashboard on mount
- Show loading spinner while fetching
- If error, display error message with retry button

Style:
- Dark theme (bg-gray-900)
- Use Tailwind CSS
- Cards have subtle shadow and hover effect
- Chart uses purple accent color (#7c3aed)
```

**Result:** LLM has everything it needs to generate exactly what you want.

## Structural Prompts

**Goal:** Describe the layout and components clearly.

### Pattern 1: Top-to-Bottom Description

```
Create a landing page with:
- Navigation bar: logo (left), links (center), CTA button (right)
- Hero section: headline, subheadline, email input + button
- Features section: 3 columns with icon, title, description
- Testimonials: 2 rows of customer quotes with avatars
- Footer: copyright, social links
```

### Pattern 2: Component Hierarchy

```
Create a ProviderCard component:
- Container: card with shadow and rounded corners
  - Top section:
    - Left: circular avatar image
    - Right: "Save" heart icon button
  - Middle section:
    - Name (h3, bold)
    - Specialty (gray text, smaller)
    - Rating stars (gold) + review count
  - Bottom section:
    - Location with pin icon
    - "View Profile" button (primary)
    - "Book Appointment" button (secondary)
```

### Pattern 3: Grid/Flex Layout

```
Create a dashboard with:
- 3-column grid (desktop), 1-column (mobile)
- Each column contains:
  - Metric card: label, value, trend indicator
- Below grid:
  - Full-width chart component
```

**Pro tip:** Use terms like "flex", "grid", "columns", "rows" — LLMs understand CSS layout terminology.

## Behavioral Prompts

**Goal:** Describe what happens when users interact.

### Pattern 1: Event → Action

```
Create a search component where:
- When user types in the search box, filter results in real-time
- When user clicks a result, navigate to detail page
- When search returns no results, show "No results found" message
```

### Pattern 2: State Transitions

```
Create a form with validation:
- Initially: all fields empty, submit button disabled
- While typing: show validation errors below invalid fields
- When all fields valid: enable submit button
- On submit: show loading spinner, disable button
- On success: show success message, reset form
- On error: show error message, keep form filled
```

### Pattern 3: API Interactions

```
Create a data table that:
- On mount: fetch /api/providers, show loading spinner
- On fetch success: display data in sortable table
- On fetch error: show error banner with retry button
- When user clicks column header: sort by that column
- When user clicks row: open detail modal
```

### Pattern 4: Conditional Display

```
Create a user profile page where:
- If user is authenticated: show profile data and edit button
- If user is NOT authenticated: show login prompt
- If profile is loading: show skeleton loader
- If user owns this profile: show "Edit Profile" button
- If user doesn't own profile: show "Follow" button
```

**Pro tip:** Use "when", "if", "on", "while" to trigger LLM's behavioral understanding.

## Style Prompts

**Goal:** Describe visual design clearly.

### Pattern 1: Theme-Based

```
Use a dark theme with:
- Background: dark gray (#1a1a1a)
- Text: white with good contrast
- Accent color: purple (#7c3aed)
- Cards: slightly lighter gray (#2a2a2a) with subtle shadow
```

### Pattern 2: Design System Reference

```
Style this component to match Stripe's design:
- Clean, minimal layout
- Subtle shadows
- Rounded corners (8px)
- Purple accent color
- Smooth transitions on hover
```

### Pattern 3: Responsive Design

```
Make this responsive:
- Desktop (≥1024px): 4-column grid
- Tablet (768px-1023px): 2-column grid
- Mobile (<768px): 1-column stack
- Hide sidebar on mobile, show hamburger menu
```

### Pattern 4: Animation/Interaction

```
Add these interactions:
- Cards lift slightly on hover (shadow increases)
- Buttons have smooth color transition (200ms)
- Modal fades in with backdrop blur
- Loading spinner rotates smoothly
```

### Pattern 5: Typography

```
Typography:
- Headings: Inter font, bold, size scale: 2xl, xl, lg
- Body: Inter font, regular, base size
- Labels: uppercase, tracking-wide, text-sm, gray-500
```

**Pro tip:** Reference well-known design systems (Stripe, Tailwind UI, Material Design) for instant style understanding.

## Iterative Refinement

**The power of LLM frontend work: small, incremental improvements.**

### Example: Building a Dashboard

**Prompt 1: Start Simple**
```
Create a React dashboard component with 3 metric cards: 
Revenue, Users, Conversion Rate. Use Tailwind CSS, dark theme.
```

**Prompt 2: Add Data Fetching**
```
Update the dashboard to fetch data from /api/metrics on mount. 
Show a loading spinner while fetching.
```

**Prompt 3: Add Chart**
```
Below the metric cards, add a line chart showing revenue over 
the last 30 days. Use Chart.js.
```

**Prompt 4: Add Filters**
```
Add a date range picker at the top. When changed, refetch data 
for that date range.
```

**Prompt 5: Add Export**
```
Add an "Export to CSV" button that downloads the current data.
```

**Each step is testable. If something breaks, you know which prompt caused it.**

### The Refinement Loop

```
Generate → Test → Identify Issue → Refine Prompt → Repeat
```

**Common refinements:**
- "Make the font size larger"
- "Use a different color for the primary button"
- "Add padding between the cards"
- "Make the table rows striped"
- "Add a search box above the table"

**Micro-changes = micro-prompts. Fast iteration.**

## Anti-Patterns

**Prompts that produce bad results:**

### Anti-Pattern 1: Too Vague

```
"Build a nice-looking dashboard"
```

**Problem:** "Nice-looking" is subjective. LLM will guess.

**Fix:** Be specific about colors, layout, components.

### Anti-Pattern 2: Too Many Features At Once

```
"Create a dashboard with metrics, charts, tables, filters, 
search, export, user management, settings panel, notifications, 
dark mode toggle, and real-time updates"
```

**Problem:** LLM will generate something, but it'll be messy and incomplete.

**Fix:** Start with core features, add iteratively.

### Anti-Pattern 3: Conflicting Instructions

```
"Use Tailwind CSS but also write custom inline styles. 
Make it look modern but also retro. Keep it simple but add lots of animations."
```

**Problem:** Contradictions confuse the LLM.

**Fix:** Be consistent in your requirements.

### Anti-Pattern 4: Assuming Context

```
"Add the search functionality we discussed"
```

**Problem:** LLM doesn't remember previous conversations (unless in same session).

**Fix:** Include all necessary context in each prompt.

### Anti-Pattern 5: No Tech Stack Specified

```
"Create a dashboard"
```

**Problem:** LLM might generate vanilla JS when you need React, or vice versa.

**Fix:** Always specify: "React + TypeScript + Tailwind" or "Single-file HTML + Alpine.js"

## Reference-Based Prompts

**Leverage existing code to guide new generation.**

### Pattern 1: Clone and Modify

```
Look at this SearchResults component [paste code]. 

Create a similar component called ProviderList with the same 
layout and styling, but showing provider cards instead of 
search results. Each card should have name, specialty, rating, 
and location.
```

### Pattern 2: Extend Existing

```
Here's my current Button component [paste code]. 

Add these variants:
- outline: transparent bg, border, hover fills
- ghost: transparent bg, no border, hover shows subtle bg
- link: looks like a link, no padding

Keep the existing solid variant.
```

### Pattern 3: Match Style

```
Here's our ProviderCard component [paste code]. 

Create a new ServiceCard component that matches this visual 
style (colors, shadows, spacing, typography) but shows service 
name, description, price, and "Learn More" button.
```

### Pattern 4: Convert Format

```
Here's a working single-file HTML prototype [paste code]. 

Convert this to:
- React component with TypeScript
- Proper state management with useState
- Props for configuration
- Tailwind classes (not inline styles)
```

**Reference-based prompts are incredibly effective** — LLMs learn your style.

## Prompt Templates

**Copy-paste these templates for common patterns:**

### Template 1: Dashboard with Cards and Charts

```
Create a [React/single-file HTML] dashboard component with:

Structure:
- Header: [title/logo] on left, [user menu/actions] on right
- Main content:
  - Grid of [number] metric cards showing: [metric names]
  - Below: [chart type] showing [data description]

Behavior:
- Fetch data from [API endpoint] on mount
- Show loading spinner while fetching
- Display error message if fetch fails
- Refresh data every [X] seconds (optional)

Style:
- [Dark/light] theme
- Use Tailwind CSS
- Cards have [shadow/border/hover effects]
- Chart uses [color] as primary color

Tech:
- [React + TypeScript / Single-file HTML + Alpine.js]
```

**Example filled in:**

```
Create a React dashboard component with:

Structure:
- Header: "Analytics Dashboard" on left, date range picker on right
- Main content:
  - Grid of 4 metric cards showing: Revenue, Users, Conversion, Churn
  - Below: line chart showing daily revenue for selected date range

Behavior:
- Fetch data from /api/dashboard?start=X&end=Y on mount
- Show loading spinner while fetching
- Display error message if fetch fails

Style:
- Dark theme (bg-gray-900)
- Use Tailwind CSS
- Cards have subtle shadow and lift on hover
- Chart uses purple (#7c3aed) as primary color

Tech:
- React + TypeScript
```

### Template 2: Data Table with Sort/Filter/Export

```
Create a data table component that:

Structure:
- Search box at top
- Table with columns: [column names]
- Pagination controls at bottom

Behavior:
- Fetch data from [API endpoint]
- Filter rows in real-time as user types in search
- Click column header to sort ascending/descending
- Paginate: [X] rows per page
- "Export to CSV" button downloads current filtered data

Style:
- [Dark/light] theme
- Striped rows
- Hover highlights row
- Sortable columns show up/down arrow icon

Tech:
- [React + TypeScript / Single-file HTML]
```

### Template 3: Form with Validation

```
Create a form component with:

Fields:
- [Field 1]: [type], [validation rules]
- [Field 2]: [type], [validation rules]
- [etc.]

Behavior:
- Validate fields on blur (when user leaves field)
- Show validation errors below each field
- Disable submit button until all fields valid
- On submit: POST to [API endpoint]
- Show loading spinner while submitting
- On success: [show message / navigate / reset form]
- On error: [show error message]

Style:
- [Dark/light] theme
- Use Tailwind CSS
- Input focus: [color] border
- Error messages: red text below field
- Success state: [green checkmark / banner]

Tech:
- [React + TypeScript with react-hook-form / Alpine.js]
```

### Template 4: Map with Markers and Popups

```
Create a map component that:

Structure:
- Full-width map showing [location]
- Markers for each item in [data array]
- Popup on marker click shows [info]

Behavior:
- Load data from [API endpoint]
- Add marker for each item using lat/lng
- Click marker: show popup with [details]
- "Current Location" button centers map on user
- Cluster markers when zoomed out (optional)

Style:
- [Map tile style: OSM / dark / satellite]
- Markers color-coded by [category]
- Popups styled to match app theme

Tech:
- [React + Leaflet / Single-file HTML + Leaflet]
```

### Template 5: Modal/Dialog with State Management

```
Create a modal component that:

Structure:
- Overlay backdrop (blurred/darkened)
- Centered modal box
- Header: [title], close X button
- Body: [content description]
- Footer: [Cancel] and [Confirm] buttons

Behavior:
- Open when [trigger action]
- Close when: user clicks X, backdrop, Cancel, or hits Escape
- Confirm button: [action description]
- Close on confirm success
- Prevent body scroll when modal open

Style:
- Backdrop: dark with blur
- Modal: [bg color], rounded corners, shadow
- Fade-in animation
- Mobile: full-screen on small screens

Tech:
- [React with useState / Alpine.js]
```

### Template 6: Multi-Step Wizard

```
Create a multi-step form wizard with:

Steps:
1. [Step 1 name]: [fields]
2. [Step 2 name]: [fields]
3. [Step 3 name]: [review/summary]

Behavior:
- Show progress indicator (Step X of Y)
- "Next" button validates current step before advancing
- "Back" button goes to previous step (preserves data)
- Final step: "Submit" button sends all data to [API endpoint]
- Can't skip ahead without completing previous steps

Style:
- Progress bar or step indicators at top
- [Dark/light] theme
- Smooth transitions between steps
- Current step highlighted

Tech:
- [React + TypeScript / Alpine.js]
```

## Advanced Techniques

### Technique 1: Provide Examples

```
Create a notification component. Examples:

1. Success: Green background, checkmark icon, 
   "Changes saved successfully"
   
2. Error: Red background, X icon, 
   "Failed to save changes. Please try again."
   
3. Warning: Yellow background, alert icon,
   "Your session will expire in 5 minutes"

Each notification should auto-dismiss after 5 seconds and 
have a manual close button.
```

### Technique 2: Reference Screenshots

```
I have a screenshot of a dashboard I like [describe it in detail 
or attach if possible]. Recreate this design with:
- Same layout: 2-column, cards on left, chart on right
- Similar color scheme: dark blue background, white cards
- Same typography style: bold headers, light body text
```

### Technique 3: Negative Instructions

```
Create a button component. DO NOT:
- Use inline styles (use Tailwind classes only)
- Include animations (keep it simple)
- Make it rounded (use sharp corners)
- Add icons (text only)
```

### Technique 4: Specify Edge Cases

```
Create a data table that handles:
- Empty state: show "No data available" message with icon
- Loading state: show skeleton rows
- Error state: show error message with retry button
- Single row: still show table header
- 1000+ rows: paginate, don't render all at once
```

## Key Takeaways

1. **Good prompts have structure, behavior, and style**
2. **Be specific** — vague prompts = vague results
3. **Iterate in small steps** — easier to debug
4. **Use templates** for common patterns
5. **Reference existing code** to maintain consistency
6. **Specify tech stack** (React vs HTML, Tailwind vs custom CSS)
7. **Describe edge cases** (loading, error, empty states)

---

**Try This Now:**

Use one of the templates above to generate a component. Fill in the blanks, run it through Claude Code or Codex, and see how close you get to your vision on the first try.

Then iterate: "Add a loading state", "Change the primary color to green", "Make it mobile-responsive".

Track how many iterations it takes to get exactly what you want. Goal: 1-3 iterations.

→ Next: [Rapid Prototyping Patterns](05-rapid-prototyping-patterns.md)
