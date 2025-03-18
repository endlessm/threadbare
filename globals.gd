extends Node

enum INK_COLOR_NAMES {
		CYAN = 0,
		MAGENTA = 1,
		YELLOW = 2,
		BLACK = 3,
}

const INK_COLORS = {
		INK_COLOR_NAMES.CYAN: Color(0., 1., 1.),
		INK_COLOR_NAMES.MAGENTA: Color(1., 0., 1.),
		INK_COLOR_NAMES.YELLOW: Color(1., 1., 0.),
		INK_COLOR_NAMES.BLACK: Color(0.2, 0.2, 0.2),
}

var player: Player
