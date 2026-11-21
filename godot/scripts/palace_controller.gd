extends CharacterBody3D

@export var walk_speed := 4.2
@export var sprint_speed := 6.4
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var prompt: Label = get_tree().current_scene.get_node("HUD/Prompt")
var pitch := 0.0
var nearby_interactable: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.35, 1.35)
		head.rotation.x = pitch
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("interact") and nearby_interactable:
		nearby_interactable.interact()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()

func set_interactable(target: Node3D) -> void:
	nearby_interactable = target
	prompt.text = "[E] Görüş / Etkileşim" if target else "WASD: hareket  •  Fare: bakış  •  Shift: koş"
