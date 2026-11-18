# Royal Garden Modular Trees

Three reusable, scene-authored tree props have been added:
- Blossom tree: 96×128 px (3×4 cells of 32×32)
- Broadleaf tree: 96×128 px (3×4 cells of 32×32)
- Evergreen tree: 96×128 px (3×4 cells of 32×32)

Each tree is a Node2D scene with:
- Sprite2D visual, anchored at its feet
- StaticBody2D trunk footprint
- CollisionShape2D for the trunk
- Y sorting enabled on the root

Scene files:
- `royalgardenblossomtree.tscn`
- `royalgardenbroadleaftree.tscn`
- `royalgardenevergreentree.tscn`

The trees are modular multi-cell objects, not forced into a single 32×32 tile.
