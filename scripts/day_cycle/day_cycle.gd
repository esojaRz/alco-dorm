extends Control

enum Phase { MORNING, EVENING }

const CHARACTER_ORDER: Array[String] = ["artur", "vasek", "kirya"]

const CHARACTER_DATA := {
	"artur": {
		"name": "Артур",
		"portrait": preload("res://characters/portrait/artur_p.png"),
		"dead_portrait": preload("res://characters/dead/portrait_d/artur_d_partret.png"),
		"bio": "Сосед с верхней койки. Любит шумные компании и всегда знает, где достать еду. Его идеи редко бывают безопасными.",
	},
	"vasek": {
		"name": "Васек",
		"portrait": preload("res://characters/portrait/vasek_p.png"),
		"dead_portrait": preload("res://characters/dead/portrait_d/vasek_d_partret.png"),
		"bio": "Хозяйственный сосед. Может поделиться припасами, если ты поможешь ему с делами.",
	},
	"kirya": {
		"name": "Киря",
		"portrait": preload("res://characters/portrait/kirya_p.png"),
		"dead_portrait": preload("res://characters/dead/portrait_d/kirya_d_partret.png"),
		"bio": "Тихий и загадочный. Часто пропадает, но возвращается с чем-то полезным.",
	},
}

const ITEM_ORDER: Array[String] = ["food", "water", "medicine"]
const ITEM_LABELS := {
	"food": "Дошик",
	"water": "Вода",
	"medicine": "Аптечка",
}
const START_INVENTORY := {
	"food": 4,
	"water": 4,
	"medicine": 2,
}

const FOOD_VALUE := 40
const WATER_VALUE := 40
const MEDICINE_VALUE := 30

const DAILY_HUNGER_LOSS := 25
const DAILY_THIRST_LOSS := 30
const STARVING_HEALTH_LOSS := 20
const DEATH_AFTER_DAYS := 2

const HUNGER_SATIATED := "Сытый"
const HUNGER_NEUTRAL := "Нейтральный"
const HUNGER_STARVING := "Голодает"
const HUNGER_EXHAUSTED := "Истощение"
const HUNGER_DEATH_BASE_DAYS := 4

const THIRST_NEUTRAL := "Нейтральный"
const THIRST_THIRSTY := "Жажда"
const THIRST_DEHYDRATED := "Обезвоживание"
const THIRST_DEATH_BASE_DAYS := 3

var day := 1
var phase := Phase.MORNING
var inventory: Dictionary = {}
var characters: Dictionary = {}

var selected_id := ""
var away_id := ""
var last_event_result := ""
var event_text := ""
var event_resolved := false

var message := "Выбери, кто пойдёт на пары. Можно не отправлять никого."
var _ui_updating := false
var _is_turning := false

@onready var header: Label = %Header
@onready var last_event_title: Label = %LastEventTitle
@onready var last_event_text: Label = %LastEventText
@onready var morning: Control = %Morning
@onready var evening: Control = %Evening

@onready var artur_select: Button = %ArturSelect
@onready var vasek_select: Button = %VasekSelect
@onready var kirya_select: Button = %KiryaSelect
@onready var food_select: Button = %FoodSelect
@onready var water_select: Button = %WaterSelect
@onready var medicine_select: Button = %MedicineSelect
@onready var confirm_morning: Button = %ConfirmMorning

@onready var cards: VBoxContainer = %Cards
@onready var event_text_label: Label = %EventText
@onready var end_day: Button = %EndDay
@onready var message_label: Label = %Message


func _ready() -> void:
	inventory = START_INVENTORY.duplicate(true)

	for id in CHARACTER_ORDER:
		var data: Dictionary = CHARACTER_DATA[id]
		characters[id] = {
			"id": id,
			"name": data["name"],
			"portrait": data["portrait"],
			"dead_portrait": data["dead_portrait"],
			"bio": data["bio"],
			"hunger": 70,
			"thirst": 70,
			"health": 100,
			"alive": true,
			"away": false,
			"starve_days": 0,
			"thirst_days": 0,
			"days_without_food": 0,
			"fed_today": false,
			"days_without_water": 0,
			"drank_today": false,
		}

	last_event_result = "Первый день. Выбери, кто пойдёт на пары, и что он возьмёт с собой."

	artur_select.toggled.connect(_on_character_toggled.bind("artur"))
	vasek_select.toggled.connect(_on_character_toggled.bind("vasek"))
	kirya_select.toggled.connect(_on_character_toggled.bind("kirya"))

	food_select.toggled.connect(_on_item_toggled)
	water_select.toggled.connect(_on_item_toggled)
	medicine_select.toggled.connect(_on_item_toggled)

	confirm_morning.pressed.connect(_on_confirm_morning)
	end_day.pressed.connect(_on_end_day)

	_setup_character_cards()
	_update_ui()
	visible = false
	_apply_phase_visuals()

	var intro := get_parent().get_node_or_null("Day1Page1")
	if intro != null:
		var start_button := intro.find_child("StartDayButton", true, false) as Button
		if start_button != null:
			start_button.pressed.connect(_on_start_day)


func _on_start_day() -> void:
	var intro := get_parent().get_node_or_null("Day1Page1")
	var pages_root := get_parent()
	var book := pages_root.get_parent()
	var animation_player: AnimationPlayer = null
	if book != null:
		animation_player = book.get_node_or_null("AnimationPlayer") as AnimationPlayer

	pages_root.visible = false
	if animation_player != null and animation_player.has_animation("book_list_anim"):
		animation_player.play("book_list_anim")
		await animation_player.animation_finished

	if intro != null:
		intro.visible = false
	visible = true
	pages_root.visible = true

	message = "Утро дня 1. Выбери, кто пойдёт на пары."

	if book != null:
		var forward := book.get_node_or_null("PageForward")
		var back := book.get_node_or_null("PageBack")
		if forward != null:
			forward.visible = false
		if back != null:
			back.visible = false

	_update_ui()
	_apply_phase_visuals()


func _setup_character_cards() -> void:
	for card in cards.get_children():
		if not card.has_method("setup"):
			continue

		var character_id: String = card.get("character_id")
		var character: Dictionary = characters[character_id]
		card.call("setup", character["name"], character["portrait"], character["bio"], character["dead_portrait"])
		card.connect("item_requested", Callable(self, "_on_card_item_requested"))


func _on_character_toggled(pressed: bool, character_id: String) -> void:
	if _ui_updating:
		return

	if pressed:
		selected_id = character_id
		for other_id in CHARACTER_ORDER:
			if other_id != character_id:
				_character_button(other_id).set_pressed_no_signal(false)
	else:
		if selected_id == character_id:
			selected_id = ""

	_clear_item_selection()
	_update_ui()


func _on_item_toggled(_pressed: bool) -> void:
	if _ui_updating:
		return
	_update_ui()


func _on_confirm_morning() -> void:
	if phase != Phase.MORNING or _is_turning:
		return

	_is_turning = true

	var taken: Array[String] = []
	for item_type in ITEM_ORDER:
		if _item_button(item_type).button_pressed and inventory[item_type] > 0:
			taken.append(item_type)

	if selected_id == "":
		away_id = ""
		message = "Никто не пошёл на пары. Вечером все дома."
	else:
		var character: Dictionary = characters[selected_id]
		for item_type in taken:
			inventory[item_type] -= 1
			_apply_item(character, item_type)

		character["away"] = true
		away_id = selected_id

		var sent_names: Array[String] = []
		for item_type in taken:
			sent_names.append(ITEM_LABELS[item_type])

		message = "%s ушёл на пары." % character["name"]
		if sent_names.size() > 0:
			message += " С собой: " + ", ".join(sent_names) + "."

	selected_id = ""
	_clear_item_selection()
	_update_ui()
	_apply_phase_visuals()

	confirm_morning.text = "ЖДЁМ ВЕЧЕРА..."
	confirm_morning.disabled = true

	await get_tree().create_timer(0.35).timeout

	var book := get_parent().get_parent()
	var animation_player: AnimationPlayer = null
	if book != null:
		animation_player = book.get_node_or_null("AnimationPlayer") as AnimationPlayer

	visible = false
	if animation_player != null and animation_player.has_animation("book_list_anim"):
		animation_player.play("book_list_anim")
		await animation_player.animation_finished

	phase = Phase.EVENING
	_prepare_event()
	_update_ui()
	_apply_phase_visuals()
	visible = true
	_is_turning = false


func _on_card_item_requested(character_id: String, item_type: String) -> void:
	if phase != Phase.EVENING:
		return
	if not characters.has(character_id):
		return

	var character: Dictionary = characters[character_id]
	if not character["alive"] or character["away"]:
		return
	if inventory[item_type] <= 0:
		return

	inventory[item_type] -= 1
	_apply_item(character, item_type)
	message = "%s: %s" % [character["name"], ITEM_LABELS[item_type]]
	_update_ui()


func _on_end_day() -> void:
	if phase != Phase.EVENING or event_resolved:
		return

	event_resolved = true

	var supply_page := get_node_or_null("SupplyPage")
	if supply_page != null and supply_page.has_method("apply_supplies"):
		supply_page.call("apply_supplies")

	var present := _present_ids()

	var result_parts: Array[String] = [event_text]
	var bonus_lines: Array[String] = []

	if present.has("vasek"):
		inventory["food"] += 1
		bonus_lines.append("Васек приготовил еду: +1 дошик.")
	if present.has("kirya"):
		inventory["water"] += 1
		bonus_lines.append("Киря принёс воды: +1 вода.")
	if present.has("artur"):
		inventory["medicine"] += 1
		bonus_lines.append("Артур нашёл аптечку: +1 аптечка.")

	if bonus_lines.size() > 0:
		result_parts.append("\n".join(bonus_lines))

	day += 1
	phase = Phase.MORNING
	_is_turning = false

	if away_id != "":
		characters[away_id]["away"] = false
	away_id = ""

	var dead_names: Array[String] = []
	for id in CHARACTER_ORDER:
		var character: Dictionary = characters[id]
		if not character["alive"]:
			continue

		character["hunger"] = max(0, int(character["hunger"]) - DAILY_HUNGER_LOSS)
		character["thirst"] = max(0, int(character["thirst"]) - DAILY_THIRST_LOSS)

		if character["hunger"] <= 0:
			character["health"] = max(0, int(character["health"]) - STARVING_HEALTH_LOSS)

		if bool(character["fed_today"]):
			character["days_without_food"] = 0
		else:
			character["days_without_food"] = int(character["days_without_food"]) + 1
		character["fed_today"] = false

		if bool(character["drank_today"]):
			character["days_without_water"] = 0
		else:
			character["days_without_water"] = int(character["days_without_water"]) + 1
		character["drank_today"] = false

		var days_without := int(character["days_without_food"])
		if days_without > HUNGER_DEATH_BASE_DAYS:
			var death_chance: float = min(
				1.0,
				0.5 + 0.25 * (days_without - HUNGER_DEATH_BASE_DAYS - 1)
			)
			if randf() < death_chance:
				character["alive"] = false
				dead_names.append(character["name"] + " (истощение)")
				continue

		var days_without_water := int(character["days_without_water"])
		if days_without_water > THIRST_DEATH_BASE_DAYS:
			var thirst_death_chance: float = min(
				1.0,
				0.4 + 0.2 * (days_without_water - THIRST_DEATH_BASE_DAYS - 1)
			)
			if randf() < thirst_death_chance:
				character["alive"] = false
				dead_names.append(character["name"] + " (обезвоживание)")
				continue

		if int(character["health"]) <= 0:
			character["alive"] = false
			dead_names.append(character["name"])

	if dead_names.size() > 0:
		result_parts.append("Ночью не стало: " + ", ".join(dead_names) + ".")

	last_event_result = "\n".join(result_parts)
	event_resolved = false
	selected_id = ""
	_clear_item_selection()
	message = "Наступило утро дня %d." % day
	_update_ui()
	_apply_phase_visuals()
	_update_diary_day()
	await _close_diary_and_show_day_intro()


func _close_diary_and_show_day_intro() -> void:
	var game := get_tree().current_scene
	if game == null:
		return

	var book_button := game.get_node_or_null("Layer_Book/Button")
	if book_button != null and bool(book_button.get("book_is_open")):
		book_button.emit_signal("pressed")
		await get_tree().create_timer(0.75).timeout

	var interface := game.get_node_or_null("Interface")
	if interface != null and interface.has_method("play_day_intro"):
		await interface.play_day_intro(day, true)


func _prepare_event() -> void:
	event_resolved = false
	var present := _present_ids()
	var present_names := _names(present)
	var away_name := ""
	if away_id != "":
		away_name = characters[away_id]["name"]

	if present.is_empty():
		if away_name != "":
			event_text = "%s ушёл на пары. В комнате пусто, вечер проходит в тишине." % away_name
		else:
			event_text = "В комнате никого не осталось."
		return

	if away_id == "":
		event_text = "Все в сборе. Вечер проходит спокойно."
	else:
		event_text = "%s ушёл на пары и не участвует в вечере. В комнате: %s." % [away_name, present_names]

	var details: Array[String] = []
	if present.has("vasek"):
		details.append("Васек готовит ужин.")
	if present.has("kirya"):
		details.append("Киря приносит воды.")
	if present.has("artur"):
		details.append("Артур находит аптечку.")

	if details.size() > 0:
		event_text += "\n" + "\n".join(details)


func _apply_item(character: Dictionary, item_type: String) -> void:
	match item_type:
		"food":
			character["hunger"] = min(100, int(character["hunger"]) + FOOD_VALUE)
			character["days_without_food"] = 0
			character["fed_today"] = true
		"water":
			character["thirst"] = min(100, int(character["thirst"]) + WATER_VALUE)
			character["days_without_water"] = 0
			character["drank_today"] = true
		"medicine":
			character["health"] = min(100, int(character["health"]) + MEDICINE_VALUE)


func _hunger_stage(character: Dictionary) -> String:
	var days := int(character.get("days_without_food", 0))
	if days >= 4:
		return HUNGER_EXHAUSTED
	if days >= 2:
		return HUNGER_STARVING
	if bool(character.get("fed_today", false)) or int(character.get("hunger", 0)) >= 90:
		return HUNGER_SATIATED
	return HUNGER_NEUTRAL


func _thirst_stage(character: Dictionary) -> String:
	var days := int(character.get("days_without_water", 0))
	if days >= THIRST_DEATH_BASE_DAYS:
		return THIRST_DEHYDRATED
	if days >= 2:
		return THIRST_THIRSTY
	return THIRST_NEUTRAL


func _present_ids() -> Array[String]:
	var result: Array[String] = []
	for id in CHARACTER_ORDER:
		var character: Dictionary = characters[id]
		if character["alive"] and not character["away"]:
			result.append(id)
	return result


func _names(ids: Array[String]) -> String:
	var names: Array[String] = []
	for id in ids:
		names.append(characters[id]["name"])
	return ", ".join(names)


func _update_ui() -> void:
	if phase == Phase.MORNING:
		header.text = "УТРО · ДЕНЬ %d" % day
	else:
		header.text = "ВЕЧЕР · ДЕНЬ %d" % day

	var morning_phase := phase == Phase.MORNING
	last_event_title.visible = morning_phase
	last_event_text.visible = morning_phase
	morning.visible = morning_phase
	evening.visible = not morning_phase
	last_event_title.text = "ЗНАКОМСТВО" if day == 1 else "ПРОШЛЫМ ВЕЧЕРОМ"
	last_event_text.text = last_event_result
	event_text_label.text = event_text
	event_text_label.visible = not morning_phase
	message_label.text = message

	var supply_page := get_node_or_null("SupplyPage")
	if supply_page != null:
		supply_page.visible = not morning_phase
		if not morning_phase:
			supply_page.call("refresh")

	_update_character_buttons()
	_update_item_buttons()
	_update_character_cards()

	confirm_morning.visible = morning_phase
	confirm_morning.disabled = _is_turning
	if selected_id == "":
		confirm_morning.text = "ЖДАТЬ ВЕЧЕРА"
	else:
		confirm_morning.text = "ОТПРАВИТЬ: " + characters[selected_id]["name"]


func _update_character_buttons() -> void:
	_ui_updating = true
	for id in CHARACTER_ORDER:
		var button := _character_button(id)
		var character: Dictionary = characters[id]
		button.disabled = not character["alive"]
		button.set_pressed_no_signal(id == selected_id)
		button.icon = character["portrait"] if character["alive"] else character["dead_portrait"]
		button.text = ""
		button.tooltip_text = character["name"]
	_ui_updating = false


func _update_item_buttons() -> void:
	_ui_updating = true
	var can_choose := selected_id != ""

	for item_type in ITEM_ORDER:
		var button := _item_button(item_type)
		button.disabled = not can_choose or inventory[item_type] <= 0
		if not can_choose:
			button.set_pressed_no_signal(false)

		button.text = ""
		button.tooltip_text = "%s (%d)" % [ITEM_LABELS[item_type], inventory[item_type]]
	_ui_updating = false


func _update_character_cards() -> void:
	var is_evening := phase == Phase.EVENING

	for card in cards.get_children():
		if not card.has_method("update_state"):
			continue

		var character_id: String = card.get("character_id")
		var character: Dictionary = characters[character_id]
		card.call("set_phase", is_evening)
		card.call(
			"update_state",
			character["hunger"],
			character["thirst"],
			character["health"],
			character["alive"],
			character["away"],
			inventory["food"],
			inventory["water"],
			inventory["medicine"],
			_hunger_stage(character),
			_thirst_stage(character)
		)

	var intro_cards := get_parent().get_node_or_null("Day1Page1/RightColumn")
	if intro_cards != null:
		for card in intro_cards.get_children():
			if card.has_method("set_alive"):
				var intro_id: String = card.get("character_id")
				if characters.has(intro_id):
					card.call("set_alive", characters[intro_id]["alive"])


func _clear_item_selection() -> void:
	for item_type in ITEM_ORDER:
		_item_button(item_type).set_pressed_no_signal(false)


func _character_button(character_id: String) -> Button:
	match character_id:
		"artur":
			return artur_select
		"vasek":
			return vasek_select
		"kirya":
			return kirya_select
	return null


func _item_button(item_type: String) -> Button:
	match item_type:
		"food":
			return food_select
		"water":
			return water_select
		"medicine":
			return medicine_select
	return null


func _apply_phase_visuals() -> void:
	var game := get_tree().current_scene
	if game == null:
		return

	var evening_sprite := game.get_node_or_null("CanvasLayer/Day/Evening")
	if evening_sprite is CanvasItem:
		evening_sprite.visible = phase == Phase.EVENING

	var sprite_names := {
		"artur": "Artur",
		"vasek": "Vasek",
		"kirya": "Kirya",
	}

	for id in CHARACTER_ORDER:
		var character: Dictionary = characters[id]
		var sprite := game.find_child(sprite_names[id], true, false)
		if sprite is CanvasItem:
			sprite.visible = character["alive"] and not character["away"]

		var dead_sprite := game.find_child(sprite_names[id] + "D", true, false)
		if dead_sprite is CanvasItem:
			dead_sprite.visible = not character["alive"]


func _update_diary_day() -> void:
	var game := get_tree().current_scene
	if game == null:
		return

	var book := game.get_node_or_null("Layer_Book/Book")
	if book != null and book.has_method("set_day"):
		book.call("set_day", day)
