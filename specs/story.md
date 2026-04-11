# conflict.nvim — Roadmap

## Core Problem

Both reviewers agree: the plugin is a solid re-implementation but lacks a **differentiating reason to switch** from `git-conflict.nvim`.

---

## Phase 1 — UX Foundation (v0.2)

**Goal:** Close the gap with existing plugins, stop losing users on basics.

- **Quickfix/Telescope integration** — `<leader>cl` to list all conflicting files project-wide with conflict counts, jump to line
- **Event system** — emit autocmd events (`ConflictDetected`, `ConflictResolved`) for composability
- **Mouse-clickable action bar** — make the virtual text `[Accept Ours] [Accept Theirs] [Accept Both]` respond to mouse clicks (not just keymaps)
- **Lazy dependencies** — core features (highlight, navigate, accept) must work with zero deps; diff views only load `diffview.nvim` on demand

---

## Phase 2 — Killer Feature: Works Everywhere (v0.3)

**Goal:** Capture the niche `git-conflict.nvim` misses.

- **Detect conflicts outside Git merge state** — work on any file with `<<<<<<<` markers (AI-generated conflicts, manually pasted code, stash pop artifacts)
- `detect_conflict_anywhere = true` config option
- Directly addresses the Reddit community complaint: "git-conflict.nvim doesn't detect if not in merge state"

---

## Phase 3 — Smart Resolve (v0.4)

**Goal:** Upgrade from "dumb accept" to "intelligent merge".

- **Trivial conflict auto-resolve** — detect whitespace-only, trailing comma, formatter diffs and resolve silently or with `<leader>cx`
- **Live preview floating window** — show merged result before committing to "Accept Both"
- **Pattern-aware merge hints** — detect import blocks, JSON keys, array merges and suggest combined result

---

## Phase 4 — AI Power-Up (v0.5)

**Goal:** Make AI the plugin's signature feature.

- **Context-aware AI suggestions** — send surrounding function scope, not just the conflict block
- **Post-AI syntax validation** — use Tree-sitter to verify the AI result before showing it
- **Multi-provider support** — abstract AI interface to support `CopilotChat.nvim`, `CodeCompanion.nvim`, `Ollama` (local LLMs), not just Avante

---

## Priority Pick

Both reviewers independently ranked **"Works outside Git"** as the highest-impact, lowest-competition niche. Phase 2 is the clearest path to becoming a **must-have** over a **nice-to-have**.
