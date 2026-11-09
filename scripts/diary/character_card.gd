@tool
extends PanelContainer

@export var character_name := "Имя":
	set(value):
		character_name = value
		if is_node_ready():
			name_label.text = value

@export_multiline var bio := "Описание персонажа.":
	set(value):
		bio = value
		if is_node_ready():
			bio_label.text = value

@export var portrait: Texture2D:
	set(value):
		portrait = value
		if is_node_ready() and _alive:
			portrait_rect.texture = value

@export var character_id := ""
@export var dead_portrait: Texture2D

var _alive := true

@onready var portrait_rect: TextureRect = $HBox/Portrait
@onready var name_label: Label = $HBox/Info/Name
@onready var bio_label: Label = $HBox/Info/Bio


func _ready() -> void:
	name_label.text = character_name
	bio_label.text = bio

	if portrait != null:
		portrait_rect.texture = portrait

	set_alive(_alive)


func set_alive(alive: bool) -> void:
	_alive = alive
	if not is_node_ready() or portrait_rect == null:
		return

	if alive or dead_portrait == null:
		portrait_rect.texture = portrait
	else:
		portrait_rect.texture = dead_portrait

	modulate = Color(1, 1, 1, 1) if alive else Color(1, 1, 1, 0.65)


func set_hunger_stage(stage: String) -> void:
	tooltip_text = "%s — %s" % [character_name, stage]
