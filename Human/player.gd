extends CharacterBody3D

# --- Movement Settings ---
@export var speed: float = 3.0
@export var sprint_speed: float = 6.0

# --- Camera / Mouse Settings ---
@export var mouse_sensitivity: float = 0.003
var pitch: float = 0.0   # กล้องก้ม/เงย

# --- References ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var gameover_anim: Control = $CanvasLayer/gameover

# --- Pick UI System ---
@onready var pick_ui: Control = $CanvasLayer/Pick_key
var current_interactable: Node3D = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerManager.player = self

	# --- ซ่อน UI ตอนเริ่ม ---
	pick_ui.visible = false

	# --- เชื่อมสัญญาณจาก key และ holy ---
	var world = get_tree().get_current_scene()
	for node in world.get_children():
		# ✅ ตรวจชื่อแบบไม่สนตัวพิมพ์เล็กใหญ่
		if node.name.to_lower().begins_with("key") or node.name.to_lower().begins_with("holy"):
			if node.has_signal("player_entered"):
				node.player_entered.connect(_on_item_entered)
			if node.has_signal("player_exited"):
				node.player_exited.connect(_on_item_exited)

	# ✅ Debug ตรวจสอบว่าเจอ UI หรือไม่
	if pick_ui == null:
		push_warning("⚠️ Pick_key UI not found! ตรวจ path ให้ถูกต้อง เช่น $CanvasLayer/Pick_key")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# หมุนซ้าย-ขวา
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# หมุนกล้องขึ้น-ลง (จำกัดองศาไว้ -30 ถึง +30 องศา)
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, -PI/14, PI/6)
		head.rotation.x = pitch
		
	if event.is_action_pressed("interact") and current_interactable != null:
		# ตรวจสอบ group ก่อนเก็บ
		if current_interactable.is_in_group("Key"):
			print("DEBUG: Pressed interact on KEY:", current_interactable.name)
			_pick_up_key(current_interactable)
		elif current_interactable.is_in_group("holy"):
			print("DEBUG: Pressed interact on HOLY WATER:", current_interactable.name)
			_pick_up_holy(current_interactable)
		else:
			print("DEBUG: Pressed interact on unknown item:", current_interactable.name)

func _physics_process(delta: float) -> void:
	# --- สำคัญ: เก็บค่าแนวดิ่ง (y) ไว้ก่อน เพราะถ้ารีเซ็ตเป็น 0 ทุกเฟรม
	#            อาจทำให้การชน/แรงโน้มถ่วงเพี้ยนหรือทะลุวัตถุได้ ---
	var vy: float = self.velocity.y

	# --- Movement Input ---
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("up"):
		input_dir.z += 1
	if Input.is_action_pressed("down"):
		input_dir.z -= 1
	if Input.is_action_pressed("left"):
		input_dir.x += 1
	if Input.is_action_pressed("right"):
		input_dir.x -= 1
	
	input_dir = input_dir.normalized()
	
	# --- Choose speed ---
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# --- Apply direction relative to player ---
	var direction = (transform.basis * input_dir)
	if direction.length() > 0.0:
		direction = direction.normalized()
	
	# --- ตั้งความเร็วเฉพาะแกน X,Z โดยไม่แตะ Y (vy ถูกเก็บไว้ด้านบน) ---
	self.velocity.x = direction.x * current_speed
	self.velocity.z = direction.z * current_speed
	self.velocity.y = vy

	# --- Move using CharacterBody3D's velocity (Godot 4 move_and_slide() ใช้ velocity ของ node) ---
	move_and_slide()

	# --- Play animation (ยังใช้ค่า velocity ของ node ได้ตามเดิม) ---
	_update_animation(self.velocity)

# -----------------------------
func _update_animation(velocity: Vector3) -> void:
	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	
	if horizontal_speed < 0.01:
		# ยืนอยู่กับที่
		if anim_player.current_animation != "Animation/idle":
			anim_player.play("Animation/idle")
	elif horizontal_speed < speed + 0.01:
		# เดิน
		if anim_player.current_animation != "Animation/walking":
			anim_player.play("Animation/walking")
	else:
		# วิ่ง
		if anim_player.current_animation != "Animation/running":
			anim_player.play("Animation/running")
	
func die() -> void:
	# --- หยุดการควบคุม player ---
	set_physics_process(false)
	set_process_input(false)

	# --- เล่น animation ตาย ---
	if anim_player.has_animation("Animation/dying_backwards"):
		anim_player.play("Animation/dying_backwards")
		await anim_player.animation_finished
		AudioManager.stop_bgm()
		gameover_anim.fade()

	# --- หลัง animation ตายจบ อาจทำอะไรเพิ่มเติมได้ เช่น ซ่อน player ---
	# visible = false  # ถ้าต้องการซ่อนตัว player หลังตาย

# -----------------------------
# ✅ ฟังก์ชันแสดง/ซ่อน Pick_key UI
func _on_item_entered(item: Node3D) -> void:
	print("DEBUG: show Pick_key for", item.name)
	pick_ui.visible = true
	current_interactable = item

func _on_item_exited(item: Node3D) -> void:
	if current_interactable == item:
		print("DEBUG: hide Pick_key for", item.name)
		pick_ui.visible = false
		current_interactable = null
		
# -----------------------------
func _pick_up_key(item: Node3D) -> void:
	print("✅ Picked up KEY:", item.name)
	pick_ui.visible = false
	item.visible = false
	var area = item.get_node_or_null("Area3D")
	if area:
		area.monitoring = false
		area.visible = false
	current_interactable = null
	Global.keys_collected += 1
	print("DEBUG: Total keys collected:", Global.keys_collected)

func _pick_up_holy(item: Node3D) -> void:
	print("✅ Picked up HOLY WATER:", item.name)
	pick_ui.visible = false
	item.visible = false
	var area = item.get_node_or_null("Area3D")
	if area:
		area.monitoring = false
		area.visible = false
	current_interactable = null
	Global.holy_collected += 1
	print("DEBUG: Total holy water collected:", Global.holy_collected)
