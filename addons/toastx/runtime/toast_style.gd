@tool
class_name ToastStyle
extends Resource

@export_group("Background")
@export var background_type: ToastEnums.BackgroundType = ToastEnums.BackgroundType.COLOR
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.95)
@export var background_texture: Texture2D
@export var background_scene: PackedScene

@export_group("Icon")
@export var icon_enabled: bool = false
@export var icon_content: Texture2D
@export var icon_scene: PackedScene
@export var icon_size: Vector2 = Vector2(32, 32)
@export var icon_tint: Color = Color.WHITE
@export var icon_margin: int = 8

@export_group("Close Button")
@export var close_button_enabled: bool = false
@export var close_button_content: Texture2D
@export var close_button_scene: PackedScene
@export var close_button_size: Vector2 = Vector2(20, 20)
@export var close_button_tint: Color = Color.WHITE
@export var close_button_margin: int = 8

@export_group("Spinner (Loading)")
@export var spinner_type: ToastEnums.SpinnerType = ToastEnums.SpinnerType.NONE
@export var spinner_texture: Texture2D
@export var spinner_scene: PackedScene
@export var spinner_size: Vector2 = Vector2(24, 24)
@export var spinner_tint: Color = Color.WHITE
@export var spinner_speed: float = 1.0

@export_group("Progress Bar (Loading)")
@export var show_progress_bar: bool = false
@export var progress_bar_height: int = 4
@export var progress_bar_style: StyleBox

@export_group("Text")
@export var font: Font
@export var font_size: int = 22
@export var font_color: Color = Color.WHITE
@export var outline_size: int = 0
@export var outline_color: Color = Color.BLACK
@export var text_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER

@export_group("Layout")
@export var padding: Vector4i = Vector4i(16, 16, 16, 16)
@export var gap: int = 8
@export var minimum_width: int = 320

@export var corner_radius: int = 8
@export var use_pill_shape: bool = true
@export var border_enabled: bool = false
@export var border_width: int = 1
@export var border_color: Color = Color.WHITE

@export_group("Shadow")
@export var shadow_enabled: bool = true
@export var shadow_color: Color = Color(0, 0, 0, 0.3)
@export var shadow_offset: Vector2 = Vector2(0, 4)
@export var shadow_size: int = 4

@export_group("Behavior")
@export var tap_to_dismiss: bool = true
@export var block_input: bool = false
@export var pause_on_hover: bool = false
@export var allow_stack: bool = true
@export var max_visible: int = 3
@export var stack_strategy: ToastEnums.StackStrategy = ToastEnums.StackStrategy.REPLACE_OLDEST
@export var safe_area_margin_top: int = 20
@export var safe_area_margin_bottom: int = 20
@export var safe_area_margin_left: int = 20
@export var safe_area_margin_right: int = 20

@export_group("Swipe")
@export var swipe_enabled: bool = false
@export var swipe_direction: ToastEnums.SwipeDirection = ToastEnums.SwipeDirection.HORIZONTAL
@export var swipe_threshold: float = 50.0
@export var swipe_velocity_threshold: float = 200.0

@export_group("Deck Stack")
@export var deck_stack_scale_step: float = 0.08
@export var deck_stack_offset_step: float = 8.0
@export var deck_stack_alpha_step: float = 0.2

@export_group("Animation")
@export var default_animation: ToastEnums.ToastAnimation = ToastEnums.ToastAnimation.SLIDE
@export var animation_duration: float = 0.3
@export var animation_easing: Tween.EaseType = Tween.EASE_OUT
@export var animation_trans: Tween.TransitionType = Tween.TRANS_QUAD

@export_group("Spawn")
@export var default_origin: ToastEnums.ToastOrigin = ToastEnums.ToastOrigin.BOTTOM

func get_effective_padding(ui_scale: float = 1.0) -> Vector4i:
	return Vector4i(
		int(padding.x * ui_scale),
		int(padding.y * ui_scale),
		int(padding.z * ui_scale),
		int(padding.w * ui_scale)
	)

func get_effective_font_size(ui_scale: float = 1.0) -> int:
	return int(font_size * ui_scale)

func get_effective_icon_size(ui_scale: float = 1.0) -> Vector2:
	return icon_size * ui_scale

func get_effective_close_button_size(ui_scale: float = 1.0) -> Vector2:
	return close_button_size * ui_scale

func get_effective_spinner_size(ui_scale: float = 1.0) -> Vector2:
	return spinner_size * ui_scale

func get_effective_gap(ui_scale: float = 1.0) -> int:
	return int(gap * ui_scale)

func get_effective_minimum_width(ui_scale: float = 1.0) -> int:
	return int(minimum_width * ui_scale)


func get_effective_corner_radius(ui_scale: float = 1.0) -> int:
	return int(corner_radius * ui_scale)

func get_effective_shadow_offset(ui_scale: float = 1.0) -> Vector2:
	return shadow_offset * ui_scale

func get_effective_shadow_size(ui_scale: float = 1.0) -> int:
	return int(shadow_size * ui_scale)

func get_effective_safe_area_margins(ui_scale: float = 1.0) -> Dictionary:
	return {
		"top": int(safe_area_margin_top * ui_scale),
		"bottom": int(safe_area_margin_bottom * ui_scale),
		"left": int(safe_area_margin_left * ui_scale),
		"right": int(safe_area_margin_right * ui_scale)
	}

func get_effective_deck_stack_offset_step(ui_scale: float = 1.0) -> float:
	return deck_stack_offset_step * ui_scale

func get_effective_swipe_threshold(ui_scale: float = 1.0) -> float:
	return swipe_threshold * ui_scale
