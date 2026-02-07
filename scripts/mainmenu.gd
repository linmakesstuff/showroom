extends Control

#Node References
@onready var projectbox = $projectbox
@onready var NPP = $"New Project Prompt"
@onready var NPPText = $"New Project Prompt/NewProjectText"

#Scene References
@export var project_menu: PackedScene

var showroom_projects_folder = "user://showroom_projects"

func _ready() -> void:
	#see if a file called Showroom exists, if not then create one
	if !DirAccess.dir_exists_absolute(showroom_projects_folder):
		DirAccess.make_dir_recursive_absolute(showroom_projects_folder)
	else:
		var dir = DirAccess.open(showroom_projects_folder)
		if dir == null:
			return
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				create_button(folder_name)
			folder_name = dir.get_next()
		
		dir.list_dir_end()

func _on_create_button_pressed() -> void:
	NPP.visible = true

func _on_ok_button_pressed() -> void:
	if NPPText.text.strip_edges() != "":
		save_new_project(NPPText.text)

func on_project_button_pressed(folder):
	var current = get_tree().current_scene.scene_file_path
	SceneSwitcher.switch_scenes(current, project_menu, folder)

func create_button(folder_name):
	var new_button = Button.new()
	new_button.text = folder_name
	
	var folder_path = showroom_projects_folder + "/" + folder_name
	
	new_button.pressed.connect(func(): on_project_button_pressed(folder_path))
	projectbox.add_child(new_button)

func save_new_project(folder_name):
	var new_folder = "user://showroom_projects/%s" % folder_name.to_lower()
	DirAccess.make_dir_recursive_absolute(new_folder)
	
	#Make all the subfolders
	DirAccess.make_dir_recursive_absolute(new_folder + "/" + "notes")
	DirAccess.make_dir_recursive_absolute(new_folder + "/" + "storyboards")
	DirAccess.make_dir_recursive_absolute(new_folder + "/" + "designs")
	
	NPP.visible = false
	#Add the button
	create_button(folder_name)
