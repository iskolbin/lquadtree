Quad Tree
=========

Persistent quad tree implementation for Lua for fast spatial queries. It's more
like persistent spatial hash structure actually. All operations are non-mutating.

### make( width, height[, levels] ) -> QuadTree

> default levels = 3

Create new quad tree structure. To optimize spatial queries `levels` variable
defines the number of spatial subdivisions, for example `levels = 3` (default)
will divide domain in 64 rectangles.

Optimal value of `levels` highly depends on the task, especially on the average
size of spatial objects. Good approximation is size of the smallest subdivision
is x2 of average size of object, for example for 32x32 px object for 1920x1080
field 5 levels will be ok, size of leaf will be 60x33,75.

As you already guessed it will perform badly if you have lots of highly
different sized objects. While internally this is a quadtree, it performs like
spatial hashing schemes.

### insert( QuadTree, x, y, width, height ) -> QuadTree, rid

Inserts new rectangle in the tree and updates internal `id` counter. Returns
updated tree and table (`rid = {x0,y0,x1,y1,id}` which can be used for `remove`
and `update`.

### remove( QuadTree, rid ) -> QuadTree

Removes entity specified by `rid` with  from the tree. Returns updated tree.

### update( QuadTree, rid[, x, y, width, height] ) -> QuadTree, rid

> default x, y, width and height will be taken from rid

Updates entity with `rid` in the tree. Essentially this is `remove` followed by
`insert`.

### get( QuadTree, x, y[, width, height] ) -> {id: id}

> default width and height are 0 (point)

Gets all entities stored in the leaf rectangles overlapping with specified rectangle
(or point). Returns table filled with id as key-value pairs (not array). After
that you have to filter properly.

### neighbors( QuadTree, rid ) -> {id: id}

Get ids of all entities in the cells in which the `rid` entity is located
(without `rid` itself). This is suitable for broadphase of collision detection
algorithm.

### intersects( rid1, rid2 ) -> boolean

Checks rectangles specified by `rid1` and `rid2` for intersection.

### id( rid ) -> id

Returns `id` from `rid` (5-th element).
