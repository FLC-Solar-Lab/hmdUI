extends Node
class_name InteractionModel

signal widget_pressed(sender_id: int, widget: UIWidget)
signal widget_released(sender_id: int, widget: UIWidget)
signal widget_clicked(sender_id: int, widget: UIWidget)
signal widget_double_clicked(sender_id: int, widget: UIWidget)

signal button_pressed(widget_id: String)
signal double_press_registered(sender_id: int)

@export var double_press_interval: float = 0.4
@export var click_requires_same_widget: bool = true
@export var capture_on_press: bool = true

var _state: Dictionary = {}  # sender_id -> Dictionary

func on_press_hold(sender_id: int, hovered: UIWidget) -> void:
	var state = _get_sender_state(sender_id)
	state["last_hovered"] = hovered

	if state["is_pressing"]:
		# Allow late capture if the first press frame missed any widget.
		if not is_instance_valid(state.get("pressed_widget", null)) and is_instance_valid(hovered):
			state["pressed_widget"] = hovered
			widget_pressed.emit(sender_id, hovered)
		return

	state["is_pressing"] = true

	if capture_on_press:
		state["pressed_widget"] = hovered
	else:
		state["pressed_widget"] = hovered

	var w: UIWidget = state["pressed_widget"]
	if is_instance_valid(w):
		widget_pressed.emit(sender_id, w)

func on_release(sender_id: int, hovered: UIWidget) -> void:
	var state = _get_sender_state(sender_id)
	state["last_hovered"] = hovered

	if not state["is_pressing"]:
		return

	state["is_pressing"] = false

	var pressed: UIWidget = state["pressed_widget"]
	if is_instance_valid(pressed):
		widget_released.emit(sender_id, pressed)

	var clicked: UIWidget = null
	if click_requires_same_widget:
		if is_instance_valid(pressed) and pressed == hovered:
			clicked = pressed
	else:
		if is_instance_valid(pressed):
			clicked = pressed

	state["pressed_widget"] = null

	if not is_instance_valid(clicked):
		return

	widget_clicked.emit(sender_id, clicked)
	button_pressed.emit(clicked.get_widget_id())

	_handle_double_press(sender_id, clicked)

func clear_sender(sender_id: int) -> void:
	if not _state.has(sender_id):
		return

	var state = _state[sender_id]
	var t: Timer = state.get("double_timer", null)
	if is_instance_valid(t):
		t.stop()
		t.queue_free()

	_state.erase(sender_id)

func get_state(sender_id: int) -> Dictionary:
	if not _state.has(sender_id):
		return {}

	var state = _state[sender_id]
	return {
		"is_pressing": state.get("is_pressing", false),
		"pressed_widget": state.get("pressed_widget", null),
		"last_hovered": state.get("last_hovered", null),
		"double_flag": state.get("double_flag", false)
	}

func _handle_double_press(sender_id: int, clicked: UIWidget) -> void:
	var state = _get_sender_state(sender_id)
	var t: Timer = state["double_timer"]

	if not state["double_flag"]:
		state["double_flag"] = true
		t.start()
		return

	if state["double_flag"] and not t.is_stopped():
		widget_double_clicked.emit(sender_id, clicked)
		double_press_registered.emit(sender_id)
		t.stop()
		state["double_flag"] = false

func _get_sender_state(sender_id: int) -> Dictionary:
	if _state.has(sender_id):
		return _state[sender_id]

	var t = Timer.new()
	t.one_shot = true
	t.wait_time = double_press_interval
	t.timeout.connect(func():
		if _state.has(sender_id):
			_state[sender_id]["double_flag"] = false
	)
	add_child(t)

	_state[sender_id] = {
		"is_pressing": false,
		"pressed_widget": null,
		"last_hovered": null,
		"double_flag": false,
		"double_timer": t
	}
	return _state[sender_id]
