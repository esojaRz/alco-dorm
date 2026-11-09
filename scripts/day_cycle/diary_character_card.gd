extends PanelContainer

signal item_requested(character_id: String, item_type: String)

@export var character_id := "artur"

@onready var portrait_rect: TextureRect = $HBox/Portrait
@onready var name_label: Label = $HBox/Info/Top/Name
@onready var status_label: Label = $HBox/Info/Top/Status
@onready var bio_label: Label = $HBox/Info/Bio
@onready var actions: HBoxContainer = $HBox/Info/Actions

@onready var hunger_value: Label = $HBox/Info/Stats/Hunger/Value
@onready var hunger_bar: ProgressBar = $HBox/Info/Stats/Hunger/Bar
@onready var thirst_value: Label = $HBox/Info/Stats/Thirst/Value
@onready var thirst_bar: ProgressBar = $HBox/Info/Stats/Thirst/Bar
@onready var health_value: Label = $HBox/Info/Stats/Health/Value
@onready var health_bar: ProgressBar = $HBox/Info/Stats/Health/Bar
@onready var hunger_box: VBoxContainer = $HBox/Info/Stats/Hunger
@onready var thirst_box: VBoxContainer = $HBox/Info/Stats/Thirst

@onready var food_button: Button = $HBox/Info/Actions/Food
@onready var water_button: Button = $HBox/Info/Actions/Water
@onready var medicine_button: Button = $HBox/Info/Actions/Medicine

var normal_portrait: Texture2D
var dead_portrait: Texture2D


func _ready() -> void:
	food_button.pressed.connect(func() -> void: item_requested.emit(character_id, "food"))
	water_button.pressed.connect(func() -> void: item_requested.emit(character_id, "water"))
	medicine_button.pressed.connect(func() -> void: item_requested.emit(character_id, "cigarettes"))


func setup(display_name: String, portrait: Texture2D, bio: String, dead: Texture2D = null) -> void:
	normal_portrait = portrait
	dead_portrait = dead
	name_label.text = display_name
	portrait_rect.texture = normal_portrait
	bio_label.text = bio


func set_phase(is_evening: bool) -> void:
	bio_label.visible = not is_evening
	actions.visible = is_evening


func update_state(
	hunger: int,
	thirst: int,
	health: int,
	alive: bool,
	away: bool,
	food_count: int,
	water_count: int,
	cigarettes_count: int,
	hunger_stage: String,
	thirst_stage: String
) -> void:
	hunger_bar.value = hunger
	var has_hunger_need := hunger_stage == "Голодает" or hunger_stage == "Истощение"
	hunger_box.visible = has_hunger_need
	hunger_value.text = hunger_stage
	thirst_bar.value = thirst
	var has_thirst_need := thirst_stage == "Жажда" or thirst_stage == "Обезвоживание"
	thirst_box.visible = has_thirst_need
	thirst_value.text = thirst_stage
	health_bar.value = health
	health_value.text = "Здоровье %d" % health

	var present := alive and not away
	food_button.disabled = not present or food_count <= 0
	water_button.disabled = not present or water_count <= 0
	medicine_button.disabled = not present or cigarettes_count <= 0
	food_button.text = "Еда (%d)" % food_count
	water_button.text = "Вода (%d)" % water_count
	medicine_button.text = "Сигареты (%d)" % cigarettes_count

	if not alive:
		if dead_portrait != null:
			portrait_rect.texture = dead_portrait
		status_label.text = "Скончался"
		modulate = Color(1, 1, 1, 0.55)
	elif away:
		portrait_rect.texture = normal_portrait
		status_label.text = "На парах"
		modulate = Color(0.85, 0.85, 0.85, 0.9)
	else:
		portrait_rect.texture = normal_portrait
		status_label.text = ""
		modulate = Color(1, 1, 1, 1)
