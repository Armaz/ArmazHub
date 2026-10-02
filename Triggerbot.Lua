local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Hardware simulation service

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local ACCURACY_RATE = 0.80 -- Strict 80% hit accuracy decimal threshold

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- BYPASS TRIGGER: Simulates a physical hardware mouse click at the center of the screen
local function fireWeaponBypass()
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    
    -- SendMouseButtonEvent parameters: (X, Y, ButtonType [0 = LeftClick], isDown, gameProcessedEvent, clickCount)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
    task.wait(0.01) -- Microscopic delay to let the engine register the press
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
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

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local targetHead = getClosestPlayerHead()
        
        if targetHead then
            -- 1. FLAWLESS 100% CONTINUOUS CAMERA HARD LOCK ON (Glued tracking)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            
            -- 2. 80% ACCURACY AUTOFIT TRIGGERBOT ENGINE
            if math.random() <= ACCURACY_RATE then
                -- 80% Case: Call the hardware bypass fire method
                task.spawn(fireWeaponBypass)
            end
        end
    end
end)
