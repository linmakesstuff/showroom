extends Sprite2D

var image = Image.new()
var tex = ImageTexture.new()
var outline: PackedVector2Array

func create_new_selection(width, height):
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	tex = ImageTexture.create_from_image(image)
	texture = tex
	tex.set_image(image)

func get_outline(path):
	outline = path
	queue_redraw()

func update_visual():
	tex.set_image(image)

func _draw() -> void:
	if outline.size() > 0:
		draw_polyline(outline, Color.RED)
