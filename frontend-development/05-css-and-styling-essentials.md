# CSS and Styling Essentials

**Enough to Read and Modify, Not Master**

You said CSS is less interesting to you — fair! This guide gives you enough to understand and modify our styles without diving deep into design.

---

## Table of Contents

1. [CSS Basics (Quick Overview)](#css-basics-quick-overview)
2. [The Box Model](#the-box-model)
3. [Flexbox (Our Layout System)](#flexbox-our-layout-system)
4. [Responsive Design](#responsive-design)
5. [TailwindCSS: Utility-First](#tailwindcss-utility-first)
6. [How Tailwind Maps to CSS](#how-tailwind-maps-to-css)
7. [Component Styling Patterns](#component-styling-patterns)

---

## CSS Basics (Quick Overview)

### Syntax

```css
/* Selector { property: value; } */
h1 {
    color: blue;
    font-size: 24px;
    margin-bottom: 16px;
}

/* Class selector */
.card {
    background-color: white;
    border: 1px solid gray;
    padding: 16px;
}

/* ID selector */
#root {
    max-width: 1200px;
}

/* Descendant selector */
.card h2 {
    color: darkblue;
}
```

### Common Properties

| Property | What It Does | Example |
|----------|-------------|---------|
| `color` | Text color | `color: blue` |
| `background-color` | Background | `background-color: white` |
| `font-size` | Text size | `font-size: 16px` |
| `margin` | Space outside | `margin: 16px` |
| `padding` | Space inside | `padding: 8px` |
| `border` | Border around | `border: 1px solid black` |
| `width`, `height` | Size | `width: 100%` |
| `display` | Layout type | `display: flex` |

---

## The Box Model

### Every Element Is a Box

```
┌─────────────────────────────────────────┐
│           MARGIN (transparent)          │
│  ┌──────────────────────────────────┐  │
│  │    BORDER (can be colored)       │  │
│  │  ┌───────────────────────────┐  │  │
│  │  │  PADDING (background)     │  │  │
│  │  │  ┌────────────────────┐  │  │  │
│  │  │  │   CONTENT          │  │  │  │
│  │  │  │   (text, images)   │  │  │  │
│  │  │  └────────────────────┘  │  │  │
│  │  └───────────────────────────┘  │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

```css
.box {
    width: 200px;          /* Content width */
    height: 100px;         /* Content height */
    padding: 20px;         /* Space inside border */
    border: 5px solid black;  /* Border */
    margin: 10px;          /* Space outside border */
}

/* Total width = 200 + 20×2 + 5×2 + 10×2 = 270px */
```

### Shorthand Properties

```css
/* Margin/Padding: top right bottom left (clockwise) */
margin: 10px 20px 10px 20px;

/* Margin/Padding: top/bottom left/right */
margin: 10px 20px;

/* Margin/Padding: all sides */
margin: 10px;

/* Specific sides */
margin-top: 10px;
margin-right: 20px;
margin-bottom: 10px;
margin-left: 20px;
```

---

## Flexbox (Our Layout System)

### The Problem: Traditional Layout Is Hard

```css
/* Old way: floats, positioning, inline-block (don't use) */
.container {
    /* Complex, fragile hacks */
}
```

### Flexbox: Modern Layout

```css
.container {
    display: flex;  /* Enable flexbox */
    gap: 16px;      /* Space between children */
}
```

**All children become "flex items" that can be easily arranged.**

### Flex Container Properties

```css
.container {
    display: flex;
    
    /* Direction */
    flex-direction: row;        /* → horizontal (default) */
    flex-direction: column;     /* ↓ vertical */
    
    /* Alignment (main axis) */
    justify-content: flex-start;   /* |123    | */
    justify-content: center;       /* |  123  | */
    justify-content: flex-end;     /* |    123| */
    justify-content: space-between;/* |1  2  3| */
    
    /* Alignment (cross axis) */
    align-items: flex-start;    /* Top */
    align-items: center;        /* Center */
    align-items: flex-end;      /* Bottom */
    
    /* Wrapping */
    flex-wrap: nowrap;  /* One line (default) */
    flex-wrap: wrap;    /* Multiple lines */
    
    /* Gap between items */
    gap: 16px;          /* Space between children */
}
```

### Flex Item Properties

```css
.item {
    /* Grow to fill space */
    flex-grow: 1;
    
    /* Shrink when needed */
    flex-shrink: 1;
    
    /* Base size */
    flex-basis: 200px;
    
    /* Shorthand */
    flex: 1;  /* flex-grow: 1, flex-shrink: 1, flex-basis: 0 */
}
```

### Common Patterns

**Center anything:**
```css
.container {
    display: flex;
    justify-content: center;  /* Horizontal center */
    align-items: center;      /* Vertical center */
}
```

**Horizontal layout with spacing:**
```css
.container {
    display: flex;
    gap: 16px;  /* Space between items */
}
```

**Responsive sidebar + main:**
```css
.layout {
    display: flex;
    gap: 24px;
}

.sidebar {
    flex: 0 0 250px;  /* Fixed width */
}

.main {
    flex: 1;  /* Fill remaining space */
}
```

---

## Responsive Design

### Media Queries

```css
/* Base styles (mobile-first) */
.container {
    padding: 16px;
}

/* Tablet and up */
@media (min-width: 768px) {
    .container {
        padding: 32px;
    }
}

/* Desktop and up */
@media (min-width: 1024px) {
    .container {
        padding: 48px;
        max-width: 1200px;
        margin: 0 auto;
    }
}
```

### Common Breakpoints

| Name | Width | Tailwind Class |
|------|-------|----------------|
| Mobile | Default | (no prefix) |
| Tablet | 640px+ | `sm:` |
| Desktop | 1024px+ | `lg:` |
| Large | 1280px+ | `xl:` |

---

## TailwindCSS: Utility-First

### Traditional CSS

```css
/* styles.css */
.card {
    background-color: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 16px;
}

.card-title {
    font-size: 20px;
    font-weight: 600;
    margin-bottom: 8px;
}
```

```html
<div class="card">
    <h3 class="card-title">Provider Name</h3>
    <p>Details...</p>
</div>
```

### Tailwind CSS (Utility-First)

```html
<div class="bg-white border border-gray-200 rounded-lg p-4 mb-4">
    <h3 class="text-xl font-semibold mb-2">Provider Name</h3>
    <p>Details...</p>
</div>
```

**No separate CSS file needed!** Styles are inline via utility classes.

### Tailwind Utility Classes

| CSS Property | Tailwind Class | Example |
|-------------|----------------|---------|
| `color: blue` | `text-blue-600` | Text color |
| `background-color: white` | `bg-white` | Background |
| `padding: 16px` | `p-4` | All sides (4 = 16px) |
| `padding-left: 8px` | `pl-2` | Left only (2 = 8px) |
| `margin: 0` | `m-0` | No margin |
| `margin-bottom: 16px` | `mb-4` | Bottom only |
| `display: flex` | `flex` | Flexbox |
| `gap: 16px` | `gap-4` | Flex gap |
| `font-weight: 600` | `font-semibold` | Bold text |
| `border-radius: 8px` | `rounded-lg` | Rounded corners |

### Spacing Scale (Important!)

```
0  → 0px
1  → 4px
2  → 8px
3  → 12px
4  → 16px
6  → 24px
8  → 32px
12 → 48px
16 → 64px
```

**Example:**
- `p-4` = `padding: 16px`
- `gap-2` = `gap: 8px`
- `mt-8` = `margin-top: 32px`

### Responsive Modifiers

```html
<!-- Mobile: stack vertically, Desktop: horizontal -->
<div class="flex flex-col lg:flex-row gap-4">
    <div>Sidebar</div>
    <div>Main</div>
</div>

<!-- Mobile: full width, Desktop: half width -->
<div class="w-full lg:w-1/2">Content</div>

<!-- Mobile: hidden, Desktop: visible -->
<div class="hidden lg:block">Desktop only</div>
```

---

## How Tailwind Maps to CSS

### Reading Tailwind Classes

```html
<div class="flex items-center gap-4 p-6 bg-white rounded-lg shadow-md border border-gray-200">
    <div class="text-xl font-bold text-gray-900">Provider Name</div>
</div>
```

**Translates to:**

```css
.container {
    display: flex;
    align-items: center;
    gap: 16px;              /* gap-4 */
    padding: 24px;          /* p-6 */
    background-color: white;  /* bg-white */
    border-radius: 8px;     /* rounded-lg */
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);  /* shadow-md */
    border: 1px solid #e5e7eb;  /* border border-gray-200 */
}

.title {
    font-size: 20px;        /* text-xl */
    font-weight: 700;       /* font-bold */
    color: #111827;         /* text-gray-900 */
}
```

### Common Patterns in Provider Search

```html
<!-- Card -->
<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    Card content
</div>

<!-- Button -->
<button class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
    Search
</button>

<!-- Input -->
<input class="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-2 focus:ring-blue-500" />

<!-- Flex container -->
<div class="flex items-center justify-between gap-4">
    <div>Left</div>
    <div>Right</div>
</div>
```

---

## Component Styling Patterns

### Conditional Classes

```javascript
// Using template literals
const buttonClass = `
    px-4 py-2 rounded-md
    ${isPrimary ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-800'}
    ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:opacity-90'}
`

<button className={buttonClass}>Click me</button>
```

### Using clsx Library (Common)

```javascript
import clsx from 'clsx'

const buttonClass = clsx(
    'px-4 py-2 rounded-md',
    isPrimary && 'bg-blue-600 text-white',
    !isPrimary && 'bg-gray-200 text-gray-800',
    isDisabled && 'opacity-50 cursor-not-allowed',
    !isDisabled && 'hover:opacity-90'
)
```

### Example from Provider Search

```typescript
// web/src/components/StatusIndicator.tsx
const statusClasses = clsx(
    'inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium',
    STATUS_CONFIG[status].bgColor,
    STATUS_CONFIG[status].color
)

return (
    <span className={statusClasses}>
        {STATUS_CONFIG[status].icon} {STATUS_CONFIG[status].label}
    </span>
)
```

---

## Why This Matters for Provider Search

**Our entire app uses Tailwind:**
- No separate CSS files (except `index.css` for global styles)
- All styles are inline via utility classes
- Responsive design via `sm:`, `lg:` prefixes

**To modify styles:**
1. Find the component in `web/src/`
2. Look at `className` prop
3. Add/remove Tailwind classes
4. Save → hot reload → see changes instantly

**Example:** Make a button larger
```diff
- <button className="px-4 py-2 text-base">Search</button>
+ <button className="px-6 py-3 text-lg">Search</button>
```

**Common tasks:**
- **Add spacing:** `gap-4`, `p-4`, `mb-2`
- **Change colors:** `bg-blue-600`, `text-gray-900`
- **Responsive:** `lg:hidden`, `sm:w-1/2`
- **Hover effects:** `hover:bg-blue-700`

---

## Next Steps

- **[06-react-fundamentals.md](06-react-fundamentals.md)** — Components that render these styles
- **[12-maps-and-complex-ui.md](12-maps-and-complex-ui.md)** — Complex UI patterns

---

**You now know enough CSS to read and modify our styles. Focus on React next.**
