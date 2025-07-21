extends Camera

var movement := preload("res://Entities/Camera/CameraMovement.gd").new()
var mouse_control := preload("res://Entities/Camera/CameraMouse.gd").new()

# Velocidad a la que se mueve la camara (Configurables desde el editor)
export var speed_movement := 10
export var height_for_build := 10

# Sensibilidad del mouse para rotar la cámara (Configurables desde el editor)
export var mouse_sensitivity := 0.1

var camera_view_x := 0.0
var camera_view_y := 0.0

# Guardar posición y rotación previas
var last_translation := Vector3()
var last_rotation := Vector3()

var mouse_captured := true

onready var tween := Tween.new()

func toggle_mouse_capture():
	if mouse_captured:
		mouse_control.release_mouse(self)
	else:
		mouse_control.capture_mouse(self)

func get_raycast_collision(screen_pos = null):
    var from
    var to
    if screen_pos == null:
        var viewport_size = get_viewport().size
        screen_pos = viewport_size / 2
    from = project_ray_origin(screen_pos)
    to = from + project_ray_normal(screen_pos) * 100
    var space_state = get_world().direct_space_state
    var result = space_state.intersect_ray(from, to)
    if result:
        return {
            "collider": result.collider,
            "position": result.position
        }
    return null

func _ready():
	mouse_control.capture_mouse(self)
	GameModeContext.connect("game_mode_changed", self, "_on_game_mode_changed")
	
	add_child(tween)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ESCAPE:
			toggle_mouse_capture()
	movement.process_input(self, event)

func _process(delta):
	movement.process_movement(self, delta)

func _on_game_mode_changed(game_mode):
	if game_mode == GameModeContext.MODE_BUILD:	
		last_translation = translation
		last_rotation = rotation_degrees

		var target_translation = Vector3(translation.x, height_for_build, translation.z)
		var target_rotation = Vector3(-90, rotation_degrees.y, rotation_degrees.z)

		tween.interpolate_property(self, "translation", translation, target_translation, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rotation_degrees", rotation_degrees, target_rotation, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

		tween.start()
	elif game_mode == GameModeContext.MODE_PLACE:
		tween.interpolate_property(self, "translation", translation, last_translation, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rotation_degrees", rotation_degrees, last_rotation, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

		tween.start()
	else:
		# Si el modo de juego no es válido, no hacemos nada
		pass
