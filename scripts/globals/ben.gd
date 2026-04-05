extends Node

# states that affect interactions
enum States {
	ANIMATION,
	DEFAULT,
	DEFAULT_SPEAKING,
	ON_PHONE,
	NEWSPAPER,
}
# states that dont affect interactions
enum Substates {
	NONE,
	DEFAULT_HEARING,
	ON_PHONE_HEARING,
}
signal state_changed(new_state: States)
signal substate_changed(new_substate: Substates)

var state: States = States.DEFAULT:
	set(new_state):
		if state != new_state:
			state = new_state
			state_changed.emit(state)
			print("Ben.state = Ben.States.%s (%d)" % [States.keys()[new_state], new_state])
var substate: Substates = Substates.NONE:
	set(new_substate):
		if substate != new_substate:
			substate = new_substate
			substate_changed.emit(substate)
			print("Ben.substate = Ben.Substates.%s (%d)" % [Substates.keys()[new_substate], new_substate])

var is_listening: bool = true

const voice_pitch_scale: float = 0.8
