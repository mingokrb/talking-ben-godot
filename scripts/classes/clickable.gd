@tool
extends Button
class_name Clickable

## Room callable to call or Ben animation to play
@export var calling: StringName = &''
@export var audio: AudioStreamWAV

@onready var room: Control = get_tree().get_first_node_in_group(&'room')
@onready var audio_player: AudioStreamPlayer = get_tree().get_first_node_in_group(&'audioplayer')
@onready var anim_player: AnimationPlayer = get_tree().get_first_node_in_group(&'animationplayer')
@onready var ben: AnimatedSprite2D = get_tree().get_first_node_in_group(&'ben')
@onready var enabled_on_state: StringName = get_parent().name

func _ready() -> void:
	if anim_player or ben:
		button_up.connect(_pressed)
	Ben.state_changed.connect(_on_ben_state_changed)
	_on_ben_state_changed(Ben.state)

func _pressed() -> void:
	# callable
	if room.get(calling):
		room.call(calling)
	# animation player
	elif anim_player and anim_player.has_animation(calling):
		anim_player.play(calling)
	# other ben anims
	elif ben and ben.sprite_frames.has_animation(calling):
		ben.play(calling)

func _on_ben_state_changed(new_state: Ben.States) -> void:
	var enable: bool = (new_state == Ben.States[enabled_on_state])
	get_parent().visible = enable
	disabled = not enable
