class_name ToastEnums

enum ToastOrigin {
	CENTER,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

enum ToastAnimation {
	SLIDE,
	FADE,
	NONE
}

enum ToastTime {
	SHORT = 2,
	MEDIUM = 4,
	LONG = 8
}

enum ToastDismissReason {
	TIMEOUT,
	CLICK,
	CLOSE_BUTTON,
	API,
	SWIPE
}

enum StackStrategy {
	DROP_NEW,
	DROP_OLDEST,
	REPLACE_OLDEST,
	QUEUE,
	DECK
}

enum BackgroundType {
	NONE,
	COLOR,
	TEXTURE,
	SCENE
}

enum SpinnerType {
	NONE,
	DEFAULT,
	TEXTURE,
	SCENE
}

enum SwipeDirection {
	NONE,
	HORIZONTAL,
	VERTICAL,
	BOTH
}
