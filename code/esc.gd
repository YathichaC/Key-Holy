extends Control
@export var return_scene: PackedScene
@export var menu_scene: PackedScene
signal return_pressed

func _ready() -> void:
	visible = false  # ซ่อนตอนเริ่ม
	# เชื่อมสัญญาณปุ่ม
	$back.pressed.connect(_on_back_pressed)
	$return.pressed.connect(_on_return_pressed)
func _on_back_pressed() -> void:
	if menu_scene:
		get_tree().change_scene_to_packed(menu_scene)

func _on_return_pressed() -> void:
	hide()
	emit_signal("return_pressed")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
