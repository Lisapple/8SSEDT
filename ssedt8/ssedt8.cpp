#include "SSEDT8.h"

/// Grid methods implementation

SSEDT8::Grid::Grid(int width, int height) : size(width, height) {
	for (int i = 0; i < height*width; ++i) {
		distances.push_back(Vector2(0,0));
	}
}

void SSEDT8::Grid::update(int x, int y, Vector2 offset) {

	Vector2 pos = Vector2(x, y), offset_pos = pos + offset;
	Vector2 distance = get_dist(x, y);
	real_t dist_sq = distance.length_squared();

	if (has(offset_pos.x, offset_pos.y)) {

		Vector2 offset_dist = get_dist(offset_pos.x, offset_pos.y) + offset;
		real_t offset_sq = offset_dist.length_squared();
		if (offset_sq < dist_sq)
			set_dist(x, y, offset_dist);
	}
}

/// SSEDT8 methods implementation

void SSEDT8::apply_pass(Grid &p_grid, Vector<Vector2> &p_offsets1, Vector<Vector2> &p_offsets2, bool inverted) {

	real_t width = p_grid.get_size().x, height = p_grid.get_size().y;
	if (inverted) {

		for (int y = height-1; y >= 0; --y) {
			for (int x = width-1; x >= 0; --x)
				apply_offsets(p_grid, x, y, p_offsets1);
			for (int x = 0; x < width; ++x)
				apply_offsets(p_grid, x, y, p_offsets2);
		}
	} else {

		for (int y = 0; y < height; ++y) {
			for (int x = 0; x < width; ++x)
				apply_offsets(p_grid, x, y, p_offsets1);
			for (int x = width-1; x >= 0; --x)
				apply_offsets(p_grid, x, y, p_offsets2);
		}
	}
}

Ref<Image> SSEDT8::from(Ref<Image> p_image, float scale) const {
	real_t width = p_image->get_width(), height = p_image->get_height();

	// Initialise grids
	Grid grid1 = Grid(width, height), grid2 = Grid(width, height);
	const real_t DISTANT = FLT_MAX;

	p_image->lock();
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {
			// if brightness > 0.5 it's foreground, background else
			real_t distance = (p_image->get_pixel(x, y).r > 0.5) ? 0 : DISTANT;
			grid1.set_dist(x, y, Vector2(distance, distance));
			grid2.set_dist(x, y, Vector2(DISTANT - distance, DISTANT - distance));
		}
	}
	p_image->unlock();

	// Pass #1
	Vector<Vector2> offsets1; {
		offsets1.push_back(Vector2(-1, 0)); offsets1.push_back(Vector2(0, -1));
		offsets1.push_back(Vector2(-1, -1)); offsets1.push_back(Vector2(1, -1));
	}
	Vector<Vector2> offsets2; {
		offsets2.push_back(Vector2(1, 0));
	}
	apply_pass(grid1, offsets1, offsets2, false);
	apply_pass(grid2, offsets1, offsets2, false);

	// Pass #2
	offsets1.clear(); {
		offsets1.push_back(Vector2(1, 0)); offsets1.push_back(Vector2(0, 1));
		offsets1.push_back(Vector2(-1, 1)); offsets1.push_back(Vector2(1, 1));
	}
	offsets2.clear(); {
		offsets2.push_back(Vector2(-1, 0));
	}
	apply_pass(grid1, offsets1, offsets2, true);
	apply_pass(grid2, offsets1, offsets2, true);

	// Output final grid image
	Ref<Image> p_output = memnew(Image(width, height, false, Image::Format::FORMAT_RGB8));
	p_output->lock();
	for (int y = 0; y < height; ++y) {
		for (int x = 0; x < width; ++x) {

			const Vector2 distance1 = grid1.get_dist(x, y);
			const Vector2 distance2 = grid2.get_dist(x, y);
			real_t distance = distance1.length() - distance2.length();
			distance = (1 + MAX(-1, MIN(distance * scale, 1))) / 2.0; // Normalize the final pixel value
			p_output->set_pixel(x, y, Color(distance, distance, distance));
		}
	}
	p_output->unlock();
	return p_output;
}

void SSEDT8::_bind_methods() {
	ClassDB::bind_method(D_METHOD("from", "image", "scale"), &SSEDT8::from, DEFVAL(0.005));
}
