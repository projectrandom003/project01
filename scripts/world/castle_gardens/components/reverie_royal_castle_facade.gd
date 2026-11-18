@tool
class_name ReverieRoyalCastleFacade
extends Node2D
## Original Royal Gardens castle frontage: moonstone Gothic hall, twin towers,
## violet roofs, warm windows, rose-gold crest and a central pointed entrance.
func _draw() -> void:
	# Main keep silhouette
	draw_colored_polygon(PackedVector2Array([Vector2(-260,8),Vector2(260,8),Vector2(260,-190),Vector2(-260,-190)]),Color("#77718f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-248,0),Vector2(248,0),Vector2(248,-182),Vector2(-248,-182)]),Color("#c6bfd4"))
	# Wing roof
	draw_colored_polygon(PackedVector2Array([Vector2(-278,-180),Vector2(0,-292),Vector2(278,-180)]),Color("#554b7e"))
	draw_line(Vector2(-270,-181),Vector2(0,-294),Color("#d7b2c0"),4.0,true)
	draw_line(Vector2(0,-294),Vector2(270,-181),Color("#d7b2c0"),4.0,true)
	# Slate roof tile highlights
	for i in range(9):
		var x := -224.0+float(i)*56.0
		draw_line(Vector2(x,-202),Vector2(x+18,-210),Color("#8174a5"),2.0,true)
	# Tower pair
	for x in [-210.0,210.0]:
		draw_rect(Rect2(x-42,-260,84,260),Color("#a9a2c3"))
		draw_rect(Rect2(x-34,-252,68,250),Color("#d2c8da"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-54,-258),Vector2(x,-350),Vector2(x+54,-258)]),Color("#514875"))
		draw_line(Vector2(x,-350),Vector2(x,-369),Color("#e6bb9c"),4.0,true)
		for yy in [-218.0,-148.0,-78.0]:
			draw_rect(Rect2(x-11,yy,22,38),Color("#645b80"))
			draw_rect(Rect2(x-7,yy+4,14,29),Color("#ffdba8"))
			draw_arc(Vector2(x,yy+4),7.0,PI,TAU,10,Color("#f4e4db"),2.0,true)
	# Main gothic windows
	for x in [-130.0,-72.0,72.0,130.0]:
		draw_rect(Rect2(x-12,-144,24,56),Color("#635b82"))
		draw_rect(Rect2(x-8,-139,16,47),Color("#ffdba5"))
		draw_arc(Vector2(x,-139),8.0,PI,TAU,12,Color("#eee0e5"),2.0,true)
	# Grand pointed arch doorway
	draw_rect(Rect2(-42,-116,84,116),Color("#51445f"))
	draw_rect(Rect2(-34,-108,68,108),Color("#302c48"))
	draw_arc(Vector2(0,-108),34.0,PI,TAU,24,Color("#e1bdad"),4.0,true)
	draw_line(Vector2(-34,0),Vector2(-34,-108),Color("#e1bdad"),4.0,true)
	draw_line(Vector2(34,0),Vector2(34,-108),Color("#e1bdad"),4.0,true)
	for x in [-22.0,-11.0,0.0,11.0,22.0]:
		draw_line(Vector2(x,0),Vector2(x,-82),Color("#b98c78"),2.0,true)
	# Heraldic crest
	draw_colored_polygon(PackedVector2Array([Vector2(0,-178),Vector2(23,-154),Vector2(0,-130),Vector2(-23,-154)]),Color("#8c416c"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-171),Vector2(15,-154),Vector2(0,-137),Vector2(-15,-154)]),Color("#e5bf99"))
	# Buttresses and rose details
	for x in [-174.0,174.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x-18,0),Vector2(x+18,0),Vector2(x+12,-170),Vector2(x-12,-170)]),Color("#aaa1c1"))
		draw_rect(Rect2(x-22,-174,44,9),Color("#e2c5c6"))
