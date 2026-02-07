extends Node

#All the nodes under this manager
@onready var TE = $TextEdit

var res
var data

func _ready() -> void:
	if SceneSwitcher.new_arg != null:
		res = SceneSwitcher.new_arg
		data = load(res)
	load_data(data.whole_text)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("save"):
		print("data saving!")
		save_data(TE.text)

func load_data(text):
	TE.text = ""
	for i in text:
		TE.text += i + "\n"
		
	
func save_data(text):
	var lines = text.replace("\r", "").split("\n")
	
	data.whole_text = lines
	ResourceSaver.save(data, res)
	
