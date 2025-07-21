# Este fichero provee funcionalidades para mover una cámara en un entorno 3D.
extends Node

func process_input(camera, event):
    if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
        return

    if camera.mouse_captured and event is InputEventMouseMotion:   
        camera.camera_view_y -= event.relative.x * camera.mouse_sensitivity
        camera.camera_view_x -= event.relative.y * camera.mouse_sensitivity
        camera.camera_view_x = clamp(camera.camera_view_x, -90, 90)
        camera.rotation_degrees = Vector3(camera.camera_view_x, camera.camera_view_y, 0)

func process_movement(camera, delta, wall_edit_controller = null):
    var dir := Vector3()

    if GameModeContext.game_mode == GameModeContext.MODE_BUILD:
        if Input.is_action_pressed("ui_up"):
            dir += camera.transform.basis.y
        if Input.is_action_pressed("ui_down"):
            dir -= camera.transform.basis.y
        if Input.is_action_pressed("ui_left"):
            dir -= camera.transform.basis.x
        if Input.is_action_pressed("ui_right"):
            dir += camera.transform.basis.x

    elif GameModeContext.game_mode == GameModeContext.MODE_PLACE:
        if Input.is_action_pressed("ui_up"):
            dir -= camera.transform.basis.z
        if Input.is_action_pressed("ui_down"):
            dir += camera.transform.basis.z
        if Input.is_action_pressed("ui_left"):
            dir -= camera.transform.basis.x
        if Input.is_action_pressed("ui_right"):
            dir += camera.transform.basis.x

    if dir.length() > 0:
        dir = dir.normalized() * camera.speed_movement * delta
        camera.translation += dir