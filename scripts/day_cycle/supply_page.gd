extends Control

const ITEM_LABELS := {
	"food": "",
	"water": "",
	"medicine": "",
}
const ITEM_ORDER: Array[String] = ["food", "water", "medicine"]

var _day_cycle: Node
var _selected: Dictionary = {}
var _cards: Dictionary = {}

@onready var message_label: Label = %Message


func _ready() -> void:
	_day_cycle = get_parent()

	_cards = {
		"artur": %ArturCard,
		"vasek": %VasekCard,
		"kirya": %KiryaCard,
	}

	for id in _cards:
		for item_type in ITEM_ORDER:
			var button := _item_button(id, item_type)
			button.toggled.connect(_on_item_toggled.bind(id, item_type))

	visible = false


func refresh() -> void:
	if _day_cycle == null:
		return

	for id in _cards:
		var character: Dictionary = _day_cycle.characters[id]
		var alive := bool(character["alive"])
		var away := bool(character["away"])
		var card: Control = _cards[id]
		var portrait: TextureRect = card.get_node("VBox/Portrait")
		var name_label: Label = card.get_node_or_null("VBox/Name") as Label
		var status_label: Label = card.get_node_or_null("VBox/Status") as Label

		portrait.texture = character["portrait"] if alive else character["dead_portrait"]
		if name_label != null:
			name_label.text = character["name"]
		if status_label != null:
			if not alive:
				status_label.text = "ВЫБЫЛ"
			elif away:
				status_label.text = "НА ПАРАХ"
			else:
				status_label.text = ""
			status_label.visible = status_label.text != ""

		card.modulate = Color(1, 1, 1, 1) if alive and not away else Color(1, 1, 1, 0.45)

		for item_type in ITEM_ORDER:
			var button := _item_button(id, item_type)
			var available := int(_day_cycle.inventory[item_type])
			button.text = "%s (%d)" % [ITEM_LABELS[item_type], available]
			button.disabled = not alive or away or available <= 0
			var selected: bool = _selected.has(id) and _selected[id].has(item_type)
			button.set_pressed_no_signal(selected)
			var cross := button.get_node_or_null("SelectCross") as TextureRect
			if cross != null:
				cross.visible = selected


func apply_supplies() -> int:
	if _day_cycle == null:
		return 0

	var given := 0
	for character_id in _selected:
		var character: Dictionary = _day_cycle.characters[character_id]
		if not character["alive"] or character["away"]:
			continue
		for item_type in _selected[character_id]:
			if int(_day_cycle.inventory[item_type]) <= 0:
				continue
			_day_cycle.inventory[item_type] = int(_day_cycle.inventory[item_type]) - 1
			_day_cycle._apply_item(character, item_type)
			given += 1

	_selected.clear()
	refresh()
	message_label.text = "Роздано припасов: %d" % given
	return given


func _on_item_toggled(pressed: bool, character_id: String, item_type: String) -> void:
	if not _selected.has(character_id):
		_selected[character_id] = {}
	if pressed:
		_selected[character_id][item_type] = true
	else:
		_selected[character_id].erase(item_type)
	refresh()


func _item_button(character_id: String, item_type: String) -> Button:
	var card: Control = _cards[character_id]
	match item_type:
		"food":
			return card.get_node("VBox/VBoxContainer/Food")
		"water":
			return card.get_node("VBox/VBoxContainer/Water")
		"medicine":
			return card.get_node("VBox/VBoxContainer/Medicine")
	return null
