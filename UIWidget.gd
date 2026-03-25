extends StaticBody3D
class_name UIWidget

signal activated(sender_id: int)
signal value_changed(sender_id: int, value)
signal text_committed(sender_id: int, text)

@export var widget_id: String = ""
@export var enabled: bool = true
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var grid_span: Vector2i = Vector2i.ONE

static func make_text_mesh_label(name: String, text: String, font_size: int, z_scale: float = 0.05) -> MeshInstance3D:
	var label = MeshInstance3D.new()
	label.name = name
	var mesh = TextMesh.new()
	mesh.text = text
	mesh.font_size = font_size
	mesh.depth = 0.0
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	label.mesh = mesh
	label.scale = Vector3(1.0, 1.0, z_scale)
	return label

static func set_label_text(node: Node, text: String) -> void:
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

static func set_sprite_world_size(sp: Sprite3D, size: Vector2) -> void:
	if sp == null or sp.texture == null:
		return
	var base = sp.texture.get_size() * sp.pixel_size
	if base.x <= 0.0 or base.y <= 0.0:
		return
	sp.scale = Vector3(size.x / base.x, size.y / base.y, sp.scale.z)

static func sprite_world_size(sp: Sprite3D) -> Vector2:
	if sp == null or sp.texture == null:
		return Vector2.ZERO
	var base = sp.texture.get_size() * sp.pixel_size
	return Vector2(base.x * sp.scale.x, base.y * sp.scale.y)

static func text_mesh_size(label: Node) -> Vector2:
	if label and label is MeshInstance3D and label.mesh is TextMesh:
		var tm: TextMesh = label.mesh
		var aabb = tm.get_aabb()
		return Vector2(abs(aabb.size.x) * label.scale.x, abs(aabb.size.y) * label.scale.y)
	return Vector2.ZERO

func get_widget_id() -> String:
	return widget_id if widget_id != "" else name

func set_enabled(v: bool) -> void:
	enabled = v

func on_pressed(sender_id: int) -> void:
	if not enabled:
		return

func on_released(sender_id: int) -> void:
	if not enabled:
		return

func on_clicked(sender_id: int) -> void:
	if not enabled:
		return
	activated.emit(sender_id)

func on_double_clicked(sender_id: int) -> void:
	if not enabled:
		return
