extends UIWidget
class_name UIDropdown

signal selection_changed(sender_id: int, index: int, text: String)
signal selection_committed(sender_id: int, index: int, text: String)

@export var items: Array[String] = []
@export var selected_index: int = 0
@export var header_label_path: NodePath = NodePath("")
@export var items_root_path: NodePath = NodePath("")
@export var item_widget_paths: Array[NodePath] = []
@export var item_label_paths: Array[NodePath] = []
@export var close_on_select: bool = true
@export var start_open: bool = false
@export var toggle_on_click: bool = true

@onready var _items_root: Node3D = _resolve_items_root()
@onready var _header_label: Node = _resolve_label(header_label_path)
var _item_widgets: Array[UIWidget] = []

static func create_dropdown(
	name: String,
	items: Array,
	textures: Dictionary,
	sizes: Dictionary
) -> UIDropdown:
	var dd = UIDropdown.new()
	dd.name = name
	dd.add_to_group("ui_component")
	var typed_items: Array[String] = []
	for it in items:
		typed_items.append(str(it))
	dd.items = typed_items
	dd.header_label_path = NodePath("HeaderLabel")
	dd.items_root_path = NodePath("ItemsRoot")
	dd.set_meta("layout_sizes", sizes)

	var header = Sprite3D.new()
	header.name = "HeaderSprite"
	header.texture = textures["header"]
	header.pixel_size = 0.16
	var header_scale: Vector2 = sizes.get("header_scale", Vector2(5.6, 1.15))
	header.scale = Vector3(header_scale.x, header_scale.y, 1.0)
	var header_size = UIWidget.sprite_world_size(header)
	header.position = Vector3(0.0, 0.0, float(sizes.get("header_z", 0.0)))
	dd.add_child(header)

	var label = UIWidget.make_text_mesh_label("HeaderLabel", typed_items[0] if typed_items.size() > 0 else "", 8)
	var pad: Vector2 = sizes.get("bg_padding", Vector2(0.08, 0.04))
	var header_label_size = UIWidget.text_mesh_size(label)
	var header_label_x = -header_size.x * 0.5 + pad.x + header_label_size.x * 0.5
	label.position = Vector3(header_label_x, 0.0, float(sizes.get("label_z", 0.02)))
	dd.add_child(label)

	var arrow = Sprite3D.new()
	arrow.name = "Arrow"
	arrow.texture = textures["arrow"]
	arrow.pixel_size = 0.04
	var arrow_scale: Vector2 = sizes.get("arrow_scale", Vector2(0.12, 0.12))
	arrow.scale = Vector3(arrow_scale.x, arrow_scale.y, 1.0)
	var arrow_size = UIWidget.sprite_world_size(arrow)
	var arrow_x = header_size.x * 0.5 - pad.x - arrow_size.x * 0.5
	arrow.position = Vector3(arrow_x, 0.0, float(sizes.get("arrow_z", 0.02)))
	dd.add_child(arrow)

	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(header_size.x, header_size.y, 0.01)
	shape.add_to_group("no_noodles")
	dd.add_child(shape)

	var items_root = Node3D.new()
	items_root.name = "ItemsRoot"
	items_root.visible = false
	items_root.position = Vector3(0.0, -0.2, 0.02)
	dd.add_child(items_root)

	for i in range(typed_items.size()):
		var item = UIWidget.new()
		item.name = "DropdownItem%d" % i
		item.add_to_group("ui_component")
		item.position = Vector3(0.0, -0.18 * i, 0.01)

		var item_sprite = Sprite3D.new()
		item_sprite.name = "Sprite"
		item_sprite.texture = textures["item"][0]
		item_sprite.pixel_size = 0.16
		UIWidget.set_sprite_world_size(item_sprite, header_size)
		item.add_child(item_sprite)

		var item_shape = CollisionShape3D.new()
		item_shape.shape = BoxShape3D.new()
		item_shape.shape.size = Vector3(header_size.x, header_size.y, 0.01)
		item_shape.add_to_group("no_noodles")
		item.add_child(item_shape)

		var item_label = UIWidget.make_text_mesh_label("Label", typed_items[i], 8)
		var item_label_size = UIWidget.text_mesh_size(item_label)
		var item_label_x = -header_size.x * 0.5 + pad.x + item_label_size.x * 0.5
		item_label.position = Vector3(item_label_x, 0.0, float(sizes.get("label_z", 0.02)))
		item.add_child(item_label)

		items_root.add_child(item)

	apply_dropdown_item_sizing(dd, sizes)
	return dd

static func apply_dropdown_item_sizing(dropdown: UIDropdown, sizes: Dictionary) -> void:
	if not is_instance_valid(dropdown):
		return
	var header = dropdown.get_node_or_null("HeaderSprite")
	var label = dropdown.get_node_or_null("HeaderLabel")
	var arrow = dropdown.get_node_or_null("Arrow")
	var header_shape = dropdown.get_node_or_null("CollisionShape3D")
	var items_root = dropdown.get_node_or_null("ItemsRoot")
	if not (header is Sprite3D and label is MeshInstance3D and arrow is Sprite3D and header_shape is CollisionShape3D and items_root is Node3D):
		return

	var pad: Vector2 = sizes.get("bg_padding", Vector2(0.08, 0.04))
	var arrow_margin: float = float(sizes.get("arrow_margin", 0.06))
	var item_spacing: float = float(sizes.get("item_spacing", 0.02))
	var items_offset: float = float(sizes.get("items_offset", 0.06))

	var label_size = UIWidget.text_mesh_size(label)
	var arrow_size = UIWidget.sprite_world_size(arrow)
	var header_scale: Vector2 = sizes.get("header_scale", Vector2(5.6, 1.15))
	var header_base = header.texture.get_size() * header.pixel_size
	var fixed_header_size = Vector2(header_base.x * header_scale.x, header_base.y * header_scale.y)

	var item_max = Vector2.ZERO
	for c in items_root.get_children():
		if not (c is Node3D):
			continue
		var item_label = c.get_node_or_null("Label")
		if item_label and item_label is MeshInstance3D:
			var s = UIWidget.text_mesh_size(item_label)
			item_max.x = max(item_max.x, s.x)
			item_max.y = max(item_max.y, s.y)

	# Use explicit configured header size so layout is stable and predictable.
	var inner_w = max(item_max.x, label_size.x + arrow_size.x + arrow_margin * 2.0)
	var inner_h = max(item_max.y, max(label_size.y, arrow_size.y))
	var measured_size = Vector2(inner_w + pad.x * 2.0, inner_h + pad.y * 2.0)
	var base_size = Vector2(
		max(fixed_header_size.x, measured_size.x),
		max(fixed_header_size.y, measured_size.y)
	)

	UIWidget.set_sprite_world_size(header, base_size)
	if header_shape.shape is BoxShape3D:
		var box: BoxShape3D = header_shape.shape
		box.size = Vector3(base_size.x, base_size.y, box.size.z)

	# Keep arrow fixed to the right edge of the header button.
	var arrow_center_x = base_size.x * 0.5 - pad.x - arrow_size.x * 0.5
	arrow.position = Vector3(arrow_center_x, 0.0, arrow.position.z)

	# Left-align header text and keep spacing from the arrow.
	var label_half = label_size.x * 0.5
	var label_center_x = -base_size.x * 0.5 + pad.x + label_half
	var label_right = label_center_x + label_half
	var arrow_left = arrow_center_x - arrow_size.x * 0.5
	var max_label_right = arrow_left - arrow_margin
	if label_right > max_label_right:
		label_center_x -= (label_right - max_label_right)
	label.position = Vector3(label_center_x, 0.0, label.position.z)

	var item_step = base_size.y + item_spacing
	items_root.position = Vector3(0.0, -(base_size.y + items_offset), items_root.position.z)

	var idx = 0
	for c in items_root.get_children():
		if not (c is Node3D):
			continue
		c.position = Vector3(0.0, -item_step * idx, c.position.z)
		var sprite = c.get_node_or_null("Sprite")
		if sprite and sprite is Sprite3D:
			UIWidget.set_sprite_world_size(sprite, base_size)
		var item_label = c.get_node_or_null("Label")
		if item_label and item_label is MeshInstance3D:
			var item_label_size = UIWidget.text_mesh_size(item_label)
			var item_label_x = -base_size.x * 0.5 + pad.x + item_label_size.x * 0.5
			item_label.position = Vector3(item_label_x, 0.0, item_label.position.z)
		var col = c.get_node_or_null("CollisionShape3D")
		if col and col is CollisionShape3D and col.shape is BoxShape3D:
			var box: BoxShape3D = col.shape
			box.size = Vector3(base_size.x, base_size.y, box.size.z)
		idx += 1

func _ready() -> void:
	# Re-apply layout once the node enters tree to avoid first-frame text metric jitter.
	if has_meta("layout_sizes"):
		var sizes: Variant = get_meta("layout_sizes")
		if sizes is Dictionary:
			apply_dropdown_item_sizing(self, sizes)
	_apply_open_state(start_open)
	_bind_items()
	_refresh_labels()
	call_deferred("_refresh_layout_deferred")

func _refresh_layout_deferred() -> void:
	# TextMesh bounds can settle one frame late; force a final sizing pass.
	if not has_meta("layout_sizes"):
		return
	var sizes: Variant = get_meta("layout_sizes")
	if sizes is Dictionary:
		apply_dropdown_item_sizing(self, sizes)
		_apply_item_background_size_to_header()

func set_items(new_items: Array[String]) -> void:
	items = new_items
	selected_index = clamp(selected_index, 0, max(items.size() - 1, 0))
	_refresh_labels()

func set_selected_index(index: int, sender_id: int = -1, emit_signals: bool = true) -> void:
	selected_index = clamp(index, 0, max(items.size() - 1, 0))
	_refresh_labels()
	if emit_signals:
		_emit_selection(sender_id, true)

func get_selected_text() -> String:
	if selected_index >= 0 and selected_index < items.size():
		return items[selected_index]
	return ""

func on_clicked(sender_id: int) -> void:
	if not enabled:
		return
	super.on_clicked(sender_id)
	if toggle_on_click:
		_apply_open_state(not _is_open())

func _bind_items() -> void:
	_item_widgets.clear()
	var widgets = _gather_item_widgets()
	for i in range(widgets.size()):
		var w = widgets[i]
		if not is_instance_valid(w):
			continue
		_item_widgets.append(w)
		if not w.activated.is_connected(Callable(self, "_on_item_activated")):
			w.activated.connect(Callable(self, "_on_item_activated").bind(i))

func _gather_item_widgets() -> Array:
	var widgets: Array = []
	if item_widget_paths.size() > 0:
		for p in item_widget_paths:
			if p == NodePath(""):
				continue
			var n = get_node_or_null(p)
			if n and n is UIWidget:
				widgets.append(n)
		return widgets

	if is_instance_valid(_items_root):
		for c in _items_root.get_children():
			if c is UIWidget:
				widgets.append(c)
	return widgets

func _on_item_activated(sender_id: int, index: int) -> void:
	set_selected_index(index, sender_id, true)
	if close_on_select:
		_apply_open_state(false)

func _emit_selection(sender_id: int, committed: bool) -> void:
	var text = get_selected_text()
	value_changed.emit(sender_id, selected_index)
	selection_changed.emit(sender_id, selected_index, text)
	if committed:
		selection_committed.emit(sender_id, selected_index, text)

func _refresh_labels() -> void:
	if items.size() == 0:
		_set_label_text(_header_label, "")
		return
	selected_index = clamp(selected_index, 0, items.size() - 1)
	_set_label_text(_header_label, items[selected_index])
	for i in range(items.size()):
		var label = _resolve_item_label(i)
		if label:
			_set_label_text(label, items[i])
	if has_meta("layout_sizes"):
		var sizes: Variant = get_meta("layout_sizes")
		if sizes is Dictionary:
			apply_dropdown_item_sizing(self, sizes)
	# Re-apply sizing after text updates so dropdown items keep the same
	# background width/height as the main header button.
	_apply_item_background_size_to_header()

func _resolve_items_root() -> Node3D:
	if items_root_path != NodePath(""):
		var n = get_node_or_null(items_root_path)
		if n and n is Node3D:
			return n
	return null

func _resolve_label(path: NodePath) -> Node:
	if path == NodePath(""):
		return null
	return get_node_or_null(path)

func _resolve_item_label(index: int) -> Node:
	if index < item_label_paths.size() and item_label_paths[index] != NodePath(""):
		return get_node_or_null(item_label_paths[index])
	if index < _item_widgets.size():
		var w = _item_widgets[index]
		if w.has_node("Label"):
			return w.get_node("Label")
		if w.has_node("Text"):
			return w.get_node("Text")
	return null

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

func _apply_open_state(open: bool) -> void:
	if is_instance_valid(_items_root):
		_items_root.visible = open
		
		# toggle physics interactions so items cannot be pressed when menu is up
		for item in _items_root.get_children():
			if item is CollisionObject3D:
				# Disables standard mouse/ray pickability
				item.input_ray_pickable = open
				
				# Forces the physics server to disable/enable the colliders natively
				for owner_id in item.get_shape_owners():
					item.shape_owner_set_disabled(owner_id, not open)

func _is_open() -> bool:
	if is_instance_valid(_items_root):
		return _items_root.visible
	return false

func _apply_item_background_size_to_header() -> void:
	var header = get_node_or_null("HeaderSprite")
	var header_shape = get_node_or_null("CollisionShape3D")
	if not (header is Sprite3D and header_shape is CollisionShape3D and header_shape.shape is BoxShape3D):
		return
	var header_size = UIWidget.sprite_world_size(header)
	if header_size == Vector2.ZERO:
		return
	if not is_instance_valid(_items_root):
		return
	for c in _items_root.get_children():
		if not (c is Node3D):
			continue
		var sprite = c.get_node_or_null("Sprite")
		if sprite and sprite is Sprite3D:
			UIWidget.set_sprite_world_size(sprite, header_size)
		var col = c.get_node_or_null("CollisionShape3D")
		if col and col is CollisionShape3D and col.shape is BoxShape3D:
			var box: BoxShape3D = col.shape
			box.size = Vector3(header_size.x, header_size.y, box.size.z)
