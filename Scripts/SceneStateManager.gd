extends Node

# Referencia al nodo principal y contenedor de bloques
var main_scene: Spatial
var blocks_container: Node
var block_scene = preload("res://Scenes/Block.tscn")

func _ready():
	# Obtener referencias cuando el nodo esté listo
	main_scene = get_parent()
	if main_scene.has_node("BlocksContainer"):
		blocks_container = main_scene.get_node("BlocksContainer")
	else:
		print("❌ No se encontró BlocksContainer")

func capture_scene_state() -> Dictionary:
	print("📸 Capturando estado de la escena...")
	
	var scene_state = {
		"user_id": "default_user", # Puedes cambiar esto por un sistema de usuarios real
		"version": "1.0",
		"timestamp": OS.get_unix_time(),
		"blocks": []
	}
	
	if blocks_container == null:
		print("❌ BlocksContainer no disponible")
		return scene_state
	
	# Recorrer todos los bloques en el contenedor
	var block_count = 0
	for child in blocks_container.get_children():
		if child.has_method("is_block"):
			var block_data = capture_block_data(child)
			scene_state.blocks.append(block_data)
			block_count += 1
	
	print("✅ Capturados ", block_count, " bloques")
	return scene_state

func capture_block_data(block: Spatial) -> Dictionary:
	var block_data = {
		"id": block.name,
		"position": {
			"x": block.translation.x,
			"y": block.translation.y,
			"z": block.translation.z
		},
		"rotation": {
			"x": block.rotation_degrees.x,
			"y": block.rotation_degrees.y,
			"z": block.rotation_degrees.z
		},
		"scale": {
			"x": block.scale.x,
			"y": block.scale.y,
			"z": block.scale.z
		}
	}
	
	# Si el bloque tiene datos adicionales, capturarlos
	if block.has_method("get_save_data"):
		block_data["custom_data"] = block.get_save_data()
	
	return block_data

func restore_scene_state(scene_data: Dictionary):
	print("🔄 Restaurando estado de la escena...")
	
	if scene_data.empty() or not scene_data.has("blocks"):
		print("ℹ️ No hay datos para restaurar")
		return
	
	if blocks_container == null:
		print("❌ BlocksContainer no disponible para restaurar")
		return
	
	# Limpiar bloques existentes
	clear_existing_blocks()
	
	# Recrear bloques desde los datos guardados
	var restored_count = 0
	for block_data in scene_data.blocks:
		var new_block = create_block_from_data(block_data)
		if new_block != null:
			blocks_container.add_child(new_block)
			restored_count += 1
	
	print("✅ Restaurados ", restored_count, " bloques")
	
	# Notificar al script principal que la escena fue restaurada
	if main_scene.has_method("_on_scene_restored"):
		main_scene._on_scene_restored()

func clear_existing_blocks():
	print("🧹 Limpiando bloques existentes...")
	
	var blocks_to_remove = []
	for child in blocks_container.get_children():
		if child.has_method("is_block"):
			blocks_to_remove.append(child)
	
	for block in blocks_to_remove:
		block.queue_free()
	
	print("🗑️ Marcados ", blocks_to_remove.size(), " bloques para eliminación")

func create_block_from_data(block_data: Dictionary) -> Spatial:
	# Crear nueva instancia del bloque
	var new_block = block_scene.instance()
	
	# Establecer nombre
	new_block.name = block_data.get("id", "Block")
	
	# Restaurar posición
	if block_data.has("position"):
		var pos = block_data.position
		new_block.translation = Vector3(pos.x, pos.y, pos.z)
	
	# Restaurar rotación
	if block_data.has("rotation"):
		var rot = block_data.rotation
		new_block.rotation_degrees = Vector3(rot.x, rot.y, rot.z)
	
	# Restaurar escala
	if block_data.has("scale"):
		var scale = block_data.scale
		new_block.scale = Vector3(scale.x, scale.y, scale.z)
	
	# Restaurar datos personalizados si existen
	if block_data.has("custom_data") and new_block.has_method("set_save_data"):
		new_block.set_save_data(block_data.custom_data)
	
	return new_block

# Función para obtener estadísticas de la escena
func get_scene_stats() -> Dictionary:
	var stats = {
		"total_blocks": 0,
		"total_volume": 0.0
	}
	
	if blocks_container != null:
		for child in blocks_container.get_children():
			if child.has_method("is_block"):
				stats.total_blocks += 1
				# Calcular volumen aproximado
				var block_volume = child.scale.x * child.scale.y * child.scale.z
				stats.total_volume += block_volume
	
	return stats
