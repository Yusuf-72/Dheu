extends Node3D

var dialogue_layer: CanvasLayer
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var battle_commander: BattleCommander
var map_panel: PanelContainer
var succession_panel: PanelContainer
var map_detail: Label
var treasury_label: Label
var date_label: Label
var provinces: Array = []
var selected_province: Dictionary = {}
var is_mobile := false

func _ready() -> void:
	is_mobile = OS.has_feature("mobile")
	var has_saved_campaign := SaveManager.load_campaign()
	battle_commander = BattleCommander.new()
	battle_commander.name = "BattleCommander"
	add_child(battle_commander)
	_load_provinces()
	_build_dialogue_ui()
	_build_campaign_hud()
	_add_ambassador()
	_refresh_campaign_hud()
	if not has_saved_campaign:
		_show_campaign_setup()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_map()
		elif event.keycode == KEY_B:
			_open_battlefield()

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
	top.add_theme_constant_override("separation", 12)
	hud.add_child(top)
	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 18)
	top.add_child(date_label)
	treasury_label = Label.new()
	treasury_label.add_theme_font_size_override("font_size", 18)
	top.add_child(treasury_label)
	var map_button := Button.new()
	map_button.text = "Harita [M]"
	map_button.pressed.connect(_toggle_map)
	top.add_child(map_button)
	var advance_button := Button.new()
	advance_button.text = "1 Gün"
	advance_button.pressed.connect(_advance_day)
	top.add_child(advance_button)
	var battle_button := Button.new()
	battle_button.text = "Savaş Alanı [B]"
	battle_button.pressed.connect(_open_battlefield)
	top.add_child(battle_button)
	var setup_button := Button.new()
	setup_button.text = "Hükümdar / Tarih"
	setup_button.pressed.connect(_show_campaign_setup)
	top.add_child(setup_button)
	var succession_button := Button.new()
	succession_button.text = "Halefiyet"
	succession_button.pressed.connect(_show_succession)
	top.add_child(succession_button)
	var save_button := Button.new()
	save_button.text = "Kaydet"
	save_button.pressed.connect(_save_game)
	top.add_child(save_button)

	map_panel = PanelContainer.new()
	map_panel.position = Vector2(25, 115)
	map_panel.size = Vector2(720, 530)
	hud.add_child(map_panel)
	map_panel.visible = false
	succession_panel = PanelContainer.new()
	succession_panel.position = Vector2(380, 230)
	succession_panel.size = Vector2(460, 230)
	hud.add_child(succession_panel)
	succession_panel.visible = false
	var succession_layout := VBoxContainer.new()
	succession_panel.add_child(succession_layout)
	var succession_title := Label.new()
	succession_title.text = "HÜKÜMDARIN VEFATI — HANEDAN KARARI"
	succession_title.add_theme_font_size_override("font_size", 20)
	succession_layout.add_child(succession_title)
	var succession_info := Label.new()
	succession_info.text = "Yeni hükümdarla devam edebilir veya seferi bitirebilirsin."
	succession_layout.add_child(succession_info)
	var heir_button := Button.new()
	heir_button.text = "Varisle devam et"
	heir_button.pressed.connect(_continue_as_heir)
	succession_layout.add_child(heir_button)
	var end_button := Button.new()
	end_button.text = "Seferi bitir"
	end_button.pressed.connect(_end_campaign)
	succession_layout.add_child(end_button)
	var columns := HBoxContainer.new()
	map_panel.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 420
	columns.add_child(left)
	var heading := Label.new()
	heading.text = "1444 SEFER HARİTASI — EYALETLER"
	heading.add_theme_font_size_override("font_size", 20)
	left.add_child(heading)
	var map_view := Control.new()
	map_view.name = "ProvinceMap"
	map_view.custom_minimum_size = Vector2(410, 440)
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.set_script(load("res://scripts/province_map.gd"))
	map_view.call("set_provinces", provinces)
	map_view.connect("province_clicked", _select_province_by_id)
	left.add_child(map_view)
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
	if not provinces.is_empty():
		_select_province(provinces[0])
	_build_campaign_setup(hud)
	if is_mobile:
		_build_touch_controls(hud)

func _build_campaign_setup(hud: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "CampaignSetup"
	panel.position = Vector2(300, 150)
	panel.size = Vector2(570, 400)
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "SEFERİNİ BELİRLE"
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var realm_label := Label.new()
	realm_label.text = "Medeniyet / Devlet"
	layout.add_child(realm_label)
	var realm := OptionButton.new()
	realm.name = "RealmChoice"
	for item in ["Osmanlı İmparatorluğu", "Bizans İmparatorluğu", "Macar Krallığı", "Memlük Sultanlığı"]:
		realm.add_item(item)
	realm.select(0)
	layout.add_child(realm)
	var ruler_label := Label.new()
	ruler_label.text = "Hükümdar"
	layout.add_child(ruler_label)
	var ruler := OptionButton.new()
	ruler.name = "RulerChoice"
	for item in ["II. Murad", "II. Mehmed", "XI. Konstantinos", "Hunyadi Yanoş"]:
		ruler.add_item(item)
	ruler.select(0)
	layout.add_child(ruler)
	var year_label := Label.new()
	year_label.text = "Başlangıç yılı (şimdilik 1300–1500 veri dönemi)"
	layout.add_child(year_label)
	var year := SpinBox.new()
	year.name = "YearChoice"
	year.min_value = 1300
	year.max_value = 1500
	year.value = 1444
	year.step = 1
	layout.add_child(year)
	var dynasty := CheckBox.new()
	dynasty.name = "DynastyChoice"
	dynasty.text = "Hanedan değişiminde oyuna devam et"
	dynasty.button_pressed = true
	layout.add_child(dynasty)
	var start := Button.new()
	start.text = "Seferi başlat"
	start.pressed.connect(_apply_campaign_setup.bind(panel))
	layout.add_child(start)
	panel.visible = false

func _show_campaign_setup() -> void:
	var panel := $HUD/CampaignSetup
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_campaign_setup(panel: PanelContainer) -> void:
	var realm := panel.get_node("VBoxContainer/RealmChoice") as OptionButton
	var ruler := panel.get_node("VBoxContainer/RulerChoice") as OptionButton
	var year := panel.get_node("VBoxContainer/YearChoice") as SpinBox
	var dynasty := panel.get_node("VBoxContainer/DynastyChoice") as CheckBox
	SaveManager.campaign["realm"] = realm.get_item_text(realm.selected)
	SaveManager.campaign["ruler"] = ruler.get_item_text(ruler.selected)
	SaveManager.campaign["date"] = "%04d-01-01" % int(year.value)
	SaveManager.campaign["dynasty_continuation"] = dynasty.button_pressed
	SaveManager.campaign["treasury"] = 1200
	panel.visible = false
	_refresh_campaign_hud()
	if not is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_touch_controls(hud: CanvasLayer) -> void:
	var controls := HBoxContainer.new()
	controls.name = "TouchControls"
	controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.position = Vector2(-360, -180)
	controls.size = Vector2(340, 150)
	controls.add_theme_constant_override("separation", 8)
	hud.add_child(controls)
	var directions := GridContainer.new()
	directions.columns = 3
	controls.add_child(directions)
	var blank1 := Control.new()
	directions.add_child(blank1)
	_add_hold_button(directions, "▲", "move_forward")
	var blank2 := Control.new()
	directions.add_child(blank2)
	_add_hold_button(directions, "◀", "move_left")
	_add_hold_button(directions, "▼", "move_back")
	_add_hold_button(directions, "▶", "move_right")
	var actions := VBoxContainer.new()
	controls.add_child(actions)
	_add_hold_button(actions, "Koş", "sprint")
	var interact := Button.new()
	interact.text = "Etkileşim"
	interact.custom_minimum_size = Vector2(105, 55)
	interact.pressed.connect(_mobile_interact)
	actions.add_child(interact)

func _add_hold_button(parent: Control, caption: String, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 55)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)

func _mobile_interact() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("mobile_interact"):
		player.mobile_interact()

func _toggle_map() -> void:
	map_panel.visible = not map_panel.visible
	if not is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_panel.visible else Input.MOUSE_MODE_CAPTURED

func _select_province_by_id(province_id: String) -> void:
	for province in provinces:
		if str(province.get("id", "")) == province_id:
			_select_province(province)
			return

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
	if bool(SaveManager.campaign.get("ended", false)):
		return
	var current := Time.get_datetime_dict_from_datetime_string(str(SaveManager.campaign.get("date", "1444-11-10")), false)
	var stamp := Time.get_unix_time_from_datetime_dict(current) + 86400
	var next_date := Time.get_datetime_dict_from_unix_time(stamp)
	SaveManager.campaign["date"] = "%04d-%02d-%02d" % [next_date.year, next_date.month, next_date.day]
	var daily_income := 0
	for province in provinces:
		if province.get("realm") == "ottoman":
			daily_income += int(province.get("tax", 0))
	daily_income += int(SaveManager.campaign.get("trade_income", 0))
	SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + daily_income
	_refresh_campaign_hud()
	_check_succession()

func _show_succession() -> void:
	if succession_panel:
		succession_panel.visible = true
		if not is_mobile:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _check_succession() -> void:
	if bool(SaveManager.campaign.get("ended", false)):
		return
	var ruler_name := str(SaveManager.campaign.get("ruler", ""))
	var death_years := {"II. Murad": 1451, "II. Mehmed": 1481, "XI. Konstantinos": 1453, "Hunyadi Yanoş": 1456}
	var death_year := int(death_years.get(ruler_name, 9999))
	var current_year := int(str(SaveManager.campaign.get("date", "1444-01-01")).substr(0, 4))
	if current_year >= death_year and not bool(SaveManager.campaign.get("succession_resolved", false)):
		_show_succession()

func _continue_as_heir() -> void:
	if not bool(SaveManager.campaign.get("dynasty_continuation", true)):
		_end_campaign()
		return
	var ruler_name := str(SaveManager.campaign.get("ruler", ""))
	var heirs := {"II. Murad": "II. Mehmed", "II. Mehmed": "II. Bayezid", "Hunyadi Yanoş": "Matthias Corvinus"}
	if not heirs.has(ruler_name):
		_end_campaign()
		return
	SaveManager.campaign["ruler"] = heirs[ruler_name]
	SaveManager.campaign["succession_resolved"] = false
	succession_panel.visible = false
	_refresh_campaign_hud()
	_save_game()

func _end_campaign() -> void:
	SaveManager.campaign["ended"] = true
	succession_panel.visible = false
	if date_label:
		date_label.text = "Sefer sona erdi — hanedan devam etmiyor."
	_save_game()

func _refresh_campaign_hud() -> void:
	if date_label:
		date_label.text = "Tarih: %s  |  %s / %s" % [str(SaveManager.campaign.get("date", "")), str(SaveManager.campaign.get("realm", "")), str(SaveManager.campaign.get("ruler", ""))]
	if treasury_label:
		treasury_label.text = "   Hazine: %s altın" % str(SaveManager.campaign.get("treasury", 0))

func _save_game() -> void:
	if SaveManager.save_campaign():
		date_label.text = "Kayıt başarılı — %s" % str(SaveManager.campaign.get("date", ""))

func _open_battlefield() -> void:
	SaveManager.save_campaign()
	get_tree().change_scene_to_file("res://scenes/battlefield.tscn")

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
	var partner := "Bizans İmparatorluğu"
	var relations: Dictionary = SaveManager.campaign.get("relations", {})
	var current_relation := int(relations.get(partner, 0))
	match option:
		"Ticaret anlaşması öner":
			SaveManager.campaign["trade_agreements"] = int(SaveManager.campaign.get("trade_agreements", 0)) + 1
			SaveManager.campaign["trade_income"] = int(SaveManager.campaign.get("trade_income", 0)) + 8
			SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + 50
			relations[partner] = mini(100, current_relation + 5)
			dialogue_text.text = "Elçi: Ticaret anlaşmasını kabul ediyoruz. Hazineye 50 altın, günlük gelire 8 altın eklendi."
		"Barış ve dostluk teklif et":
			relations[partner] = mini(100, current_relation + 15)
			SaveManager.campaign["stability"] = mini(100, int(SaveManager.campaign.get("stability", 75)) + 2)
			dialogue_text.text = "Elçi: Barış teklifinizi kabul ediyoruz. İlişkiler ve devlet istikrarı iyileşti."
		"Askerî ittifak görüş":
			relations[partner] = mini(100, current_relation + 25)
			SaveManager.campaign["alliances"] = int(SaveManager.campaign.get("alliances", 0)) + 1
			dialogue_text.text = "Elçi: Askerî ittifak kuruldu. İlişkiler belirgin biçimde güçlendi."
		_:
			(dialogue_layer.get_meta("panel") as Control).visible = false
			if not is_mobile:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	SaveManager.campaign["relations"] = relations
	_refresh_campaign_hud()
	_save_game()
