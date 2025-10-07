extends Control

signal transitioned

@onready var anim_player: AnimationPlayer = $TransitionScreen/AnimationPlayer

func _ready() -> void:
	visible = false
	# make sure we get notified when an animation finishes
	if anim_player:
		anim_player.animation_finished.connect(Callable(self, "_on_AnimationPlayer_animation_finished"))

func transition() -> void:
	visible = true
	anim_player.play("normal_to_fade")
	print("Fading to black")

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "normal_to_fade":
		emit_signal("transitioned")  # half-way point
		anim_player.play("fade_to_normal")
	elif anim_name == "fade_to_normal":
		visible = false
		print("Finished fading")
