class_name NinePatchFrame
extends RefCounted
## Generates a pixel-art nine-patch frame texture at runtime and applies it to buttons/panels.

static var _frame_tex: ImageTexture = null
const _SIZE := 24
const _BORDER := 3

static func _get_texture() -> ImageTexture:
	if _frame_tex:
		return _frame_tex
	var s := _SIZE
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var outer := Color(1.0, 1.0, 1.0, 0.9)
	var mid := Color(0.85, 0.85, 0.88, 0.7)
	var inner := Color(0.55, 0.55, 0.6, 0.45)
	var fill := Color(0.09, 0.12, 0.2, 0.95)
	var clear := Color(0, 0, 0, 0)
	for y in range(s):
		for x in range(s):
			var dist_l: int = x
			var dist_r: int = s - 1 - x
			var dist_t: int = y
			var dist_b: int = s - 1 - y
			var dist_edge: int = mini(mini(dist_l, dist_r), mini(dist_t, dist_b))
			var in_corner := (dist_l + dist_t < 2) or (dist_r + dist_t < 2) or (dist_l + dist_b < 2) or (dist_r + dist_b < 2)
			if in_corner:
				img.set_pixel(x, y, clear)
			elif dist_edge == 0:
				img.set_pixel(x, y, outer)
			elif dist_edge == 1:
				img.set_pixel(x, y, mid)
			elif dist_edge == 2:
				img.set_pixel(x, y, inner)
			else:
				img.set_pixel(x, y, fill)
	_frame_tex = ImageTexture.create_from_image(img)
	return _frame_tex

static func _make_sb(content_l: float, content_t: float, content_r: float, content_b: float) -> StyleBoxTexture:
	var tex := _get_texture()
	if not tex:
		return null
	var m := _BORDER + 1
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = m
	sb.texture_margin_top = m
	sb.texture_margin_right = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = content_l
	sb.content_margin_top = content_t
	sb.content_margin_right = content_r
	sb.content_margin_bottom = content_b
	return sb

static func apply_to_button(btn: Button) -> void:
	if not btn:
		return
	var sb_normal := _make_sb(12.0, 8.0, 12.0, 8.0)
	if not sb_normal:
		return
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("focus", sb_normal)
	var sb_hover := sb_normal.duplicate() as StyleBoxTexture
	sb_hover.expand_margin_left = 2.0
	sb_hover.expand_margin_top = 2.0
	sb_hover.expand_margin_right = 2.0
	sb_hover.expand_margin_bottom = 2.0
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb_normal.duplicate() as StyleBoxTexture
	sb_pressed.expand_margin_left = 3.0
	sb_pressed.expand_margin_top = 3.0
	sb_pressed.expand_margin_right = 3.0
	sb_pressed.expand_margin_bottom = 3.0
	btn.add_theme_stylebox_override("pressed", sb_pressed)

static func apply_to_panel(panel: PanelContainer) -> void:
	if not panel:
		return
	var sb := _make_sb(16.0, 10.0, 16.0, 10.0)
	if sb:
		panel.add_theme_stylebox_override("panel", sb)

static func apply_to_compact_panel(panel: PanelContainer) -> void:
	if not panel:
		return
	var sb := _make_sb(8.0, 6.0, 8.0, 6.0)
	if sb:
		panel.add_theme_stylebox_override("panel", sb)

static func apply_to_all_buttons(root: Node) -> void:
	if root is Button:
		apply_to_button(root as Button)
	for child in root.get_children():
		apply_to_all_buttons(child)
