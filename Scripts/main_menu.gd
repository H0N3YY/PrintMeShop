
extends Control

@onready var start_btn: Button = $VBoxContainer/start_btn
@onready var exit_btn: Button = $VBoxContainer/exit_btn

const INTRO_SCENE_PATH := "res://Scenes/Intro.tscn"

func _ready() -> void:
	print("Main menu loaded")

	start_btn.pressed.connect(start_game)
	exit_btn.pressed.connect(exit_game)


func start_game() -> void:
	print("Start button pressed")

	GameState.new_game()

	var error: Error = get_tree().change_scene_to_file(
		INTRO_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open ShopScene.")


func exit_game() -> void:
	print("Exit button pressed")
	get_tree().quit()
