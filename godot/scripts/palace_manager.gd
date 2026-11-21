extends Node3D

var dialogue_layer: CanvasLayer
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var battle_commander: BattleCommander
var map_panel: PanelContainer
var map_list: VBoxContainer
var map_detail: Label
var treasury_label: Label
var date_label: Label
var provinces: Array = []
var selected_province: Dictionary = {}

func _ready() -> void:
	battle_commander = BattleCommander.new()
	battle_commander.name = "BattleCommander"
	add_child(battle_commander)
	_load_provinces()
	_build_dialogue_ui()
	_build_campaign_hud()
	_add_ambassador()
	_refresh_campaign_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_map()

func _load_provinces() -> void:
	var file := FileAccess.open("res://data/provinces_1444.json", FileAccess.READ)
	if file == null:
		push_error("Eyalet verisi bulunamadı.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		provinces = parsed.get("provinces", [])

func _add_ambassador() -> void:
	var scene := load("res://scenes/ambassador.tscn") as PackedScene
	if scene:
		add_child(scene.instantiate())

func _build_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.name = "DialogueLayer"
	add_child(dialogue_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-300, -300)
	panel.size = Vector2(600, 270)
	dialogue_layer.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	dialogue_title = Label.new()
	dialogue_title.add_theme_font_size_override("font_size", 24)
	layout.add_child(dialogue_title)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size.y = 65
	layout.add_child(dialogue_text)
	dialogue_choices = VBoxContainer.new()
	layout.add_child(dialogue_choices)
	panel.visible = false
	panel.name = "DialoguePanel"
	dialogue_layer.set_meta("panel", panel)

func _build_campaign_hud() -> void:
	var hud := $HUD
	var top := HBoxContainer.new()
	top.position = Vector2(20, 65)
	hud.add_child(top)
	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 18)
	top.add_child(date_label)
	treasury_label = Label.new()
	treasury_label.add_theme_font_size_override("font_size", 18)
	top.add_child(treasury_label)
	var map_button := Button.new()
	map_button.text = "Dünya Haritası [M]"
	map_button.pressed.connect(_toggle_map)
	top.add_child(map_button)
	var advance_button := Button.new()
	advance_button.text = "1 Gün İlerle"
	advance_button.pressed.connect(_advance_day)
	top.add_child(advance_button)
	var save_button := Button.new()
	save_button.text = "Kaydet"
	save_button.pressed.connect(_save_game)
	top.add_child(save_button)
	map_panel = PanelContainer.new()
	map_panel.position = Vector2(30, 115)
	map_panel.size = Vector2(520, 520)
	hud.add_child(map_panel)
	map_panel.visible = false
	var columns := HBoxContainer.new()
	map_panel.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 205
	columns.add_child(left)
	var heading := Label.new()
	heading.text = "EYALETLER"
	heading.add_theme_font_size_override("font_size", 20)
	left.add_child(heading)
	map_list = VBoxContainer.new()
	left.add_child(map_list)
	var right := VBoxContainer.new()
	columns.add_child(right)
	map_detail = Label.new()
	map_detail.custom_minimum_size = Vector2(250, 180)
	map_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(map_detail)
	var tax_button := Button.new()
	tax_button.text = "Vergi tahsil et"
	tax_button.pressed.connect(_collect_tax)
	right.add_child(tax_button)
	var close_button := Button.new()
	close_button.text = "Haritayı kapat"
	close_button.pressed.connect(_toggle_map)
	right.add_child(close_button)
	for province in provinces:
		var button := Button.new()
		button.text = province.name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_province.bind(province))
		map_list.add_child(button)
	if not provinces.is_empty():
		_select_province(provinces[0])

func _toggle_map() -> void:
	map_panel.visible = not map_panel.visible
	if map_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _select_province(province: Dictionary) -> void:
	selected_province = province
	map_detail.text = "%s\n\nNüfus: %s\nVergi geliri: %s altın/gün\nErzak: %s\nGarnizon: %s\nArazi: %s" % [
		province.get("name", "?"), str(province.get("population", 0)),
		str(province.get("tax", 0)), str(province.get("food", 0)),
		str(province.get("garrison", 0)), str(province.get("terrain", "?"))
	]

func _collect_tax() -> void:
	if selected_province.is_empty():
		return
	var income := int(selected_province.get("tax", 0))
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + income
	_refresh_campaign_hud()
	map_detail.text += "\n\nTahsil edildi: %d altın." % income

func _advance_day() -> void:
	var current := Time.get_datetime_dict_from_datetime_string(str(SaveManager.campaign.get("date", "1444-11-10")), false)
	var stamp := Time.get_unix_time_from_datetime_dict(current) + 86400
	var next_date := Time.get_datetime_dict_from_unix_time(stamp)
	SaveManager.campaign["date"] = "%04d-%02d-%02d" % [next_date.year, next_date.month, next_date.day]
	var daily_income := 0
	for province in provinces:
		if province.get("realm") == "ottoman":
			daily_income += int(province.get("tax", 0))
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + daily_income
	_refresh_campaign_hud()

func _refresh_campaign_hud() -> void:
	if date_label:
		date_label.text = "Tarih: %s" % str(SaveManager.campaign.get("date", ""))
	if treasury_label:
		treasury_label.text = "   Hazine: %s altın" % str(SaveManager.campaign.get("treasury", 0))

func _save_game() -> void:
	if SaveManager.save_campaign():
		date_label.text = "Kayıt başarılı — %s" % str(SaveManager.campaign.get("date", ""))

func open_ambassador_dialogue(name: String, opening: String, options: Array[String]) -> void:
	dialogue_title.text = name
	dialogue_text.text = opening
	for child in dialogue_choices.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option
		button.pressed.connect(_on_diplomatic_choice.bind(option))
		dialogue_choices.add_child(button)
	(dialogue_layer.get_meta("panel") as Control).visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_diplomatic_choice(option: String) -> void:
	match option:
		"Ticaret anlaşması öner":
			dialogue_text.text = "Elçi: Ticaret şartlarını görüşmek üzere heyetimizi görevlendireceğiz."
		"Barış ve dostluk teklif et":
			dialogue_text.text = "Elçi: Barış teklifinizi hükümdarıma ileteceğim."
		"Askerî ittifak görüş":
			dialogue_text.text = "Elçi: Ortak düşmanlarımıza karşı ittifak şartları müzakere edilebilir."
		_:
			(dialogue_layer.get_meta("panel") as Control).visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
