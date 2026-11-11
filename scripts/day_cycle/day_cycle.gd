extends Control

enum Phase { MORNING, EVENING }

const CHARACTER_ORDER: Array[String] = ["artur", "vasek", "kirya"]

const CHARACTER_DATA := {
	"artur": {
		"name": "Артурик",
		"portrait": preload("res://characters/portrait/artur_p.png"),
		"dead_portrait": preload("res://characters/dead/portrait_d/artur_d_partret.png"),
		"bio": "Опасный паренек.",
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

const ITEM_ORDER: Array[String] = ["food", "water", "cigarettes"]
const ITEM_LABELS := {
	"food": "Доширак",
	"water": "Энергутик",
	"cigarettes": "Сигареты",
}
const START_INVENTORY := {
	"food": 4,
	"water": 4,
	"cigarettes": 1,
}

const FOOD_VALUE := 40
const WATER_VALUE := 40
const CIGARETTES_VALUE := 30

## Пачку сигарет нельзя накопить: одновременно в запасах только одна.
const CIGARETTES_MAX := 1

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

## Приносить припасы может только тот, кто ушёл на пары.
## Шанс, что персонаж вернётся с добычей, и таблица находок у каждого свои.
const LOOT_CHANCE := {
	"artur": 0.4,
	"vasek": 0.35,
	"kirya": 0.4,
}
const LOOT_WEIGHTS := {
	"artur": {"food": 35, "water": 30, "cigarettes": 35},
	"vasek": {"food": 60, "water": 30, "cigarettes": 10},
	"kirya": {"food": 30, "water": 50, "cigarettes": 20},
}
## Подсказка в подсказке кнопки: на чём специализируется персонаж.
const LOOT_HINTS := {
	"artur": "чаще приносит СИГАРЕТЫ",
	"vasek": "чаще приносит ЕДУ",
	"kirya": "чаще приносит ЭНЕРГЕТИК",
}

## Вечерние события: большая ситуация и 2–3 варианта действий.
## У каждого варианта свой исход: текст, изменения запасов и состояние соседей.
## inventory — изменение склада; stats.all / stats.<id> — голод, жажда, здоровье.
const EVENTS := [
	{
		"id": "night_guest",
		"title": "НОЧНОЙ ГОСТЬ",
		"text": "В дверь стучат. На пороге — сосед с третьего этажа: куртка в снегу, руки дрожат, в руке початая бутылка. Его корпус закрыли на ночь, идти ему некуда. Он просит пустить хотя бы до утра.",
		"options": [
			{
				"label": "Пустить на ночь",
				"result": "Он доел остатки доширака и уснул на полу. Утром ушёл, оставив на столе помятую пачку сигарет.",
				"inventory": {"food": -1, "cigarettes": 1},
			},
			{
				"label": "Не пускать",
				"result": "Он стучал ещё полчаса, потом ушёл. До утра в подъезде кто-то бил бутылки, и никто не спал.",
				"stats": {"all": {"health": -10}},
			},
			{
				"label": "Вынести ему чай",
				"result": "Он выпил чай на лестнице, согрелся и ушёл. Бутылку оставил под дверью.",
				"inventory": {"water": -1},
				"stats": {"all": {"health": 5}},
			},
		],
	},
	{
		"id": "flood",
		"title": "ПОТОП НА КУХНЕ",
		"text": "Ночью на общей кухне прорвало трубу. Вода уже в коридоре и медленно подбирается к двери. Соседи спят, из-за двери слышно, как капает с потолка.",
		"options": [
			{
				"label": "Перекрыть стояк",
				"result": "Ты крутил ржавый вентиль в темноте и ободрал руки, но воду остановил. Заодно набрал полную бутылку чистой воды.",
				"inventory": {"water": 1},
				"stats": {"all": {"health": -5}},
			},
			{
				"label": "Разбудить весь этаж",
				"result": "Всем миром перекрыли воду и вытерли коридор. Утром соседи принесли кто доширак, кто энергетик.",
				"inventory": {"food": 1, "water": 1},
				"stats": {"all": {"health": -5}},
			},
			{
				"label": "Заткнуть щель под дверью",
				"result": "Комната осталась сухой, а коридор к утру затопило. Соседи весь день косились в твою сторону.",
			},
		],
	},
	{
		"id": "party",
		"title": "ВЕЧЕРИНКА СВЕРХУ",
		"text": "Сверху второй час гремят басы. Слышно, как открывают бутылки, смеются и что-то роняют. Уснуть невозможно, а до утра ещё далеко.",
		"options": [
			{
				"label": "Попросить тишины",
				"result": "Тебя встретили смехом, но музыку выключили. Кто-то сунул тебе пачку сигарет «за беспокойство».",
				"inventory": {"cigarettes": 1},
				"stats": {"all": {"health": -5}},
			},
			{
				"label": "Пойти на вечеринку",
				"result": "Ты вернулся под утро с чужим энергетиком в кармане и гудящей головой.",
				"inventory": {"water": 1},
				"stats": {"all": {"health": -10, "hunger": 10}},
			},
			{
				"label": "Терпеть до утра",
				"result": "Ты не сомкнул глаз. Утром голова гудела, зато ничего не случилось.",
				"stats": {"all": {"health": -15}},
			},
		],
	},
	{
		"id": "inspection",
		"title": "ОБХОД КОМЕНДАНТА",
		"text": "По общаге прошёл слух: ночью будет обход. Ищут сигареты, алкоголь и тех, кто живёт не по прописке. В коридоре уже слышны тяжёлые шаги и звон ключей.",
		"options": [
			{
				"label": "Открыть дверь и поздороваться",
				"result": "Комендант заглянул, вздохнул и ушёл. Соседи потом говорили, что ты молодец.",
				"stats": {"all": {"health": 5}},
			},
			{
				"label": "Спрятать сигареты в вентиляцию",
				"result": "Ты провозился полчаса. Комендант прошёл мимо, но утром сигареты нашлись отсыревшими.",
				"inventory": {"cigarettes": -1},
				"stats": {"all": {"health": -5}},
			},
			{
				"label": "Сделать вид, что никого нет",
				"result": "Шаги замерли у двери. Кто-то дёрнул ручку и ушёл. Ты не дышал до утра.",
				"stats": {"all": {"health": -10}},
			},
		],
	},
	{
		"id": "fight",
		"title": "ДРАКА НА ЭТАЖЕ",
		"text": "В коридоре шум: двое соседей сцепились из-за какой-то ерунды. Слышны крики, звон и грохот упавшего стула. Драка медленно перемещается к вашей двери.",
		"options": [
			{
				"label": "Разнять",
				"result": "Ты влез между ними и получил локтем в лицо, но драку остановил. Утром оба принесли извинения и по дошираку.",
				"inventory": {"food": 1},
				"stats": {"all": {"health": -10}},
			},
			{
				"label": "Позвать коменданта",
				"result": "Комендант разогнал всех по комнатам. Соседи весь день смотрели косо, зато драки больше не было.",
				"stats": {"all": {"health": 5}},
			},
			{
				"label": "Не вмешиваться",
				"result": "Ты переждал за дверью. Утром на этаже недосчитались пары вещей — и твоего доширака тоже.",
				"inventory": {"food": -1},
			},
		],
	},
	{
		"id": "cold",
		"title": "ОТОПЛЕНИЕ ОТКЛЮЧИЛИ",
		"text": "Отопление отключили до утра. Батареи ледяные, из окна дует, одеял на всех не хватает. В комнате становится заметно холоднее.",
		"options": [
			{
				"label": "Собраться всем в одной комнате",
				"result": "Вчетвером было теплее. Спали плохо, но никто не замёрз.",
				"stats": {"all": {"health": 5, "hunger": -5}},
			},
			{
				"label": "Переждать каждый у себя",
				"result": "К утру все продрогли и не выспались.",
				"stats": {"all": {"health": -10}},
			},
		],
	},
]

## Бонусы за предметы, которые персонаж взял с собой на пары.
const CARRY_LOOT_CHANCE_BONUS := 0.08
const CARRY_EXTRA_ITEM_CHANCE := 0.15
const CARRY_WEIGHT_MULTIPLIER := 2.0
const CARRY_CIGARETTES_WEIGHT_MULTIPLIER := 3.0
const MAX_LOOT_QUANTITY := 2
const MAX_LOOT_CHANCE := 0.95

var day := 1
var phase := Phase.MORNING
var inventory: Dictionary = {}
var characters: Dictionary = {}

var selected_id := ""
var away_id := ""
var away_items: Array[String] = []
var last_event_result := ""
var event_text := ""
var event_resolved := false
var event_choice_made := false
var event_result_text := ""
var _current_event: Dictionary = {}
var _last_event_id := ""
## Название события, итог которого показываем утром на следующей странице.
var last_event_name := ""

var message := "Выбери, кто пойдёт на пары. Можно никого не отправлять."
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
@onready var event_title_label: Label = %EventTitle
@onready var event_text_label: Label = %EventText
@onready var choices: VBoxContainer = %Choices
@onready var choice_buttons: Array = [%Choice1, %Choice2, %Choice3]
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

	last_event_result = "Первый день. Выбери, кто пойдёт на пары, и что возьмёт с собой."

	artur_select.toggled.connect(_on_character_toggled.bind("artur"))
	vasek_select.toggled.connect(_on_character_toggled.bind("vasek"))
	kirya_select.toggled.connect(_on_character_toggled.bind("kirya"))

	food_select.toggled.connect(_on_item_toggled)
	water_select.toggled.connect(_on_item_toggled)
	medicine_select.toggled.connect(_on_item_toggled)

	confirm_morning.pressed.connect(_on_confirm_morning)
	end_day.pressed.connect(_on_end_day)

	for i in choice_buttons.size():
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

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

	message = "День 1. Утро. Выбери, кто пойдёт на пары."

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

	# Запоминаем, что именно он унёс: это даст бонусы к вечерней добыче.
	away_items.clear()
	if selected_id != "":
		away_items = taken.duplicate()

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
	if phase != Phase.EVENING or event_resolved or not event_choice_made:
		return

	event_resolved = true

	var supply_page := get_node_or_null("SupplyPage")
	if supply_page != null and supply_page.has_method("apply_supplies"):
		supply_page.call("apply_supplies")

	# Утренняя сводка: чем закончился вечер, что принёс ушедший на пары
	# и кто не пережил ночь. Показываем её на следующей странице, уже утром.
	var night_parts: Array[String] = []

	var loot_lines := _roll_loot()
	night_parts.append_array(loot_lines)

	day += 1
	phase = Phase.MORNING
	_is_turning = false

	if away_id != "":
		characters[away_id]["away"] = false
	away_id = ""
	away_items.clear()

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
		night_parts.append("Ночью не стало: " + ", ".join(dead_names) + ".")

	if night_parts.is_empty():
		night_parts.append("Ночь прошла спокойно.")

	var morning_parts: Array[String] = []
	if event_result_text != "":
		morning_parts.append(event_result_text)
	morning_parts.append_array(night_parts)

	last_event_result = "\n\n".join(morning_parts)
	last_event_name = String(_current_event.get("title", ""))
	event_resolved = false
	selected_id = ""
	_clear_item_selection()
	message = "Наступило утро дня %d." % day
	_update_diary_day()
	await _close_diary_and_show_day_intro()
	# Страховка, если интро не проигралось: состояние всё равно обновится.
	_apply_morning_state()


## Обновляет книгу и комнату под утро. Вызывается, пока экран чёрный,
## чтобы смерть персонажа игрок увидел уже после затемнения.
func _apply_morning_state() -> void:
	_update_ui()
	_apply_phase_visuals()


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
		await interface.play_day_intro(day, true, false, Callable(self, "_apply_morning_state"))


## Возвращает строки о том, что персонаж принёс с пар.
## Приносить припасы может только тот, кто ушёл на пары.
func _roll_loot() -> Array[String]:
	var lines: Array[String] = []
	if away_id == "":
		return lines

	var character_name: String = characters[away_id]["name"]

	# Каждый предмет в руках немного повышает шанс вернуться с добычей.
	var chance := float(LOOT_CHANCE[away_id]) + CARRY_LOOT_CHANCE_BONUS * away_items.size()
	chance = minf(chance, MAX_LOOT_CHANCE)

	if randf() >= chance:
		lines.append("%s вернулся с пар ни с чем." % character_name)
		return lines

	var item_type := _pick_loot_item(away_id)
	if item_type == "":
		lines.append("%s вернулся с пар ни с чем." % character_name)
		return lines

	var quantity := 1
	# Взятые с собой вещи позволяют унести больше за один раз.
	if randf() < CARRY_EXTRA_ITEM_CHANCE * away_items.size():
		quantity += 1
	quantity = mini(quantity, MAX_LOOT_QUANTITY)

	if item_type == "cigarettes":
		var room := CIGARETTES_MAX - int(inventory[item_type])
		quantity = mini(quantity, room)
	if quantity <= 0:
		return lines

	inventory[item_type] = int(inventory[item_type]) + quantity
	lines.append(
		"%s принёс с пар: %s ×%d." % [character_name, ITEM_LABELS[item_type], quantity]
	)
	return lines


## Взвешенный выбор находки. У каждого персонажа свои шансы,
## а взятый с собой предмет повышает шанс найти именно его.
func _pick_loot_item(character_id: String) -> String:
	var weights: Dictionary = {}
	var total := 0.0
	var character_weights: Dictionary = LOOT_WEIGHTS[character_id]

	for item_type in ITEM_ORDER:
		# Пачка сигарет всегда одна, поэтому вторую не ищем.
		if item_type == "cigarettes" and int(inventory[item_type]) >= CIGARETTES_MAX:
			continue

		var weight := float(character_weights[item_type])
		if item_type in away_items:
			if item_type == "cigarettes":
				weight *= CARRY_CIGARETTES_WEIGHT_MULTIPLIER
			else:
				weight *= CARRY_WEIGHT_MULTIPLIER
		if weight <= 0.0:
			continue

		weights[item_type] = weight
		total += weight

	if total <= 0.0:
		return ""

	var roll := randf() * total
	for item_type in weights:
		roll -= float(weights[item_type])
		if roll < 0.0:
			return item_type
	return ""


## Ставит на вечер новое большое событие и варианты выбора.
func _prepare_event() -> void:
	event_resolved = false
	event_choice_made = false
	event_result_text = ""
	_current_event = _pick_event()
	event_text = String(_current_event.get("text", ""))
	event_title_label.text = String(_current_event.get("title", "СОБЫТИЯ"))
	_build_choices()


## Случайное событие, но не то же самое, что было в прошлый вечер.
func _pick_event() -> Dictionary:
	if EVENTS.is_empty():
		return {}

	var candidates: Array = []
	for event in EVENTS:
		if event["id"] != _last_event_id:
			candidates.append(event)

	if candidates.is_empty():
		candidates = EVENTS.duplicate()

	var event: Dictionary = candidates[randi() % candidates.size()]
	_last_event_id = String(event["id"])
	return event


func _build_choices() -> void:
	var options: Array = _current_event.get("options", [])
	for i in choice_buttons.size():
		var button: Button = choice_buttons[i]
		var has_option := i < options.size()
		button.visible = has_option
		if has_option:
			button.text = String(options[i].get("label", ""))
			button.disabled = false

	# Если у события вдруг нет вариантов, не запираем игрока в вечере.
	if options.is_empty():
		event_choice_made = true


func _on_choice_pressed(index: int) -> void:
	if phase != Phase.EVENING or event_choice_made:
		return

	var options: Array = _current_event.get("options", [])
	if index < 0 or index >= options.size():
		return

	var option: Dictionary = options[index]
	event_choice_made = true
	_apply_event_effects(option)
	event_result_text = String(option.get("result", ""))
	# Итог не показываем сразу: он окажется утром на следующей странице.
	event_text = String(_current_event.get("text", "")) + "\n\nТвой выбор: " + String(option.get("label", ""))
	message = "Выбор сделан. Заверши день — итог будет утром."
	_update_ui()


## Применяет последствия выбора: склад и состояние соседей.
func _apply_event_effects(option: Dictionary) -> void:
	var inventory_changes: Dictionary = option.get("inventory", {})
	for item_type in inventory_changes:
		if not inventory.has(item_type):
			continue
		var value := int(inventory[item_type]) + int(inventory_changes[item_type])
		if item_type == "cigarettes":
			value = mini(value, CIGARETTES_MAX)
		inventory[item_type] = maxi(value, 0)

	var stats: Dictionary = option.get("stats", {})
	for target in stats:
		var changes: Dictionary = stats[target]
		for character_id in CHARACTER_ORDER:
			if target != "all" and target != character_id:
				continue
			var character: Dictionary = characters[character_id]
			if not character["alive"] or character["away"]:
				continue
			for stat in changes:
				if not character.has(stat):
					continue
				character[stat] = clampi(int(character[stat]) + int(changes[stat]), 0, 100)


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
		"cigarettes":
			character["health"] = min(100, int(character["health"]) + CIGARETTES_VALUE)


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


func _last_event_heading() -> String:
	if day == 1:
		return "ЗНАКОМСТВО"
	if last_event_name == "":
		return "ПРОШЛЫМ ВЕЧЕРОМ"
	return "ПРОШЛЫМ ВЕЧЕРОМ · " + last_event_name


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
	last_event_title.text = _last_event_heading()
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
	choices.visible = not morning_phase and not event_choice_made
	end_day.visible = not morning_phase and event_choice_made
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
		button.tooltip_text = "%s — %s" % [character["name"], LOOT_HINTS[id]]
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
			inventory["cigarettes"],
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
		"cigarettes":
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
