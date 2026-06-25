--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualConfig = require(ReplicatedStorage.Modules.VisualConfig)

local VisualController = {}

local started = false

local function ensureAssetsFolders()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = ReplicatedStorage
	end

	for _, folderName in VisualConfig.AssetFolders do
		if not assets:FindFirstChild(folderName) then
			local folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = assets
		end
	end
end

local function applyLighting()
	local lightingConfig = VisualConfig.Lighting
	Lighting.Brightness = lightingConfig.Brightness
	Lighting.Ambient = lightingConfig.Ambient
	Lighting.OutdoorAmbient = lightingConfig.OutdoorAmbient
	Lighting.ClockTime = lightingConfig.ClockTime
	Lighting.ExposureCompensation = lightingConfig.ExposureCompensation

	local effects = VisualConfig.PostEffects

	local bloom = Lighting:FindFirstChild("MOBA_Bloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "MOBA_Bloom"
		bloom.Parent = Lighting
	end
	if bloom:IsA("BloomEffect") then
		bloom.Intensity = effects.BloomIntensity
		bloom.Size = effects.BloomSize
		bloom.Threshold = effects.BloomThreshold
	end

	local colorCorrection = Lighting:FindFirstChild("MOBA_ColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "MOBA_ColorCorrection"
		colorCorrection.Parent = Lighting
	end
	if colorCorrection:IsA("ColorCorrectionEffect") then
		colorCorrection.Saturation = effects.ColorSaturation
		colorCorrection.Contrast = effects.ColorContrast
		colorCorrection.Brightness = effects.ColorBrightness
	end

	local atmosphere = Lighting:FindFirstChild("MOBA_Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "MOBA_Atmosphere"
		atmosphere.Parent = Lighting
	end
	if atmosphere:IsA("Atmosphere") then
		atmosphere.Density = effects.AtmosphereDensity
		atmosphere.Offset = effects.AtmosphereOffset
		atmosphere.Color = effects.AtmosphereColor
		atmosphere.Decay = effects.AtmosphereDecay
	end
end
local function applyMaterialToPart(part: BasePart, visual: any)
	if typeof(visual) ~= "table" then
		return
	end

	if typeof(visual.Color) == "Color3" then
		part.Color = visual.Color
	end

	if typeof(visual.Material) == "EnumItem" then
		part.Material = visual.Material
	end
end

local function shouldIgnorePart(part: BasePart): boolean
	if part.Name == "HumanoidRootPart" then
		return true
	end

	if part:FindFirstAncestor("Units") then
		return true
	end

	if part:FindFirstAncestor("HealthBar") then
		return true
	end

	return false
end

local function applyMapPalette()
	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("[MOBA][VISUAL] Workspace.Map not found for palette")
		return
	end

	local materials = VisualConfig.MapMaterials
	if typeof(materials) ~= "table" then
		return
	end

	for _, descendant in map:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		if shouldIgnorePart(descendant) then
			continue
		end

		local name = string.lower(descendant.Name)

		if string.find(name, "ground") or string.find(name, "grass") then
			applyMaterialToPart(descendant, materials.Ground)
		elseif string.find(name, "lane") or string.find(name, "road") or string.find(name, "path") then
			applyMaterialToPart(descendant, materials.Lane)
		elseif string.find(name, "river") or string.find(name, "water") then
			applyMaterialToPart(descendant, materials.River)
		elseif string.find(name, "tower") or string.find(name, "wall") or string.find(name, "base") then
			applyMaterialToPart(descendant, materials.Structure)
		elseif string.find(name, "nexus") or string.find(name, "crystal") then
			local team = descendant:GetAttribute("Team")
			if team == "Red" then
				applyMaterialToPart(descendant, materials.RedCrystal)
			elseif team == "Blue" then
				applyMaterialToPart(descendant, materials.BlueCrystal)
			else
				applyMaterialToPart(descendant, materials.NeutralCrystal)
			end
		end
	end
end

function VisualController.start()
	if started then
		return
	end
	started = true

	ensureAssetsFolders()
	applyLighting()
	applyMapPalette()

	print("[MOBA][VISUAL] VisualController started")
end

return VisualController
