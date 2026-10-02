local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams") -- Reference the Teams service

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local MAX_DISTANCE = 500
local SMOOTHNESS = 0.15 
local JITTER_STRENGTH = 0.01

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

local function getClosestPlayerHead()
    local closestHead = nil
    local shortestDistance = MAX_DISTANCE
    local teamsExist = areTeamsActive()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            
            -- DYNAMIC TEAM CHECK
            local shouldTarget = true
            if teamsExist then
                -- If teams exist, only target them if they are on a different team
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
            end
            
            if shouldTarget then
                local head = player.Character:FindFirstChild("Head")
                local humanoid = player.Character:FindFirstChild("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
                    -- Get distance from your character to the target
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
    return closestHead
end

-- This runs every frame automatically
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local targetHead = getClosestPlayerHead()
        
        if targetHead then
            -- 1. CALCULATE DIRECTION WITH JITTER
            local jitter = Vector3.new(
                math.random(-100, 100) / 1000 * JITTER_STRENGTH,
                math.random(-100, 100) / 1000 * JITTER_STRENGTH,
                math.random(-100, 100) / 1000 * JITTER_STRENGTH
            )
            
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position + jitter)

            -- 2. SMOOTH ROTATION (LERP)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
        end
    end
end)
