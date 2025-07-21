extends Node

# Muro por defecto y base para el resto de personalizaciones.
export var wall_scene = preload("res://Entities/Wall/Wall.tscn")

# Contenedor para los bloques de muro.
onready var walls_containers = $BlocksContainer

# Coloca un muro en la posición especificada.
func place_wall(position):
    var point = position.snapped(Vector3.ONE)
    point.y = 0 

    var wall = wall_scene.instance()
    wall.translation = point
    wall.scale = Vector3(5.0, 3.5, 0.25)

    walls_containers.add_child(wall)
    return wall;