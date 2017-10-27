8-points Signed Sequential Euclidean Distance Transform
=======================================================

The Signed-Distance Field (SDF) of an 2-shades image will compute, for each pixel, the _signed-distance_ (can be positive or negative) to the **nearest pixel with different value**. Pixels have positive distance in foreground, and negative distance in background.

#### Example:

![](image.png)

will give the distance for each pixel:

(positive for dark gray pixel and negative for light gray)

![](distances.png)

#### Simple bitmap example:

For a bitmap with representation:

```
[0][0][0]
[0][1][1]
[1][1][1]

```

where all 0 represent pixel outside the (white) shape (i.e background) and all 1 inside (i.e foreground).

The final result is:

```
[-2][-1][-1]
[-1][ 1][ 1]
[ 1][ 2][ 2]

```

* The first pixel (background) is at a distance (signed-squared in this case) of -2 to foreground.

* The last pixel (foreground) is at a distance of 1 to background, etc.

#### Building the initial grid

For each pixel, we need to build a _first grid_ (grid #1) with a distance duet `(dx, dy)`

like `(dx=0, dy=0)` if inside (foreground) and `(dx=∞, dy=∞)` if outside (background)

```
[∞][∞][∞]
[∞][0][0]
[0][0][0]

```

with `(0, 0)` represented by `0` and `(∞, ∞)` by `∞`.

and a `second grid` (grid #2) with inverted distances:

```
[0][0][0]
[0][∞][∞]
[∞][∞][∞]

```

**Note:** All pixel out of bounds are use the value `(∞, ∞)` as:

```
 ∞  ∞  ∞ 
 ∞ [x][∞]
 ∞ [∞][0]

```

- Computing grids:

To get the distance `x`, we look all neighbours (from `#1` to `#8`) distances:

```
[#1][#2][#3]
[#4][ x][#5]
[#6][#7][#8]

```

using relative offset `[offset x, offset y]` to `x` like so:

```
[-1,-1][0,-1][1,-1]
[-1, 0][0, 0][1, 0]
[-1, 1][0, 1][1, 1]

```

then the final value of `x` is

`x = min(#0.distance, ..., #7.distance)`

using the distance function that compute the magnitude of the distance with offset:

`#?.distance = sqrt( (?dx + offset x)^2 + (?dy + offset y)^2 )`

This gives:

```
#1.distance = (∞-1, ∞-1).distance = √(∞^2 + ∞^2) = ∞
#2.distance = (∞+0, ∞-1).distance = √(∞^2 + ∞^2) = ∞
#3.distance = (∞+1, ∞-1).distance = √(∞^2 + ∞^2) = ∞
#4.distance = (∞-1, ∞+0).distance = √(∞^2 + ∞^2) = ∞
#5.distance = (0+1, 0+0).distance = √(1^2 + 0^2) = 1
#6.distance = (0-1, 0+1).distance = √(-1^2 + 1^2) = √2
#7.distance = (0+0, 0+1).distance = √(0^2 + 1^2) = 1
#8.distance = (0+1, 0+1).distance = √(1^2 + 1^2) = √2

```

so

`x = min(#0.distance, ..., #7.distance]) = 1`

* Updated grid:

```
[∞][∞][∞]
[∞][1][0]
[0][0][0]

```

Then process the next cell on the right.

#### Computing method

In total 4 passes are necessary to compute all distances, two sequential passes, for each grid #1 and #2.  


Using the initialised grid:

(from left to right, top to bottom)

```
   - - - >
| [?][?][?]
| [?][x][ ]
v [ ][ ][ ]
```

then (using the same grid)

(from right to left)

```
   < - - -
| [ ][ ][ ]
| [ ][x][?]
v [ ][ ][ ]
```

then

(from right to left, bottom to top)

```
   < - - -
^ [ ][ ][ ]
| [ ][x][?]
| [?][?][?]
```

then:

(from left to right)

```
   - - - >
^ [ ][ ][ ]
| [?][x][ ]
| [ ][ ][ ]
```


#### Computing final signed distances

Once the four steps applied on the grid #1 and #2,
we compute the difference of the magnitude of each cell (pixel) `#n1` and `#n2` of the two grids:

```
foreach (#n1 of grid #1) and (#n2 of grid #2):
	final distance = #n1.distance - #n2.distance
```

with `#n.distance = sqrt( #n.dx * #n.dx + #n.dy * #n.dy )`.

#### References

Distance field generator with C++ and SDL [codersnotes.com](http://www.codersnotes.com/notes/signed-distance-fields/)

Valve paper on distance field [Improved Alpha-Tested Magnification for Vector Textures and Special Effects](http://www.valvesoftware.com/publications/2007/SIGGRAPH2007_AlphaTestedMagnification.pdf)