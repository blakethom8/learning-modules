#!/bin/bash

################################################################################
# Frontend Development Setup Script
# 
# Purpose: Scaffold a modern React + TypeScript + Vite project with best practices
# Target: Python developers learning frontend development
# 
# What this script does:
#   1. Checks for Node.js, npm, and pnpm
#   2. Creates a Vite + React + TypeScript project
#   3. Installs essential dependencies (React Router, Tailwind CSS)
#   4. Configures ESLint and Prettier for code quality
#   5. Sets up development environment
#
# Usage: ./frontend-setup.sh [project-name]
################################################################################

# Color codes for output (makes it educational and easier to read)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions for colored output
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

step() {
    echo -e "\n${MAGENTA}▶ $1${NC}"
}

# Get project name from argument or use default
PROJECT_NAME="${1:-my-react-app}"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Frontend Development Setup Script                  ║"
echo "║         React + TypeScript + Vite                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

info "Project name: ${PROJECT_NAME}"

################################################################################
# Step 1: Check Node.js
################################################################################

step "Checking Node.js installation..."

if ! command -v node &> /dev/null; then
    error "Node.js is not installed!"
    echo ""
    echo "  📦 Install Node.js:"
    echo "     - macOS: brew install node"
    echo "     - Ubuntu: sudo apt install nodejs npm"
    echo "     - Windows: Download from https://nodejs.org"
    echo ""
    exit 1
fi

NODE_VERSION=$(node -v)
success "Node.js installed: ${NODE_VERSION}"

# Check if Node version is recent enough (v16+)
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_MAJOR" -lt 16 ]; then
    warning "Node.js version is old (${NODE_VERSION}). Recommend v18+ for best experience."
fi

################################################################################
# Step 2: Check npm
################################################################################

step "Checking npm installation..."

if ! command -v npm &> /dev/null; then
    error "npm is not installed!"
    exit 1
fi

NPM_VERSION=$(npm -v)
success "npm installed: v${NPM_VERSION}"

################################################################################
# Step 3: Check/Install pnpm (faster package manager)
################################################################################

step "Checking pnpm installation..."

if ! command -v pnpm &> /dev/null; then
    warning "pnpm not found. It's faster than npm!"
    info "Installing pnpm globally..."
    npm install -g pnpm
    
    if [ $? -eq 0 ]; then
        success "pnpm installed successfully"
    else
        warning "pnpm installation failed. Will use npm instead."
        PACKAGE_MANAGER="npm"
    fi
else
    PNPM_VERSION=$(pnpm -v)
    success "pnpm installed: v${PNPM_VERSION}"
    PACKAGE_MANAGER="pnpm"
fi

# Use pnpm if available, fallback to npm
PACKAGE_MANAGER=${PACKAGE_MANAGER:-pnpm}
info "Using package manager: ${PACKAGE_MANAGER}"

################################################################################
# Step 4: Create Vite project
################################################################################

step "Creating Vite + React + TypeScript project..."

info "🎯 Why Vite? It's FAST! Uses native ES modules (like Python imports)"
info "🎯 Why TypeScript? Type safety (like Python type hints but enforced)"

# Check if directory already exists
if [ -d "$PROJECT_NAME" ]; then
    error "Directory '${PROJECT_NAME}' already exists!"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_NAME"
        success "Removed existing directory"
    else
        error "Aborted"
        exit 1
    fi
fi

# Create Vite project (React + TypeScript template)
if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm create vite "$PROJECT_NAME" --template react-ts
else
    npm create vite@latest "$PROJECT_NAME" -- --template react-ts
fi

if [ $? -ne 0 ]; then
    error "Failed to create Vite project"
    exit 1
fi

success "Vite project created"

# Navigate into project directory
cd "$PROJECT_NAME" || exit 1

################################################################################
# Step 5: Install base dependencies
################################################################################

step "Installing base dependencies..."

info "This might take a minute (downloading ~200MB of packages)"
info "🐍 Think of this like 'pip install -r requirements.txt'"

if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm install
else
    npm install
fi

success "Base dependencies installed"

################################################################################
# Step 6: Install React Router (for navigation)
################################################################################

step "Installing React Router..."

info "React Router = Flask/Django URL routing for the frontend"

if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm add react-router-dom
else
    npm install react-router-dom
fi

success "React Router installed"

################################################################################
# Step 7: Install and configure Tailwind CSS
################################################################################

step "Installing Tailwind CSS..."

info "Tailwind = Utility-first CSS framework (think Bootstrap but composable)"

# Install Tailwind and its dependencies
if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm add -D tailwindcss postcss autoprefixer
else
    npm install -D tailwindcss postcss autoprefixer
fi

# Initialize Tailwind config
npx tailwindcss init -p

success "Tailwind CSS installed"

# Configure Tailwind content paths
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

success "Tailwind config created"

# Add Tailwind directives to CSS
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom global styles */
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

success "Tailwind directives added to index.css"

################################################################################
# Step 8: Configure ESLint
################################################################################

step "Configuring ESLint (code linter)..."

info "ESLint = Like flake8/pylint for JavaScript/TypeScript"

# ESLint should already be installed by Vite, just configure it
cat > .eslintrc.cjs << 'EOF'
module.exports = {
  root: true,
  env: { browser: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
  ],
  ignorePatterns: ['dist', '.eslintrc.cjs'],
  parser: '@typescript-eslint/parser',
  plugins: ['react-refresh'],
  rules: {
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true },
    ],
    // Customize rules as needed
    '@typescript-eslint/no-unused-vars': ['warn'],
    '@typescript-eslint/no-explicit-any': ['warn'],
  },
}
EOF

success "ESLint configured"

################################################################################
# Step 9: Configure Prettier (code formatter)
################################################################################

step "Installing and configuring Prettier..."

info "Prettier = Like black for Python (automatic code formatting)"

# Install Prettier
if [ "$PACKAGE_MANAGER" == "pnpm" ]; then
    pnpm add -D prettier eslint-config-prettier
else
    npm install -D prettier eslint-config-prettier
fi

# Create Prettier config
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
EOF

success "Prettier configured"

# Add format script to package.json
info "Adding format script to package.json..."

# Use a more portable way to modify package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts.format = 'prettier --write \"src/**/*.{ts,tsx,js,jsx,css,md}\"';
pkg.scripts.lint = 'eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

success "Format and lint scripts added"

################################################################################
# Step 10: Create helpful README
################################################################################

step "Creating project README..."

cat > README.md << EOF
# ${PROJECT_NAME}

A modern React + TypeScript + Vite project created with the frontend setup script.

## 🎯 For Python Developers

This project uses:
- **React**: Component-based UI (think: classes/functions that return HTML)
- **TypeScript**: JavaScript with types (like Python type hints, but enforced)
- **Vite**: Fast build tool (like running a dev server instantly)
- **Tailwind CSS**: Utility CSS framework
- **React Router**: Client-side routing

## 📦 Package Manager

Using: \`${PACKAGE_MANAGER}\`

Think of \`package.json\` as your \`requirements.txt\` and \`node_modules/\` as your \`.venv/\`.

## 🚀 Getting Started

### Development Server
\`\`\`bash
${PACKAGE_MANAGER} run dev
# Opens http://localhost:5173 (like Flask's development server)
\`\`\`

### Build for Production
\`\`\`bash
${PACKAGE_MANAGER} run build
# Creates optimized bundle in dist/
\`\`\`

### Preview Production Build
\`\`\`bash
${PACKAGE_MANAGER} run preview
\`\`\`

## 🎨 Code Quality

### Format Code (like black)
\`\`\`bash
${PACKAGE_MANAGER} run format
\`\`\`

### Lint Code (like flake8)
\`\`\`bash
${PACKAGE_MANAGER} run lint
\`\`\`

## 📁 Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/
│   ├── App.tsx          # Main app component
│   ├── main.tsx         # Entry point (like if __name__ == '__main__')
│   ├── index.css        # Global styles
│   └── assets/          # Images, fonts, etc.
├── public/              # Static files
├── index.html           # HTML template
├── package.json         # Dependencies (like requirements.txt)
├── tsconfig.json        # TypeScript config
├── vite.config.ts       # Vite config
└── tailwind.config.js   # Tailwind config
\`\`\`

## 🔗 Useful Resources

- [React Docs](https://react.dev) - Official React documentation
- [TypeScript Handbook](https://www.typescriptlang.org/docs/) - Learn TypeScript
- [Vite Guide](https://vitejs.dev/guide/) - Vite documentation
- [Tailwind CSS](https://tailwindcss.com/docs) - Tailwind documentation

## 💡 Tips for Python Developers

1. **Components = Classes/Functions**: React components are just functions that return JSX
2. **Props = Arguments**: Passing data to components is like function arguments
3. **State = Instance Variables**: Component state is like \`self.value\` in Python
4. **Hooks = Decorators/Context Managers**: useEffect, useState, etc. are like Python decorators
5. **JSX = Template Strings**: \`<div>Hello</div>\` is syntactic sugar for function calls

## 🐛 Common Issues

### Port 5173 already in use
\`\`\`bash
# Kill the process using the port
lsof -ti:5173 | xargs kill -9
\`\`\`

### Node modules corrupted
\`\`\`bash
rm -rf node_modules
${PACKAGE_MANAGER} install
\`\`\`

---

**Happy coding!** 🚀
EOF

success "README.md created"

################################################################################
# Step 11: Create a sample component to get started
################################################################################

step "Creating sample components..."

# Create a components directory
mkdir -p src/components

# Create a sample Counter component (shows state management)
cat > src/components/Counter.tsx << 'EOF'
import { useState } from 'react';

/**
 * Counter Component
 * 
 * Demonstrates:
 * - useState hook (like instance variables in Python)
 * - Event handlers (like button click callbacks)
 * - Conditional rendering
 */
export default function Counter() {
  // useState = like self.count in a Python class
  const [count, setCount] = useState(0);

  // Event handlers (like def on_click(self): in Python)
  const increment = () => setCount(count + 1);
  const decrement = () => setCount(count - 1);
  const reset = () => setCount(0);

  return (
    <div className="p-6 max-w-md mx-auto bg-white rounded-xl shadow-lg">
      <h2 className="text-2xl font-bold text-gray-800 mb-4">Counter Example</h2>
      
      <div className="text-6xl font-bold text-blue-600 text-center my-8">
        {count}
      </div>

      <div className="flex gap-2">
        <button
          onClick={decrement}
          className="flex-1 bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded"
        >
          -
        </button>
        <button
          onClick={reset}
          className="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded"
        >
          Reset
        </button>
        <button
          onClick={increment}
          className="flex-1 bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
        >
          +
        </button>
      </div>

      <p className="text-gray-600 text-sm mt-4">
        💡 This uses <code className="bg-gray-100 px-1 rounded">useState</code> 
        - similar to instance variables in Python classes
      </p>
    </div>
  );
}
EOF

# Update App.tsx to use the Counter component
cat > src/App.tsx << 'EOF'
import Counter from './components/Counter';

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <header className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            🚀 Welcome to React + TypeScript!
          </h1>
          <p className="text-xl text-gray-600">
            A modern frontend stack for Python developers
          </p>
        </header>

        <main className="space-y-8">
          <Counter />
          
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-800 mb-4">
              🐍 Next Steps for Python Developers
            </h2>
            <ul className="list-disc list-inside space-y-2 text-gray-700">
              <li>Edit <code className="bg-gray-100 px-2 py-1 rounded">src/App.tsx</code> to change this page</li>
              <li>Create new components in <code className="bg-gray-100 px-2 py-1 rounded">src/components/</code></li>
              <li>Add routes with React Router (already installed!)</li>
              <li>Style with Tailwind CSS utility classes</li>
              <li>Open browser DevTools to see console.log() output</li>
            </ul>
          </div>
        </main>

        <footer className="text-center mt-12 text-gray-600">
          <p>Built with ⚛️ React + TypeScript + Vite + Tailwind CSS</p>
        </footer>
      </div>
    </div>
  );
}

export default App;
EOF

success "Sample components created"

################################################################################
# Final Steps
################################################################################

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   ✅ Setup Complete!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

info "Project created in: $(pwd)"
echo ""

echo -e "${CYAN}🚀 To get started:${NC}"
echo ""
echo -e "   cd ${PROJECT_NAME}"
echo -e "   ${PACKAGE_MANAGER} run dev"
echo ""
echo -e "${CYAN}📖 Useful commands:${NC}"
echo ""
echo -e "   ${PACKAGE_MANAGER} run dev      - Start development server"
echo -e "   ${PACKAGE_MANAGER} run build    - Build for production"
echo -e "   ${PACKAGE_MANAGER} run lint     - Check code quality"
echo -e "   ${PACKAGE_MANAGER} run format   - Format code with Prettier"
echo ""
echo -e "${YELLOW}💡 Pro tip: Install the React DevTools browser extension!${NC}"
echo ""

success "Happy coding! 🎉"
