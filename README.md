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

### Care mistake tracking

`scenes/creature/creature.gd` now watches a `CARE_MISTAKE_RULES` table every world tick and increments `CreatureStats.care_mistakes` whenever a stat sits in a "red zone" for multiple consecutive ticks. The default rules (tuned for a 10s world tick) are:

- **Starvation:** Hunger ratio `>= 0.95` for 3 ticks (`~30s`) without relief.
- **Exhaustion:** Energy ratio `<= 0.10` for 3 ticks.
- **Grimy:** Grooming need ratio `>= 0.90` for 4 ticks.
- **Nest neglect:** Nest cleanliness ratio `<= 0.20` for 5 ticks.

Each rule has its own recovery ratio, so the counter only re-arms once the stat returns to a safer band. When a mistake fires, `Eventbus.care_mistake_recorded` and `Eventbus.care_mistake_total_changed` broadcast the new total, and the creature's blackboard gains a `"<name>_care_mistakes"` entry so BeeHave decorators or evolution logic can branch on neglect. Clean play also matters: if none of the rules stay active for a full in-game hour (`CARE_MISTAKE_DECAY_HOURS`), `_update_care_mistake_decay()` subtracts one mistake and emits another `care_mistake_total_changed` signal. Future evolution requirements can now read the total directly instead of guessing whether the player was attentive.

## Creature behavior tree

The BeeHave selector inside `scenes/creature/creature.tscn` now prioritizes self-care loops before falling back to idle wandering. The order is Sleep → Eat → Groom → Nest Maintenance → Wander/Idle. `scenes/creature/Creature.gd` syncs hunger, energy, grooming need, and nest cleanliness to the blackboard every world tick so the new condition nodes have up-to-date data.

- **New stats.** `CreatureStats` stores `current_grooming_need`/`max_grooming_need` (ticks add ~1.5 need points/hour) plus `nest_cleanliness`/`max_nest_cleanliness` (ticks remove ~0.5 cleanliness points/hour). Those values serialize with the rest of the creature payload so grooming urgency and nest messiness persist across saves.
- **Blackboard keys.** Each creature writes `"<name>_grooming_need"` and `"<name>_nest_cleanliness"` every tick. Condition leaves read those keys so the selectors stay per-creature even when multiple pets share one tree instance.
- **Exported tuning knobs.** Designers can tweak `grooming_relief_per_action` and `nest_cleanliness_restore_per_action` on `scenes/creature/creature.tscn` to rebalance how much each action relieves the corresponding stat without editing the action scripts.
- **Smarter wandering.** `creature_ai/actions/WalkAroundAction.gd` now samples TileMap bounds, queues 1–3 waypoint patrols, and injects short scenic pauses so creatures stop hugging the map edge and feel more intentional as they meander between points of interest.
- **Timed emotions.** `show_emotion()` inside `scenes/creature/Creature.gd` now spins up a bubble for a few seconds (`emotion_linger_seconds`) before auto-clearing so creatures no longer display a permanent mood icon while idle.
- **Live action/mood readouts.** Every action script calls `Creature.set_behavior_state()`, which broadcasts a `creature_activity_changed` signal (see `autoload/eventbus.gd`). The focus drawer (`scenes/ui/drawers/creature_details_drawer.tscn`) now surfaces the mood label, current action, and a rotating “thought” quip so players can read what each creature is doing when zoomed in.

| Routine | Trigger (condition leaf) | Side effects |
| --- | --- | --- |
| `GroomSelfAction` | `NeedsGroomingCondition` fires when `current_grooming_need / max_grooming_need >= 0.6`. | Plays the love emotion bubble while the creature spends ~3 seconds cleaning, then subtracts `grooming_relief_per_action` from the need stat and awards +5 happiness before returning to the tree. |
| `CleanNestAction` | `IsNestDirtyCondition` fires when `nest_cleanliness / max_nest_cleanliness <= 0.45`. | Shows the idle bubble during a ~4.5 second tidy session, restores `nest_cleanliness_restore_per_action`, and updates hunger/energy blackboard values to account for the work performed. |

The fallback selector (WalkAround → Idle) still keeps creatures roaming whenever none of the higher-priority conditions pass, so new routines can slot in ahead of it by following the same pattern: define a condition leaf that reads the blackboard and an action leaf that updates stats + emits the desired signals.

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
- **Training payoff + upkeep.** `resources/stats/creature_stats.gd` now stores per-stat baselines, caps, and fractional progress, and `scenes/creature/Creature.gd` exposes session helpers so training stations can grant temporary stat boosts that decay after a 30-minute grace window. Sessions convert XP every tick, drain extra hunger/energy, and accumulate fatigue that slows future gains until creatures rest.

**Suggested adjustments**

1. Capture hunger/energy deltas per creature in `scenes/world.gd` or `autoload/eventbus.gd` so designers can compare the real number of care interactions/hour against the theoretical constants and update this README when targets shift.
2. Thread bed quality or buildables into the new multipliers—e.g., a deluxe nest could boost `sleep_recovery_multiplier` while cozy blankets suppress hunger during naps—to give the furnishing loop tangible impact.
3. Build the upcoming training stations so they call `Creature.begin_training_session()` (see below) with the right stat/intensity and render `Eventbus.training_progress_updated` payloads over time. When stations stop, let the creature rest so fatigue can drop and decay can be avoided.

### Training payoff model (`resources/stats/creature_stats.gd`, `scenes/creature/Creature.gd`, `autoload/eventbus.gd`, `scenes/ui/drawers/creature_details_drawer.*`)

- **Baselines + caps.** Every creature now persists `strength|intelligence|happiness_baseline` plus `*_cap` values alongside their live stats. Training boosts can never dip below the baseline or climb past the cap, and the UI shows the delta as `value (+bonus) / cap` so designers immediately see how much of the buff is temporary.
- **Session math.** Call `Creature.begin_training_session(stat: StringName, duration_seconds: float, intensity: float = 1.0, station_id := StringName())` when a creature claims a Gym Pod/Study Desk/etc. Sessions accrue XP every tick using the rates below, scaled by intensity and reduced as fatigue grows. Training drains additional hunger/energy that the player must refill:

| Stat | XP/min (intensity 1.0, pre-fatigue) | XP per stat point | Extra hunger/min | Extra energy/min | Decay/hour (after 30 min idle) |
| --- | --- | --- | --- | --- | --- |
| Strength | 4.0 | 6.0 | +3.0 | -6.0 | -1.25 |
| Intelligence | 3.5 | 5.0 | +2.0 | -4.0 | -1.0 |
| Happiness | 2.5 | 4.0 | +1.5 | -3.0 | -0.75 |

- **Fatigue + grace.** Sessions add ~12 fatigue/minute × intensity; fatigue caps at 100 and linearly reduces future XP gains down to 35%. Resting (no active session) recovers 18 fatigue/hour. Training bonuses decay only after 30 minutes of rest—once the grace timer expires, `TRAINING_DECAY_PER_HOUR` removes points until stats meet their baselines. `Creature.get_training_snapshot()` exposes the active stat, seconds remaining, fatigue, and per-stat bonuses so UI and future combat/evolution systems can reflect the data.
- **Signals + HUD.** `autoload/eventbus.gd` now emits `training_session_started`, `training_progress_updated`, `training_session_completed`, and `training_session_cancelled` so world/buildable scripts can hook into the lifecycle. The focus drawer (`scenes/ui/drawers/creature_details_drawer.tscn`) surfaces training status, fatigue, and per-stat bonuses to players, making the tradeoffs visible before the dedicated training-station UI exists.

## Online services (Talo roadmap)

We're planning to lean on [Talo](https://trytalo.com), an open-source, self-hostable backend that already ships a Godot plug-in and Dockerized server. Instead of inventing new infrastructure, the authoritative layer will focus on configuring and extending Talo so it mirrors our core simulation data.

- **Deployment:** Follow `docs/integrations/talo.md` to clone/run the official Talo Docker stack in a sibling directory. We never vendor the upstream repo or Compose files here; `backend/` stays reserved for bridge scripts/config we author that talk to Talo.
- **Godot integration:** Use the upstream Talo add-on (checked into `addons/talo_client/`) as-is—configuration only, no code edits—to authenticate per-device, sync game saves, and emit telemetry directly from `autoload/game.gd` and UI menus.
- **Storefront + purchase authority:** Build a Godot storefront panel plus lightweight bridge scripts under `backend/` that talk to Talo endpoints responsible for minting/consuming egg bundles, verifying soft-currency spends, and logging each transaction so dupes or rollbacks can be audited. The same flow must support gated "packs" of 1/3/5 eggs plus future seasonal bundles.
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

1. **Talo-only customization.** Attempt to author purchase flows directly inside a fork of the official Talo backend by extending its serverless functions. This keeps everything inside the official stack but will require upstream deep dives plus custom dashboards for SKU management.
2. **Hybrid companion service (recommended).** Keep Talo for identity, storage, and analytics, but introduce a standalone, multi-tenant commerce suite (built in the external `commerce-hub-suite` repo) that exposes signed entitlements. The Godot client talks to the storefront for bundle pricing and receipts, and that service writes final inventory data back into Talo via its REST API. This lets us design commerce-specific logic (soft currency sinks, real-money hooks, fraud checks) without abandoning the Talo ecosystem we already plan to rely on, while letting other games configure their catalogs without forking.
3. **Full custom backend.** Replace Talo entirely with our own authoritative service so storefront, saves, and multiplayer share one codebase. That maximizes flexibility but recreates features (auth, leaderboards, dashboards) that Talo already solved and would dramatically increase maintenance costs.

**Best path right now:** pursue the hybrid model. We keep device/OAuth authentication, leaderboards, and analytics inside the Talo Docker stack while prototyping purchases in a purpose-built service that can grow into real-money monetization later. Should the hybrid spike prove unworkable (e.g., Talo APIs cannot be extended cleanly), we'll revisit the full custom backend and update `TODO.yaml` accordingly.

#### Hybrid implementation plan

- **Companion repo (`commerce-hub-suite`).** Commerce-specific logic now lives in an external, multi-tenant repository that is inspired by (but not dependent on) Talo. That suite ships a Fastify/TypeScript backend, a React/Vite dashboard, and a Godot 4 add-on so any Godot project—Talo-powered or otherwise—can bolt the storefront on, configure per-tenant catalogs/currencies, and treat egg bundles as optional fixtures. See `docs/storefront_repo_prompt.md` for the bootstrap prompt we hand to agents when creating the repo.
- **Integration boundaries.** This Godot project keeps using the official `addons/talo_client` plug-in for auth and analytics. The storefront client add-on (authored in the new repo) will request offers, submit purchases, and optionally echo receipts back to the Talo backend via REST so inventory remains authoritative there. Because the commerce suite is standalone, other games can integrate it without Talo by wiring their own identity adapters.
- **Next steps in this repo.** Track storefront-specific work under `TODO.yaml` (`online.storefront_egg_packs`, `online.monetization_foundation`, etc.), but implement shared commerce code in `commerce-hub-suite`. Future integration tasks here focus on wiring Godot UI scenes to the storefront client add-on and ensuring whichever identity provider we use (Talo or custom) is forwarded correctly.

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
