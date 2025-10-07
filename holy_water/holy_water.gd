extends Node3D

@onready var area: Area3D = $Area3D
@onready var pick_ui: Control = $pick

signal player_entered(key: Node3D)
signal player_exited(key: Node3D)

func _ready():
	pick_ui.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		pick_ui.visible = true
		print("DEBUG: Player entered Area of", name)
		emit_signal("player_entered", self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		pick_ui.visible = false
		print("DEBUG: Player exited Area of", name)
		emit_signal("player_exited", self)
