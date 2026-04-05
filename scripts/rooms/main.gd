extends Control

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var ben: AnimatedSprite2D = $Center/BenSprites

# default
@onready var default_speak_timer: Timer = $DefaultSpeakTimer

# phone
@onready var phone_answer_timer: Timer = $PhoneAnswerTimer
@onready var phone_drop_timer: Timer = $PhoneDropTimer

@onready var speak_frame_count: int = ben.sprite_frames.get_frame_count(&'default_speak')
## MICROPHONE INPUT
const mic_sensitivity: float = 0.8

var mic_idx: int
var mic_recorder: AudioEffectRecord
var mic_spectrum: AudioEffectSpectrumAnalyzerInstance
var mic_volume: float

var mic_is_talking: bool
var mic_has_talked: bool

var sound_spectrum: AudioEffectSpectrumAnalyzerInstance
var sound_volume: float

func _ready() -> void:
	Ben.state_changed.connect(_on_ben_state_changed)
	
	mic_idx = AudioServer.get_bus_index(&'Microphone')
	mic_recorder = AudioServer.get_bus_effect(mic_idx, 0)
	mic_spectrum = AudioServer.get_bus_effect_instance(mic_idx, 1)

	sound_spectrum = AudioServer.get_bus_effect_instance(0, 0)

	# default
	default_speak_timer.timeout.connect(_default_speak)
	# phone
	phone_answer_timer.timeout.connect(_phone_random_answer)
	phone_drop_timer.timeout.connect(_phone_drop)

func _on_ben_state_changed(new_state: Ben.States) -> void:
	mic_recorder.set_recording_active(new_state == Ben.States.DEFAULT_HEARING)

func _process(_delta: float) -> void:
	## sound volume
	var sound_vol: Vector2 = sound_spectrum.get_magnitude_for_frequency_range(0, 10000)
	sound_volume = float('%0.2f' % (max(sound_vol.x, sound_vol.y) * 100.0))
	## mic input
	if Ben.is_listening:
		var mic_vol: Vector2 = mic_spectrum.get_magnitude_for_frequency_range(0, 10000)
		mic_volume = float('%0.2f' % (max(mic_vol.x, mic_vol.y) * mic_sensitivity))

	mic_is_talking = (mic_volume > 0.0)
	match Ben.state:
		Ben.States.DEFAULT:
			if mic_is_talking:
				mic_has_talked = true
				Ben.state = Ben.States.DEFAULT_HEARING
		Ben.States.DEFAULT_HEARING:
			if mic_is_talking:
				ben.play(&'default_listen')
				default_speak_timer.start()
		Ben.States.DEFAULT_SPEAKING:
			var frame: int = int(sound_volume * 100.0)
			print(sound_volume)
			ben.frame = min(frame, speak_frame_count)
		Ben.States.ON_PHONE:
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

func _default_speak() -> void:
	ben.play(&'default_speak')
	Ben.state = Ben.States.DEFAULT_SPEAKING
	Ben.is_listening = false
	audio_player.stream = mic_recorder.get_recording()
	if audio_player.stream:
		audio_player.pitch_scale = 0.85
		audio_player.play()
		await audio_player.finished
	audio_player.pitch_scale = 1.0
	_default_reset()

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
