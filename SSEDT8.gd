extends Object

## About
# Godot engine (https://godotengine.com) GDScript to compute 8SSEDT image.

## Usage
#	var SSEDT8 = preload("res://path/to/SSEDT8.gd") # Import
#
# var map_img = preload("res://map.png").get_data() # Load source image
# var dist_img = SSEDT8.from(map_img)
# dist_img.save_png("res://dist.png") # Save to disk

class Grid extends Object:
	var _size
	var cells = [] # [Vector2]

	func _init(width, height):
		_size = Vector2(width, height)
		for y in range(height): for x in range(width): cells.append(Vector2(0,0))

	func get_size():
		return _size

	func contains(x, y):
		return (0 <= x and x < _size.x and 0 <= y and y < _size.y)

	func _index(x, y):
		assert(contains(x, y))
		return y * _size.x + x

	func at(x, y):
		return cells[_index(x, y)]

	func put(x, y, distance): # void put(float, float, Vector2)
		cells[_index(x, y)] = distance

	func update(x, y, offset): # void update(float, float, Vector2)
		var position = Vector2(x, y)
		var distance = at(x, y); var squared = distance.length_squared()
		var offposition = position + offset
		if contains(offposition.x, offposition.y):
			var offdistance = at(offposition.x, offposition.y) + offset
			var offsquared = offdistance.length_squared()
			if offsquared < squared:
				put(x, y, offdistance)

static func apply_pass(grid, offsets1, offsets2, inverted=false): # Grid apply_pass(&Grid, [Vector2], [Vector2], bool?)
	var width = grid.get_size().x; var height = grid.get_size().y
	for y in range(height-1,0,-1) if inverted else range(height):
		for x in range(width-1,0,-1) if inverted else range(width):
			for offset in offsets1: grid.update(x, y, offset)
		for x in range(width) if inverted else range(width-1,0,-1):
			for offset in offsets2: grid.update(x, y, offset)

static func from(image):
	var width = image.get_width(); var height = image.get_height()

	# Initialise grid
	var grid1 = Grid.new(width, height); var grid2 = Grid.new(width, height)
	var DISTANT = 9999
	for y in range(height):
		for x in range(width):
			# Foreground if brightness > 0.5, background else
			var distance = 0 if image.get_pixel(x, y).v > 0.5 else DISTANT
			grid1.put(x, y, Vector2(distance,distance))
			grid2.put(x, y, Vector2(DISTANT-distance,DISTANT-distance))

	# Pass #1
	var offsets1 = [ Vector2(-1, 0), Vector2(0, -1), Vector2(-1, -1), Vector2(1, -1) ]
	var offsets2 = [ Vector2(1, 0) ]
	apply_pass(grid1, offsets1, offsets2, false)
	apply_pass(grid2, offsets1, offsets2, false)
	# Pass #2 (inverted direction)
	var offsets1 = [ Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1), Vector2(1, 1) ]
	var offsets2 = [ Vector2(-1, 0)]
	apply_pass(grid1, offsets1, offsets2, true)
	apply_pass(grid2, offsets1, offsets2, true)

	# Output final grid image
	var output = Image(width, height, false, Image.FORMAT_GRAYSCALE)
	for y in range(height):
		for x in range(width):
			var distance1 = grid1.at(x, y); var distance2 = grid2.at(x, y)
			var distance = distance1.length() - distance2.length()
			distance = (1 + clamp(-1, distance / 200.0, 1)) / 2.0 # Normalize the final pixel value
			output.put_pixel(x, y, Color(distance,distance,distance))
	return output
