extends Node

enum States {
	ANIMATION,
	DEFAULT,
	ON_PHONE,
	NEWSPAPER,
}
signal state_changed(new_state: States)

var state: States = States.DEFAULT:
	set(new_state):
		if state != new_state:
			state = new_state
			state_changed.emit(state)

var is_listening: bool = true
