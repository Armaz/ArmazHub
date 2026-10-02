local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local HIT_CHANCE = 0.80 -- Direct 80% decimal value representation

-- Engagement trackers
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
            -- Evaluate target locking states based on engagement persistence
            if currentTarget ~= targetHead then
                currentTarget = targetHead
                -- Calculates probability against the 0.80 value directly
                shouldHitCurrentTarget = (math.random() <= HIT_CHANCE)
            end
            
            if shouldHitCurrentTarget then
                -- 80% Hit Case: Perfect central lock
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            else
                -- 20% Miss Case: Offset orientation targeting overhead positioning space
                local missOffset = Vector3.new(0, 2.5, 0)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position + missOffset)
            end
        else
            currentTarget = nil
        end
    end
end)
