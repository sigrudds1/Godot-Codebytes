extends Control

var _device_input: DeviceInput

func _ready() -> void:
	
	var gui_input_handlers: Dictionary = {
		DeviceInput.Events.LEFT_CLICK: Callable(self, "_on_device_left_click"),
		DeviceInput.Events.MOUSE_SCROLL: Callable(self, "_on_device_zoomed"),
		DeviceInput.Events.PAN: Callable(self, "_on_device_panned"),
		DeviceInput.Events.PINCH: Callable(self, "_on_device_pinched")
	}
	_device_input = DeviceInput.new(gui_input_handlers, 0.1)


func _gui_input(p_event: InputEvent) -> void:
	_device_input.handle_gui_event(p_event)


func _on_device_left_click(p_pos:Vector2) -> void:
	var local_pos: Vector2 = get_local_mouse_position()
	print(self, " LeftClick:", p_pos, " ", local_pos)


func _on_device_panned(p_move: Vector2) -> void:
	print(self, " Pan:", p_move)


func _on_device_pinched(p_factor: float) -> void:
	print(self, " Pinch:", p_factor)


func _on_device_zoomed(p_amount: float) -> void:
	print(self, " Zoom: ", p_amount)
