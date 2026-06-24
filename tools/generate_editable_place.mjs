import { spawnSync } from "node:child_process";
import { unlinkSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const temporaryProject = join(projectRoot, ".editable-place.project.json");
const outputPlace = join(projectRoot, "GameTest-editable.rbxlx");

const COLORS = {
	grass: rgb(52, 87, 50),
	lane: rgb(132, 126, 113),
	river: rgb(50, 130, 163),
	rock: rgb(66, 72, 70),
	laneEdge: rgb(70, 73, 69),
	blue: rgb(55, 151, 255),
	blueDark: rgb(24, 59, 101),
	red: rgb(239, 71, 78),
	redDark: rgb(110, 35, 41),
	neutral: rgb(207, 157, 76),
};

const PATHS = {
	Top: [
		[-500, 0, -20],
		[-430, 0, -230],
		[-300, 0, -345],
		[0, 0, -370],
		[300, 0, -345],
		[430, 0, -230],
		[500, 0, -20],
	],
	Mid: [
		[-500, 0, 0],
		[-340, 0, 0],
		[-170, 0, 0],
		[0, 0, 0],
		[170, 0, 0],
		[340, 0, 0],
		[500, 0, 0],
	],
	Bot: [
		[-500, 0, 20],
		[-430, 0, 230],
		[-300, 0, 345],
		[0, 0, 370],
		[300, 0, 345],
		[430, 0, 230],
		[500, 0, 20],
	],
};

function rgb(red, green, blue) {
	return [red / 255, green / 255, blue / 255];
}

function typedAttribute(value) {
	if (typeof value === "string") return { String: value };
	if (typeof value === "boolean") return { Bool: value };
	return { Float64: value };
}

function attributes(values) {
	return Object.fromEntries(Object.entries(values).map(([key, value]) => [key, typedAttribute(value)]));
}

function folder(children = {}, attributeValues = null) {
	const description = { $className: "Folder", ...children };
	if (attributeValues) {
		description.$properties = { Attributes: attributes(attributeValues) };
	}
	return description;
}

function model(children = {}, attributeValues = null) {
	const description = { $className: "Model", ...children };
	if (attributeValues) {
		description.$properties = { Attributes: attributes(attributeValues) };
	}
	return description;
}

function yawCFrame(position, yaw = 0) {
	const cosine = Math.cos(yaw);
	const sine = Math.sin(yaw);
	return [
		position[0],
		position[1],
		position[2],
		cosine,
		0,
		sine,
		0,
		1,
		0,
		-sine,
		0,
		cosine,
	];
}

function verticalCylinderCFrame(position) {
	return [
		position[0],
		position[1],
		position[2],
		0,
		-1,
		0,
		1,
		0,
		0,
		0,
		0,
		1,
	];
}

function part({
	size,
	position,
	color,
	material,
	yaw = 0,
	canCollide = true,
	transparency = 0,
	shape = "Block",
	attributeValues = null,
	cframe = null,
	children = {},
}) {
	const properties = {
		Anchored: true,
		CanCollide: canCollide,
		CanTouch: canCollide,
		Size: size,
		CFrame: cframe ?? yawCFrame(position, yaw),
		Color: color,
		Material: material,
		Transparency: transparency,
		Shape: shape,
	};
	if (attributeValues) properties.Attributes = attributes(attributeValues);
	return { $className: "Part", $properties: properties, ...children };
}

function disc(position, diameter, height, color) {
	return part({
		size: [height, diameter, diameter],
		position,
		color,
		material: "Slate",
		shape: "Cylinder",
		cframe: verticalCylinderCFrame(position),
	});
}

function light(color, brightness, range) {
	return {
		$className: "PointLight",
		$properties: { Color: color, Brightness: brightness, Range: range },
	};
}

function laneSegment(start, finish) {
	const dx = finish[0] - start[0];
	const dz = finish[2] - start[2];
	const length = Math.hypot(dx, dz);
	const midpoint = [(start[0] + finish[0]) / 2, 0.32, (start[2] + finish[2]) / 2];
	return part({
		size: [length + 4, 0.65, 52],
		position: midpoint,
		yaw: -Math.atan2(dz, dx),
		color: COLORS.lane,
		material: "Cobblestone",
	});
}

function tower(teamName, position) {
	const isBlue = teamName === "Blue";
	const color = isBlue ? COLORS.blue : COLORS.red;
	const dark = isBlue ? COLORS.blueDark : COLORS.redDark;
	return model(
		{
			Foundation: disc([position[0], 1.25, position[2]], 19, 2.5, COLORS.laneEdge),
			HumanoidRootPart: part({
				size: [8, 17, 8],
				position: [position[0], 10, position[2]],
				color: dark,
				material: "Basalt",
			}),
			Focus: part({
				size: [9, 9, 9],
				position: [position[0], 22, position[2]],
				color,
				material: "Neon",
				canCollide: false,
				shape: "Ball",
				children: { Light: light(color, 1.8, 30) },
			}),
		},
		{
			Team: teamName,
			UnitType: "Tower",
			MaxHealth: 3000,
			Health: 3000,
			AttackDamage: 150,
			AttackRange: 90,
			AttackCooldown: 1,
			Dead: false,
		},
	);
}

function nexus(teamName, position) {
	const isBlue = teamName === "Blue";
	const color = isBlue ? COLORS.blue : COLORS.red;
	const dark = isBlue ? COLORS.blueDark : COLORS.redDark;
	return model(
		{
			Platform: disc([position[0], 1, position[2]], 45, 2, dark),
			HumanoidRootPart: part({
				size: [10, 24, 10],
				position: [position[0], 13, position[2]],
				yaw: Math.PI / 4,
				color,
				material: "Neon",
				children: { Light: light(color, 2.5, 42) },
			}),
		},
		{ Team: teamName, UnitType: "Nexus", MaxHealth: 5000, Health: 5000, Dead: false },
	);
}

function waypoint(position, order) {
	return part({
		size: [3, 3, 3],
		position: [position[0], 1.5, position[2]],
		color: COLORS.neutral,
		material: "Neon",
		canCollide: false,
		transparency: 1,
		attributeValues: { Order: order },
	});
}

function buildTerrain() {
	const terrain = {
		Ground: part({
			size: [1200, 4, 900],
			position: [0, -2, 0],
			color: COLORS.grass,
			material: "Grass",
		}),
		River: part({
			size: [34, 0.4, 870],
			position: [0, 0.1, 0],
			color: COLORS.river,
			material: "Glass",
			canCollide: false,
			transparency: 0.2,
		}),
		BlueBase: disc([-535, 0.8, 0], 125, 1.6, COLORS.blueDark),
		RedBase: disc([535, 0.8, 0], 125, 1.6, COLORS.redDark),
	};

	for (const [laneName, points] of Object.entries(PATHS)) {
		const segments = {};
		for (let index = 0; index < points.length - 1; index += 1) {
			segments["Segment_" + String(index + 1).padStart(2, "0")] = laneSegment(points[index], points[index + 1]);
		}
		terrain[laneName] = folder(segments);
	}

	for (let index = 1; index <= 40; index += 1) {
		const side = index % 2 === 0 ? -1 : 1;
		const x = -560 + ((index * 83) % 1120);
		const z = side * (415 + ((index * 7) % 24));
		const scale = 10 + ((index * 5) % 13);
		terrain["BoundaryRock_" + String(index).padStart(2, "0")] = part({
			size: [scale, scale * 0.75, scale],
			position: [x, scale * 0.3, z],
			color: COLORS.rock,
			material: "Rock",
			shape: "Ball",
		});
	}

	const walls = [
		[[0, 20, -450], [1200, 40, 4]],
		[[0, 20, 450], [1200, 40, 4]],
		[[-600, 20, 0], [4, 40, 900]],
		[[600, 20, 0], [4, 40, 900]],
	];
	walls.forEach(([position, size], index) => {
		terrain["Boundary_" + (index + 1)] = part({
			size,
			position,
			color: COLORS.rock,
			material: "SmoothPlastic",
			transparency: 1,
		});
	});
	return folder(terrain);
}

function buildPaths() {
	const blue = {};
	const red = {};
	for (const [laneName, points] of Object.entries(PATHS)) {
		const blueWaypoints = {};
		const redWaypoints = {};
		points.forEach((position, index) => {
			blueWaypoints[String(index + 1).padStart(2, "0")] = waypoint(position, index + 1);
		});
		[...points].reverse().forEach((position, index) => {
			redWaypoints[String(index + 1).padStart(2, "0")] = waypoint(position, index + 1);
		});
		blue[laneName] = folder(blueWaypoints);
		red[laneName] = folder(redWaypoints);
	}
	return folder({ Blue: folder(blue), Red: folder(red) });
}

function buildMinionSpawns() {
	const blue = {};
	const red = {};
	for (const [laneName, points] of Object.entries(PATHS)) {
		blue[laneName] = part({
			size: [8, 1, 8],
			position: [points[0][0], 0.5, points[0][2]],
			color: COLORS.blue,
			material: "Neon",
			canCollide: false,
			transparency: 0.45,
			attributeValues: { Lane: laneName },
		});
		const last = points.at(-1);
		red[laneName] = part({
			size: [8, 1, 8],
			position: [last[0], 0.5, last[2]],
			color: COLORS.red,
			material: "Neon",
			canCollide: false,
			transparency: 0.45,
			attributeValues: { Lane: laneName },
		});
	}
	return folder({ Blue: folder(blue), Red: folder(red) });
}

function buildTowers() {
	return folder({
		BlueTopTower: tower("Blue", [-285, 0, -380]),
		RedTopTower: tower("Red", [285, 0, -380]),
		BlueMidTower: tower("Blue", [-265, 0, -34]),
		RedMidTower: tower("Red", [265, 0, 34]),
		BlueBotTower: tower("Blue", [-285, 0, 380]),
		RedBotTower: tower("Red", [285, 0, 380]),
	});
}

function buildNexus() {
	return folder({
		BlueNexus: nexus("Blue", [-535, 0, 0]),
		RedNexus: nexus("Red", [535, 0, 0]),
	});
}

function buildPlayerSpawns() {
	return folder({
		Blue: part({
			size: [14, 1, 14],
			position: [-490, 1, 0],
			color: COLORS.blue,
			material: "Neon",
			transparency: 0.2,
			attributeValues: { Team: "Blue" },
		}),
		Red: part({
			size: [14, 1, 14],
			position: [490, 1, 0],
			color: COLORS.red,
			material: "Neon",
			transparency: 0.2,
			attributeValues: { Team: "Red" },
		}),
	});
}

function buildJungleCamps() {
	const camps = [
		["BlueWolfTop", "SmallWolf", "Blue", [-250, 0.3, -185]],
		["BlueGolemBot", "BigGolem", "Blue", [-210, 0.3, 195]],
		["RedWolfBot", "SmallWolf", "Red", [250, 0.3, 185]],
		["RedGolemTop", "BigGolem", "Red", [210, 0.3, -195]],
		["Dragon", "DragonPrototype", "Neutral", [0, 0.3, 180]],
	];
	const children = {};
	for (const [name, campType, teamSide, position] of camps) {
		children[name] = part({
			size: [14, 0.6, 14],
			position,
			color: COLORS.neutral,
			material: "Neon",
			canCollide: false,
			transparency: 0.35,
			attributeValues: { CampType: campType, TeamSide: teamSide },
		});
	}
	return folder(children);
}

const map = folder(
	{
		Terrain: buildTerrain(),
		Paths: buildPaths(),
		MinionSpawns: buildMinionSpawns(),
		Towers: buildTowers(),
		JungleCamps: buildJungleCamps(),
		Nexus: buildNexus(),
		PlayerSpawns: buildPlayerSpawns(),
	},
	{ Version: 1, Mode: "MOBA5v5" },
);

const project = {
	name: "GameTest Editable",
	tree: {
		$className: "DataModel",
		ReplicatedStorage: {
			Modules: { $path: "src/shared/modules" },
		},
		ServerScriptService: {
			Server: { $path: "src/server" },
		},
		StarterPlayer: {
			$properties: { DevComputerMovementMode: "Scriptable" },
			StarterPlayerScripts: {
				Client: { $path: "src/client" },
			},
		},
		Workspace: {
			$properties: { FilteringEnabled: true, FallenPartsDestroyHeight: -100 },
			Map: map,
			Units: folder(),
		},
		Lighting: {
			$properties: {
				Ambient: [0.24, 0.27, 0.3],
				Brightness: 2.4,
				ClockTime: 15.2,
				GlobalShadows: true,
				Outlines: false,
			},
			MobaAtmosphere: {
				$className: "Atmosphere",
				$properties: {
					Color: rgb(196, 220, 210),
					Decay: rgb(90, 110, 124),
					Density: 0.16,
					Haze: 1,
				},
			},
		},
		SoundService: {
			$properties: { RespectFilteringEnabled: true },
		},
	},
};

writeFileSync(temporaryProject, JSON.stringify(project, null, 2) + "\n");
try {
	const result = spawnSync("rojo", ["build", temporaryProject, "-o", outputPlace], {
		cwd: projectRoot,
		stdio: "inherit",
	});
	if (result.status !== 0) process.exit(result.status ?? 1);
} finally {
	unlinkSync(temporaryProject);
}

console.log("Editable place created at " + outputPlace);
