--!strict

local JungleData = {}

JungleData.Camps = {
	SmallWolf = {
		MaxHealth = 700,
		AttackDamage = 18,
		AttackRange = 8,
		AttackCooldown = 1.5,
		GoldReward = 45,
		XPReward = 80,
		RespawnTime = 65,
		Scale = 5,
	},
	BigGolem = {
		MaxHealth = 1800,
		AttackDamage = 35,
		AttackRange = 9,
		AttackCooldown = 1.7,
		GoldReward = 110,
		XPReward = 180,
		RespawnTime = 120,
		Scale = 8,
	},
	DragonPrototype = {
		MaxHealth = 5000,
		AttackDamage = 80,
		AttackRange = 14,
		AttackCooldown = 2,
		GoldReward = 250,
		XPReward = 450,
		RespawnTime = 300,
		GlobalReward = true,
		Scale = 13,
	},
}

return JungleData
