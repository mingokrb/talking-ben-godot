extends Control

@onready var anim_player = $AnimationPlayer
@onready var ben = $Center/BenSprites

@onready var phone_answer_timer: Timer = $PhoneAnswerTimer
@onready var phone_drop_timer: Timer = $PhoneDropTimer

## MICROPHONE INPUT
const mic_sensitivity: float = 0.8

var mic_idx: int
var mic_spectrum: AudioEffectSpectrumAnalyzerInstance
var mic_volume: float

var mic_is_talking: bool
var mic_has_talked: bool

func _ready() -> void:
	mic_idx = AudioServer.get_bus_index(&'Microphone')
	mic_spectrum = AudioServer.get_bus_effect_instance(mic_idx, 1)

	ben.animation_finished.connect(_ben_anim_finished.bind(ben.animation))
	phone_answer_timer.timeout.connect(_phone_random_answer)
	phone_drop_timer.timeout.connect(_phone_drop)

func _process(_delta: float) -> void:
	## mic input
	if not Ben.is_listening: return
	var vol: Vector2 = mic_spectrum.get_magnitude_for_frequency_range(0, 10000)
	mic_volume = float('%0.2f' % (max(vol.x, vol.y) * mic_sensitivity))

	match Ben.state:
		Ben.States.ON_PHONE:
			mic_is_talking = (mic_volume > 0.0)
			if mic_is_talking:
				mic_has_talked = true
				phone_answer_timer.start()
				phone_drop_timer.stop()

func _ben_anim_finished(_anim: StringName) -> void:
	pass

func _phone_reset() -> void:
	ben.play(&'phone_default')
	Ben.state = Ben.States.ON_PHONE
	phone_drop_timer.start()
	Ben.is_listening = true
	mic_has_talked = false

func _phone_random_answer() -> void:
	Ben.is_listening = false
	phone_drop_timer.stop()
	var answers: Array[StringName] = [ &'no', &'yes', &'laugh', &'sillyface' ]
	anim_player.play(&'phone_answer_' + answers.pick_random())
	await ben.animation_finished
	_phone_reset()

func _phone_drop() -> void:
	Ben.is_listening = false
	mic_has_talked = false
	anim_player.play(&'phone_drop')
	Ben.state = Ben.States.DEFAULT
	await ben.animation_finished
	ben.play(&'default')
	Ben.is_listening = true
