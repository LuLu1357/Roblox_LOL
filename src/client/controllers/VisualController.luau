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

function VisualController.start()
	if started then
		return
	end
	started = true

	ensureAssetsFolders()
	applyLighting()

	print("[MOBA][VISUAL] VisualController started")
end

return VisualController
