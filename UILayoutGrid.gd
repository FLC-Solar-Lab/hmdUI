extends Node3D
class_name UILayoutGrid

@export var columns: int = 3
@export var padding: Vector2 = Vector2(0.06, 0.06)
@export var spacing: Vector2 = Vector2(0.1, 0.1)
@export var include_groups: Array[String] = ["ui_component"]
@export var auto_layout_on_ready: bool = true

func _ready() -> void:
	if auto_layout_on_ready:
		call_deferred("relayout")

func relayout() -> void:
	var items = _collect_items()
	if items.is_empty():
		return
	var max_size = _compute_max_item_size(items)
	var cols = max(columns, 1)
	var rows = int(ceil(float(items.size()) / float(cols)))
	var cell_w = max_size.x + spacing.x
	var cell_h = max_size.y + spacing.y
	var grid_w = cell_w * cols - spacing.x
	var grid_h = cell_h * rows - spacing.y
	var origin_x = -grid_w * 0.5 + cell_w * 0.5
	var origin_y = grid_h * 0.5 - cell_h * 0.5

	for i in range(items.size()):
		var r = int(i / cols)
		var c = int(i % cols)
		var x = origin_x + c * cell_w
		var y = origin_y - r * cell_h
		var n: Node3D = items[i]
		var p = n.position
		n.position = Vector3(x, y, p.z)

func _collect_items() -> Array[Node3D]:
	var items: Array[Node3D] = []
	for g in include_groups:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D and _is_descendant_of(n, self):
				items.append(n)
	items.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		if a.get_parent() == b.get_parent():
			return a.get_index() < b.get_index()
		return str(a.get_path()) < str(b.get_path())
	)
	return items

func _is_descendant_of(n: Node, root: Node) -> bool:
	var p = n
	while p != null:
		if p == root:
			return true
		p = p.get_parent()
	return false

func _compute_max_item_size(items: Array[Node3D]) -> Vector2:
	var max_w = 0.0
	var max_h = 0.0
	for n in items:
		var aabb = _compute_bounds(n)
		var size = Vector2(aabb.size.x, aabb.size.y) + padding * 2.0
		max_w = max(max_w, size.x)
		max_h = max(max_h, size.y)
	return Vector2(max_w, max_h)

func _compute_bounds(root: Node3D) -> AABB:
	var inv = global_transform.affine_inverse()
	var has_any = false
	var min_v = Vector3.ZERO
	var max_v = Vector3.ZERO

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is Node3D:
			var n3 = n as Node3D
			if n is GeometryInstance3D:
				var gi = n as GeometryInstance3D
				var aabb = gi.get_aabb()
				_unpack_aabb(inv, n3.global_transform, aabb)
				if not has_any:
					min_v = _tmp_min
					max_v = _tmp_max
					has_any = true
				else:
					min_v = min_v.min(_tmp_min)
					max_v = max_v.max(_tmp_max)
			elif n is CollisionShape3D:
				var cs = n as CollisionShape3D
				if cs.shape and cs.shape.has_method("get_aabb"):
					var saabb = cs.shape.get_aabb()
					_unpack_aabb(inv, n3.global_transform, saabb)
					if not has_any:
						min_v = _tmp_min
						max_v = _tmp_max
						has_any = true
					else:
						min_v = min_v.min(_tmp_min)
						max_v = max_v.max(_tmp_max)

			for c in n.get_children():
				stack.append(c)

	if not has_any:
		return AABB(Vector3.ZERO, Vector3(0.2, 0.2, 0.0))

	return AABB(min_v, max_v - min_v)

var _tmp_min: Vector3
var _tmp_max: Vector3

func _unpack_aabb(inv: Transform3D, t: Transform3D, aabb: AABB) -> void:
	var corners = _aabb_corners(aabb)
	var p0 = inv * (t * corners[0])
	var min_v = p0
	var max_v = p0
	for i in range(1, corners.size()):
		var p = inv * (t * corners[i])
		min_v = min_v.min(p)
		max_v = max_v.max(p)
	_tmp_min = min_v
	_tmp_max = max_v

func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p = aabb.position
	var s = aabb.size
	return [
		Vector3(p.x, p.y, p.z),
		Vector3(p.x + s.x, p.y, p.z),
		Vector3(p.x, p.y + s.y, p.z),
		Vector3(p.x, p.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z),
		Vector3(p.x + s.x, p.y, p.z + s.z),
		Vector3(p.x, p.y + s.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z + s.z)
	]
