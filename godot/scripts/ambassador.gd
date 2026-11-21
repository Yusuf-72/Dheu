extends StaticBody3D
class_name AmbassadorNPC

@export var ambassador_name := "Bizans Elçisi"
@export_multiline var opening_line := "Hükümdarım, devletlerimiz arasındaki meseleleri görüşmek üzere huzurunuza çıktım."
@export var diplomatic_options: Array[String] = [
	"Ticaret anlaşması öner",
	"Barış ve dostluk teklif et",
	"Askerî ittifak görüş",
	"Görüşmeyi bitir"
]

func interact() -> void:
	var palace := get_tree().current_scene
	if palace.has_method("open_ambassador_dialogue"):
		palace.open_ambassador_dialogue(ambassador_name, opening_line, diplomatic_options)
