extends Node2D

@export var brick_scene: PackedScene
@export var n: int = 30
@export var spacing: float = 1
@export var move_delay: float = 0.05
@onready var score_display: ScoreDisplay = $ScoreDisplay  # 节点挂在场景中

var bricks: Array = []
var direction: Vector2 = Vector2.RIGHT
var head: Vector2 = Vector2.ZERO
var snake_path: Array = []

var fruit_pos: Vector2 = Vector2(-1,-1)
var fruit_node: Brick = null
var fruit_eaten: int = 0

var dead := false
var flash_restart := false

func _ready():
	if not brick_scene:
		push_error("请在 Inspector 中拖入 brick.tscn")
		return

	await generate_grid_with_bounce()  # ✅ 弹跳感生成
	await get_tree().create_timer(0.3).timeout

	head = Vector2(n/2, n/2)
	snake_path.append(head)
	spawn_fruit()
	move_snake()

# ✅ 弹跳+逐行渲染
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
		var t = clamp(elapsed / duration, 0, 1)
		for brick in row:
			var scale_t = sin(t * PI) * 0.2 + t  # 有弹跳感
			brick.scale = Vector2.ONE * scale_t
			brick.set_color(Color(t, t, t))  # 从黑到白
		await get_tree().process_frame

	for brick in row:
		brick.scale = Vector2.ONE
		brick.set_color(Color(1, 1, 1))

# 后面逻辑都不动 ↓
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		PauseManager.toggle()
	if PauseManager.paused:
		return

	var input_dir = Vector2.ZERO
	if Input.is_action_just_pressed("ui_right") and direction != Vector2.LEFT:
		input_dir = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2.RIGHT:
		input_dir = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2.UP:
		input_dir = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_up") and direction != Vector2.DOWN:
		input_dir = Vector2.UP

	if input_dir != Vector2.ZERO:
		direction = input_dir

	if dead and Input.is_action_just_pressed("restart") and not flash_restart:
		flash_restart = true
		start_flash_restart()

func spawn_fruit():
	if fruit_node:
		fruit_node.rotation_speed = 0.0
		fruit_node.set_color(Color(1, 1, 1))

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

func update_score():
	score_display.show_score(fruit_eaten)

func move_snake() -> void:
	while true:
		var timer = get_tree().create_timer(move_delay)
		await timer.timeout
		while PauseManager.paused:
			await get_tree().process_frame

		if dead:
			continue

		var next_head = head + direction
		if next_head.x < 0: next_head.x = n-1
		if next_head.x >= n: next_head.x = 0
		if next_head.y < 0: next_head.y = n-1
		if next_head.y >= n: next_head.y = 0

		var next_brick = bricks[next_head.y][next_head.x]
		if next_brick.is_rotated_45() and next_head != fruit_pos:
			dead = true
			for brick in get_tree().get_nodes_in_group("bricks"):
				brick.trigger_global_flash_custom(Color(1,0,0), 0.3, 3)
			for row in bricks:
				for brick in row:
					brick.blue_strength = 0.0
					brick.target_scale = brick.base_scale
					brick.target_rotation = brick.base_rotation
					brick.rotation_speed = 0.0
					brick.set_color(Color(1,1,1))
			continue

		#吃果子
		if next_head == fruit_pos:
			fruit_eaten += 1
			var speed = 12.0 / (fruit_eaten + 1)
			next_brick.fade_speed = speed
			fruit_node.rotation_speed = 0
			fruit_node.set_color(Color(1,1,1))
			fruit_node = null
			spawn_fruit()
			#update_score()
		else:
			var speed = 12.0 / (fruit_eaten + 1)
			next_brick.fade_speed = speed

		next_brick.set_blue(1.0)
		head = next_head
		snake_path.append(head)

func start_flash_restart() -> void:
	for brick in get_tree().get_nodes_in_group("bricks"):
		brick.trigger_global_flash_custom(Color(0.5, 1, 0.5), 0.6, 3)
	await get_tree().create_timer(2.0).timeout
	reset_game()

func reset_game() -> void:
	dead = false
	flash_restart = false
	direction = Vector2.RIGHT
	fruit_eaten = 0
	snake_path.clear()

	# 清空方块状态
	for row in bricks:
		for brick in row:
			brick.blue_strength = 0.0
			brick.fade_speed = 1.0
			brick.rotation_speed = 0.0
			brick.target_rotation = brick.base_rotation
			brick.target_scale = brick.base_scale
			brick.set_color(Color(1,1,1))

	# 重新生成蛇和果子
	head = Vector2(n/2, n/2)
	snake_path.append(head)
	spawn_fruit()
