extends UIWidget
class_name UISpinner

@export var target_path: NodePath = NodePath("")
@export var spin_axis: Vector3 = Vector3.UP
@export var spin_speed_deg: float = 180.0
@export var spinning: bool = true
@export var pause_on_disable: bool = true

@onready var _target: Node3D = _resolve_target()

func _process(delta: float) -> void:
	if not spinning:
		return
	if pause_on_disable and not enabled:
		return
	if not is_instance_valid(_target):
		return
	if spin_axis.length() == 0.0:
		return
	var rads = deg_to_rad(spin_speed_deg) * delta
	_target.rotate(spin_axis.normalized(), rads)

func set_spinning(v: bool) -> void:
	spinning = v

func _resolve_target() -> Node3D:
	if target_path != NodePath(""):
		var n = get_node_or_null(target_path)
		if n and n is Node3D:
			return n
	return self
