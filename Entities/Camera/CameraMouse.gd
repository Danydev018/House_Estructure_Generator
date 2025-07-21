# Este fichero provee funcionalidades para capturar y liberar el mouse en una cámara.

extends Node

func capture_mouse(camera):
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    camera.mouse_captured = true

func release_mouse(camera):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    camera.mouse_captured = false
