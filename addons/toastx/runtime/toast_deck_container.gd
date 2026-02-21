## ToastDeckContainer — Sonner-style stacked deck.
##
## Architecture:
##   _visible_cards[0]          = active front card (full interaction, normal scale)
##   _visible_cards[1..MAX_PREVIEWS] = preview cards (no interaction, scaled/offset)
##   _deck_queue                = cards waiting to enter the scene
##
## When the front card is dismissed, preview[1] animates to the active position,
## preview[2] moves to preview[1] slot, and a new card from the queue fills the
## last preview slot — everything stays visible and transitions smoothly.
class_name ToastDeckContainer
extends ToastContainer

const MAX_PREVIEWS: int = 2

## Cards currently in the scene (indices 0 = front active, 1+ = previews).
var _visible_cards: Array[ToastView] = []
## Cards waiting — not yet added to the scene.
var _deck_queue: Array[ToastView] = []

## Deduplication flag: ensures _do_layout() runs at most once per frame.
var _layout_pending: bool = false

func _init(p_origin: ToastEnums.ToastOrigin):
	super(p_origin)

# ---------------------------------------------------------------------------
# add_toast — override for DECK strategy
# ---------------------------------------------------------------------------

func add_toast(toast_view: ToastView, strategy: int, _max_visible: int) -> bool:
	if strategy != ToastEnums.StackStrategy.DECK:
		return super.add_toast(toast_view, strategy, _max_visible)

	if _visible_cards.size() < 1 + MAX_PREVIEWS:
		_push_to_visible(toast_view)
	else:
		_deck_queue.push_back(toast_view)

	return true

# ---------------------------------------------------------------------------
# Adding cards to the visible stack
# ---------------------------------------------------------------------------

func _push_to_visible(toast_view: ToastView):
	var slot = _visible_cards.size()
	_visible_cards.append(toast_view)

	toast_view.position = Vector2(-9999.0, -9999.0)  # off-screen until positioned
	toast_view.z_index  = 20 - slot

	if slot == 0:
		# Active card — normal behavior, full interaction.
		toast_view.dismissed.connect(_on_active_dismissed)
	else:
		# Preview card — disable timer and input before _ready() fires.
		_enter_preview(toast_view)

	add_child(toast_view)
	_schedule_layout()

func _enter_preview(toast_view: ToastView):
	## Called BEFORE add_child so _ready() sees display_time=-1 and skips the timer.
	toast_view.set_meta("_deck_original_display_time", toast_view.display_time)
	toast_view.display_time  = -1  # prevents _setup_timer() from running in _ready()
	toast_view.mouse_filter  = Control.MOUSE_FILTER_IGNORE

func _exit_preview(toast_view: ToastView):
	## Promotes a preview card to the active front slot.
	var orig_time: float = toast_view.get_meta("_deck_original_display_time", -1.0)
	toast_view.display_time = orig_time
	toast_view.mouse_filter = Control.MOUSE_FILTER_STOP
	# Reset visual transform (was scaled/offset as a preview).
	toast_view.scale        = Vector2.ONE
	toast_view.pivot_offset = Vector2.ZERO
	# Start the auto-dismiss timer now that the card is in front.
	if orig_time > 0:
		toast_view._setup_timer()

# ---------------------------------------------------------------------------
# Layout — position all visible cards in their correct slots
# ---------------------------------------------------------------------------

func _schedule_layout():
	if _layout_pending:
		return
	_layout_pending = true
	call_deferred("_do_layout")

func _do_layout():
	_layout_pending = false
	if _visible_cards.is_empty():
		return

	var front = _visible_cards[0]
	if not is_instance_valid(front):
		return

	var active_pos = _compute_active_position(front)
	var card_w = front.size.x

	for i in range(_visible_cards.size()):
		var card = _visible_cards[i]
		if not is_instance_valid(card):
			continue
		card.z_index = 20 - i
		if i == 0:
			if card.position.x < -100:
				card.animate_in(active_pos)
		else:
			var card_h = card.size.y
			var sf    = _scale_for_slot(i, card.style)
			var pivot = _pivot_for_slot(card_w, card_h)
			var pos   = _pos_for_slot(active_pos, card_h, i, sf, card.style)
			card.pivot_offset = pivot
			card.scale        = Vector2(sf, sf)
			card.position     = pos

# ---------------------------------------------------------------------------
# Transition after the front card is dismissed
# ---------------------------------------------------------------------------

func _on_active_dismissed(_toast_id: String, _reason: int):
	if _visible_cards.is_empty():
		return
	_visible_cards.remove_at(0)  # front card frees itself via queue_free()

	# Fill empty preview slots from the queue.
	while _visible_cards.size() < 1 + MAX_PREVIEWS and not _deck_queue.is_empty():
		var queued = _deck_queue.pop_front()
		queued.position = Vector2(-9999.0, -9999.0)
		# Enter preview BEFORE add_child to suppress the timer in _ready().
		_enter_preview(queued)
		_visible_cards.append(queued)
		queued.z_index = 20 - (_visible_cards.size() - 1)
		add_child(queued)

	if _visible_cards.is_empty():
		return

	# Promote the new front card: restore interaction + timer.
	var new_front = _visible_cards[0]
	if is_instance_valid(new_front):
		_exit_preview(new_front)
		new_front.z_index = 20
		new_front.dismissed.connect(_on_active_dismissed)

	# Animate all visible cards to their updated slot positions.
	call_deferred("_animate_transition")

func _animate_transition():
	if _visible_cards.is_empty():
		return

	var front = _visible_cards[0]
	if not is_instance_valid(front):
		return

	var active_pos = _compute_active_position(front)
	var card_w = front.size.x

	var dur = 0.28

	for i in range(_visible_cards.size()):
		var card = _visible_cards[i]
		if not is_instance_valid(card):
			continue
		card.z_index = 20 - i

		if i == 0:
			var tw = card.create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_CUBIC)
			tw.set_parallel(true)
			tw.tween_property(card, "position",     active_pos,   dur)
			tw.tween_property(card, "scale",        Vector2.ONE,  dur)
			tw.tween_property(card, "pivot_offset", Vector2.ZERO, dur)
		else:
			var card_h       = card.size.y
			var sf           = _scale_for_slot(i, card.style)
			var target_pos   = _pos_for_slot(active_pos, card_h, i, sf, card.style)
			var target_pivot = _pivot_for_slot(card_w, card_h)
			if card.position.x < -100:
				# brand-new card from queue: place directly, no tween needed
				card.pivot_offset = target_pivot
				card.scale        = Vector2(sf, sf)
				card.position     = target_pos
			else:
				var tw = card.create_tween()
				tw.set_ease(Tween.EASE_OUT)
				tw.set_trans(Tween.TRANS_CUBIC)
				tw.set_parallel(true)
				tw.tween_property(card, "position",     target_pos,      dur)
				tw.tween_property(card, "scale",        Vector2(sf, sf), dur)
				tw.tween_property(card, "pivot_offset", target_pivot,    dur)

# ---------------------------------------------------------------------------
# Position / scale / pivot helpers
# ---------------------------------------------------------------------------

func _scale_for_slot(slot: int, style: ToastStyle) -> float:
	return clamp(1.0 - slot * style.deck_stack_scale_step, 0.5, 1.0)

## Returns the pivot that keeps the near edge of each preview aligned with
## the near edge of the active card as scale shrinks toward the background.
## BOTTOM/CENTER/LEFT/RIGHT → pivot at bottom-center (w/2, h): shrinks upward.
## TOP → pivot at top-center (w/2, 0): shrinks downward.
func _pivot_for_slot(w: float, h: float) -> Vector2:
	match origin:
		ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.TOP_RIGHT:
			return Vector2(w / 2.0, 0.0)
		_:
			return Vector2(w / 2.0, h)

## Previews fan away from the active card toward the background:
## BOTTOM: previews move up  → pos.y decreases by offset_step per slot.
## TOP:    previews move down → pos.y increases by offset_step per slot.
func _pos_for_slot(active_pos: Vector2, _h: float, slot: int,
		_scale: float, style: ToastStyle) -> Vector2:
	var offset = style.get_effective_deck_stack_offset_step(1.0) * slot
	var pos    = active_pos
	match origin:
		ToastEnums.ToastOrigin.TOP, ToastEnums.ToastOrigin.TOP_LEFT, ToastEnums.ToastOrigin.TOP_RIGHT:
			pos.y = active_pos.y + offset
		_:
			pos.y = active_pos.y - offset
	return pos

# ---------------------------------------------------------------------------
# Active-card position (from deck origin settings)
# ---------------------------------------------------------------------------

func _compute_active_position(toast_view: ToastView) -> Vector2:
	var vp  = get_viewport().get_visible_rect().size
	var ui  = toast_view._ui_scale
	var sa  = toast_view.style.get_effective_safe_area_margins(ui)
	var w   = toast_view.size.x if toast_view.size.x > 1 else toast_view.custom_minimum_size.x
	var h   = toast_view.size.y if toast_view.size.y > 1 else toast_view.custom_minimum_size.y
	var pad = 16.0

	match origin:
		ToastEnums.ToastOrigin.BOTTOM:
			return Vector2((vp.x - w) / 2.0,            vp.y - sa.bottom - pad - h)
		ToastEnums.ToastOrigin.BOTTOM_LEFT:
			return Vector2(sa.left + pad,                vp.y - sa.bottom - pad - h)
		ToastEnums.ToastOrigin.BOTTOM_RIGHT:
			return Vector2(vp.x - sa.right - pad - w,   vp.y - sa.bottom - pad - h)
		ToastEnums.ToastOrigin.TOP:
			return Vector2((vp.x - w) / 2.0,            sa.top + pad)
		ToastEnums.ToastOrigin.TOP_LEFT:
			return Vector2(sa.left + pad,                sa.top + pad)
		ToastEnums.ToastOrigin.TOP_RIGHT:
			return Vector2(vp.x - sa.right - pad - w,   sa.top + pad)
		ToastEnums.ToastOrigin.LEFT:
			return Vector2(sa.left + pad,                (vp.y - h) / 2.0)
		ToastEnums.ToastOrigin.RIGHT:
			return Vector2(vp.x - sa.right - pad - w,   (vp.y - h) / 2.0)
		_:  # CENTER
			return Vector2((vp.x - w) / 2.0,            (vp.y - h) / 2.0)

# ---------------------------------------------------------------------------
# Overrides
# ---------------------------------------------------------------------------

func dismiss_all(reason: int = ToastEnums.ToastDismissReason.API):
	for card in _visible_cards:
		if is_instance_valid(card):
			card.queue_free()
	_visible_cards.clear()
	for card in _deck_queue:
		if is_instance_valid(card):
			card.queue_free()
	_deck_queue.clear()

func dismiss_toast(id: String, reason: int = ToastEnums.ToastDismissReason.API) -> bool:
	for i in range(_visible_cards.size()):
		if is_instance_valid(_visible_cards[i]) and _visible_cards[i].toast_id == id:
			_visible_cards[i].dismiss(reason)
			return true
	for i in range(_deck_queue.size()):
		if is_instance_valid(_deck_queue[i]) and _deck_queue[i].toast_id == id:
			_deck_queue[i].queue_free()
			_deck_queue.remove_at(i)
			return true
	return false

func get_queued_count() -> int:
	return _deck_queue.size()

func handle_viewport_resized():
	_schedule_layout()
