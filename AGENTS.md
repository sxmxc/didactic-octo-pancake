# AGENTS

## Scope

Applies to the entire repository until a nested `AGENTS.md` overrides it.

## Authoring guidelines

1. **Document-first mindset.** When you add, remove, or significantly change a system, update `README.md` and/or `TODO.yaml` in the same change so newcomers understand how to interact with it.
2. **Task tracking.** Keep `TODO.yaml` curated—if you finish a task, remove it; if you discover new work, describe it with clear entrypoints and definitions of done.
3. **File references.** Always mention full paths (e.g., `scenes/world.gd`) in commit messages, PR descriptions, and documentation whenever you reference code. This helps AI agents jump directly to the right place.
4. **Godot style.** Prefer idiomatic Godot 4.x GDScript (typed variables, `_on_*` signal handlers, etc.) and avoid wrapping imports in `try/except` blocks.
5. **File naming** Avoid use of capitals in file names. File names should be snake_case. Follow [Naming Conventions](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#naming-conventions)
6. **Strict typing.** Always follow Godot's strict typing conventions when possible—explicitly type exports, locals, return values, and member variables so warnings never escalate to errors.
7. **Design assets.** Store editable sources (draw.io, Krita, etc.) next to exported images inside `assets/` so future contributors can iterate without recreating artwork.
8. **Branching:** Work on feature branches named `feature/<feature-name>`.
9. **Commit Messages:** Follow Conventional Commits specification (e.g., `feat: add new user registration`).
10. **Pull Requests:** Use this pull request template for all pull requests `.github/pull_request_template.md`.
11. **Addons:** Changes should never be made to any of the thirdparty addons in `addons/`.
12. **Creature AI and BehaviorTree:** We are using [BeeHave](https://bitbra.in/beehave/#/) behaviour tree addon. Refer to its docs when implementing new ai behaviour acions or have questions about its structure.
13. **Code Generation** Always use context7 when you need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.
