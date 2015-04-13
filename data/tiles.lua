mapTiles = {

	blank = {
		char = ' ',
		name = 'blank',
		walkThru = false,
		seeThru = false,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		},

	floor = {
		char = '.',
		name = 'floor',
		walkThru = true,
		seeThru = true,
		backColor = {10, 10, 10, 255},
		textColor = {255, 255, 255, 255},
		},
		
	cooridorfloor = {
		char = '╫',
		name = 'floor',
		walkThru = true,
		seeThru = false,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		},
		
	wall = {
		char = '#',
		name = 'wall',
		walkThru = false,
		seeThru = false,
		backColor = {219, 199, 130, 255},
		textColor = {74, 67, 34, 255},
		},
		
	smoothwall = {
		char = '#',
		name = 'smoothwall',
		walkThru = false,
		seeThru = false,
		backColor = {175, 175, 175, 255},
		textColor = {255, 255, 255, 255},
		},
		
	closeddoor = {
		char = '+',
		name = 'closeddoor',
		walkThru = false,
		seeThru = false,
		backColor = {102, 70, 0, 255},
		textColor = {204, 152, 41, 255},
		},
		
	opendoor = {
		char = '/',
		name = 'opendoor',
		walkThru = true,
		seeThru = true,
		backColor = {61, 34, 7, 255},
		textColor = {204, 152, 41, 255},
		},
		
	upstairs = {
		char = '<',
		name = 'upstairs',
		walkThru = true,
		seeThru = true,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		},
		
	downstairs = {
		char = '>',
		name = 'downstairs',
		walkThru = true,
		seeThru = true,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		},
		
	connection = {
		char = '>',
		name = 'connection',
		walkThru = true,
		seeThru = true,
		backColor = {0, 0, 0, 255},
		textColor = {120, 255, 255, 255},
		},
		
	fence = {
		char = '#',
		name = 'fence',
		walkThru = false,
		seeThru = true,
		backColor = {0, 0, 0, 255},
		textColor = {150, 150, 150, 255},
		},
		
	grass = {
		char = '.',
		name = 'floor',
		walkThru = true,
		seeThru = true,
		backColor = {0, 25, 0, 255},
		textColor = {0, 255, 0, 255},
		},
		
	tombstone = {
		char = '+',
		name = 'tombstone',
		walkThru = false,
		seeThru = true,
		backColor = {55, 55, 55, 255},
		textColor = {185, 185, 185, 255},
		},
		
	deadtree = {
		char = 'T',
		name = 'deadtree',
		walkThru = false,
		seeThru = true,
		backColor = {74, 62, 53, 255},
		textColor = {171, 133, 84, 255},
		},
		
	identify = {
		char = '÷',
		name = 'identify',
		walkThru = true,
		seeThru = true,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		interaction = 'identify',
		charge = 3,
		},
		
}