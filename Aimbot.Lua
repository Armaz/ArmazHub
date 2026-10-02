local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local HIT_CHANCE = 0.80 -- Direct 80% accuracy representation
local TICK_RATE = 0.1   -- Checks every 0.1 seconds whether to lock on or off

-- State variables for the timer logic
local isLockActive = true
local lastTickTime = 0

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
            -- TIMER CHECK: Has 0.1 seconds passed since the last roll?
            local currentTime = os.clock()
            if currentTime - lastTickTime >= TICK_RATE then
                lastTickTime = currentTime
                -- Roll an independent 80% accuracy chance for this 0.1s window
                isLockActive = (math.random() <= HIT_CHANCE)
            end
            
            -- If the 80% active state roll passes, lock onto the head instantly. 
            -- If it lands on the 20% failure state, it drops the lock, letting you move naturally.
            if isLockActive then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            end
        else
            -- Reset state if no target is near
            lastTickTime = 0
            isLockActive = true
        end
    end
end)
