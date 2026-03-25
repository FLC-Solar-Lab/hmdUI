
extends UIWidget
class_name UISlider

signal value_committed(sender_id: int, value: float)

@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var value: float = 0.0
@export var bar_length: float = 0.6
@export var handle_path: NodePath = NodePath("")
@export var handle_low_texture: Texture2D
@export var handle_mid_texture: Texture2D
@export var handle_high_texture: Texture2D
@export var use_value_colors: bool = true

@onready var _handle: Node3D = _resolve_handle()

static func create_slider(
	name: String,
	label_text: String,
	bar_texture: Texture2D,
	handle_low: Texture2D,
	handle_mid: Texture2D,
	handle_high: Texture2D,
	sizes: Dictionary,
	label_z: float
) -> UISlider:
	var slider_node = UISlider.new()
	slider_node.name = name
	slider_node.handle_path = NodePath("Handle")
	slider_node.handle_low_texture = handle_low
	slider_node.handle_mid_texture = handle_mid
	slider_node.handle_high_texture = handle_high

	var bar = Sprite3D.new()
	bar.name = "Bar"
	bar.texture = bar_texture
	bar.pixel_size = 0.2
	bar.scale = Vector3(sizes.get("bar_scale", Vector2(2.2, 0.28)).x, sizes.get("bar_scale", Vector2(2.2, 0.28)).y, 1.0)
	bar.position = Vector3(0.0, 0.0, float(sizes.get("bar_z", 0.0)))
	slider_node.add_child(bar)

	var handle = Sprite3D.new()
	handle.name = "Handle"
	handle.texture = handle_low
	handle.pixel_size = 0.2
	handle.scale = Vector3(sizes.get("handle_scale", Vector2(0.35, 0.55)).x, sizes.get("handle_scale", Vector2(0.35, 0.55)).y, 1.0)
	handle.position = Vector3(0.0, 0.0, float(sizes.get("handle_z", 0.02)))
	slider_node.add_child(handle)

	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.6, 0.12, 0.01)
	shape.add_to_group("no_noodles")
	slider_node.add_child(shape)

	var label = UIWidget.make_text_mesh_label(name + "Label", label_text, 8)
	label.position = Vector3(0.0, 0.18, label_z)
	slider_node.add_child(label)
	return slider_node

func _resolve_handle() -> Node3D:
	if handle_path != NodePath(""):
		var n = get_node_or_null(handle_path)
		if n and n is Node3D:
			return n
	return null

func set_value(v: float) -> void:
	value = clamp(v, min_value, max_value)
	_update_handle()

func get_value() -> float:
	return value

func _emit_value_changed(sender_id: int) -> void:
	value_changed.emit(sender_id, value)

func _emit_value_committed(sender_id: int) -> void:
	value_committed.emit(sender_id, value)

func update_from_hit(hit_point: Vector3, sender_id: int) -> void:
	var local = to_local(hit_point)
	var half = bar_length * 0.5
	var t = 0.0
	if bar_length > 0.0:
		t = clamp((local.x + half) / bar_length, 0.0, 1.0)
	value = lerp(min_value, max_value, t)
	_update_handle()
	_emit_value_changed(sender_id)

func on_released(sender_id: int) -> void:
	if not enabled:
		return
	super.on_released(sender_id)
	_emit_value_committed(sender_id)

func _update_handle() -> void:
	if not is_instance_valid(_handle):
		return
	var t = 0.0
	if max_value > min_value:
		t = (value - min_value) / (max_value - min_value)
	var half = bar_length * 0.5
	var x = lerp(-half, half, clamp(t, 0.0, 1.0))
	var p = _handle.position
	_handle.position = Vector3(x, p.y, p.z)
	if use_value_colors and _handle is Sprite3D:
		var sp: Sprite3D = _handle
		var tex: Texture2D = null
		if t < 0.33 and handle_low_texture:
			tex = handle_low_texture
		elif t < 0.66 and handle_mid_texture:
			tex = handle_mid_texture
		elif handle_high_texture:
			tex = handle_high_texture
		if tex:
			sp.texture = tex
