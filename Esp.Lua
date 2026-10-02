local Players = game:GetService("Players")

-- SETTINGS
local WALK_SPEED = 24

local LocalPlayer = Players.LocalPlayer

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local Teams = game:GetService("Teams")
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Determines the correct color based on team logic
local function getTeamColor(targetPlayer)
    -- If it's yourself, or teams aren't active, default to white or gray
    if targetPlayer == LocalPlayer or not areTeamsActive() then
        return Color3.fromRGB(200, 200, 200) -- Default gray
    end

    local targetTeam = targetPlayer.Team
    local localTeam = LocalPlayer.Team

    -- Check if target is on "Lobby" or "Neutral"
    if targetTeam then
        local teamName = targetTeam.Name
        if teamName == "Lobby" or teamName == "Neutral" then
            return Color3.fromRGB(128, 128, 128) -- Gray for Lobby/Neutral
        end
    end

    -- Check if they are on the same team as you
    if localTeam and targetTeam and localTeam == targetTeam then
        return Color3.fromRGB(0, 255, 0) -- Green for Teammates
    else
        return Color3.fromRGB(255, 0, 0) -- Red for Opposing Players
    end
end

local function addOrUpdateHighlight(player, character)
    if not character then return end

    local highlight = character:FindFirstChild("GlobalHighlight")
    
    -- Create the highlight if it doesn't exist yet
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "GlobalHighlight"
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end

    -- Apply the correct color based on team conditions
    highlight.FillColor = getTeamColor(player)
end

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	-- speed boost
	humanoid.WalkSpeed = WALK_SPEED

	-- add/update ESP for the player
	addOrUpdateHighlight(player, character)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	-- if already spawned
	if player.Character then
		setupCharacter(player, player.Character)
	end
end)

-- also handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setupCharacter(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
end
