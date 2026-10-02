local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local FIRE_RATE_DELAY = 0.03 -- Small buffer to prevent the game engine from breaking/unequipping your tool
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

-- Safely activates the tool using an isolated thread buffer
local function safeFireTool(tool)
    if isFiring then return end
    isFiring = true
    
    -- Fire the tool natively in the engine
    tool:Activate()
    
    -- Give the gun script a microscopic moment to register the shot before the next input
    task.wait(FIRE_RATE_DELAY)
    isFiring = false
end

-- Pre-allocated raycast parameters for maximum performance (native wallcheck)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    -- Find currently equipped tool
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end -- If no gun is equipped, do nothing
    
    -- Dynamic screen centering calculation
    local viewportSize = Camera.ViewportSize
    local unitRay = Camera:ScreenPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Update character to ignore dynamically
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, tool}
    
    -- Execute instantaneous wall-check raycast (Stops at the first solid physical object)
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
                
                -- EXECUTE CONTROLLED ENGINE ACTIVATION
                if shouldFire then
                    task.spawn(safeFireTool, tool)
                end
            end
        end
    end
end)
