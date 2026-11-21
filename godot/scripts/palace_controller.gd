extends CharacterBody3D

@export var walk_speed := 4.2
@export var sprint_speed := 6.4
@export var mouse_sensitivity := 0.0022
@export var gravity := 18.0
@onready var head: Node3D = $Head
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var prompt: Label = get_tree().current_scene.get_node_or_null("HUD/Prompt")
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
	if event is InputEventScreenDrag:
		var viewport_size := get_viewport().get_visible_rect().size
		if event.position.x > viewport_size.x * 0.42 and event.position.y < viewport_size.y * 0.72:
			rotate_y(-event.relative.x * mouse_sensitivity * 1.8)
			pitch = clampf(pitch - event.relative.y * mouse_sensitivity * 1.8, -1.35, 1.35)
			head.rotation.x = pitch
	if event.is_action_pressed("ui_cancel") and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("interact"):
		mobile_interact()

func mobile_interact() -> void:
	if is_instance_valid(nearby_interactable) and nearby_interactable.has_method("interact"):
		nearby_interactable.interact()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	_update_interaction_target()

func _update_interaction_target() -> void:
	interact_ray.force_raycast_update()
	var target: Node3D
	if interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider is Node3D and collider.has_method("interact"):
			target = collider
	if target != nearby_interactable:
		nearby_interactable = target
		if prompt:
			prompt.text = "[E] Elçiyle görüş" if target else "Hareket • Bakış • Etkileşim"
