gameClasses = { 

	Vagrant = {
		name = 'Vagrant',
		health = 5,
		mana = 1,
		vit = 5,
		ment = 1,
		endur = 4,
		will = 2,
		levelup = {vit = 1, endur = 2, ment = 1, will = 2},
		startingEquipment =	{back = "cape", 
							feet = "sandels",
							weapon = "shortsword",
							},
		startingItems = {'bandage', 'dagger'},
		spells = { {name = 'Roll', direction = true, dist = 5, mana = 5, level = 1, 
					desc = 'Roll forward in target direction.  Increases damage shortly after rolling.', 
					castmsg = 'You roll forward.  You pounce off the ground and raise your weapon.',
					scaling = {endur = 0.50, will = 0.1},
					},
					{name = 'Spin Slice', direction = false, dist = 1, mana = 10, level = 1,
					desc = 'Swing your weapon in a circle around yourself hitting adjacent enemies.',
					castmsg = 'You spin around swinging in a circle.',
					},
					{name = 'Shoutout', dist = 5, armor = -6, mana = 6, level = 5, turns = 15,
					desc = 'Let out a commanding shout that reduces armor of nearby enemies.',
					castmsg = 'You let out a commanding shout.',
					scaling = {endur = 0.15},
					},
					},
		},
		
}