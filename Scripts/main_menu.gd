
extends Control

@onready var start_btn: TextureButton = $VBoxContainer/start_btn
@onready var exit_btn: Button = $VBoxContainer/exit_btn

# Credits buttons
@onready var lavy_btn: BaseButton = $Createdby/Lavy
@onready var harnas_btn: BaseButton = $Createdby/Harnas
@onready var quiuki_btn: BaseButton = $Createdby/Quiuki
@onready var morfeiqo_btn: BaseButton = $Createdby/Morfeiqo
@onready var reklama_btn: BaseButton = $Createdby/Reklama
@onready var luc_btn: BaseButton = $Createdby/Luc

const INTRO_SCENE_PATH := "res://Scenes/Intro.tscn"


func _ready() -> void:
	start_btn.pressed.connect(start_game)
	exit_btn.pressed.connect(exit_game)

	lavy_btn.pressed.connect(
		open_profile.bind("www.linkedin.com/in/czech03902")
	)
	harnas_btn.pressed.connect(
		open_profile.bind("https://linktr.ee/patiszonequ")
	)
	quiuki_btn.pressed.connect(
		open_profile.bind("https://linktr.ee/Quuiki")
	)
	morfeiqo_btn.pressed.connect(
		open_profile.bind("https://www.instagram.com/morfeiqo/")
	)
	reklama_btn.pressed.connect(
		open_profile.bind(" https://karolinapawelec2df12.myportfolio.com/")
	)
	luc_btn.pressed.connect(
		open_profile.bind("https://www.instagram.com/loushiyen/")
	)

func open_profile(url: String) -> void:
	var error: Error = OS.shell_open(url)

	if error != OK:
		push_error("Failed to open profile: " + url)


func start_game() -> void:
	GameState.new_game()

	var error: Error = get_tree().change_scene_to_file(
		INTRO_SCENE_PATH
	)

	if error != OK:
		push_error("Failed to open IntroScene.")


func exit_game() -> void:
	get_tree().quit()
