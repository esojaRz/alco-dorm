@tool
extends TextureRect

## Подложка книги для редактирования day_cycle.tscn.
## В самой игре книга уже есть в node_2d, поэтому здесь превью скрывается,
## чтобы не рисовать вторую книгу поверх настоящей.

func _ready() -> void:
	var page := get_parent()
	var diary_pages := page.get_parent() if page != null else null
	var book := diary_pages.get_parent() if diary_pages != null else null
	visible = book == null or not book.has_method("set_day")
