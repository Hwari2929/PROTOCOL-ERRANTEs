# Project Brief — PROTOCOL ERRANTES (Battle Slice)

## What we are building
A vertical slice of the **combat layer** for PROTOCOL ERRANTES, a bar-management +
TFT-style auto-battler hybrid set in the ERRANTES universe. This slice covers ONLY
the battle side (GDD roadmap Phase 3). The run is a short **quest (의뢰)** of 3 combat
**nodes**. Node and combat are separate concepts: the quest advances node-by-node,
and inside each combat node a **TFT-style round** plays out — a (future) preparation
phase followed by a **real-time, second-based auto-battle**. Between nodes the player
gains **resonance (공명도)**, raises their **resonance grade (공명 등급)**, and on each
grade-up picks one of three **MAJOR augments (증강)**. Win by clearing all 3 nodes;
lose if the player team is wiped.

Out of scope for this slice (deferred): the bar-management mode, shop/economy buying,
tactical card decks, equipment/sets, gacha, synergy-by-tag, and objectives other than
elimination. The generic TFT combat section in GDD.md (전사/마법사 synergies, shop) is a
superseded placeholder; this slice follows the uploaded ERRANTES class docs instead.

## Tech stack
- Engine/runtime: Godot 4.6 (arm64), `gl_compatibility` renderer (iOS/Xogot compatible)
- Language: GDScript (typed)
- Existing autoloads reused: `EventBus`, `GameManager`, `ResourceManager`
- Compile gate: `godot --headless --import`; smoke: `--quit-after N`; contract: Expression
  over the scene tree; pixel screenshot via xvfb when available.

## Project tree (slice-relevant)
```
pe_game/
  project.godot                 # gl_compat, autoloads, main_scene
  scenes/
    main.tscn                   # Main: Camera2D + BattleField + Resonance +
                                #   AugmentSystem + BattleSession + UI/BattleHUD
    battle/
      battle_field.tscn         # BattleField > Units
      unit.tscn                 # a single unit
  scripts/
    core/                       # EventBus / GameManager / ResourceManager (existing)
    battle/
      unit.gd                   # PE1 — auto-battle unit behavior
      battle_field.gd           # PE2 — roster spawn + victory/defeat resolution
      resonance.gd              # PE3 — 공명도/등급/크레딧
      augment.gd                # PE4 — MAJOR augment pool + 3-choice UI + apply
      battle_session.gd         # PE5 — quest node-chain orchestration
    ui/
      battle_hud.gd             # PE6 — HUD + result banner
  docs/                         # this brief + dev guidelines
```

## Data & state
- All combat systems are **nodes pre-wired in main.tscn**; each issue fills one node's
  script. This keeps contracts tree-based and stable.
- Units are spawned at runtime by `BattleField` into the `Units` container and tagged
  with `team` (0 = player, 1 = enemy) and group `"unit"`.
- The player roster for the slice = **주인공 + 레인저 + 뱅가드** (3 units). The 4 MAJOR
  classes available are 레인저 / 뱅가드 / 커맨더 / 메딕 (simplest tactical type: one MAJOR
  augment choice per resonance grade). Class stat configs live as a const table in
  `battle_field.gd`.
- Resonance grade thresholds (cumulative resonance points): grade 2 = 8, 3 = 12,
  4 = 24, 5 = 40 (from the ERRANTES terminology doc).
- No persistence in this slice (a run is in-memory). Energy credits / resonance reset
  per run.

## Design direction (UI/UX)
- 2D top-down. Placeholder visuals: units draw themselves via `_draw()` (blue = player,
  red = enemy) — NO texture dependency yet; the Artist pipeline adds sprites later.
- HUD is functional (labels/bars), Korean-facing text is rendered by the report layer;
  in-engine strings may stay short/English for the slice.
- Real-time auto-battle: the player does not micro-control units during COMBAT; player
  decisions happen between nodes (augment choice).

## Pipeline & phases
1. **Phase 1 — Combat core** (PE1, PE2): units acquire/move/attack/die; battlefield
   spawns roster vs wave and resolves victory/defeat with EventBus signals.
   Exit: a single combat node plays out and reports a result.
2. **Phase 2 — Growth** (PE3, PE4, PE5): resonance grade + credits; MAJOR augment pool
   with 3-choice apply; quest orchestration across 3 nodes with augment between nodes.
   Exit: a full 3-node quest is playable end-to-end with grade-ups and augments.
3. **Phase 3 — Presentation** (PE6): HUD reflects HP/grade/credits/node progress and a
   win/lose banner. Exit: run state is legible on screen; screenshot proof.
