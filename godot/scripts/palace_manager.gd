extends Node3D

var dialogue_layer: CanvasLayer
var dialogue_title: Label
var dialogue_text: Label
var dialogue_choices: VBoxContainer
var battle_commander: BattleCommander

func _ready() -> void:
	battle_commander = BattleCommander.new()
	battle_commander.name = "BattleCommander"
	add_child(battle_commander)
	_build_dialogue_ui()
	_add_ambassador()

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
