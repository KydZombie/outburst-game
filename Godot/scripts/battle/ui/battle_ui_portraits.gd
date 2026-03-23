extends RefCounted
class_name BattleUIPortraits
## Loads and applies character portraits. Shared by party list and enemy panel.

const _NinePatch := preload("res://scripts/ui/nine_patch_frame.gd")

const CHAR_PORTRAITS: Dictionary = {
	"Niko": "res://art/tile_0121.png",
	"Remi": "res://art/tile_0088.png",
	"Arna": "res://art/tile_0108.png",
	"Caelum": "res://art/tile_0111.png",
	"Syd": "res://art/tile_0096.png",
	"Jeff": "res://art/tile_0110.png",
	"Jeff The Crab": "res://art/tile_0110.png",
}

static func get_portrait_path(character_name: String) -> String:
	if CHAR_PORTRAITS.has(character_name):
		return CHAR_PORTRAITS[character_name] as String
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
		if portrait:
			var name_str: String = p.get("name", "") as String
			var path: String = get_portrait_path(name_str)
			var tex: Texture2D = load_portrait(path, fallback)
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
