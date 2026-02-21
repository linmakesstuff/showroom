extends Sprite2D

var current_layer

var selection_img: Image
var selection_position: Vector2
var selection_tex

var dirty = false

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if event.pressed and !event.is_echo():
				#if !is_drawing:
					#select_path.clear()
					#is_drawing = true
					#current_stroke = stroke.new()
			#
					#current_stroke.brush_size = current_bs
					#current_stroke.color = current_color
			#elif !event.pressed:
				#is_drawing = false
				#last_point = null
				#if current_stroke != null and current_stroke.path.size() > 0:
					#save_stroke(current_stroke)
				#if current_tool == tools.SELECT:
					#select_path.append(select_path[0])
					#create_select(select_path)
#
	#if event is InputEventMouseMotion:
		#if Input.is_action_pressed("space"):
			#if is_selecting:
				#selection_sprite.position += event.relative
				#queue_redraw()
		#if is_drawing:
			#pass
			##if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
				##if current_layer:
					##if current_layer.redos.size() > 0:
						##current_layer.redos.clear()
				##
			##var mouse_pos = get_global_mouse_position()
			##var lpos = to_local(mouse_pos)
				##
			##if lpos.x >= 0 and lpos.y >= 0 and lpos.x < width and lpos.y < height:
				##if last_point == null:
					##last_point = lpos
					##
				##var distance = last_point.distance_to(lpos)
				##var step = 1.0  # 1 unit per step; can scale with brush size
				##var steps = int(ceil(distance / step))
					##
				##for i in range(steps):
					##var t = float(i) / steps
					##var interp = last_point.lerp(lpos, t)
					##if current_stroke != null and current_tool != tools.SELECT:
						##current_stroke.path.append(interp)
					##if current_tool == tools.ERASER:
						##var eraser = Color.TRANSPARENT
						##paint_canvas(interp, eraser, current_bs)
					##if current_tool == tools.SELECT:
						##select_path.append(interp)
					##else:
						##paint_canvas(interp, current_color, current_bs)
				##last_point = lpos
				#
	#
	#if Input.is_action_just_pressed("ui_left"):
		#current_tool = tools.SELECT
		#print(select_path)
#
	#if Input.is_action_just_pressed("undo"):
		#if !is_drawing:
			#if current_layer.undos.size() > 0:
				#undo_strokes()
	#if Input.is_action_just_pressed("redo"):
		#if !is_drawing:
			#if current_layer.redos.size() > 0:
				#redo_strokes()


#CANVAS PROCESSES

func _process(_delta: float) -> void:
	if dirty:
		update_canvas()
		dirty = false

func paint_canvas(pos: Vector2, color: Color, bs: float):
	var ipos = Vector2i(pos)
	@warning_ignore("narrowing_conversion")
	current_layer.image.fill_rect(Rect2i(ipos, Vector2i(1,1)).grow(bs), color)
	dirty = true

func update_canvas():
	current_layer.texture.update(current_layer.image)
	
func set_current(data):
	current_layer = data

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
