extends Node3D

# --- Nodes / References ---
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area3D = $Area3D
@onready var ui_open: Control = $open_door
@onready var ui_close: Control = $close_door
@onready var audio_open: AudioStreamPlayer = $door_open
@onready var audio_close: AudioStreamPlayer = $door_close


# --- State ---
var player_in_range: bool = false
var door_state: String = "close"
var player_ref: Node = null

# --- CONFIG ---
const REQUIRED_KEYS: int = 7   # ต้องมีกุญแจ 7 ดอกถึงจะเปิดได้

func _ready() -> void:
	anim.play("RESET")
	ui_open.visible = false
	ui_close.visible = false

	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if door_state == "close":
			_try_open_door()
		elif door_state == "open":
			_close_door()

# -----------------------------
# TRY TO OPEN DOOR
# -----------------------------
func _try_open_door() -> void:
	if not player_ref:
		return
	
	# ✅ ตรวจว่าผู้เล่นมีกุญแจครบหรือยัง
	if player_ref.key_count >= REQUIRED_KEYS:
		_open_door()
	else:
		print("You need more keys! (", player_ref.key_count, "/", REQUIRED_KEYS, ")")



# -----------------------------
# OPEN / CLOSE DOOR
# -----------------------------
func _open_door() -> void:
	print("Opening door...")
	audio_open.play()
	anim.play("door_open")
	door_state = "open"
	ui_open.visible = false
	ui_close.visible = false

func _close_door() -> void:
	print("Closing door...")
	audio_close.play()
	anim.play("door_close")
	door_state = "close"
	ui_open.visible = false
	ui_close.visible = false

# -----------------------------
# AREA DETECTION
# -----------------------------
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		
		if door_state == "close":
			ui_open.visible = true
			ui_close.visible = false
		else:
			ui_open.visible = false
			ui_close.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		ui_open.visible = false
		ui_close.visible = false
