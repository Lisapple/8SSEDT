#ifndef SSEDT8_H
#define SSEDT8_H

#include <object.h>
#include <core/vector.h>
#include <core/image.h>

class SSEDT8 : public Object {
	GDCLASS(SSEDT8, Object);

private:

	class Grid {

	private:
		Vector2 size;
		Vector<Vector2> distances;

		bool has(int x, int y) const {
			return (0 <= x and x < size.x and 0 <= y and y < size.y);
		}

		int _index(int x, int y) const {
			return y * size.x + x;
		}

	public:

		Vector2& get_size() { return size; }

		Grid(int width, int height);

		Vector2 get_dist(int x, int y) const {
			return distances[_index(x, y)];
		}

		int set_dist(int x, int y, Vector2 p_distance) {
			distances[_index(x, y)] = p_distance;
		}

		void update(int x, int y, Vector2 offset);
	};

	static void apply_offsets(Grid &p_grid, int x, int y, Vector<Vector2> &p_offsets) {

		for (int i = 0; i < p_offsets.size(); ++i)
			p_grid.update(x, y, p_offsets[i]);
	}

	static void apply_pass(Grid &p_grid, Vector<Vector2> &p_offsets1, Vector<Vector2> &p_offsets2, bool inverted = false);

protected:

	static void _bind_methods();

public:

	Ref<Image> from(Ref<Image> p_image, real_t scale = 0.005) const;
};

#endif // SSEDT8_H
