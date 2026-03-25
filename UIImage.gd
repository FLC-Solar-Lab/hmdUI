extends UIWidget
class_name UIImage

@export var normal_material: Material
@export var target_path: NodePath = NodePath("")

@onready var _target: Node3D = _resolve_target()

static func create_image(name: String, label_text: String, texture: Texture2D, label_z: float = 0.02) -> UIImage:
	var img = UIImage.new()
	img.name = name
	img.add_to_group("ui_component")

	var sprite = Sprite3D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.pixel_size = 0.2
	sprite.scale = Vector3(0.00125, 0.00125, 1.0)
	img.add_child(sprite)

	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.2, 0.2, 0.01)
	shape.add_to_group("no_noodles")
	img.add_child(shape)

	var label = UIWidget.make_text_mesh_label("UIDefImageLabel", label_text, 8)
	label.position = Vector3(0.0, 0.26, label_z)
	img.add_child(label)
	return img

func _resolve_target() -> Node3D:
	if target_path != NodePath(""):
		var n = get_node_or_null(target_path)
		if n and n is Node3D:
			return n
	return self
