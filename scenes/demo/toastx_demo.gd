extends Control

@onready var message_input: LineEdit = $VBoxContainer/MessageInput

func _ready():
	message_input.text = "Hello from ToastX!"

func _on_show_toast_pressed():
	var message = message_input.text
	if message.is_empty():
		message = "Empty message!"
	ToastX.show(message)

func _on_show_success_pressed():
	ToastX.success("Operation completed successfully!")

func _on_show_error_pressed():
	ToastX.error("Something went wrong!")

func _on_show_warning_pressed():
	ToastX.warning("Please check your input!")

func _on_show_info_pressed():
	ToastX.info("Did you know? ToastX is awesome!")

func _on_show_loading_pressed():
	var id = ToastX.loading("Loading data...")

	await get_tree().create_timer(2.0).timeout
	if not id.is_empty():
		ToastX.update_loading(id, 50.0, "Halfway there...")

	await get_tree().create_timer(2.0).timeout
	if not id.is_empty():
		ToastX.complete_loading(id, true, "Done!")

func _on_show_deck_pressed():
	# Sonner-style deck: 1 active + up to 2 preview cards behind
	var deck_style = ToastStyle.new()
	deck_style.background_color = Color(0.97, 0.97, 0.99, 0.98)
	deck_style.font_color = Color(0.1, 0.1, 0.15, 1.0)
	deck_style.border_enabled = true
	deck_style.border_color = Color(0.82, 0.82, 0.88, 1.0)
	deck_style.shadow_enabled = true
	deck_style.shadow_color = Color(0, 0, 0, 0.18)
	deck_style.shadow_size = 12
	deck_style.corner_radius = 14
	deck_style.max_visible = 3
	deck_style.stack_strategy = ToastEnums.StackStrategy.DECK
	deck_style.swipe_enabled = true
	deck_style.swipe_direction = ToastEnums.SwipeDirection.BOTH
	deck_style.swipe_threshold = 40.0
	deck_style.tap_to_dismiss = true  # click OR swipe both dismiss
	deck_style.close_button_enabled = false
	# Deck preview appearance
	deck_style.deck_stack_scale_step = 0.06
	deck_style.deck_stack_offset_step = 12.0
	deck_style.deck_stack_alpha_step = 0.0  # same color; depth shown by scale only

	for i in range(5):
		ToastX.show("Deck card #%d — swipe to dismiss!" % (i + 1), deck_style, ToastEnums.ToastTime.LONG)
		await get_tree().create_timer(0.05).timeout

func _on_clear_all_pressed():
	ToastX.clear_all()


# ---------------------------------------------------------------------------
# Example: Custom Icons from assets/images
# ---------------------------------------------------------------------------

func _on_show_custom_icons_pressed():
	# Load custom icons from assets/images
	var success_icon = load("res://assets/images/success.svg")
	var warning_icon = load("res://assets/images/warning.svg")

	# Success toast with custom icon - force small icon size
	var success_style = ToastStyle.new()
	success_style.background_color = Color(0.2, 0.6, 0.3, 0.95)
	success_style.font_color = Color.WHITE
	success_style.icon_enabled = true
	success_style.icon_content = success_icon
	success_style.use_pill_shape = true
	success_style.shadow_enabled = true
	ToastX.show("Custom icon success!", success_style)

	await get_tree().create_timer(0.3).timeout

	# Warning toast with custom icon - force small icon size
	var warning_style = ToastStyle.new()
	warning_style.background_color = Color(0.9, 0.6, 0.1, 0.95)
	warning_style.font_color = Color.BLACK
	warning_style.icon_enabled = true
	warning_style.icon_content = warning_icon
	warning_style.use_pill_shape = true
	warning_style.shadow_enabled = true
	ToastX.show("Custom icon warning!", warning_style)


# ---------------------------------------------------------------------------
# Example: Medieval Style
# ---------------------------------------------------------------------------

func _on_show_medieval_pressed():
	# Medieval style with brown theme
	var medieval_style = ToastStyle.new()
	medieval_style.background_color = Color(0.35, 0.22, 0.12, 0.98)
	medieval_style.font_color = Color(0.95, 0.85, 0.6, 1.0)
	medieval_style.font_size = 18
	medieval_style.border_enabled = true
	medieval_style.border_width = 3
	medieval_style.border_color = Color(0.65, 0.45, 0.2, 1.0)
	medieval_style.corner_radius = 6
	medieval_style.shadow_enabled = true
	medieval_style.shadow_color = Color(0, 0, 0, 0.2)
	medieval_style.shadow_size = 6
	medieval_style.padding = Vector4i(24, 14, 24, 14)
	medieval_style.outline_size = 1
	medieval_style.outline_color = Color(0.15, 0.08, 0.03, 1.0)

	ToastX.show("Quest completed! Gold earned: 500", medieval_style, ToastEnums.ToastTime.LONG)

	await get_tree().create_timer(0.4).timeout

	# Second medieval toast - different color variation
	var medieval_style2 = ToastStyle.new()
	medieval_style2.background_color = Color(0.3, 0.18, 0.1, 0.98)
	medieval_style2.font_color = Color(0.9, 0.75, 0.5, 1.0)
	medieval_style2.font_size = 18
	medieval_style2.border_enabled = true
	medieval_style2.border_width = 3
	medieval_style2.border_color = Color(0.55, 0.35, 0.15, 1.0)
	medieval_style2.corner_radius = 6
	medieval_style2.shadow_enabled = true
	medieval_style2.shadow_color = Color(0, 0, 0, 0.15)
	medieval_style2.shadow_size = 4
	medieval_style2.padding = Vector4i(24, 14, 24, 14)
	medieval_style2.outline_size = 1
	medieval_style2.outline_color = Color(0.12, 0.06, 0.02, 1.0)

	ToastX.show("New armor unlocked!", medieval_style2, ToastEnums.ToastTime.MEDIUM)


# ---------------------------------------------------------------------------
# Example: Toast from center
# ---------------------------------------------------------------------------

func _on_show_center_pressed():
	var style = ToastStyle.new()
	style.background_color = Color(0.7, 0.3, 0.7, 0.95)
	style.font_color = Color.WHITE
	style.use_pill_shape = true
	style.shadow_enabled = true
	style.shadow_size = 16
	ToastX.show("Centered toast notification", style, ToastEnums.ToastTime.MEDIUM, ToastEnums.ToastOrigin.CENTER)


# ---------------------------------------------------------------------------
# Example: Toast from top
# ---------------------------------------------------------------------------

func _on_show_top_pressed():
	var style = ToastStyle.new()
	style.background_color = Color(0.95, 0.5, 0.2, 0.95)
	style.font_color = Color.WHITE
	style.use_pill_shape = true
	style.shadow_enabled = true
	ToastX.show("Top toast notification", style, ToastEnums.ToastTime.SHORT, ToastEnums.ToastOrigin.TOP)
