# ScoreDisplay.gd
extends Node
class_name ScoreDisplay

@export var bricks: Array  # 来自main的砖块二维数组
@export var n: int = 30    # 网格大小
@export var digit_map_res: Resource = preload("res://scripts/DigitMap.gd") # 数字映射

# 显示三位数，score范围0~999
func show_score(score:int):
	score = clamp(score, 0, 999)
	var digits = str(score).pad_zeros(3)  # 补齐3位，例如 '007'

	var digit_width = 3
	var digit_height = 5
	var spacing = 1  # 数字间隔1格
	var total_width = 3*digit_width + 2*spacing

	var start_x = int(n/2 - total_width/2)
	var start_y = int(n/2 - digit_height/2)

	# 先把数字区域清空
	for y in range(digit_height):
		for x in range(total_width):
			bricks[start_y + y][start_x + x].set_color(Color(0,0,0))  # 背景

	# 绘制每一位数字
	for idx in range(3):
		var digit_val = int(digits[idx])
		var map = digit_map_res.get_digit_map(digit_val)
		for dy in range(digit_height):
			for dx in range(digit_width):
				var brick = bricks[start_y + dy][start_x + idx*(digit_width + spacing) + dx]
				if map[dy][dx] == 1:
					brick.set_color(Color(1,1,0))  # 黄色亮格
				else:
					brick.set_color(Color(0,0,0))  # 背景
