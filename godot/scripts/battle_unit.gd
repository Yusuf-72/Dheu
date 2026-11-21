extends CharacterBody3D
class_name ImperiumBattleUnit

@export var unit_name := "Yeniçeri Birliği"
@export var move_speed := 2.8
@export var charge_speed := 4.8
@export var morale := 100.0
@export var strength := 100
@export var formation_defence := 1.0

var active_order: int = 1
var destination := Vector3.ZERO
var has_destination := false
var formation: int = 0
var gravity := 18.0

func receive_order(order: int, target: Vector3, new_formation: int) -> void:
	active_order = order
	formation = new_formation
	match order:
		0:
			destination = global_position - global_transform.basis.z * 18.0
			has_destination = true
		1:
			has_destination = false
		2:
			destination = target if target != Vector3.ZERO else global_position - global_transform.basis.z * 24.0
			has_destination = true
		3:
			destination = global_position + global_transform.basis.z * 16.0
			has_destination = true
		4:
			destination = target
			has_destination = true
		5:
			destination = target if target != Vector3.ZERO else Vector3(0, 0, -12)
			has_destination = true

func set_formation(new_formation: int) -> void:
	formation = new_formation
	match formation:
		0:
			formation_defence = 1.0
		1:
			formation_defence = 0.9
		2:
			formation_defence = 0.85
		3:
			formation_defence = 1.35

func apply_losses(amount: int) -> void:
	strength = maxi(0, strength - amount)
	morale = maxf(0.0, morale - float(amount) * 0.65)
	if strength == 0:
		queue_free()
	elif morale < 20.0:
		receive_order(3, Vector3.ZERO, formation)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	if active_order == 1 or not has_destination:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 2.0)
		move_and_slide()
		return
	var offset := destination - global_position
	offset.y = 0.0
	if offset.length() < 0.8:
		has_destination = false
		if active_order != 5:
			active_order = 1
		return
	var direction := offset.normalized()
	var speed := charge_speed if active_order == 2 else move_speed
	if morale < 35.0:
		speed *= 0.7
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at(global_position + direction, Vector3.UP)
	move_and_slide()
