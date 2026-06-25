--!strict

local AbilityData = {}

export type AbilityDefinition = {
	Id: string,
	DisplayName: string,
	Slot: number,
	Type: string,
	Range: number?,
	Damage: number?,
	Heal: number?,
	Cooldown: number,
	Radius: number?,
	Duration: number?,
	DashDistance: number?,
	MaxHealthBonus: number?,
	ExecuteBonusDamage: number?,
	ExecuteThreshold: number?,
	DashOffset: number?,
}

local spells: { [string]: { [number]: AbilityDefinition } } = {
	Tank = {
		[1] = {
			Id = "Tank_ShieldBash",
			DisplayName = "Shield Bash",
			Slot = 1,
			Type = "MeleeDamage",
			Range = 18,
			Damage = 60,
			Cooldown = 5,
		},
		[2] = {
			Id = "Tank_Guard",
			DisplayName = "Guard",
			Slot = 2,
			Type = "SelfHeal",
			Heal = 160,
			Cooldown = 10,
		},
		[3] = {
			Id = "Tank_GroundSlam",
			DisplayName = "Ground Slam",
			Slot = 3,
			Type = "AoEDamage",
			Radius = 22,
			Damage = 70,
			Cooldown = 8,
		},
		[4] = {
			Id = "Tank_Unbreakable",
			DisplayName = "Unbreakable",
			Slot = 4,
			Type = "TemporaryMaxHealth",
			MaxHealthBonus = 350,
			Duration = 8,
			Cooldown = 35,
		},
	},

	Assassin = {
		[1] = {
			Id = "Assassin_DashStrike",
			DisplayName = "Dash Strike",
			Slot = 1,
			Type = "DashDamage",
			Range = 30,
			Damage = 90,
			Cooldown = 6,
			DashOffset = 4,
		},
		[2] = {
			Id = "Assassin_SmokeStep",
			DisplayName = "Smoke Step",
			Slot = 2,
			Type = "DashForward",
			DashDistance = 28,
			Cooldown = 8,
		},
		[3] = {
			Id = "Assassin_Backstab",
			DisplayName = "Backstab",
			Slot = 3,
			Type = "MeleeDamage",
			Range = 16,
			Damage = 130,
			Cooldown = 9,
		},
		[4] = {
			Id = "Assassin_Execute",
			DisplayName = "Execute",
			Slot = 4,
			Type = "ExecuteDamage",
			Range = 24,
			Damage = 140,
			ExecuteBonusDamage = 160,
			ExecuteThreshold = 0.35,
			Cooldown = 35,
		},
	},

	Mage = {
		[1] = {
			Id = "Mage_Fireball",
			DisplayName = "Fireball",
			Slot = 1,
			Type = "RangedDamage",
			Range = 60,
			Damage = 85,
			Cooldown = 4,
		},
		[2] = {
			Id = "Mage_FrostNova",
			DisplayName = "Frost Nova",
			Slot = 2,
			Type = "AoEDamage",
			Radius = 24,
			Damage = 55,
			Cooldown = 7,
		},
		[3] = {
			Id = "Mage_ArcaneBurst",
			DisplayName = "Arcane Burst",
			Slot = 3,
			Type = "RangedDamage",
			Range = 65,
			Damage = 130,
			Cooldown = 9,
		},
		[4] = {
			Id = "Mage_Meteor",
			DisplayName = "Meteor",
			Slot = 4,
			Type = "AoEDamageAtTarget",
			Range = 75,
			Radius = 28,
			Damage = 220,
			Cooldown = 40,
		},
	},

	Marksman = {
		[1] = {
			Id = "Marksman_PowerShot",
			DisplayName = "Power Shot",
			Slot = 1,
			Type = "RangedDamage",
			Range = 70,
			Damage = 75,
			Cooldown = 5,
		},
		[2] = {
			Id = "Marksman_Roll",
			DisplayName = "Roll",
			Slot = 2,
			Type = "DashForward",
			DashDistance = 22,
			Cooldown = 10,
		},
		[3] = {
			Id = "Marksman_PiercingShot",
			DisplayName = "Piercing Shot",
			Slot = 3,
			Type = "RangedDamage",
			Range = 80,
			Damage = 120,
			Cooldown = 8,
		},
		[4] = {
			Id = "Marksman_BulletStorm",
			DisplayName = "Bullet Storm",
			Slot = 4,
			Type = "AoEDamage",
			Radius = 34,
			Damage = 170,
			Cooldown = 38,
		},
	},

	Support = {
		[1] = {
			Id = "Support_Heal",
			DisplayName = "Heal",
			Slot = 1,
			Type = "SelfHeal",
			Heal = 100,
			Cooldown = 7,
		},
		[2] = {
			Id = "Support_GreaterHeal",
			DisplayName = "Greater Heal",
			Slot = 2,
			Type = "AllyOrSelfHeal",
			Range = 40,
			Heal = 160,
			Cooldown = 9,
		},
		[3] = {
			Id = "Support_HolyPulse",
			DisplayName = "Holy Pulse",
			Slot = 3,
			Type = "AoEDamage",
			Radius = 24,
			Damage = 60,
			Cooldown = 8,
		},
		[4] = {
			Id = "Support_Sanctuary",
			DisplayName = "Sanctuary",
			Slot = 4,
			Type = "TeamHeal",
			Radius = 36,
			Heal = 240,
			Cooldown = 40,
		},
	},
}

AbilityData.Spells = spells

function AbilityData.getSpell(championId: string, slot: number): AbilityDefinition?
	local championSpells = spells[championId]
	if not championSpells then
		return nil
	end

	return championSpells[slot]
end

return AbilityData
