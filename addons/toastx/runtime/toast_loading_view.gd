class_name ToastLoadingView
extends ToastView

signal progress_updated(toast_id: String, progress: float)

var progress: float = 0.0:
	set(value):
		progress = clamp(value, 0.0, 100.0)
		_on_progress_changed()

var _spinner: Control = null
var _progress_bar: ProgressBar = null

func _init():
	super._init()
	display_time = -1

func _ready():
	# super._ready() builds the layout (icon_container, text_label, etc.)
	super._ready()
	# Now that layout exists, build spinner and progress bar on top.
	_setup_spinner()
	_setup_progress_bar()
	# Remove the timer that super creates (loading toasts don't auto-dismiss).
	_remove_auto_timer()

func _remove_auto_timer():
	if _timer:
		_timer.stop()
		_timer.queue_free()
		_timer = null

func _setup_spinner():
	if not style:
		return

	match style.spinner_type:
		ToastEnums.SpinnerType.NONE:
			return
		ToastEnums.SpinnerType.DEFAULT:
			_spinner = _create_default_spinner()
		ToastEnums.SpinnerType.TEXTURE:
			if style.spinner_texture:
				_spinner = _create_texture_spinner()
			else:
				push_error("ToastLoadingView: spinner_type is TEXTURE but spinner_texture is null")
				return
		ToastEnums.SpinnerType.SCENE:
			if style.spinner_scene:
				_spinner = _create_scene_spinner()
			else:
				push_error("ToastLoadingView: spinner_type is SCENE but spinner_scene is null")
				return

	if _spinner and _icon_container:
		_icon_container.custom_minimum_size = style.get_effective_spinner_size(_ui_scale)
		# Clear any existing icon content.
		for child in _icon_container.get_children():
			child.queue_free()
		_icon_container.add_child(_spinner)
	elif _spinner == null:
		push_error("ToastLoadingView: failed to create spinner")

func _create_default_spinner() -> Control:
	var container = CenterContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.custom_minimum_size = style.get_effective_spinner_size(_ui_scale)

	var texture_rect = TextureRect.new()
	texture_rect.name = "SpinnerTexture"
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var spinner_size = style.get_effective_spinner_size(_ui_scale)
	texture_rect.custom_minimum_size = spinner_size
	texture_rect.pivot_offset = spinner_size / 2.0
	texture_rect.modulate = style.spinner_tint

	if style.spinner_texture:
		texture_rect.texture = style.spinner_texture
	else:
		texture_rect.texture = _create_default_spinner_texture(spinner_size)

	container.add_child(texture_rect)

	# Use a simple rotation tween loop instead of AnimationPlayer to avoid
	# AnimationLibrary setup issues in Godot 4.3+.
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_method(
		func(angle: float): texture_rect.rotation = angle,
		0.0, TAU,
		1.0 / maxf(0.1, style.spinner_speed)
	)

	return container

func _create_default_spinner_texture(size: Vector2) -> ImageTexture:
	var px = int(maxf(32, size.x))
	var image = Image.create(px, px, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center = Vector2(px / 2.0, px / 2.0)
	var radius = px * 0.38
	var thickness = maxf(2.0, px * 0.09)

	for x in range(px):
		for y in range(px):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist >= radius - thickness and dist <= radius + thickness:
				var angle = (pos - center).angle()
				# Fading arc: transparent at -PI, opaque at PI/2
				var normalized = fposmod(angle + PI, TAU) / TAU
				var alpha = 0.1 + 0.9 * pow(normalized, 1.5)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(image)

func _create_texture_spinner() -> Control:
	var container = CenterContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.custom_minimum_size = style.get_effective_spinner_size(_ui_scale)

	var texture_rect = TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = style.spinner_texture
	var spinner_size = style.get_effective_spinner_size(_ui_scale)
	texture_rect.custom_minimum_size = spinner_size
	texture_rect.pivot_offset = spinner_size / 2.0
	texture_rect.modulate = style.spinner_tint
	container.add_child(texture_rect)

	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_method(
		func(angle: float): texture_rect.rotation = angle,
		0.0, TAU,
		1.0 / maxf(0.1, style.spinner_speed)
	)

	return container

func _create_scene_spinner() -> Control:
	var instance = style.spinner_scene.instantiate()
	if not instance is Control:
		push_error("ToastLoadingView: spinner_scene root must be a Control")
		instance.queue_free()
		return null
	instance.custom_minimum_size = style.get_effective_spinner_size(_ui_scale)
	return instance

func _setup_progress_bar():
	if not style or not style.show_progress_bar:
		return

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = progress
	_progress_bar.custom_minimum_size.y = style.progress_bar_height
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if style.progress_bar_style:
		_progress_bar.add_theme_stylebox_override("fill", style.progress_bar_style)

	# Inject below the HBox content inside a VBox wrapper.
	# We need to restructure: wrap _content_container in a VBox and add progress bar below.
	var parent = _content_container.get_parent()
	if parent:
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 4)

		parent.remove_child(_content_container)
		vbox.add_child(_content_container)
		vbox.add_child(_progress_bar)
		parent.add_child(vbox)

func _on_progress_changed():
	if _progress_bar:
		_progress_bar.value = progress
	if not toast_id.is_empty():
		progress_updated.emit(toast_id, progress)

func update_progress(value: float, new_message: String = ""):
	progress = value
	if not new_message.is_empty():
		message = new_message
		if _text_label:
			_text_label.text = message

func complete(success: bool = true, final_message: String = ""):
	if not final_message.is_empty():
		message = final_message
		if _text_label:
			_text_label.text = message

	if _spinner:
		_spinner.visible = false

	dismiss(ToastEnums.ToastDismissReason.API)
