class_name DeviceInput extends RefCounted

enum Events{
	LEFT_CLICK,
	LEFT_DBL_CLICK,
	MOUSE_SCROLL,
	PAN,
	PINCH
}

const kDragEnableDistance: float = 5.0
const kTouchCooldown: int = 100

var _block_mouse_until_ms: int = 0
var _ignore_next_left_click: bool = false
var _mouse_drag_start: Vector2
var _mouse_dragging: bool = false
var _mouse_left_dbl_click: bool = false
var _mouse_left_pressed: bool = false
var _mouse_button_locked: bool = false
var _mouse_wheel_step: float = 0.1
var _touch_indices: Array[int] = []
var _touch_positions: Array[Vector2] = []
var _prev_touch_distance: float = 0.0

var _gui_handlers: Dictionary


func _init(p_gui_input_handlers: Dictionary, p_mouse_wheel_step: float) -> void:
	_gui_handlers = p_gui_input_handlers
	_mouse_wheel_step = p_mouse_wheel_step


func handle_gui_event(p_event: InputEvent) -> void:
	if p_event is InputEventScreenTouch:
		var event: InputEventScreenTouch = p_event
		var touch_index: int = event.index
		var touch_indices_idx: int = _touch_indices.find(touch_index)
		if event.pressed == true:
			_mouse_button_locked = true
			if touch_indices_idx < 0:
				_touch_indices.push_back(touch_index)
				_touch_positions.push_back(event.position)
			
			if _touch_indices.size() == 1:
				_mouse_left_pressed = true
				_ignore_next_left_click = false
			else:
				var dist: float = _touch_positions[0].distance_to(_touch_positions[1])
				_prev_touch_distance = dist
				_mouse_left_pressed = false
		else:
			if touch_indices_idx > -1:
				_touch_indices.remove_at(touch_indices_idx)
				_touch_positions.remove_at(touch_indices_idx)
				if _touch_indices.size() == 0:
					_block_mouse_until_ms = Time.get_ticks_msec() + kTouchCooldown
					if _mouse_left_pressed == true:
						var cb: Callable = _gui_handlers.get(Events.LEFT_CLICK, Callable())
						if cb.is_valid():
							cb.callv([event.position])
					_mouse_left_pressed = false
	elif p_event is InputEventScreenDrag:
		var event: InputEventScreenDrag = p_event
		if _touch_indices.size() > 1:
			var touch_index: int = event.index
			var touch_indices_idx: int = _touch_indices.find(touch_index)
			var touch_dist: float = _prev_touch_distance
			var pan_vector: Vector2 = Vector2.ZERO
			if touch_indices_idx == 0:
				touch_dist = event.position.distance_to(_touch_positions[1])
				pan_vector =  event.position - _touch_positions[0]
				_touch_positions[0] = event.position
			elif touch_indices_idx == 1:
				touch_dist = event.position.distance_to(_touch_positions[0])
				pan_vector =  event.position - _touch_positions[1]
				_touch_positions[1] = event.position
			var touch_dist_delta: float = _prev_touch_distance - touch_dist
			if abs(touch_dist_delta) > kDragEnableDistance:
				_ignore_next_left_click = true
				var cb: Callable = _gui_handlers.get(Events.PINCH, Callable())
				if cb.is_valid():
					cb.callv([touch_dist_delta])
			elif abs(pan_vector.x) > kDragEnableDistance or abs(pan_vector.y) > kDragEnableDistance:
				_ignore_next_left_click = true
				var cb: Callable = _gui_handlers.get(Events.PAN, Callable())
				if cb.is_valid():
					cb.callv([pan_vector])
			
			_prev_touch_distance = touch_dist
	
	elif p_event is InputEventMouseButton:
		var event: InputEventMouseButton = p_event
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var cb: Callable = _gui_handlers.get(Events.MOUSE_SCROLL, Callable())
				if cb.is_valid():
					cb.callv([-_mouse_wheel_step])
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var cb: Callable = _gui_handlers.get(Events.MOUSE_SCROLL, Callable())
				if cb.is_valid():
					cb.callv([_mouse_wheel_step])
			# Prevent multiple clicks from touchpads
			elif _mouse_button_locked or Time.get_ticks_msec() < _block_mouse_until_ms:
				return
			elif event.button_index == MOUSE_BUTTON_LEFT:
				#print("DeviceInput mouse left pressed")
				_mouse_left_dbl_click = event.double_click
				#print(self, " ", event)
				_mouse_left_pressed = true
				_mouse_drag_start = event.position
		elif event.is_released():
			if event.button_index == MOUSE_BUTTON_LEFT:
				#print(self, " ", event)
				if _mouse_dragging:
					_mouse_dragging = false
				elif not _mouse_left_dbl_click:
					var cb: Callable = _gui_handlers.get(Events.LEFT_CLICK, Callable())
					if cb.is_valid():
						cb.callv([event.position])
				elif _mouse_left_dbl_click:
					var cb: Callable = _gui_handlers.get(Events.LEFT_DBL_CLICK, Callable())
					if cb.is_valid():
						cb.callv([event.position])
					_mouse_left_dbl_click = false
				
				_mouse_left_pressed = false
				_ignore_next_left_click = false
				
				
	elif p_event is InputEventMouseMotion:
		var event: InputEventMouseMotion = p_event
		if _mouse_left_pressed:
			if _mouse_dragging:
				var cb: Callable = _gui_handlers.get(Events.PAN, Callable())
				if cb.is_valid():
					cb.callv([event.relative])
			else:
				if _mouse_drag_start.distance_to(event.position as Vector2) > kDragEnableDistance:
					_mouse_dragging = true
