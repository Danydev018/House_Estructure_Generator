extends Camera

var speed := 10
var mouse_sensitivity := 0.1
var rotation_x := 0.0
var rotation_y := 0.0
var mouse_captured := true  #estado de captura del mouse

func _ready():
	capture_mouse()  # Iniciar con mouse capturado

#función para alternar captura de mouse
func toggle_mouse_capture():
	if mouse_captured:
		release_mouse()
	else:
		capture_mouse()

# capturar mouse
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

# liberar mouse
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _input(event):
	# Alternar captura con ESC
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			toggle_mouse_capture()
	
	# Solo procesar movimiento si mouse está capturado
	if mouse_captured and event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -90, 90)
		rotation_degrees = Vector3(rotation_x, rotation_y, 0)

func _process(delta):
	var dir := Vector3()
	if Input.is_action_pressed("ui_up"):
		dir -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		dir += transform.basis.z
	if Input.is_action_pressed("ui_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("ui_right"):
		dir += transform.basis.x
	translation += dir.normalized() * speed * delta
