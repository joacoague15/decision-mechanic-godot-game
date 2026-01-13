extends Node2D

const MIN_STAT := 0
const MAX_STAT := 100
const STARTING_VALUE := 50
const DEFAULT_PORTRAIT := preload("res://economia.png")
const PORTRAIT_SHADOW_ALPHA := 0.35
const STAT_DISPLAY_NAMES := {
	"militar": "Militar",
	"social": "Social",
	"religion": "Religión",
	"economia": "Economía"
}
const ADVISORS := {
	"militar": {
		"name": "General Aldana",
		"portrait": "res://militar.png"
	},
	"social": {
		"name": "Maestra de Fiestas Iara",
		"portrait": "res://sociedad.png"
	},
	"religion": {
		"name": "Prior Lucio",
		"portrait": "res://religion.png"
	},
	"economia": {
		"name": "Gremial Galian",
		"portrait": "res://economia.png"
	}
}

const EVENT_POOL := [
	{
		"id": "militar_refuerzos",
		"advisor": "militar",
		"dialogue": "Necesitamos más arqueros para defender las murallas orientales. Sin refuerzos la frontera caerá.",
		"options": [
			{
				"label": "Organizar una leva extraordinaria",
				"consequence": "Los jóvenes se entrenan sin descanso mientras la armería echa humo.",
				"effects": {"militar": 12, "economia": -8, "social": -3}
			},
			{
				"label": "Confiar en las tropas actuales",
				"consequence": "La corte respira tranquila, pero los capitanes murmuran sobre debilidad.",
				"effects": {"militar": -10, "economia": 5, "social": 3}
			}
		]
	},
	{
		"id": "militar_astillero",
		"advisor": "militar",
		"dialogue": "Nuestros navíos envejecen. Un astillero moderno garantizaría la supremacía naval.",
		"options": [
			{
				"label": "Construir el astillero real",
				"consequence": "Las olas retumban con nuevos cascos de guerra.",
				"effects": {"militar": 10, "economia": -7}
			},
			{
				"label": "Ceder la ampliación a los comerciantes",
				"consequence": "Los empresarios controlan las gradas y reclaman protagonismo.",
				"effects": {"economia": 9, "militar": -5, "social": 2}
			}
		]
	},
	{
		"id": "militar_murallas",
		"advisor": "militar",
		"dialogue": "Las murallas interiores agrietan. Repararlas implica cerrar barrios enteros.",
		"options": [
			{
				"label": "Reforzar de inmediato",
				"consequence": "La capital se vuelve un taller gigante, pero quedará segura.",
				"effects": {"militar": 8, "economia": -5, "social": -4}
			},
			{
				"label": "Posponer hasta el invierno",
				"consequence": "Ahorro temporal, riesgo permanente.",
				"effects": {"economia": 6, "militar": -9}
			}
		]
	},
	{
		"id": "militar_conspiracion",
		"advisor": "militar",
		"dialogue": "Tenemos pruebas de conspiraciones nobles. Un golpe preventivo consolidaría tu poder.",
		"options": [
			{
				"label": "Arrestar a los sospechosos",
				"consequence": "El miedo mantiene unido al consejo.",
				"effects": {"militar": 5, "social": -7, "economia": -3}
			},
			{
				"label": "Negociar con favores",
				"consequence": "Pactas influencias y evitas derramamiento de sangre.",
				"effects": {"social": 6, "economia": -4, "militar": -3}
			}
		]
	},
	{
		"id": "social_festival",
		"advisor": "social",
		"dialogue": "El pueblo necesita un festival para olvidar las penurias. ¿Autorizamos el gasto?",
		"options": [
			{
				"label": "Celebrar la semana completa",
				"consequence": "Las plazas cantan, la lealtad popular se fortalece.",
				"effects": {"social": 12, "economia": -6, "religion": -2}
			},
			{
				"label": "Solo vigilias austeras",
				"consequence": "Los clérigos aplauden, pero la esperanza del pueblo se enfría.",
				"effects": {"religion": 8, "social": -10}
			}
		]
	},
	{
		"id": "social_guardabosques",
		"advisor": "social",
		"dialogue": "Los nobles quieren desmontar bosques para sembrar lino. Las aldeas temen perder caza y agua.",
		"options": [
			{
				"label": "Autorizar el desmonte",
				"consequence": "La nobleza paga nuevos impuestos, pero el campo se resiente.",
				"effects": {"economia": 8, "social": -5, "religion": -3}
			},
			{
				"label": "Declarar reserva sagrada",
				"consequence": "Los druidas bendicen, los nobles gruñen.",
				"effects": {"religion": 7, "economia": -4, "social": 3}
			}
		]
	},
	{
		"id": "social_graneros",
		"advisor": "social",
		"dialogue": "Las reservas de grano están llenas, pero los ratones acechan. Sugiere abrir los graneros al pueblo.",
		"options": [
			{
				"label": "Distribuir grano inmediatamente",
				"consequence": "La hambruna se aplaza y los aldeanos juran fidelidad.",
				"effects": {"social": 10, "economia": -5}
			},
			{
				"label": "Aumentar la guardia y vender más caro",
				"consequence": "El tesoro crece mientras las quejas hierven.",
				"effects": {"economia": 10, "social": -8, "militar": 2}
			}
		]
	},
	{
		"id": "religion_santuario",
		"advisor": "religion",
		"dialogue": "Los peregrinos exigen fondos para restaurar el gran santuario del oeste.",
		"options": [
			{
				"label": "Financiar la restauración completa",
				"consequence": "Los mosaicos brillan y los sermones se multiplican.",
				"effects": {"religion": 14, "economia": -9}
			},
			{
				"label": "Solicitar donaciones privadas",
				"consequence": "Los fieles se organizan, pero cuestionan tu compromiso.",
				"effects": {"religion": -6, "economia": 5, "social": -2}
			}
		]
	},
	{
		"id": "religion_inquisicion",
		"advisor": "religion",
		"dialogue": "Las incursiones de brujos provocan miedo. Propongo tribunales especiales.",
		"options": [
			{
				"label": "Autorizar la inquisición",
				"consequence": "Los sermones celebran la pureza, pero cunde el temor.",
				"effects": {"religion": 10, "social": -9}
			},
			{
				"label": "Proteger la libertad de culto",
				"consequence": "Las minorías respiran, aunque el clero resopla.",
				"effects": {"social": 8, "religion": -7}
			}
		]
	},
	{
		"id": "religion_ayuno",
		"advisor": "religion",
		"dialogue": "Una tormenta hundió barcos cargados de diezmos. Sugiere declarar ayuno nacional.",
		"options": [
			{
				"label": "Ordenar el ayuno",
				"consequence": "La fe se renueva, aunque la moral cae.",
				"effects": {"religion": 11, "social": -4, "economia": -3}
			},
			{
				"label": "Reemplazar los bienes con fondos reales",
				"consequence": "Reinas con generosidad y compras voluntades.",
				"effects": {"economia": -8, "social": 6}
			}
		]
	},
	{
		"id": "economia_aranceles",
		"advisor": "economia",
		"dialogue": "Los gremios proponen abrir rutas con reinos lejanos si se reducen ciertos impuestos.",
		"options": [
			{
				"label": "Reducir aranceles",
				"consequence": "Las caravanas vuelven cargadas y el tesoro se diversifica.",
				"effects": {"economia": 12, "militar": -4}
			},
			{
				"label": "Mantener los tributos",
				"consequence": "La riqueza permanece estable, pero el comercio languidece.",
				"effects": {"economia": -6, "social": -3, "religion": 2}
			}
		]
	},
	{
		"id": "economia_prensas",
		"advisor": "economia",
		"dialogue": "Los reinos vecinos imprimen leyes en prensas móviles. Si financiamos talleres, nuestra burocracia volará.",
		"options": [
			{
				"label": "Financiar los talleres de impresión",
				"consequence": "El conocimiento se multiplica y la burocracia se agiliza.",
				"effects": {"economia": 5, "social": 9, "religion": -4}
			},
			{
				"label": "Mantener los códices manuscritos",
				"consequence": "Los escribas mantienen su influencia tradicional.",
				"effects": {"religion": 4, "social": -6}
			}
		]
	},
	{
		"id": "economia_reforma",
		"advisor": "economia",
		"dialogue": "Los gremios piden simplificar los impuestos y cobrar en moneda fuerte para evitar el fraude.",
		"options": [
			{
				"label": "Aplicar la reforma monetaria",
				"consequence": "El tesoro gana claridad y control absoluto.",
				"effects": {"economia": 11, "social": -5, "religion": -2}
			},
			{
				"label": "Preservar el sistema tradicional",
				"consequence": "Los barrios celebran la continuidad, aunque dejamos pasar ingresos.",
				"effects": {"economia": -7, "social": 4, "religion": 3}
			}
		]
	}
]

var stats := {}
var upcoming_events : Array = []
var current_event : Dictionary = {}
var is_game_over := false
var rng := RandomNumberGenerator.new()
var portrait_tween : Tween
var event_panel_tween : Tween
var status_tween : Tween
var dialogue_tween : Tween
var stat_tweens : Dictionary = {}
var button_tweens : Dictionary = {}
var has_presented_event := false
var event_base_position := Vector2.ZERO
var last_advisor_key := ""
var advisor_repeat_count := 0

@onready var speaker_label : Label = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox/DialogueBox/SpeakerLabel
@onready var dialogue_label : RichTextLabel = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox/DialogueBox/DialogueLabel
@onready var portrait_shadow : TextureRect = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox/PortraitContainer/Shadow
@onready var portrait_rect : TextureRect = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox/PortraitContainer/Portrait
@onready var status_label : Label = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox/StatusLabel
@onready var event_vbox : VBoxContainer = $CanvasLayer/UI/MarginContainer/PanelContainer/VBoxContainer/EventPanel/EventVBox
@onready var option_buttons : Array[Button] = [
	$CanvasLayer/UI/ChoicesOverlay/PanelContainer/ButtonsRow/OptionA,
	$CanvasLayer/UI/ChoicesOverlay/PanelContainer/ButtonsRow/OptionB
]
@onready var stat_bars := {
	"militar": $CanvasLayer/UI/StatsOverlay/PanelContainer/StatsRow/MilitaryStat/ProgressBar,
	"social": $CanvasLayer/UI/StatsOverlay/PanelContainer/StatsRow/SocialStat/ProgressBar,
	"religion": $CanvasLayer/UI/StatsOverlay/PanelContainer/StatsRow/ReligionStat/ProgressBar,
	"economia": $CanvasLayer/UI/StatsOverlay/PanelContainer/StatsRow/EconomyStat/ProgressBar
}

func _ready() -> void:
	rng.randomize()
	_connect_buttons()
	event_base_position = event_vbox.position
	event_vbox.modulate = Color(1, 1, 1, 1)
	_reset_game()

func _connect_buttons() -> void:
	for index in option_buttons.size():
		var button := option_buttons[index]
		button.scale = Vector2.ONE
		button.pressed.connect(_on_option_selected.bind(index))
		button.mouse_entered.connect(_on_button_hover.bind(button, true))
		button.mouse_exited.connect(_on_button_hover.bind(button, false))

func _reset_game() -> void:
	if portrait_tween:
		portrait_tween.kill()
	if event_panel_tween:
		event_panel_tween.kill()
	if status_tween:
		status_tween.kill()
	for stat_key in stat_tweens.keys():
		if stat_tweens[stat_key]:
			stat_tweens[stat_key].kill()
	stat_tweens.clear()
	for button_tween in button_tweens.values():
		if button_tween:
			button_tween.kill()
	button_tweens.clear()
	if dialogue_tween:
		dialogue_tween.kill()
	stats.clear()
	for stat_key in STAT_DISPLAY_NAMES.keys():
		stats[stat_key] = STARTING_VALUE
	for stat_key in stat_bars.keys():
		var bar : ProgressBar = stat_bars[stat_key]
		bar.value = STARTING_VALUE
	upcoming_events = EVENT_POOL.duplicate(true)
	upcoming_events.shuffle()
	current_event.clear()
	is_game_over = false
	status_label.text = ""
	status_label.modulate = Color(1, 1, 1, 1)
	dialogue_label.text = ""
	dialogue_label.visible_ratio = 1.0
	portrait_rect.texture = DEFAULT_PORTRAIT
	portrait_rect.modulate = Color(1, 1, 1, 1)
	portrait_shadow.modulate = Color(0, 0, 0, PORTRAIT_SHADOW_ALPHA)
	portrait_shadow.texture = DEFAULT_PORTRAIT
	event_vbox.modulate = Color(1, 1, 1, 1)
	event_vbox.position = event_base_position
	has_presented_event = false
	last_advisor_key = ""
	advisor_repeat_count = 0
	for button in option_buttons:
		button.scale = Vector2.ONE
	_set_button_texts(["Decidir", "Decidir"])
	_update_stats_ui()
	_show_next_event()

func _show_next_event() -> void:
	if upcoming_events.is_empty():
		upcoming_events = EVENT_POOL.duplicate(true)
		upcoming_events.shuffle()
	current_event = _pick_next_event()
	_update_advisor_streak(current_event)
	_display_event(current_event)

func _pick_next_event() -> Dictionary:
	if upcoming_events.is_empty():
		return {}
	if last_advisor_key != "" and advisor_repeat_count >= 2:
		var index := _find_alternative_event_index()
		if index == -1:
			upcoming_events = EVENT_POOL.duplicate(true)
			upcoming_events.shuffle()
			index = _find_alternative_event_index()
		if index != -1:
			var candidate : Dictionary = upcoming_events[index]
			upcoming_events.remove_at(index)
			return candidate
	return upcoming_events.pop_back()

func _find_alternative_event_index() -> int:
	for i in range(upcoming_events.size() - 1, -1, -1):
		var candidate : Dictionary = upcoming_events[i]
		if candidate.get("advisor", "") != last_advisor_key:
			return i
	return -1

func _update_advisor_streak(event_data: Dictionary) -> void:
	var advisor_key : String = event_data.get("advisor", "")
	if advisor_key == "":
		last_advisor_key = ""
		advisor_repeat_count = 0
		return
	if advisor_key == last_advisor_key:
		advisor_repeat_count += 1
	else:
		last_advisor_key = advisor_key
		advisor_repeat_count = 1

func _display_event(event_data: Dictionary) -> void:
	_animate_event_panel(event_data)

func _animate_event_panel(event_data: Dictionary) -> void:
	if not has_presented_event:
		_populate_event_fields(event_data)
		has_presented_event = true
		_intro_event_panel()
		return
	if event_panel_tween:
		event_panel_tween.kill()
	event_panel_tween = create_tween()
	event_panel_tween.tween_property(event_vbox, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	event_panel_tween.parallel().tween_property(event_vbox, "position:y", event_base_position.y + 20.0, 0.12).set_trans(Tween.TRANS_SINE)
	event_panel_tween.tween_callback(Callable(self, "_on_event_panel_swap").bind(event_data))
	event_panel_tween.tween_property(event_vbox, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	event_panel_tween.parallel().tween_property(event_vbox, "position:y", event_base_position.y, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _intro_event_panel() -> void:
	event_vbox.modulate = Color(1, 1, 1, 0)
	event_vbox.position = event_base_position + Vector2(0, 20)
	var intro_tween := create_tween()
	intro_tween.tween_property(event_vbox, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.parallel().tween_property(event_vbox, "position:y", event_base_position.y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_event_panel_swap(event_data: Dictionary) -> void:
	_populate_event_fields(event_data)
	event_vbox.position = event_base_position + Vector2(0, 16)

func _populate_event_fields(event_data: Dictionary) -> void:
	var advisor_key : String = event_data.get("advisor", "")
	var advisor_data : Dictionary = {}
	if ADVISORS.has(advisor_key):
		advisor_data = ADVISORS[advisor_key]
	var speaker_name : String = advisor_data.get("name", event_data.get("name", "Consejo Real"))
	speaker_label.text = speaker_name
	var dialogue_text : String = event_data.get("dialogue", "")
	var portrait_path : String = advisor_data.get("portrait", event_data.get("portrait", ""))
	var texture : Texture2D = DEFAULT_PORTRAIT
	if portrait_path != "":
		if ResourceLoader.exists(portrait_path):
			var loaded_texture := load(portrait_path)
			if loaded_texture is Texture2D:
				texture = loaded_texture
	_transition_portrait(texture)
	_play_dialogue(dialogue_text)
	var options : Array = event_data.get("options", [])
	for i in option_buttons.size():
		var button : Button = option_buttons[i]
		if i < options.size():
			button.disabled = false
			button.text = options[i].get("label", "Elegir")
		else:
			button.disabled = true
			button.text = "Sin opción"

func _on_option_selected(index: int) -> void:
	if is_game_over:
		_reset_game()
		return
	if current_event.is_empty():
		return
	var options : Array = current_event.get("options", [])
	if index >= options.size():
		return
	_resolve_option(options[index])

func _on_button_hover(button: Button, is_hovered: bool) -> void:
	if button_tweens.has(button):
		if button_tweens[button]:
			button_tweens[button].kill()
	var tween := create_tween()
	button_tweens[button] = tween
	var target_scale := Vector2.ONE
	if is_hovered:
		target_scale = Vector2(1.035, 1.035)
	tween.tween_property(button, "scale", target_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _transition_portrait(texture: Texture2D) -> void:
	if portrait_tween:
		portrait_tween.kill()
	var is_same_texture := portrait_rect.texture == texture and portrait_rect.texture != null
	if is_same_texture:
		portrait_rect.modulate = Color(1, 1, 1, 1)
		portrait_shadow.modulate = Color(0, 0, 0, PORTRAIT_SHADOW_ALPHA)
		portrait_shadow.texture = texture
		return
	if portrait_rect.texture == null:
		portrait_rect.texture = texture
		portrait_shadow.texture = texture
		portrait_rect.modulate = Color(1, 1, 1, 1)
		portrait_shadow.modulate = Color(0, 0, 0, PORTRAIT_SHADOW_ALPHA)
		return
	portrait_tween = create_tween()
	portrait_tween.tween_property(portrait_rect, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	portrait_tween.parallel().tween_property(portrait_shadow, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	portrait_tween.tween_callback(Callable(self, "_on_portrait_fade_switch").bind(texture))
	portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	portrait_tween.parallel().tween_property(portrait_shadow, "modulate:a", PORTRAIT_SHADOW_ALPHA, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_portrait_fade_switch(texture: Texture2D) -> void:
	portrait_rect.texture = texture
	portrait_shadow.texture = texture

func _play_dialogue(text: String) -> void:
	if dialogue_tween:
		dialogue_tween.kill()
	if text == "":
		dialogue_label.text = ""
		dialogue_label.visible_ratio = 1.0
		return
	dialogue_label.text = text
	dialogue_label.visible_ratio = 0.0
	var duration = clamp(text.length() * 0.03, 0.25, 2.0)
	dialogue_tween = create_tween()
	dialogue_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _resolve_option(option_data: Dictionary) -> void:
	var effects : Dictionary = option_data.get("effects", {})
	for stat_key in effects.keys():
		if not stats.has(stat_key):
			continue
		var delta = effects[stat_key]
		stats[stat_key] = clamp(stats[stat_key] + delta, MIN_STAT, MAX_STAT)
	var summary := _build_effect_summary(effects)
	var consequence : String = option_data.get("consequence", "")
	var parts : Array[String] = []
	if consequence != "":
		parts.append(consequence)
	if summary != "":
		parts.append(summary)
	_update_stats_ui()
	_animate_status_text("\n".join(parts))
	_check_end_conditions()
	if not is_game_over:
		_show_next_event()

func _animate_status_text(new_text: String) -> void:
	if status_tween:
		status_tween.kill()
	if new_text == "":
		status_label.text = ""
		status_label.modulate = Color(1, 1, 1, 0)
		return
	if status_label.text == "":
		status_label.text = new_text
		status_label.modulate = Color(1, 1, 1, 0)
		status_tween = create_tween()
		status_tween.tween_property(status_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return
	status_tween = create_tween()
	status_tween.tween_property(status_label, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	status_tween.tween_callback(Callable(self, "_on_status_text_swap").bind(new_text))
	status_tween.tween_property(status_label, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_status_text_swap(new_text: String) -> void:
	status_label.text = new_text

func _build_effect_summary(effects: Dictionary) -> String:
	var parts : Array[String] = []
	for stat_key in STAT_DISPLAY_NAMES.keys():
		if not effects.has(stat_key):
			continue
		var delta_value : int = effects[stat_key]
		if delta_value == 0:
			continue
		var prefix := ""
		if delta_value > 0:
			prefix = "+"
		else:
			prefix = ""
		var stat_name : String = STAT_DISPLAY_NAMES[stat_key]
		parts.append("%s%d %s" % [prefix, delta_value, stat_name])
	return ", ".join(parts)

func _update_stats_ui() -> void:
	for stat_key in stats.keys():
		if not stat_bars.has(stat_key):
			continue
		var bar : ProgressBar = stat_bars[stat_key]
		var target_value : int = stats[stat_key]
		if is_equal_approx(bar.value, target_value):
			continue
		if stat_tweens.has(stat_key):
			if stat_tweens[stat_key]:
				stat_tweens[stat_key].kill()
		var tween := create_tween()
		stat_tweens[stat_key] = tween
		tween.tween_property(bar, "value", target_value, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_on_stat_tween_finished.bind(stat_key))

func _on_stat_tween_finished(stat_key: String) -> void:
	stat_tweens[stat_key] = null

func _check_end_conditions() -> void:
	for stat_key in stats.keys():
		var value : int = stats[stat_key]
		if value <= MIN_STAT:
			_trigger_game_over("El poder %s colapsa y el reino cae en caos." % STAT_DISPLAY_NAMES[stat_key])
			return
		if value >= MAX_STAT:
			_trigger_game_over("El equilibrio se rompe: el aspecto %s domina sobre todo." % STAT_DISPLAY_NAMES[stat_key])
			return

func _trigger_game_over(message: String) -> void:
	is_game_over = true
	if status_tween:
		status_tween.kill()
	status_label.modulate = Color(1, 1, 1, 1)
	speaker_label.text = "Crónicas"
	dialogue_label.text = "Fin de reinado"
	status_label.text = "%s\nPulsa cualquier opción para reiniciar." % message
	_set_button_texts(["Comenzar de nuevo", "Volver a intentarlo"])
	current_event.clear()

func _set_button_texts(texts: Array[String]) -> void:
	for i in option_buttons.size():
		var button : Button = option_buttons[i]
		if i < texts.size():
			button.text = texts[i]
		else:
			button.text = "..."
