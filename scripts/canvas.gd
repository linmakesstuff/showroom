extends Sprite2D

var current_layer

var selection_img: Image
var selection_position: Vector2
var selection_tex

var dirty = false

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
