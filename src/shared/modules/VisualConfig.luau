--!strict

local VisualConfig = {}

VisualConfig.Lighting = {
	Brightness = 2,
	Ambient = Color3.fromRGB(100, 105, 115),
	OutdoorAmbient = Color3.fromRGB(75, 82, 95),
	ClockTime = 14,
	ExposureCompensation = 0.05,
}

VisualConfig.PostEffects = {
	BloomIntensity = 0.12,
	BloomSize = 16,
	BloomThreshold = 1.6,
	ColorSaturation = 0.08,
	ColorContrast = 0.06,
	ColorBrightness = 0.01,
	AtmosphereDensity = 0.12,
	AtmosphereOffset = 0.08,
	AtmosphereColor = Color3.fromRGB(200, 215, 235),
	AtmosphereDecay = Color3.fromRGB(90, 100, 125),
}

VisualConfig.MapMaterials = {
	Ground = {
		Color = Color3.fromRGB(58, 92, 64),
		Material = Enum.Material.Grass,
	},
	Lane = {
		Color = Color3.fromRGB(68, 76, 84),
		Material = Enum.Material.Slate,
	},
	River = {
		Color = Color3.fromRGB(42, 82, 118),
		Material = Enum.Material.SmoothPlastic,
	},
	Structure = {
		Color = Color3.fromRGB(78, 86, 104),
		Material = Enum.Material.Slate,
	},
	BlueCrystal = {
		Color = Color3.fromRGB(80, 180, 255),
		Material = Enum.Material.Neon,
	},
	RedCrystal = {
		Color = Color3.fromRGB(255, 90, 100),
		Material = Enum.Material.Neon,
	},
	NeutralCrystal = {
		Color = Color3.fromRGB(120, 220, 170),
		Material = Enum.Material.Neon,
	},
}

VisualConfig.AssetFolders = {
	"VFX",
	"Models",
	"Animations",
	"UI",
	"Packages",
}

return VisualConfig