extends Control

const SHOP_SCENE_PATH := "res://Scenes/ShopScene.tscn"

@onready var blocks: Array[Sprite2D] =[
	$block1,
	$block2,
	$block3,
	$block4,
	$block5,
	$block6
]

@onready var skip_button: TextureButton = $skip_btn

var current_block_index: int = 0


func _ready() -> void:
	current_block_index = 0

	# Make sure all comic panels are covered initially.
	for block in blocks:
		block.show()

	# Prevent the skip button from triggering comic clicks.
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.pressed.connect(start_shop)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Mouse clicked!")
			reveal_next_block()

func reveal_next_block() -> void:
	if current_block_index >= blocks.size():
		return

	blocks[current_block_index].hide()
	current_block_index += 1

	print("Revealed comic panel: ", current_block_index)

func start_shop() -> void:
	GameState.new_game()

	var error: Error = get_tree().change_scene_to_file(
		SHOP_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open ShopScene.")
