# conflict.nvim — Roadmap

## Core Problem

Both reviewers agree: the plugin is a solid re-implementation but lacks a **differentiating reason to switch** from `git-conflict.nvim`.

---

## Phase 0 — Stability (v0.1.x)

**Goal:** Harden the core before adding more features. Source: `specs/feedback/chatgpt.md` P0 items.

- [x] **diff3 parser correctness** — `detect_conflicts()` distinguishes `|||||||` base section from `<<<<<<<`/`=======`/`>>>>>>>` (`detect.lua` captures `conflict.base` and renders a separate "Base" highlight)
- [x] **Multi-buffer state isolation** — conflict/LSP-suppression state is stored per-buffer via `vim.b[bufnr]` (`snapshot_buffer_state`/`restore_buffer_state`), not global
- [x] **LSP/TreeSitter lifecycle correctness** — diagnostics and TreeSitter are snapshotted and restored per buffer (`restore_buffer_state` in `detect.lua`)
- [ ] **Edge-case test coverage** — conflict at EOF/first line, empty ours/theirs/both, nested/adjacent conflicts, CRLF, Unicode, buffer unload/rename, resolve last vs. one-of-many (only `init_spec.lua` and `list_spec.lua` exist today)

---

## Phase 0.5 — Polish (v0.1.x)

**Goal:** Quality-of-life fixes before adding new features. Source: `specs/feedback/chatgpt.md` P1 items.

- [x] ~~README workflow section~~ — done
- [x] ~~Clarify ours/theirs/current/incoming~~ — done
- [ ] **Colorscheme integration** — `colors` config currently takes hard-coded hex (`config.lua`), contradicting the "adapts to colorscheme" claim; support semantic highlight group names (e.g. `"DiffAdd"`) or a function returning a color
- [x] ~~Project scan performance~~ — already uses `git grep` in `list.lua`, not a full-repo Lua scan
- [ ] **API documentation** — document public Lua API (`require("conflict")` functions) beyond keymaps/commands
- [ ] **Version/tag/release** — cut a tagged release so Lazy.nvim users can pin a version
- [ ] **Health check** — add `:checkhealth conflict` (verify git available, optional deps present, config valid)

---

## Phase 1 — UX Foundation (v0.2)

**Goal:** Close the gap with existing plugins, stop losing users on basics.

- [x] **Quickfix/Telescope integration** — `<leader>cl` lists all conflicting files project-wide (`list.lua`)
- [x] **Event system** — emits `ConflictDetected`/`ConflictResolved` autocmd events (`detect.lua`, `resolve.lua`)
- [x] **Mouse-clickable action bar** — `<LeftMouse>` mapped to `detect.on_mouse` for clicking action buttons
- [x] **Lazy dependencies** — core features work with zero deps; diff views `pcall(require, "diffview")` and fall back to built-in diff

---

## Phase 2 — Killer Feature: Works Everywhere (v0.3)

**Goal:** Capture the niche `git-conflict.nvim` misses.

- [x] **Detect conflicts outside Git merge state** — `detect.anywhere` config option (default `true`) works on any file with conflict markers, not just active merges

---

## Phase 3 — Smart Resolve (v0.4)

**Goal:** Upgrade from "dumb accept" to "intelligent merge".

- [ ] **Trivial conflict auto-resolve** — detect whitespace-only, trailing comma, formatter diffs and resolve silently or with `<leader>cx`
- [ ] **Live preview floating window** — show merged result before committing to "Accept Both"
- [ ] **Pattern-aware merge hints** — detect import blocks, JSON keys, array merges and suggest combined result

---

## Priority Pick

Both reviewers independently ranked **"Works outside Git"** as the highest-impact, lowest-competition niche — already shipped (Phase 2). Remaining focus: close out Phase 0 test coverage, then Phase 3.
