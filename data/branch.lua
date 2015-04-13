mapBranch = {

	Dungeon = {
		gen = 'mapGenDungeon',
		intro = 'Dungeon',
		floors = 7,
		minCreatures = 10,
		maxCreatures = 13,
		creatures = { {name = 'Fox', perc = 20}, 
					  {name = 'Firefly', perc = 35}, 
					  {name = 'Spitbug', perc = 15}, 
					  {name = 'Littlefairy', perc = 40},
					  },
		rareCreatures = { {name = 'Fairymystic', min = 1, max = 2},
							},
		minItems = 1,
		maxItems = 2,
		maxExtraItems = 9,
		extraItemsChance = 100,
		items = { {name = 'stone', perc = 55}, {name = 'dart', perc = 25}, {name = 'bandage', perc = 20} },
		extraItems = { 'tunic', 'clothpants', 'sandels', 'shortsword', 'potionhealing', 'potionmanagain', 'potionpoison', 
						'dagger', 'bandage', 'stone', 'dart', 'potionspeed', 'potionslow', },
		connections = { {branch = 'Caves', floor = 4, drop = 1}, {branch = 'Storehouse', floor = 7, drop = 1}, },
		tiles = { {name = 'identify', floor = 6, x = 'random', y = 'random'}, 
					 },
		},
		
	Storehouse = {
		gen = 'mapGenBSP',
		intro = 'Storehouse',
		floors = 6,
		minCreatures = 12,
		maxCreatures = 15,
		extraItemsChance = 65,
		maxExtraItems = 3,
		creatures = { {name = 'Fox', perc = 100}, },
		minItems = 1,
		maxItems = 3,
		items = { {name = 'stone', perc = 100}, },
		extraItems = { 'stone', },
		connections = { {branch = 'Dungeon', floor = 1, drop = 7}, },
		tiles = { },
		},

	Caves = {
		gen = 'mapGenCave',
		intro = 'Caves',
		floors = 4,
		minCreatures = 14, 
		maxCreatures = 16,
		maxExtraItems = 2,
		extraItemsChance = 65,
		magicItemsTier = 1,
		magicChance = 35,
		maxMagicItems = 2,
		creatures = { {name = 'Lizard', perc = 60}, {name = 'Vulture', perc = 25}, {name = 'Spitbug', perc = 15}, },
		rareCreatures = { {name = 'Fairymystic', min = 2, max = 3},
						  {name = 'Gremlinmage', min = 2, max = 3},
							},
		minItems = 1,
		maxItems = 3,
		items = { {name = 'stone', perc = 55}, {name = 'dart', perc = 25}, {name = 'bandage', perc = 20} },
		extraItems = { 'tunic', 'clothpants', 'sandels', 'shortsword', 'potionhealing', 'potionmanagain', 'potionpoison', 
						'dagger', 'bandage', 'stone', 'dart', 'potionspeed', 'potionslow', },
		connections = { {branch = 'Dungeon', floor = 1, drop = 4},
						{branch = 'Graves', floor = 4, drop = 1}, 
						},
		},
		
	Graves = {
		gen = 'mapGenGrave',
		intro = 'Graves',
		floors = 1,
		minCreatures = 19,
		maxCreatures = 21,
		maxExtraItems = 4,
		extraItemsChance = 95,
		magicItemsTier = 1,
		magicChance = 55,
		maxMagicItems = 2,
		creatures = { {name = 'Vulture', perc = 10}, {name = 'Spitbug', perc = 15},
					  {name = 'Skeleton', perc = 30}, {name = 'Fairy', perc = 20},
					  {name = 'Lizard', perc = 10}, {name = 'Fox', perc = 15},
						},
		rareCreatures = { {name = 'Aashecht', min = 1, max = 1},
						  {name = 'Fairymystic', min = 3, max = 3},
						  {name = 'Gremlinmage', min = 3, max = 3},
							},
		minItems = 1,
		maxItems = 3,
		items = { {name = 'stone', perc = 55}, {name = 'dart', perc = 25}, {name = 'bandage', perc = 20} },
		extraItems = { 'tunic', 'clothpants', 'sandels', 'shortsword', 'potionhealing', 'potionmanagain', 'potionpoison', 
						'dagger', 'bandage', 'stone', 'dart', 'potionspeed', 'potionslow', },
		connections = { {branch = 'Caves', floor = 1, drop = 4} },
		},
		
}