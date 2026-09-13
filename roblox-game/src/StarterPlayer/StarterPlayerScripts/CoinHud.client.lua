-- Builds the on-screen coin counter and the "you win" banner, and wires them
-- up to the server's leaderstats and PlayerWon remote event.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.AnchorPoint = Vector2.new(1, 0)
coinLabel.Position = UDim2.new(1, -20, 0, 20)
coinLabel.Size = UDim2.new(0, 220, 0, 50)
coinLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
coinLabel.BackgroundTransparency = 0.3
coinLabel.TextColor3 = Color3.fromRGB(255, 223, 0)
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 24
coinLabel.Text = "Coins: 0"
coinLabel.Parent = screenGui

local winLabel = Instance.new("TextLabel")
winLabel.Name = "WinLabel"
winLabel.AnchorPoint = Vector2.new(0.5, 0.5)
winLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
winLabel.Size = UDim2.new(0, 500, 0, 80)
winLabel.BackgroundTransparency = 1
winLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
winLabel.Font = Enum.Font.GothamBold
winLabel.TextSize = 40
winLabel.Text = ""
winLabel.Visible = false
winLabel.Parent = screenGui

local function bindCoinLabel()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins")

	local function updateLabel()
		coinLabel.Text = string.format("Coins: %d", coins.Value)
	end

	coins:GetPropertyChangedSignal("Value"):Connect(updateLabel)
	updateLabel()
end

bindCoinLabel()

local playerWonEvent = ReplicatedStorage:WaitForChild("PlayerWon")
playerWonEvent.OnClientEvent:Connect(function()
	winLabel.Text = "You collected enough coins - you win!"
	winLabel.Visible = true
	task.wait(5)
	winLabel.Visible = false
end)
