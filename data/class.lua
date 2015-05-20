gameClasses = { 

	Vagrant = {
		name = 'Vagrant',
		pername = 'Keir Ostrason',
		health = 5,
		mana = 1,
		vit = 5,
		ment = 1,
		endur = 4,
		will = 2,
		levelup = {vit = 1, endur = 2, ment = 1, will = 1},
		startingEquipment =	{back = "cape", 
							feet = "sandels",
							weapon = "shortsword",
							},
		startingItems = {'bandage', 'dagger'},
		spells = { 	{name = 'Temporal Backstab', direction = false, dist = 12, mana = 5, level = 1, req = false, y = 1, damagescale = 2,
					desc = {
						'Blink behind the nearest enemy and',
						'stab them in the back for massive',
						'damage.',
					},
					castmsg = 'You blink forward and strike it in the back.',
					scaling  = {endur = 0.50},
					scaledesc = 'Increases backstab damage.',
					},

					{name = 'Double Strike', direction = true, mana = 3, level = 1, req = false, y = 3,
					desc = {
						'Strike the targeted tile twice in',
						'one turn with your weapon.  All hit',
						'modifiers affect your strikes like',
						'normal melee attacks.',
					},
					castmsg = 'You swing twice.',
					},

					{name = 'Spell Sword', passive = true, level = 2, req = 'Temporal Backstab', y = 1, damage = 5,
					desc = {
						'Casting spells temporarily increases',
						'your attack damage by 5 for 3 turns.',
					},
					scaling = {endur = 0.15, will = 0.15},
					scaledesc = 'Increases bonus damage.',
					},

					{name = 'Roll', direction = true, dist = 5, mana = 5, level = 2, req = false, y = 2,
					desc = {
						'Roll forward 5 spaces in the target',
						'direction.  After rolling forward,',
						'you ready your weapon and do extra',
						'damage for the next 2 turns.',
					},
					castmsg = 'You roll forward.  You pounce off the ground and raise your weapon.',
					scaling = {endur = 0.50, will = 0.1},
					scaledesc = 'Increases extra damage after rolling.',
					},

					{name = 'Spell Charge', passive = true, level = 3, req = 'Spell Sword', y = 1, managain = 1,
					desc = {
						'Melee attacks recharge your mana.',
					},
					scaling = {will = 0.20},
					scaledesc = 'Increases mana gain.',
					},

					{name = 'Shredder', passive = true, level = 3, y = 3, req = 'Double Strike', armor = 1,
					desc = {
						'Your melee attacks shred through',
						'your enemies armor.',
					},
					scaling = {endur = 0.15},
					scaledesc = 'Increases armor shred.',
					},

					{name = 'Spin Slice', direction = false, dist = 1, mana = 5, level = 3, req = 'Roll', y = 2,
					desc = {
						'Spin in a circle while holding your',
						'weapon out.  Your weapon will strike',
						'all adjacent enemies for melee',
						'damage.',
					},
					castmsg = 'You spin around swinging in a circle.',
					},

					{name = 'Dragon\'s Flame', direction = false, dist = 6, mana = 10, level = 4, req = false, y = 1,
					desc = {
						'Surrounds yourself with the flames',
						'of dragons, which burn nearby enemies',
						'every turn.',
					},
					castmsg = 'Your surround yourself in the Dragon\'s Flame.',
					scaling = {endur = 0.10, will = 0.10},
					scaledesc = 'Increaes flame damage.',
					},

					{name = 'Ostrason Heritage', dist = 5, armor = -6, mana = 1, level = 4, turns = 15, req = 'Shredder', y = 2,
					desc = {
						'Let out a commanding shout which',
						'lowers the armor of nearby enemies',
						'by 6 points for 15 turns.',
					},
					castmsg = 'You let out a commanding shout.',
					scaling = {endur = 0.15},
					scaledesc = 'Increases armor loss.'
					},

					{name = 'Great Strike', passive = true, stun = 25, level = 4, y = 3, req = 'Shredder',
					desc = {
						'Gives your melee attacks a chance',
						'to stun enemies on hit.',
					},
					},

					},
		},
		
	Arcanist = {
		name = 'Arcanist',
		pername = 'Uisdean Bluespell',
		health = 3,
		mana = 6,
		vit = 3,
		ment = 3,
		endur = 2,
		will = 4,
		levelup = {vit = 1, endur = 0, ment = 2, will = 2},
		startingEquipment = {weapon = "dagger",
							 back = "cape",
							 },
		startingItems = {'dart', 'dart', 'dart'},
		spells = {	{name = 'Arcane Dart', direction = true, dist = 7, mana = 5, level = 1, damage = 4, y = 2,
					chaintime = 5,
					desc = {
						'Fires a single bolt of energy which',
						'damages the first enemy it comes in',
						'contact with.  Firing multiple shots',
						'in a row after each other reduces',
						'the mana cost.',
					},
					castmsg = 'You fire an arcane dart.',
					scaling = {ment = 0.40, will = 0.40},
					scaledesc = 'Increases spell damage.'
					},

					{name = 'Unstable Concoction', direction = true, dist = 6, mana = 12, level = 2, damage = 6, y = 1, req = 'Arcane Dart',
					desc = {
						'Throws a ball of energy which',
						'explodes on contact dealing',
						'damage in an area around itself.',
					},
					castmsg = 'You throw a ball of magical energy.  It explodes!',
					scaling = {ment = 0.25, will = 0.25},
					scaledesc = 'Increases spell damage.'
					},

					{name = 'Mystic Wind', direction = true, dist = 6, mana = 4, level = 3, damage = 2, y = 3, req = 'Arcane Dart',
					desc = {
						'Creates a gust of wind in the',
						'target direction which blows back',
						'and deals minor damage to the',
						'first enemy it hits.',
					},
					castmsg = 'A strong wind roars by you.',
					scaling = {will = 0.10},
					scaledesc = 'Increases spell damage.',
					},

					{name = 'Cyclone', range = 6, mana = 8, level = 4, damage = 3, turn = 8, y = 3, req = 'Mystic Wind',
					desc = {
						'Conjure a powerful cyclone that',
						'surrounds you for 8 turns and',
						'damages any enemy that comes near',
						'you.',
					},
					castmsg = 'You whip up a powerful cyclone around youself.',
					msgend = 'Your cyclone dies down.',
					scaling = {ment = 0.15},
					scaledesc = 'Increases spell damage.'
					},
					},
		},
		
}