@tool
class_name ImageIO

## Pure, stateless helpers for PNG load / create / save.
## Centralised so no other class duplicates file-format logic.

const _PNG_EXTENSION := ".png"


static func load_png(path: String) -> Image:
	assert(path.get_extension().to_lower() == "png", "ImageIO only handles PNG")
	var img := Image.load_from_file(path)
	if img == null:
		push_error("PixelEditor: failed to load image at %s" % path)
		return null
	# Normalise to RGBA8 so the editor always has an alpha channel (eraser
	# transparency, flood-fill, region undo). add_frame_with_image enforces this
	# too, but direct ImageIO consumers benefit from a consistent format here.
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Creates a transparent image. size_x/size_y are clamped to >=1.
static func create_blank(size_x: int, size_y: int) -> Image:
	size_x = maxi(size_x, 1)
	size_y = maxi(size_y, 1)
	return Image.create(size_x, size_y, false, Image.FORMAT_RGBA8)


static func save_png(img: Image, path: String) -> Error:
	if not path.ends_with(_PNG_EXTENSION):
		path += _PNG_EXTENSION
	return img.save_png(path)
