-- Builds the whole "Coin Collector Obby" course from scratch and runs its
-- gameplay loop: rising stepping-stone platforms lead to a coin room; collect
-- enough coins and step on the gold pad to win. Building the map here (instead
-- of hand-placing parts in Studio) keeps the whole game reproducible from code.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local COINS_TO_WIN = 10
local COIN_COUNT = 10
local PLATFORM_COUNT = 8
local FALL_RESET_HEIGHT = -25

-- Tells clients when they've won so the HUD can celebrate.
local playerWonEvent = Instance.new("RemoteEvent")
playerWonEvent.Name = "PlayerWon"
playerWonEvent.Parent = ReplicatedStorage

local mapFolder = Instance.new("Folder")
mapFolder.Name = "GameMap"
mapFolder.Parent = Workspace

local function createPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = mapFolder
	return part
end

createPart({
	Name = "Ground",
	Size = Vector3.new(40, 1, 40),
	Position = Vector3.new(0, 0, 0),
	Color = Color3.fromRGB(96, 156, 96),
	Material = Enum.Material.Grass,
})

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(8, 1, 8)
spawnLocation.Position = Vector3.new(0, 1, 0)
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color = Color3.fromRGB(90, 170, 255)
spawnLocation.Parent = mapFolder

-- Rising stepping-stone platforms with gaps between them.
local lastPlatformPosition = Vector3.new(0, 1, 0)
for i = 1, PLATFORM_COUNT do
	local position = Vector3.new(0, 2 + i * 1.5, i * 8)
	createPart({
		Name = "Platform" .. i,
		Size = Vector3.new(6, 1, 6),
		Position = position,
		Color = i % 2 == 0 and Color3.fromRGB(255, 170, 60) or Color3.fromRGB(255, 210, 90),
		Material = Enum.Material.SmoothPlastic,
	})
	lastPlatformPosition = position
end

local coinRoomPosition = lastPlatformPosition + Vector3.new(0, 1.5, 10)
createPart({
	Name = "CoinRoom",
	Size = Vector3.new(26, 1, 26),
	Position = coinRoomPosition,
	Color = Color3.fromRGB(200, 200, 210),
	Material = Enum.Material.Marble,
})

local winPad = createPart({
	Name = "WinPad",
	Size = Vector3.new(6, 1, 6),
	Position = coinRoomPosition + Vector3.new(0, 1, 0),
	Color = Color3.fromRGB(255, 215, 0),
	Material = Enum.Material.Neon,
	CanCollide = false,
})

local coinsFolder = Instance.new("Folder")
coinsFolder.Name = "Coins"
coinsFolder.Parent = mapFolder

local coinParts = {}
local touchDebounce = {}

local function spawnCoin(position)
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 2, 2)
	coin.Orientation = Vector3.new(0, 0, 90)
	coin.Position = position
	coin.Anchored = true
	coin.CanCollide = false
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(255, 223, 0)
	coin.Parent = coinsFolder

	coin.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or not coin.CanTouch then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player or touchDebounce[coin] then
			return
		end
		touchDebounce[coin] = true

		local leaderstats = player:FindFirstChild("leaderstats")
		local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue.Value += 1
		end

		coin.Transparency = 1
		coin.CanTouch = false

		task.delay(5, function()
			coin.Transparency = 0
			coin.CanTouch = true
			touchDebounce[coin] = nil
		end)
	end)

	table.insert(coinParts, coin)
end

for i = 1, COIN_COUNT do
	local angle = (i / COIN_COUNT) * math.pi * 2
	local radius = 8
	local offset = Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
	spawnCoin(coinRoomPosition + offset)
end

local wonPlayers = {}
winPad.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player or wonPlayers[player] then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coinsValue or coinsValue.Value < COINS_TO_WIN then
		return
	end

	wonPlayers[player] = true
	playerWonEvent:FireClient(player)
end)

Players.PlayerRemoving:Connect(function(player)
	wonPlayers[player] = nil
end)

-- Single loop drives coin spin and catches anyone who falls off the course.
RunService.Heartbeat:Connect(function(deltaTime)
	local spin = CFrame.Angles(0, math.rad(60) * deltaTime, 0)
	for _, coin in ipairs(coinParts) do
		coin.CFrame = coin.CFrame * spin
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart and rootPart.Position.Y < FALL_RESET_HEIGHT then
			humanoid.Health = 0
		end
	end
end)
