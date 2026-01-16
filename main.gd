extends Control

const STAT_MIN := 0
const STAT_MAX := 100

# Cambiá esto para achicar/agrandar los iconos
const ICON_SIZE := Vector2(24, 24)

var stats := {
	"fear": 50,
	"belief": 50,
	"power": 50,
	"economy": 50
}

var last_event_id: String = ""
var current_event: Dictionary = {}

# 1 icono (TextureProgressBar) por stat
@onready var fear_bar: TextureProgressBar = $MarginContainer/Root/Stats/FearWrap/FearBar
@onready var belief_bar: TextureProgressBar = $MarginContainer/Root/Stats/BeliefWrap/BeliefBar
@onready var power_bar: TextureProgressBar = $MarginContainer/Root/Stats/PowerWrap/PowerBar
@onready var economy_bar: TextureProgressBar = $MarginContainer/Root/Stats/EconomyWrap/EconomyBar

@onready var event_text: RichTextLabel = $MarginContainer/Root/EventPanel/EventVBox/EventText
@onready var delta_text: Label = $MarginContainer/Root/EventPanel/EventVBox/DeltaText
@onready var option_a: Button = $MarginContainer/Root/EventPanel/EventVBox/Buttons/OptionA
@onready var option_b: Button = $MarginContainer/Root/EventPanel/EventVBox/Buttons/OptionB
@onready var event_panel: CanvasItem = $MarginContainer/Root/EventPanel

var events: Array[Dictionary] = [
	{
		"id": "need_more_cultists",
		"text": "Los fieles susurran:\n\"Necesitamos más cultistas en las calles.\"",
		"a_text": "Sí, reclutá como sea.",
		"a_fx": {"economy": -10, "power": +8, "fear": +4},
		"b_text": "No, mantené el perfil bajo.",
		"b_fx": {"economy": +6, "power": -5, "fear": -3}
	},
	{
		"id": "forbidden_ritual",
		"text": "Un sacerdote propone un ritual prohibido esta noche.",
		"a_text": "Hacelo. Que Cthulhu escuche.",
		"a_fx": {"belief": +10, "fear": +6, "economy": -6},
		"b_text": "No. Todavía no.",
		"b_fx": {"belief": -4, "fear": -2, "economy": +3, "power": +2}
	},
	{
		"id": "bribe_official",
		"text": "Un funcionario sabe demasiado. Pide \"un aporte\".",
		"a_text": "Pagale.",
		"a_fx": {"economy": -12, "fear": -2, "power": +3},
		"b_text": "Amenazalo.",
		"b_fx": {"fear": +8, "power": +6, "belief": -2}
	},
]

func _ready() -> void:
	randomize()

	option_a.pressed.connect(func(): _on_choose("a"))
	option_b.pressed.connect(func(): _on_choose("b"))

	# Importante: forzar layout DESPUÉS del layout inicial de containers
	call_deferred("_apply_icon_layout")

	_refresh_stats_ui()
	_load_next_event()

func _on_choose(which: String) -> void:
	_set_buttons_enabled(false)

	var fx: Dictionary = current_event.get(which + "_fx", {})
	var delta_lines := _apply_effects(fx)

	_show_delta_feedback(delta_lines)
	_refresh_stats_ui()

	if _any_stat_at_extreme():
		await _play_crisis_flash()
		_soft_recover_from_extremes()
		_refresh_stats_ui()

	await get_tree().create_timer(0.35).timeout

	_load_next_event()
	_set_buttons_enabled(true)

func _load_next_event() -> void:
	current_event = _pick_random_event()
	last_event_id = current_event.get("id", "")

	event_text.clear()
	event_text.append_text("[center]" + current_event.get("text", "") + "[/center]")

	option_a.text = current_event.get("a_text", "")
	option_b.text = current_event.get("b_text", "")

	delta_text.text = ""

func _pick_random_event() -> Dictionary:
	var e := events[randi() % events.size()]
	if e.get("id") == last_event_id and events.size() > 1:
		return _pick_random_event()
	return e

func _apply_effects(fx: Dictionary) -> Array[String]:
	var lines: Array[String] = []

	for stat in fx.keys():
		if not stats.has(stat):
			continue

		var change := int(fx[stat])
		stats[stat] = clamp(stats[stat] + change, STAT_MIN, STAT_MAX)

		var sign := "+" if change > 0 else ""
		lines.append("%s %s%d" % [stat, sign, change])

	return lines

func _refresh_stats_ui() -> void:
	fear_bar.value = stats["fear"]
	belief_bar.value = stats["belief"]
	power_bar.value = stats["power"]
	economy_bar.value = stats["economy"]

func _show_delta_feedback(lines: Array[String]) -> void:
	if lines.is_empty():
		delta_text.text = ""
		return

	delta_text.text = "Cambios: " + ", ".join(lines)

	var t := create_tween()
	delta_text.scale = Vector2.ONE
	t.tween_property(delta_text, "scale", Vector2(1.05, 1.05), 0.08)
	t.tween_property(delta_text, "scale", Vector2.ONE, 0.08)

func _set_buttons_enabled(enabled: bool) -> void:
	option_a.disabled = not enabled
	option_b.disabled = not enabled

func _any_stat_at_extreme() -> bool:
	for v in stats.values():
		if v <= STAT_MIN or v >= STAT_MAX:
			return true
	return false

func _play_crisis_flash() -> void:
	event_panel.modulate = Color.WHITE
	var t := create_tween()
	t.tween_property(event_panel, "modulate", Color(1, 0.7, 0.7), 0.08)
	t.tween_property(event_panel, "modulate", Color.WHITE, 0.12)
	await t.finished

func _soft_recover_from_extremes() -> void:
	for k in stats.keys():
		if stats[k] <= STAT_MIN:
			stats[k] = 10
		elif stats[k] >= STAT_MAX:
			stats[k] = 90
