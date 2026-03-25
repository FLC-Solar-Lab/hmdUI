
extends Node3D
class_name UITextLabel

@export var text: String = ""

func set_text(t: String) -> void:
	text = t
	# Rebuild mesh or sprite text here.
