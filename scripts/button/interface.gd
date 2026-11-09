extends CanvasLayer

@onready var fade_day_text: Label = $Day_Count/Label
@onready var book_button: Button = get_parent().get_node("Layer_Book/Button")
@onready var black_fade: ColorRect = $BlackFade

var day := 1


func _ready() -> void:
	# Первый день начинается сразу с чёрного экрана: меню уже затемнило сцену.
	await play_day_intro(1, false, true)


## Показывает «ДЕНЬ N».
## start_black — экран уже чёрный (переход из меню), не затемняем повторно.
## with_black_fade — плавно затемняем, держим 2 секунды и показываем день.
## on_black — вызывается, когда экран уже полностью чёрный: можно незаметно
## обновить состояние комнаты (например, показать умершего персонажа).
func play_day_intro(
	day_number: int,
	with_black_fade := false,
	start_black := false,
	on_black := Callable()
) -> void:
	visible = true
	book_button.disabled = true

	if start_black:
		black_fade.visible = true
		black_fade.color = Color(0, 0, 0, 1)
	elif with_black_fade:
		black_fade.visible = true
		black_fade.color = Color(0, 0, 0, 0)
		var fade_in := create_tween()
		fade_in.tween_property(black_fade, "color:a", 1.0, 0.8)
		await fade_in.finished
		await get_tree().create_timer(2.0).timeout

	if on_black.is_valid():
		on_black.call()

	day = day_number
	fade_day_text.text = "ДЕНЬ %d" % day
	fade_day_text.visible_ratio = 0.0

	var label_tween := create_tween()
	label_tween.tween_property(fade_day_text, "visible_ratio", 1.0, 0.5)
	label_tween.tween_interval(1.0)
	label_tween.tween_property(fade_day_text, "visible_ratio", 0.0, 0.3)
	await label_tween.finished

	if with_black_fade or start_black:
		var fade_out := create_tween()
		fade_out.tween_property(black_fade, "color:a", 0.0, 0.8)
		await fade_out.finished
		black_fade.visible = false

	book_button.disabled = false
