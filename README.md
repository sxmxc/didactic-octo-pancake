# digi-tamogotcha-mon

A Godot 4.5 virtual-creature sandbox inspired by classic Tamagotchi and Digimon handhelds. You hatch multiple pets at once, place buildables to keep them alive, and eventually steer them toward branching evolution paths.

## Current pillars
- **Signal-driven simulation.** Autoload singletons (`Data`, `Game`, `Eventbus`, etc.) expose shared data, events, and logging so scenes can communicate without tight coupling.
- **World scene as orchestrator.** `scenes/world.tscn` and `scenes/world.gd` spawn creatures, manage timers, and react to UI requests such as feeding or dropping buildables.
- **Resource-based content.** Creatures, stats, and audio live in `resources/`, making it easy to add new species or items by authoring `.tres` files and referencing them from `autoload/data.gd`.
- **UI-first interactions.** The HUD (`scenes/ui`) listens to `Eventbus` signals to switch menus, update segmented bars, drag-and-drop buildables, and queue notifications.

## Evolution brainstorming
The current data includes baby species (e.g., Blop, Ghos, Sprit, Squip) and placeholders for their teen evolutions. A visual reference (see `/assets/design/evolution-tree.png` once checked in) outlines a branching structure with multiple ghostly or armored variants. Names are in flux, and one teen form still lacks a baby counterpart—expect further iteration as stat-based mechanics solidify.

### Evolution spreadsheet starter
To make the written data easier to extend, `assets/design/evolution_tree_seed.csv` captures the current baby → teen pairings along with their known requirements, egg textures, and notes about missing adult branches. Treat it as the source-of-truth planning sheet: duplicate rows when you add new `.tres` resources, fill in the per-column requirement breakdowns (age trigger, death flag, stat minimums/maximums, allowed care mistakes, etc.), and link to any relevant sprite assets so art and design stay in sync.

## Getting started
1. Install [Godot 4.5](https://godotengine.org/).
2. Open this repository as a project; the editor will load `scenes/main_menu.tscn` by default.
3. Run the project on desktop to iterate quickly. Mobile build targets are planned but not yet configured.

### Developer tips
- Review `autoload/eventbus.gd` to learn every signal fired by the simulation before extending gameplay.
- Inspect `scenes/world.gd` to see how the world clock, player inventory, and drop area interact; most new mechanics hook in here.
- New buildables should inherit from the templates under `buildables/` and register themselves in `autoload/data.gd` so the UI can surface them.
- Keep early-game unlocks (free nest, food bowl, 500 gold) in mind—they are temporary debugging aids and may be removed or gated later.

## Contributing
- Track work in `TODO.md` so future agents can pick up partially scoped efforts.
- Document new systems here in the README, including where they live and how to try them.
- Use `AGENTS.md` for repo-wide guidelines or directory-specific instructions.

