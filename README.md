# digi-tamogotcha-mon

A Godot 4.5 virtual-creature sandbox inspired by classic Tamagotchi and Digimon handhelds. You hatch multiple pets at once, place buildables to keep them alive, and eventually steer them toward branching evolution paths.

## Current pillars

- **Signal-driven simulation.** Autoload singletons (`Data`, `Game`, `Eventbus`, etc.) expose shared data, events, and logging so scenes can communicate without tight coupling.
- **World scene as orchestrator.** `scenes/world.tscn` and `scenes/world.gd` spawn creatures, manage timers, and react to UI requests such as feeding or dropping buildables.
- **Resource-based content.** Creatures, stats, and audio live in `resources/`, making it easy to add new species or items by authoring `.tres` files and referencing them from `autoload/data.gd`.
- **UI-first interactions.** The HUD (`scenes/ui`) listens to `Eventbus` signals to switch menus, update segmented bars, drag-and-drop buildables, and queue notifications.

## Evolution brainstorming

The current data includes baby species (e.g., Blop, Ghos, Sprit, Squip) plus three new families—Nibblit → Thornet, Emberpup → Scorchhound, and Glimm → Prismscout—that each branch into distinct adult archetypes (Bramblord/Bloomseraph, Cinderdrake/Glasshowl, and Luminarch/Nullsir, respectively). A visual reference (see `/assets/design/evolution-tree.png` once checked in) outlines the branching structure with ghostly, armored, elemental, and holographic variants. Names are still in flux, so expect further iteration as stat-based mechanics solidify.

### Evolution spreadsheet starter

To make the written data easier to extend, `assets/design/evolution_tree_seed.csv` captures the current baby → teen → adult pairings along with their known requirements, egg textures, and notes about branching routes (balanced care, neglect, stat focus, day/night training, etc.). Treat it as the source-of-truth planning sheet: duplicate rows when you add new `.tres` resources, fill in the per-column requirement breakdowns (age trigger, death flag, stat minimums/maximums, allowed care mistakes, etc.), and link to any relevant sprite assets so art and design stay in sync.

## Getting started

1. Install [Godot 4.5](https://godotengine.org/).
2. Open this repository as a project; the editor will load `scenes/main_menu.tscn` by default.
3. Run the project on desktop to iterate quickly. Mobile build targets are planned but not yet configured.
4. A lightweight placeholder login screen (`scenes/login_screen.tscn`) now appears first. It automatically advances through a faux “Connecting…” state, then hands off directly to the main menu. Longer transitions—like entering the world from the menu—route through the animated loading scene (`scenes/ui/load_screen.tscn`), which rotates gameplay quick facts, cycles an emoji-based progress meter, and exposes an **Enter Habitat** button once `SceneManager` signals that the next scene is ready.

Add, remove, or reorder the quick facts by editing the `quick_facts` export array inside `scenes/ui/load_screen.gd`; designers can iterate on tips without touching the rest of the UI wiring. To skip the loading UI for short hops, call `SceneManager.load_scene("res://path_to_scene.tscn", "", false)`. Both the login (`scenes/login_screen.tscn`) and load (`scenes/ui/load_screen.tscn`) screens pull their background and accents from the shared palette (e.g., `#0E071B`, `#03193F`, `#00CDF9`, `#FFA214`), so stick to those swatches when iterating on colors.

### Developer tips

- Review `autoload/eventbus.gd` to learn every signal fired by the simulation before extending gameplay.
- Inspect `scenes/world.gd` to see how the world clock, player inventory, and drop area interact; most new mechanics hook in here.
- New buildables should inherit from the templates under `buildables/` and register themselves in `autoload/data.gd` so the UI can surface them.
- Keep early-game unlocks (free nest, food bowl, 500 gold) in mind—they are temporary debugging aids and may be removed or gated later.

## Creature care cadence
The world clock inside `scenes/world.gd` emits a tick every `tick_frequency` seconds (the default scene at `scenes/world.tscn` sets this to 2s). Each tick drives `scenes/creature/Creature.gd::_on_world_tick()`, which derives decay math from ticks-per-hour so changing the frequency automatically rebalances the sim.

- **Base targets per real-time hour.** Hunger rises enough to require ~6 feedings, energy drains to zero twice, and sleep restores a full bar four times. These values map to the constants `HUNGER_INTERACTIONS_PER_HOUR`, `ENERGY_DRAIN_CYCLES_PER_HOUR`, and `SLEEP_RECOVERY_CYCLES_PER_HOUR` inside `scenes/creature/Creature.gd`.
- **Life-stage multipliers.** Babies run hotter than teens while adults coast longer; eggs stay stable. The per-stage profile also specifies what fraction of the hunger rate applies while the creature sleeps.

| Life stage | Hunger multiplier | Energy multiplier | Sleep energy multiplier | Sleep hunger fraction |
| --- | --- | --- | --- | --- |
| Egg | 0.0 | 0.0 | 0.0 | 0.0 |
| Baby | 1.2 | 1.1 | 0.9 | 0.35 |
| Teen | 1.0 | 1.0 | 1.0 | 0.45 |
| Adult | 0.8 | 0.9 | 1.1 | 0.6 |

- **Species tuning.** Every entry in `resources/creature/species.gd` now exports `hunger_decay_multiplier`, `energy_decay_multiplier`, `sleep_recovery_multiplier`, and `sleep_hunger_multiplier`. Designers can nudge specific species (gluttons, night owls, etc.) without touching global constants while `resources/stats/creature_stats.gd` keeps storing the canonical values.

## HUD menu & drawers

- **Unified menu bar.** `scenes/ui/menu_bar.tscn` sits inside the SubViewport and swaps button profiles: world view surfaces Save + Creatures/Eggs/Build/Food toggles, while focus view swaps in Zoom Out + Creature Details. Save only appears in the world profile; Zoom only appears in the focus profile.
- **Button-driven drawers.** Every toggle belongs to a `ButtonGroup`. Only one drawer opens at a time, and toggling the active button closes its drawer via tweens so the bar feels like a handheld device sliding open.
- **Modular drawer scenes.** World drawers (`scenes/ui/drawers/creature_list_drawer.tscn`, `egg_catalog_drawer.tscn`, `build_shop_drawer.tscn`, `food_bag_drawer.tscn`) plus the focus details drawer (`creature_details_drawer.tscn`) all extend `scenes/ui/drawers/menu_drawer.gd`, which animates a `ContentRoot` node so SubViewport scaling no longer distorts them.
- **Signals instead of custom menus.** `scenes/ui/menu_bar.gd` emits `save_requested` / `zoom_requested` so `WorldUI` can bridge into gameplay, and the drawers listen to `Eventbus` (egg inventory, focus view requests, etc.) just like any other scene.
- **Focus view via HUDMenuBar.** `scenes/ui/UI.gd` now swaps profiles in response to `Eventbus.focus_view_requested` / `world_view_requested`, pushes the focused creature into the `creature_details_drawer.tscn` via `HUDMenuBar.set_focus_creature()`, and relies on the `Zoom` button to unwind back to the world—`scenes/ui/focus_view_menu.tscn` and its script were removed.
- **Debug inventory.** `_bootstrap_player_profile()` still seeds three baby-species eggs via `Player.grant_debug_eggs()` so designers always have hatchable inventory while the real pack/economy tasks remain in TODO. These eggs save/load through the player payload and are consumed only on successful spawns.

## Save & idle catch-up

- `autoload/game.gd` owns the lifecycle for persistence. It calls `scenes/world.gd.serialize_state()` and writes `user://saves/autosave.save` via `save/save_io.gd`, bundling player wallet/buildables, all spawned buildables, creature payloads (stats, species, bed positions), RNG state, and the last world tick timestamp.
- `scenes/world.gd` exposes `start_new_session()`, `begin_simulation()`, `apply_saved_state()`, `apply_idle_ticks()`, and `prepare_for_save()` while `scenes/creature/Creature.gd` ships `Creature.apply_save_data()` so those calls can rebuild the player wallet, dynamic buildables, creature stats, and nest assignments before manual or auto saves run.
- Autosaves occur whenever key actions fire (`Player.add_to_wallet`, buildable placement in `scenes/ui/drop_area.gd`, creature adoption inside `scenes/world.gd`) and are debounced inside `Game.queue_save`. Players can pick **Continue** on the main menu to load the last save, opt for **New** to wipe `user://saves/autosave.save` before entering the world, or trigger a manual checkpoint via the Save button on `scenes/ui/menu_bar.tscn`.
- On boot `Game.register_world()` loads the payload, rehydrates `scenes/world.gd` (player, buildables, creatures), and runs a bounded idle catch-up loop (up to six hours of ticks) so hunger/energy decay and life-stage transitions advance before the clock restarts.
- Failures (missing/corrupt save) emit `Eventbus.load_failed` and fall back to `start_new_session()`, so other systems can surface warnings without crashing the sim.

## Simulation balance review

- **Stage-aware decay.** `scenes/creature/Creature.gd::_on_world_tick()` now hits ~6 hunger interactions/hour, two full energy drains/hour, and four sleep recoveries/hour while scaling by the life-stage profile above. We still need telemetry to confirm that real play sessions hit those touchpoints without feeling spammy.
- **Sleep tradeoffs.** Sleeping no longer tops off energy instantly; recovery speed and hunger suppression both depend on stage data plus the species multipliers living in `resources/creature/species.gd`. The next layer should let nests or status effects adjust those multipliers temporarily.
- **Untrained stats stay flat.** Strength, intelligence, and happiness never change after `resources/stats/creature_stats.gd` initializes them, so training loops still lack any payoff.

**Suggested adjustments**

1. Capture hunger/energy deltas per creature in `scenes/world.gd` or `autoload/eventbus.gd` so designers can compare the real number of care interactions/hour against the theoretical constants and update this README when targets shift.
2. Thread bed quality or buildables into the new multipliers—e.g., a deluxe nest could boost `sleep_recovery_multiplier` while cozy blankets suppress hunger during naps—to give the furnishing loop tangible impact.
3. Build the upcoming training stations so stats climb/decay in response to world ticks, letting the new hunger/energy cadence create tradeoffs between care, rest, and stat gains.

## Online services (Talo roadmap)

We're planning to lean on [Talo](https://trytalo.com), an open-source, self-hostable backend that already ships a Godot plug-in and Dockerized server. Instead of inventing new infrastructure, the authoritative layer will focus on configuring and extending Talo so it mirrors our core simulation data.

- **Deployment:** Run the official Talo Docker stack inside `backend/talo/` (compose file + env templates) so local contributors can boot leaderboards, persistent storage, and analytics without cloud credentials.
- **Godot integration:** Use the upstream Talo add-on (checked into `addons/talo_client/`) to authenticate per-device, sync game saves, and emit telemetry directly from `autoload/game.gd` and UI menus.
- **Storefront + purchase authority:** Build a Godot storefront panel that talks to Talo endpoints responsible for minting/consuming egg bundles, verifying soft-currency spends, and logging each transaction in the backend so dupes or rollbacks can be audited. The same flow must support gated "packs" of 1/3/5 eggs plus future seasonal bundles.
- **Feature set we plan to adopt:**
  - Player management (device auth, optional OAuth, persistent data & groups).
  - Peer-to-peer multiplayer sessions with server-authoritative persistence.
  - Leaderboards plus global/player analytics.
  - Remote config + save slots hosted in the cloud backend.
  - Feedback hooks and online presence indicators so friends can see when others are active.
- **Monetization runway:** Even before real-money hooks land, design the storefront API so Talo can track real-currency receipts (Stripe, Steam, etc.) or soft-currency conversions. Document pricing tables in `README.md`/`TODO.yaml`, and ensure device/OAuth auth tokens are part of every purchase so egg inventory can be trusted server-side.

As the Talo integration lands, update this section with exact Docker commands, environment variables, storefront wiring, and any Godot add-on setup steps so future agents can reproduce the backend quickly.

### Storefront architecture options

Talo covers authentication, save syncing, analytics, and presence out of the box, but it does not ship a turnkey storefront. We have three viable approaches:

1. **Talo-only customization.** Attempt to author purchase flows directly in `backend/talo/` by extending its serverless functions. This keeps everything inside the official stack but will require upstream deep dives plus custom dashboards for SKU management.
2. **Hybrid companion service (recommended).** Keep Talo for identity, storage, and analytics, but introduce a lightweight purchase authority (`backend/storefront/`) that exposes signed entitlements. The Godot client talks to the storefront for bundle pricing and receipts, and that service writes final inventory data back into Talo via its REST API. This lets us design commerce-specific logic (soft currency sinks, real-money hooks, fraud checks) without abandoning the Talo ecosystem we already plan to rely on.
3. **Full custom backend.** Replace Talo entirely with our own authoritative service so storefront, saves, and multiplayer share one codebase. That maximizes flexibility but recreates features (auth, leaderboards, dashboards) that Talo already solved and would dramatically increase maintenance costs.

**Best path right now:** pursue the hybrid model. We keep device/OAuth authentication, leaderboards, and analytics inside the Talo Docker stack while prototyping purchases in a purpose-built service that can grow into real-money monetization later. Should the hybrid spike prove unworkable (e.g., Talo APIs cannot be extended cleanly), we'll revisit the full custom backend and update `TODO.yaml` accordingly.

### Mobile persistence considerations

- **Constraint:** The current save/load pipeline only persistently writes `user://saves/autosave.save` through `autoload/game.gd`, so iOS/Android suspensions still risk wiping progress when the OS reclaims the process until we add background/cloud sync.
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
