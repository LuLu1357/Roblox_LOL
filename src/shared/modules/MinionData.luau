--!strict

local MinionData = {}

MinionData.Types = {
	Melee = {
		MaxHealth = 450,
		AttackDamage = 18,
		AttackRange = 7,
		AttackCooldown = 1.2,
		MoveSpeed = 12,
		GoldReward = 21,
		XPReward = 35,
		Scale = 3.8,
	},
	Ranged = {
		MaxHealth = 300,
		AttackDamage = 14,
		AttackRange = 28,
		AttackCooldown = 1.4,
		MoveSpeed = 11,
		GoldReward = 14,
		XPReward = 25,
		Scale = 3.3,
	},
	Siege = {
		MaxHealth = 900,
		AttackDamage = 45,
		AttackRange = 36,
		AttackCooldown = 2,
		MoveSpeed = 9,
		GoldReward = 60,
		XPReward = 90,
		Scale = 5.2,
	},
}

MinionData.Wave = {
	MeleeCount = 3,
	RangedCount = 3,
	SiegeEveryNWaves = 3,
}

return MinionData
