extends Sprite2D

@onready var layer_holder = $"../camera/ui_elements/PanelContainer/MarginContainer/layer_holder"
@onready var current_display: Label = $"../camera/ui_elements/current_display"
@onready var canvas_holder = $"../canvas_holder"

var height
var width  

var current_bs = 3
var current_color := Color.BLACK
var dirty = false

var all_layers := {}
var current_layer

var current_stroke
var last_point = null

var current_img: Image
var current_texture

func _ready() -> void:
	centered = false
	if SceneSwitcher.new_arg != null:
		var data = load(SceneSwitcher.new_arg)
		load_data(data)


func load_data(data):
	if data.frames.is_empty():
		texture = ImageTexture.new()
		width = data.size.x
		height = data.size.y
		current_img = Image.new()
		current_img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		current_img.fill(Color.WHITE)
		texture.set_image(current_img)
		_on_storyboard_manager_create_new_layer()
	else:
		pass

func save_data():
	pass

func save_stroke(new_stroke):
	current_layer.undos.append(new_stroke)
	print(current_layer.undos)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
		#print("painting on: " + str(current_layer))
		current_stroke = stroke.new()
			
		current_stroke.brush_size = current_bs
		current_stroke.color = current_color

	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			if current_layer.redos.size() > 0:
				current_layer.redos.clear()
			
			var mouse_pos = get_global_mouse_position()
			var lpos = to_local(mouse_pos)
			
			if lpos.x >= 0 and lpos.y >= 0 and lpos.x < width and lpos.y < height:
				if last_point == null:
					last_point = lpos
				
				var distance = last_point.distance_to(lpos)
				var step = 1.0  # 1 unit per step; can scale with brush size
				var steps = int(ceil(distance / step))
				
				for i in range(steps):
					var t = float(i) / steps
					var interp = last_point.lerp(lpos, t)
					if current_stroke != null:
						current_stroke.path.append(interp)
					paint_canvas(interp, current_color)
				last_point = lpos
		
	if Input.is_action_just_released("left_click"):
		last_point = null
		if current_stroke != null and current_stroke.path.size() > 0:
			save_stroke(current_stroke)

	if Input.is_action_just_pressed("undo"):
		undo_strokes()
	if Input.is_action_just_pressed("redo"):
		pass

func undo_strokes():
	current_img.fill(Color.TRANSPARENT)
	current_layer.redos.append(current_layer.undos[-1])
	current_layer.undos.remove_at(-1)
	for i in current_layer.undos:
		#i.path, i.color
		for j in i.path:
			current_img.fill_rect(Rect2i(j, Vector2i(1,1)).grow(current_bs), current_color)
	update_canvas()

func _process(_delta: float) -> void:
	if dirty:
		update_canvas()
		dirty = false

func paint_canvas(pos: Vector2, color: Color):
	var ipos = Vector2i(pos)
	current_img.fill_rect(Rect2i(ipos, Vector2i(1,1)).grow(current_bs), color)
	dirty = true

func update_canvas():
	current_texture.update(current_img)

func create_button(data):
	var new_button = Button.new()
	new_button.text = data.name
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	new_button.pressed.connect(func(): on_layer_button_pressed(data))
	
	layer_holder.add_child(new_button)

func _on_storyboard_manager_create_new_layer() -> void:
	var index = 1
	var layer_name = "layer_%s" % index
	while all_layers.has(layer_name):
			index += 1
			layer_name = "layer_%s" % index 

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
	
	all_layers[layer_name] = data
	
	current_layer = data
	current_img = data.image
	current_texture = data.texture
	current_display.text = "Current: %s" % data.name
	
	create_button(data)


func on_layer_button_pressed(data):
	current_layer = data
	current_display.text = "Current: %s" % data.name
	current_img = data.image
	current_texture = data.texture

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
	var undos: Array = []
