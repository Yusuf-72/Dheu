extends Node3D

var commander: BattleCommander
var units: Array[Node3D] = []
var selected_index := 0
var status_label: Label
var unit_scene: PackedScene

func _ready() -> void:
	unit_scene = load("res://scenes/battle_unit.tscn")
	commander = BattleCommander.new()
	add_child(commander)
	commander.battle_log.connect(_set_status)
	_spawn_armies()
	_build_battle_hud()
	_select_unit(0)

func _spawn_armies() -> void:
	for i in range(3):
		var unit := unit_scene.instantiate()
		unit.name = "Yeniçeri %d" % (i + 1)
		unit.position = Vector3(-5.0 + i * 5.0, 0.1, 5.0)
		add_child(unit)
		units.append(unit)
		var mesh := unit.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#b68a45")
		mesh.material_override = material
	for i in range(3):
		var enemy := unit_scene.instantiate()
		enemy.name = "Düşman %d" % (i + 1)
		enemy.position = Vector3(-5.0 + i * 5.0, 0.1, -7.0)
		add_child(enemy)
		units.append(enemy)
		var mesh := enemy.get_node("Visual") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#8b4242")
		mesh.material_override = material

func _build_battle_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(500, 250)
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "MEYDAN MUHAREBESİ — BİRLİK KOMUTASI"
	title.add_theme_font_size_override("font_size", 20)
	layout.add_child(title)
	status_label = Label.new()
	status_label.text = "Birlik seç ve emir ver."
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
	if index < 0 or index >= 3:
		return
	selected_index = index
	commander.select_unit(units[index])
	_set_status("Seçili birlik: Yeniçeri %d — mevcut kuvvet: %d" % [index + 1, units[index].strength])

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
