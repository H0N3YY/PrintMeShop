
extends Control

@onready var start_btn: TextureButton = $VBoxContainer/start_btn
@onready var exit_btn: Button = $VBoxContainer/exit_btn

const INTRO_SCENE_PATH := "res://Scenes/Intro.tscn"

func _ready() -> void:

	start_btn.pressed.connect(start_game)
	exit_btn.pressed.connect(exit_game)


func start_game() -> void:
	GameState.new_game()

	var error: Error = get_tree().change_scene_to_file(
		INTRO_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open ShopScene.")


func exit_game() -> void:
	get_tree().quit()
