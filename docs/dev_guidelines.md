# Development Guidelines (Coder reference) — PROTOCOL ERRANTES

Minimum safety rules. Every change MUST follow these. Many encode real bugs that
previously broke Godot harness projects.

## Naming
- snake_case for vars/functions; PascalCase for node names and any `class_name`.
- Signals in past tense (e.g. `damage_dealt`, `round_ended`), matching the existing
  EventBus convention.
- Private helpers prefixed with `_`.
- One script per node; file name matches the script's role (unit.gd, resonance.gd).

## Structure & reuse
- Cross-node references: prefer **groups + signals** over absolute paths from unrelated
  nodes. Units are in group `"unit"` and carry a `team` int (0 = player, 1 = enemy).
- Use the existing **autoloads**: `EventBus` (global signals), `ResourceManager`
  (gold/tokens), `GameManager` (state). Emit battle progress on EventBus signals that
  already exist: `round_started(round_number)`, `round_ended(round_number, victory)`,
  `battle_session_started`, `battle_session_ended(victory)`.
- Combat systems are **separate nodes in main.tscn** (BattleField / Resonance /
  AugmentSystem / BattleSession / UI/BattleHUD). A node reaches a sibling via
  `get_parent().get_node_or_null("Resonance")` etc., guarded with `get_node_or_null`.
- Do NOT duplicate logic across classes; extend or call shared methods.

## GDScript / Godot 4 patterns (REQUIRED)
- **Type your locals.** `var x := min(a, b)` infers Variant and triggers a warning this
  project treats as an ERROR. Use explicit types and typed math helpers:
  `var x: int = mini(a, b)`, `var f: float = maxf(a, b)`.
- Theme from code: use `add_theme_font_size_override("font_size", n)` and
  `add_theme_color_override(...)`. NEVER assign `theme_override_font_sizes[...]` or
  `theme_override_colors[...]` in code — inspector-only paths cause parse errors.
- Connect signals in `_ready()`. Match signal names EXACTLY between emitter and listener.
- Use `@onready` for child node references; guard optional/cross-node lookups with
  `get_node_or_null`.
- A node that pauses the tree (e.g. an augment menu) and still needs input must set
  `process_mode = Node.PROCESS_MODE_ALWAYS`.
- Placeholder visuals via `_draw()` are fine (headless skips rendering harmlessly); do
  not require textures for units in this slice.
- Iterating `for i in count` over an int is valid; cast to float for math:
  `(float(i) - float(count - 1) / 2.0)`.

## Preservation (do not regress)
- `battle_field.gd` MUST keep: spawning into the `$Units` container, tagging each unit
  with `team` and group `"unit"`, and the `units_of(team) -> Array` API. When PE2 adds
  resolution, do not remove the spawn.
- `unit.gd` MUST keep a `setup(team: int)` entry point and membership in group `"unit"`.
- When editing a node already wired into main.tscn, integrate new behavior into the
  existing flow; do not delete unrelated existing members or break sibling lookups.
- Keep the `EventBus` / `GameManager` / `ResourceManager` autoload scripts free of
  `class_name` (they are autoloads; a `class_name` equal to the autoload name errors).

## Must-not
- Do not change the renderer away from `gl_compatibility` (breaks iOS/Xogot).
- Do not introduce Variant-inference warnings (treated as errors here).
- Do not hard-code unit instances into scenes; units are spawned at runtime.
- Do not reference the deferred bar/gacha/shop systems from battle scripts.
