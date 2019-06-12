extends Object

## About
# Godot engine (https://godotengine.com) GDScript to compute 8SSEDT image.
# Source: https://github.com/Lisapple/8SSEDT
#
# This code is in public domain.

## Usage
# var SSEDT8 = preload("res://path/to/SSEDT8.gd") # Import
#
# var map_img = preload("res://map.png").get_data() # Load source image
# var dist_img = SSEDT8.from(map_img)
# dist_img.resize(128, 128) # Save disk space
# dist_img.save_png("res://dist.png") # Save to disk

class Grid extends Object:
	var size: Vector2 setget ,get_size
	func get_size() -> Vector2:
		return size
	
	var cells := PoolVector2Array()

	func _init(width: int, height: int):
		size = Vector2(width, height)
		cells.resize(width * height)
# warning-ignore:unused_variable
		for y in range(height):
# warning-ignore:unused_variable
			for x in range(width):
				cells.append(Vector2())

	func contains(x: int, y: int) -> bool:
		return (0 <= x and x < self.size.x and 0 <= y and y < self.size.y)

	func _index(x: int, y: int) -> int:
		assert(contains(x, y))
		return y * int(self.size.x) + x

	func at(x: int, y: int) -> Vector2:
		return cells[_index(x, y)]

	func put(x: int, y: int, distance: Vector2):
		cells[_index(x, y)] = distance

	func update(x: int, y: int, offset: Vector2):
		var position := Vector2(x, y)
		var distance := at(x, y); var squared := distance.length_squared()
		var offposition := position + offset
		if contains(int(offposition.x), int(offposition.y)):
			var offdistance := at(int(offposition.x), int(offposition.y)) + offset
			var offsquared := offdistance.length_squared()
			if offsquared < squared:
				put(x, y, offdistance)

static func apply_pass(grid: Grid, offsets1: PoolVector2Array, offsets2: PoolVector2Array, inverted:=false):
	var width := grid.get_size().x
	var height := grid.get_size().y
	for y in (range(height-1,0,-1) if inverted else range(height)):
		for x in (range(width-1,0,-1) if inverted else range(width)):
			for offset in offsets1:
				grid.update(x, y, offset)
		for x in (range(width) if inverted else range(width-1,0,-1)):
			for offset in offsets2:
				grid.update(x, y, offset)

# Returns distance map of `image`.
# For better results but much slower computation, use high resolution images (2014px or more).
# Adjust `distance_factor` for better sharpness of output image.
# Note: This is a (very) slow process! (For faster computation, use repository C++ module.)
static func from(image: Image, distance_factor:=0.005) -> Image:
	var width := image.get_width(); var height := image.get_height()

	# Initialise grids
	var grid1 := Grid.new(width, height)
	var grid2 := Grid.new(width, height)
	var DISTANT := 9999
	image.lock()
	for y in range(height):
		for x in range(width):
			# Foreground if brightness > 0.5, background else
			var distance := (0 if image.get_pixel(x, y).v > 0.5 else DISTANT)
			grid1.put(x, y, Vector2(distance, distance))
			grid2.put(x, y, Vector2(DISTANT-distance, DISTANT-distance))
	image.unlock()

	# Pass #1
	var offsets1 := [ Vector2(-1, 0), Vector2(0, -1), Vector2(-1, -1), Vector2(1, -1) ]
	var offsets2 := [ Vector2(1, 0) ]
	apply_pass(grid1, offsets1, offsets2, false)
	apply_pass(grid2, offsets1, offsets2, false)
	# Pass #2 (inverted direction)
	offsets1 = [ Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(1, 1) ]
	offsets2 = [ Vector2(-1, 0)]
	apply_pass(grid1, offsets1, offsets2, true)
	apply_pass(grid2, offsets1, offsets2, true)

	# Output final grid image
	var output := Image.new()
	output.create(width, height, false, Image.FORMAT_L8)
	output.lock()
	for y in range(height):
		for x in range(width):
			var distance1 := grid1.at(x, y)
			var distance2 := grid2.at(x, y)
			var distance := distance1.length() - distance2.length()
			distance = (1 + clamp(distance * distance_factor, -1,1)) / 2.0 # Normalize the final pixel value
			output.set_pixel(x, y, Color(distance, distance, distance))
	output.unlock()
	return output
