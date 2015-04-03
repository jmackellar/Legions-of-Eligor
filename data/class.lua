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
					desc = 'Roll forward in target direction.', 
					castmsg = 'You roll forward.',
					},
					{name = 'Shoutout', dist = 5, armor = -6, mana = 10, level = 3, turns = 15,
					desc = 'Let out a commanding shout that reduces armor of nearby enemies.',
					castmsg = 'You let out a commanding shout.',
					},
					},
		},
		
}