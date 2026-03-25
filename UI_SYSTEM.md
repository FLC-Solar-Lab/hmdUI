# UI System

**Files**
- `GodotServer/flc_root.tscn` scene entry.
- `GodotServer/hmd_ui.gd` runtime UI construction, layout data, and bindings.
- `GodotServer/UIPanel.gd` grid layout and background sizing for panels.
- `GodotServer/UIRoot.gd` input router between `SpatialResolver` and `InteractionModel`.
- `GodotServer/InteractionModel.gd` press/release/click state tracking.
- `GodotServer/SpatialResolver.gd` raycasts to identify hovered widgets.
- `GodotServer/UIWidget.gd` base class for UI widgets and signals.
- `GodotServer/UIButton.gd`, `UISlider.gd`, `UIStepper.gd`, `UIDropdown.gd`, `UIImage.gd` core components.
- `GodotServer/buttons.gd` legacy direct interaction path.

**Runtime Flow**
1. `UIRoot.gd` receives pose updates and requests hover from `SpatialResolver.gd`.
2. `InteractionModel.gd` converts press/release into widget events.
3. Widgets emit signals consumed by bindings in `hmd_ui.gd`.

**UI Layout Definition**
- `hmd_ui.gd` builds `UIDefinition` at runtime.
- `UI_LAYOUT` defines panels, grid, spacing, padding, and item list.
- Each `items` entry uses `type` and `name`. Optional fields include `label`, `cols`, `rows`, `items`.
- `UIPanel.gd` computes panel bounds from child render sizes and sizes the background.

**Bindings**
- `UI["bindings"]` in `hmd_ui.gd` wires sliders, buttons, dropdowns.
- `UISlider` emits `value_changed` and `value_committed`.
- `UIDropdown` emits `selection_committed`.
- `UIWidget` emits `activated`.

**Time-Of-Day Slider**
- Slider A emits `time_of_day_changed` with a normalized value in `hmd_ui.gd`.
- `flc_root.gd` handles `_on_ui_time_of_day_changed()` and updates `_sim_config.date_time`, then calls `SimLink.compute_sun_position`.

**Add Or Modify Components**
1. Add the item to `UI_LAYOUT` in `hmd_ui.gd`.
2. If it needs input, add a binding in `UI["bindings"]` in `hmd_ui.gd`.
3. If it needs simulation behavior, connect in `flc_root.gd`.

**Notes**
- `UIRoot.enable_hover = false` disables hover state for HMD interactions.
- `buttons.gd` can overlap `UIRoot` input if both are active.
