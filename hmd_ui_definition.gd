# Data source for HMD UI layout and bindings.

extends RefCounted

class_name UIDefinitions

## Layout
const LAYOUT := {
	"panels": [
		{
			"name": "MainPanel",
			"title": "Adjust Simulation Parameters",
			"pos": Vector3(-0.6, 3.0, 0),
			"cols": 2,
			"rows": 5,
			"spacing": Vector2(0.1, -.5),
			"padding": Vector2(0.12, 0.12),
			"bg_inset": Vector2(0.0, 0.0),
			"bg_scale": Vector2(1.0, 1.0),
			"cell_padding": Vector2(0.0, 0.0),
			"items": [
				{"type": "spinner", "name": "UITimeSpinner", "label": "Time", "min": 0, "max": 1.0, "step": 0.01041666667, "value": 0.5, "auto_label": false, "hide_slider": false},
				{"type": "dropdown", "name": "UIModuleDropdown", "label": "Module", "items": ["SIL 410", "Hy 410", "QCells 405"]},
				{"type": "spinner", "name": "UIDateSpinner", "label": "Date", "min": 0, "max": 365, "step": 12, "value": 183, "auto_label": false, "hide_slider": false},
				{"type": "spinner", "name": "UITempSpinner", "label": "Temp (ºC)", "min": -30.0, "max": 50.0, "step": 1.5, "value": 25.0, "format": "%.1f", "auto_label": false, "hide_slider": false},
				{"type": "dropdown", "name": "UILocationDropdown", "label": "Location", "items": ["Durango, CO", "Los Angeles, CA", "New York, NY", "Portland, OR", "Custom"]},
				{"type": "spinner", "name": "UIWindSpinner", "label": "Wind", "min": 0.0, "max": 40.0, "step": 1.0, "value": 5.0, "format": "%.1f", "auto_label": false, "hide_slider": false},
				{"type": "spinner", "name": "UIAltSpinner", "label": "Altitude (m)", "min": 0.0, "max": 3500.0, "step": 40.0, "value": 1989, "format": "%.0f", "auto_label": false, "hide_slider": false},
				{"type": "dropdown", "name": "UIObstacleDropdown", "label": "Obstacle", "items": ["None", "Box", "Tree", "Physical"]},
				{"type": "spinner", "name": "UILatSpinner", "label": "Latitude (ºN)", "min": -90.0, "max": 90.0, "step": 1.0, "value": 37.3, "format": "%.1f", "auto_label": false, "hide_slider": false},
				{"type": "spinner", "name": "UILongSpinner", "label": "Latitude (ºE)", "min": -180.0, "max": 180.0, "step": 1.5, "value": -107.9, "format": "%.1f", "auto_label": false, "hide_slider": false},
			]
		},
	]
}

## Bindings
const BINDINGS := {
	"steppers": [
		{"panel": "MainPanel", "stepper": "UITimeSpinner", "param": "time"},
		{"panel": "MainPanel", "stepper": "UIDateSpinner", "param": "date"},
		{"panel": "MainPanel", "stepper": "UITempSpinner", "param": "temp"},
		{"panel": "MainPanel", "stepper": "UIWindSpinner", "param": "wind"},
		{"panel": "MainPanel", "stepper": "UIAltSpinner", "param": "alt"},
		{"panel": "MainPanel", "stepper": "UILatSpinner", "param": "lat"},
		{"panel": "MainPanel", "stepper": "UILongSpinner", "param": "long"},
	],
	"dropdowns": [
		{
			"panel": "MainPanel",
			"dropdown": "UILocationDropdown",
			"param": "loc",
			"options": {
				"Durango, CO": Vector3(37.274, -107.879, 1989),
				"Los Angles, CA": Vector3(33.80445,-118.01547, 15),
				"Portland, OR": Vector3(45.52025,-122.67419, 10.9),
				"NYC, NY": Vector3(40.71273,-74.00602, 13),
				"NashVille, TN": Vector3(36.16228,-86.77430, 128),
			}
		},
		{
			"panel": "MainPanel",
			"dropdown": "UIModuleDropdown",
			"param": "mod",
			"options": {
				"SIL 410": "SIL-410", 
				"Hy 410": "Hy 410", 
				"QCells 405": "QCells 405", 
				"Haitai 675": "Haitai 675",
			}
		},
		{
			"panel": "ConditionPanel",
			"dropdown": "UIObstacleDropdown",
			"param": "obs",
			"options": {
				"None": -1,
				"Box": 0,
				"Tree": 1,
			}
		},
	],
}

static func get_layout() -> Dictionary:
	# Return a deep copy so runtime edits do not touch constants.
	return LAYOUT.duplicate(true)

static func get_bindings() -> Dictionary:
	# Return a deep copy so runtime edits do not touch constants.
	return BINDINGS.duplicate(true)
