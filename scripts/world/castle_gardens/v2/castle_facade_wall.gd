class_name CastleFacadeWall
extends CastlePiece
## Screen-facing curtain-wall segment. Keeps the authored two-cell isometric
## footprint, but replaces the chunky 3D brick block with a continuous facade.

@export_enum("x", "y") var orientation: String = "x"

func _draw() -> void:
    var a: Vector2
    var b: Vector2
    if orientation == "x":
        a = Vector2(-48.0, -24.0)
        b = Vector2(16.0, 8.0)
    else:
        a = Vector2(-16.0, 8.0)
        b = Vector2(48.0, -24.0)

    var top_a := a + Vector2(0.0, -112.0)
    var top_b := b + Vector2(0.0, -112.0)
    var cap_a := top_a + Vector2(0.0, -13.0)
    var cap_b := top_b + Vector2(0.0, -13.0)

    # One broad, uninterrupted stone face rather than a stack of brick-like blocks.
    draw_colored_polygon(PackedVector2Array([top_a, top_b, b, a]), Color("#777b91"))
    # Crown coping and its darker front lip.
    draw_colored_polygon(PackedVector2Array([cap_a, cap_b, top_b, top_a]), Color("#a9a9b7"))
    draw_colored_polygon(PackedVector2Array([top_a, top_b, top_b + Vector2(0, 5), top_a + Vector2(0, 5)]), Color("#555b72"))

    # One central pilaster per segment creates a regular architectural rhythm.
    # Keep segment ends flush: paired end-piers made adjacent segments read as
    # overlapping masonry blocks instead of one continuous curtain wall.
    for t in [0.50]:
        var p: Vector2 = a.lerp(b, t)
        var q := p + Vector2(0, -106)
        var w := 4.0
        draw_colored_polygon(PackedVector2Array([
            q + Vector2(-w, 0), q + Vector2(w, 0),
            p + Vector2(w, 0), p + Vector2(-w, 0)
        ]), Color("#9296a8"))
        draw_line(q + Vector2(-w, 0), p + Vector2(-w, 0), Color("#c4c1c3"), 1.5, true)
        draw_line(q + Vector2(w, 0), p + Vector2(w, 0), Color("#555c73"), 1.5, true)

    # Recessed narrow arrow slit, aligned to the camera-facing wall plane.
    var mid := a.lerp(b, 0.50)
    var slit_top := mid + Vector2(0, -82)
    var slit_bottom := mid + Vector2(0, -52)
    draw_line(slit_top, slit_bottom, Color("#292f49"), 4.0, true)
    draw_line(slit_top + Vector2(-1, 0), slit_bottom + Vector2(-1, 0), Color("#c4c1c3"), 1.0, true)

    # Continuous lower plinth and subtle stone-course seams (not individual bricks).
    draw_line(a + Vector2(0, -10), b + Vector2(0, -10), Color("#4f566d"), 4.0, true)
    draw_line(a + Vector2(0, -15), b + Vector2(0, -15), Color("#a8a4ad"), 1.5, true)
    draw_line(top_a + Vector2(0, 3), top_b + Vector2(0, 3), Color("#d1cbd0"), 2.0, true)

    # Three restrained merlons create a recognizable fortified parapet silhouette.
    for t in [0.12, 0.50, 0.88]:
        var p: Vector2 = cap_a.lerp(cap_b, t)
        var block := PackedVector2Array([
            p + Vector2(-5, 0), p + Vector2(5, 0),
            p + Vector2(5, -9), p + Vector2(-5, -9)
        ])
        draw_colored_polygon(block, Color("#9b9daf"))
        draw_polyline(PackedVector2Array([block[0], block[3], block[2], block[1]]), Color("#d0cbd1"), 1.0, true)
