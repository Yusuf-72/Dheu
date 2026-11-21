extends Node3D

var commander: BattleCommander
var friendly_units: Array[ImperiumBattleUnit] = []
var enemy_units: Array[ImperiumBattleUnit] = []
var selected_index := 0
var status_label: Label
var unit_scene: PackedScene
var combat_clock := 0.0
var siege_progress := 0.0
var siege_bar: ProgressBar
var siege_won := false
var battle_result_recorded := false

func _ready() -> void:
	unit_scene = load("res://scenes/battle_unit.tscn")
	commander = BattleCommander.new()
	add_child(commander)
	commander.battle_log.connect(_set_status)
	_build_fort()
	_spawn_armies()
	_build_battle_hud()
	_select_unit(0)

func _spawn_armies() -> void:
	for i in range(3):
		var unit := unit_scene.instantiate() as ImperiumBattleUnit
		unit.name = "Yeniçeri %d" % (i + 1)
		unit.position = Vector3(-5.0 + i * 5.0, 0.1, 5.0)
		add_child(unit)
		friendly_units.append(unit)
		var mesh := unit.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#b68a45")
		mesh.material_override = material
	for i in range(3):
		var enemy := unit_scene.instantiate() as ImperiumBattleUnit
		enemy.name = "Düşman %d" % (i + 1)
		enemy.position = Vector3(-5.0 + i * 5.0, 0.1, -7.0)
		add_child(enemy)
		enemy_units.append(enemy)
		var mesh := enemy.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#8b4242")
		mesh.material_override = material
		enemy.receive_order(BattleCommander.Order.ADVANCE, Vector3(0, 0, 3), BattleCommander.Formation.LINE)

func _build_fort() -> void:
	var fort := MeshInstance3D.new()
	fort.name = "Fortress"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(10, 5, 3)
	fort.mesh = mesh
	fort.position = Vector3(0, 2.5, -15)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#77746b")
	fort.material_override = material
	add_child(fort)

func _physics_process(delta: float) -> void:
	if not siege_won:
		var siege_force := 0
		for unit in friendly_units:
			if is_instance_valid(unit) and unit.active_order == BattleCommander.Order.SIEGE and unit.global_position.distance_to(Vector3(0, 0, -12)) < 4.0:
				siege_force += 1
		if siege_force > 0:
			siege_progress = minf(100.0, siege_progress + delta * 1.7 * siege_force)
			if is_instance_valid(siege_bar):
				siege_bar.value = siege_progress
			if siege_progress >= 100.0:
				siege_won = true
				SaveManager.campaign["sieges_won"] = int(SaveManager.campaign.get("sieges_won", 0)) + 1
				SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + 150
				SaveManager.save_campaign()
				_set_status("Kuşatma başarılı! Kale ele geçirildi. Hazineye 150 altın eklendi.")
	combat_clock += delta
	if combat_clock < 1.5:
		return
	combat_clock = 0.0
	for enemy in enemy_units:
		if not is_instance_valid(enemy):
			continue
		var target: ImperiumBattleUnit
		var nearest := 99999.0
		for ally in friendly_units:
			if is_instance_valid(ally):
				var distance := enemy.global_position.distance_to(ally.global_position)
				if distance < nearest:
					nearest = distance
					target = ally
		if target and nearest < 2.2:
			target.apply_losses(3)
			enemy.apply_losses(2)
	var alive_friends := 0
	var alive_enemies := 0
	for unit in friendly_units:
		if is_instance_valid(unit):
			alive_friends += 1
	for unit in enemy_units:
		if is_instance_valid(unit):
			alive_enemies += 1
	if not battle_result_recorded and alive_enemies == 0:
		battle_result_recorded = true
		SaveManager.campaign["battles_won"] = int(SaveManager.campaign.get("battles_won", 0)) + 1
		SaveManager.campaign["treasury"] = int(SaveManager.campaign.get("treasury", 0)) + 100
		SaveManager.save_campaign()
		_set_status("Zafer! Düşman kuvvetleri dağıtıldı. Hazineye 100 altın eklendi.")
	elif not battle_result_recorded and alive_friends == 0:
		battle_result_recorded = true
		SaveManager.campaign["battles_lost"] = int(SaveManager.campaign.get("battles_lost", 0)) + 1
		SaveManager.campaign["stability"] = maxi(0, int(SaveManager.campaign.get("stability", 75)) - 5)
		SaveManager.save_campaign()
		_set_status("Yenilgi. Ordun dağıldı; devlet istikrarı düştü.")

func _build_battle_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(510, 270)
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "MEYDAN MUHAREBESİ — BİRLİK KOMUTASI"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	status_label = Label.new()
	status_label.text = "Birlik seç ve emir ver. Altın birlikler senin, kızıllar düşman."
	layout.add_child(status_label)
	var selection := HBoxContainer.new()
	layout.add_child(selection)
	for i in range(3):
		var button := Button.new()
		button.text = "Yeniçeri %d" % (i + 1)
		button.pressed.connect(_select_unit.bind(i))
		selection.add_child(button)
	var formations := HBoxContainer.new()
	layout.add_child(formations)
	_add_command_button(formations, "Hat", func(): commander.set_formation(BattleCommander.Formation.LINE))
	_add_command_button(formations, "Kol", func(): commander.set_formation(BattleCommander.Formation.COLUMN))
	_add_command_button(formations, "Kama", func(): commander.set_formation(BattleCommander.Formation.WEDGE))
	_add_command_button(formations, "Kare", func(): commander.set_formation(BattleCommander.Formation.SQUARE))
	var orders := HBoxContainer.new()
	layout.add_child(orders)
	_add_command_button(orders, "İlerle", func(): commander.issue_order(BattleCommander.Order.ADVANCE))
	_add_command_button(orders, "Hücum", func(): commander.issue_order(BattleCommander.Order.CHARGE))
	_add_command_button(orders, "Tut", func(): commander.issue_order(BattleCommander.Order.HOLD))
	_add_command_button(orders, "Çekil", func(): commander.issue_order(BattleCommander.Order.RETREAT))
	var siege := Button.new()
	siege.text = "Kuşatmayı başlat"
	siege.pressed.connect(func(): commander.issue_order(BattleCommander.Order.SIEGE, Vector3(0, 0, -12)))
	layout.add_child(siege)
	siege_bar = ProgressBar.new()
	siege_bar.min_value = 0
	siege_bar.max_value = 100
	siege_bar.value = 0
	layout.add_child(siege_bar)
	var back := Button.new()
	back.text = "Saray'a dön"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/palace.tscn"))
	layout.add_child(back)

func _add_command_button(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)

func _select_unit(index: int) -> void:
	if index < 0 or index >= friendly_units.size():
		return
	selected_index = index
	commander.select_unit(friendly_units[index])
	_set_status("Seçili birlik: Yeniçeri %d — mevcut kuvvet: %d" % [index + 1, friendly_units[index].strength])

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
