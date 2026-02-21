class_name ToastContainer
extends Control

var origin: ToastEnums.ToastOrigin
var _toasts: Array[ToastView] = []
var _queued_toasts: Array[Dictionary] = []
var _spacing: int = 8

func _init(p_origin: ToastEnums.ToastOrigin):
	origin = p_origin
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 200
	anchors_preset = Control.PRESET_FULL_RECT

func add_toast(toast_view: ToastView, strategy: int, max_visible: int) -> bool:
	if _toasts.size() >= max_visible:
		match strategy:
			ToastEnums.StackStrategy.DROP_NEW:
				toast_view.queue_free()
				return false
			ToastEnums.StackStrategy.DROP_OLDEST:
				if _toasts.size() > 0:
					_toasts[0].dismiss(ToastEnums.ToastDismissReason.API)
				_toasts.append(toast_view)
			ToastEnums.StackStrategy.REPLACE_OLDEST:
				if _toasts.size() > 0:
					_toasts[0].dismiss(ToastEnums.ToastDismissReason.API)
				_toasts.append(toast_view)
			ToastEnums.StackStrategy.QUEUE:
				_queued_toasts.append({"view": toast_view, "strategy": strategy, "max": max_visible})
				return true
	else:
		_toasts.append(toast_view)

	_add_toast_node(toast_view)
	return true

func _add_toast_node(toast_view: ToastView):
	toast_view.position = Vector2(-9999.0, -9999.0)
	add_child(toast_view)
	toast_view.dismissed.connect(_on_toast_dismissed)
	if toast_view.has_signal("swiped"):
		toast_view.swiped.connect(_on_toast_swiped)
	# Use Godot's sorting mechanism - wait for layout
	call_deferred("_position_toast_after_layout", toast_view)

func _position_toast_after_layout(toast_view: ToastView):
	if not is_instance_valid(toast_view):
		return
	# Position all visible toasts
	_position_all_toasts()
	toast_view.animate_in(_get_toast_position(toast_view))

func _get_toast_position(toast_view: ToastView) -> Vector2:
	var visible_toasts = _get_visible_toasts()
	var idx = visible_toasts.find(toast_view)
	if idx < 0:
		return Vector2.ZERO
	var positions = _calculate_positions()
	if idx < positions.size():
		return positions[idx]
	return Vector2.ZERO

func _position_all_toasts():
	var positions = _calculate_positions()
	var visible_toasts = _get_visible_toasts()
	for i in range(visible_toasts.size()):
		if i < positions.size():
			visible_toasts[i].position = positions[i]

func _on_toast_dismissed(toast_id: String, _reason: int):
	for i in range(_toasts.size()):
		if _toasts[i].toast_id == toast_id:
			_toasts.remove_at(i)
			break
	call_deferred("_reposition_toasts")
	_process_queue()

func _on_toast_swiped(toast_id: String, _direction: Vector2):
	dismiss_toast(toast_id, ToastEnums.ToastDismissReason.SWIPE)

func _process_queue():
	if _queued_toasts.is_empty():
		return
	var next = _queued_toasts.pop_front()
	add_toast(next.view, next.strategy, next.max)

func _reposition_toasts():
	var visible_toasts = _get_visible_toasts()
	if visible_toasts.is_empty():
		return
	var positions = _calculate_positions()
	for i in range(visible_toasts.size()):
		if i < positions.size():
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(visible_toasts[i], "position", positions[i], 0.2)

func _calculate_positions() -> Array:
	# Get only visible (non-dismissing) toasts
	var visible_toasts: Array[ToastView] = []
	for toast in _toasts:
		if not toast._is_dismissing:
			visible_toasts.append(toast)
	
	if visible_toasts.is_empty():
		return []

	var viewport_size = get_viewport().get_visible_rect().size
	var safe_area = _get_safe_area_margins()
	var direction = _get_stack_direction()
	var positions = []

	var anchor_y = _get_anchor_y(viewport_size, safe_area, visible_toasts)

	var current_y = anchor_y
	for toast in visible_toasts:
		# Calculate X position individually for each toast based on its width
		var toast_w = toast.size.x
		var pos_x = _calculate_x_for_toast(viewport_size, safe_area, toast_w)
		var pos = Vector2(pos_x, current_y)
		positions.append(pos)
		var toast_h = toast.size.y
		current_y += direction * (toast_h + _spacing)

	return positions

func _calculate_x_for_toast(viewport_size: Vector2, safe_area: Dictionary, toast_width: float) -> float:
	match origin:
		ToastEnums.ToastOrigin.CENTER, ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.BOTTOM:
			return (viewport_size.x - toast_width) / 2.0
		ToastEnums.ToastOrigin.LEFT, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.BOTTOM_LEFT:
			return safe_area.left + 16.0
		ToastEnums.ToastOrigin.RIGHT, ToastEnums.ToastOrigin.TOP_RIGHT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			return viewport_size.x - safe_area.right - 16.0 - toast_width
	return 0.0

func _get_visible_toasts() -> Array[ToastView]:
	var visible: Array[ToastView] = []
	for toast in _toasts:
		if not toast._is_dismissing:
			visible.append(toast)
	return visible

func _get_anchor_x(viewport_size: Vector2, safe_area: Dictionary, visible_toasts: Array[ToastView] = []) -> float:
	if visible_toasts.is_empty():
		visible_toasts = _get_visible_toasts()
	if visible_toasts.is_empty():
		return 0.0
	var toast_width = visible_toasts[0].size.x

	match origin:
		ToastEnums.ToastOrigin.CENTER, ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.BOTTOM:
			return (viewport_size.x - toast_width) / 2.0
		ToastEnums.ToastOrigin.LEFT, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.BOTTOM_LEFT:
			return safe_area.left + 16.0
		ToastEnums.ToastOrigin.RIGHT, ToastEnums.ToastOrigin.TOP_RIGHT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			return viewport_size.x - safe_area.right - 16.0 - toast_width
	return 0.0

func _get_anchor_y(viewport_size: Vector2, safe_area: Dictionary, visible_toasts: Array[ToastView] = []) -> float:
	if visible_toasts.is_empty():
		visible_toasts = _get_visible_toasts()
	
	var total_height = _calculate_total_height()

	match origin:
		ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.TOP_RIGHT:
			return safe_area.top + 16.0
		ToastEnums.ToastOrigin.BOTTOM, ToastEnums.ToastOrigin.BOTTOM_LEFT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			if visible_toasts.is_empty():
				return viewport_size.y - safe_area.bottom - 16.0
			var first_height = visible_toasts[0].size.y
			return viewport_size.y - safe_area.bottom - 16.0 - first_height
		ToastEnums.ToastOrigin.CENTER:
			return (viewport_size.y - total_height) / 2.0
		ToastEnums.ToastOrigin.LEFT, ToastEnums.ToastOrigin.RIGHT:
			return (viewport_size.y - total_height) / 2.0
	return 16.0

func _calculate_total_height() -> float:
	var total = 0.0
	var visible_count = 0
	for toast in _toasts:
		if not toast._is_dismissing:
			total += toast.size.y
			visible_count += 1
	if visible_count > 0:
		total += (visible_count - 1) * _spacing
	return total

func _get_stack_direction() -> float:
	match origin:
		ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.TOP_RIGHT:
			return 1.0
		ToastEnums.ToastOrigin.BOTTOM, ToastEnums.ToastOrigin.BOTTOM_LEFT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			return -1.0
		_:
			return 1.0

func _get_safe_area_margins() -> Dictionary:
	if _toasts.is_empty():
		return {"top": 0, "bottom": 0, "left": 0, "right": 0}
	var ui_scale = get_global_transform().get_scale().x
	return _toasts[0].style.get_effective_safe_area_margins(ui_scale)

func get_toast_count() -> int:
	return _toasts.size()

func get_toast_by_id(id: String) -> ToastView:
	for toast in _toasts:
		if toast.toast_id == id:
			return toast
	return null

func dismiss_all(reason: int = ToastEnums.ToastDismissReason.API):
	var toasts_copy = _toasts.duplicate()
	_toasts.clear()
	for toast in toasts_copy:
		if is_instance_valid(toast):
			toast.dismiss(reason)
	for queued in _queued_toasts:
		if is_instance_valid(queued.view):
			queued.view.queue_free()
	_queued_toasts.clear()

func dismiss_toast(id: String, reason: int = ToastEnums.ToastDismissReason.API) -> bool:
	for toast in _toasts:
		if toast.toast_id == id:
			toast.dismiss(reason)
			return true
	return false

func update_max_widths(max_width: float):
	for toast in _toasts:
		toast.set_max_width(max_width)
	call_deferred("_reposition_toasts")

func handle_viewport_resized():
	call_deferred("_reposition_toasts")
