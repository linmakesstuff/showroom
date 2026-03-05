extends Control

#SIGNALS

#ONREADY VARIABLES
@onready var cam = $camera
@onready var canvas = $canvas
@onready var selection_canvas = $canvas_holder/selection_sprite
@onready var canvas_holder = $canvas_holder
@onready var ui_elements = $ui_elements
@onready var layer_holder = $ui_elements/ui_control/PanelContainer/MarginContainer/layer_holder

#SCENE SETTINGS
var height: int 
var width : int

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
var selection_position: Vector2i
var selection_tex
var selection_status = select_state.IDLE
var select_path: Array = []
var selection_moved: bool = false
var selection_mask: Image


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
	if get_viewport().gui_get_hovered_control() != null:
		return  # Mouse is over UI, ignore canvas input
	
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
						if current_tool == tools.SELECT and selection_status == select_state.DRAWING:
							select_path.append(interp)
							selection_canvas.get_outline(select_path)
						if current_tool == tools.ERASER:
							current_stroke.path.append(interp)
							canvas.paint_canvas(interp, Color.TRANSPARENT, current_es)
					last_point = lpos

		if current_tool == tools.SELECT and selection_status == select_state.FLOATING:
			print("selection is right")
			if Input.is_action_pressed("space"):
				print("space pressed")
				selection_canvas.position += event.relative
				selection_position = Vector2i(selection_canvas.position)
				selection_moved = true

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
	
	
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if !is_drawing and current_tool == tools.BRUSH:
					select_path.clear()
					is_drawing = true
							
					current_stroke = stroke.new()
					current_stroke.brush_size = current_bs
					current_stroke.color = current_color

				if current_tool == tools.FILL:
					var pos = canvas.to_local(get_global_mouse_position())
					paint_bucket_fill(pos)

				if current_tool == tools.SELECT:
					match selection_status:
						select_state.IDLE:
							select_path.clear()
							is_drawing = true
							selection_status = select_state.DRAWING
						select_state.FLOATING:
							commit_selection()

		if event.is_action_released("left_click"):
			is_drawing = false
			last_point = null
			if current_stroke != null and current_stroke.path.size() > 0:
				action_history.append(current_stroke)
				save_stroke(current_stroke.path)
			if current_tool == tools.SELECT and selection_status == select_state.DRAWING and select_path.size() > 0:
				select_path.append(select_path[0])
				create_select(select_path)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		print("yeah you pressed undo")
		undo_action()

	if event.is_action_pressed("change_brush_temp"):
		current_tool = tools.SELECT
	#if event.is_action_pressed("ui_accept"):
		#current_tool = tools.FILL

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
	#Getting boundaries of selection
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

	#Grabbing pixels within the boundaries
	var src_img = canvas.current_layer.image
	selection_mask = Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	selection_mask.fill(Color(0,0,0,0)) # start fully unselected
	
	selection_canvas.create_new_selection(bounds.size.x, bounds.size.y)

	for x in range(int(bounds.position.x), int(bounds.position.x + bounds.size.x)):
		for y in range(int(bounds.position.y), int(bounds.position.y + bounds.size.y)):

			var point = Vector2(x, y)
			var local_x = x - int(bounds.position.x)
			var local_y = y - int(bounds.position.y)

			if Geometry2D.is_point_in_polygon(point, path):
				
				var color = src_img.get_pixel(point.x, point.y)
				if color.a > 0:
					selection_canvas.image.set_pixel(local_x, local_y, color)
					canvas.current_layer.image.set_pixel(x, y, Color.TRANSPARENT)
				selection_mask.set_pixel(local_x, local_y, Color(1,1,1,1))
		
	
	#for x in range(bounds.size.x):
		#for y in range(bounds.size.y):
#
			#var world_point = Vector2i(x, y)
#
			#print("POINT:", world_point)
			#print("POLY FIRST:", path[0])
			#if Geometry2D.is_point_in_polygon(world_point, path):
				#var color = src_img.get_pixel(world_point.x, world_point.y)
				#if color.a > 0:
					#selection_mask.set_pixel(x, y, Color(1,1,1,1))
					#selection_canvas.image.set_pixel(x, y, color)
					#canvas.current_layer.image.set_pixel(world_point.x, world_point.y, Color.TRANSPARENT)
	
	canvas.update_canvas()
	selection_canvas.update_visual()
	
	#Creating the outline to visually represent selection
	var local_outline: Array = []
	for p in select_path:
		local_outline.append(p - bounds.position)
	selection_canvas.get_outline(local_outline)
	
	#Setting all selection variables to be new selected area
	selection_tex = selection_canvas.tex
	selection_position = Vector2i(bounds.position)
	selection_status = select_state.FLOATING
	selection_canvas.position = selection_position
	selection_moved = false
	select_path.clear()
	
	ui_elements.select_prompt.visible = true

func create_layer():
	var current_frame = all_frames[frame_index]
	var index = current_frame.layers.size() + 1
	var layer_name = "layer_%s" % index


	var data = layers.new()
	data.texture = ImageTexture.new()
	data.image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	data.image.fill(Color.WHITE)
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
	canvas.update_canvas()
	ui_elements.current_layer_display.text = "Current: %s" % data.name
	
	create_button(data)

#CHANGE STATES

#INCEDIBLY SLOW IM SORRY IM WORKING ON IT
func paint_bucket_fill(start):
	var old_color = canvas.current_layer.image.get_pixelv(start)
	
	if start.x < 0 or start.x >= width:
		return 
	if start.y < 0 or start.y >= height:
		return
	
	if old_color == current_color:
		return
	
	var queue: Array[Vector2i] = []
	queue.append(start)
	
	while queue.size() > 0:
		var p = queue.pop_back()
		
		if p.x < 0 or p.x >= width:
			continue
		if p.y < 0 or p.y >= height:
			continue
		
		if canvas.current_layer.image.get_pixelv(p) !=  old_color:
			continue
		
		canvas.current_layer.image.set_pixel(p.x, p.y, current_color)
		
		queue.append(Vector2i(p.x + 1, p.y))
		queue.append(Vector2i(p.x - 1, p.y))
		queue.append(Vector2i(p.x, p.y + 1))
		queue.append(Vector2i(p.x, p.y - 1))
	
	canvas.update_canvas()

func load_frame(index):
	frame_index = index
	
	#Clearing on frame change because i do not want to store allat
	current_layer.undos.clear()
	current_layer.redos.clear()
	
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

func commit_selection():
	is_drawing = false
			
	var re_commit = canvas.current_layer.image
	for x in range(selection_canvas.image.get_width()):
		for y in range(selection_canvas.image.get_height()):
			var color = selection_canvas.image.get_pixel(x, y)
			if color.a > 0:
				re_commit.set_pixelv(
					selection_position + Vector2i(x,y), color
				)
	
	canvas.current_layer.texture.set_image(canvas.current_layer.image)
	canvas.update_canvas()

	current_tool = tools.BRUSH

	selection_status = select_state.IDLE
	select_path.clear()
	selection_canvas.get_outline([])
	selection_canvas.position = Vector2i(0,0)
	selection_canvas.image.fill(Color(0,0,0,0))
	selection_canvas.update_visual()
	selection_tex = null

	ui_elements.select_prompt.visible = false

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

func _on_frame_delete_button_pressed() -> void:
	if all_frames.size() == 1:
		return
	all_frames.remove_at(frame_index)
	if frame_index > 0:
		load_frame(frame_index - 1)
	elif frame_index >= all_frames.size():
		frame_index = all_frames.size() - 1
	
func _on_layer_delete_button_pressed() -> void:
	if all_frames[frame_index].layers.size() <= 1:
		return

	var layer_index = all_frames[frame_index].layers.find(current_layer)
	all_frames[frame_index].layers.remove_at(layer_index)
	
	for button in layer_holder.get_children():
		if button.text == current_layer.name:
			button.queue_free()
	
	if layer_index > 0:
		layer_index -= 1
	elif layer_index >= all_frames[frame_index].layers.size():
		layer_index = all_frames[frame_index].layers.size() - 1
	
	current_layer = all_frames[frame_index].layers[layer_index]
	change_layer(current_layer)

func _on_frame_duplicate_button_2_pressed() -> void:
	var new_frame = all_frames[frame_index]
	all_frames.insert(frame_index, new_frame)
	load_frame(frame_index + 1)

func _on_ui_elements_select_button_signal(type) -> void:
	print(selection_status, current_tool)
	if selection_status == select_state.FLOATING:
		match type:
			"copy":
				var re_commit = canvas.current_layer.image
				for x in range(selection_canvas.image.get_width()):
					for y in range(selection_canvas.image.get_height()):
						var color = selection_canvas.image.get_pixel(x, y)
						if color.a > 0:
							re_commit.set_pixelv(
							selection_position + Vector2i(x,y), color)
				canvas.update_canvas()
				

			"cut":
				selection_canvas.image.fill(Color.TRANSPARENT)
				commit_selection()
			"fill":
				if !selection_moved:
					for x in range(selection_mask.get_width()):
						for y in range(selection_mask.get_height()):
							if selection_mask.get_pixel(x,y).a > 0 :
								selection_canvas.image.set_pixel(x,y, current_color)
					commit_selection()
			_:
				print("failed")

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
class frame:
	var layers: Array = []
#ALL OF THESE GOT UNDO FUNCTIONS
class stroke:
	var path: PackedVector2Array
	var color: Color
	var brush_size: float
	func _init():
		path = PackedVector2Array()
class selection_cut:
	var area : PackedVector2Array
	var color: Color
class selection_copy:
	var idkwhatillneedinhere
class selection_fill:
	var area: PackedVector2Array
	var color: Color
class selection_move:
	var original_pos: Vector2i
	var new_pos: Vector2i
	var selected_area: PackedVector2Array
class bucket_fill:
	var area: PackedVector2Array
	var color: Color
	

#Camera and action input. > Self
#Drawing and Visual rep > In the canvas sprite2d
#Ui Rep > Canvas Layer
#hub for classes, and large data sets > Self
#Creation > Self
