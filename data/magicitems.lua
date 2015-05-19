magicItems = {

	keyToString = {damagebonus = {key = 'Damage Bonus', color = {234, 255, 0, 255}},
				   vit = {key = 'Vitality', color = {224, 119, 119, 255}},
				   ment = {key = 'Mentality', color = {119, 224, 119, 255}},
				   endur = {key = 'Endurance', color = {119, 224, 119, 255}},
				   will = {key = 'Willpower', color = {119, 119, 224, 255}},
				   speed = {key = 'Speed', color = {234, 255, 0, 255}},
				   armor = {key = 'Armor', color = {234, 255, 0, 255}},
				   },

	mColors = {backColor = {92, 140, 145}, textColor = {255, 255, 255, 255}, invColor = {59, 252, 255, 255} },
	qColors = {backCOlor = {233, 110, 255}, textColor = {255, 255, 255, 255}, invColor = {233, 110, 255}, },

	mItems = {
		{name = 'shortsword', type = 'sword'},
		{name = 'dagger', type = 'dagger'},
		{name = 'tunic', type = 'body'},
		},		
	mPrefix = {
		sword = {
			{name = 'valient', val = {damagebonus = 5, vit = 1}},
			{name = 'sharp', val = {damagebonus = 7}},
			{name = 'lean', val = {damagebonus = 4, endur = 1, will = 1}},
			},
		dagger = {
			{name = 'swift', val = {damagebonus = 3, speed = -15}},
			{name = 'homing', val = {damagebonus = 1, endur = 2}},
			},
		body = {
			{name = 'stout', val = {endur = 2, vit = 2}},
			{name = 'hard', val = {armor = 4}},
			{name = 'clear', val = {armor = 1, ment = 2}},
			{name = 'towering', val = {speed = 25, vit = 3, armor = 6}},
			},
		},
		
}