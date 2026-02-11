extends Control

#Scene References
@export var note_writing_manager: PackedScene
#Storyboard Manager
#Design Manager

#Node References
@onready var file_holder = $FileHolder
@onready var EANText = $"Enter A Name Prompt/EANText"
@onready var NFP = $"New File Prompt"
@onready var EANP = $"Enter A Name Prompt"

var current_folder
var type_array = ["notes", "storyboards", "designs"]
var selected_type

func _ready() -> void:
	if SceneSwitcher.new_arg != null:
		current_folder = SceneSwitcher.new_arg
		load_data()

func create_button(type, folder_name):
	var new_button = Button.new()
	var button_name = folder_name.get_basename()
	new_button.text = button_name
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var folder_path = current_folder + "/" + type + "/" + folder_name
	
	new_button.pressed.connect(func(): on_project_button_pressed(folder_path))
	
	file_holder.add_child(new_button)

func load_data():
	var index = 0
	while index <= 2:
		var dir = DirAccess.open(current_folder + "/" + type_array[index])
		if dir == null:
			index += 1
			
			continue
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if not folder_name.begins_with("."):
				create_button(type_array[index], folder_name)
			folder_name = dir.get_next()
		dir.list_dir_end()
		index += 1
	
func save_data(res_name):
	var path_to_data
	match selected_type:
		"notes":
			var data = text_res.new()
			data.whole_text = [" "]
			data.file_name = res_name
			data.type = "notes"
			ResourceSaver.save(data, current_folder + "/" + selected_type + "/" + res_name + ".tres")
			path_to_data = res_name + ".tres"
		"storyboards":
			var data = sbres.new()
			data.file_name = res_name
			data.size
			data.type = "storyboards"
		"designs":
			pass
	create_button(selected_type, path_to_data)

func _on_createbutton_pressed() -> void:
	NFP.visible = true

func _on_notes_button_pressed() -> void:
	selected_type = "notes"
	NFP.visible = false
	EANP.visible = true

func _on_sb_button_pressed() -> void:
	selected_type = "storyboards"
	NFP.visible = false
	EANP.visible = true

func _on_design_button_pressed() -> void:
	selected_type = "designs"
	NFP.visible = false
	EANP.visible = true

func _on_ean_button_pressed() -> void:
	if EANText.text != "":
		var text = EANText.text
		save_data(text)
		EANP.visible = false

func on_project_button_pressed(path):
	print(path)
	var current = get_tree().current_scene.scene_file_path
	var scene_to_load
	
	if path.contains("/notes/"):
		scene_to_load = note_writing_manager
	elif path.contains("/storyboards/"):
		pass
	elif path.contains("/designs/"):
		pass
		
	SceneSwitcher.switch_scenes(current, scene_to_load, path)
	print("project button pressed")
