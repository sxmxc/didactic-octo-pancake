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

## Simulation balance review
- **Tick cadence vs. stat decay.** The global timer in `scenes/world.gd` fires every 10 seconds, meaning hunger rises by just +1 and energy falls by -1 per tick while a creature is awake (`scenes/creature/Creature.gd::_on_world_tick`). This slow drift leaves almost no pressure on the player until many minutes have passed.
- **Sleep makes energy trivial.** The same tick grants +10 energy when the AI is sleeping, letting a nap undo one hundred seconds of exhaustion instantly. Because hunger still increases during sleep, unattended creatures are likely to overfill hunger long before energy becomes interesting.
- **Untrained stats stay flat.** Strength, intelligence, and happiness never change after the resource is instantiated, so training loops cannot currently counterbalance decay or unlock evolutions.

**Suggested adjustments**
1. Scale decay by life stage or elapsed time so newly hatched creatures need gentle care while adults drain faster. Consider converting the current +/-1 adjustments into percentages of `max_hunger`/`max_energy` to keep species balanced even if their caps diverge.
2. Replace the constant +10 energy during sleep with a recovery rate tied to `max_energy` or a "sleep quality" stat so rest feels meaningful but not instantaneous.
3. Gate stat decay/bonuses behind the upcoming training stations (see TODO) so strength/intelligence growth introduces tradeoffs—e.g., training drains more energy but slows hunger gain for a short period.
4. Document the target number of player interactions per in-game day (feeds, naps, training sessions) so future tuning work can aim for a predictable loop.

### Mobile persistence considerations
- **Constraint:** The current build has no save/load pipeline, so iOS/Android suspensions wipe progress or keep the simulation frozen until the OS reclaims memory.
- **Goal:** Preserve creature state without requiring the app to stay alive in the background, while still letting time passage matter so that skipping a day has consequences but not instant death.

**Recommended approach**
1. **Snapshot on intentful actions.** Serialize `autoload/data.gd`'s world clock, creature roster, buildables, and inventory to `user://saves/slot_01.save` (JSON or `ResourceSaver`) whenever the player feeds, trains, or exits to the menu. Mobile OSes can kill the app anytime, so deterministic save hooks beat background execution.
2. **Store a timestamp.** Include `last_tick_epoch_ms` in the save data. On boot, compute `elapsed_seconds = now - last_tick` and run a catch-up tick loop that replays decay/training outcomes in coarse batches (e.g., minutes) with safety clamps so extreme gaps cap at a “grace period.”
3. **Offer soft rest mode.** Instead of real background simulation, use notifications or UI reminders when the elapsed time exceeds thresholds (12h, 24h). That keeps the design mobile-friendly and avoids battery-draining background threads.
4. **Document guardrails.** Decide how long creatures can go unattended before death and communicate it in the HUD so players know what to expect if they miss a day.

## Contributing
- Track work in `TODO.yaml` (prioritized backlog with blockers/subtasks) so future agents can pick up partially scoped efforts.
- Document new systems here in the README, including where they live and how to try them.
- Use `AGENTS.md` for repo-wide guidelines or directory-specific instructions.

