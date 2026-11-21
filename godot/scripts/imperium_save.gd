extends Node
class_name ImperiumSave

const SAVE_PATH := "user://imperium_save.json"
var campaign := {
	"date": "1444-11-10",
	"realm": "Osmanlı İmparatorluğu",
	"ruler": "II. Murad",
	"treasury": 1200,
	"stability": 75,
	"dynasty_continuation": true
}

func save_campaign() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Kayıt dosyası açılamadı.")
		return false
	file.store_string(JSON.stringify(campaign, "\t"))
	return true

func load_campaign() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Kayıt dosyası bozuk.")
		return false
	campaign = parsed
	return true
