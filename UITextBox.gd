
extends UIWidget
class_name UITextBox

@export var text: String = ""

var _focused_sender: int = -1

func focus(sender_id: int) -> void:
	if not enabled:
		return
	_focused_sender = sender_id

func unfocus(sender_id: int) -> void:
	if _focused_sender == sender_id:
		_focused_sender = -1

func commit_text(sender_id: int, t: String) -> void:
	if not enabled:
		return
	text = t
	text_committed.emit(sender_id, text)

func set_text(t: String) -> void:
	text = t
	# Visual update hook only. Do not rebuild per keystroke.
