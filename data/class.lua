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

					{name = 'Spell Sword', passive = true, level = 2, req = 'Temporal Backstab', y = 1, damage = 8, turn = 4,
					desc = {
						'Casting a spell calls upon your',
						'wandering heritage, causing your',
						'attack damage to be increases for 4',
						'turns.',
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
						'A hidden sword technique passed down',
						'through the Ostrason lineage causes',
						'your melee attacks to recharge your',
						'mana by 1 point per attack.',
					},
					scaling = {will = 0.20},
					scaledesc = 'Increases mana gain.',
					},

					{name = 'Shredder', passive = true, level = 3, y = 3, req = 'Double Strike', armor = 1, turn = 10,
					desc = {
						'A sharp blade not only cuts through',
						'demon flesh, but also clothing and',
						'armor.  Your melee attacks reduce the',
						'enemy\'s armor by 1 point.',
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
					turn = 10, damage = 3, range = 3,
					desc = {
						'Surrounds yourself with the flames',
						'of dragons, which burn nearby enemies',
						'every turn.',
					},
					castmsg = 'Your surround yourself in the Dragon\'s Flame.',
					msgend = 'The flames of the dragons dies out.',
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
						'A sharp swing to the head has the',
						'potential of disorienting the target.',
						'Your melee attacks have a 25% chance',
						'to stun the target for 2 turns.',					
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
		spells = {	{name = 'Mystic Wind', direction = true, dist = 6, mana = 4, level = 1, damage = 2, y = 1, req = false,
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

					{name = 'Arcane Dart', direction = true, dist = 7, mana = 5, level = 1, damage = 4, y = 3,
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

					{name = 'Depleted Batteries', passive = true, level = 2, y = 1, req = 'Mystic Wind', damage = 0.10,
					desc = {
						'An Arcanist reserves the ability to',
						'channel his lack of magical into his',
						'swordplay.  You gain attack damage',
						'for missing mana.',
					},
					scaling = {endur = 0.05},
					scaledesc = 'Increases attack damage.',
					},

					{name = 'Unstable Energy', turn = 10, mana = 8, level = 2, damage = 6, y = 2, req = 'Arcane Dart',
					desc = {
						'Modifies your Arcane Darts to explode',
						'on contact with enemies, damaging',
						'everything within the area.',
					},
					castmsg = 'You modify your Arcane Darts to explode on contact.',
					msgend = 'Your Arcane Darts revert back to being normal.',
					scaling = {ment = 0.25, will = 0.25},
					scaledesc = 'Increases spell damage.'
					},

					{name = 'Anti-Personal Dart', mana = 8, turn= 10, level = 2, y = 3, req = 'Arcane Dart',
					desc = {
						'Modifies your Arcane Darts to pierce',
						'through enemies, damaging everything',
						'in a line.',
					},
					castmsg = 'You modify your Arcane Darts to pierce enemies.',
					msgend = 'Your Arcane Darts revert back to being normal.',
					},

					{name = 'Cyclone', range = 6, mana = 8, level = 3, damage = 3, turn = 8, y = 1, req = 'Depleted Batteries',
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

					{name = 'Arcane Freeze', passive = true, level = 3, y = 2, req = 'Unstable Energy',
					desc = {
						'The Arcane Arts where originally',
						'derived from the Frost Arts.  You',
						'can use this link to add a chilling',
						'touch to your Arcane Darts, causing',
						'them to slow enemies on hit.',					},
					},

					{name = 'Arcane Study', passive = true, level = 4, y = 1, req = false,
					desc = {
						'Through rigorous studies, the Arcanist',
						'learns his art.  With further studying',
						'the Arcanist can fine tune his spells',
						'for further destruction.  Your spells',
						'all scale by 10% more.'
					},
					},

					{name = 'Arcane Shield', passive = true, level = 4, y = 2, req = false,
					desc = {
						'An Arcanist can manifest his mental',
						'energy as a physical shield to protect',
						'himself.  35% of all damage is',
						'absorbed by your mana, and the rest',
						'damages your health like normal.',
					},
					},

					{name = 'Arcane Flak', mana = 8, level = 4, y = 3, turn = 10, req = 'Anti-Personal Dart',
					desc = {
						'Some jobs call for a heavy tool, or',
						'in some cases, call for a heavy',
						'weapon.  Your Arcane Darts harden',
						'and gain the ability to stun enemies',
						'on hit.',
					},
					castmsg = 'You modify your Arcane Darts to stun enemies.',
					msgend = 'Your Arcane Darts revert back to being normal.',
					},

					},
		},
		
}