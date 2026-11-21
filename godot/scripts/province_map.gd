extends Control
signal province_clicked(province_id: String)

var province_data: Array = []
var point_cache: Array[Vector2] = []

func set_provinces(data: Array) -> void:
	province_data = data
	queue_redraw()

func _province_point(province: Dictionary) -> Vector2:
	return Vector2(float(province.get("x", 0.5)), float(province.get("y", 0.5))) * size

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#172b35"), true)
	var land := PackedVector2Array([
		Vector2(size.x * 0.05, size.y * 0.13),
		Vector2(size.x * 0.24, size.y * 0.06),
		Vector2(size.x * 0.40, size.y * 0.17),
		Vector2(size.x * 0.48, size.y * 0.35),
		Vector2(size.x * 0.40, size.y * 0.52),
		Vector2(size.x * 0.56, size.y * 0.60),
		Vector2(size.x * 0.92, size.y * 0.55),
		Vector2(size.x * 0.98, size.y * 0.79),
		Vector2(size.x * 0.73, size.y * 0.91),
		Vector2(size.x * 0.43, size.y * 0.84),
		Vector2(size.x * 0.27, size.y * 0.68),
		Vector2(size.x * 0.08, size.y * 0.48)
	])
	draw_colored_polygon(land, Color("#6d7255"))
	draw_polyline(PackedVector2Array([land[0], land[1], land[2], land[3], land[4], land[5], land[6], land[7], land[8], land[9], land[10], land[11], land[0]]), Color("#c6b58b"), 2.0, true)
	for province in province_data:
		var point := _province_point(province)
		var owned: bool = str(province.get("realm", "")) == "ottoman"
		var fill := Color("#c29a4b") if owned else Color("#9b6d78")
		draw_circle(point, 9.0, Color("#161a1d"))
		draw_circle(point, 6.5, fill)
		draw_string(ThemeDB.fallback_font, point + Vector2(10, 4), str(province.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 12), "ALTIN: Osmanlı   •   GÜL: Diğer devletler", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f2e5c9"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for province in province_data:
			if _province_point(province).distance_to(event.position) <= 18.0:
				province_clicked.emit(str(province.get("id", "")))
				accept_event()
				return
