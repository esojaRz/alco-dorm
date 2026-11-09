extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pages_root: Control = $DiaryPages
@onready var back_button: Button = get_node_or_null("PageBack")
@onready var forward_button: Button = get_node_or_null("PageForward")

var current_day := 1

var _pages: Array[Control] = []
var _page_index := 0
var _is_turning := false


func _ready() -> void:
	set_day(1)


## Показывает первый разворот указанного дня.
## Дни назад не листаются: страницы прошлых дней недоступны.
func set_day(day: int) -> void:
	if day < current_day:
		return

	current_day = day
	_pages.clear()

	for child in pages_root.get_children():
		if child is Control and child.get("day") == day and child.get("page") != null:
			_pages.append(child)

	_pages.sort_custom(func(a, b): return a.get("page") < b.get("page"))
	_page_index = 0
	_show_current_page()
	_update_buttons()


## direction: 1 — вперёд, -1 — назад.
## Назад можно только в пределах текущего дня.
func turn_page(direction: int) -> void:
	if _is_turning:
		return

	var target := _page_index + direction
	if target < 0 or target >= _pages.size():
		return

	_is_turning = true
	pages_root.visible = false

	if direction > 0:
		animation_player.play("book_list_anim")
	else:
		animation_player.play_backwards("book_list_anim")

	await animation_player.animation_finished

	_page_index = target
	_show_current_page()
	pages_root.visible = true
	_is_turning = false
	_update_buttons()


func _show_current_page() -> void:
	for i in _pages.size():
		_pages[i].visible = i == _page_index


func _update_buttons() -> void:
	if back_button != null:
		back_button.disabled = _page_index <= 0
	if forward_button != null:
		forward_button.disabled = _page_index >= _pages.size() - 1
