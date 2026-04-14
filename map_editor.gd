extends Node3D

@export var UIPanel: ColorRect
@export var Cursor: DecalCompatibility
@export var BrushSelection: Label
@export var PlacerSelection: Label
@export var BrushSize: float
@export var BrushStr: float
@export var BrushSelectionLabel: Label
@export var BrushDescriptionLabel: Label

@export var MouseInUI: bool

func _on_ui_close_pressed() -> void:
	UIPanel.hide()

func _on_ui_expand_pressed() -> void:
	UIPanel.show()

func _on_size_slider_value_changed(value: float) -> void:
	BrushSize = value
	
func _on_str_slider_value_changed(value: float) -> void:
	BrushStr = value
	
func is_point_in_sphere(point: Vector3, sphere_center: Vector3, radius: float) -> bool:
	return sphere_center.distance_to(point) < radius

func _on_gaus_button_pressed() -> void:
	Cursor.BrushMode = Cursor.BRUSH_MODE.Gaus
	BrushSelectionLabel.text = "GAUSSIAN"
	BrushDescriptionLabel.text = "Click and hold the left mouse to raise and right mouse to lower terrain."
	BrushSelection.show()
	PlacerSelection.hide()
	Cursor._switch_cursors(false)

func _on_cyl_button_pressed() -> void:
	Cursor.BrushMode = Cursor.BRUSH_MODE.Flatten
	BrushSelectionLabel.text = "FLATTEN"
	BrushDescriptionLabel.text = "Right click to select a height, then click and hold left mouse to flatten to that height."
	BrushSelection.show()
	PlacerSelection.hide()
	Cursor._switch_cursors(false)

func _on_place_button_pressed() -> void:
	Cursor.BrushMode = Cursor.BRUSH_MODE.Place
	BrushSelection.hide()
	PlacerSelection.show()
	Cursor._switch_cursors(true)
	pass # Replace with function body.
