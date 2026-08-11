extends ScrollContainer

const DRAG_THRESHOLD := 12.0

var _pressed := false
var _dragging := false
var _start_position := Vector2.ZERO
var _start_scroll := 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressed = event.pressed
		_dragging = false
		_start_position = event.position
		_start_scroll = scroll_horizontal
		return
	if event is InputEventMouseMotion and _pressed:
		_handle_drag(event.position)
		return
	if event is InputEventScreenTouch:
		_pressed = event.pressed
		_dragging = false
		_start_position = event.position
		_start_scroll = scroll_horizontal
		return
	if event is InputEventScreenDrag and _pressed:
		_handle_drag(event.position)


func _handle_drag(position: Vector2) -> void:
	var offset := position - _start_position
	if not _dragging and absf(offset.x) < DRAG_THRESHOLD:
		return
	_dragging = true
	scroll_horizontal = _start_scroll - int(offset.x)
	accept_event()
