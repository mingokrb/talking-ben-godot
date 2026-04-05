extends Control

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var ben: AnimatedSprite2D = $Center/BenSprites

@onready var speak_frame_count: int = ben.sprite_frames.get_frame_count(&'default_speak')

## TIMERS ##
# default
@onready var default_speak_timer: Timer = $DefaultSpeakTimer
# phone
@onready var phone_answer_timer: Timer = $PhoneAnswerTimer
@onready var phone_drop_timer: Timer = $PhoneDropTimer

## MICROPHONE INPUT
const mic_sensitivity: float = 5.0

var mic_idx: int
var mic_recorder: AudioEffectRecord
var mic_spectrum: AudioEffectSpectrumAnalyzerInstance
var mic_volume: float

var mic_is_talking: bool
var mic_has_talked: bool

var sound_spectrum: AudioEffectSpectrumAnalyzerInstance
var sound_pitch: AudioEffectPitchShift
var sound_volume: float

func _ready() -> void:
	Ben.substate_changed.connect(_on_ben_substate_changed)
	
	mic_idx = AudioServer.get_bus_index(&'Microphone')
	mic_recorder = AudioServer.get_bus_effect(mic_idx, 0)
	mic_spectrum = AudioServer.get_bus_effect_instance(mic_idx, 1)

	sound_spectrum = AudioServer.get_bus_effect_instance(0, 0)
	sound_pitch = AudioServer.get_bus_effect(0, 1)

	# default
	default_speak_timer.timeout.connect(_default_speak)
	# phone
	phone_answer_timer.timeout.connect(_phone_random_answer)
	phone_drop_timer.timeout.connect(_phone_drop)

func _on_ben_substate_changed(new_substate: Ben.Substates) -> void:
	mic_recorder.set_recording_active(new_substate == Ben.Substates.DEFAULT_HEARING)

func _process(_delta: float) -> void:
	## sound volume
	var sound_vol: Vector2 = sound_spectrum.get_magnitude_for_frequency_range(0, 10000)
	sound_volume = float('%0.1f' % (max(sound_vol.x, sound_vol.y) * 100.0))
	## mic input
	if Ben.is_listening:
		var mic_vol: Vector2 = mic_spectrum.get_magnitude_for_frequency_range(0, 10000)
		mic_volume = float('%0.1f' % (max(mic_vol.x, mic_vol.y) * mic_sensitivity))

	mic_is_talking = (mic_volume > 0.0)
	match Ben.state:
		Ben.States.DEFAULT:
			if mic_is_talking:
				mic_has_talked = true
				Ben.substate = Ben.Substates.DEFAULT_HEARING
		Ben.States.DEFAULT_SPEAKING:
			var vol: float = sound_volume * mic_sensitivity
			if vol > 0.0:
				ben.frame = min(int(vol), speak_frame_count)
		Ben.States.ON_PHONE:
			if mic_is_talking:
				mic_has_talked = true
				Ben.substate = Ben.Substates.ON_PHONE_HEARING

	if mic_is_talking:
		match Ben.substate:
			Ben.Substates.DEFAULT_HEARING:
				ben.play(&'default_listen')
				default_speak_timer.start()
			Ben.Substates.ON_PHONE_HEARING:
				ben.play(&'phone_listen')
				phone_answer_timer.start()
				phone_drop_timer.stop()
	

#################
 ### DEFAULT ###
#################
func _default_reset():
	_ben_reset()
	anim_player.play(&'RESET')

func _default_speak() -> void:
	ben.play(&'default_speak')
	Ben.state = Ben.States.DEFAULT_SPEAKING
	Ben.substate = Ben.Substates.NONE
	Ben.is_listening = false
	audio_player.stream = mic_recorder.get_recording()
	if audio_player.stream:
		sound_pitch.pitch_scale = Ben.voice_pitch_scale
		audio_player.pitch_scale = 0.9
		audio_player.play()
		await audio_player.finished
	sound_pitch.pitch_scale = 1.0
	audio_player.pitch_scale = 1.0
	_default_reset()

##################
 ### ON_PHONE ###
##################
func _phone_reset() -> void:
	_ben_reset()
	ben.play(&'phone_default')
	Ben.state = Ben.States.ON_PHONE
	phone_drop_timer.start()

func _phone_random_answer() -> void:
	Ben.state = Ben.States.ANIMATION
	Ben.substate = Ben.Substates.NONE
	Ben.is_listening = false
	phone_drop_timer.stop()
	var answers: Array[StringName] = [ &'no', &'yes', &'laugh', &'sillyface' ]
	anim_player.play(&'phone_answer_' + answers.pick_random())
	await ben.animation_finished
	_phone_reset()

## pick up phone
func _phone_answer() -> void:
	_ben_reset()
	Ben.is_listening = false
	Ben.state = Ben.States.ANIMATION
	anim_player.play(&'phone_answer')

	await anim_player.animation_finished
	_phone_reset()
## hang up phone
func _phone_drop() -> void:
	_ben_reset()
	Ben.is_listening = false
	Ben.state = Ben.States.ANIMATION
	ben.play(&'phone_drop')
	audio_player.stream = load('res://assets/sounds/phoneDrop.wav')
	audio_player.play(0.16)
	phone_answer_timer.stop()
	phone_drop_timer.stop()

	await ben.animation_finished
	_default_reset()

###########
### BEN ###
###########
func _ben_reset() -> void:
	Ben.state = Ben.States.DEFAULT
	Ben.substate = Ben.Substates.NONE
	Ben.is_listening = true
	mic_has_talked = false
	sound_pitch.pitch_scale = 1.0

	# stop timers
	for child: Node in get_children(true):
		if child is Timer:
			child.stop()
