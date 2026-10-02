local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local HIT_CHANCE = 80 -- 80% chance to hit the head perfectly

-- Track the current target and whether this engagement is a "hit" or "miss"
local currentTarget = nil
local shouldHitCurrentTarget = true

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
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
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
            end
            
            if shouldTarget then
                local head = player.Character:FindFirstChild("Head")
                local humanoid = player.Character:FindFirstChild("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
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
            -- Check if we switched to a brand new target
            if currentTarget ~= targetHead then
                currentTarget = targetHead
                -- Roll the 80% chance ONCE for this specific player engagement
                shouldHitCurrentTarget = (math.random(1, 100) <= HIT_CHANCE)
            end
            
            -- Lock logic based on the single roll result
            if shouldHitCurrentTarget then
                -- 80% Case: Flawless hard lock directly on the center of the head
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            else
                -- 20% Case: Intentionally aims slightly above the head to simulate a natural miss
                local missOffset = Vector3.new(0, 2.5, 0)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position + missOffset)
            end
        else
            currentTarget = nil
        end
    end
end)
