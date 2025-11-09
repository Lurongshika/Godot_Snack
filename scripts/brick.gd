extends CharacterBody2D
class_name Brick

@onready var sprite: Sprite2D = $Sprite2D
@onready var main = get_node("/root/MainGame")
var mat: ShaderMaterial
var blue_strength: float = 0.0
var fade_speed: float = 1.0  # 蓝色褪色速度

# 缩放与旋转
var base_scale: Vector2 = Vector2.ONE
var base_rotation: float = 0.0
var target_scale: Vector2 = Vector2.ONE
var target_rotation: float = 0.0
var rotation_speed: float = 0.0  # 果子旋转速度
var scale_speed: float = 5.0
var rotation_interp_speed: float = 5.0

# 闪烁逻辑
var flashing: bool = false
var flash_timer: float = 0.0
var flash_duration: float = 0.3
var flash_count: int = 0
var max_flash_count: int = 1
var original_color: Color = Color(1,1,1)
var flash_color: Color = Color(1,0,0)  # 默认红色

func _ready():
	mat = sprite.material.duplicate()
	sprite.material = mat
	original_color = Color(1,1,1)
	base_scale = Vector2.ONE
	base_rotation = 0.0
	target_scale = base_scale
	target_rotation = base_rotation

func _process(delta):

	if PauseManager.paused:
		return

	# 蓝色线性褪回
	if blue_strength > 0.0:
		blue_strength = max(blue_strength - delta * fade_speed / log(main.fruit_eaten + 2) , 0.0)

	# 蓝色褪去后恢复缩放与旋转
	if blue_strength <= 0.0:
		target_rotation = base_rotation
		target_scale = base_scale

	# 缩放与旋转插值
	scale = scale.lerp(target_scale, delta * scale_speed)
	rotation = lerp_angle(rotation, target_rotation, delta * rotation_interp_speed)

	# 果子旋转叠加
	rotation += deg_to_rad(rotation_speed * delta)

	# 闪烁逻辑
	if flashing:
		flash_timer -= delta
		var t = clamp(flash_timer / flash_duration, 0.0, 1.0)
		mat.set_shader_parameter("display_color", original_color.lerp(flash_color, t))
		if flash_timer <= 0:
			flash_count -= 1
			if flash_count > 0:
				flash_timer = flash_duration
			else:
				flashing = false
				mat.set_shader_parameter("display_color", original_color)
				target_scale = base_scale
				target_rotation = base_rotation
				blue_strength = 0.0
	else:
		var final_color = original_color.lerp(Color(0.5,0.5,1.0), blue_strength)
		mat.set_shader_parameter("display_color", final_color)


func set_head(amount: float):
	blue_strength = clamp(amount, 0.0, 1.0)
	target_rotation = deg_to_rad(45)
	target_scale = base_scale / 1.41

func is_rotated_45() -> bool:
	return abs(fmod(rotation, TAU) - deg_to_rad(45)) < deg_to_rad(30)

# 全局闪烁方法，可传入颜色、时长、次数
func trigger_global_flash_custom(color: Color, duration: float = 0.3, times: int = 1):
	for brick in get_tree().get_nodes_in_group("bricks"):
		brick.flashing = true
		brick.flash_color = color
		brick.flash_timer = duration
		brick.flash_count = times
		brick.max_flash_count = times

func set_color(color: Color): 
	mat.set_shader_parameter("display_color", color) 
	original_color = color

func add_color(color: Color):
	var new_color = Color(
		(original_color.r + color.r)/2,
		(original_color.g + color.g)/2,
		(original_color.b + color.b)/2,
		1.0  # alpha 保持不变
	)
	mat.set_shader_parameter("display_color", new_color)
	original_color = new_color
