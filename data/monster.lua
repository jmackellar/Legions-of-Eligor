gameMonsters = {

	Fox = {
		name = 'Fox',
		prefix = 'the ',
		char = 'F',
		textColor = {230, 156, 32, 255},
		backColor = {0, 0, 0, 255},
		health = 12,
		armor = 0,
		damage = {dice = 1, sides = 4, bonus = 0},
		ai = 'grunt',
		speed = 150,
		xp = 2,
		},
		
	Firefly = {
		name = 'Firefly',
		prefix = 'the ',
		char = 'f',
		textColor = {255, 255, 87, 255},
		backColor = {0, 0, 0, 255},
		health = 8,
		armor = 0,
		damage = {dice = 1, sides = 3, bonus = 0},
		ranged = {range = 3, dice = 1, sides = 2, bonus = 0,
				  msg = "The Firefly shoots dust at you.  It stings." },
		ai = 'grunt', 
		speed = 100,
		xp = 1,
		},
		
	Spitbug = {
		name = 'Spit Bug',
		prefix = 'the ',
		char = 'b',
		textColor = {0, 255, 0, 255},
		backColor = {0, 0, 0, 255},
		health = 5,
		armor = 0,
		damage = {dice = 1, sides = 2, bonus = 0},
		ranged = {range = 6, dice = 3, sides = 2, bonus = 1,
				  msg = "The Spit Bug spits on you.  It burns!" },
		ai = 'ranged',
		speed = 100,
		xp = 1,
		},
		
	Littlefairy = {
		name = 'Little Fairy',
		prefix = 'the ',
		char = '*',
		textColor = {182, 239, 255, 255},
		backColor = {0, 0, 0, 255},
		health = 7,
		armor = 0,
		damage = {dice = 1, sides = 2, bonus = 1},
		ai = 'scared',
		speed = 100,
		xp = 1,
		},
		
	Fairymystic = {
		name = 'Fairy Mystic',
		prefix = 'the ',
		char = '*',
		textColor = {0, 0, 0, 255},
		backColor = {182, 239, 255, 255},
		health = 15,
		armor = 0,
		damage = {dice = 2, sides = 2, bonus = 1},
		spells = { {name = 'summon', monster = 'Littlefairy', amnt = 3, cooldown = 20},
				   {name = 'addmod', monster = 'Little Fairy', mod = 'ai', val = 1, turns = 5, cooldown = 12},
				  },
		ai = 'scared',
		speed = 100,
		xp = 4,
		},
		
	Gremlinmage = {
		name = 'Gremlin Mage',
		prefix = 'the ',
		char = 'g',
		textColor = {0, 0, 0, 255},
		backColor = {0, 255, 0, 255},
		health = 15,
		armor = 0,
		damage = {dice = 3, sides = 2, bonus = 2},
		spells = { {name = 'mapeffect', shape = 'square', size = 2, target = 'player', cooldown = 7,
					effect = {name = 'Fire', turn = 5, dam = 3, char = '^', 
							  backColor = {255, 0, 0, 255}, textColor = {255, 188, 117},
							  castmsg = "sets the ground on fire.",
							  endmsg = "The fire burns out.",
							  hurtmsg = "The fire burns!",
							  },
					},
					},
		ai = 'scared',
		speed = 100,
		xp = 5,
		},
		
	Lizard = {
		name = 'Lizard',
		prefix = 'the ',
		char = 'l',
		textColor = {222, 210, 158, 255},
		backColor = {0, 0, 0, 255},
		health = 10,
		armor = 0,
		damage = {dice = 2, sides = 2, bonus = 2},
		ai = 'grunt',
		speed = 125,
		xp = 2,
		},
		
	Vulture = {
		name = 'Vulture',
		prefix = 'the ',
		char = 'v',
		textColor = {237, 233, 228, 255},
		backColor = {0, 0, 0, 255},
		health = 12,
		armor = 0,
		damage = {dice = 3, sides = 3, bonus = 0},
		ai = 'scared',
		speed = 50,
		xp = 3,
		},
		
	Skeleton = {
		name = 'Skeleton',
		prefix = 'the ',
		char = 's',
		textColor = {255, 255, 255, 255},
		backColor = {0, 0, 0, 255},
		health = 12, armor = 2,
		damage = {dice = 1, sides = 3, bonus = 0},
		ai = 'grunt',
		speed = 125,
		xp = 3,
		},
		
	Hound = {
		name = 'Hound',
		prefix = 'the ',
		char = 'h',
		textColor = {255, 0, 0, 255},
		backColor = {0, 0, 0, 255},
		health = 15, armor = 2,
		damage = {dice = 3, sides = 3, bonus = 1},
		ai = 'grunt',
		speed = 75,
		xp = 4,
		},
}