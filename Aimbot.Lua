local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local ACCURACY_RATE = 0.95 -- Hit accuracy decimal threshold

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Safely fetches the tool and commands it to execute a programmatic fire sequence
local function fireEquippedTool()
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end
end

-- Checks if a target's head is visible on screen and not blocked by walls
local function isPlayerVisible(targetHead)
    if not targetHead then return false end
    
    -- 1. SCREEN VISIBILITY CHECK (Ensure they are actually on the screen)
    local screenPosition, onScreen = Camera:WorldToViewportPoint(targetHead.Position)
    if not onScreen then return false end
    
    -- 2. WALL CHECK (Raycast from camera to enemy head)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Ignore your own character so you don't block your own raycast
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetHead.Position - origin
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    
    -- If the raycast hits nothing, or it hits the target's character part, they are visible
    if not raycastResult or raycastResult.Instance:IsDescendantOf(targetHead.Parent) then
        return true
    end
    
    return false -- Hitting a wall or obstacle instead
end

local function getClosestPlayerHead()
    local closestHead = nil
    local shortestDistance = math.huge
    local teamsExist = areTeamsActive()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            
            -- DYNAMIC TEAM CHECK
            local shouldTarget = true
            if teamsExist then
                -- Check if target is on your team
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
                
                -- EXCLUSION CHECK: Ignore players on teams named "Lobby" or "Neutral"
                if player.Team then
                    local teamName = player.Team.Name
                    if teamName == "Lobby" or teamName == "Neutral" then
                        shouldTarget = false
                    end
                end
            end
            
            if shouldTarget then
                local head = player.Character:FindFirstChild("Head")
                local humanoid = player.Character:FindFirstChild("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
                    -- VISIBILITY & WALL CHECK PIPELINE
                    if isPlayerVisible(head) then
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local distance = (character.HumanoidRootPart.Position - head.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestHead = head
                            end
                        end
                    end
                end
            end
        end
    end
    return closestHead
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local targetHead = getClosestPlayerHead()
        
        if targetHead then
            -- 1. FLAWLESS 100% CONTINUOUS CAMERA HARD LOCK ON (Glued tracking)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            
            -- 2. ACCURACY AUTOFIT TRIGGERBOT ENGINE
            if math.random() <= ACCURACY_RATE then
                fireEquippedTool()
            end
        end
    end
end)
