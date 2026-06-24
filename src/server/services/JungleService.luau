--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local JungleData = require(ReplicatedStorage.Modules.JungleData)
local CombatService = require(script.Parent.CombatService)
local UnitFactory = require(script.Parent.UnitFactory)
local Utility = require(script.Parent.Utility)

local JungleService = {}

type AggroState = {
	target: Instance,
	lastHitAt: number,
	spawnPosition: Vector3,
}

local AGGRO_TIMEOUT = 6
local LEASH_RANGE = 65

local monsterAggro: { [Model]: AggroState } = setmetatable({}, { __mode = "k" }) :: any
local damageListenerRegistered = false

local function getUnitType(unit: Instance): string?
	local unitType = unit:GetAttribute("UnitType")
	return if typeof(unitType) == "string" then unitType else nil
end

local function clearAggro(monster: Model)
	monsterAggro[monster] = nil
	monster:SetAttribute("Aggro", false)
end

local function setAggro(monster: Model, target: Instance)
	local root = Utility.getRoot(monster)
	if not root then
		return
	end

	monsterAggro[monster] = {
		target = target,
		lastHitAt = os.clock(),
		spawnPosition = root.Position,
	}

	monster:SetAttribute("Aggro", true)
end

local function registerDamageListener()
	if damageListenerRegistered then
		return
	end
	damageListenerRegistered = true

	CombatService.onDamage(function(attacker: Instance, target: Instance, _damage: number)
		if getUnitType(target) ~= "JungleMonster" then
			return
		end
		if getUnitType(attacker) ~= "Champion" then
			return
		end
		if not target:IsA("Model") then
			return
		end
		if not Utility.isAlive(target) or not Utility.isAlive(attacker) then
			return
		end

		setAggro(target, attacker)
	end)
end

local function runMonsterAI(monster: Model)
	task.spawn(function()
		while monster.Parent and Utility.isAlive(monster) do
			local state = monsterAggro[monster]

			if state then
				local target = state.target
				local monsterRoot = Utility.getRoot(monster)

				local shouldReset = false

				if not monsterRoot then
					shouldReset = true
				elseif not target.Parent or not Utility.isAlive(target) then
					shouldReset = true
				elseif os.clock() - state.lastHitAt > AGGRO_TIMEOUT then
					shouldReset = true
				elseif (monsterRoot.Position - state.spawnPosition).Magnitude > LEASH_RANGE then
					shouldReset = true
				end

				if shouldReset then
					clearAggro(monster)
				else
					CombatService.tryAutoAttack(monster, target, nil)
				end
			end

			task.wait(0.3)
		end
	end)
end

function JungleService.spawnCamp(campPart: BasePart)
	local campTypeAttribute = campPart:GetAttribute("CampType")
	if typeof(campTypeAttribute) ~= "string" then
		return
	end

	local data = JungleData.Camps[campTypeAttribute]
	if not data then
		warn("[MOBA] Invalid jungle camp:", campTypeAttribute)
		return
	end

	local monster = UnitFactory.createJungleMonster(campTypeAttribute, campPart.Position)
	if not monster then
		return
	end

	monster.Parent = Workspace:WaitForChild("Units")
	monster:SetAttribute("Aggro", false)

	monster:GetAttributeChangedSignal("Dead"):Connect(function()
		if monster:GetAttribute("Dead") == true then
			clearAggro(monster)

			task.delay(2, function()
				if monster.Parent then
					monster:Destroy()
				end
			end)

			task.delay(data.RespawnTime, function()
				if campPart.Parent then
					JungleService.spawnCamp(campPart)
				end
			end)
		end
	end)

	runMonsterAI(monster)
end

function JungleService.start()
	registerDamageListener()

	local camps = Workspace:WaitForChild("Map"):WaitForChild("JungleCamps")
	for _, campPart in camps:GetChildren() do
		if campPart:IsA("BasePart") then
			JungleService.spawnCamp(campPart)
		end
	end
end

return JungleService