extends Control

@onready var start_btn : Button = $MenuButtons/start_btn
@onready var exit_btn: Button = $MenuButtons/exit_btn

const SHOP_SCENE_PATH :="res://Scenes/ShopScene.tscn"

func _ready() -> void:
	start_btn.pressed.connect(start_game)
	exit_btn.pressed.connect(exit_game)

func start_game() -> void:
	GameState.new_game()

	var error := get_tree().change_scene_to_file(
		SHOP_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open ShopScene.")

func exit_game() -> void:
	get_tree().quit()
