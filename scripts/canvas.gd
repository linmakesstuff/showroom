extends Sprite2D

var height = 1000
var width = 1000

func _ready() -> void:
	texture = ImageTexture.new()
	#images is the colors that go on the canvas, texture is the canvas (i think)
	var img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color.CORNFLOWER_BLUE)
	
	texture.set_image(img)
	
func update_canvas():
	pass
