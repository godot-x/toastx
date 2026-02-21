class_name ToastStyles

const SUCCESS = "success"
const WARNING = "warning"
const INFO = "info"
const ERROR = "error"
const LIGHT = "light"
const DARK = "dark"
const LOADING = "loading"

static var _styles: Dictionary = {}
static var _default_font_path: String = "res://addons/toastx/assets/fonts/Roboto-Regular.ttf"
static var _font_cache: Dictionary = {}

static func _static_init():
	_register_builtin_styles()

static func register(id: String, style: ToastStyle) -> void:
	if id.is_empty():
		push_error("ToastStyles: Cannot register style with empty id")
		return
	if style == null:
		push_error("ToastStyles: Cannot register null style for id: %s" % id)
		return
	_styles[id.to_lower()] = style

static func unregister(id: String) -> void:
	_styles.erase(id.to_lower())

static func get_style(id: Variant) -> ToastStyle:
	if id is ToastStyle:
		return id
	if id is String:
		var key = id.to_lower()
		if _styles.has(key):
			return _styles[key]
		push_error("ToastStyles: Style not found: %s" % id)
		return null
	push_error("ToastStyles: Invalid style type: %s" % typeof(id))
	return null

static func has_style(id: String) -> bool:
	return _styles.has(id.to_lower())

static func get_default_font() -> Font:
	if not _font_cache.has("default"):
		var font = load(_default_font_path) if ResourceLoader.exists(_default_font_path) else null
		if font == null:
			font = ThemeDB.get_fallback_font()
		_font_cache["default"] = font
	return _font_cache["default"]

static func clear_font_cache() -> void:
	_font_cache.clear()

static func _register_builtin_styles() -> void:
	var font = get_default_font()
	
	var success = ToastStyle.new()
	success.background_color = Color(0.13, 0.55, 0.13, 0.95)
	success.font = font
	success.font_color = Color.WHITE
	success.border_color = Color(0.2, 0.7, 0.2, 1.0)
	success.shadow_color = Color(0, 0, 0, 0.25)
	success.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(SUCCESS, success)
	
	var warning = ToastStyle.new()
	warning.background_color = Color(0.96, 0.59, 0.12, 0.95)
	warning.font = font
	warning.font_color = Color.BLACK
	warning.border_color = Color(1.0, 0.76, 0.03, 1.0)
	warning.shadow_color = Color(0, 0, 0, 0.25)
	warning.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(WARNING, warning)
	
	var info = ToastStyle.new()
	info.background_color = Color(0.13, 0.47, 0.76, 0.95)
	info.font = font
	info.font_color = Color.WHITE
	info.border_color = Color(0.25, 0.6, 0.9, 1.0)
	info.shadow_color = Color(0, 0, 0, 0.25)
	info.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(INFO, info)
	
	var error = ToastStyle.new()
	error.background_color = Color(0.83, 0.18, 0.18, 0.95)
	error.font = font
	error.font_color = Color.WHITE
	error.border_color = Color(0.95, 0.3, 0.3, 1.0)
	error.shadow_color = Color(0, 0, 0, 0.3)
	error.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(ERROR, error)
	
	var light = ToastStyle.new()
	light.background_color = Color(0.95, 0.95, 0.95, 0.98)
	light.font = font
	light.font_color = Color(0.13, 0.13, 0.13, 1.0)
	light.border_enabled = true
	light.border_color = Color(0.8, 0.8, 0.8, 1.0)
	light.shadow_color = Color(0, 0, 0, 0.15)
	light.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(LIGHT, light)
	
	var dark = ToastStyle.new()
	dark.background_color = Color(0.2, 0.2, 0.2, 0.98)
	dark.font = font
	dark.font_color = Color(0.95, 0.95, 0.95, 1.0)
	dark.border_enabled = true
	dark.border_color = Color(0.4, 0.4, 0.4, 1.0)
	dark.shadow_color = Color(0, 0, 0, 0.4)
	dark.default_origin = ToastEnums.ToastOrigin.BOTTOM
	register(DARK, dark)
	
	var loading = ToastStyle.new()
	loading.background_color = Color(0.25, 0.25, 0.25, 0.98)
	loading.font = font
	loading.font_color = Color.WHITE
	loading.border_enabled = true
	loading.border_color = Color(0.5, 0.5, 0.5, 0.5)
	loading.shadow_color = Color(0, 0, 0, 0.4)
	loading.shadow_enabled = true
	loading.default_origin = ToastEnums.ToastOrigin.BOTTOM
	# Spinner configuration
	loading.spinner_type = ToastEnums.SpinnerType.DEFAULT
	loading.spinner_tint = Color(0.4, 0.7, 1.0)
	loading.spinner_speed = 1.5
	loading.spinner_size = Vector2(28, 28)
	# Make icon slot visible so spinner renders
	loading.icon_enabled = true
	loading.icon_size = Vector2(28, 28)
	# Prevent user from dismissing loading toasts
	loading.tap_to_dismiss = false
	loading.swipe_enabled = false
	loading.close_button_enabled = false
	loading.max_visible = 1
	loading.stack_strategy = ToastEnums.StackStrategy.REPLACE_OLDEST
	loading.default_animation = ToastEnums.ToastAnimation.FADE
	register(LOADING, loading)
