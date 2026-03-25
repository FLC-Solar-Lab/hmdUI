extends Node3D
class_name UIRoot

@export var spatial_resolver_path: NodePath = NodePath("")
@export var interaction_model_path: NodePath = NodePath("")
@export var debug_log: bool = true
@export var enable_hover: bool = false
@export var enable_legacy_world_buttons: bool = true

var _resolver: SpatialResolver
var _interaction: InteractionModel
var _action_map: Dictionary = {}  # widget_id -> Callable
var _legacy_pressed: Dictionary = {}  # sender_id -> String button name

func _ready() -> void:
	_resolve_refs()
	if not is_instance_valid(_resolver) or not is_instance_valid(_interaction):
		call_deferred("_resolve_refs")

func _resolve_refs() -> void:
	if is_instance_valid(_resolver) and is_instance_valid(_interaction):
		return

	_resolver = _get_node_typed(spatial_resolver_path, "SpatialResolver")
	_interaction = _get_node_typed(interaction_model_path, "InteractionModel")

	if not is_instance_valid(_resolver):
		var r = get_node_or_null("SpatialResolver")
		if _matches_type(r, "SpatialResolver"):
			_resolver = r

	if not is_instance_valid(_interaction):
		var i = get_node_or_null("InteractionModel")
		if _matches_type(i, "InteractionModel"):
			_interaction = i

	if not is_instance_valid(_resolver) or not is_instance_valid(_interaction):
		if debug_log:
			print_debug("UIRoot missing SpatialResolver or InteractionModel reference.")
		return

	if not _interaction.widget_pressed.is_connected(_on_widget_pressed):
		_interaction.widget_pressed.connect(_on_widget_pressed)
	if not _interaction.widget_released.is_connected(_on_widget_released):
		_interaction.widget_released.connect(_on_widget_released)
	if not _interaction.widget_clicked.is_connected(_on_widget_clicked):
		_interaction.widget_clicked.connect(_on_widget_clicked)
	if not _interaction.widget_double_clicked.is_connected(_on_widget_double_clicked):
		_interaction.widget_double_clicked.connect(_on_widget_double_clicked)

func bind_action(widget_id: String, action: Callable) -> void:
	_action_map[widget_id] = action

func unbind_action(widget_id: String) -> void:
	_action_map.erase(widget_id)

# Input: position + direction (press hold)
func on_position_updated(pos: Vector3, dir: Vector3, sender_id: int) -> void:
	if not is_instance_valid(_resolver) or not is_instance_valid(_interaction):
		if debug_log:
			print_debug("UIRoot press ignored: resolver/interaction missing")
		return
	if debug_log:
		print_debug("UIRoot press event sender=", sender_id)

	var state = _interaction.get_state(sender_id)
	if not enable_hover:
		if state.get("is_pressing", false):
			# Keep sampling while held until we capture a legacy world button hit.
			if enable_legacy_world_buttons and not _legacy_pressed.has(sender_id):
				_resolver.raycast_widget(sender_id, pos, dir)
				_capture_legacy_button_press(sender_id)
			return

	var hovered = _resolver.raycast_widget(sender_id, pos, dir)
	var was_pressing = state.get("is_pressing", false)
	if enable_legacy_world_buttons and not was_pressing:
		_capture_legacy_button_press(sender_id)
	if enable_hover and debug_log and hovered:
		print_debug("UI hover: ", hovered.get_widget_id(), " sender=", sender_id)

	_interaction.on_press_hold(sender_id, hovered)
	if enable_hover:
		_apply_slider_drag(sender_id, hovered)

# Input: release
func on_position_set(sender_id: int) -> void:
	if not is_instance_valid(_resolver) or not is_instance_valid(_interaction):
		if debug_log:
			print_debug("UIRoot release ignored: resolver/interaction missing")
		return
	if debug_log:
		print_debug("UIRoot release event sender=", sender_id)

	var hovered: UIWidget = null
	if enable_hover:
		hovered = _resolver.raycast_widget(sender_id, Vector3.ZERO, Vector3.ZERO)
	else:
		var state = _interaction.get_state(sender_id)
		hovered = state.get("pressed_widget", null)
	if enable_hover and debug_log and hovered:
		print_debug("UI release: ", hovered.get_widget_id(), " sender=", sender_id)
	_interaction.on_release(sender_id, hovered)
	_emit_legacy_button_press(sender_id)

func _apply_slider_drag(sender_id: int, hovered: UIWidget) -> void:
	if not is_instance_valid(hovered):
		return
	if not (hovered is UISlider):
		return
	var hit = _resolver.get_last_hit(sender_id)
	if hit.has("point"):
		var s: UISlider = hovered
		s.update_from_hit(hit["point"], sender_id)

func _on_widget_pressed(sender_id: int, widget: UIWidget) -> void:
	if not is_instance_valid(widget):
		return
	widget.on_pressed(sender_id)

func _on_widget_released(sender_id: int, widget: UIWidget) -> void:
	if not is_instance_valid(widget):
		return
	widget.on_released(sender_id)

func _on_widget_clicked(sender_id: int, widget: UIWidget) -> void:
	if not is_instance_valid(widget):
		return

	widget.on_clicked(sender_id)
	if debug_log:
		print_debug("UI widget clicked: ", widget.get_widget_id(), " sender: ", sender_id)

	var id = widget.get_widget_id()
	if _action_map.has(id):
		var cb: Callable = _action_map[id]
		if cb.is_valid():
			cb.call(sender_id)

func _on_widget_double_clicked(sender_id: int, widget: UIWidget) -> void:
	if not is_instance_valid(widget):
		return
	widget.on_double_clicked(sender_id)

func _capture_legacy_button_press(sender_id: int) -> void:
	var hit = _resolver.get_last_hit(sender_id)
	if not hit.has("collider"):
		_legacy_pressed.erase(sender_id)
		return

	var collider = hit["collider"]
	if collider is Node and collider.is_in_group("Buttons"):
		var button_name: String = str(collider.name)
		_legacy_pressed[sender_id] = button_name
		if debug_log:
			print_debug("Legacy world button captured: ", button_name, " sender=", sender_id)
		# Emit immediately on press so legacy world buttons (string
		# selectors, plot toggle, etc.) do not depend on a separate
		# position_set/ release signal path, which can be flaky in
		# some HMD setups.
		_interaction.button_pressed.emit(button_name)
	else:
		_legacy_pressed.erase(sender_id)

func _emit_legacy_button_press(sender_id: int) -> void:
	if not enable_legacy_world_buttons:
		return
	if not _legacy_pressed.has(sender_id):
		return

	var button_name: String = str(_legacy_pressed[sender_id])
	_legacy_pressed.erase(sender_id)
	if debug_log:
		print_debug("Legacy world button pressed (release): ", button_name, " sender=", sender_id)

func _get_node_typed(path: NodePath, expected_class: String) -> Object:
	if path == NodePath(""):
		return null
	var n = get_node_or_null(path)
	if n == null:
		return null
	if _matches_type(n, expected_class):
		return n
	# Prefer availability over strict typing; caller path is explicit.
	return n

func _matches_type(n: Object, expected_class: String) -> bool:
	if n == null:
		return false
	if n.is_class(expected_class):
		return true
	var s = n.get_script()
	if s is Script and s.get_global_name() == expected_class:
		return true
	return false
