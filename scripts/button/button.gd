extends Button

## Сколько секунд длится затемнение перед сменой сцены или выходом.
const FADE_OUT_DURATION := 1.0

@onready var fade_layer: CanvasLayer = owner.get_node("FadeLayer")
@onready var fade: ColorRect = owner.get_node("FadeLayer/Fade")
@onready var animation_player: AnimationPlayer = owner.get_node("FadeLayer/Fade/AnimationPlayer")

var _is_transitioning := false


func _ready() -> void:
	# Если в редакторе слой скрыт, чтобы не закрывать сцену,
	# в игре всё равно показываем его — с него начинается fade_in.
	fade_layer.visible = true


func _fade_to_black() -> void:
	# Останавливаем fade_in, не сбрасывая текущую прозрачность:
	# затемнение должно начаться с того места, где сейчас экран.
	animation_player.stop(true)
	fade_layer.visible = true

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_OUT_DURATION)
	await tween.finished

	# Гарантируем полностью чёрный кадр перед сменой сцены/выходом.
	fade.color = Color(0, 0, 0, 1)


func _on_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	disabled = true

	await _fade_to_black()
	get_tree().quit()


func _on_play_button_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	await _fade_to_black()
	get_tree().change_scene_to_file("res://node_2d.tscn")
