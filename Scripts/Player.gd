extends CharacterBody3D

const SENSITIVITY = 0.01
const ANIM_SPEED = 10

const FILM_SPEED = 1.5
const CROUCH_SPEED = 2.0
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0

const EYE_HEIGHT = 0.5
const COLLIDER_HEIGHT = 2.0
const CROUCH_HEIGHT_REDUCTION = 0.9

const JUMP_VELOCITY = 4.5
const GROUND_CONTROL = 10.0
const AIR_CONTROL = 3.0

const FOV_FILM = 10.0
const FOV = 75.0
const FOV_SPRINT = 90.0

const CAMPOS_WALK = Vector3(0.23, -0.3, -0.4)
const CAMPOS_SPRINT = Vector3(0.4, -0.4, -0.2)
const CAMPOS_FILM = Vector3(0.02075, -0.2795, -0.4)
const CAMROT_WALK = 0.0
const CAMROT_SPRINT = -90.0

const BOB_FREQ = 2
const BOB_AMP = .08

const BATTERY100 = preload("res://Materials/battery-100.material")
const BATTERY75 = preload("res://Materials/battery-75.material")
const BATTERY50 = preload("res://Materials/battery-50.material")
const BATTERY25 = preload("res://Materials/battery-25.material")
const BATTERY0 = preload("res://Materials/battery-0.material")

var speed
var t_bob = 0
var battery = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var Head = $Head
@onready var Camera = $Head/Camera3D
@onready var Recorder = $Head/Camera3D/Recorder
@onready var RecorderEyepiece = $Head/Camera3D/Recorder/RecorderEyepiece
@onready var BatteryUI = $Head/Camera3D/Recorder/RecorderBatteryUI
@onready var Collider = $CollisionShape3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		Head.rotate_y(-event.relative.x * SENSITIVITY)
		Camera.rotate_x(-event.relative.y * SENSITIVITY)
		Camera.rotation.x = clamp(Camera.rotation.x, -1.5, 1.5)

func _process(delta):
	if battery <= 0:
		RecorderEyepiece.hide()
	elif battery < 20:
		BatteryUI.set_surface_override_material(0, BATTERY0)
		battery -= delta * ANIM_SPEED
	elif battery < 40:
		BatteryUI.set_surface_override_material(0, BATTERY25)
		battery -= delta * ANIM_SPEED
	elif battery < 60:
		BatteryUI.set_surface_override_material(0, BATTERY50)
		battery -= delta * ANIM_SPEED
	elif battery < 80:
		BatteryUI.set_surface_override_material(0, BATTERY75)
		battery -= delta * ANIM_SPEED
	else:
		BatteryUI.set_surface_override_material(0, BATTERY100)
		battery -= delta * ANIM_SPEED

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("Film") && battery > 0:
		FilmFOVSetup(delta)
	elif Input.is_action_pressed("Sprint") && Input.is_action_pressed("Forward"):
		SprintFOVSetup(delta)
	elif Input.is_action_pressed("Crouch"):
		CrouchFOVSetup(delta)
	else:
		WalkFOVSetup(delta)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and is_on_floor():
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	elif is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * speed, delta * GROUND_CONTROL)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * GROUND_CONTROL)
		velocity.z = 0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * AIR_CONTROL)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * AIR_CONTROL)
	
	t_bob += delta * velocity.length() * int(is_on_floor()) * int(!is_on_wall())
	Camera.transform.origin = Vector3(cos(t_bob * BOB_FREQ /2) * BOB_AMP, sin(t_bob * BOB_FREQ) * BOB_AMP, 0)

	move_and_slide()

func FilmFOVSetup(delta):
	speed = FILM_SPEED
	Head.transform.origin.y = lerp(Head.transform.origin.y, EYE_HEIGHT - CROUCH_HEIGHT_REDUCTION * float(Input.is_action_pressed("Crouch")), delta * ANIM_SPEED)
	Camera.fov = lerp(Camera.fov, FOV_FILM, delta * ANIM_SPEED)
	Recorder.transform.origin = lerp(Recorder.transform.origin, CAMPOS_FILM, delta * ANIM_SPEED)
	Recorder.rotation_degrees.x = (lerp(Recorder.rotation_degrees.x, CAMROT_WALK, delta * ANIM_SPEED))
func SprintFOVSetup(delta):
	speed = SPRINT_SPEED
	Head.transform.origin.y = lerp(Head.transform.origin.y, EYE_HEIGHT, delta * ANIM_SPEED)
	Camera.fov = lerp(Camera.fov, FOV_SPRINT, delta * ANIM_SPEED)
	Recorder.transform.origin = lerp(Recorder.transform.origin, CAMPOS_SPRINT, delta * ANIM_SPEED)
	Recorder.rotation_degrees.x = (lerp(Recorder.rotation_degrees.x, CAMROT_SPRINT, delta * ANIM_SPEED))
func CrouchFOVSetup(delta):
	speed = CROUCH_SPEED
	Head.transform.origin.y = lerp(Head.transform.origin.y, EYE_HEIGHT - CROUCH_HEIGHT_REDUCTION, delta * ANIM_SPEED)
	Camera.fov = lerp(Camera.fov, FOV, delta * ANIM_SPEED)
	Recorder.transform.origin = lerp(Recorder.transform.origin, CAMPOS_WALK, delta * ANIM_SPEED)
	Recorder.rotation_degrees.x = (lerp(Recorder.rotation_degrees.x, CAMROT_WALK, delta * ANIM_SPEED))
func WalkFOVSetup(delta):
	speed = WALK_SPEED
	Head.transform.origin.y = lerp(Head.transform.origin.y, EYE_HEIGHT, delta * ANIM_SPEED)
	Camera.fov = lerp(Camera.fov, FOV, delta * ANIM_SPEED)
	Recorder.transform.origin = lerp(Recorder.transform.origin, CAMPOS_WALK, delta * ANIM_SPEED)
	Recorder.rotation_degrees.x = lerp(Recorder.rotation_degrees.x, CAMROT_WALK, delta * ANIM_SPEED)
