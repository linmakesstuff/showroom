extends Control

var max_zoom = 1.5
var min_zoom = 0.1

@onready var cam = $camera

signal create_new_layer

func _on_new_folder_button_pressed() -> void:
	emit_signal("create_new_layer")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			cam.position -= event.relative
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = cam.zoom - Vector2(0.05, 0.05)
			new_zoom = new_zoom.clamp(
			Vector2(min_zoom, min_zoom),
			Vector2(max_zoom, max_zoom)
			)
			cam.zoom = new_zoom

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = cam.zoom + Vector2(0.05, 0.05)
			new_zoom = new_zoom.clamp(
			Vector2(min_zoom, min_zoom),
			Vector2(max_zoom, max_zoom)
		)
			cam.zoom = new_zoom
