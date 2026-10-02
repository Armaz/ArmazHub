local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local ACCURACY_RATE = 0.80 -- Strict 80% hit accuracy decimal threshold

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
            tool:Activate() -- Activates weapon internally bypassing mechanical driver layers
        end
    end
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

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local targetHead = getClosestPlayerHead()
        
        if targetHead then
            -- 1. FLAWLESS 100% CONTINUOUS CAMERA HARD LOCK ON (Glued tracking)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            
            -- 2. 80% ACCURACY AUTOFIT TRIGGERBOT ENGINE
            -- Calculates a probability threshold against the 0.80 configuration marker
            if math.random() <= ACCURACY_RATE then
                -- 80% Case: Engine passes activation command to fire weapon tool
                fireEquippedTool()
            end
        end
    end
end)
