extends Sprite2D

var image = Image.new()
var tex = ImageTexture.new()

func create_new_selection(width, height):
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	tex.set_image(image)

func get_variables():
	return [image, tex]
