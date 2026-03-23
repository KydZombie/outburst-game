extends RefCounted
class_name BattleUIPortraits
## Loads and applies character portraits. Shared by party list and enemy panel.
## Party members with entries in SHEET_ROW get emotion-based portraits from the
## 4×4 sprite sheet (columns: Neutral / Happy / Sad / Angry).
## Characters not in the sheet fall back to a static tile portrait.

const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

const SHEET_PATH := "res://outburst-character-sheet.png"
const FRAME_SIZE := 48

const SHEET_ROW: Dictionary = {
	"Niko": 0,
	"Remi": 1,
	"Arna": 2,
	"Caelum": 3,
}

const EMOTION_COL: Dictionary = {
	"": 0,
	"Happy": 1,
	"Sad": 2,
	"Angry": 3,
}

const STATIC_PORTRAITS: Dictionary = {
	"Niko": "res://art/tile_0121.png",
	"Remi": "res://art/tile_0088.png",
	"Arna": "res://art/tile_0108.png",
	"Caelum": "res://art/tile_0111.png",
	"Jeff": "res://art/tile_0110.png",
	"Jeff The Crab": "res://art/tile_0110.png",
}

static var _sheet: Texture2D = null
static var _atlas_cache: Dictionary = {}

static func _get_sheet() -> Texture2D:
	if _sheet:
		return _sheet
	if ResourceLoader.exists(SHEET_PATH):
		_sheet = ResourceLoader.load(SHEET_PATH) as Texture2D
	return _sheet

static func get_dominant_emotion(emotions: Dictionary) -> String:
	var best_key := ""
	var best_val := 0
	for key in ["Angry", "Sad", "Happy"]:
		var val: int = emotions.get(key, 0) as int
		if val > best_val:
			best_val = val
			best_key = key
	return best_key

static func get_emotion_portrait(char_name: String, emotion: String) -> Texture2D:
	if not SHEET_ROW.has(char_name):
		return null
	var sheet := _get_sheet()
	if not sheet:
		return null
	var row: int = SHEET_ROW[char_name]
	var col: int = EMOTION_COL.get(emotion, 0)
	var key := "%d_%d" % [row, col]
	if _atlas_cache.has(key):
		return _atlas_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	_atlas_cache[key] = atlas
	return atlas

static func get_portrait_path(character_name: String) -> String:
	if STATIC_PORTRAITS.has(character_name):
		return STATIC_PORTRAITS[character_name] as String
	return "res://art/%s.png" % character_name.to_lower().replace(" ", "_")

static func make_placeholder_texture(fill_color: Color, size_x: int = 40, size_y: int = 40) -> ImageTexture:
	var img := Image.create(size_x, size_y, false, Image.FORMAT_RGBA8)
	if img == null or img.is_empty():
		return null
	img.fill(fill_color)
	return ImageTexture.create_from_image(img)

static func load_portrait(path: String, fallback_color: Color, size_x: int = 40, size_y: int = 40) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		var res := ResourceLoader.load(path) as Texture2D
		if res:
			return res
	var placeholder := make_placeholder_texture(fallback_color, size_x, size_y)
	return placeholder if placeholder else null

static func apply_nine_patch_to_party_rows(party_list: Control) -> void:
	if not party_list:
		return
	for i in range(party_list.get_child_count()):
		var row := party_list.get_child(i) as PanelContainer
		if row:
			_NinePatch.apply_to_compact_panel(row)

static func apply_party_portraits(party_list: Control, party: Array[Dictionary]) -> void:
	if not party_list:
		return
	var fallback := Color(0.2, 0.25, 0.4, 1)
	for i in range(min(party_list.get_child_count(), party.size())):
		var row := party_list.get_child(i)
		var p: Dictionary = party[i]
		var portrait := row.get_node_or_null("HBox/Portrait") as TextureRect
		if not portrait:
			continue
		var name_str: String = p.get("name", "") as String
		var emotions: Dictionary = p.get("emotions", {}) as Dictionary
		var dominant: String = get_dominant_emotion(emotions)
		var tex: Texture2D = get_emotion_portrait(name_str, dominant)
		if not tex:
			var path: String = get_portrait_path(name_str)
			tex = load_portrait(path, fallback)
		if tex:
			portrait.texture = tex

static func apply_enemy_portrait(enemy_portrait: TextureRect, enemies: Array[Dictionary]) -> void:
	if not enemy_portrait:
		return
	var fallback := Color(0.25, 0.2, 0.2, 1)
	if enemies.is_empty():
		var placeholder_tex: ImageTexture = make_placeholder_texture(fallback, 120, 120)
		if placeholder_tex:
			enemy_portrait.texture = placeholder_tex
		return
	var name_str: String = enemies[0].get("name", "") as String
	var path: String = get_portrait_path(name_str)
	var portrait_tex: Texture2D = load_portrait(path, fallback, 120, 120)
	if portrait_tex:
		enemy_portrait.texture = portrait_tex
