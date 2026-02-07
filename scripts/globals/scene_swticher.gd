extends Node

var previous_scene = null
var new_arg = null

func switch_scenes(current, new, passed_argument):
	previous_scene = current
	new_arg = passed_argument
	get_tree().change_scene_to_packed(new)
	
