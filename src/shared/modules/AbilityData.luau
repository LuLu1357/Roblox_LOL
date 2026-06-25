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
