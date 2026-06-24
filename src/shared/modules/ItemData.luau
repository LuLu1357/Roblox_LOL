--!strict

local ItemData = {}

ItemData.Items = {
	LongSword = {
		Id = "LongSword",
		DisplayName = "Long Sword",
		Cost = 350,
		Stats = {
			AttackDamage = 10,
		},
	},

	RubyCrystal = {
		Id = "RubyCrystal",
		DisplayName = "Ruby Crystal",
		Cost = 400,
		Stats = {
			MaxHealth = 150,
		},
	},

	Boots = {
		Id = "Boots",
		DisplayName = "Boots",
		Cost = 300,
		Unique = true,
		UniqueGroup = "Boots",
		Stats = {
			MoveSpeed = 8,
		},
	},

	BFSword = {
		Id = "BFSword",
		DisplayName = "B.F. Sword",
		Cost = 1300,
		Stats = {
			AttackDamage = 30,
		},
		Recipe = {
			Components = { "LongSword", "LongSword" },
			CombineCost = 300,
		},
	},

	GiantBelt = {
		Id = "GiantBelt",
		DisplayName = "Giant Belt",
		Cost = 1100,
		Stats = {
			MaxHealth = 400,
		},
		Recipe = {
			Components = { "RubyCrystal", "RubyCrystal" },
			CombineCost = 300,
		},
	},

	SwiftBoots = {
		Id = "SwiftBoots",
		DisplayName = "Swift Boots",
		Cost = 900,
		Unique = true,
		UniqueGroup = "Boots",
		Stats = {
			MoveSpeed = 18,
		},
		Recipe = {
			Components = { "Boots" },
			CombineCost = 500,
		},
	},
}

return ItemData
