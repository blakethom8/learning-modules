# 14. Testing Frontend Code

**Goal:** Understand why and how to test frontend applications, with practical examples from Provider Search.

---

## Why Test Frontend Code?

You already know why testing matters from Python:

```python
def calculate_discount(price, discount_pct):
    return price * (1 - discount_pct / 100)

# Without tests, you don't know:
# - Does it handle 0?
# - Does it handle 100%?
# - Does it handle negative numbers?
# - Does it round correctly?

def test_calculate_discount():
    assert calculate_discount(100, 10) == 90
    assert calculate_discount(100, 0) == 100
    assert calculate_discount(100, 100) == 0
```

Frontend is the same, but with extra concerns:

1. **Does the UI render correctly?**
   - Component shows the right text
   - Buttons are enabled/disabled correctly
   - Loading states appear

2. **Do user interactions work?**
   - Clicking a button calls the right function
   - Typing in an input updates state
   - Form submission triggers API call

3. **Does data flow correctly?**
   - API responses update the UI
   - State changes cause re-renders
   - Errors display properly

4. **Do components integrate?**
   - Parent and child communicate
   - Context provides correct values
   - Navigation works

---

## Types of Frontend Tests

### 1. Unit Tests (Fast, Isolated)

Test individual functions or components in isolation.

```typescript
// utils/formatting.test.ts
import { formatPhoneNumber } from './formatting'

describe('formatPhoneNumber', () => {
  it('formats 10-digit numbers', () => {
    expect(formatPhoneNumber('4155551234')).toBe('(415) 555-1234')
  })
  
  it('returns input unchanged if invalid', () => {
    expect(formatPhoneNumber('invalid')).toBe('invalid')
  })
})
```

**Python equivalent:**
```python
# test_formatting.py
from utils.formatting import format_phone_number

def test_format_phone_number():
    assert format_phone_number('4155551234') == '(415) 555-1234'

def test_format_phone_number_invalid():
    assert format_phone_number('invalid') == 'invalid'
```

### 2. Integration Tests (Medium Speed, Multiple Units)

Test how components work together.

```typescript
// AppSearch.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import AppSearch from './AppSearch'
import * as searchApi from '../api/search'

jest.mock('../api/search')

test('displays search results after user searches', async () => {
  // Mock API response
  searchApi.searchProviders.mockResolvedValue([
    { id: '1', name: 'Dr. Smith' },
    { id: '2', name: 'Dr. Jones' },
  ])
  
  // Render component
  render(<AppSearch />)
  
  // User types and clicks search
  await userEvent.type(screen.getByLabelText('Specialty'), 'cardiologist')
  await userEvent.click(screen.getByText('Search'))
  
  // Results appear
  await waitFor(() => {
    expect(screen.getByText('Dr. Smith')).toBeInTheDocument()
    expect(screen.getByText('Dr. Jones')).toBeInTheDocument()
  })
})
```

**Python equivalent:**
```python
# test_search_view.py
from flask import Flask
from unittest.mock import patch

def test_search_results(client):
    with patch('services.search.search_providers') as mock_search:
        mock_search.return_value = [
            {'id': '1', 'name': 'Dr. Smith'},
            {'id': '2', 'name': 'Dr. Jones'},
        ]
        
        response = client.post('/search', json={'specialty': 'cardiologist'})
        
        assert response.status_code == 200
        assert 'Dr. Smith' in response.text
        assert 'Dr. Jones' in response.text
```

### 3. End-to-End (E2E) Tests (Slow, Full System)

Test the entire application as a user would, in a real browser.

```typescript
// e2e/search.spec.ts (Playwright)
import { test, expect } from '@playwright/test'

test('user can search for providers', async ({ page }) => {
  await page.goto('http://localhost:5173')
  
  await page.fill('[name="specialty"]', 'cardiologist')
  await page.fill('[name="location"]', 'San Francisco')
  await page.click('text=Search')
  
  await expect(page.locator('.provider-card')).toHaveCount(10)
  await expect(page.locator('text=Dr. Smith')).toBeVisible()
})
```

**Python equivalent:**
```python
# test_search_e2e.py (Selenium)
from selenium import webdriver
from selenium.webdriver.common.by import By

def test_user_can_search_providers():
    driver = webdriver.Chrome()
    driver.get('http://localhost:5000')
    
    driver.find_element(By.NAME, 'specialty').send_keys('cardiologist')
    driver.find_element(By.NAME, 'location').send_keys('San Francisco')
    driver.find_element(By.CSS_SELECTOR, 'button[type="submit"]').click()
    
    results = driver.find_elements(By.CLASS_NAME, 'provider-card')
    assert len(results) == 10
    assert 'Dr. Smith' in driver.page_source
    
    driver.quit()
```

---

## Testing Stack: Provider Search

Provider Search uses:

- **Vitest** — Test runner (like pytest)
- **React Testing Library** — Render and interact with components
- **jsdom** — Simulates browser environment (no real browser needed)

### Vitest vs Jest

Both are JavaScript test runners. Vitest is newer and faster.

```typescript
// Vitest (what Provider Search uses)
import { describe, it, expect } from 'vitest'

describe('my feature', () => {
  it('does something', () => {
    expect(2 + 2).toBe(4)
  })
})
```

**Python equivalent:**
```python
# pytest
def test_my_feature():
    assert 2 + 2 == 4
```

---

## Testing Components: React Testing Library

### Philosophy: Test Like a User

Don't test implementation details. Test what the user sees and does.

**Bad (testing implementation):**
```typescript
// ❌ Don't do this
test('component has correct state', () => {
  const wrapper = shallow(<MyComponent />)
  expect(wrapper.state().count).toBe(0)
})
```

**Good (testing behavior):**
```typescript
// ✅ Do this
test('displays count starting at 0', () => {
  render(<MyComponent />)
  expect(screen.getByText('Count: 0')).toBeInTheDocument()
})
```

### Basic Component Test

```typescript
// components/StatusIndicator.test.tsx
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import StatusIndicator from './StatusIndicator'

describe('StatusIndicator', () => {
  it('shows pending status with spinner', () => {
    render(<StatusIndicator status="pending" message="Loading..." />)
    
    expect(screen.getByText(/Loading/)).toBeInTheDocument()
    expect(screen.getByText(/⏳/)).toBeInTheDocument()
  })
  
  it('shows complete status with checkmark', () => {
    render(<StatusIndicator status="complete" message="Done" />)
    
    expect(screen.getByText(/Done/)).toBeInTheDocument()
    expect(screen.getByText(/✅/)).toBeInTheDocument()
  })
  
  it('shows error status with X', () => {
    render(<StatusIndicator status="error" message="Failed" />)
    
    expect(screen.getByText(/Failed/)).toBeInTheDocument()
    expect(screen.getByText(/❌/)).toBeInTheDocument()
  })
})
```

**Python equivalent:**
```python
# test_status_indicator.py
from bs4 import BeautifulSoup

def test_status_indicator_pending():
    html = render_template('status_indicator.html', status='pending', message='Loading...')
    soup = BeautifulSoup(html, 'html.parser')
    
    assert 'Loading' in soup.text
    assert '⏳' in soup.text

def test_status_indicator_complete():
    html = render_template('status_indicator.html', status='complete', message='Done')
    soup = BeautifulSoup(html, 'html.parser')
    
    assert 'Done' in soup.text
    assert '✅' in soup.text
```

### Testing User Interactions

```typescript
// components/SearchBar.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import SearchBar from './SearchBar'

describe('SearchBar', () => {
  it('calls onSearch when form is submitted', async () => {
    const onSearch = vi.fn()  // Mock function (like unittest.mock.Mock)
    const user = userEvent.setup()
    
    render(<SearchBar onSearch={onSearch} />)
    
    // User types
    await user.type(screen.getByLabelText('Specialty'), 'cardiologist')
    await user.type(screen.getByLabelText('Location'), 'San Francisco')
    
    // User clicks submit
    await user.click(screen.getByRole('button', { name: /search/i }))
    
    // Callback was called with correct args
    expect(onSearch).toHaveBeenCalledWith({
      specialty: 'cardiologist',
      location: 'San Francisco',
    })
  })
  
  it('shows validation error if specialty is empty', async () => {
    const onSearch = vi.fn()
    const user = userEvent.setup()
    
    render(<SearchBar onSearch={onSearch} />)
    
    // Submit without typing
    await user.click(screen.getByRole('button', { name: /search/i }))
    
    // Error message appears, callback not called
    expect(screen.getByText(/specialty is required/i)).toBeInTheDocument()
    expect(onSearch).not.toHaveBeenCalled()
  })
})
```

**Python equivalent:**
```python
# test_search_form.py
from unittest.mock import Mock

def test_search_form_submission(client):
    on_search = Mock()
    
    # Simulate form submission
    response = client.post('/search', data={
        'specialty': 'cardiologist',
        'location': 'San Francisco',
    })
    
    # Check callback was called (in real code, this would be a signal or event)
    assert response.status_code == 200
    # In practice, you'd check that the search function was called

def test_search_form_validation(client):
    response = client.post('/search', data={
        'specialty': '',  # Empty
        'location': 'San Francisco',
    })
    
    assert 'Specialty is required' in response.text
```

---

## Testing Hooks

Hooks can't be called outside components, so we use `renderHook` from React Testing Library.

```typescript
// hooks/useProviderSearch.test.ts
import { renderHook, waitFor } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { useProviderSearch } from './useProviderSearch'
import * as searchApi from '../api/search'

vi.mock('../api/search')

describe('useProviderSearch', () => {
  it('fetches providers on mount', async () => {
    const mockResults = [
      { id: '1', name: 'Dr. Smith' },
      { id: '2', name: 'Dr. Jones' },
    ]
    searchApi.searchProviders.mockResolvedValue(mockResults)
    
    const { result } = renderHook(() => useProviderSearch({
      specialty: 'cardiologist',
      location: 'SF',
    }))
    
    // Initially loading
    expect(result.current.loading).toBe(true)
    expect(result.current.results).toEqual([])
    
    // Wait for data to load
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })
    
    // Results populated
    expect(result.current.results).toEqual(mockResults)
    expect(result.current.error).toBeNull()
  })
  
  it('sets error state if API call fails', async () => {
    searchApi.searchProviders.mockRejectedValue(new Error('Network error'))
    
    const { result } = renderHook(() => useProviderSearch({
      specialty: 'cardiologist',
      location: 'SF',
    }))
    
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })
    
    expect(result.current.error).toBe('Network error')
    expect(result.current.results).toEqual([])
  })
})
```

**Python equivalent:**
```python
# test_provider_search_service.py
from unittest.mock import patch, Mock

def test_provider_search_service_success():
    with patch('api.search.search_providers') as mock_search:
        mock_search.return_value = [
            {'id': '1', 'name': 'Dr. Smith'},
            {'id': '2', 'name': 'Dr. Jones'},
        ]
        
        service = ProviderSearchService(specialty='cardiologist', location='SF')
        service.execute()
        
        assert service.loading is False
        assert len(service.results) == 2
        assert service.error is None

def test_provider_search_service_failure():
    with patch('api.search.search_providers') as mock_search:
        mock_search.side_effect = Exception('Network error')
        
        service = ProviderSearchService(specialty='cardiologist', location='SF')
        service.execute()
        
        assert service.loading is False
        assert service.results == []
        assert service.error == 'Network error'
```

---

## Mocking API Calls

You don't want tests to hit real APIs:
- Slow
- Unreliable (network issues)
- May cost money
- Hard to test error cases

Instead, **mock** the API module.

```typescript
// AppSearch.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import AppSearch from './AppSearch'
import * as searchApi from '../api/search'

// Mock the entire module
vi.mock('../api/search')

describe('AppSearch', () => {
  beforeEach(() => {
    // Reset mocks before each test
    vi.clearAllMocks()
  })
  
  it('displays search results', async () => {
    // Set up mock to return specific data
    searchApi.searchProviders.mockResolvedValue([
      { id: '1', name: 'Dr. Smith', specialty: 'Cardiology' },
    ])
    
    render(<AppSearch />)
    
    // Trigger search
    await userEvent.type(screen.getByLabelText('Specialty'), 'cardiology')
    await userEvent.click(screen.getByRole('button', { name: /search/i }))
    
    // Wait for results
    await waitFor(() => {
      expect(screen.getByText('Dr. Smith')).toBeInTheDocument()
    })
    
    // Verify API was called correctly
    expect(searchApi.searchProviders).toHaveBeenCalledWith({
      specialty: 'cardiology',
      location: expect.any(String),
    })
  })
  
  it('shows error message if search fails', async () => {
    // Mock API to reject
    searchApi.searchProviders.mockRejectedValue(new Error('Server error'))
    
    render(<AppSearch />)
    
    await userEvent.click(screen.getByRole('button', { name: /search/i }))
    
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument()
    })
  })
})
```

**Python equivalent:**
```python
# test_search_view.py
from unittest.mock import patch, Mock

@patch('api.search.search_providers')
def test_search_view_displays_results(mock_search, client):
    mock_search.return_value = [
        {'id': '1', 'name': 'Dr. Smith', 'specialty': 'Cardiology'},
    ]
    
    response = client.post('/search', json={'specialty': 'cardiology'})
    
    assert response.status_code == 200
    assert 'Dr. Smith' in response.text
    mock_search.assert_called_once_with(specialty='cardiology', location=ANY)

@patch('api.search.search_providers')
def test_search_view_shows_error(mock_search, client):
    mock_search.side_effect = Exception('Server error')
    
    response = client.post('/search', json={'specialty': 'cardiology'})
    
    assert 'error' in response.text.lower()
```

---

## Real Tests from Provider Search

Let's examine actual tests from the codebase.

### Example 1: App.test.tsx

```typescript
// web/src/__tests__/App.test.tsx
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import App from '../App'

describe('App', () => {
  it('renders search page on root path', () => {
    render(
      <MemoryRouter initialEntries={['/']}>
        <App />
      </MemoryRouter>
    )
    
    // Check that search UI is present
    expect(screen.getByPlaceholderText(/specialty/i)).toBeInTheDocument()
  })
  
  it('redirects to login for protected routes when not authenticated', () => {
    render(
      <MemoryRouter initialEntries={['/lists']}>
        <App />
      </MemoryRouter>
    )
    
    // Should see login page
    expect(screen.getByRole('heading', { name: /login/i })).toBeInTheDocument()
  })
})
```

**Key points:**
- Use `MemoryRouter` to test routing without a real browser
- `initialEntries` simulates navigating to a specific URL
- Tests verify that the right component renders for each route

### Example 2: useProviderSearch.test.ts

```typescript
// web/src/__tests__/useProviderSearch.test.ts
import { renderHook, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useProviderSearch } from '../hooks/useProviderSearch'
import * as searchApi from '../api/search'

vi.mock('../api/search')

describe('useProviderSearch', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  
  it('returns empty results initially', () => {
    const { result } = renderHook(() => useProviderSearch(null))
    
    expect(result.current.results).toEqual([])
    expect(result.current.loading).toBe(false)
    expect(result.current.error).toBeNull()
  })
  
  it('searches when params are provided', async () => {
    const mockResults = [{ id: '1', name: 'Dr. Smith' }]
    searchApi.searchProviders.mockResolvedValue(mockResults)
    
    const { result } = renderHook(() => useProviderSearch({
      specialty: 'cardiology',
      location: 'SF',
    }))
    
    expect(result.current.loading).toBe(true)
    
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
    })
    
    expect(result.current.results).toEqual(mockResults)
  })
  
  it('refetches when params change', async () => {
    const { result, rerender } = renderHook(
      ({ params }) => useProviderSearch(params),
      { initialProps: { params: { specialty: 'cardiology', location: 'SF' } } }
    )
    
    await waitFor(() => expect(result.current.loading).toBe(false))
    
    // Change params
    rerender({ params: { specialty: 'neurology', location: 'SF' } })
    
    expect(result.current.loading).toBe(true)
    await waitFor(() => expect(result.current.loading).toBe(false))
    
    // API called again with new params
    expect(searchApi.searchProviders).toHaveBeenCalledTimes(2)
  })
})
```

**Key points:**
- `renderHook` lets you test hooks in isolation
- `waitFor` handles async operations (API calls)
- `rerender` simulates prop changes

### Example 3: AuthDebugPanel.test.tsx

```typescript
// web/src/__tests__/AuthDebugPanel.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import AuthDebugPanel from '../dev/AuthDebugPanel'
import { AuthProvider } from '../contexts/AuthContext'

describe('AuthDebugPanel', () => {
  it('shows login form when not authenticated', () => {
    render(
      <AuthProvider>
        <AuthDebugPanel />
      </AuthProvider>
    )
    
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
  })
  
  it('calls login when form is submitted', async () => {
    const user = userEvent.setup()
    
    render(
      <AuthProvider>
        <AuthDebugPanel />
      </AuthProvider>
    )
    
    await user.type(screen.getByLabelText(/email/i), 'test@example.com')
    await user.type(screen.getByLabelText(/password/i), 'password123')
    await user.click(screen.getByRole('button', { name: /login/i }))
    
    // Would verify API call here
  })
})
```

**Key points:**
- Wrap component in providers it needs (AuthProvider)
- Simulate full user interaction (type, click)
- Test what the user sees, not implementation

---

## Integration vs Unit vs E2E

| Type | Speed | Scope | Example |
|------|-------|-------|---------|
| **Unit** | ⚡ Fast | Single function/component | `formatPhoneNumber('4155551234')` |
| **Integration** | 🐢 Medium | Multiple components | `AppSearch` with mocked API |
| **E2E** | 🐌 Slow | Entire app + backend | Playwright test in real browser |

### When to use each:

**Unit tests:**
- Pure functions (utilities, formatters)
- Individual components (buttons, inputs)
- Hooks in isolation

**Integration tests:**
- Pages with multiple components
- Components that fetch data
- User flows within one page

**E2E tests:**
- Critical user paths (signup, purchase)
- Cross-page workflows
- Real browser behavior (CSS, JavaScript events)

### Test Pyramid

```
        /\      ← E2E (few, slow, expensive)
       /  \
      /    \
     /------\   ← Integration (some, medium speed)
    /        \
   /          \
  /------------\ ← Unit (many, fast, cheap)
```

**Rule of thumb:**
- 70% unit tests
- 20% integration tests
- 10% E2E tests

---

## Running Tests

### Vitest CLI

```bash
# Run all tests
npm test

# Run in watch mode (re-runs on file change)
npm test -- --watch

# Run specific file
npm test -- App.test.tsx

# Run with coverage
npm test -- --coverage
```

**Python equivalent:**
```bash
# Run all tests
pytest

# Run in watch mode
pytest-watch

# Run specific file
pytest tests/test_app.py

# Run with coverage
pytest --cov=app
```

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,           // No need to import describe/it/expect
    environment: 'jsdom',    // Simulate browser
    setupFiles: './src/__tests__/setup.ts',  // Run before tests
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      exclude: ['node_modules/', '__tests__/'],
    },
  },
})
```

**Python equivalent:**
```ini
# pytest.ini or setup.cfg
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --cov=app --cov-report=html
```

---

## Test Setup File

```typescript
// src/__tests__/setup.ts
import '@testing-library/jest-dom'  // Adds matchers like toBeInTheDocument
import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

// Clean up after each test
afterEach(() => {
  cleanup()
})

// Mock environment variables
vi.stubEnv('VITE_API_URL', 'http://localhost:8000')

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
}
global.localStorage = localStorageMock as any
```

**Python equivalent:**
```python
# conftest.py (pytest)
import pytest
from unittest.mock import Mock

@pytest.fixture(autouse=True)
def setup_env(monkeypatch):
    monkeypatch.setenv('API_URL', 'http://localhost:8000')

@pytest.fixture
def mock_cache():
    return Mock()

@pytest.fixture(autouse=True)
def cleanup():
    yield
    # Teardown code here
```

---

## Common Matchers

```typescript
// Equality
expect(value).toBe(5)                   // Exact equality (===)
expect(value).toEqual({ a: 1 })         // Deep equality
expect(value).not.toBe(null)

// Truthiness
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(value).toBeNull()
expect(value).toBeUndefined()

// Numbers
expect(value).toBeGreaterThan(10)
expect(value).toBeLessThan(100)
expect(value).toBeCloseTo(0.3, 1)       // Floating point

// Strings
expect(text).toMatch(/hello/i)
expect(text).toContain('world')

// Arrays
expect(array).toContain('item')
expect(array).toHaveLength(5)

// Objects
expect(obj).toHaveProperty('name')
expect(obj).toMatchObject({ name: 'Alice' })

// DOM (from @testing-library/jest-dom)
expect(element).toBeInTheDocument()
expect(element).toBeVisible()
expect(element).toHaveTextContent('Hello')
expect(element).toHaveAttribute('href', '/about')
expect(button).toBeDisabled()
```

**Python equivalent:**
```python
# pytest assertions
assert value == 5
assert value == {'a': 1}
assert value is not None

assert value  # Truthy
assert not value  # Falsy
assert value is None
assert value is undefined  # (doesn't exist in Python)

assert value > 10
assert value < 100
assert abs(value - 0.3) < 0.1

assert 'hello' in text.lower()
assert 'world' in text

assert 'item' in array
assert len(array) == 5

assert hasattr(obj, 'name')
assert obj.name == 'Alice'

# For DOM, use BeautifulSoup
soup = BeautifulSoup(html, 'html.parser')
assert soup.find(text='Hello') is not None
```

---

## Playwright & Cypress (E2E Tools)

### Playwright (Recommended)

```typescript
// e2e/search.spec.ts
import { test, expect } from '@playwright/test'

test('user can search for providers', async ({ page }) => {
  // Navigate to app
  await page.goto('http://localhost:5173')
  
  // Fill out search form
  await page.fill('[name="specialty"]', 'cardiologist')
  await page.fill('[name="location"]', 'San Francisco, CA')
  await page.click('button:has-text("Search")')
  
  // Wait for results
  await page.waitForSelector('.provider-card')
  
  // Verify results
  const cards = await page.locator('.provider-card').count()
  expect(cards).toBeGreaterThan(0)
  
  // Click on first result
  await page.click('.provider-card:first-child')
  
  // Modal opens
  await expect(page.locator('.provider-modal')).toBeVisible()
})

test('displays error for invalid location', async ({ page }) => {
  await page.goto('http://localhost:5173')
  
  await page.fill('[name="specialty"]', 'cardiologist')
  await page.fill('[name="location"]', 'Invalid Location')
  await page.click('button:has-text("Search")')
  
  // Error message appears
  await expect(page.locator('.error-message')).toBeVisible()
})
```

**Python equivalent (Selenium):**
```python
# test_search_e2e.py
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def test_user_can_search_providers():
    driver = webdriver.Chrome()
    driver.get('http://localhost:5173')
    
    driver.find_element(By.NAME, 'specialty').send_keys('cardiologist')
    driver.find_element(By.NAME, 'location').send_keys('San Francisco, CA')
    driver.find_element(By.CSS_SELECTOR, 'button').click()
    
    # Wait for results
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, 'provider-card'))
    )
    
    cards = driver.find_elements(By.CLASS_NAME, 'provider-card')
    assert len(cards) > 0
    
    cards[0].click()
    
    # Modal opens
    modal = WebDriverWait(driver, 5).until(
        EC.visibility_of_element_located((By.CLASS_NAME, 'provider-modal'))
    )
    assert modal.is_displayed()
    
    driver.quit()
```

### Cypress

```typescript
// cypress/e2e/search.cy.ts
describe('Provider Search', () => {
  it('allows searching for providers', () => {
    cy.visit('/')
    
    cy.get('[name="specialty"]').type('cardiologist')
    cy.get('[name="location"]').type('San Francisco, CA')
    cy.contains('button', 'Search').click()
    
    cy.get('.provider-card').should('have.length.greaterThan', 0)
    
    cy.get('.provider-card').first().click()
    cy.get('.provider-modal').should('be.visible')
  })
})
```

---

## Best Practices

### 1. Test Behavior, Not Implementation

**Bad:**
```typescript
it('calls useEffect', () => {
  // Testing React internals
})
```

**Good:**
```typescript
it('displays search results', () => {
  // Testing what user sees
})
```

### 2. Use Descriptive Test Names

**Bad:**
```typescript
it('works', () => { ... })
```

**Good:**
```typescript
it('displays error message when API returns 500', () => { ... })
```

### 3. Arrange-Act-Assert Pattern

```typescript
it('adds provider to list', () => {
  // Arrange
  const provider = { id: '1', name: 'Dr. Smith' }
  render(<ProviderList />)
  
  // Act
  await user.click(screen.getByRole('button', { name: /add/i }))
  
  // Assert
  expect(screen.getByText('Dr. Smith')).toBeInTheDocument()
})
```

### 4. Keep Tests Independent

Each test should be able to run alone, in any order.

**Bad:**
```typescript
let results
it('searches', () => {
  results = searchProviders()  // Other tests depend on this
})
it('filters results', () => {
  filterResults(results)  // ❌ Depends on previous test
})
```

**Good:**
```typescript
it('searches', () => {
  const results = searchProviders()
  expect(results).toHaveLength(10)
})
it('filters results', () => {
  const results = searchProviders()  // ✅ Independent setup
  const filtered = filterResults(results)
  expect(filtered).toHaveLength(5)
})
```

### 5. Don't Test Third-Party Libraries

Don't test that React Router works. Trust that it does.

**Bad:**
```typescript
it('react router navigates', () => {
  // Testing React Router itself
})
```

**Good:**
```typescript
it('shows lists page when user navigates to /lists', () => {
  // Testing your app's behavior with React Router
})
```

---

## Summary

**Why test:**
- Catch bugs early
- Refactor with confidence
- Document expected behavior
- Prevent regressions

**Test types:**
- **Unit:** Individual functions/components
- **Integration:** Multiple components together
- **E2E:** Full app in real browser

**Tools:**
- **Vitest:** Test runner
- **React Testing Library:** Render and interact with components
- **Playwright/Cypress:** E2E testing

**Key principles:**
- Test behavior, not implementation
- Mock external dependencies
- Keep tests independent
- Use descriptive names

**Next:** You now understand testing. Let's explore building frontend apps without frameworks (guide 15).
