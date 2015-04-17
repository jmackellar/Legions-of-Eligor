gameItems = {

	----------------------------------------------
	------------------------------------
	------ Weapons 
	----------------------------------------------
	------------------------------------
	------

	dagger = {
		name = 'dagger',
		prefix = 'the ',
		singular = 'a ',
		type = 'weapon',
		slot = 'weapon',
		sort = 'weapons',
		damage = {dice = 1, sides = 4, bonus = 2},
		throwdam = {10, 12},
		throwmsg = 'Your dagger flies in.  It screams!',
		throwbreakchance = 15,
		char = '/',
		backColor = {0, 0, 0, 255},
		textColor = {220, 220, 220, 255},
		},
	
	shortsword = {
		name = 'shortsword',
		prefix = 'the ',
		singular = 'a ',
		type = 'weapon',
		slot = 'weapon',
		sort = 'weapons',
		damage = {dice = 2, sides = 3, bonus = 2},
		char = '/',
		backColor = {0, 0, 0, 255},
		textColor = {190, 190, 190, 255},
		},
		
	shockblade = {
		name = 'shortsword',
		idname = 'Shockblade',
		prefix = 'the ',
		singular = 'a ',
		type = 'weapon',
		slot = 'weapon',
		sort = 'weapons',
		damage = {dice = 6, sides = 2, bonus = 1},
		char = '/',
		backColor = {0, 0, 0, 255},
		textColor = {130, 130, 255, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Armor (Body)
	----------------------------------------------
	------------------------------------
	------
		
	tunic = {
		name = 'tunic',
		prefix = 'the ',
		singular = 'a ',
		sort = 'armor',
		type = 'armor',
		slot = 'body',
		armor = 2,
		char = '[',
		backColor = {0, 0, 0, 255},
		textColor = {0, 255, 0, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Armor (Back)
	----------------------------------------------
	------------------------------------
	------
	
	cape = {
		name = 'cape',
		prefix = 'the ',
		singular = 'a ',
		sort = 'armor',
		type = 'armor',
		slot = 'back',
		armor = 1,
		char = '}',
		backColor = {0, 0, 0, 255},
		textColor = {255, 152, 97, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Armor (Legs)
	----------------------------------------------
	------------------------------------
	------
		
	clothpants = {
		name = 'clothpants',
		prefix = 'the ',
		singular = 'a pair of ',
		sort = 'armor',
		type = 'armor',
		slot = 'legs',
		armor = 1,
		char = '{',
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 255, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Armor (Feet)
	----------------------------------------------
	------------------------------------
	
	sandels = {
		name = 'sandels',
		prefix = 'the ',
		singular = 'a pair of ',
		sort = 'armor',
		type = 'armor',
		slot = 'feet',
		armor = 1,
		char = '_',
		backColor = {0, 0, 0, 255},
		textColor = {255, 152, 97, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Armor (Hands)
	----------------------------------------------
	------------------------------------
	
	leathergloves = {
		name = 'leather gloves',
		prefix = 'the ',
		singular = 'a pair of ',
		sort = 'armor',
		type = 'armor',
		slot = 'hands',
		armor = 1,
		char = '}',
		backColor = {0, 0, 0, 255},
		textColor = {152, 255, 97},
		},
		
	----------------------------------------------
	------------------------------------
	------ Potions
	----------------------------------------------
	------------------------------------
	
	potionhealing = {
		name = 'corked potion',
		idname = 'potion of healing',
		prefix = 'the ',
		singular = 'a ',
		sort = 'potions',
		type = 'healplayer',
		useonce = true,
		health = {12, 14},
		msg = 'You drink the viscous potion.  You feel better.',
		char = '!',
		breakonthrow = true,
		backColor = {0, 0, 0, 255},
		textColor = {255, 240, 185, 255},
		},
		
	potionmanagain = {
		name = 'corked potion',
		idname = 'potion of gain mana',
		prefix = 'the ',
		singular = 'a ',
		sort = 'potions',
		type = 'managainplayer',
		useonce = true,
		mana = {14, 16},
		msg = 'You drink the bitter potion.  You feel recharged.',
		char = '!',
		breakonthrow = true,
		backColor = {0, 0, 0, 255},
		textColor = {255, 240, 185, 255},
		},
		
	potionpoison = {
		name = 'corked potion',
		idname = 'potion of poison',
		prefix = 'the ',
		singular = 'a ',
		sort = 'potions',
		type = 'healplayer',
		useonce = true,
		health = {-20, -14},
		throwdam = {14, 20},
		throwmsg = 'The potion shatters.  It shrieks!',
		breakonthrow = true,
		msg = 'You drink the acidic potion.  Your throat burns and your stomach throbs.',
		char = '!',
		backColor = {0, 0, 0, 255},
		textColor = {255, 240, 185, 255},
		},
		
	potionspeed = {
		name = 'corked potion',
		idname = 'potion of speed',
		prefix = 'the ',
		singular = 'a ',
		sort = 'potions',
		type = 'speed',
		useonce = true,
		speed = -50,
		turns = 150,
		msgend = 'You feel yourself slow down.',
		breakonthrow = true,
		msg = 'You drink the watery potion.  You feel yourself speed up.',
		char = '!',
		backColor = {0, 0, 0, 255},
		textColor = {255, 240, 185, 255},
		},
		
	potionslow = {
		name = 'corked potion',
		idname = 'potion of slow',
		prefix = 'the ',
		singular = 'a ',
		sort = 'potions',
		type = 'speed',
		useonce = true,
		speed = 50,
		turns = 100,
		msgend = 'You feel yourself speed back up.',
		breakonthrow = true,
		msg = 'You drink the watery potion.  You feel yourself slow down.',
		char = '!',
		backColor = {0, 0, 0, 255},
		textColor = {255, 240, 185, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Keys/Progress items
	----------------------------------------------
	------------------------------------
	------
	
	rustedkey = {
		name = 'Rusted Key',
		prefix = 'the ',
		singular = 'a ',
		sort = 'useables',
		char = '$',
		backColor = {0, 0, 0, 255},
		textColor = {196, 164, 112, 255},
		},
		
	----------------------------------------------
	------------------------------------
	------ Misc. Usable Items
	----------------------------------------------
	------------------------------------
	------
	
	bandage = {
		name = 'bandage',
		prefix = 'the ',
		singular = 'a ',
		sort = 'useables',
		type = 'healplayer',
		useonce = true,
		health = {7, 8},
		msg = 'You wrap the bandage around yourself.  You feel better',
		char = '\\',
		backColor = {0, 0, 0, 255},
		textColor = {255, 0, 0, 255},
		},
		
	stone = {
		name = 'stone',
		prefix = 'the ',
		singular = 'a round ',
		sort = 'ammo',
		char = '*',
		throwdam = {5, 8},
		throwmsg = 'The rock crashes.  It cries!',
		throwbreakchance = 20,
		backColor = {0, 0, 0, 255},
		textColor = {150, 150, 150, 255},
		},
		
	dart = {
		name = 'dart',
		prefix = 'the ',
		singular = 'a ',
		sort = 'ammo',
		char = '-',
		throwdam = {9, 11},
		throwmsg = 'The dart flies straight.  It cries!',
		throwbreakchance = 5,
		backColor = {0, 0, 0, 255},
		textColor = {255, 255, 0, 255},
		},
}