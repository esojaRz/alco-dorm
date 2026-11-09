extends Button

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var diary_pages: Control = owner.get_node("Layer_Book/Book/DiaryPages")


var book_is_open := false


func _ready() -> void:
	diary_pages.visible = false


func _on_pressed() -> void:
	await await get_tree().create_timer(0.065).timeout
	if book_is_open:
		anim_player.play_backwards("book_anim")
		await anim_player.animation_finished
		book_is_open = false
		diary_pages.visible = false
	else:
		diary_pages.visible = true
		anim_player.play("book_anim")
		await anim_player.animation_finished
		book_is_open = true
