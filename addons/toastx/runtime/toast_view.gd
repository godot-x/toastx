## ToastView — single toast notification node.
##
## Architecture: extends PanelContainer.
## • Background (COLOR): StyleBoxFlat applied to the "panel" theme slot.
##   StyleBoxFlat.content_margin_* provides the padding — no extra containers needed.
## • Background (TEXTURE/SCENE): StyleBoxEmpty on "panel" slot + a TextureRect/
##   scene child positioned with z_index < 0 so it renders behind the content.
## • Content: HBoxContainer [icon | label | close] fills the PanelContainer naturally.
##
## PanelContainer sizes itself to max(custom_minimum_size, content + content_margin),
## which gives correct, compact toasts without any manual height calculation.
class_name ToastView
extends PanelContainer

signal clicked(toast_id: String)
signal close_requested(toast_id: String)
signal dismissed(toast_id: String, reason: int)
signal swiped(toast_id: String, direction: Vector2)

var toast_id: String
var style: ToastStyle
var message: String
var display_time: float
var origin: ToastEnums.ToastOrigin
var animation: ToastEnums.ToastAnimation

var _ui_scale: float = 1.0
var _timer: Timer
var _is_hovering: bool = false
var _is_dismissing: bool = false
var _tween: Tween
var _content_container: HBoxContainer
var _icon_container: Control
var _text_label: Label
var _close_container: Control

var _is_dragging: bool = false
var _drag_start_pos: Vector2
var _drag_current_pos: Vector2
var _drag_start_mouse: Vector2

func _init():
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 100
	anchors_preset = Control.PRESET_TOP_LEFT
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _ready():
	_ui_scale = _get_ui_scale()
	_setup_background()
	_setup_layout()
	_apply_style()
	_setup_timer()
	_setup_input()

func _get_ui_scale() -> float:
	var s = get_global_transform().get_scale().x
	return s if s > 0.01 else 1.0

# ---------------------------------------------------------------------------
# Background
# ---------------------------------------------------------------------------

func _setup_background():
	var p = style.get_effective_padding(_ui_scale)

	match style.background_type:
		ToastEnums.BackgroundType.NONE:
			var empty = StyleBoxEmpty.new()
			# Content margin keeps padding even with no visible background
			empty.content_margin_left   = p.x
			empty.content_margin_top    = p.y
			empty.content_margin_right  = p.z
			empty.content_margin_bottom = p.w
			add_theme_stylebox_override("panel", empty)

		ToastEnums.BackgroundType.COLOR:
			var sb = StyleBoxFlat.new()
			sb.bg_color = style.background_color
			var cr: int
			if style.use_pill_shape:
				# Pill shape: corner radius = half of estimated height
				var font_size = style.get_effective_font_size(_ui_scale)
				var padding = style.get_effective_padding(_ui_scale)
				var estimated_height = font_size + padding.y + padding.w + 4  # Extra for better pill shape
				cr = int(estimated_height / 2.0)
			else:
				cr = style.get_effective_corner_radius(_ui_scale)
			sb.corner_radius_top_left    = cr
			sb.corner_radius_top_right   = cr
			sb.corner_radius_bottom_left  = cr
			sb.corner_radius_bottom_right = cr
			if style.border_enabled:
				sb.border_width_left   = style.border_width
				sb.border_width_top    = style.border_width
				sb.border_width_right  = style.border_width
				sb.border_width_bottom = style.border_width
				sb.border_color        = style.border_color
			if style.shadow_enabled:
				sb.shadow_color  = style.shadow_color
				sb.shadow_size   = style.get_effective_shadow_size(_ui_scale)
				sb.shadow_offset = style.get_effective_shadow_offset(_ui_scale)
			sb.content_margin_left   = p.x
			sb.content_margin_top    = p.y
			sb.content_margin_right  = p.z
			sb.content_margin_bottom = p.w
			add_theme_stylebox_override("panel", sb)

		ToastEnums.BackgroundType.TEXTURE:
			if style.background_texture:
				# Transparent panel + texture child behind content.
				var empty = StyleBoxEmpty.new()
				empty.content_margin_left   = p.x
				empty.content_margin_top    = p.y
				empty.content_margin_right  = p.z
				empty.content_margin_bottom = p.w
				add_theme_stylebox_override("panel", empty)
				var tx = TextureRect.new()
				tx.texture       = style.background_texture
				tx.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				tx.z_index       = -1
				tx.mouse_filter  = Control.MOUSE_FILTER_IGNORE
				# Anchors fill the PanelContainer, ignoring content_margin.
				tx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				add_child(tx)
			else:
				push_error("ToastView: background_type TEXTURE but background_texture is null")

		ToastEnums.BackgroundType.SCENE:
			if style.background_scene:
				var empty = StyleBoxEmpty.new()
				empty.content_margin_left   = p.x
				empty.content_margin_top    = p.y
				empty.content_margin_right  = p.z
				empty.content_margin_bottom = p.w
				add_theme_stylebox_override("panel", empty)
				var inst = style.background_scene.instantiate()
				if inst is Control:
					inst.z_index      = -1
					inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
					inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					add_child(inst)
				else:
					push_error("ToastView: background_scene root must be a Control")
					inst.queue_free()
			else:
				push_error("ToastView: background_type SCENE but background_scene is null")

# ---------------------------------------------------------------------------
# Layout — [icon | label | close] inside PanelContainer
# ---------------------------------------------------------------------------

func _setup_layout():
	_content_container = HBoxContainer.new()
	_content_container.alignment        = BoxContainer.ALIGNMENT_CENTER
	_content_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_content_container.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	_content_container.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	_content_container.add_theme_constant_override("separation", style.get_effective_gap(_ui_scale))
	add_child(_content_container)

	_icon_container = Control.new()
	_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_icon_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_content_container.add_child(_icon_container)

	_text_label = Label.new()
	_text_label.horizontal_alignment = style.text_alignment
	_text_label.vertical_alignment   = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode        = TextServer.AUTOWRAP_OFF

	_text_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_text_label.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	_text_label.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	_content_container.add_child(_text_label)

	_close_container = Control.new()
	_close_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_content_container.add_child(_close_container)

# ---------------------------------------------------------------------------
# Style application
# ---------------------------------------------------------------------------

func _apply_style():
	var font_to_use: Font = style.font if style.font else ToastStyles.get_default_font()
	if font_to_use:
		_text_label.add_theme_font_override("font", font_to_use)
	_text_label.add_theme_font_size_override("font_size", style.get_effective_font_size(_ui_scale))
	_text_label.add_theme_color_override("font_color", style.font_color)
	if style.outline_size > 0:
		_text_label.add_theme_constant_override("outline_size", style.outline_size)
		_text_label.add_theme_color_override("font_outline_color", style.outline_color)
	_text_label.text = message

	_setup_icon()
	_setup_close_button()

	# Apply padding as custom_minimum_size to ensure consistent height across all background types
	var pad = style.get_effective_padding(_ui_scale)
	var font_size = style.get_effective_font_size(_ui_scale)
	# Height: font size + vertical padding (top + bottom)
	var min_height = font_size + pad.y + pad.w
	custom_minimum_size.y = min_height

func _setup_icon():
	for ch in _icon_container.get_children():
		ch.queue_free()
	if not style.icon_enabled:
		_icon_container.custom_minimum_size = Vector2.ZERO
		return
	var sz = style.get_effective_icon_size(_ui_scale)
	_icon_container.custom_minimum_size = sz
	_icon_container.size = sz
	if style.icon_scene:
		var inst = style.icon_scene.instantiate()
		if inst is Control:
			inst.custom_minimum_size = sz
			inst.size = sz
			_icon_container.add_child(inst)
		else:
			push_error("ToastView: icon_scene root must be a Control")
			inst.queue_free()
	elif style.icon_content:
		var tx = TextureRect.new()
		tx.texture      = style.icon_content
		tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tx.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tx.modulate     = style.icon_tint
		# Force exact size and center the icon
		tx.custom_minimum_size = sz
		tx.size = sz
		tx.position = Vector2.ZERO
		tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_container.add_child(tx)

func _setup_close_button():
	for ch in _close_container.get_children():
		ch.queue_free()
	if not style.close_button_enabled:
		_close_container.custom_minimum_size = Vector2.ZERO
		return
	var sz = style.get_effective_close_button_size(_ui_scale)
	_close_container.custom_minimum_size = sz
	_close_container.mouse_filter        = Control.MOUSE_FILTER_STOP
	if style.close_button_scene:
		var inst = style.close_button_scene.instantiate()
		if inst is Control:
			inst.custom_minimum_size = sz
			inst.size = sz
			_close_container.add_child(inst)
		else:
			push_error("ToastView: close_button_scene root must be a Control")
			inst.queue_free()
	elif style.close_button_content:
		var tx = TextureRect.new()
		tx.texture      = style.close_button_content
		tx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tx.modulate     = style.close_button_tint
		tx.custom_minimum_size = sz
		tx.size         = sz
		tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_close_container.add_child(tx)
	_close_container.gui_input.connect(_on_close_input)

# ---------------------------------------------------------------------------
# Timer
# ---------------------------------------------------------------------------

func _setup_timer():
	if display_time <= 0:
		return
	_timer = Timer.new()
	_timer.one_shot   = true
	_timer.wait_time  = display_time
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	_timer.start()

# ---------------------------------------------------------------------------
# Input — all handled via gui_input (MOUSE_FILTER_STOP ensures only the
# topmost node receives events; critical for the deck's active-only behavior).
# ---------------------------------------------------------------------------

func _setup_input():
	gui_input.connect(_on_gui_input)
	if style.pause_on_hover:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _on_gui_input(event: InputEvent):
	if _is_dismissing:
		return

	var threshold = style.get_effective_swipe_threshold(_ui_scale)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos   = position
			_drag_start_mouse = event.global_position
			_drag_current_pos = event.global_position
		else:
			if _is_dragging:
				_is_dragging = false
				var did_swipe = _evaluate_swipe(threshold)
				if not did_swipe and style.tap_to_dismiss:
					clicked.emit(toast_id)
					dismiss(ToastEnums.ToastDismissReason.CLICK)

	elif event is InputEventMouseMotion and _is_dragging:
		_drag_current_pos = event.global_position
		if style.swipe_enabled:
			_update_drag_position()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_is_dragging = true
			_drag_start_pos   = position
			_drag_start_mouse = event.position
			_drag_current_pos = event.position
		else:
			if _is_dragging:
				_is_dragging = false
				var did_swipe = _evaluate_swipe(threshold)
				if not did_swipe and style.tap_to_dismiss:
					clicked.emit(toast_id)
					dismiss(ToastEnums.ToastDismissReason.CLICK)

	elif event is InputEventScreenDrag and _is_dragging:
		_drag_current_pos = event.position
		if style.swipe_enabled:
			_update_drag_position()

func _on_close_input(event: InputEvent):
	if _is_dismissing:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_requested.emit(toast_id)
		dismiss(ToastEnums.ToastDismissReason.CLOSE_BUTTON)
	elif event is InputEventScreenTouch and event.pressed:
		close_requested.emit(toast_id)
		dismiss(ToastEnums.ToastDismissReason.CLOSE_BUTTON)

func _update_drag_position():
	var delta = _drag_current_pos - _drag_start_mouse
	match style.swipe_direction:
		ToastEnums.SwipeDirection.HORIZONTAL:
			position.x = _drag_start_pos.x + delta.x
		ToastEnums.SwipeDirection.VERTICAL:
			position.y = _drag_start_pos.y + delta.y
		ToastEnums.SwipeDirection.BOTH:
			position = _drag_start_pos + delta

func _evaluate_swipe(threshold: float) -> bool:
	if not style.swipe_enabled:
		return false
	var delta = _drag_current_pos - _drag_start_mouse
	var direction = Vector2.ZERO
	match style.swipe_direction:
		ToastEnums.SwipeDirection.HORIZONTAL:
			if abs(delta.x) > threshold:
				direction = Vector2(sign(delta.x), 0)
		ToastEnums.SwipeDirection.VERTICAL:
			if abs(delta.y) > threshold:
				direction = Vector2(0, sign(delta.y))
		ToastEnums.SwipeDirection.BOTH:
			if delta.length() > threshold:
				direction = delta.normalized()
	if direction != Vector2.ZERO:
		_swipe_out(direction)
		return true
	if delta.length() > 2.0:
		_snap_back()
	return false

func _swipe_out(direction: Vector2):
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(style.animation_easing)
	_tween.set_trans(style.animation_trans)
	var vp    = get_viewport().get_visible_rect().size
	var target = position
	if direction.x != 0:
		target.x = (vp.x + size.x) * sign(direction.x)
	if direction.y != 0:
		target.y = (vp.y + size.y) * sign(direction.y)
	_tween.tween_property(self, "position", target, 0.2)
	_tween.tween_callback(func():
		swiped.emit(toast_id, direction)
		_complete_dismiss(ToastEnums.ToastDismissReason.SWIPE)
	)

func _snap_back():
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_SPRING)
	_tween.tween_property(self, "position", _drag_start_pos, 0.3)

func _on_mouse_entered():
	_is_hovering = true
	if _timer:
		_timer.paused = true

func _on_mouse_exited():
	_is_hovering = false
	if _timer:
		_timer.paused = false

func _on_timeout():
	if not _is_dismissing:
		dismiss(ToastEnums.ToastDismissReason.TIMEOUT)

# ---------------------------------------------------------------------------
# Dismiss
# ---------------------------------------------------------------------------

func dismiss(reason: int = ToastEnums.ToastDismissReason.API):
	if _is_dismissing:
		return
	_is_dismissing = true
	if _timer:
		_timer.stop()
	_animate_out(reason)

func _animate_out(reason: int):
	if _tween and _tween.is_valid():
		_tween.kill()
	if animation == ToastEnums.ToastAnimation.NONE:
		_complete_dismiss(reason)
		return
	_tween = create_tween()
	_tween.set_ease(style.animation_easing)
	_tween.set_trans(style.animation_trans)
	match animation:
		ToastEnums.ToastAnimation.SLIDE:
			_tween.tween_property(self, "position", _get_slide_out_pos(), style.animation_duration)
		ToastEnums.ToastAnimation.FADE:
			_tween.tween_property(self, "modulate:a", 0.0, style.animation_duration)
	_tween.tween_callback(_complete_dismiss.bind(reason))

func _complete_dismiss(reason: int):
	dismissed.emit(toast_id, reason)
	queue_free()

# ---------------------------------------------------------------------------
# Animate in
# ---------------------------------------------------------------------------

func animate_in(target_position: Vector2):
	if _tween and _tween.is_valid():
		_tween.kill()
	if animation == ToastEnums.ToastAnimation.NONE:
		position = target_position
		return
	match animation:
		ToastEnums.ToastAnimation.SLIDE:
			position = _slide_in_start(target_position)
			modulate.a = 1.0
			_tween = create_tween()
			_tween.set_ease(style.animation_easing)
			_tween.set_trans(style.animation_trans)
			_tween.tween_property(self, "position", target_position, style.animation_duration)
		ToastEnums.ToastAnimation.FADE:
			position  = target_position
			modulate.a = 0.0
			_tween = create_tween()
			_tween.set_ease(style.animation_easing)
			_tween.set_trans(style.animation_trans)
			_tween.tween_property(self, "modulate:a", 1.0, style.animation_duration)

func _slide_in_start(target: Vector2) -> Vector2:
	var vp = get_viewport().get_visible_rect().size
	var s  = target
	match origin:
		ToastEnums.ToastOrigin.LEFT, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.BOTTOM_LEFT:
			s.x = -size.x - 50
		ToastEnums.ToastOrigin.RIGHT, ToastEnums.ToastOrigin.TOP_RIGHT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			s.x = vp.x + 50
		ToastEnums.ToastOrigin.TOP:
			s.y = -size.y - 50
		_:  # BOTTOM, CENTER
			s.y = vp.y + 50
	return s

func _get_slide_out_pos() -> Vector2:
	var vp = get_viewport().get_visible_rect().size
	var t  = position
	match origin:
		ToastEnums.ToastOrigin.LEFT, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.BOTTOM_LEFT:
			t.x = -size.x - 50
		ToastEnums.ToastOrigin.RIGHT, ToastEnums.ToastOrigin.TOP_RIGHT, ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			t.x = vp.x + 50
		ToastEnums.ToastOrigin.TOP:
			t.y = -size.y - 50
		_:  # BOTTOM, CENTER
			t.y = vp.y + 50
	return t

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

var _max_width: float = 0.0

func set_max_width(max_w: float):
	_max_width = max_w
	# Apply max width constraint if needed
	if _max_width > 0 and size.x > _max_width:
		custom_minimum_size.x = _max_width

func update_style(new_style: ToastStyle, new_ui_scale: float = 1.0):
	style     = new_style
	_ui_scale = new_ui_scale
	_apply_style()
