extends Node

export var wall_scene = preload("res://Entities/Wall/Wall.tscn")

onready var walls_containers = get_or_create_walls_container()

var selected_wall = null
var move_key_pressed = false
var last_move_key = null
var is_dragging = false
var drag_offset = Vector3.ZERO
var original_position = Vector3.ZERO

# TODO: Implementar UI para seleccionar paredes y moverlas con botones
# TODO: Eliminar paredes seleccionadas con botón de eliminar
# TODO: Implementar escalado de paredes donde el slider se actualize de acuerdo al tamaño de la pared seleccionada
# TODO: Posiblemente implementar shader para renderizar en el suelo el sistema de snapping

func handle_input(event, camera):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			print("Mouse button pressed at: ", event.position)
			# ! Check this function to avoid UI selection
			# Evitar selección si el mouse está sobre la UI
			# if is_click_on_ui(event.position):
			# 	return
			var collision = camera.get_raycast_collision()
			if collision:
				print("Collision detected at: ", collision.position)
				var collider = collision.collider
				var collision_point = collision.position
				if collider and collider.get_parent().is_in_group("wall"):
					var wall = collider.get_parent()
					if selected_wall == wall:
						start_drag(collision_point)
					else:
						select_wall(wall)
				else:
					deselect_wall()
			else:
				deselect_wall()
		else:
			if is_dragging:
				finish_drag()
	elif event is InputEventMouseMotion and is_dragging:
		var collision = camera.get_raycast_collision()
		if collision:
			update_drag_position(collision.position)
			
	elif event is InputEventKey and selected_wall:
        # Manage wall movement with keyboard keys
		var valid_key = (
			event.scancode == KEY_UP or event.scancode == KEY_W or
			event.scancode == KEY_DOWN or event.scancode == KEY_S or
			event.scancode == KEY_LEFT or event.scancode == KEY_A or
			event.scancode == KEY_RIGHT or event.scancode == KEY_D
		)

		if valid_key:
			move_key_pressed = event.pressed
			if event.pressed:
				last_move_key = event.scancode
			elif last_move_key == event.scancode:
				last_move_key = null
				move_key_pressed = false
    # ! Manage with the buttons UI

func process_wall_move(camera):
	if move_key_pressed and selected_wall:
		var collision = camera.get_raycast_collision()
		if collision:
			var target_pos = collision.position.snapped(Vector3.ONE)
			target_pos.y = selected_wall.translation.y
			if selected_wall.translation.distance_to(target_pos) > 0.1:
				selected_wall.translation = target_pos

func place_wall(collision_point):
	if not is_dragging:
		var snapped_point = collision_point.snapped(Vector3.ONE)
		snapped_point.y = 1.0 
		var wall_instance = wall_scene.instance()
		wall_instance.translation = snapped_point
		wall_instance.scale = Vector3(5.0, 3.5, 0.25)
		walls_containers.add_child(wall_instance)
		select_wall(wall_instance)

func get_or_create_walls_container():
	var container = get_node_or_null("WallsContainers")
	if container == null:
		container = Node.new()
		container.name = "WallsContainers"
		add_child(container)
	return container

func select_wall(wall):
	print("Selecting wall: ", wall.name)
	
	if selected_wall:
		var mesh_instance = selected_wall.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = null

	selected_wall = wall
	var mesh_instance = wall.get_node("StaticBody/MeshInstance")
	# Si tienes un material de selección, asígnalo aquí
	# mesh_instance.material_override = selected_material

func move_selected_wall(direction):
	if selected_wall:
		var new_pos = selected_wall.translation + direction.snapped(Vector3.ONE)
		new_pos.y = selected_wall.translation.y # Mantener altura
		selected_wall.translation = new_pos

func deselect_wall():
	if selected_wall:
		var mesh_instance = selected_wall.get_node("StaticBody/MeshInstance")
		mesh_instance.material_override = null
		selected_wall = null

func start_drag(collision_point):
	is_dragging = true
	original_position = selected_wall.translation
	var snapped_point = collision_point.snapped(Vector3.ONE)
	snapped_point.y = selected_wall.translation.y
	drag_offset = selected_wall.translation - snapped_point
	drag_offset.y = 0

func update_drag_position(new_position):
	if not is_dragging or not selected_wall:
		return
	new_position = new_position.snapped(Vector3.ONE) + drag_offset
	new_position.y = original_position.y
	selected_wall.translation = new_position

func finish_drag():
	is_dragging = false
