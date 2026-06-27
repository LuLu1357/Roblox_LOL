--!strict

local VisualConfig = {}

VisualConfig.Lighting = {
	Brightness = 2,
	Ambient = Color3.fromRGB(70, 70, 95),
	OutdoorAmbient = Color3.fromRGB(100, 100, 130),
	ClockTime = 17.8,
	ExposureCompensation = 0,
	GlobalShadows = true,
	ShadowSoftness = 0.55,
	EnvironmentDiffuseScale = 0.7,
	EnvironmentSpecularScale = 0.8,
}

VisualConfig.PostEffects = {
	BloomIntensity = 0.2,
	BloomSize = 24,
	BloomThreshold = 1.2,
	ColorSaturation = -0.03,
	ColorContrast = 0.12,
	ColorBrightness = 0.02,
	ColorTint = Color3.fromRGB(225, 230, 255),
	AtmosphereDensity = 0.25,
	AtmosphereOffset = 0.1,
	AtmosphereHaze = 2,
	AtmosphereGlare = 0.15,
	AtmosphereColor = Color3.fromRGB(190, 205, 230),
	AtmosphereDecay = Color3.fromRGB(80, 90, 130),
	SunRaysIntensity = 0.04,
	SunRaysSpread = 0.7,
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

VisualConfig.AssetModels = {
	Minions = {
		Blue = {
			Melee = {
				Path = "Assets/Models/Minions/Blue/Melee",
				ModelName = "BlueMeleeVisual",
			},
			Ranged = {
				Path = "Assets/Models/Minions/Blue/Ranged",
				ModelName = "BlueRangedVisual",
			},
			Siege = {
				Path = "Assets/Models/Minions/Blue/Siege",
				ModelName = "BlueSiegeVisual",
			},
		},
		Red = {
			Melee = {
				Path = "Assets/Models/Minions/Red/Melee",
				ModelName = "RedMeleeVisual",
			},
			Ranged = {
				Path = "Assets/Models/Minions/Red/Ranged",
				ModelName = "RedRangedVisual",
			},
			Siege = {
				Path = "Assets/Models/Minions/Red/Siege",
				ModelName = "RedSiegeVisual",
			},
		},
	},
	Jungle = {
		Dragon = {
			Path = "Assets/Models/Jungle/Dragon",
			ModelName = "Dragon",
		},
		Golem = {
			Path = "Assets/Models/Jungle/Golem",
			ModelName = "Golem",
		},
		Wolf = {
			Path = "Assets/Models/Jungle/Wolf",
			ModelName = "Wolf",
		},
		SmallMonster = {
			Path = "Assets/Models/Jungle/SmallMonster",
			ModelName = "SmallMonster",
		},
	},
	Structures = {
		Towers = {
			Blue = {
				Path = "Assets/Models/Structures/Towers",
				ModelName = "BlueTowerVisual",
			},
			Red = {
				Path = "Assets/Models/Structures/Towers",
				ModelName = "RedTowerVisual",
			},
		},
		Inhibitors = {
			Blue = {
				Path = "Assets/Models/Structures/Inhibitors",
				ModelName = "BlueInhibitorVisual",
			},
			Red = {
				Path = "Assets/Models/Structures/Inhibitors",
				ModelName = "RedInhibitorVisual",
			},
		},
		Nexus = {
			Blue = {
				Path = "Assets/Models/Structures/Nexus",
				ModelName = "BlueNexusVisual",
			},
			Red = {
				Path = "Assets/Models/Structures/Nexus",
				ModelName = "RedNexusVisual",
			},
		},
	},
	Props = {
		Jungle = "Assets/Models/Props/Jungle",
		Base = "Assets/Models/Props/Base",
		Shop = "Assets/Models/Props/Shop",
	},
}

VisualConfig.LegacyAssetModels = {
	MinionsRoot = "Assets/Models/sbires",
	TowersRoot = "Assets/Models/Towers",
}

return VisualConfig
