--!strict

local ChampionData = {}
local DEFAULT_CHAMPION_ID = "Tank"

export type ChampionDefinition = {
	Id: string,
	DisplayName: string,
	Role: string,
	MaxHealth: number,
	AttackDamage: number,
	AttackRange: number,
	AttackCooldown: number,
	MoveSpeed: number,
}

local champions: { [string]: ChampionDefinition } = {
	Tank = {
		Id = "Tank",
		DisplayName = "Tank",
		Role = "Tank",
		MaxHealth = 10000,
		AttackDamage = 200,
		AttackDamage2 = 45, 
		AttackRange = 14,
		AttackCooldown = 1.25,
		MoveSpeed = 92,
	},

	Assassin = {
		Id = "Assassin",
		DisplayName = "Assassin",
		Role = "Assassin",
		MaxHealth = 520,
		AttackDamage = 70,
		AttackRange = 13,
		AttackCooldown = 0.9,
		MoveSpeed = 112,
	},

	Mage = {
		Id = "Mage",
		DisplayName = "Mage",
		Role = "Mage",
		MaxHealth = 480,
		AttackDamage = 42,
		AttackRange = 28,
		AttackCooldown = 1.1,
		MoveSpeed = 100,
	},

	Marksman = {
		Id = "Marksman",
		DisplayName = "Marksman",
		Role = "Marksman",
		MaxHealth = 500,
		AttackDamage = 58,
		AttackRange = 34,
		AttackCooldown = 0.85,
		MoveSpeed = 102,
	},

	Support = {
		Id = "Support",
		DisplayName = "Support",
		Role = "Support",
		MaxHealth = 600,
		AttackDamage = 38,
		AttackRange = 24,
		AttackCooldown = 1.05,
		MoveSpeed = 100,
	},
}

ChampionData.Champions = champions
ChampionData.DEFAULT_CHAMPION_ID = DEFAULT_CHAMPION_ID

function ChampionData.getChampion(championId: string?): ChampionDefinition
	if typeof(championId) == "string" then
		local champion = champions[championId]
		if champion then
			return champion
		end
	end

	return champions[DEFAULT_CHAMPION_ID] :: ChampionDefinition
end

ChampionData.Default = ChampionData.getChampion(DEFAULT_CHAMPION_ID)

return ChampionData
