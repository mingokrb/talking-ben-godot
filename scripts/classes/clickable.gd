@tool
extends Button
class_name Clickable

## Ben animation to play
@export var animation: StringName
@export var audio: AudioStreamWAV

@onready var audio_player: AudioStreamPlayer = get_tree().get_first_node_in_group(&'audioplayer')
@onready var anim_player: AnimationPlayer = get_tree().get_first_node_in_group(&'animationplayer')
@onready var ben: AnimatedSprite2D = get_tree().get_first_node_in_group(&'ben')
@onready var enabled_on_state: StringName = get_parent().name

func _ready() -> void:
	if anim_player or ben:
		button_up.connect(_pressed)
	Ben.state_changed.connect(_on_ben_state_changed)

func _pressed() -> void:
	# animation player
	if anim_player and anim_player.has_animation(animation):
		anim_player.play(animation)
	# other ben anims
	elif ben and ben.sprite_frames.has_animation(animation):
		ben.play(animation)

func _on_ben_state_changed(new_state: Ben.States) -> void:
	var enable: bool = (new_state == Ben.States[enabled_on_state])
	visible = enable
	disabled = not enable
