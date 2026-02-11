extends Sprite2D

var height = 1000
var width = 1000

var current_bs = 3
var current_color := Color.BLACK
var dirty = false

var all_layers := {}
var current_layer = 1

var undo = []
var redo = []

var current_stroke
var last_point = null

var img: Image

func _ready() -> void:
	centered = false
	texture = ImageTexture.new()
	#images is the colors that go on the canvas, texture is the canvas (i think)
	img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color.CORNFLOWER_BLUE)
	#Needs to be set first
	texture.set_image(img)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click"):
				print("new stroke created")
				current_stroke = stroke.new()
			
				current_stroke.brush_size = current_bs
				current_stroke.color = current_color
				current_stroke.layer_id = current_layer

	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			var mouse_pos = get_global_mouse_position()
			var lpos = to_local(mouse_pos)
			
			if last_point == null:
				last_point = lpos
			
			var distance = last_point.distance_to(lpos)
			var step = 1.0  # 1 unit per step; can scale with brush size
			var steps = int(ceil(distance / step))
			
			for i in range(steps):
				var t = float(i) / steps
				var interp = last_point.lerp(lpos, t)
				current_stroke.path.append(interp)
				paint_canvas(interp)
			last_point = lpos
		
	if Input.is_action_just_released("left_click"):
		last_point = null
		save_stroke(current_stroke)

	if Input.is_action_just_pressed("undo"):
		if undo.size() > 0:
			undo.remove_at(-1)
	if Input.is_action_just_pressed("redo"):
		if redo.size() > 0:
			pass

func save_stroke(stroke):
	undo.append(stroke)

func _process(_delta: float) -> void:
	if dirty:
		update_canvas()
		dirty = false

func paint_canvas(pos):
	var ipos = Vector2i(pos)
	img.fill_rect(Rect2i(ipos, Vector2i(1,1)).grow(current_bs), current_color)
	dirty = true

func update_canvas():
	texture.update(img)

func _on_storyboard_manager_create_new_layer() -> void:
	var layer_created = false
	var index = 1
	var layer_name = "layer_%s" % index
	while layer_created == false:
		for key in all_layers.keys():
			if key == layer_name:
				break
			else:
				layer_created = true
				pass #crate new layer

class layers:
	var index: int
	var vis: bool
	var opacity: float
	var name: String

class stroke:
	var path: PackedVector2Array
	var color: Color
	var brush_size: float
	var layer_id: int
	


	
