local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Input simulator setup
local VirtualInputManager = game:GetService("VirtualInputManager")
local isFiring = false

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Fast player lookup from hit part
local function getPlayerFromTarget(targetPart)
    if not targetPart or not targetPart.Parent then return nil end
    local player = Players:GetPlayerFromCharacter(targetPart.Parent)
    if player then return player end
    if targetPart.Parent.Parent then
        player = Players:GetPlayerFromCharacter(targetPart.Parent.Parent)
        if player then return player end
    end
    return nil
end

-- Completely safe firing mechanics utilizing hardware level hooks
local function startFiring()
    if not isFiring then
        isFiring = true
        -- Sends a direct hardware-level press down at the center of the screen
        local center = Camera.ViewportSize / 2
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    end
end

local function stopFiring()
    if isFiring then
        isFiring = false
        -- Safely releases the hardware-level click
        local center = Camera.ViewportSize / 2
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end
end

-- Pre-allocated raycast parameters for maximum performance (native wallcheck)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or GuiService:GetOpenedPriorityGui() then 
        stopFiring()
        return 
    end
    
    -- Ensure you are holding a tool before even trying to fire
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then 
        stopFiring()
        return 
    end
    
    -- Dynamic screen centering calculation
    local viewportSize = Camera.ViewportSize
    local unitRay = Camera:ScreenPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Update characters to ignore dynamically
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, tool}
    
    -- Raycast captures the absolute first solid physical asset hit (native wallcheck)
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 5000, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        local targetPlayer = getPlayerFromTarget(raycastResult.Instance)
        
        if targetPlayer and targetPlayer ~= LocalPlayer then
            local character = targetPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                -- DYNAMIC TEAM CHECK
                local shouldFire = true
                if areTeamsActive() then
                    if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
                        shouldFire = false
                    end
                end
                
                -- HARDWARE FIRE SIMULATION
                if shouldFire then
                    startFiring()
                else
                    stopFiring()
                end
            else
                stopFiring()
            end
        else
            stopFiring()
        end
    else
        stopFiring()
    end
end)
