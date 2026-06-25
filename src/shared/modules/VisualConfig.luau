--!strict

local VisualConfig = {}

VisualConfig.Lighting = {
	Brightness = 2.2,
	Ambient = Color3.fromRGB(95, 105, 125),
	OutdoorAmbient = Color3.fromRGB(65, 75, 95),
	ClockTime = 14,
	ExposureCompensation = 0.15,
}

VisualConfig.PostEffects = {
	BloomIntensity = 0.22,
	BloomSize = 24,
	BloomThreshold = 1.25,
	ColorSaturation = 0.12,
	ColorContrast = 0.08,
	ColorBrightness = 0.02,
	AtmosphereDensity = 0.18,
	AtmosphereOffset = 0.1,
	AtmosphereColor = Color3.fromRGB(190, 205, 230),
	AtmosphereDecay = Color3.fromRGB(80, 90, 120),
}

VisualConfig.AssetFolders = {
	"VFX",
	"Models",
	"Animations",
	"UI",
	"Packages",
}

return VisualConfig
