Quad Tree
=========

Persistent quad tree implementation for Lua. It's more like persistent spatial
hash structure actually. All operations are non-mutating.

QuadTree.make( width, height, levels = 3 )
--------------------------------------------

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

QuadTree.insert( qt, x, y, width, height )
------------------------------------------

Inserts new rectangle in the tree and updates internal `id` counter. Returns
updated tree and table (`rid`:  x0, y0, x1, y1 and id 5-element table) which
can be used for `remove` and `update`.

QuadTree.remove( qt, rid )
--------------------------

Removes entity specified by `rid` with  from the tree. Returns updated tree.

QuadTree.update( qt, rid, nx = rid[1], ny = rid[2], nw = rid[3]-rid[1], nh = rid[4]-rid[2] )
--------------------------------------------------------------------------------------------

Updates entity with `rid` in the tree. Essentially this is `remove` followed by
`insert`.

QuadTree.get( qt, x, y, width = 0, height = 0 )
-----------------------------------------------

Gets all entities stored in leaf rectangles overlapping with specified rectangle
(or point). Returns table filled with id as key-value pairs (not array). After
that you have to filter properly.

QuadTree.neighbors( qt, rid )
-----------------------------

Get ids of all entities in the cells in which the `rid` entity is located
(without `rid` itself). This is suitable for broadphase of collision detection
algorithm.

QuadTree.intersects( rid1, rid2 )
---------------------------------

Checks rectangles specified by `rid1` and `rid2` for intersection.

QuadTree.id( rid )
------------------

Returns `id` from `rid`.
