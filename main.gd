extends Control

const STAT_MIN := 0
const STAT_MAX := 100

const TYPE_CHAR_DELAY := 0.015
const TYPE_PUNCT_DELAY := 0.08

const STAT_TWEEN_TIME := 0.25

var typing_task_id := 0
var is_typing := false

var stats := {
	"fear": 50,
	"belief": 50,
	"power": 50,
	"economy": 50
}

var last_event_id: String = ""
var current_event: Dictionary = {}

@onready var fear_bar: TextureProgressBar = $FearBar
@onready var belief_bar: TextureProgressBar = $BeliefBar
@onready var power_bar: TextureProgressBar = $PowerBar
@onready var economy_bar: TextureProgressBar = $EconomyBar

@onready var context_text: RichTextLabel = $ContextTextSpace/RichTextLabel

@onready var button_yes: Button = $ButtonYes
@onready var button_no: Button = $ButtonNo

var stat_tweens := {}                # key: stat string -> Tween
var button_press_tweens := {}        # key: Button -> Tween

var events: Array[Dictionary] = [
	{
		"id": "need_more_cultists",
		"context": "El callejón huele a sal y herrumbre. Los nuevos rostros esperan tu gesto.",
		"a_fx": {"economy": -10, "power": +8, "fear": +4},
		"b_fx": {"economy": +6, "power": -5, "fear": -3}
	},
	{
		"id": "forbidden_ritual",
		"context": "El aire vibra con un murmullo que no es viento. Algo quiere ser invocado.",
		"a_fx": {"belief": +10, "fear": +6, "economy": -6},
		"b_fx": {"belief": -4, "fear": -2, "economy": +3, "power": +2}
	},
	{
		"id": "bribe_official",
		"context": "Un ojo humano te mira como si pudiera verte por dentro. Extiende la mano.",
		"a_fx": {"economy": -12, "fear": -2, "power": +3},
		"b_fx": {"fear": +8, "power": +6, "belief": -2}
	},
]

func _ready() -> void:
	randomize()

	button_yes.pressed.connect(func(): _on_choose("a"))
	button_no.pressed.connect(func(): _on_choose("b"))

	_setup_button_fx(button_yes)
	_setup_button_fx(button_no)

	_refresh_stats_ui()
	_load_next_event()

# -----------------------------
# Choice flow
# -----------------------------
func _on_choose(which: String) -> void:
	_set_buttons_enabled(false)

	var fx: Dictionary = current_event.get(which + "_fx", {})
	_apply_effects(fx)
	_refresh_stats_ui()

	# (Opcional) crisis
	if _any_stat_at_extreme():
		await _play_crisis_flash()
		_soft_recover_from_extremes()
		_refresh_stats_ui()

	await get_tree().create_timer(0.35).timeout
	_load_next_event()

	_set_buttons_enabled(true)

# -----------------------------
# Events
# -----------------------------
func _load_next_event() -> void:
	current_event = _pick_random_event()
	last_event_id = current_event.get("id", "")

	_type_context(current_event.get("context", ""))

func _pick_random_event() -> Dictionary:
	var e := events[randi() % events.size()]
	if e.get("id") == last_event_id and events.size() > 1:
		return _pick_random_event()
	return e

# -----------------------------
# Effects + stats UI
# -----------------------------
func _apply_effects(fx: Dictionary) -> void:
	for stat in fx.keys():
		if not stats.has(stat):
			continue
		var change := int(fx[stat])
		stats[stat] = clamp(int(stats[stat]) + change, STAT_MIN, STAT_MAX)

func _refresh_stats_ui() -> void:
	_animate_bar(fear_bar, "fear")
	_animate_bar(belief_bar, "belief")
	_animate_bar(power_bar, "power")
	_animate_bar(economy_bar, "economy")

func _animate_bar(bar: TextureProgressBar, stat_key: String) -> void:
	var target := float(stats[stat_key])

	if stat_tweens.has(stat_key) and is_instance_valid(stat_tweens[stat_key]):
		(stat_tweens[stat_key] as Tween).kill()

	var t := create_tween()
	stat_tweens[stat_key] = t
	t.tween_property(bar, "value", target, STAT_TWEEN_TIME) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

# -----------------------------
# Typewriter
# -----------------------------
func _type_context(text: String) -> void:
	typing_task_id += 1
	var my_id := typing_task_id
	is_typing = true

	context_text.clear()

	for i in text.length():
		if my_id != typing_task_id:
			return

		context_text.append_text(text[i])

		var d := TYPE_CHAR_DELAY
		var ch := text[i]
		if ch == "." or ch == "," or ch == "!" or ch == "?" or ch == ":" or ch == ";":
			d += TYPE_PUNCT_DELAY

		await get_tree().create_timer(d).timeout

	if my_id == typing_task_id:
		is_typing = false

# -----------------------------
# Button UX
# -----------------------------
func _set_buttons_enabled(enabled: bool) -> void:
	button_yes.disabled = not enabled
	button_no.disabled = not enabled

func _setup_button_fx(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(func(): _play_button_press_fx(button))

func _play_button_press_fx(button: Button) -> void:
	if button_press_tweens.has(button) and is_instance_valid(button_press_tweens[button]):
		(button_press_tweens[button] as Tween).kill()

	var t := create_tween()
	button_press_tweens[button] = t
	button.scale = Vector2.ONE
	t.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# -----------------------------
# Endless safety
# -----------------------------
func _any_stat_at_extreme() -> bool:
	for v in stats.values():
		if int(v) <= STAT_MIN or int(v) >= STAT_MAX:
			return true
	return false

func _play_crisis_flash() -> void:
	# si no lo usás, dejalo vacío así no rompe los await
	await get_tree().process_frame

func _soft_recover_from_extremes() -> void:
	for k in stats.keys():
		var v := int(stats[k])
		if v <= STAT_MIN:
			stats[k] = 10
		elif v >= STAT_MAX:
			stats[k] = 90
