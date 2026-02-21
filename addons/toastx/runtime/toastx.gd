extends Node

signal toast_shown(id: String)
signal toast_dismissed(id: String, reason: int)
signal toast_clicked(id: String)
signal loading_progress_updated(id: String, progress: float)
signal loading_completed(id: String, success: bool)

var proportion: float = 30.0:
	set(value):
		proportion = clamp(value, 1.0, 100.0)
		if _manager:
			_manager.set_proportion(proportion)

var default_origin: ToastEnums.ToastOrigin = ToastEnums.ToastOrigin.BOTTOM:
	set(value):
		default_origin = value
		if _manager:
			_manager.default_origin = value

var default_animation: ToastEnums.ToastAnimation = ToastEnums.ToastAnimation.SLIDE:
	set(value):
		default_animation = value
		if _manager:
			_manager.default_animation = value

var default_time: int = ToastEnums.ToastTime.MEDIUM:
	set(value):
		default_time = value
		if _manager:
			_manager.default_time = value

var _manager: ToastManager = null
var _initialized: bool = false

func _ready():
	_initialize.call_deferred()

func _initialize():
	if _initialized:
		return
	
	_manager = ToastManager.new()
	_manager.name = "ToastManager"
	add_child(_manager)
	
	_manager.proportion = proportion
	_manager.default_origin = default_origin
	_manager.default_animation = default_animation
	_manager.default_time = default_time
	
	_manager.toast_shown.connect(func(id): toast_shown.emit(id))
	_manager.toast_dismissed.connect(func(id, reason): toast_dismissed.emit(id, reason))
	_manager.toast_clicked.connect(func(id): toast_clicked.emit(id))
	_manager.loading_progress_updated.connect(func(id, progress): loading_progress_updated.emit(id, progress))
	_manager.loading_completed.connect(func(id, success): loading_completed.emit(id, success))
	
	_initialized = true

func show(
	message: String,
	style: Variant = null,
	time: Variant = null,
	origin: int = -1,
	animation: int = -1,
	options: Dictionary = {}
) -> String:
	
	if not _initialized:
		_initialize()
	
	if message.is_empty():
		push_error("ToastX: Message cannot be empty")
		return ""
	
	var resolved_style: ToastStyle
	if style == null:
		resolved_style = ToastStyles.get_style(ToastStyles.INFO)
	elif style is String:
		resolved_style = ToastStyles.get_style(style)
	elif style is ToastStyle:
		resolved_style = style
	else:
		push_error("ToastX: Invalid style type")
		return ""
	
	if resolved_style == null:
		push_error("ToastX: Could not resolve style")
		return ""
	
	var resolved_time: float
	if time is int:
		resolved_time = float(time)
	elif time is float:
		resolved_time = time
	elif time == null:
		resolved_time = float(default_time)
	else:
		resolved_time = float(default_time)
	
	var resolved_origin = origin if origin >= 0 else resolved_style.default_origin
	var resolved_animation = animation if animation >= 0 else resolved_style.default_animation
	
	return _manager.show_toast(
		message,
		resolved_style,
		resolved_time,
		resolved_origin,
		resolved_animation,
		options
	)

func show_loading(
	message: String,
	style: Variant = null,
	origin: int = -1,
	animation: int = -1,
	options: Dictionary = {}
) -> String:
	
	if not _initialized:
		_initialize()
	
	if message.is_empty():
		push_error("ToastX: Loading message cannot be empty")
		return ""
	
	var resolved_style: ToastStyle
	if style == null:
		resolved_style = ToastStyles.get_style(ToastStyles.LOADING)
	elif style is String:
		resolved_style = ToastStyles.get_style(style)
	elif style is ToastStyle:
		resolved_style = style
	else:
		push_error("ToastX: Invalid style type for loading")
		return ""
	
	if resolved_style == null:
		push_error("ToastX: Could not resolve loading style")
		return ""
	
	var resolved_origin = origin if origin >= 0 else resolved_style.default_origin
	var resolved_animation = animation if animation >= 0 else resolved_style.default_animation
	
	return _manager.show_loading(
		message,
		resolved_style,
		resolved_origin,
		resolved_animation,
		options
	)

func update_loading(toast_id: String, progress: float, new_message: String = "") -> bool:
	if not _initialized or _manager == null:
		return false
	return _manager.update_loading(toast_id, progress, new_message)

func complete_loading(toast_id: String, success: bool = true, final_message: String = "") -> bool:
	if not _initialized or _manager == null:
		return false
	return _manager.complete_loading(toast_id, success, final_message)

func loading(message: String, style: Variant = null) -> String:
	return show_loading(message, style)

func dismiss(toast_id: String) -> bool:
	if not _initialized or _manager == null:
		return false
	return _manager.dismiss_toast(toast_id)

func clear_all():
	if not _initialized or _manager == null:
		return
	_manager.clear_all()

func clear_by_origin(origin: ToastEnums.ToastOrigin):
	if not _initialized or _manager == null:
		return
	_manager.dismiss_by_origin(origin)

func quick_show(message: String, style_id: String = "info", time_seconds: float = 4.0) -> String:
	return show(message, style_id, time_seconds)

func success(message: String, time: Variant = null) -> String:
	return show(message, ToastStyles.SUCCESS, time if time != null else default_time)

func error(message: String, time: Variant = null) -> String:
	return show(message, ToastStyles.ERROR, time if time != null else default_time)

func warning(message: String, time: Variant = null) -> String:
	return show(message, ToastStyles.WARNING, time if time != null else default_time)

func info(message: String, time: Variant = null) -> String:
	return show(message, ToastStyles.INFO, time if time != null else default_time)

func configure(
	p_proportion: float = -1,
	p_default_origin: int = -1,
	p_default_animation: int = -1,
	p_default_time: int = -1
):
	if p_proportion > 0:
		proportion = p_proportion
	if p_default_origin >= 0:
		default_origin = p_default_origin
	if p_default_animation >= 0:
		default_animation = p_default_animation
	if p_default_time > 0:
		default_time = p_default_time
	
	if _manager:
		_manager.update_config(proportion, default_origin, default_animation, default_time)
