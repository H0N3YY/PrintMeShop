
extends Control

const SHOP_SCENE_PATH := "res://Scenes/ShopScene.tscn"

# Fade duration in seconds
const FADE_DURATION: float = 2.0

@onready var blocks: Array[Sprite2D] = [
	$block1,
	$block2,
	$block3,
	$block4,
	$block5,
	$block6
]

@onready var skip_button: TextureButton = $skip_btn

var current_block_index: int = 0
var is_fading: bool = false


func _ready() -> void:
	current_block_index = 0
	is_fading = false

	for block in blocks:
		block.show()
		block.modulate.a = 1.0

	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.pressed.connect(start_shop)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_fading:
				return

			# Ignore clicks on the skip button.
			if skip_button.get_global_rect().has_point(
				get_global_mouse_position()
			):
				return

			reveal_next_block()


func reveal_next_block() -> void:
	if current_block_index >= blocks.size():
		return

	is_fading = true

	var block: Sprite2D = blocks[current_block_index]

	var tween: Tween = create_tween()

	tween.tween_property(
		block,
		"modulate:a",
		0.0,
		FADE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	block.hide()

	current_block_index += 1
	is_fading = false

	print("Revealed comic panel: ", current_block_index)

func start_shop() -> void:
	GameState.new_game()

	var error: Error = get_tree().change_scene_to_file(
		SHOP_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open ShopScene.")
