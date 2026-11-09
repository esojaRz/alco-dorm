extends Node

@onready var tooltip: Control = get_node("../../CharacterTooltip")
@onready var tooltip_label: Label = get_node("../../CharacterTooltip/Label")

var _day_cycle: Node
var _areas: Dictionary = {}
var _anchors: Dictionary = {}
var _dead_anchors: Dictionary = {}


func _ready() -> void:
	_day_cycle = get_tree().current_scene.get_node_or_null("Layer_Book/Book/DiaryPages/DayCyclePage")

	_areas = {
		"artur": [$Node2D2/Artur/Area2D, $Node2D2/ArturD/Area2D],
		"vasek": [$Node2D/Vasek/Area2D, $Node2D/VasekD/Area2D],
		"kirya": [$Node2D3/Kirya/Area2D, $Node2D3/KiryaD/Area2D],
	}
	_anchors = {
		"artur": $Node2D2/Artur/TooltipAnchor,
		"vasek": $Node2D/Vasek/TooltipAnchor,
		"kirya": $Node2D3/Kirya/TooltipAnchor,
	}
	_dead_anchors = {
		"artur": $Node2D2/ArturD/TooltipAnchor,
		"vasek": $Node2D/VasekD/TooltipAnchor,
		"kirya": $Node2D3/KiryaD/TooltipAnchor,
	}

	for id in _areas:
		for area in _areas[id]:
			var hit_area: Area2D = area
			hit_area.mouse_entered.connect(_show_tooltip.bind(id))
			hit_area.mouse_exited.connect(_hide_tooltip)

	tooltip.visible = false


func _show_tooltip(character_id: String) -> void:
	if _day_cycle == null or not _day_cycle.characters.has(character_id):
		return

	var character: Dictionary = _day_cycle.characters[character_id]
	var alive := bool(character["alive"])
	var lines: Array[String] = [character["name"]]

	if alive:
		var hunger_stage := String(_day_cycle.call("_hunger_stage", character))
		var thirst_stage := String(_day_cycle.call("_thirst_stage", character))
		if hunger_stage != "Нейтральный":
			lines.append(hunger_stage)
		if thirst_stage != "Нейтральный":
			lines.append(thirst_stage)
	else:
		lines.append("Скончался")

	tooltip_label.text = "\n".join(lines)
	tooltip.reset_size()

	var anchor: Node2D = _anchors[character_id] if alive else _dead_anchors[character_id]
	tooltip.position = Vector2(
		anchor.global_position.x - tooltip.size.x * 0.5,
		anchor.global_position.y - tooltip.size.y - 10.0
	)
	tooltip.visible = true


func _hide_tooltip() -> void:
	tooltip.visible = false
