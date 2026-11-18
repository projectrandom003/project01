extends SceneTree
func dump(n:Node,depth:int=0):
 if depth<=4: print("  ".repeat(depth),n.name," [",n.get_class(),"] pos=",n.position if n is Node2D else Vector2.ZERO," global=",n.global_position if n is Node2D else Vector2.ZERO)
 if depth<5:
  for c in n.get_children(): dump(c,depth+1)
func _initialize():
 var packed=load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene
 var root=packed.instantiate()
 get_root().add_child(root)
 await process_frame
 dump(root)
 quit(0)
