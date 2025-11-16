# AGENTS

## Scope
Applies to the entire repository until a nested `AGENTS.md` overrides it.

## Authoring guidelines
1. **Document-first mindset.** When you add, remove, or significantly change a system, update `README.md` and/or `TODO.yaml` in the same change so newcomers understand how to interact with it.
2. **Task tracking.** Keep `TODO.yaml` curated—if you finish a task, remove it; if you discover new work, describe it with clear entrypoints and definitions of done.
3. **File references.** Always mention full paths (e.g., `scenes/world.gd`) in commit messages, PR descriptions, and documentation whenever you reference code. This helps AI agents jump directly to the right place.
4. **Godot style.** Prefer idiomatic Godot 4.x GDScript (typed variables, `_on_*` signal handlers, etc.) and avoid wrapping imports in `try/except` blocks.
5. **Design assets.** Store editable sources (draw.io, Krita, etc.) next to exported images inside `assets/` so future contributors can iterate without recreating artwork.

