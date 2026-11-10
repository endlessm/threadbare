# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends RefCounted
## Las letras cursivas que escribe el hilo en final_hilo.gd.
## En "em": 1 = altura de la x; y hacia arriba, 0 = renglón.

const CURSIVA: Dictionary = {
	"e":
	[
		0.8,
		[
			Vector2(0.0, 0.15),
			Vector2(0.3, 0.35),
			Vector2(0.6, 0.62),
			Vector2(0.62, 0.88),
			Vector2(0.45, 1.0),
			Vector2(0.22, 0.88),
			Vector2(0.12, 0.5),
			Vector2(0.2, 0.15),
			Vector2(0.45, 0.0),
			Vector2(0.75, 0.12)
		],
		[]
	],
	"l":
	[
		0.75,
		[
			Vector2(0.0, 0.15),
			Vector2(0.35, 0.8),
			Vector2(0.62, 1.55),
			Vector2(0.6, 2.05),
			Vector2(0.4, 2.2),
			Vector2(0.2, 1.95),
			Vector2(0.18, 1.2),
			Vector2(0.2, 0.5),
			Vector2(0.3, 0.08),
			Vector2(0.5, 0.0),
			Vector2(0.72, 0.12)
		],
		[]
	],
	"h":
	[
		1.1,
		[
			Vector2(0.0, 0.15),
			Vector2(0.35, 0.8),
			Vector2(0.62, 1.55),
			Vector2(0.6, 2.05),
			Vector2(0.4, 2.2),
			Vector2(0.2, 1.95),
			Vector2(0.18, 1.2),
			Vector2(0.2, 0.5),
			Vector2(0.18, 0.0),
			Vector2(0.26, 0.55),
			Vector2(0.5, 0.92),
			Vector2(0.72, 0.88),
			Vector2(0.8, 0.6),
			Vector2(0.78, 0.2),
			Vector2(0.9, 0.0),
			Vector2(1.1, 0.12)
		],
		[]
	],
	"i":
	[
		0.62,
		[
			Vector2(0.0, 0.15),
			Vector2(0.22, 0.7),
			Vector2(0.3, 1.0),
			Vector2(0.25, 0.4),
			Vector2(0.3, 0.08),
			Vector2(0.45, 0.0),
			Vector2(0.62, 0.12)
		],
		[[Vector2(0.3, 1.42)]]
	],
	"í":
	[
		0.62,
		[
			Vector2(0.0, 0.15),
			Vector2(0.22, 0.7),
			Vector2(0.3, 1.0),
			Vector2(0.25, 0.4),
			Vector2(0.3, 0.08),
			Vector2(0.45, 0.0),
			Vector2(0.62, 0.12)
		],
		[[Vector2(0.22, 1.3), Vector2(0.5, 1.65)]]
	],
	"o":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.28, 0.55),
			Vector2(0.5, 0.95),
			Vector2(0.72, 0.8),
			Vector2(0.72, 0.3),
			Vector2(0.5, 0.0),
			Vector2(0.25, 0.15),
			Vector2(0.25, 0.6),
			Vector2(0.5, 0.95),
			Vector2(0.75, 0.92),
			Vector2(0.95, 0.85)
		],
		[]
	],
	"q":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.45, 0.8),
			Vector2(0.62, 0.95),
			Vector2(0.38, 1.0),
			Vector2(0.12, 0.7),
			Vector2(0.15, 0.2),
			Vector2(0.4, 0.02),
			Vector2(0.6, 0.4),
			Vector2(0.66, 0.95),
			Vector2(0.64, 0.2),
			Vector2(0.6, -0.6),
			Vector2(0.48, -1.15),
			Vector2(0.35, -0.95),
			Vector2(0.45, -0.45),
			Vector2(0.7, -0.05),
			Vector2(0.92, 0.12)
		],
		[]
	],
	"u":
	[
		1.0,
		[
			Vector2(0.0, 0.15),
			Vector2(0.18, 0.75),
			Vector2(0.22, 1.0),
			Vector2(0.18, 0.35),
			Vector2(0.3, 0.03),
			Vector2(0.5, 0.1),
			Vector2(0.65, 0.6),
			Vector2(0.72, 1.0),
			Vector2(0.68, 0.35),
			Vector2(0.78, 0.02),
			Vector2(1.0, 0.12)
		],
		[]
	],
	"n":
	[
		1.05,
		[
			Vector2(0.0, 0.15),
			Vector2(0.2, 0.75),
			Vector2(0.28, 1.0),
			Vector2(0.26, 0.5),
			Vector2(0.24, 0.0),
			Vector2(0.33, 0.55),
			Vector2(0.55, 0.95),
			Vector2(0.75, 0.8),
			Vector2(0.76, 0.3),
			Vector2(0.85, 0.02),
			Vector2(1.05, 0.12)
		],
		[]
	],
	"t":
	[
		0.72,
		[
			Vector2(0.0, 0.15),
			Vector2(0.3, 0.75),
			Vector2(0.45, 1.7),
			Vector2(0.38, 0.9),
			Vector2(0.36, 0.2),
			Vector2(0.5, 0.0),
			Vector2(0.72, 0.12)
		],
		[[Vector2(0.12, 1.1), Vector2(0.72, 1.18)]]
	],
	"j":
	[
		0.7,
		[
			Vector2(0.0, 0.15),
			Vector2(0.25, 0.7),
			Vector2(0.32, 1.0),
			Vector2(0.3, 0.2),
			Vector2(0.26, -0.6),
			Vector2(0.12, -1.15),
			Vector2(-0.02, -0.95),
			Vector2(0.15, -0.45),
			Vector2(0.45, -0.05),
			Vector2(0.68, 0.12)
		],
		[[Vector2(0.33, 1.42)]]
	],
	".": [0.35, [], [[Vector2(0.2, 0.06)]]],
	"a":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.45, 0.8),
			Vector2(0.62, 0.95),
			Vector2(0.38, 1.0),
			Vector2(0.12, 0.7),
			Vector2(0.15, 0.2),
			Vector2(0.4, 0.02),
			Vector2(0.6, 0.4),
			Vector2(0.66, 0.95),
			Vector2(0.64, 0.3),
			Vector2(0.75, 0.02),
			Vector2(0.95, 0.12)
		],
		[]
	],
	"d":
	[
		1.0,
		[
			Vector2(0.0, 0.15),
			Vector2(0.45, 0.8),
			Vector2(0.62, 0.95),
			Vector2(0.38, 1.0),
			Vector2(0.12, 0.7),
			Vector2(0.15, 0.2),
			Vector2(0.4, 0.02),
			Vector2(0.6, 0.4),
			Vector2(0.66, 0.95),
			Vector2(0.72, 1.6),
			Vector2(0.75, 2.1),
			Vector2(0.7, 1.3),
			Vector2(0.66, 0.3),
			Vector2(0.78, 0.02),
			Vector2(0.98, 0.12)
		],
		[]
	],
	"r":
	[
		0.8,
		[
			Vector2(0.0, 0.15),
			Vector2(0.2, 0.75),
			Vector2(0.28, 1.12),
			Vector2(0.32, 0.85),
			Vector2(0.48, 0.9),
			Vector2(0.62, 0.95),
			Vector2(0.55, 0.55),
			Vector2(0.52, 0.12),
			Vector2(0.62, 0.0),
			Vector2(0.8, 0.12)
		],
		[]
	],
	"v":
	[
		0.9,
		[
			Vector2(0.0, 0.15),
			Vector2(0.15, 0.8),
			Vector2(0.22, 1.0),
			Vector2(0.3, 0.4),
			Vector2(0.45, 0.0),
			Vector2(0.6, 0.5),
			Vector2(0.7, 1.0),
			Vector2(0.62, 0.9),
			Vector2(0.9, 0.85)
		],
		[]
	],
	"w":
	[
		1.15,
		[
			Vector2(0.0, 0.15),
			Vector2(0.12, 0.8),
			Vector2(0.18, 1.0),
			Vector2(0.25, 0.4),
			Vector2(0.38, 0.0),
			Vector2(0.5, 0.6),
			Vector2(0.56, 0.85),
			Vector2(0.62, 0.3),
			Vector2(0.75, 0.0),
			Vector2(0.88, 0.6),
			Vector2(0.93, 1.0),
			Vector2(0.86, 0.9),
			Vector2(1.15, 0.85)
		],
		[]
	],
	"I":
	[
		0.85,
		[
			Vector2(0.0, 0.15),
			Vector2(0.35, 1.0),
			Vector2(0.6, 2.0),
			Vector2(0.55, 2.25),
			Vector2(0.4, 2.1),
			Vector2(0.38, 1.2),
			Vector2(0.3, 0.2),
			Vector2(0.15, 0.0),
			Vector2(0.05, 0.2),
			Vector2(0.4, 0.3),
			Vector2(0.75, 0.12)
		],
		[]
	],
	"f":
	[
		0.8,
		[
			Vector2(0.0, 0.15),
			Vector2(0.35, 0.9),
			Vector2(0.55, 1.7),
			Vector2(0.5, 2.15),
			Vector2(0.35, 2.1),
			Vector2(0.3, 1.3),
			Vector2(0.28, 0.2),
			Vector2(0.25, -0.7),
			Vector2(0.12, -1.1),
			Vector2(0.05, -0.8),
			Vector2(0.3, -0.2),
			Vector2(0.6, 0.05),
			Vector2(0.78, 0.12)
		],
		[]
	],
	"m":
	[
		1.3,
		[
			Vector2(0.0, 0.15),
			Vector2(0.18, 0.8),
			Vector2(0.22, 1.0),
			Vector2(0.22, 0.0),
			Vector2(0.3, 0.6),
			Vector2(0.45, 0.95),
			Vector2(0.6, 0.75),
			Vector2(0.6, 0.0),
			Vector2(0.68, 0.6),
			Vector2(0.85, 0.95),
			Vector2(1.0, 0.75),
			Vector2(1.0, 0.2),
			Vector2(1.1, 0.0),
			Vector2(1.3, 0.12)
		],
		[]
	],
	"s":
	[
		0.72,
		[
			Vector2(0.0, 0.15),
			Vector2(0.3, 0.7),
			Vector2(0.4, 1.0),
			Vector2(0.48, 0.6),
			Vector2(0.55, 0.25),
			Vector2(0.4, 0.0),
			Vector2(0.2, 0.08),
			Vector2(0.45, 0.05),
			Vector2(0.72, 0.12)
		],
		[]
	],
	"p":
	[
		0.9,
		[
			Vector2(0.0, 0.15),
			Vector2(0.25, 0.8),
			Vector2(0.3, 1.0),
			Vector2(0.28, 0.0),
			Vector2(0.26, -1.15),
			Vector2(0.27, 0.0),
			Vector2(0.35, 0.6),
			Vector2(0.6, 0.95),
			Vector2(0.78, 0.7),
			Vector2(0.65, 0.15),
			Vector2(0.38, 0.1),
			Vector2(0.6, 0.05),
			Vector2(0.85, 0.12)
		],
		[]
	],
	"é":
	[
		0.8,
		[
			Vector2(0.0, 0.15),
			Vector2(0.3, 0.35),
			Vector2(0.6, 0.62),
			Vector2(0.62, 0.88),
			Vector2(0.45, 1.0),
			Vector2(0.22, 0.88),
			Vector2(0.12, 0.5),
			Vector2(0.2, 0.15),
			Vector2(0.45, 0.0),
			Vector2(0.75, 0.12)
		],
		[[Vector2(0.35, 1.25), Vector2(0.6, 1.55)]]
	],
	"c":
	[
		0.75,
		[
			Vector2(0.0, 0.15),
			Vector2(0.4, 0.7),
			Vector2(0.6, 0.9),
			Vector2(0.5, 1.0),
			Vector2(0.25, 0.85),
			Vector2(0.12, 0.45),
			Vector2(0.22, 0.08),
			Vector2(0.45, 0.0),
			Vector2(0.72, 0.12)
		],
		[]
	],
	"g":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.45, 0.8),
			Vector2(0.62, 0.95),
			Vector2(0.38, 1.0),
			Vector2(0.12, 0.7),
			Vector2(0.15, 0.2),
			Vector2(0.4, 0.02),
			Vector2(0.6, 0.4),
			Vector2(0.66, 0.95),
			Vector2(0.64, 0.2),
			Vector2(0.6, -0.6),
			Vector2(0.45, -1.15),
			Vector2(0.2, -1.0),
			Vector2(0.25, -0.5),
			Vector2(0.6, -0.1),
			Vector2(0.95, 0.12)
		],
		[]
	],
	"y":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.18, 0.75),
			Vector2(0.22, 1.0),
			Vector2(0.18, 0.35),
			Vector2(0.3, 0.03),
			Vector2(0.5, 0.1),
			Vector2(0.65, 0.6),
			Vector2(0.72, 1.0),
			Vector2(0.68, 0.3),
			Vector2(0.64, -0.6),
			Vector2(0.48, -1.15),
			Vector2(0.25, -1.0),
			Vector2(0.3, -0.5),
			Vector2(0.65, -0.1),
			Vector2(0.95, 0.12)
		],
		[]
	],
	"k":
	[
		0.9,
		[
			Vector2(0.0, 0.15),
			Vector2(0.35, 0.8),
			Vector2(0.62, 1.55),
			Vector2(0.6, 2.05),
			Vector2(0.4, 2.2),
			Vector2(0.2, 1.95),
			Vector2(0.18, 1.2),
			Vector2(0.2, 0.5),
			Vector2(0.18, 0.0),
			Vector2(0.26, 0.5),
			Vector2(0.5, 0.9),
			Vector2(0.7, 0.8),
			Vector2(0.55, 0.5),
			Vector2(0.3, 0.45),
			Vector2(0.55, 0.35),
			Vector2(0.68, 0.05),
			Vector2(0.9, 0.12)
		],
		[]
	],
	"T":
	[
		0.95,
		[
			Vector2(0.0, 0.15),
			Vector2(0.3, 0.9),
			Vector2(0.5, 2.1),
			Vector2(0.46, 1.0),
			Vector2(0.48, 0.2),
			Vector2(0.62, 0.0),
			Vector2(0.95, 0.12)
		],
		[[Vector2(0.0, 2.0), Vector2(0.35, 2.22), Vector2(0.8, 2.12), Vector2(1.1, 2.3)]]
	],
	"G":
	[
		1.1,
		[
			Vector2(0.0, 0.15),
			Vector2(0.45, 0.9),
			Vector2(0.9, 1.8),
			Vector2(1.05, 2.15),
			Vector2(0.8, 2.3),
			Vector2(0.45, 2.15),
			Vector2(0.15, 1.6),
			Vector2(0.0, 0.9),
			Vector2(0.12, 0.25),
			Vector2(0.4, 0.0),
			Vector2(0.7, 0.15),
			Vector2(0.85, 0.6),
			Vector2(0.88, 1.0),
			Vector2(0.86, 0.2),
			Vector2(0.8, -0.6),
			Vector2(0.62, -1.15),
			Vector2(0.4, -1.0),
			Vector2(0.45, -0.5),
			Vector2(0.8, -0.1),
			Vector2(1.1, 0.12)
		],
		[]
	],
	"M":
	[
		1.45,
		[
			Vector2(0.0, 0.15),
			Vector2(0.12, 1.2),
			Vector2(0.2, 2.0),
			Vector2(0.3, 2.1),
			Vector2(0.36, 1.2),
			Vector2(0.38, 0.0),
			Vector2(0.45, 1.3),
			Vector2(0.62, 2.1),
			Vector2(0.75, 1.9),
			Vector2(0.78, 1.0),
			Vector2(0.78, 0.0),
			Vector2(0.85, 1.0),
			Vector2(1.02, 2.0),
			Vector2(1.15, 1.85),
			Vector2(1.18, 1.0),
			Vector2(1.2, 0.15),
			Vector2(1.28, 0.0),
			Vector2(1.45, 0.12)
		],
		[]
	],
	"'": [0.3, [], [[Vector2(0.18, 2.15), Vector2(0.12, 1.7)]]],
}
