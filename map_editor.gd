extends Node3D

@export var UIPanel: ColorRect
@export var Brush: DecalCompatibility
@export var BrushSize: float

func _on_ui_close_pressed() -> void:
	UIPanel.hide()

func _on_ui_expand_pressed() -> void:
	UIPanel.show()

func _on_size_slider_value_changed(value: float) -> void:
	BrushSize = value
	Brush.size = Vector3(value,value,value)
	
