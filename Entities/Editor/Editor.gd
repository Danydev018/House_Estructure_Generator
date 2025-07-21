extends Spatial

export(NodePath) var camera_path
onready var camera = get_node(camera_path)

onready var create_button = $HUD/CreateButton
onready var delete_button = $HUD/DeleteButton
onready var rotate_button = $HUD/RotateButton
onready var scale_slider = $HUD/ScaleSlider
onready var wall_edit_controller = $WallEditController
onready var object_edit_controller = $ObjectEditController

# Usar el contexto global para el modo de juego
onready var game_mode_context = get_node("/root/GameModeContext")

var drag_offset = Vector3.ZERO
var original_position = Vector3.ZERO

func _ready():
	# Conectar señales de UI
	create_button.connect("pressed", self, "_on_create_button_pressed")
	delete_button.connect("pressed", self, "_on_delete_button_pressed")
	rotate_button.connect("pressed", self, "_on_rotate_button_pressed")
	scale_slider.connect("value_changed", self, "_on_scale_slider_changed")

	# Conectar señal del contexto global
	game_mode_context.connect("game_mode_changed", self, "_on_game_mode_changed")

func _process(delta):
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
		wall_edit_controller.process_wall_move(camera)

func _input(event):
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
		wall_edit_controller.handle_input(event, camera)
	elif GameModeContext.game_mode == GameModeContext.MODE_PLACE:
		object_edit_controller.handle_input(event)

func _on_game_mode_changed(_arg = null):
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
		# ! Renderizar UI de construcción
		pass
	elif GameModeContext.game_mode == GameModeContext.MODE_PLACE:
		# ! Renderizar UI de colocación de objetos
		pass
	else:
		# ! Renderizar UI de otro modo
		pass

func _on_create_button_pressed():
	var collision = camera.get_raycast_collision()

	if collision == null:
		return

	var collision_point = collision.position

	if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
		wall_edit_controller.place_wall(collision_point)
	elif GameModeContext.game_mode == GameModeContext.MODE_PLACE:
		# ! Implementacion de colocar objetos
		pass
	else:
		# ! Implementacion de otro modo
		pass

func _on_delete_button_pressed():
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD and wall_edit_controller.selected_wall:
		wall_edit_controller.delete_wall(wall_edit_controller.selected_wall)

func _on_rotate_button_pressed():
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD and wall_edit_controller.selected_wall:
		wall_edit_controller.selected_wall.rotation_degrees.y += 90

func _on_scale_slider_changed(value):
	if GameModeContext.game_mode == GameModeContext.MODE_BUILD and wall_edit_controller.selected_wall:
		wall_edit_controller.selected_wall.scale.x = value
