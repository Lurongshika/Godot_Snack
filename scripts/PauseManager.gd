extends Node

var paused: bool = false

func toggle():
	for brick in get_tree().get_nodes_in_group("bricks"):
		brick.trigger_global_flash_custom(Color(1,0.5,0), 0.3, 1)
	paused = !paused
