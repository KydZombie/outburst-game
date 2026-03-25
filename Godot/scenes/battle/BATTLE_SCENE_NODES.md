# Battle Scene – Node Tree & Script Reference

This document lists every node in `battle_scene.tscn` that the battle UI script uses, so you can adjust the scene in the editor without breaking references.

**Script:** `res://scripts/battle/battle_ui_manager.gd`  
**Root:** `BattleScene` (Control)

**Hint copy (uniform look):** `BattleHintTheme` in `res://scripts/battle/ui/battle_hint_theme.gd` sets shared white fill + blue outline for `TargetPrompt`, `AngryComboHint`, `ControlsLabel` (applied in `BattleUIManager._ready`), and for the runtime **turn banner** label (`BattleUIRuntime._ensure_turn_banner`). Tweak sizes there to keep all instructional text consistent.

---

## Scene tree (path = from root)

All paths are relative to the root node `BattleScene`. The script uses `get_node_or_null("...")` with these paths (root is the node that has the script).

---

### Root level

| Node           | Type         | Script variable   | Notes                                      |
|----------------|--------------|-------------------|--------------------------------------------|
| `DragLayer`    | CanvasLayer  | `_drag_layer`     | Cards are reparented here while dragging.  |

---

### Background

| Node             | Type              | Script variable | Notes                          |
|------------------|-------------------|-----------------|--------------------------------|
| `Background`     | PanelContainer    | —               | Full-screen background panel.  |
| `Background/BackgroundTexture` | TextureRect | —         | Uses `res://art/background.png`. |
| `Background/Margin`            | MarginContainer | —      | Margins around main content.    |
| `Background/Margin/VBox`       | VBoxContainer  | —      | Main vertical stack (Main + BottomBar). |

---

### Main (left / center / right)

| Node                             | Type              | Script variable  | Notes                          |
|----------------------------------|-------------------|------------------|--------------------------------|
| `Background/Margin/VBox/Main`    | HBoxContainer     | —                | LeftPanel, CenterArea, RightPanel. |
| `.../Main/LeftPanel`             | PanelContainer    | `_left_panel`    | Party list container.          |
| `.../Main/LeftPanel/PartyList`   | VBoxContainer     | `_party_list`    | One row per party member.      |

**Each party row** (Niko, Remi, Arna, Caelum) – script expects **exactly this structure** per row:

| Node (relative to row) | Type         | Used by script                    |
|-------------------------|-------------|-----------------------------------|
| `HBox`                  | HBoxContainer | —                               |
| `HBox/Portrait`         | TextureRect | `_apply_party_portraits()` – set at runtime or from `res://art/<name>.png`. |
| `HBox/VBox`             | VBoxContainer | —                              |
| `HBox/VBox/Name`        | Label       | `_refresh_party()` – character name. |
| `HBox/VBox/HP`          | Label       | `_refresh_party()` – "hp/max_hp".   |
| `HBox/VBox/HealthBar`   | ProgressBar | `_refresh_party()` – value, max_value. |

**Do not rename** `HBox`, `Portrait`, `VBox`, `Name`, `HP`, `HealthBar` inside each party row.

---

### Center area (deck, discard, hand)

| Node                                                       | Type           | Script variable   | Notes                                  |
|------------------------------------------------------------|----------------|-------------------|----------------------------------------|
| `.../Main/CenterArea`                                      | VBoxContainer  | `_center_area`    | Deck row + hand area.                  |
| `.../CenterArea/DeckDiscardRow`                            | HBoxContainer  | —                 | Deck \| **OutburstLabel** \| Discard.   |
| `.../DeckDiscardRow/OutburstLabel`                         | Label          | —                 | Center title **OUTBURST** (large).       |
| `.../DeckDiscardRow/DeckCounter`                           | PanelContainer| —                 | "Deck" card-style panel.                |
| `.../DeckCounter/VBox/Count`                               | Label          | `_deck_counter`   | Number of cards in deck (e.g. "9").    |
| `.../DeckCounter/VBox/Label`                               | Label          | —                 | Text "DECK".                           |
| `.../DeckDiscardRow/DiscardCounter`                         | PanelContainer| —                 | "Discard" panel.                       |
| `.../DiscardCounter/VBox/Count`                            | Label          | `_discard_counter`| Number of cards in discard (e.g. "0"). |
| `.../DiscardCounter/VBox/Label`                            | Label          | —                 | Text "DISCARD".                        |
| `.../CenterArea/HandContainer`                             | Control        | `_hand_container` | **Cards are added here at runtime.**   |
| `.../CenterArea/PlayZone`                                  | Control        | `_play_zone`      | Tinted center area; drop target.       |
| `.../PlayZone/PlayZoneFill`                                | ColorRect      | —                 | Semi-transparent fill.               |
| `.../PlayZone/AngryComboHint`                              | RichTextLabel  | `_angry_combo_hint` | Same centered rect as `TargetPrompt`; shows Gain Energy hint at 0 energy (if that card is in hand), or Angry Punch combo when hovering that card. |
| `.../PlayZone/TargetPrompt`                                | Label          | `_target_prompt`  | Ally-targeting instructions.           |
| `.../PlayZone/PlayEffect`                                  | Label          | `_play_effect`    | Big card title on play.                |

---

### Right panel (enemy)

| Node                                           | Type        | Script variable   | Notes                                  |
|------------------------------------------------|-------------|-------------------|----------------------------------------|
| `.../Main/RightPanel`                          | PanelContainer | `_right_panel`  | Drop zone for playing cards.           |
| `.../RightPanel/EnemyPanel`                    | VBoxContainer | `_enemy_panel`  | Intent, portrait, name, HP.            |
| `.../EnemyPanel/IntentLabel`                   | Label       | `_enemy_intent`   | e.g. "⚔ 12".                          |
| `.../EnemyPanel/EnemyPortrait`                 | TextureRect | `_enemy_portrait` | Set at runtime or from `res://art/jeff_the_crab.png`. |
| `.../EnemyPanel/EnemyName`                     | Label       | `_enemy_name`     | e.g. "JEFF THE CRAB".                  |
| `.../EnemyPanel/EnemyHP`                       | Label       | `_enemy_hp`       | e.g. "60 / 60".                        |
| `.../EnemyPanel/EnemyHealthBar`                | ProgressBar | `_enemy_health_bar` | HP fill; updated with state.       |

---

### Bottom bar

| Node                                              | Type           | Script variable   | Notes                |
|---------------------------------------------------|----------------|-------------------|----------------------|
| `Background/Margin/VBox/BottomBar`                | PanelContainer | `_bottom_bar`     | Bottom strip.        |
| `.../BottomBar/HBox`                              | HBoxContainer  | —                 | Energy, button, controls. |
| `.../HBox/EnergyBox`                              | PanelContainer | —                 | Yellow energy box.   |
| `.../HBox/EnergyBox/EnergyLabel`                  | Label          | `_energy_display` | e.g. "Energy: 4 / 4". |
| `.../HBox/EndTurnButton`                          | Button         | `_end_turn_btn`   | "[ END TURN ]".      |
| `.../HBox/ControlsLabel`                          | Label          | `controls_label`  | Hotkey hint (D draw, S end turn, **M** main menu); `BattleHintTheme` styles. |

---

## Summary – do not rename or remove

- **Root:** `BattleScene`, `DragLayer`, `Background`, `Margin`, `VBox`, `Main`, `BottomBar`
- **Left:** `LeftPanel`, `PartyList`, and for each row: `HBox`, `Portrait`, `VBox`, `Name`, `HP`, `HealthBar`
- **Center:** `CenterArea`, `DeckDiscardRow`, `DeckCounter`, `DiscardCounter`, `HandContainer`, `PlayZone` (`PlayZoneFill`, `AngryComboHint`, `TargetPrompt`, `PlayEffect`), and `VBox/Count`/`Label` under each counter
- **Right:** `RightPanel`, `EnemyPanel`, `IntentLabel`, `EnemyPortrait`, `EnemyName`, `EnemyHP`
- **Bottom:** `BottomBar`, `HBox`, `EnergyBox`, `EnergyLabel`, `BottomBarSpacerL`, `EndTurnButton`, `BottomBarSpacerR`, `ControlsLabel`

You can safely change: **themes**, **styles**, **colors**, **fonts**, **margins**, **custom_minimum_size**, **text content** (script overwrites Count, Name, HP, Energy, etc. at runtime). You can change **party row names** (Niko, Remi, …) as long as you keep the same **child structure** (HBox → Portrait, VBox → Name, HP, HealthBar).

---

## Runtime-only nodes

- **HandContainer** gets **CardUI** instances added by `HandManager` when the game runs (from `res://scenes/card_ui.tscn`). There is no CardUI in the scene by default.
- **DragLayer** gets a card temporarily reparented into it only while that card is being dragged.
