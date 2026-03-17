# Outburst Game
Battle UI
Godot 4.x card battler UI  with design system colors, hand manager (max 4 cards), drag-to-play, fan layout, and animated panels.

## Design System

- **Background:** `#0B0F1E`
- **Panel:** `#12182D`
- **Card base:** `#1B233D`
- **Hover glow:** `#2A3B6F`
- **Enemy health:** `#FF3B3B`
- **Player health:** `#34D399`
- **Energy:** `#FACC15`

## Scene Structure

```
BattleScene
├── DragLayer (CanvasLayer, for dragging cards on top)
├── Background
│   ├── Margin
│   │   ├── Main (HBox)
│   │   │   ├── LeftPanel → PartyList (portrait, name, health bar per member)
│   │   │   ├── CenterArea → DeckCounter, DiscardCounter, HandContainer
│   │   │   └── RightPanel → EnemyPanel (portrait, name, HP, intent)
│   │   └── BottomBar → Energy, [ END TURN ], Controls
```

## File Structure

- **scenes/battle/battle_scene.tscn** — Main battle layout (run as main scene)
- **scenes/card_ui.tscn** + **scenes/card_ui.gd** — Single card (cost, title, icon, description, base/hover/drag styles)
- **scripts/battle/battle_ui_manager.gd** — UI only; game logic in scripts/battle/
- **scripts/hand_manager.gd** — Max 4 cards, add (evict oldest if full), fan layout (-10° to +10°)
- **scripts/card_drag_system.gd** — Drag card to cursor, release above threshold to play
- **resources/** — `card_base_stylebox.tres`, `card_hover_stylebox.tres`, `card_drag_stylebox.tres`, `battle_theme.tres`

## Features

- **Hand:** Max 4 cards; drawing when full removes leftmost then adds.
- **Cards:** Cost, title, icon (⚔/🛡/✦), description; base / hover / drag styleboxes; hover scale 1.08 and raise.
- **Drag:** Card follows cursor on drag; release above threshold = play; else return to hand.
- **Fan layout:** Cards in hand with slight rotation and dynamic spacing.
- **Panels:** Party list with health bars; enemy with intent; bottom bar with energy and End Turn (hover scale/color).
- **Controls:** 1–3 play card, D draw, S end turn, Q quit.

## Run

1. Open the project in Godot 4.x.
2. In **Project → Project Settings → General**, confirm **Application → Run → Main Scene** is `res://scenes/battle/battle_scene.tscn`.
3. Press **F5** (or **Run Project**) so the battle scene runs, not a different scene.
4. Window is 1280×720 with aspect **keep** (no stretch distortion). Resize the game window if the layout looks wrong.
