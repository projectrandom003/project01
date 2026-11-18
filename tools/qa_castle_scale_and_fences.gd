extends SceneTree
func _initialize():
 var preview=load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn")
 var playable=load("res://scenes/world/castle_royal_gardens.tscn")
 if preview == null or playable == null:
  push_error("CASTLE_FENCE_SCENE_LOAD_FAILED")
  quit(1)
  return
 var pv=preview.instantiate()
 root.add_child(pv)
 await process_frame
 var fences=pv.get_node_or_null("FenceSystem/GardenFences/FenceRuns")
 var castle=pv.get_node_or_null("CastleSystem/ModularCastleAssembly")
 if fences == null or castle == null:
  push_error("PREVIEW_FENCE_OR_CASTLE_MISSING")
  quit(1)
  return
 var count=fences.get_child_count()
 var keep=castle.get_node("CastleKeep")
 var gate=castle.get_node("GrandGatehouse")
 print("PREVIEW_FENCE_SPRITES=",count)
 print("KEEP_SCALE=",keep.scale," GATE_SCALE=",gate.scale)
 if count < 24 or keep.scale.x < 1.17 or gate.scale.x < 0.91:
  push_error("CASTLE_FENCE_LAYOUT_ASSERTION_FAILED")
  quit(1)
  return
 var world=playable.instantiate()
 root.add_child(world)
 await process_frame
 var playable_fences=world.get_node_or_null("GardenFences/FenceRuns")
 if playable_fences == null or playable_fences.get_child_count() < 24:
  push_error("PLAYABLE_FENCE_ASSEMBLY_MISSING")
  quit(1)
  return
 print("PLAYABLE_FENCE_SPRITES=",playable_fences.get_child_count())
 print("CASTLE_SCALE_AND_FENCE_QA_OK")
 quit()
