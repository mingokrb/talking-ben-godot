extends Control

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var ben: AnimatedSprite2D = $Center/BenSprites

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
	

#################
 ### DEFAULT ###
#################
func _default_reset():
	anim_player.play(&'RESET')
	Ben.state = Ben.States.DEFAULT
	Ben.is_listening = true

##################
 ### ON_PHONE ###
##################
func _phone_reset() -> void:
	ben.play(&'phone_default')
	Ben.state = Ben.States.ON_PHONE
	phone_drop_timer.start()
	Ben.is_listening = true
	mic_has_talked = false

func _phone_random_answer() -> void:
	Ben.state = Ben.States.ANIMATION
	Ben.is_listening = false
	phone_drop_timer.stop()
	var answers: Array[StringName] = [ &'no', &'yes', &'laugh', &'sillyface' ]
	anim_player.play(&'phone_answer_' + answers.pick_random())
	await ben.animation_finished
	_phone_reset()

## pick up phone
func _phone_answer() -> void:
	Ben.is_listening = false
	anim_player.play(&'phone_answer')
	Ben.state = Ben.States.ANIMATION

	await anim_player.animation_finished
	_phone_reset()
## hang up phone
func _phone_drop() -> void:
	Ben.is_listening = false
	mic_has_talked = false
	ben.play(&'phone_drop')
	audio_player.stream = load('res://assets/sounds/phoneDrop.wav')
	audio_player.play(0.16)
	Ben.state = Ben.States.ANIMATION
	phone_answer_timer.stop()
	phone_drop_timer.stop()

	await ben.animation_finished
	_default_reset()
