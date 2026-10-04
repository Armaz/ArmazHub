local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local WALK_SPEED = 16

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Uses your exact team-checking logic to determine highlight colors
local function getTeamColor(player)
    local teamsExist = areTeamsActive()
    
    if teamsExist then
        -- 1. EXCLUSION CHECK: Lobby or Neutral teams are Gray
        if player.Team then
            local teamName = player.Team.Name
            if teamName == "Lobby" or teamName == "Neutral" then
                return Color3.fromRGB(128, 128, 128) -- Gray
            end
        end
        
        -- 2. TEAM CHECK: Check if target is on your team (Green)
        if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            return Color3.fromRGB(0, 255, 0) -- Green
        end
    end
    
    -- 3. DEFAULT/OPPOSING: Everyone else is Red
    return Color3.fromRGB(255, 0, 0) -- Red
end

-- Helper to check if a player is an opposing teammate (not neutral/lobby, not on your team)
local function isOpposingTeam(player)
    local teamsExist = areTeamsActive()
    if teamsExist then
        if player.Team then
            local teamName = player.Team.Name
            if teamName == "Lobby" or teamName == "Neutral" then
                return false
            end
        end
        if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            return false
        end
    end
    -- If no teams exist or they are on a different team, they are opposing
    return player ~= LocalPlayer
end

local function addOrUpdateHighlight(player, character)
    if not character then return end

    local highlight = character:FindFirstChild("GlobalHighlight")
    
    -- Create highlight if it doesn't exist
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "GlobalHighlight"
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end

    -- Apply color based on team logic
    highlight.FillColor = getTeamColor(player)
end

local function setupHealthBillboard(player, character)
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    -- Check if billboard already exists
    local billboard = character:FindFirstChild("HealthBillboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "HealthBillboard"
        billboard.Size = UDim2.new(0, 120, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        
        -- Green background fill frame for the health display
        local fillFrame = Instance.new("Frame")
        fillFrame.Name = "FillFrame"
        fillFrame.Size = UDim2.new(1, 0, 0, 24)
        fillFrame.Position = UDim2.new(0, 0, 0.5, -12)
        fillFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Green fill color
        fillFrame.BorderSizePixel = 0
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 4)
        uiCorner.Parent = fillFrame
        
        fillFrame.Parent = billboard
        
        -- Bigger text label for the percentage
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "HealthLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextSize = 18 -- Increased size
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard
        
        billboard.Parent = character
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    local textLabel = billboard:FindFirstChild("HealthLabel")
    local fillFrame = billboard:FindFirstChild("FillFrame")

    if humanoid and textLabel and fillFrame then
        local function updateHealthText()
            -- Only show health for opposing team members
            if isOpposingTeam(player) and humanoid.Health > 0 then
                billboard.Enabled = true
                local healthPercent = math.clamp(math.floor((humanoid.Health / humanoid.MaxHealth) * 100 + 0.5), 0, 100)
                textLabel.Text = healthPercent .. "%"
                
                -- Dynamically scale the green fill frame width based on health percentage
                fillFrame.Size = UDim2.new(healthPercent / 100, 0, 0, 24)
            else
                billboard.Enabled = false
            end
        end

        humanoid.HealthChanged:Connect(updateHealthText)
        updateHealthText()
    end
end

local function setupCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")

    -- Speed boost
    humanoid.WalkSpeed = WALK_SPEED

    -- Add or update the colored ESP highlight
    addOrUpdateHighlight(player, character)
    
    -- Add health percentage UI only for opposing team members
    setupHealthBillboard(player, character)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)

    -- If already spawned
    if player.Character then
        setupCharacter(player, player.Character)
    end
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setupCharacter(player, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
end
