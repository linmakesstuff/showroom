extends Control

#SIGNALS
signal create_new_layer

#ONREADY VARIABLES
@onready var cam = $camera
@onready var canvas = $canvas
@onready var selection_canvas = $canvas_holder/selection_sprite
@onready var canvas_holder = $canvas_holder
@onready var ui_elements = $ui_elements
@onready var layer_holder = $ui_elements/ui_control/PanelContainer/MarginContainer/layer_holder

#SCENE SETTINGS
var height
var width  

var max_zoom = 1.5
var min_zoom = 0.1

var bg_sprite = Sprite2D

var action_history = []

#TOOL VARIABLES
enum tools {
	BRUSH,
	ERASER,
	SELECT,
	FILL}
enum select_state {
	IDLE,
	DRAWING,
	FLOATING
}
var dirty = false
var current_tool
var current_bs = 3
var current_es = 5
var current_color := Color.BLACK
var is_drawing: bool = false

#FRAME AND LAYER VARIABLES
var all_frames := []
var frame_index = 0
var current_layer

#STROKE VARIABLES
var current_select
var current_stroke
var last_point = null

#SELECTION VARIABLES
var selection_img: Image
var selection_position: Vector2i
var selection_tex
var selection_status
var select_path: Array = []

var copy_img
var copy_pos

#INITALIZATION

func _ready() -> void:
	selection_canvas.z_index = 100
	selection_canvas.centered = false
	if SceneSwitcher.new_arg != null:
		var data = load(SceneSwitcher.new_arg)
		load_data(data)

func load_data(data):
	current_tool = tools.BRUSH
	if data.frames.is_empty():
		width = data.size.x
		height = data.size.y
		
		var f = frame.new()
		all_frames.append(f)
		frame_index = 0
		ui_elements.frame_display.text = str(frame_index + 1)
		
		#Create Background Texture and Images
		bg_sprite = Sprite2D.new()
		bg_sprite.centered = false
		var texture = ImageTexture.new()
		var image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		texture.set_image(image)
		bg_sprite.texture = texture
		canvas_holder.add_child(bg_sprite)
		
		create_layer()

	else:
		pass

func save_data():
	pass

func save_stroke(new_stroke):
	current_layer.undos.append(new_stroke)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			cam.position -= event.relative

		#DRAWING AND SELECT LOGIC
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if is_drawing:
				#Clear Redos
				if current_layer:
					if current_layer.redos.size() > 0:
						current_layer.redos.clear()
					
				var mouse_pos = get_global_mouse_position()
				var lpos = canvas.to_local(mouse_pos)
				
				if lpos.x >= 0 and lpos.y >= 0 and lpos.x < width and lpos.y < height:
					if last_point == null:
						last_point = lpos
				
					var distance = last_point.distance_to(lpos)
					var step = 1.0  # 1 unit per step; can scale with brush size
					var steps = int(ceil(distance / step))
					
					for i in range(steps):
						var t = float(i) / steps
						var interp = last_point.lerp(lpos, t)
						
						#Find tool type
						if current_tool == tools.BRUSH:
							current_stroke.path.append(interp)
							canvas.paint_canvas(interp, current_color, current_bs)
						if current_tool == tools.SELECT:
							select_path.append(interp)
							selection_canvas.get_outline(select_path)
						if current_tool == tools.ERASER:
							current_stroke.path.append(interp)
							canvas.paint_canvas(interp, Color.TRANSPARENT, current_es)
					last_point = lpos

		if Input.is_action_pressed("space"):
			selection_canvas.position += event.relative

	#MOUSE BUTTON LOGIC
	
	if event is InputEventMouseButton:
		
		#ZOOM CAMERA FUNCTIONS
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
		
		if event.is_action_pressed("left_click"):
			if !is_drawing and current_tool == tools.BRUSH:
				select_path.clear()
				is_drawing = true
				
				current_stroke = stroke.new()
				current_stroke.brush_size = current_bs
				current_stroke.color = current_color
			if !is_drawing and current_tool == tools.SELECT:
				if selection_status == select_state.DRAWING:
					_on_ui_elements_select_button_signal("release")
				is_drawing = true
				var data = select.new()

		if event.is_action_released("left_click"):
			is_drawing = false
			last_point = null
			if current_stroke != null and current_stroke.path.size() > 0:
				action_history.append(current_stroke)
				save_stroke(current_stroke.path)
			if current_tool == tools.SELECT and select_path.size() > 0:
				select_path.append(select_path[0])
				create_select(select_path)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		print("yeah you pressed undo")
		undo_action()

	if event.is_action_pressed("change_brush_temp"):
		current_tool = tools.SELECT

#UNDO REDO ACTIONS

func undo_action():
	var type = typeof(action_history[-1])
	if type:
		print(type)
	else:
		print("typeof sucks")
	

func redo_action():
	match current_tool:
		tools.BRUSH:
			pass
		tools.ERASER:
			pass
		tools.SELECT:
			pass
		tools.FILL:
			pass

#CREATION

func create_frame():
	var data = frame.new()
	all_frames.append(data)
	frame_index = all_frames.size() - 1
	load_frame(frame_index)
	create_layer()

func create_button(data):
	var new_button = Button.new()
	new_button.text = data.name
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	new_button.pressed.connect(func(): on_layer_button_pressed(data))
	
	layer_holder.add_child(new_button)

func create_select(path):
	print("create select started")
	var minx = path[0].x
	var maxx = path[0].x
	var miny = path[0].y
	var maxy = path[0].y
	
	for p in path:
		minx = min(minx, p.x)
		maxx = max(maxx, p.x)
		miny = min(miny, p.y)
		maxy = max(maxy, p.y)
	var bounds = Rect2(
		Vector2i(minx, miny),
		Vector2i(maxx - minx + 1, maxy - miny + 1))

	var src_img = canvas.current_layer.image
	#Not sure if this will be needed in the long run
	
	selection_canvas.create_new_selection(bounds.size.x, bounds.size.y)
	
	for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
		for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
			var point = Vector2(x, y)
			
			if Geometry2D.is_point_in_polygon(point, path):
				var color = src_img.get_pixel(x, y)
				if color.a > 0:
					selection_canvas.image.set_pixel(x - bounds.position.x, y - bounds.position.y, color)
	
	selection_canvas.update_visual()
	
	var local_outline: Array = []
	for p in select_path:
		local_outline.append(p - bounds.position)
	selection_canvas.get_outline(local_outline)
	
	selection_img = selection_canvas.image
	selection_tex = selection_canvas.tex
	selection_position = Vector2i(bounds.position)
	is_selecting = true
	selection_canvas.position = selection_position
	
	for point in select_path:
		canvas.current_layer.image.set_pixel(point.x, point.y, Color.TRANSPARENT)
	
	ui_elements.select_prompt.visible = true

func create_layer():
	var current_frame = all_frames[frame_index]
	var index = current_frame.layers.size() + 1
	var layer_name = "layer_%s" % index


	var data = layers.new()
	data.texture = ImageTexture.new()
	data.image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	data.vis = true
	data.opacity = 100.0
	data.name = layer_name
	data.undos = []
	data.redos = []
	data.texture.set_image(data.image)
	
	var sprite = Sprite2D.new()
	sprite.texture = data.texture
	sprite.centered = false
	data.sprite = sprite
	canvas_holder.add_child(sprite)
	
	current_frame.layers.append(data)
	
	current_layer = data
	canvas.set_current(current_layer)
	ui_elements.current_layer_display.text = "Current: %s" % data.name
	
	create_button(data)

#CHANGE STATES

func load_frame(index):
	frame_index = index
	
	for child in canvas_holder.get_children():
		canvas_holder.remove_child(child)
		
	for child in layer_holder.get_children():
		child.queue_free()
		
	var f = all_frames[index]
	for layer in f.layers:
		canvas_holder.add_child(layer.sprite)
		create_button(layer)
	
	if f.layers.size() > 0:
		change_layer(f.layers[0])
	
	ui_elements.frame_display.text = str(frame_index + 1)

func change_layer(data):
	current_layer = data
	ui_elements.current_layer_display.text = "Current: %s" % data.name
	canvas.set_current(current_layer)

#BUTTON SIGNALS

func on_layer_button_pressed(data):
	change_layer(data)

func _on_forward_frame_button_pressed() -> void:
	if frame_index < all_frames.size() - 1:
		load_frame(frame_index + 1)
	else:
		create_frame()

func _on_backward_frame_button_pressed() -> void:
	if frame_index > 0:
		load_frame(frame_index - 1)

func _on_new_folder_button_pressed() -> void:
	create_layer()

func _on_ui_elements_select_button_signal(type) -> void:
	match type:
		"copy":
			#Whatever is in the selected area, duplicate it, set first selection down, bring second selection in
			pass
		"cut":
			#whatever is in the area obliterate
			pass
		"fill":
			#whatever is in the area flood
			pass
		"release":
			#this is just putting whatever is selected where it is at
			is_drawing = false
			is_selecting = false
			
			var re_commit = canvas.current_layer.image
			for x in range(selection_img.get_width()):
				for y in range(selection_img.get_height()):
					var color = selection_img.get_pixel(x, y)
					if color.a > 0:
						re_commit.set_pixelv(
							selection_position + Vector2i(x,y), color
						)
			canvas.current_layer.texture.set_image(canvas.current_layer.image)

			is_drawing = false
			is_selecting = false
			current_tool = tools.BRUSH
			select_path.clear()
			selection_canvas.get_outline([])
			selection_tex = null
			selection_img = null

#Classes
class layers:
	var index: int
	var texture: ImageTexture
	var image: Image
	var vis: bool
	var opacity: float
	var name: String
	var undos: Array
	var redos: Array
	var sprite: Sprite2D
class stroke:
	var path: PackedVector2Array
	var color: Color
	var brush_size: float
	func _init():
		path = PackedVector2Array()
class frame:
	var layers: Array = []
class select:
	var select_path: Array = []
class bucker_fill:
	var color: Color

#Camera and action input. > Self
#Drawing and Visual rep > In the canvas sprite2d
#Ui Rep > Canvas Layer
#hub for classes, and large data sets > Self
#Creation > Self
