extends Node

# 存放音效资源
var sounds = {
	"eat": preload("res://sounds/eat.mp3"),
	"death": preload("res://sounds/death.mp3")
}

func play(name: String, volume_db: float = 0.0):
	if not sounds.has(name):
		push_warning("没有找到音效: %s" % name)
		return
	var player = AudioStreamPlayer2D.new()
	player.stream = sounds[name]
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.connect("finished", Callable(player, "queue_free"))
