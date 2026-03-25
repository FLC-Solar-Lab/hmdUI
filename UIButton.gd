extends UIWidget
class_name UIButton

@export var pressed_scale: Vector3 = Vector3(1.1, 1.1, 1.1)
@export var released_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var animate_target_path: NodePath = NodePath("")
@export var normal_material: Material
@export var pressed_material: Material
@export var target_path: NodePath = NodePath("")
@export var normal_texture: Texture2D
@export var pressed_texture: Texture2D
@export var texture_target_path: NodePath = NodePath("")
@export var cycle_on_click: bool = false
@export var cycle_textures: Array[Texture2D] = []
@export var cycle_pressed_textures: Array[Texture2D] = []

@onready var _target: Node3D = _resolve_target()
@onready var _material_target: Node3D = _resolve_material_target()
@onready var _texture_target: Node3D = _resolve_texture_target()
var _is_pressed: bool = false
var _cycle_index: int = 0

static func create_button(name: String, label_text: String, tex: Texture2D, tex_pressed: Texture2D, label_z: float = 0.02) -> UIButton:
	var btn = UIButton.new()
	btn.name = name
	btn.add_to_group("ui_component")
	btn.normal_texture = tex
	btn.pressed_texture = tex_pressed
	btn.texture_target_path = NodePath("Sprite")

	var sprite = Sprite3D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.pixel_size = 0.18
	btn.add_child(sprite)

	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.2, 0.2, 0.01)
	shape.add_to_group("no_noodles")
	btn.add_child(shape)

	var label = UIWidget.make_text_mesh_label("TextLabel", label_text, 8)
	label.position = Vector3(0.0, -0.18, label_z)
	btn.add_child(label)
	return btn

func _resolve_target() -> Node3D:
	if animate_target_path != NodePath(""):
		var n = get_node_or_null(animate_target_path)
		if n and n is Node3D:
			return n
	return self

func _resolve_material_target() -> Node3D:
	if target_path != NodePath(""):
		var n = get_node_or_null(target_path)
		if n and n is Node3D:
			return n
	return self

func _resolve_texture_target() -> Node3D:
	if texture_target_path != NodePath(""):
		var n = get_node_or_null(texture_target_path)
		if n and n is Node3D:
			return n
	return _material_target

func on_pressed(sender_id: int) -> void:
	if not enabled:
		return
	super.on_pressed(sender_id)
	if is_instance_valid(_target):
		_target.scale = pressed_scale
	_is_pressed = true
	_apply_material()

func on_released(sender_id: int) -> void:
	if not enabled:
		return
	super.on_released(sender_id)
	if is_instance_valid(_target):
		_target.scale = released_scale
	_is_pressed = false
	_apply_material()

func on_clicked(sender_id: int) -> void:
	if not enabled:
		return
	super.on_clicked(sender_id)
	if cycle_on_click and cycle_textures.size() > 0:
		_cycle_index = (_cycle_index + 1) % cycle_textures.size()
		normal_texture = cycle_textures[_cycle_index]
		if cycle_pressed_textures.size() == cycle_textures.size():
			pressed_texture = cycle_pressed_textures[_cycle_index]
		_apply_material()

func _apply_material() -> void:
	if is_instance_valid(_texture_target) and _texture_target is Sprite3D:
		var sp: Sprite3D = _texture_target
		var tex: Texture2D = null
		if _is_pressed and pressed_texture:
			tex = pressed_texture
		elif normal_texture:
			tex = normal_texture
		if tex:
			sp.texture = tex
		return

	if not is_instance_valid(_material_target):
		return
	var mat: Material = null
	if _is_pressed and pressed_material:
		mat = pressed_material
	elif normal_material:
		mat = normal_material
	if mat:
		_material_target.material_override = mat
