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
		Stats = {
			MoveSpeed = 8,
		},
	},
}

return ItemData