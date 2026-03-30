extends Node3D
class_name UIStepper

const PARAM_TIME := "time"
const PARAM_DATE := "date"
const PARAM_TEMP := "temp"

@export var slider_path: NodePath = NodePath("")
@export var decrement_button_path: NodePath = NodePath("")
@export var increment_button_path: NodePath = NodePath("")
@export var value_label_path: NodePath = NodePath("")
@export var step: float = 0.1
@export var format_string: String = "%.2f"
@export var auto_label: bool = true
@export var clamp_to_range: bool = true
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var grid_span: Vector2i = Vector2i.ONE

@onready var _slider: UISlider = _resolve_slider()
@onready var _btn_dec: UIWidget = _resolve_button(decrement_button_path)
@onready var _btn_inc: UIWidget = _resolve_button(increment_button_path)
@onready var _label: Node = _resolve_label()
var _bound_param: String = ""
var _bound_on_param: Callable = Callable()

static func create_from_def(
	def: Dictionary,
	slider_textures: Dictionary,
	button_textures: Dictionary,
	component_sizes: Dictionary
) -> UIStepper:
	var name = str(def.get("name", "Stepper"))
	var label_text = str(def.get("label", "Stepper"))
	var min_value = float(def.get("min", 0.0))
	var max_value = float(def.get("max", 1.0))
	var step_value = float(def.get("step", 0.1))
	var start_value = float(def.get("value", (min_value + max_value) * 0.5))
	start_value = clamp(start_value, min_value, max_value)
	var format_string = str(def.get("format", "%.2f"))
	var auto_label = bool(def.get("auto_label", true))
	var hide_slider = bool(def.get("hide_slider", false))

	var stepper = UIStepper.new()
	stepper.name = name
	stepper.slider_path = NodePath(name + "Slider")
	stepper.decrement_button_path = NodePath(name + "Down")
	stepper.increment_button_path = NodePath(name + "Up")
	stepper.value_label_path = NodePath(name + "ValueLabel")
	stepper.step = step_value
	stepper.format_string = format_string
	stepper.auto_label = auto_label

	var stepper_sizes: Dictionary = component_sizes.get("stepper", {})
	var slider_sizes: Dictionary = component_sizes.get("slider", {})
	var button_sizes: Dictionary = component_sizes.get("button", {})
	var layout_sizes: Dictionary = def.get("layout", {})

	var label_y: float = float(layout_sizes.get("label_y", def.get("label_y", stepper_sizes.get("label_y", 0.18))))
	var value_label_y: float = float(layout_sizes.get("value_label_y", def.get("value_label_y", stepper_sizes.get("value_label_y", 0.08))))
	var control_row_y: float = float(layout_sizes.get("control_row_y", def.get("control_row_y", stepper_sizes.get("control_row_y", -0.06))))
	var button_offset_x: float = float(layout_sizes.get("button_offset_x", def.get("button_offset_x", stepper_sizes.get("button_offset_x", 0.42))))
	var bar_length: float = float(layout_sizes.get("bar_length", def.get("bar_length", stepper_sizes.get("bar_length", 0.4))))
	var dec_style: String = str(layout_sizes.get("decrement_style", def.get("decrement_style", stepper_sizes.get("decrement_style", "primary"))))
	var inc_style: String = str(layout_sizes.get("increment_style", def.get("increment_style", stepper_sizes.get("increment_style", "secondary"))))

	var slider_label_z: float = float(slider_sizes.get("label_z", 0.02))
	var button_label_z: float = float(button_sizes.get("label_z", 0.02))

	var label = UIWidget.make_text_mesh_label(name + "Label", label_text, 8)
	label.position = Vector3(0.0, label_y, slider_label_z)
	stepper.add_child(label)

	var value_label_text = ""
	if auto_label:
		value_label_text = format_string % start_value
	var value_label = UIWidget.make_text_mesh_label(name + "ValueLabel", value_label_text, 8)
	value_label.position = Vector3(0.0, value_label_y, slider_label_z)
	stepper.add_child(value_label)

	var slider = UISlider.create_slider(
		name + "Slider",
		"",
		slider_textures["bar"],
		slider_textures["low"],
		slider_textures["mid"],
		slider_textures["high"],
		slider_sizes,
		slider_label_z
	)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.set_value(start_value)
	slider.bar_length = bar_length
	slider.position = Vector3(0.0, control_row_y, 0.0)
	if hide_slider:
		var bar = slider.get_node_or_null("Bar")
		var handle = slider.get_node_or_null("Handle")
		if bar:
			bar.visible = false
		if handle:
			handle.visible = false
		var shape = slider.get_node_or_null("CollisionShape3D")
		if shape and shape is CollisionShape3D:
			shape.disabled = true
		slider.set_enabled(false)
	stepper.add_child(slider)

	var dec_pair: Array = _resolve_button_pair(button_textures, dec_style, "primary")
	var inc_pair: Array = _resolve_button_pair(button_textures, inc_style, "secondary")
	var down = UIButton.create_button(name + "Down", "-", dec_pair[0], dec_pair[1], button_label_z)
	down.position = Vector3(-button_offset_x, control_row_y, 0.0)
	var down_label = down.get_node_or_null("TextLabel")
	if down_label:
		down_label.position = Vector3(0.0, 0.0, button_label_z)
	stepper.add_child(down)

	var up = UIButton.create_button(name + "Up", "+", inc_pair[0], inc_pair[1], button_label_z)
	up.position = Vector3(button_offset_x, control_row_y, 0.0)
	var up_label = up.get_node_or_null("TextLabel")
	if up_label:
		up_label.position = Vector3(0.0, 0.0, button_label_z)
	stepper.add_child(up)
	return stepper

static func _resolve_button_pair(button_textures: Dictionary, style_key: String, fallback_key: String) -> Array:
	var pair: Variant = button_textures.get(style_key, button_textures.get(fallback_key, []))
	if pair is Array and pair.size() >= 2:
		return pair
	var fallback_pair: Variant = button_textures.get(fallback_key, [])
	if fallback_pair is Array and fallback_pair.size() >= 2:
		return fallback_pair
	return [null, null]

func bind_param(param: String, on_param: Callable) -> void:
	var slider = _resolve_slider()
	if slider == null:
		return
	_bound_param = param
	_bound_on_param = on_param
	# Apply immediately so bound labels (for example temp) are initialized.
	_apply_bound_param(slider.value, false)

func sync_value(value: Variant, emit_signal: bool = false) -> void:
	var slider = _resolve_slider()
	if slider == null:
		return
	if not (value is int or value is float):
		return
	slider.set_value(float(value))
	_apply_bound_param(slider.value, emit_signal)
	_refresh_label()

static func normalize_slider_value(slider: UISlider, value: float) -> float:
	if slider.max_value <= slider.min_value:
		return 0.0
	return clamp((value - slider.min_value) / (slider.max_value - slider.min_value), 0.0, 1.0)

static func format_time_label(value: float) -> String:
	var clamped = clamp(value, 0.0, 1.0)
	var total_minutes = int(round(clamped * 1440.0))
	if total_minutes >= 1440:
		total_minutes = 0
	var hours = int(total_minutes / 60)
	var minutes = int(total_minutes % 60)
	return "Time: %02d:%02d" % [hours, minutes]

static func format_day_label(day_of_year: int, year: int = 2024) -> String:
	var max_day = 366 if is_leap_year(year) else 365
	var clamped = int(clamp(day_of_year, 1, max_day))
	var md = date_from_day_of_year(year, clamped)
	return "Date: %02d/%02d/%04d" % [md["month"], md["day"], year]

static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

static func date_from_day_of_year(year: int, day_of_year: int) -> Dictionary:
	var month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var remaining = day_of_year
	for m in range(12):
		var days_in_month = month_lengths[m]
		if m == 1 and is_leap_year(year):
			days_in_month += 1
		if remaining > days_in_month:
			remaining -= days_in_month
		else:
			return {"month": m + 1, "day": remaining}
	return {"month": 12, "day": 31}

func _ready() -> void:
	_bind_buttons()
	_refresh_label()
	if is_instance_valid(_slider) and not _slider.value_changed.is_connected(_on_slider_value_changed):
		_slider.value_changed.connect(_on_slider_value_changed)

func _bind_buttons() -> void:
	if is_instance_valid(_btn_dec) and not _btn_dec.activated.is_connected(_on_decrement):
		_btn_dec.activated.connect(_on_decrement)
	if is_instance_valid(_btn_inc) and not _btn_inc.activated.is_connected(_on_increment):
		_btn_inc.activated.connect(_on_increment)

func _on_decrement(sender_id: int) -> void:
	_step_value(sender_id, -step)

func _on_increment(sender_id: int) -> void:
	_step_value(sender_id, step)

func _step_value(sender_id: int, delta: float) -> void:
	if not is_instance_valid(_slider):
		return
	var v = _slider.value + delta
	if clamp_to_range:
		v = clamp(v, _slider.min_value, _slider.max_value)
	_slider.set_value(v)
	_slider.value_changed.emit(sender_id, _slider.value)
	_slider.value_committed.emit(sender_id, _slider.value)
	_refresh_label()

func _on_slider_value_changed(_sender_id: int, _value: float) -> void:
	_apply_bound_param(_value, true)
	_refresh_label()

func _apply_bound_param(value: float, emit_signal: bool) -> void:
	if _bound_param == "":
		return
	var slider = _resolve_slider()
	if slider == null:
		return
	var label_node = _resolve_label()
	match _bound_param:
		PARAM_TIME:
			var t = normalize_slider_value(slider, value)
			UIWidget.set_label_text(label_node, format_time_label(t))
			if emit_signal and _bound_on_param.is_valid():
				_bound_on_param.call(t)
		PARAM_DATE:
			var day = int(round(clamp(value, slider.min_value, slider.max_value)))
			UIWidget.set_label_text(label_node, format_day_label(day))
			if emit_signal and _bound_on_param.is_valid():
				_bound_on_param.call(day)
		PARAM_TEMP:
			var temp = clamp(value, slider.min_value, slider.max_value)
			var temp_text = format_string % temp
			UIWidget.set_label_text(label_node, "Temp: %s C" % temp_text)
			if emit_signal and _bound_on_param.is_valid():
				_bound_on_param.call(temp)
		_:
			UIWidget.set_label_text(label_node, format_string % value)
			if emit_signal and _bound_on_param.is_valid():
				_bound_on_param.call(value)

func _refresh_label() -> void:
	if not auto_label:
		return
	if not is_instance_valid(_label) or not is_instance_valid(_slider):
		return
	var text = format_string % _slider.value
	_set_label_text(_label, text)

func _resolve_slider() -> UISlider:
	if slider_path == NodePath(""):
		return null
	var n = get_node_or_null(slider_path)
	if n and n is UISlider:
		return n
	return null

func _resolve_button(path: NodePath) -> UIWidget:
	if path == NodePath(""):
		return null
	var n = get_node_or_null(path)
	if n and n is UIWidget:
		return n
	return null

func _resolve_label() -> Node:
	if value_label_path == NodePath(""):
		return null
	return get_node_or_null(value_label_path)

func _set_label_text(node: Node, text: String) -> void:
	if not is_instance_valid(node):
		return
	if node is Label3D:
		node.text = text
		return
	if node is Label:
		node.text = text
		return
	if node is MeshInstance3D and node.mesh is TextMesh:
		var tm: TextMesh = node.mesh
		tm.text = text
