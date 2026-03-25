# hmdUI Setup and Integration Guide

This guide covers how to set up, configure, and integrate the `hmdUI` submodule into your Godot mixed-reality simulation.

---

## 1. Configure the UI Definitions (`ui_definitions.gd`)

The framework relies on a configuration script to build the interface dynamically. Instead of manually placing nodes, you define the layout and data bindings in a single script.

Because standard 2D Control nodes don't always play nicely in mixed reality (and standard Labels are off-limits for this project in favor of `MeshInstance3D` text), this dictionary approach allows the `hmdUI` system to generate the correct 3D meshes and interactables automatically.

Create a `hmd_ui_definitions.gd` script in your project root (`res://`) and point `hmd_ui.gd` to it if you change its location. It requires two main dictionaries and two functions: `LAYOUT` and `BINDINGS`; `get_layout()` and `get_bindings()`. 

### The `LAYOUT` Dictionary
This defines the visual structure of your panels and the input items (spinners, dropdowns, etc.) they contain.

```gdscript
const LAYOUT := {
	"panels": [
		{
			"name": "MainPanel",
			"title": "Adjust Simulation Parameters",
			"pos": Vector3(-0.6, 3.0, 0),
			"cols": 2,
			"items": [
				# A spinner for adjusting a numerical value
				{"type": "spinner", "name": "UITempSpinner", "label": "Temp (ºC)", "min": -30.0, "max": 50.0, "step": 1.5, "value": 25.0},
				# A dropdown for selecting from a list
				{"type": "dropdown", "name": "UIObstacleDropdown", "label": "Obstacle", "items": ["None", "Box", "Tree"]}
			]
		}
	]
}
```

### The `BINDINGS` Dictionary
This maps the visual UI elements defined above to internal parameter string names. When a user interacts with the UI, it broadcasts this parameter name so your main simulation logic knows what changed.

```gdscript
const BINDINGS := {
	"steppers": [
		# Links the UITempSpinner to the internal parameter "temp"
		{"panel": "MainPanel", "stepper": "UITempSpinner", "param": "temp"},
	],
	"dropdowns": [
		# Links the UIObstacleDropdown to the parameter "obs", and maps the UI strings to backend values
		{
			"panel": "MainPanel",
			"dropdown": "UIObstacleDropdown",
			"param": "obs",
			"options": { "None": -1, "Box": 0, "Tree": 1 }
		}
	]
}
```

### Functions
Append these two functions to the end of the script:

```gdscript
static func get_layout() -> Dictionary:
	# Return a deep copy so runtime edits do not touch constants.
	return LAYOUT.duplicate(true)

static func get_bindings() -> Dictionary:
	# Return a deep copy so runtime edits do not touch constants.
	return BINDINGS.duplicate(true)
```

---

## 2. Set Up the Scene Structure and Connect Signals

### Step A:
To ensure the UI renders and interacts correctly, drag the `ui_root.tscn` scene below your `NoodlesRoot` node. The scene
should appear in in the following structure:

* `UIRoot`
    * `SpacialResolver`
    * `InteractionModel`
    * `hmdUI` 

(make sure scripts are attached to **all** nodes)

Once built, select `UIRoot` and `hmdUI` and configure any exported variables in the Inspector (if necessary).

### Step B:
#### Connect the `position_updated` and `position_set` signals
When an HMD client presses a bumper, NOODLES will emit one of two different signals. 
```gdscript
# when a bumper is pressed
signal position_updated(pos: Vector3, dir: Vector3, sender_id: int)
```
```gdscript
# when a bumper is released
signal position_set(sender_id)
```

Locate the node containing the `position_updated` signal (node usually 
labeled as `PositionUpdated` or `BumperIsPressed`). In the `Node` section on the right side of the editor,
connect that signal to the `UIRoot` node. Repeate the same process for the `position_set` signal.

---

## 3. Connecting UI Actions to Your Simulation

When a user interacts with the `hmdUI`, it emits a `parameter_changed` signal. You may connect and handle this signal how ever
you prefer, but below is a recommended approach.

To handle this cleanly without a massive `match` statement, we will map the UI parameters to specific functions using an Action Dictionary.

This is ceanest if done in a sperate manager script (e.g., `UserInteractions.gd`) to handle these connections.

### Step A: Initialize the Bindings and Actions
In your `_ready()` function, connect the signal and define which function should run for each parameter.

```gdscript
@onready var _hmd_ui = $"../NoodlesRoot/UIRoot/hmdUI"

var _UI_ACTIONS: Dictionary
var _UI_BINDINGS = UIDefinitions.get_bindings()  # this was defined in step 1

func _ready():
	# 1. Connect the core signal from the UI
	_hmd_ui.parameter_changed.connect(_on_ui_parameter_updated)
	
	# 2. Map the parameter strings (from UIDefinitions in step 1) to specific functions
	_UI_ACTIONS = {
		"temp": _on_temp_changed,
		"obs":  _on_obstacle_changed,
		"loc":  _determine_loc_type
	}
```

### Step B: Create the Router Function
This function catches the signal and dynamically calls the correct method from your dictionary.

```gdscript
func _on_ui_parameter_updated(param: String, value: Variant):
	"""Called every time a UI element is pressed, diverting the action to the associated method."""
	var action = _UI_ACTIONS.get(param, null)
	
	if action == null:
		printerr("Parameter %s does not exist in _UI_ACTIONS." % param)
		return
	
	# Call the mapped function, handling both 1-argument and 2-argument functions
	if action.get_argument_count() == 1:
		action.call(value)
	else:
		action.call(param, value)
```

### Step C: Define the Action Methods
Write the specific functions that execute your simulation logic when the UI changes.

```gdscript
func _on_temp_changed(temp: int):
	# Example: Update the simulation config and trigger a debounce timer
	_sim_config.ambient_temp = temp
	debounce_timer.start()

func _on_obstacle_changed(obs_index: int):
	# Example: Enable/disable physical obstacles in the scene
	obstacle_root.set_obstacle(obs_index)
```

---
