# JavaScript Fundamentals

**From Python to JavaScript: A First Principles Guide**

You know Python. JavaScript is different, but not alien. This guide translates everything you know into JavaScript concepts, with Python↔JavaScript comparisons throughout.

---

## Table of Contents

1. [Variables and Constants](#variables-and-constants)
2. [Data Types](#data-types)
3. [Functions](#functions)
4. [Objects and Arrays](#objects-and-arrays)
5. [Control Flow](#control-flow)
6. [String Templates](#string-templates)
7. [Comparison Operators](#comparison-operators)
8. [Error Handling](#error-handling)
9. [Modules](#modules)
10. [Summary: Python↔JavaScript Quick Reference](#summary-pythonjavascript-quick-reference)

---

## Variables and Constants

### Python: Everything is Mutable by Default

```python
# Python
x = 5
x = 10  # Can reassign

MY_CONSTANT = 42  # Convention only, not enforced
MY_CONSTANT = 100  # Python doesn't stop you
```

### JavaScript: Three Ways to Declare

```javascript
// JavaScript
var x = 5      // OLD way (don't use) - function-scoped, can redeclare
let y = 10     // NEW way - block-scoped, can reassign
const z = 15   // BEST - block-scoped, CANNOT reassign
```

### The const Default Rule

**In modern JavaScript, use `const` by default.** Only use `let` when you *know* the variable will change.

| Python | JavaScript | Notes |
|--------|------------|-------|
| `x = 5` | `const x = 5` | Immutable binding (can't reassign) |
| `x = 5`<br>`x = 10` | `let x = 5`<br>`x = 10` | Can reassign |
| No equivalent | `var x = 5` | Legacy, avoid |

### Why const?

```javascript
const user = { name: "Blake", role: "engineer" }
user.name = "Blake2"  // ✅ This works! Object is mutable
user = { name: "Someone else" }  // ❌ This fails! Can't reassign

const numbers = [1, 2, 3]
numbers.push(4)  // ✅ This works! Array is mutable
numbers = [5, 6, 7]  // ❌ This fails! Can't reassign
```

**Key insight:** `const` means "constant binding," not "immutable data." The variable can't be reassigned, but objects/arrays can still be modified.

### Block Scope vs Function Scope

```javascript
// Python: function scope only
def my_function():
    if True:
        x = 5
    print(x)  # ✅ Works! x is visible

// JavaScript with let/const: block scope
function myFunction() {
    if (true) {
        let x = 5
    }
    console.log(x)  // ❌ Error! x not defined outside if block
}

// JavaScript with var: function scope (like Python)
function myFunction() {
    if (true) {
        var x = 5
    }
    console.log(x)  // ✅ Works! var is function-scoped
}
```

**Bottom line:** Use `const` by default. Use `let` when you need reassignment. Never use `var`.

---

## Data Types

### Python vs JavaScript Primitives

| Python | JavaScript | Notes |
|--------|------------|-------|
| `str` | `string` | Immutable text |
| `int` | `number` | JavaScript has only one number type |
| `float` | `number` | Same as int! |
| `bool` | `boolean` | `True` → `true`, `False` → `false` |
| `None` | `null` or `undefined` | Two "nothing" values! |
| `dict` | `object` | Key-value pairs |
| `list` | `Array` | Ordered collection |

### Strings

```python
# Python
name = "Blake"
name = 'Blake'  # Both work
multiline = """
    Multiple
    lines
"""
```

```javascript
// JavaScript
const name = "Blake"
const name = 'Blake'  // Both work, same thing
const multiline = `
    Multiple
    lines
`  // Template literal (backticks)
```

### Numbers (JavaScript Has Only One!)

```python
# Python
x = 5        # int
y = 5.5      # float
z = 5 / 2    # 2.5 (true division)
w = 5 // 2   # 2 (integer division)
```

```javascript
// JavaScript
const x = 5        // number
const y = 5.5      // also number
const z = 5 / 2    // 2.5 (always true division)
const w = Math.floor(5 / 2)  // 2 (explicit floor)
```

**JavaScript gotcha:** There's no separate integer type. `5` and `5.0` are the same.

### Booleans

```python
# Python
is_valid = True
is_empty = False
```

```javascript
// JavaScript
const isValid = true   // lowercase!
const isEmpty = false  // lowercase!
```

**Naming convention:** JavaScript uses `camelCase`, not `snake_case`.

### null vs undefined (The Double "Nothing")

```python
# Python has one "nothing"
x = None
```

```javascript
// JavaScript has TWO kinds of "nothing"
const x = null       // Explicitly set to nothing
let y                // undefined (not initialized)
let z = undefined    // Explicitly undefined (rare)
```

| Value | Meaning |
|-------|---------|
| `null` | "I explicitly set this to nothing" |
| `undefined` | "This hasn't been initialized" or "This property doesn't exist" |

```javascript
const user = {
    name: "Blake",
    age: null  // We know they exist, but age is intentionally empty
}

console.log(user.email)  // undefined (property doesn't exist)
```

**Practical tip:** Use `null` when you mean "empty value." You'll see `undefined` automatically when things don't exist.

---

## Functions

### Python Functions

```python
# Function declaration
def greet(name):
    return f"Hello, {name}"

# Lambda (anonymous function)
double = lambda x: x * 2

# Function as argument
def apply_func(f, value):
    return f(value)

result = apply_func(lambda x: x * 3, 10)
```

### JavaScript Functions: Three Styles

```javascript
// 1. Function declaration (like Python def)
function greet(name) {
    return `Hello, ${name}`
}

// 2. Function expression (assigned to variable)
const greet = function(name) {
    return `Hello, ${name}`
}

// 3. Arrow function (like Python lambda, but more powerful)
const greet = (name) => {
    return `Hello, ${name}`
}

// Arrow function shorthand (implicit return)
const greet = (name) => `Hello, ${name}`
const double = (x) => x * 2
const add = (a, b) => a + b
```

### Arrow Functions: The Modern Way

**Python lambda is limited:** One expression only.

```python
# Python lambda: single expression
double = lambda x: x * 2

# Can't do multiple lines:
# multiply_and_log = lambda x, y: print(x * y)  # ❌ Syntax error!
```

**JavaScript arrow functions are full functions:**

```javascript
// Single expression: implicit return
const double = (x) => x * 2

// Multiple lines: explicit return
const multiplyAndLog = (x, y) => {
    const result = x * y
    console.log(`Result: ${result}`)
    return result
}

// Single parameter: parentheses optional
const square = x => x * x
const cube = (x) => x * x * x  // Same, with parens
```

### Arrow Function Syntax Rules

| Pattern | Example | Notes |
|---------|---------|-------|
| No parameters | `() => 42` | Need empty parens |
| One parameter | `x => x * 2` | Parens optional |
| Multiple parameters | `(x, y) => x + y` | Need parens |
| Single expression | `x => x * 2` | Implicit return |
| Multiple statements | `x => { return x * 2 }` | Need braces and explicit return |
| Return object | `x => ({ value: x })` | Wrap object in parens |

### Functions Are First-Class (Like Python)

```javascript
// Functions as arguments
const numbers = [1, 2, 3]
const doubled = numbers.map(x => x * 2)  // [2, 4, 6]

// Functions as return values
const makeMultiplier = (factor) => {
    return (x) => x * factor
}

const double = makeMultiplier(2)
const triple = makeMultiplier(3)
console.log(double(5))  // 10
console.log(triple(5))  // 15
```

### Python↔JavaScript Function Comparison

| Python | JavaScript | Notes |
|--------|------------|-------|
| `def func(x):` | `function func(x) { }` | Function declaration |
| `func = lambda x: x * 2` | `const func = x => x * 2` | Anonymous function |
| `def func(x, y=10):` | `const func = (x, y=10) => { }` | Default parameters |
| `def func(*args):` | `const func = (...args) => { }` | Rest parameters |
| `func(1, 2, 3)` | `func(1, 2, 3)` | Calling functions |

---

## Objects and Arrays

### Objects (Like Python Dicts)

```python
# Python dictionary
user = {
    "name": "Blake",
    "age": 30,
    "role": "engineer"
}

print(user["name"])  # Bracket notation
print(user.get("email", "N/A"))  # Safe access
```

```javascript
// JavaScript object
const user = {
    name: "Blake",    // Keys don't need quotes (usually)
    age: 30,
    role: "engineer"
}

console.log(user.name)       // Dot notation (preferred)
console.log(user["name"])    // Bracket notation (same as Python)
console.log(user.email)      // undefined (property doesn't exist)
```

### Object Property Access

```javascript
const user = { name: "Blake", age: 30 }

// Dot notation (when key is a valid identifier)
user.name        // "Blake"
user.age         // 30

// Bracket notation (when key is dynamic or has special chars)
const key = "name"
user[key]        // "Blake"
user["user-role"]  // For keys with dashes

// Adding properties
user.email = "blake@example.com"
user["phone"] = "555-1234"
```

### Destructuring Objects

```python
# Python unpacking
user = {"name": "Blake", "age": 30}
name = user["name"]
age = user["age"]
```

```javascript
// JavaScript destructuring (syntactic sugar)
const user = { name: "Blake", age: 30 }

// Extract properties into variables
const { name, age } = user
console.log(name)  // "Blake"
console.log(age)   // 30

// Rename while destructuring
const { name: userName, age: userAge } = user

// Default values
const { email = "N/A" } = user
console.log(email)  // "N/A"
```

### Arrays (Like Python Lists)

```python
# Python list
numbers = [1, 2, 3, 4, 5]
numbers.append(6)
numbers[0] = 10
```

```javascript
// JavaScript array
const numbers = [1, 2, 3, 4, 5]
numbers.push(6)     // Append (array is still mutable!)
numbers[0] = 10     // Modify element
```

### Array Methods (Compare to Python)

| Python | JavaScript | Example |
|--------|------------|---------|
| `len(arr)` | `arr.length` | `[1, 2, 3].length` → 3 |
| `arr.append(x)` | `arr.push(x)` | `arr.push(4)` |
| `arr.extend([1,2])` | `arr.push(...items)` | `arr.push(...[1,2])` |
| `arr[0]` | `arr[0]` | `[1, 2][0]` → 1 |
| `arr[-1]` | `arr[arr.length - 1]` or `arr.at(-1)` | Last element |
| `arr[1:3]` | `arr.slice(1, 3)` | Slice |
| `[x*2 for x in arr]` | `arr.map(x => x*2)` | Map |
| `[x for x in arr if x>2]` | `arr.filter(x => x>2)` | Filter |
| `sum(arr)` | `arr.reduce((a,b) => a+b, 0)` | Reduce |

### Destructuring Arrays

```python
# Python unpacking
numbers = [1, 2, 3]
first = numbers[0]
second = numbers[1]
# Or
first, second, third = numbers
```

```javascript
// JavaScript destructuring
const numbers = [1, 2, 3]
const [first, second, third] = numbers

// Skip elements
const [first, , third] = numbers  // Skip second

// Rest elements
const [first, ...rest] = [1, 2, 3, 4, 5]
console.log(first)  // 1
console.log(rest)   // [2, 3, 4, 5]
```

### Spread Operator (...)

```python
# Python unpacking
list1 = [1, 2, 3]
list2 = [4, 5, 6]
combined = [*list1, *list2]  # [1, 2, 3, 4, 5, 6]

dict1 = {"a": 1, "b": 2}
dict2 = {"c": 3}
merged = {**dict1, **dict2}  # {"a": 1, "b": 2, "c": 3}
```

```javascript
// JavaScript spread (same concept!)
const list1 = [1, 2, 3]
const list2 = [4, 5, 6]
const combined = [...list1, ...list2]  // [1, 2, 3, 4, 5, 6]

const obj1 = { a: 1, b: 2 }
const obj2 = { c: 3 }
const merged = { ...obj1, ...obj2 }  // { a: 1, b: 2, c: 3 }
```

---

## Control Flow

### If/Else

```python
# Python
if x > 10:
    print("Large")
elif x > 5:
    print("Medium")
else:
    print("Small")
```

```javascript
// JavaScript
if (x > 10) {
    console.log("Large")
} else if (x > 5) {
    console.log("Medium")
} else {
    console.log("Small")
}
```

### Ternary Operator

```python
# Python
status = "active" if user.is_logged_in else "inactive"
```

```javascript
// JavaScript
const status = user.isLoggedIn ? "active" : "inactive"
```

### Loops

```python
# Python for loop
for item in items:
    print(item)

for i, item in enumerate(items):
    print(i, item)
```

```javascript
// JavaScript for...of loop (modern, preferred)
for (const item of items) {
    console.log(item)
}

// With index (less elegant than Python)
for (const [i, item] of items.entries()) {
    console.log(i, item)
}

// Traditional for loop (C-style)
for (let i = 0; i < items.length; i++) {
    console.log(items[i])
}
```

### Array Iteration Methods (Preferred in JavaScript)

```python
# Python list comprehensions and functions
doubled = [x * 2 for x in numbers]
filtered = [x for x in numbers if x > 5]
total = sum(numbers)
```

```javascript
// JavaScript array methods (more idiomatic)
const doubled = numbers.map(x => x * 2)
const filtered = numbers.filter(x => x > 5)
const total = numbers.reduce((sum, x) => sum + x, 0)

// Chaining (very common in JS)
const result = numbers
    .filter(x => x > 5)
    .map(x => x * 2)
    .reduce((sum, x) => sum + x, 0)
```

### forEach (Imperative Iteration)

```python
# Python
for item in items:
    process(item)
```

```javascript
// JavaScript
items.forEach(item => {
    process(item)
})

// With index
items.forEach((item, index) => {
    console.log(index, item)
})
```

---

## String Templates

### Python f-strings

```python
name = "Blake"
age = 30
message = f"Hello, {name}! You are {age} years old."
result = f"2 + 2 = {2 + 2}"
```

### JavaScript Template Literals

```javascript
const name = "Blake"
const age = 30
const message = `Hello, ${name}! You are ${age} years old.`
const result = `2 + 2 = ${2 + 2}`
```

**Key difference:** JavaScript uses **backticks** (`` ` ``) not quotes (`"` or `'`).

### Multiline Strings

```python
# Python
text = """
    Line 1
    Line 2
"""
```

```javascript
// JavaScript
const text = `
    Line 1
    Line 2
`
```

---

## Comparison Operators

### The == vs === Problem

**Python has one equality:**

```python
# Python
5 == 5       # True
5 == "5"     # False (different types)
```

**JavaScript has TWO equalities:**

```javascript
// JavaScript
5 == 5       // true
5 == "5"     // true (WAT?! Type coercion)

5 === 5      // true
5 === "5"    // false (strict equality, no coercion)
```

### Always Use === and !==

| Operator | Python | JavaScript (Use This) | JavaScript (Avoid) |
|----------|--------|----------------------|-------------------|
| Equal | `==` | `===` | `==` |
| Not equal | `!=` | `!==` | `!=` |

```javascript
// ALWAYS use strict equality
const x = 5
const y = "5"

x === y   // false (correct!)
x == y    // true (type coercion, confusing)

// Use === and !== exclusively
if (user.role === "admin") { }
if (value !== null) { }
```

### Truthy and Falsy Values

**Python falsy values:** `False`, `None`, `0`, `""`, `[]`, `{}`

**JavaScript falsy values:** `false`, `null`, `undefined`, `0`, `""`, `NaN`

```javascript
// Falsy in JavaScript
if (false) { }        // Won't run
if (null) { }         // Won't run
if (undefined) { }    // Won't run
if (0) { }            // Won't run
if ("") { }           // Won't run
if (NaN) { }          // Won't run

// Truthy in JavaScript (everything else)
if (true) { }         // Runs
if (42) { }           // Runs
if ("hello") { }      // Runs
if ([]) { }           // Runs (empty array is truthy!)
if ({}) { }           // Runs (empty object is truthy!)
```

**JavaScript gotcha:** Empty arrays and objects are truthy! (Unlike Python)

---

## Error Handling

### Python try/except

```python
try:
    result = risky_operation()
except ValueError as e:
    print(f"Error: {e}")
except Exception as e:
    print(f"Unknown error: {e}")
finally:
    cleanup()
```

### JavaScript try/catch

```javascript
try {
    const result = riskyOperation()
} catch (error) {
    console.log(`Error: ${error.message}`)
} finally {
    cleanup()
}
```

**Key difference:** JavaScript doesn't have multiple `catch` blocks for different error types. All errors go to one `catch`.

### Throwing Errors

```python
# Python
raise ValueError("Invalid input")
```

```javascript
// JavaScript
throw new Error("Invalid input")
```

---

## Modules

### Python Imports

```python
# Import entire module
import math
print(math.sqrt(16))

# Import specific functions
from math import sqrt, pi
print(sqrt(16))

# Import with alias
import pandas as pd
```

### JavaScript Imports (ES6 Modules)

```javascript
// Import specific exports
import { useState, useEffect } from 'react'

// Import default export
import React from 'react'

// Import with alias
import { something as alias } from './module'

// Import everything
import * as Utils from './utils'
```

### Exporting

```python
# Python (implicit exports, everything is public)
def my_function():
    return 42

MY_CONSTANT = 100
```

```javascript
// JavaScript (explicit exports)

// Named exports
export function myFunction() {
    return 42
}

export const MY_CONSTANT = 100

// Or export at end
const myFunction = () => 42
const MY_CONSTANT = 100
export { myFunction, MY_CONSTANT }

// Default export (one per file)
export default function MainComponent() {
    return "Main"
}
```

### Import/Export in Provider Search

```javascript
// web/src/types/provider.ts
export interface Provider {
    name: string
    specialty: string
}
export type ProviderStatus = 'hard_lead' | 'soft_lead'

// web/src/api/client.ts
import { getAccessToken } from '../lib/auth'

export async function apiCall(endpoint, options) {
    // ...
}

// web/src/App.tsx
import AppSearch from './app/AppSearch'  // Default export
import { ProtectedRoute } from './components/ProtectedRoute'  // Named export
```

---

## Summary: Python↔JavaScript Quick Reference

### Variables
| Python | JavaScript |
|--------|------------|
| `x = 5` | `const x = 5` (default) |
| `x = 5; x = 10` | `let x = 5; x = 10` |

### Data Types
| Python | JavaScript |
|--------|------------|
| `str` | `string` |
| `int`, `float` | `number` |
| `True`, `False` | `true`, `false` |
| `None` | `null`, `undefined` |
| `dict` | `object` |
| `list` | `Array` |

### Functions
| Python | JavaScript |
|--------|------------|
| `def func():` | `function func() {}` or `const func = () => {}` |
| `lambda x: x*2` | `x => x*2` |

### Control Flow
| Python | JavaScript |
|--------|------------|
| `if x:` | `if (x) {}` |
| `for x in arr:` | `for (const x of arr) {}` |
| `[x*2 for x in arr]` | `arr.map(x => x*2)` |

### String Formatting
| Python | JavaScript |
|--------|------------|
| `f"Hello {name}"` | `` `Hello ${name}` `` |

### Comparison
| Python | JavaScript |
|--------|------------|
| `==` | `===` (strict) |
| `!=` | `!==` (strict) |

### Error Handling
| Python | JavaScript |
|--------|------------|
| `try/except/finally` | `try/catch/finally` |
| `raise Error()` | `throw new Error()` |

### Modules
| Python | JavaScript |
|--------|------------|
| `from x import y` | `import { y } from 'x'` |
| `import x` | `import x from 'x'` (default) |

---

## Why This Matters for Provider Search

Every file in `web/src/` is JavaScript (or TypeScript, which is JavaScript with types). Understanding these fundamentals means you can:

- **Read our components:** Functions returning JSX (HTML-like syntax)
- **Understand our API calls:** Async functions using fetch
- **Follow data transformations:** Array methods like `.map()`, `.filter()`
- **Debug effectively:** Know what `const`/`let` mean, understand error messages
- **Write new code:** Follow our patterns and conventions

---

## Next Steps

Now that you understand JavaScript basics, move on to:
- **[02-javascript-async-and-the-event-loop.md](02-javascript-async-and-the-event-loop.md)** — How async code works (critical for API calls)
- **[03-typescript-essentials.md](03-typescript-essentials.md)** — Adding types to JavaScript

Or practice with:
- **[browser-tools/js-playground.html](browser-tools/js-playground.html)** — Interactive JavaScript exercises

---

**You now understand JavaScript fundamentals. Everything else builds on this foundation.**
