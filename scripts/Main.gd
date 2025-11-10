extends Node2D

@export var brick_scene: PackedScene
@export var n: int = 24
@export var spacing: float = 1
@export var move_delay: float = 0.05
@export var fade_speed_1_fix: float = 0
@export var fade_speed_2_fix: float = 0
@export var fruit_eaten_1: int = 0
@export var fruit_eaten_2: int = 0
@export var score_1: int = 0
@export var score_2: int = 0
@onready var camera : Camera2D = $Camera2D
@onready var score_label1: Label = $ScoreLabel1
@onready var score_label2: Label = $ScoreLabel2
#@onready var score_display: ScoreDisplay = $ScoreDisplay  # 节点挂在场景中

var bricks: Array = []
var direction_1: Vector2 = Vector2.RIGHT
var direction_2: Vector2 = Vector2.LEFT
var head_1: Vector2 = Vector2(0,0)
var head_2: Vector2 = Vector2(n,n)
var snake1_path: Array = []
var snake2_path: Array = []

var fruit_pos: Vector2 = Vector2(-1,-1)
var fruit_node: Brick = null

var dead := true
var flash_restart := false

func _ready():
	if not brick_scene:
		push_error("请在 Inspector 中拖入 brick.tscn")
		return

	await generate_grid_with_bounce()  # 弹跳
	await get_tree().create_timer(0.3).timeout

	head_1 = Vector2.ONE
	snake1_path.append(head_1)
	
	move_snake(1)
	move_snake(2)

# 弹跳+逐行渲染
func generate_grid_with_bounce() -> void:
	var temp = brick_scene.instantiate()
	add_child(temp)
	var brick_size = temp.rect_size if "rect_size" in temp else Vector2(40,40)
	remove_child(temp)
	temp.queue_free()

	var total_size = n * brick_size.x + (n-1) * spacing
	var start_pos = Vector2(
		(get_viewport_rect().size.x - total_size)/2,
		(get_viewport_rect().size.y - total_size)/2
	)

	for i in range(n):
		bricks.append([])
		for j in range(n):
			var brick: Brick = brick_scene.instantiate()
			add_child(brick)
			brick.add_to_group("bricks")
			brick.position = start_pos + Vector2(j*(brick_size.x+spacing), i*(brick_size.y+spacing))
			brick.set_color(Color(0,0,0))
			brick.scale = Vector2.ZERO
			bricks[i].append(brick)

		# 整行弹跳效果
		await bounce_row(i)
		await get_tree().process_frame

func bounce_row(row_idx: int) -> void:
	var row = bricks[row_idx]
	var duration = 0.25
	var elapsed = 0.0

	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t = clamp(elapsed / duration, 0, 0.9)
		for brick in row:
			var scale_t = sin(t * PI) * 0.2 + t  # 有弹跳感
			brick.scale = Vector2.ONE * scale_t
			brick.set_color(Color(t, t, t))  # 从黑到白
		await get_tree().process_frame

	for brick in row:
		brick.scale = Vector2.ONE
		brick.set_color(Color(1, 1, 1))

# 逻辑
func _process(_delta):
	
	if Input.is_action_just_pressed("ui_accept"):
		PauseManager.toggle()
	if PauseManager.paused:
		return

	var input_dir = Vector2.ZERO
	if Input.is_action_just_pressed("ui_right") and direction_1 != Vector2.LEFT:
		input_dir = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and direction_1 != Vector2.RIGHT:
		input_dir = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_down") and direction_1 != Vector2.UP:
		input_dir = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_up") and direction_1 != Vector2.DOWN:
		input_dir = Vector2.UP

	if input_dir != Vector2.ZERO:
		direction_1 = input_dir
		
	var input_dir2 = Vector2.ZERO
	if Input.is_action_just_pressed("ui_right2") and direction_2 != Vector2.LEFT:
		input_dir2 = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left2") and direction_2 != Vector2.RIGHT:
		input_dir2 = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_down2") and direction_2 != Vector2.UP:
		input_dir2 = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_up2") and direction_2 != Vector2.DOWN:
		input_dir2 = Vector2.UP

	if input_dir2 != Vector2.ZERO:
		direction_2 = input_dir2

	if dead and Input.is_action_just_pressed("restart") and not flash_restart:
		flash_restart = true
		start_flash_restart()

func spawn_fruit():
	if fruit_node:
		fruit_node.rotation_speed = 0.0
		fruit_node.set_color(Color(1,1,1))

	var valid_pos: Vector2
	while true:
		var x = randi() % n
		var y = randi() % n
		var try_node = bricks[y][x]
		if abs(try_node.rotation) > 0.001:
			continue
		valid_pos = Vector2(x, y)
		break

	fruit_pos = valid_pos
	fruit_node = bricks[fruit_pos.y][fruit_pos.x]
	fruit_node.rotation_speed = 180.0
	fruit_node.set_color(Color(0.5, 1.0, 0.5))

#func update_score():
	#score_display.show_score(fruit_eaten_1)

func move_snake(i: int):
	while true:
		var fruit_eaten = get("fruit_eaten_%d" % i)
		var head = get("head_%d" % i)
		var direction = get("direction_%d" % i)
		var snake_path = get("snake%d_path" % i)
		var fade_speed_fix = get("fade_speed_%d_fix" % i)
		var ui_speedup = ("ui_speedup_%d" % i)
		var score = get("score_%d" % (3-i))
		fade_speed_fix = log(fruit_eaten / 3 + 2)
		var timer = get_tree().create_timer(3 * move_delay * fade_speed_fix)
		if Input.is_action_pressed(ui_speedup):
			timer = get_tree().create_timer(move_delay * fade_speed_fix)
		else:
			timer = get_tree().create_timer(3 * move_delay * fade_speed_fix)
		await timer.timeout
		while PauseManager.paused:
			await get_tree().process_frame

		if dead:
			continue

		var next_head = head + direction
		if next_head.x < 0: next_head.x = n - 1
		if next_head.x >= n: next_head.x = 0
		if next_head.y < 0: next_head.y = n - 1
		if next_head.y >= n: next_head.y = 0

		var next_brick = bricks[next_head.y][next_head.x]
		if next_brick.is_rotated_45() and next_head != fruit_pos:
			dead = true
			set("score_%d" % (3-i), score + 1)
			SoundManerger.play("death")
			camera.shake(7)
			print(score)
			update_score()
			for brick in get_tree().get_nodes_in_group("bricks"):
				brick.trigger_global_flash_custom(Color(2-i, 0, i-1), 0.3, 3)
			for row in bricks:
				for brick in row:
					brick.color_strength = 0.0
					brick.target_scale = brick.base_scale
					brick.target_rotation = brick.base_rotation
					brick.rotation_speed = 0.0
					brick.set_color(Color(1, 1, 1))

		if next_head == fruit_pos:
			var fruit_brick = bricks[fruit_pos.y][fruit_pos.x]
			fruit_brick.trigger_effect()  # 播放粒子
			fruit_eaten += 1
			camera.shake(3)
			SoundManerger.play("eat")
			print("fruit_eaten_%d" % i)
			print(fruit_eaten)
			set("fruit_eaten_%d" % i, fruit_eaten)
			var speed = 4.0 / (fruit_eaten + 1)
			next_brick.fade_speed = speed
			fruit_node.rotation_speed = 0
			fruit_node.set_color(Color(1, 1, 1))
			fruit_node = null
			spawn_fruit()
		else:
			var speed = 4.0 / (fruit_eaten + 1)
			next_brick.fade_speed = speed

		if i == 1:
			next_brick.set_head_1(1.0)
		if i == 2:
			next_brick.set_head_2(1.0)

		head = next_head
		snake_path.append(head)

		set("head_%d" % i, head)
		set("snake%d_path" % i, snake_path)

func start_flash_restart() -> void:
	for brick in get_tree().get_nodes_in_group("bricks"):
		brick.trigger_global_flash_custom(Color(0.5, 1, 0.5), 0.6, 3)
	await get_tree().create_timer(2.0).timeout
	reset_game()

func update_score():
	score_label1.text = "%d" % score_2
	score_label2.text = "%d" % score_1

func reset_game() -> void:
	dead = false
	flash_restart = false
	direction_1 = Vector2.RIGHT
	direction_2 = Vector2.LEFT
	fruit_eaten_1 = 0
	fruit_eaten_2 = 0
	snake1_path.clear()
	snake2_path.clear()

	# 清空方块状态
	for row in bricks:
		for brick in row:
			brick.color_strength = 0.0
			brick.fade_speed = 1.0
			brick.rotation_speed = 0.0
			brick.target_rotation = brick.base_rotation
			brick.target_scale = brick.base_scale
			brick.set_color(Color(1,1,1))

	# 重新生成蛇和果子
	var x = randi() % n
	var y = randi() % n
	head_1 = Vector2(x,y)
	x = randi() % n
	y = randi() % n
	head_2 = Vector2(x,y)
	snake1_path.append(head_1)
	snake2_path.append(head_2)
	spawn_fruit()
	print("Player1:Player2-",score_1,":",score_2)
