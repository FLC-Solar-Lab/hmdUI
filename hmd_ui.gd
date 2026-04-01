# Runtime HMD UI: build from definition data and emit parameter updates.

extends Node3D

# SIGNALS EMITTED
signal parameter_changed(param: String, value: Variant)
signal change_string_plot(int)
signal string_plot_selected(index: int)


var button_actions: Dictionary = {}
var _ui_root: Node3D
var _panel_registry: Dictionary = {}
var _widget_registry: Dictionary = {}
@export var ui_scale: float = 1.0
var _string_status_label: Node

const UI_ROOT_NODE_NAME := "UIDefinition"
const DEFAULT_UI_DEFINITION_PATH := "res://hmd_ui_definition.gd"
const DEFAULT_UI_DEFINITION: Script = preload("res://hmd_ui_definition.gd")

@export_file("*.gd") var ui_definition_path: String = DEFAULT_UI_DEFINITION_PATH
var _ui_layout: Dictionary = {}
var _ui_bindings: Dictionary = {}

const COMPONENT_SIZES = {
	"panel_bg_z": -0.015,
	"slider": {
		"bar_scale": Vector2(2.2, 0.28),
		"bar_z": 0.0,
		"handle_scale": Vector2(0.35, 0.55),
		"handle_z": 0.008,
		"label_z": 0.008
	},
	"button": {
		"label_z": 0.008
	},
	"dropdown": {
		"header_scale": Vector2(5.6, 1.15),
		"header_z": 0.0,
		"arrow_scale": Vector2(0.12, 0.12),
		"arrow_z": 0.008,
		"label_z": 0.008,
		"bg_padding": Vector2(0.08, 0.04),
		"arrow_margin": 0.06,
		"item_spacing": 0.02,
		"items_offset": 0.06
	},
	"grid": {
		"cell": 0.22,
		"spacing": 0.05,
		"z": 0.0
	}
}

## Textures
const TEX_PANEL 				:= preload("res://hmdUI/assets/ui_panel_dark.png")
const TEX_BTN_STYLE1 			:= preload("res://hmdUI/assets/ui_btn_c1.png")
const TEX_BTN_STYLE1_PRESSED 	:= preload("res://hmdUI/assets/ui_btn_c1_p.png")
const TEX_BTN_STYLE2 			:= preload("res://hmdUI/assets/ui_btn_c2.png")
const TEX_BTN_STYLE2_PRESSED 	:= preload("res://hmdUI/assets/ui_btn_c2_p.png")
const TEX_BTN_STYLE3 			:= preload("res://hmdUI/assets/ui_btn_c3.png")
const TEX_BTN_STYLE3_PRESSED 	:= preload("res://hmdUI/assets/ui_btn_c3_p.png")
const TEX_BTN_STYLE4 			:= preload("res://hmdUI/assets/ui_btn_c4.png")
const TEX_BTN_STYLE4_PRESSED 	:= preload("res://hmdUI/assets/ui_btn_c4_p.png")
const TEX_SLIDER_BAR 	:= preload("res://hmdUI/assets/ui_slider_bar.png")
const TEX_SLIDER_LOW 	:= preload("res://hmdUI/assets/ui_slider_low.png")
const TEX_SLIDER_MID 	:= preload("res://hmdUI/assets/ui_slider_mid.png")
const TEX_SLIDER_HIGH 	:= preload("res://hmdUI/assets/ui_slider_high.png")
#const TEX_IMAGE 		:= preload("res://hmdUI/assets/cat_image.jpg")
const TEX_DD_ARROW 		:= preload("res://hmdUI/assets/dropdown_arrow_icon.png")

const PANEL_TITLE_FONT_SIZE := 9

## Lifecycle
func _ready() -> void:
	_connect_button_source()
	call_deferred("_connect_button_source")
	_configure_button_actions()
	rebuild_ui()

func _connect_button_source() -> void:
	var controls = get_node_or_null("../../SpatialUIRoot/InteractionModel")
	if controls and controls.has_signal("button_pressed"):
		var on_button_pressed = Callable(self, "handle_button_press")
		if not controls.is_connected("button_pressed", on_button_pressed):
			controls.connect("button_pressed", on_button_pressed)

func rebuild_ui() -> void:
	_load_ui_definition()
	_build_ui()
	_bind_from_layout(_ui_bindings)
	_update_string_status_label(0)

func _load_ui_definition() -> void:
	var default_data: Dictionary = _read_ui_definition(DEFAULT_UI_DEFINITION)
	var definition_script: Script = load(ui_definition_path) as Script
	var definition_data: Dictionary = {}

	if definition_script == null:
		push_warning(
			"HMD UI definition file not found at %s. Falling back to %s."
			% [ui_definition_path, DEFAULT_UI_DEFINITION_PATH]
		)
		definition_data = default_data
	else:
		definition_data = _read_ui_definition(definition_script)

	var layout_data: Dictionary = definition_data.get("layout", {})
	if not layout_data.has("panels"):
		if definition_script != null:
			push_warning(
				"HMD UI definition file at %s is missing layout panels. Using default layout."
				% ui_definition_path
			)
		layout_data = default_data.get("layout", {"panels": []})

	var bindings_data: Dictionary = definition_data.get("bindings", {})
	if bindings_data.is_empty():
		if definition_script != null:
			push_warning(
				"HMD UI definition file at %s has empty bindings. Using default bindings."
				% ui_definition_path
			)
		bindings_data = default_data.get("bindings", {})

	_ui_layout = layout_data
	_ui_bindings = bindings_data

func _read_ui_definition(definition_script: Script) -> Dictionary:
	var result := {"layout": {}, "bindings": {}}
	if definition_script == null:
		return result

	var definition = definition_script.new()
	if definition == null:
		return result

	if definition.has_method("get_layout"):
		var layout_value: Variant = definition.call("get_layout")
		if layout_value is Dictionary:
			result["layout"] = (layout_value as Dictionary).duplicate(true)
	if definition.has_method("get_bindings"):
		var bindings_value: Variant = definition.call("get_bindings")
		if bindings_value is Dictionary:
			result["bindings"] = (bindings_value as Dictionary).duplicate(true)
	return result

func _configure_button_actions() -> void:
	button_actions.clear()
	button_actions["Plot3StaticBody"] = Callable(self, "next_string_plot")
	for i in range(6):
		button_actions["Str%dButton" % i] = Callable(self, "go_to_str_plot").bind(i)

## Build
func _build_ui() -> void:
	var existing = get_node_or_null(UI_ROOT_NODE_NAME)
	if existing:
		existing.queue_free()

	_panel_registry.clear()
	_widget_registry.clear()

	_ui_root = Node3D.new()
	_ui_root.name = UI_ROOT_NODE_NAME
	_ui_root.scale = Vector3.ONE * max(ui_scale, 0.001)
	add_child(_ui_root)

	var panels: Array = _ui_layout.get("panels", [])
	for panel_def_var in panels:
		if not (panel_def_var is Dictionary):
			continue
		var panel_def: Dictionary = panel_def_var
		var panel = _make_panel(panel_def)
		_ui_root.add_child(panel)
		_register_panel(panel)
		var items: Array = panel_def.get("items", [])
		for item_def_var in items:
			if not (item_def_var is Dictionary):
				continue
			var item_def: Dictionary = item_def_var
			var node = _build_item(item_def)
			if node:
				panel.add_child(node)
				_register_widget(panel.name, node)
		panel.apply_grid()

func _register_panel(panel: UIPanel) -> void:
	var panel_name := str(panel.name)
	_panel_registry[panel_name] = panel
	_widget_registry[panel_name] = {}

func _register_widget(panel_name: String, node: Node) -> void:
	if panel_name == "" or node == null:
		return
	var panel_widgets: Dictionary = _widget_registry.get(panel_name, {})
	panel_widgets[str(node.name)] = node
	_widget_registry[panel_name] = panel_widgets

func _make_panel(def: Dictionary) -> UIPanel:
	var panel = UIPanel.new()
	panel.name = def.get("name", "Panel")
	panel.position = def.get("pos", Vector3.ZERO)
	panel.rotation_degrees = def.get("rot_deg", Vector3.ZERO)
	panel.columns = def.get("cols", 1)
	panel.rows = def.get("rows", 0)
	panel.auto_layout_on_ready = false
	panel.auto_size_cells = true
	panel.cell_spacing = def.get("spacing", Vector2(0.12, 0.12))
	panel.panel_padding = def.get("padding", Vector2(0.18, 0.18))
	panel.panel_bg_inset = def.get("bg_inset", Vector2(0.0, 0.0))
	panel.panel_bg_scale = def.get("bg_scale", Vector2(1.0, 1.0))
	panel.cell_padding = def.get("cell_padding", Vector2(0.0, 0.0))
	panel.title_padding = def.get("title_padding", Vector2(0.0, 0.08))

	var title_text = def.get("title", "")
	if title_text != "":
		var title = _make_panel_title(title_text)
		panel.add_child(title)

	var bg = Sprite3D.new()
	bg.name = "PanelBG"
	bg.texture = TEX_PANEL
	bg.centered = true
	bg.pixel_size = 0.01
	bg.position = Vector3(0.0, 0.0, COMPONENT_SIZES["panel_bg_z"])
	panel.add_child(bg)
	return panel

func _make_panel_title(text: String) -> MeshInstance3D:
	var title = UIWidget.make_text_mesh_label("PanelTitle", text, PANEL_TITLE_FONT_SIZE)
	title.add_to_group("panel_title")
	title.position = Vector3(0.0, 0.0, COMPONENT_SIZES["panel_bg_z"] + 0.03)
	return title

func _build_item(def: Dictionary) -> Node3D:
	var t = def.get("type", "")
	match t:
		"spinner":
			return _make_stepper(def)
		"dropdown":
			return _make_dropdown(def.get("name", "Dropdown"), def.get("items", []), def.get("label", ""))
		"slider":
			return _make_slider(def.get("name", "Slider"), def.get("label", ""))
		"stepper":
			return _make_stepper(def)
		"button":
			var tex_key = def.get("tex", "c1")
			var pair = _button_textures(tex_key)
			return _make_button(def.get("name", "Button"), def.get("label", ""), pair[0], pair[1])
		#"image":
			#return _make_image(def.get("name", "Image"), def.get("label", ""))
		"grid":
			return _make_ui_grid(def.get("name", "Grid"), def.get("cols", 4), def.get("rows", 4))
		"label":
			return _make_status_label(def.get("name", "Label"), def.get("label", ""))
		"spacer":
			return _make_spacer(def.get("name", "Spacer"))
		_:
			return null

func _button_textures(key: String) -> Array:
	match key:
		"secondary":
			return [TEX_BTN_STYLE3, TEX_BTN_STYLE3_PRESSED]
		"primary":
			return [TEX_BTN_STYLE1, TEX_BTN_STYLE1_PRESSED]
		_:
			# Fallback: treat unknown styles as primary.
			return [TEX_BTN_STYLE1, TEX_BTN_STYLE1_PRESSED]

func _make_dropdown(name: String, items: Array, label_text: String = "") -> Node3D:
	var dropdown_textures = {
		"header": TEX_BTN_STYLE2,
		"arrow": TEX_DD_ARROW,
		"item": [TEX_BTN_STYLE4, TEX_BTN_STYLE4_PRESSED]
	}
	var dd = UIDropdown.create_dropdown(name, items, dropdown_textures, COMPONENT_SIZES["dropdown"])
	if label_text != "":
		var top_label = UIWidget.make_text_mesh_label("TopLabel", label_text, 8)
		top_label.position = Vector3(0.0, 0.17, float(COMPONENT_SIZES["dropdown"].get("label_z", 0.02)))
		dd.add_child(top_label)
	return dd

func _make_slider(name: String, label_text: String) -> UISlider:
	var slider_textures = {
		"bar": TEX_SLIDER_BAR,
		"low": TEX_SLIDER_LOW,
		"mid": TEX_SLIDER_MID,
		"high": TEX_SLIDER_HIGH
	}
	return UISlider.create_slider(
		name,
		label_text,
		slider_textures["bar"],
		slider_textures["low"],
		slider_textures["mid"],
		slider_textures["high"],
		COMPONENT_SIZES["slider"],
		float(COMPONENT_SIZES["slider"]["label_z"])
	)

func _make_stepper(def: Dictionary) -> UIStepper:
	var slider_textures = {
		"bar": TEX_SLIDER_BAR,
		"low": TEX_SLIDER_LOW,
		"mid": TEX_SLIDER_MID,
		"high": TEX_SLIDER_HIGH
	}
	var button_textures = {
		"primary": [TEX_BTN_STYLE1, TEX_BTN_STYLE1_PRESSED],
		"secondary": [TEX_BTN_STYLE3, TEX_BTN_STYLE3_PRESSED],
	}
	return UIStepper.create_from_def(def, slider_textures, button_textures, COMPONENT_SIZES)

func _make_button(name: String, label_text: String, tex: Texture2D, tex_pressed: Texture2D) -> UIWidget:
	return UIButton.create_button(name, label_text, tex, tex_pressed, float(COMPONENT_SIZES["button"]["label_z"]))

#func _make_image(name: String, label_text: String) -> UIWidget:
	#return UIImage.create_image(name, label_text, TEX_IMAGE, float(COMPONENT_SIZES["button"]["label_z"]))

func _make_status_label(name: String, label_text: String) -> UIWidget:
	var label_node = UIWidget.new()
	label_node.name = name
	label_node.enabled = false

	var sprite = Sprite3D.new()
	sprite.name = "Sprite"
	sprite.texture = TEX_BTN_STYLE3
	sprite.pixel_size = 0.18
	label_node.add_child(sprite)

	var label = UIWidget.make_text_mesh_label("TextLabel", label_text, 8)
	label.position = Vector3(0.0, 0.0, COMPONENT_SIZES["button"]["label_z"])
	label_node.add_child(label)

	return label_node

func _make_spacer(name: String) -> Node3D:
	var spacer = Node3D.new()
	spacer.name = name
	return spacer

func _make_ui_grid(name: String, cols: int, rows: int) -> Node3D:
	var grid = Node3D.new()
	grid.name = name
	grid.add_to_group("ui_component")
	var cell = COMPONENT_SIZES["grid"]["cell"]
	var spacing = COMPONENT_SIZES["grid"]["spacing"]
	for y in range(rows):
		for x in range(cols):
			var cell_btn = _make_button("UIGrid_%d_%d" % [x, y], "", TEX_BTN_STYLE1, TEX_BTN_STYLE1_PRESSED)
			cell_btn.texture_target_path = NodePath("Sprite")
			cell_btn.cycle_on_click = true
			var cycle_tex: Array[Texture2D] = [TEX_BTN_STYLE1, TEX_BTN_STYLE2, TEX_BTN_STYLE3, TEX_BTN_STYLE4]
			var cycle_tex_p: Array[Texture2D] = [TEX_BTN_STYLE1_PRESSED, TEX_BTN_STYLE2_PRESSED, TEX_BTN_STYLE3_PRESSED, TEX_BTN_STYLE4_PRESSED]
			cell_btn.cycle_textures = cycle_tex
			cell_btn.cycle_pressed_textures = cycle_tex_p
			cell_btn.get_node("TextLabel").visible = false
			cell_btn.position = Vector3(
				(x - (cols - 1) * 0.5) * (cell + spacing),
				(rows - 1) * 0.5 * (cell + spacing) - y * (cell + spacing),
				COMPONENT_SIZES["grid"]["z"]
			)
			grid.add_child(cell_btn)
	return grid

## Bindings
func _bind_from_layout(bindings: Dictionary) -> void:
	for slider_config in bindings.get("sliders", []):
		var panel_name = str(slider_config.get("panel", ""))
		var slider_name = str(slider_config.get("slider", ""))
		var slider = _get_widget(panel_name, slider_name)
		var label_node = _resolve_slider_label_node(panel_name, slider, str(slider_config.get("label", "")))
		var param = str(slider_config.get("param", ""))
		var is_time = bool(slider_config.get("is_time", false))
		if not is_time:
			is_time = (param == "time") or slider_name == "UIDefSliderA"
		if param == "":
			param = "time" if is_time else slider_name
		_bind_slider(slider, label_node, is_time, param)
	for stepper in bindings.get("steppers", []):
		var panel_name = str(stepper.get("panel", ""))
		var stepper_name = str(stepper.get("stepper", ""))
		var param = str(stepper.get("param", ""))
		_bind_stepper(_get_widget(panel_name, stepper_name), param)
	for button in bindings.get("buttons", []):
		var panel_name = str(button.get("panel", ""))
		var button_name = str(button.get("button", ""))
		var param = str(button.get("param", ""))
		var value: Variant = button.get("value", button_name)
		_bind_text_button(_get_widget(panel_name, button_name), param, value)
	for dropdown in bindings.get("dropdowns", []):
		var panel_name = str(dropdown.get("panel", ""))
		var dropdown_name = str(dropdown.get("dropdown", ""))
		var param = str(dropdown.get("param", ""))
		var option_values: Dictionary = dropdown.get("options", {})
		_bind_dropdown(_get_widget(panel_name, dropdown_name), param, option_values)

func _get_widget(panel_name: String, widget_name: String) -> Node:
	if widget_name == "":
		return null
	if panel_name != "":
		var panel_widgets: Dictionary = _widget_registry.get(panel_name, {})
		if panel_widgets.has(widget_name):
			return panel_widgets[widget_name]
		var panel = _panel_registry.get(panel_name, null)
		if panel and panel is Node:
			var in_panel = panel.find_child(widget_name, true, false)
			if in_panel:
				return in_panel
	if is_instance_valid(_ui_root):
		var in_root = _ui_root.find_child(widget_name, true, false)
		if in_root:
			return in_root
	return _find_node_from_hint("", widget_name)

func _find_node_from_hint(panel_name: String, hint: String) -> Node:
	if hint == "":
		return null
	var from_path = get_node_or_null(NodePath(hint))
	if from_path:
		return from_path
	var rooted = UI_ROOT_NODE_NAME + "/" + hint
	var rooted_node = get_node_or_null(NodePath(rooted))
	if rooted_node:
		return rooted_node
	if panel_name != "":
		var panel = _panel_registry.get(panel_name, null)
		if panel and panel is Node:
			var in_panel = panel.find_child(hint, true, false)
			if in_panel:
				return in_panel
	if is_instance_valid(_ui_root):
		return _ui_root.find_child(hint, true, false)
	return null

func _resolve_slider_label_node(panel_name: String, slider_node: Node, label_hint: String) -> Node:
	if label_hint != "":
		return _find_node_from_hint(panel_name, label_hint)
	if slider_node == null:
		return null
	var direct = slider_node.get_node_or_null("Label")
	if direct:
		return direct
	return slider_node.get_node_or_null(str(slider_node.name) + "Label")

func _bind_slider(slider_node: Node, label_node: Node, is_time: bool, param: String) -> void:
	if slider_node == null or not (slider_node is UISlider):
		return
	var slider: UISlider = slider_node
	var on_slider_update = func(_sender_id: int, value: float) -> void:
		if is_time:
			UIWidget.set_label_text(label_node, UIStepper.format_time_label(value))
		else:
			UIWidget.set_label_text(label_node, "Slider: %.2f" % value)
		_emit_parameter_change(param, value)
	slider.value_changed.connect(on_slider_update)
	slider.value_committed.connect(on_slider_update)
	if is_time:
		UIWidget.set_label_text(label_node, UIStepper.format_time_label(slider.value))
	else:
		UIWidget.set_label_text(label_node, "Slider: %.2f" % slider.value)

func _bind_stepper(stepper_node: Node, param: String) -> void:
	if stepper_node == null or not (stepper_node is UIStepper):
		return
	var stepper: UIStepper = stepper_node
	stepper.bind_param(param, func(value: Variant) -> void:
		_emit_parameter_change(param, value)
	)

func _bind_text_button(button_node: Node, param: String, value: Variant) -> void:
	if button_node == null or not (button_node is UIWidget):
		return
	var btn: UIWidget = button_node
	if param == "":
		return
	# Use the generic UIWidget activated signal so buttons defined in the
	# layout can drive parameter changes (e.g. string mapping selectors).
	var cb := func(_sender_id: int) -> void:
		print_debug("HMD-UI button activated param=", param, " value=", value)
		_emit_parameter_change(param, value)
		if param == "string_select":
			_update_string_status_label(int(value))
	btn.activated.connect(cb)

func _update_string_status_label(active_index: int) -> void:
	if not is_instance_valid(_ui_root):
		return
	if not is_instance_valid(_string_status_label):
		_string_status_label = _ui_root.find_child("UIStringStatusLabel", true, false)
	if not is_instance_valid(_string_status_label):
		return
	var label_node = _string_status_label.get_node_or_null("TextLabel")
	if label_node == null:
		return
	var text = "Building String %d" % [active_index + 1]
	UIWidget.set_label_text(label_node, text)

func _bind_dropdown(dropdown_node: Node, param: String, option_values: Dictionary) -> void:
	if dropdown_node and dropdown_node is UIDropdown:
		var dropdown: UIDropdown = dropdown_node
		dropdown.selection_committed.connect(func(_sender_id: int, index: int, text: String) -> void:
			if param != "":
				var value: Variant = option_values.get(text, index)
				_emit_parameter_change(param, value)
		)

func _emit_parameter_change(param: String, value: Variant) -> void:
	parameter_changed.emit(param, value)

## Button Actions
func handle_button_press(button_pressed: String) -> void:
	print_debug("HMD-UI received button_pressed: ", button_pressed)
	if not button_actions.has(button_pressed):
		# Ignore button IDs that are not legacy world buttons (e.g. UI-only
		# widgets like UIStringButton1, UIStringResetButton). Those are
		# handled via the HMD-UI parameter bindings instead.
		return
	button_actions[button_pressed].call()

func toggle_menu() -> void:
	if self.visible:
		self.visible = false
	elif not self.visible:
		self.visible = true

func next_string_plot() -> void:
	change_string_plot.emit(1)

func previous_string_plot() -> void:
	change_string_plot.emit(-1)

func go_to_str_plot(i) -> void:
	string_plot_selected.emit(int(i))
