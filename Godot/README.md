# Outburst Game
Battle UI  
Godot 4.x card battler UI with design system colors, hand manager, drag-to-play, fan layout, and animated panels.

## Turn rules (see `scripts/battle/turn_manager.gd`)

- **`HAND_SIZE` = 5** — cards drawn at battle start and after each full hand discard at end of player turn.
- **`MAX_CARD_PLAYS_PER_TURN` = 6** — cap on playing cards and on paid draws in one player turn (separate from hand size).

The hand can hold more than five cards if you draw extra during a turn; there is no separate “max 4” cap in code.

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
- **scripts/battle/battle_ui_manager.gd** — Wires UI to battle logic
- **scripts/battle/turn_manager.gd** — Hand size, max plays per turn, enemy phase flow
- **scripts/hand_manager.gd** — Fan layout (~−10° to +10°), hover lift, hand card nodes
- **scripts/card_drag_system.gd** — Drag card to cursor, release above threshold to play
- **resources/** — `card_base_stylebox.tres`, `card_hover_stylebox.tres`, `card_drag_stylebox.tres`, `battle_theme.tres`

## Features

- **Hand:** Default draw count `TurnManager.HAND_SIZE` (5); layout scales with however many cards are in hand.
- **Cards:** Cost, title, icon (⚔/🛡/✦), description; base / hover / drag styleboxes; hover scale and raise.
- **Drag:** Card follows cursor on drag; release above threshold = play; else return to hand.
- **Fan layout:** Slight rotation and dynamic spacing.
- **Panels:** Party list with health bars; enemy with intent; bottom bar with energy and End Turn.
- **Deck / discard:** Click counts to open a list/summary overlay in the **play zone** (center area).

## Controls (battle)

Bindings live in **Project → Project Settings → Input** (`project.godot`). Defaults:

| Action | Key | Notes |
|--------|-----|--------|
| Play hand slot 1–3 | **1**, **2**, **3** | First three cards in hand |
| Draw card | **D** | Costs energy when used |
| End turn | **S** | Same as Skip turn action |
| Return to menu | **M** | From battle |
| Quit game | **Q** | Global `quit_game` action |

When choosing a **party target** for a card, **1–5** pick party slots (see `InputController`).

## Run

1. Open the project in **Godot 4.6** (with **.NET** / C# support if you use the adapter).
2. In **Project → Project Settings → General**, confirm **Application → Run → Main Scene** is `res://scenes/main.tscn` (or the scene you want).
3. Press **F5** (or **Run Project**).
4. Default window size is **1280×860** (see `project.godot`). Resize if the layout needs more room.

---

## Missing script (diagnosis)

If the Godot Output/Console shows a **missing script** or **script not found** error:

### 1. Get the exact path from the error

- Run the project (F5), open **Output** (or **Debugger → Console**).
- Find the line that says the script is missing or could not be loaded. It will mention a path like `res://scripts/...` or a C# class name.

### 2. Check against known script references

All of these paths have been verified to exist under the `Godot/` project folder:

| Reference | Path | File exists |
|-----------|------|-------------|
| Main scene loader | `res://scenes/main.gd` | ✓ |
| Main menu | `res://scripts/ui/main_menu.gd` | ✓ |
| Battle UI | `res://scripts/battle/battle_ui_manager.gd` | ✓ |
| Battle C# adapter | `res://scripts/GodotBattleAdapter.cs` | ✓ |
| Audio manager | `res://scripts/audio_manager.gd` | ✓ |
| Card UI | `res://scenes/card_ui.gd` | ✓ |
| Credits | `res://scripts/ui/credits_screen.gd` | ✓ |
| Game over | `res://scripts/ui/game_over_screen.gd` | ✓ |
| Tutorial (how to play) | `res://scripts/ui/settings_screen.gd` | ✓ |
| Settings (volume) | `res://scripts/ui/settings_menu.gd` | ✓ |
| **Autoload** | `res://scripts/battle_result.gd` | ✓ |

### 3. Apply the fix

- **If the error path is a GDScript (`.gd`):**  
  - Confirm the file exists at that path under your `Godot/` folder (e.g. `res://scripts/foo.gd` → `Godot/scripts/foo.gd`).  
  - If the file was moved or renamed, either move it back or update the scene/autoload that references it to the new path.

- **If the error is about a C# script (e.g. `GodotBattleAdapter` or `.cs`):**  
  1. In Godot: **Build → Build Project** (or **Ctrl+Shift+B**). Wait until the build finishes.  
  2. In `Godot/Outburst.Godot.csproj`, ensure **`EnableDynamicLoading`** is **`true`** (it is by default).  
  3. **Restart Godot** (close and reopen the project) so it reloads the C# assembly.  
  4. From the repo root you can also run: `dotnet build Godot/Outburst.Godot.csproj` (requires .NET 8 and Godot.NET.Sdk restored). Then reopen Godot.

Most “missing script” issues in this project are resolved by building the C# project inside Godot and restarting the editor.
