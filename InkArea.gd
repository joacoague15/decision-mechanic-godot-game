extends Area2D
signal stroke_finished

@export var brush_radius := 10
@export var brush_color := Color(0, 0, 0, 0.85)
@export var draw_only_while_pressed := true

@export var base_sprite_path: NodePath
@onready var base_sprite: Sprite2D = $"../../ContextBackground" as Sprite2D
@onready var overlay: Sprite2D = $"../InkOverlay"
@onready var col: CollisionShape2D = $CollisionShape2D

var _img: Image
var _tex: ImageTexture
var _drawing := false
var _last_local := Vector2.ZERO
var _has_stroke := false

func _ready() -> void:
	# Señales de hover
	mouse_exited.connect(_on_mouse_exited)

	_setup_canvas()
	_setup_collision()

func _setup_canvas() -> void:
	var tex := base_sprite.texture
	if tex == null:
		push_error("ContextTextSpace Sprite2D no tiene textura.")
		return

	var size := tex.get_size()
	_img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	_img.fill(Color(0,0,0,0))
	_tex = ImageTexture.create_from_image(_img)

	overlay.texture = _tex
	overlay.centered = base_sprite.centered
	overlay.offset = base_sprite.offset
	overlay.flip_h = base_sprite.flip_h
	overlay.flip_v = base_sprite.flip_v

func _setup_collision() -> void:
	var tex := base_sprite.texture
	if tex == null:
		return

	var size := tex.get_size()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	# Esto asume Sprite2D centered=true (default). Si no, avisame.
	col.position = Vector2.ZERO

func clear_ink() -> void:
	if _img == null:
		return
	_img.fill(Color(0,0,0,0))
	_tex.update(_img)
	_has_stroke = false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _img == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drawing = true
			_last_local = _mouse_local_to_sprite_local()
			_draw_dot(_last_local)
		else:
			_drawing = false

	if event is InputEventMouseMotion:
		if draw_only_while_pressed and not _drawing:
			return
		if _drawing or not draw_only_while_pressed:
			var p := _mouse_local_to_sprite_local()
			_draw_line(_last_local, p)
			_last_local = p

func _on_mouse_exited() -> void:
	_drawing = false
	_finish_stroke_if_needed()

func _finish_stroke_if_needed() -> void:
	if _has_stroke:
		emit_signal("stroke_finished")

# --- Helpers de dibujo ---

func _mouse_local_to_sprite_local() -> Vector2:
	# mouse en coords de Area2D (local) -> coords del Sprite (local)
	# Como InkArea es hijo del Sprite, y ambos comparten transform, esto suele estar ok:
	return base_sprite.to_local(get_global_mouse_position())

func _sprite_local_to_image_px(p_local: Vector2) -> Vector2i:
	# Convertimos posición local del sprite (centrado) a pixeles de la imagen
	# Para Sprite2D centered=true: (0,0) es centro. TopLeft = -size/2
	var size := base_sprite.texture.get_size()
	var top_left := -size * 0.5
	var uv := (p_local - top_left) # ahora está en rango [0..size]
	return Vector2i(int(uv.x), int(uv.y))

func _draw_dot(p_local: Vector2) -> void:
	_has_stroke = true
	_img.lock()
	var px := _sprite_local_to_image_px(p_local)
	_draw_circle(px.x, px.y, brush_radius, brush_color)
	_img.unlock()
	_tex.update(_img)

func _draw_line(a_local: Vector2, b_local: Vector2) -> void:
	_has_stroke = true
	_img.lock()
	var a := _sprite_local_to_image_px(a_local)
	var b := _sprite_local_to_image_px(b_local)

	var dist := Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y))
	var step = max(1.0, float(brush_radius) * 0.5)
	var steps := int(max(1.0, dist / step))

	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(lerp(float(a.x), float(b.x), t))
		var y := int(lerp(float(a.y), float(b.y), t))
		_draw_circle(x, y, brush_radius, brush_color)

	_img.unlock()
	_tex.update(_img)

func _draw_circle(cx: int, cy: int, r: int, col: Color) -> void:
	var w := _img.get_width()
	var h := _img.get_height()
	var r2 := r * r
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x*x + y*y <= r2:
				var px := cx + x
				var py := cy + y
				if px >= 0 and px < w and py >= 0 and py < h:
					_img.set_pixel(px, py, col)
