extends SubViewport


@onready var _panel_back = $UIRoot/MarginMain


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var win_size = _panel_back.size
	self.size = win_size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
