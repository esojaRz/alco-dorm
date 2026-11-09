extends Button

## Если true — листаем назад, иначе вперёд.
@export var backwards := false


func _on_pressed() -> void:
	get_parent().turn_page(-1 if backwards else 1)
