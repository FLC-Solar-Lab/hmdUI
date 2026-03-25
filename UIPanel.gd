extends Node3D
class_name UIPanel

@export var panel_id: String = ""
@export var enabled: bool = true

@export var columns: int = 0
@export var rows: int = 0
@export var use_child_order: bool = true
@export var auto_size_cells: bool = true
@export var cell_size: Vector2 = Vector2(0.7, 0.35)
@export var cell_padding: Vector2 = Vector2(0.1, 0.1)
@export var cell_spacing: Vector2 = Vector2(0.1, 0.1)
@export var panel_origin: Vector2 = Vector2(0.0, 0.0)
@export var auto_layout_on_ready: bool = true
@export var panel_bg_path: NodePath = NodePath("PanelBG")
@export var panel_padding: Vector2 = Vector2(0.1, 0.1)
@export var panel_bg_inset: Vector2 = Vector2(0.0, 0.0)
@export var panel_bg_scale: Vector2 = Vector2(1.0, 1.0)
@export var ignore_group: StringName = &"no_layout"
@export var title_group: StringName = &"panel_title"
@export var title_padding: Vector2 = Vector2(0.0, 0.08)

func _ready() -> void:
	if auto_layout_on_ready:
		call_deferred("apply_grid")

func get_panel_id() -> String:
	return panel_id if panel_id != "" else name

func set_enabled(v: bool) -> void:
	enabled = v
	_set_children_enabled(v)

func apply_grid() -> void:
	var items = _get_layout_items()
	if items.is_empty():
		return

	var grid_cols = columns
	var grid_rows = rows
	if grid_cols <= 0 and grid_rows > 0:
		grid_cols = int(ceil(float(items.size()) / float(grid_rows)))
	if grid_cols <= 0:
		grid_cols = items.size()
	if grid_rows <= 0:
		grid_rows = int(ceil(float(items.size()) / float(grid_cols)))

	if auto_size_cells:
		cell_size = _compute_cell_size(items)

	for i in range(items.size()):
		var c = items[i]
		var col = i % grid_cols
		var row = i / grid_cols
		var p = Vector2i(col, row)
		if c is UIWidget:
			c.grid_pos = p
			_place_widget(c)
		elif c is UIStepper:
			c.grid_pos = p
			_place_stepper(c)
		elif c is Node3D:
			var pos = _grid_to_pos(p)
			c.position = Vector3(pos.x, pos.y, c.position.z)

	_update_panel_bg(items)

func _get_layout_items() -> Array:
	var items: Array = []
	for c in get_children():
		if panel_bg_path != NodePath("") and str(c.name) == str(panel_bg_path):
			continue
		if c.is_in_group(title_group):
			continue
		if c.is_in_group(ignore_group):
			continue
		if c is UIWidget or c is UIStepper or c is Node3D:
			items.append(c)
	return items

func _compute_cell_size(items: Array) -> Vector2:
	var max_w = 0.0
	var max_h = 0.0
	for c in items:
		var size = _measure_node_size(c)
		max_w = max(max_w, size.x)
		max_h = max(max_h, size.y)
	max_w += cell_padding.x * 2.0
	max_h += cell_padding.y * 2.0
	return Vector2(max_w, max_h)

func _place_widget(w: UIWidget) -> void:
	var p = _grid_to_pos(w.grid_pos)
	w.position = Vector3(p.x, p.y, w.position.z)

func _place_stepper(s: UIStepper) -> void:
	var p = _grid_to_pos(s.grid_pos)
	s.position = Vector3(p.x, p.y, s.position.z)

func _grid_to_pos(p: Vector2i) -> Vector2:
	return Vector2(
		panel_origin.x + float(p.x) * (cell_size.x + cell_spacing.x),
		panel_origin.y - float(p.y) * (cell_size.y + cell_spacing.y)
	)

func _update_panel_bg(items: Array) -> void:
	if items.is_empty():
		return
	var bg = get_node_or_null(panel_bg_path)
	if bg == null or not (bg is Sprite3D):
		return
	var content_bounds = _measure_items_bounds_in_panel(self, items)
	if content_bounds.size == Vector2.ZERO:
		content_bounds = _fallback_bounds_from_positions(items)

	var bounds = content_bounds
	var titles = _get_title_nodes()
	if not titles.is_empty():
		var title = titles[0]
		_position_title(title, content_bounds)
		var title_bounds = _measure_item_bounds_in_panel(self, title)
		bounds = _union_rect(bounds, title_bounds)

	if bounds.size == Vector2.ZERO:
		return
	var width = bounds.size.x + panel_padding.x * 2.0
	var height = bounds.size.y + panel_padding.y * 2.0
	if panel_bg_inset != Vector2.ZERO:
		width = max(width - panel_bg_inset.x * 2.0, 0.0)
		height = max(height - panel_bg_inset.y * 2.0, 0.0)
	if panel_bg_scale != Vector2.ONE:
		width = max(width * panel_bg_scale.x, 0.0)
		height = max(height * panel_bg_scale.y, 0.0)
	var sp: Sprite3D = bg
	var center = bounds.position + bounds.size * 0.5
	sp.position = Vector3(center.x, center.y, sp.position.z)
	var tex = sp.texture
	if tex == null:
		sp.scale = Vector3(width, height, sp.scale.z)
		return
	var base = tex.get_size() * sp.pixel_size
	if base.x <= 0.0 or base.y <= 0.0:
		return
	sp.scale = Vector3(width / base.x, height / base.y, sp.scale.z)

func _measure_node_size(node: Node3D) -> Vector2:
	var bounds = _measure_node_bounds(node)
	return bounds.size

func _measure_node_bounds(node: Node3D) -> Rect2:
	var has_bounds = false
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	var renderables: Array = _gather_renderables(node)
	for r in renderables:
		var aabb = _get_renderable_aabb(r)
		if aabb.size == Vector3.ZERO:
			continue
		var corners = _aabb_corners(aabb)
		for corner in corners:
			var world = r.global_transform * corner
			var local = node.to_local(world)
			min_v = min_v.min(local)
			max_v = max_v.max(local)
			has_bounds = true
	if not has_bounds:
		return Rect2()
	var size = max_v - min_v
	return Rect2(Vector2(min_v.x, min_v.y), Vector2(abs(size.x), abs(size.y)))

func _measure_items_bounds_in_panel(panel: Node3D, items: Array) -> Rect2:
	var has_bounds = false
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	for c in items:
		if not (c is Node3D):
			continue
		var renderables: Array = _gather_renderables(c)
		for r in renderables:
			var aabb = _get_renderable_aabb(r)
			if aabb.size == Vector3.ZERO:
				continue
			var corners = _aabb_corners(aabb)
			for corner in corners:
				var world = r.global_transform * corner
				var local = panel.to_local(world)
				min_v = min_v.min(local)
				max_v = max_v.max(local)
				has_bounds = true
	if not has_bounds:
		return Rect2()
	var size = max_v - min_v
	return Rect2(Vector2(min_v.x, min_v.y), Vector2(abs(size.x), abs(size.y)))

func _get_title_nodes() -> Array:
	var list: Array = []
	for c in get_children():
		if c is Node3D and c.is_in_group(title_group):
			list.append(c)
	return list

func _position_title(title: Node3D, content_bounds: Rect2) -> void:
	if not is_instance_valid(title):
		return
	var local_bounds = _measure_node_bounds(title)
	if local_bounds.size == Vector2.ZERO:
		return
	var content_center_x = content_bounds.position.x + content_bounds.size.x * 0.5
	var content_top = content_bounds.position.y + content_bounds.size.y
	var target_center = Vector2(content_center_x, content_top + title_padding.y + local_bounds.size.y * 0.5)
	var local_center = local_bounds.position + local_bounds.size * 0.5
	var offset = target_center - local_center
	title.position = Vector3(offset.x, offset.y, title.position.z)

func _union_rect(a: Rect2, b: Rect2) -> Rect2:
	if a.size == Vector2.ZERO:
		return b
	if b.size == Vector2.ZERO:
		return a
	var min_x = min(a.position.x, b.position.x)
	var min_y = min(a.position.y, b.position.y)
	var max_x = max(a.position.x + a.size.x, b.position.x + b.size.x)
	var max_y = max(a.position.y + a.size.y, b.position.y + b.size.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _measure_item_bounds_in_panel(panel: Node3D, item: Node3D) -> Rect2:
	var has_bounds = false
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	var renderables: Array = _gather_renderables(item)
	for r in renderables:
		var aabb = _get_renderable_aabb(r)
		if aabb.size == Vector3.ZERO:
			continue
		var corners = _aabb_corners(aabb)
		for corner in corners:
			var world = r.global_transform * corner
			var local = panel.to_local(world)
			min_v = min_v.min(local)
			max_v = max_v.max(local)
			has_bounds = true
	if not has_bounds:
		return Rect2()
	var size = max_v - min_v
	return Rect2(Vector2(min_v.x, min_v.y), Vector2(abs(size.x), abs(size.y)))

func _fallback_bounds_from_positions(items: Array) -> Rect2:
	var min_p = Vector2(INF, INF)
	var max_p = Vector2(-INF, -INF)
	var has_positions = false
	for c in items:
		if not (c is Node3D):
			continue
		var p = Vector2(c.position.x, c.position.y)
		min_p = min_p.min(p)
		max_p = max_p.max(p)
		has_positions = true
	if not has_positions:
		return Rect2()
	var half = cell_size * 0.5
	var pos = min_p - half
	var size = (max_p - min_p) + cell_size
	return Rect2(pos, size)

func debug_get_layout_info() -> Dictionary:
	var items = _get_layout_items()
	var bounds = _measure_items_bounds_in_panel(self, items)
	if bounds.size == Vector2.ZERO:
		bounds = _fallback_bounds_from_positions(items)
	var bg = get_node_or_null(panel_bg_path)
	var bg_center = Vector2.ZERO
	var bg_size = Vector2.ZERO
	if bg and bg is Sprite3D:
		var sp: Sprite3D = bg
		bg_center = Vector2(sp.position.x, sp.position.y)
		if sp.texture:
			var base = sp.texture.get_size() * sp.pixel_size
			bg_size = Vector2(base.x * sp.scale.x, base.y * sp.scale.y)
	var item_infos: Array = []
	for c in items:
		if not (c is Node3D):
			continue
		var item_bounds = _measure_item_bounds_in_panel(self, c)
		item_infos.append({
			"name": c.name,
			"class": c.get_class(),
			"pos": Vector2(c.position.x, c.position.y),
			"bounds": item_bounds
		})
	return {
		"panel_bounds": bounds,
		"bg_center": bg_center,
		"bg_size": bg_size,
		"items": item_infos
	}

func _gather_renderables(root: Node) -> Array:
	var list: Array = []
	if root is MeshInstance3D or root is Sprite3D:
		list.append(root)
	for c in root.get_children():
		list.append_array(_gather_renderables(c))
	return list

func _get_renderable_aabb(node: Node) -> AABB:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		if mi.mesh:
			return mi.mesh.get_aabb()
	elif node is Sprite3D:
		var sp: Sprite3D = node
		if sp.texture:
			var tex_size = sp.texture.get_size()
			var w = tex_size.x * sp.pixel_size
			var h = tex_size.y * sp.pixel_size
			return AABB(Vector3(-w * 0.5, -h * 0.5, 0.0), Vector3(w, h, 0.0))
	return AABB()

func _aabb_corners(aabb: AABB) -> Array:
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
		Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
	]

func _set_children_enabled(v: bool) -> void:
	for w in get_children():
		if w is UIWidget:
			w.set_enabled(v)
