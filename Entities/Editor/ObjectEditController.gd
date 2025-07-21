extends Node

# Controlador de edición de objetos
var selected_object = null

func set_active(active: bool):
    self.set_process(active)
    self.visible = active

func handle_input(event):
    # Aquí va la lógica de input específica para objetos
    pass

func place_object(position):
    # Lógica para colocar un objeto
    pass

func delete_object(obj):
    # Lógica para borrar un objeto
    pass

# ...más funciones específicas de objetos...
