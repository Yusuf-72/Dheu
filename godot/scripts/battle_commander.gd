extends Node
class_name BattleCommander

signal order_issued(order_name: String, target: Vector3)
signal battle_log(message: String)

enum Order { ADVANCE, HOLD, CHARGE, RETREAT, MOVE_TO, SIEGE }
enum Formation { LINE, COLUMN, WEDGE, SQUARE }

var selected_unit: Node3D
var current_formation: Formation = Formation.LINE
var orders_issued: int = 0

func select_unit(unit: Node3D) -> void:
	selected_unit = unit
	battle_log.emit("Birlik seçildi: %s" % unit.name)

func set_formation(formation: Formation) -> void:
	current_formation = formation
	battle_log.emit("Düzen değiştirildi: %s" % Formation.keys()[formation])
	if selected_unit and selected_unit.has_method("set_formation"):
		selected_unit.set_formation(formation)

func issue_order(order: Order, target: Vector3 = Vector3.ZERO) -> bool:
	if not is_instance_valid(selected_unit):
		battle_log.emit("Önce komuta edilecek birliği seçin.")
		return false
	var names := ["İLERLE", "MEVZİYİ KORU", "HÜCUM", "GERİ ÇEKİL", "HEDEFE İLERLE", "KUŞATMAYA GEÇ"]
	var order_name: String = names[order]
	if selected_unit.has_method("receive_order"):
		selected_unit.receive_order(order, target, current_formation)
	orders_issued += 1
	order_issued.emit(order_name, target)
	battle_log.emit("%s emri verildi: %s" % [selected_unit.name, order_name])
	return true
