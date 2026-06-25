--!strict

local AutoAttackController = require(script.controllers.AutoAttackController)
local AbilityVFXController = require(script.controllers.AbilityVFXController)
local CombatFeedbackController = require(script.controllers.CombatFeedbackController)
local FogController = require(script.controllers.FogController)
local HudController = require(script.controllers.HudController)
local InputController = require(script.controllers.InputController)

InputController.start()
AutoAttackController.start()
CombatFeedbackController.start()
FogController.start()
HudController.start()
AbilityVFXController.start()

print("[MOBA] Client started — ZQSD, default Roblox camera, attack and HUD ready")
