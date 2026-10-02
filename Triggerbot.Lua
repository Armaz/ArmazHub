local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Track firing state to prevent rapid unequip glitches
local isFiring = false

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Helper function to find a player from a hit part
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

-- Stop firing safely
local function stopFiring()
    if isFiring then
        isFiring = false
        if mouse1release then
            mouse1release()
        end
    end
end

-- This runs every frame automatically
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
        
        -- SCREEN CENTER RAYCAST (Detects exactly what you are aiming at)
        local viewportSize = Camera.ViewportSize
        local centerScreen = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        local unitRay = Camera:ScreenPointToRay(centerScreen.X, centerScreen.Y)
        
        -- WALL CHECK & SELF EXCLUSION
        -- The raycast natively handles wall checks because it hits the FIRST solid object in its path.
        -- If a wall is in front of the player, the raycast hits the wall instead of the player model.
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.IgnoreWater = true
        
        local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, raycastParams)
        
        if raycastResult and raycastResult.Instance then
            local targetPart = raycastResult.Instance
            local targetPlayer = getPlayerFromTarget(targetPart)
            
            -- If aiming at a player who is alive and isn't you
            if targetPlayer and targetPlayer ~= LocalPlayer then
                local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    
                    -- DYNAMIC TEAM CHECK
                    local shouldFire = true
                    if areTeamsActive() then
                        if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
                            shouldFire = false
                        end
                    end
                    
                    -- AUTOMATIC HOLD-TO-FIRE LOGIC
                    if shouldFire then
                        if not isFiring then
                            isFiring = true
                            if mouse1press then
                                mouse1press() -- Holds down left click safely
                            end
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
        else
            stopFiring()
        end
    else
        stopFiring()
    end
end)
