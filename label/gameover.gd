extends Control

@export var menu: PackedScene
@export var retry: PackedScene

@onready var screen: Control = $Screen
@onready var anim: AnimationPlayer = $Screen/AnimationPlayer

func _ready() -> void:
	screen.visible = false

func _on_menu_pressed() -> void:
	if menu:
		AudioManager.stop_bgm()
		get_tree().change_scene_to_packed(menu)

func _on_retry_pressed() -> void:
	if retry:
		get_tree().change_scene_to_packed(retry)

func fade() -> void:
	screen.visible = true
	anim.play("gameover")
	await anim.animation_finished
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
