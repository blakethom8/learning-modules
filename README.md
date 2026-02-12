# Free Learning Modules: Web Development for Python Developers

**Three comprehensive courses on web security, frontend development, and building UIs with LLMs — designed for Python developers with zero web experience.**

---

## 📚 What's Inside

This repository contains three interconnected learning modules that take you from complete beginner to building production-ready web applications:

### 1. 🔐 [Web Security, Authentication & Session Management](./security-auth/)
**Duration:** ~6-8 hours | **Level:** Intermediate

Learn web security from first principles:
- Core vulnerabilities (XSS, CSRF, injection attacks)
- Authentication patterns (JWT, OAuth, session cookies)
- Token storage strategies and security tradeoffs
- Session management across different frameworks
- Rate limiting and abuse protection
- Production security checklists

**Why it matters:** Security isn't about following rules — it's about understanding tradeoffs and making informed decisions for your specific use case.

### 2. 🎨 [Frontend Development: JavaScript, React & Modern Web Stack](./frontend-development/)
**Duration:** ~15-20 hours | **Level:** Beginner to Intermediate

A complete ground-up guide to modern frontend development:
- **JavaScript & TypeScript** — Variables, async/await, type systems (Python→JS comparisons throughout)
- **How Browsers Work** — DOM, rendering pipeline, DevTools, CSS fundamentals
- **React Framework** — Components, hooks, state management, routing
- **Modern Stack** — Build tools (Vite), data fetching (React Query), complex UI (maps, charts)
- **Architecture** — Project structure, testing, deployment patterns

**Designed for:** Python developers with zero JavaScript experience who want to understand how modern web apps actually work.

### 3. 🤖 [Frontends for LLMs: Building UIs Without Being a Frontend Expert](./frontends-for-llms/)
**Duration:** ~4-6 hours | **Level:** Intermediate

How LLMs fundamentally change the frontend development workflow:
- **The LLM Frontend Workflow** — Using AI to generate, refine, and debug UIs
- **Command-Line Tools** — v0.dev, Bolt.new, Claude Code, Cursor
- **Single-File HTML Apps** — Rapid prototyping patterns
- **Prompt Engineering** — How to describe UIs that work
- **Rapid Prototyping** — Going from idea to working UI in minutes
- **Skills You Still Need** — What you can't delegate to LLMs (yet)
- **Building a Frontend CLI** — Scripting UI generation workflows

**The thesis:** You can build production-quality frontends without being a frontend expert — but you need to know *just enough* to guide the AI and fix what it breaks.

---

## 🎯 Who This Is For

These modules were created for:
- **Python developers** learning web development for the first time
- **Data scientists** who need to build dashboards and apps
- **Backend engineers** who want to understand the frontend
- **Technical founders** prototyping products without a frontend team
- **Anyone** who learns by understanding "why" before memorizing "how"

**Prerequisites:**
- Comfortable with Python (or any programming language)
- Basic terminal/command-line usage
- No web development experience required

---

## 🗺️ How to Navigate

### Suggested Learning Paths

**Path 1: Traditional Deep Dive (if you want to master fundamentals)**
1. Start with **Frontend Development** (module 2) — build a strong foundation
2. Move to **Web Security** (module 1) — understand authentication and security
3. Finish with **Frontends for LLMs** (module 3) — accelerate your workflow

**Path 2: LLM-First Approach (if you want to ship fast and learn iteratively)**
1. Start with **Frontends for LLMs** (module 3) — get productive immediately
2. Use **Frontend Development** (module 2) as a reference when you get stuck
3. Read **Web Security** (module 1) before shipping to production

**Path 3: Security-First (if you're building an MVP with authentication)**
1. Start with **Web Security** (module 1) — make informed security decisions early
2. Move to **Frontend Development** (module 2) — build the UI properly
3. Use **Frontends for LLMs** (module 3) to accelerate iteration

### Each Module Includes
- **Overview** — Why it matters, what you'll learn, how it connects
- **Concepts** — First-principles explanations with real-world examples
- **Code examples** — Copy-paste ready snippets
- **Interactive tools** — CLI commands, browser DevTools exercises, hands-on experiments
- **Tradeoffs** — When to use each approach and why

---

## 🛠️ Interactive Tools & Experiments

These modules aren't just reading — they include hands-on experiments:

- **Browser DevTools exercises** — Inspect live sites, debug network requests, profile performance
- **CLI security tools** — Test JWT decoding, CORS behavior, rate limiting
- **Single-file HTML apps** — Complete working apps you can modify and learn from
- **Prompt templates** — Copy-paste prompts for generating UIs with Claude/ChatGPT
- **Real-world examples** — Taken from actual production code, not toy examples

---

## 📖 Module Structure

Each module follows the same structure:

```
module-name/
├── 00-overview.md          ← Start here
├── 01-concept.md           ← Numbered lessons
├── 02-concept.md
├── ...
└── tools/                  ← Interactive scripts and examples
    ├── example-app.html
    └── cli-tool.sh
```

Read the `00-overview.md` first to understand scope, then follow the numbered lessons in order.

---

## 🧠 Learning Philosophy

These modules follow three core principles:

### 1. **First Principles Over Recipes**
We don't just tell you *what* to do — we explain *why* different approaches exist, *when* to use each, and the *tradeoffs* involved. You'll develop intuition, not just follow checklists.

### 2. **Python → Web Comparisons**
Every new concept is compared to Python equivalents:
- JavaScript promises → Python async/await
- React components → Python functions
- Webpack bundling → pip/poetry dependency management

### 3. **Real-World Context**
Examples are taken from real production code, not toy tutorials. You'll see messy tradeoffs, security decisions, and architectural patterns that actually matter.

---

## 💡 How These Modules Were Created

These modules were originally built to support the [Provider Search](https://github.com/blakethom8/provider-search) project — a FastAPI + React + Supabase app for healthcare provider search.

They were written as a learning resource for a Python developer (biomedical engineer background) with no web development experience who needed to:
- Build a production-ready frontend
- Implement secure authentication
- Use LLMs to accelerate development
- Understand *why* things work, not just copy-paste

The result: comprehensive, first-principles modules that help you build real products, not just learn syntax.

---

## 📝 Contributing

Found something confusing? Have a better explanation? Want to add a new module?

**Contributions welcome!** Please open an issue or PR. This is a living resource meant to evolve.

---

## 📄 License

MIT License — free to use, modify, and distribute. See [LICENSE](./LICENSE) for details.

---

## 🔗 More Resources

- **OpenClaw** — Local AI assistant framework ([docs](https://docs.openclaw.ai))
- **Provider Search Project** — The app these modules were built for ([repo](https://github.com/blakethom8/provider-search))
- **Claude Code** — LLM-powered coding assistant ([Anthropic](https://www.anthropic.com))

---

**Questions or feedback?** Open an issue or start a discussion!

Happy learning 🚀
