--!strict

local Workspace = game:GetService("Workspace")

local ChampionService = require(script.services.ChampionService)
local JungleService = require(script.services.JungleService)
local MapValidatorService = require(script.services.MapValidatorService)
local MatchStateService = require(script.services.MatchStateService)
local MinionService = require(script.services.MinionService)
local NexusService = require(script.services.NexusService)
local RemoteService = require(script.services.RemoteService)
local TeamService = require(script.services.TeamService)
local TowerService = require(script.services.TowerService)
local VisionService = require(script.services.VisionService)
local EconomyProgressionService = require(script.services.EconomyProgressionService)
local ShopService = require(script.services.ShopService)

local map = Workspace:WaitForChild("Map", 10)
assert(map and map:IsA("Folder"), "[MOBA] Workspace.Map is missing. Open GameTest-editable.rbxlx in Studio.")

local units = Workspace:FindFirstChild("Units")
if not units then
	units = Instance.new("Folder")
	units.Name = "Units"
	units.Parent = Workspace
end
assert(units:IsA("Folder"), "[MOBA] Workspace.Units must be a Folder")

RemoteService.start()
MapValidatorService.start()
TeamService.start()
ChampionService.start()
TowerService.start()
JungleService.start()
NexusService.start()
VisionService.start()
MatchStateService.start()
EconomyProgressionService.start()
ShopService.start()
MinionService.start()


print("[MOBA] Server started — 3 lanes, jungle, ZQSD client ready")
