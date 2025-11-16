# TODO

A living backlog for AI agents and collaborators. Each task lists the primary files to inspect plus completion hints.

## Core mechanics

### 1. Stat training loops
- **Problem:** Creatures can lose hunger/energy over time but have no way to raise strength, intelligence, or other stats.
- **Entrypoints:** `scenes/world.gd` (world tick + event wiring), `scenes/creature/creature.gd` (stat container + behavior tree integration), `buildables/` (training stations), `autoload/eventbus.gd` (signals), `resources/stats/creature_stats.gd`.
- **Approach:**
  1. Author one or two training buildables (e.g., Gym Pod, Study Desk) and register them inside `autoload/data.gd`.
  2. Extend creature AI so idle pets can claim nearby training stations and emit a signal describing the stat they are working on.
  3. Consume that signal/timer inside the world tick to increment stats gradually while draining hunger/energy.
  4. Surface training progress in the UI via new `Eventbus` signals so multiple creatures can be managed simultaneously.
- **Definition of done:** Stats visibly increase after training, UI reflects progress, and the system works for any number of creatures.

### 2. Evolution requirement checks
- **Problem:** Species resources already store requirement dictionaries, yet age-ups never evaluate them.
- **Entrypoints:** `resources/creature/data/**/*.tres`, `scenes/creature/creature.gd` (`_age_up()`), `resources/stats/creature_stats.gd`.
- **Approach:**
  1. When a creature hits an age threshold, iterate over its potential evolutions and check requirement dictionaries (happiness, care mistakes, stat minimums, `is_dead`).
  2. Select a valid teen/adult resource (supporting randomness or priority weighting) and swap sprites/stats accordingly.
  3. Emit UI + notification signals so the player understands why that branch triggered.
- **Definition of done:** Evolution outcomes reflect stat training and care history; requirements are easy to tweak per species.

### 3. Care mistake tracking
- **Problem:** `CreatureStats` exposes `care_mistakes` but nothing increments it.
- **Entrypoints:** `scenes/creature/creature.gd`, `scenes/world.gd`, `Eventbus` notifications.
- **Approach:** Define “mistakes” (e.g., starving hunger bar, ignoring sickness) and increment counters when they occur. Broadcast updates for UI/analytics and feed the values into evolution logic.
- **Definition of done:** Care mistakes rise under neglect, reset/decay rules are documented, and evolution branches consume the value.

## Content & UX

### 4. Evolution data pass
- **Problem:** Only four baby species exist and one teen slot lacks a base form.
- **Entrypoints:** `resources/creature/data/babies/*.tres`, `resources/creature/data/teens/*.tres` (create), design docs.
- **Approach:** Flesh out the attached evolution diagram into `.tres` resources (names can be temporary). Capture sprite references, requirement dictionaries, and notes so future agents can implement them directly.
- **Definition of done:** Each teen/adult node in the diagram has a corresponding resource with clearly documented requirements and owner sprites.

### 5. Item roster audit
- **Problem:** Starter buildables (nest, food bowl, 500 gold) are debug conveniences; the long-term item list is undecided.
- **Entrypoints:** `buildables/`, `autoload/data.gd`, design notes.
- **Approach:** Draft a proposed item progression (core habitat, specialty training gear, cosmetic clutter). Note costs, unlock triggers, and desired effects so they can be implemented incrementally.
- **Definition of done:** README/TODO captures an ordered list of candidate items plus rationale for early/mid/late-game availability.

### 6. Naming + theming review
- **Problem:** Species names are placeholders and may change as the art style evolves.
- **Entrypoints:** `resources/creature/data/**/*.tres`, design reference image.
- **Approach:** Propose naming conventions (e.g., elemental roots + suffix) and outline how recolors or variants could be labeled consistently. Update the design reference if possible.
- **Definition of done:** Documented naming guide plus a list of proposed replacements for existing species.

## Tooling

### 7. Evolution tree asset ingestion
- **Problem:** The evolution-diagram image currently lives outside the repo.
- **Entrypoints:** `/assets/design/` (create), README link.
- **Approach:** Check the diagram into version control, preferably as both the editable source (draw.io, Excalidraw, etc.) and an exported PNG. Reference it from README once available.
- **Definition of done:** Diagram sits in the repo, README links to it, and future contributors can edit the source.

