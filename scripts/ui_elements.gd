extends CanvasLayer

signal select_button_signal

@onready var frame_display = $ui_control/frame_index_display
@onready var current_layer_display = $ui_control/current_display
@onready var select_prompt = $ui_control/SelectPrompts





func _on_cut_button_pressed() -> void:
	print("cut button pressed")
	emit_signal("select_button_signal", "cut")
	print("signal sent")
func _on_copy_button_pressed() -> void:
	emit_signal("select_button_signal", "copy")
func _on_fill_button_pressed() -> void:
	emit_signal("select_button_signal", "fill")
