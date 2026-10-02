local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Firing state tracker to prevent executor input buffer flooding
local isCurrentlyFiring = false

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Ultra-fast player lookup from hit part
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

-- Safety function to release the trigger instantly
local function forceStopFiring()
    if isCurrentlyFiring then
        isCurrentlyFiring = false
        if mouse1release then
            mouse1release()
        elseif releasemouse1 then
            releasemouse1()
        end
    end
end

-- Pre-allocated raycast parameters for peak frame performance
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
        forceStopFiring()
        return
    end
    
    -- Calculate precise center of screen ray
    local viewportSize = Camera.ViewportSize
    local unitRay = Camera:ScreenPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Dynamically update exclusion filter to ignore yourself
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    -- Execute instantaneous wall-check raycast (Stops at the first solid physical object)
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 5000, raycastParams)
    
    if raycastResult and raycastResult.Instance then
        local targetPlayer = getPlayerFromTarget(raycastResult.Instance)
        
        -- Validate target constraints
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
                
                -- INSTANT TRIGGER TOGGLE LOGIC
                if shouldFire then
                    if not isCurrentlyFiring then
                        isCurrentlyFiring = true
                        if mouse1press then
                            mouse1press() -- Instantly holds down left click without spamming the engine
                        elseif pressmouse1 then
                            pressmouse1()
                        end
                    end
                else
                    forceStopFiring()
                end
            else
                forceStopFiring()
            end
        else
            forceStopFiring()
        end
    else
        forceStopFiring()
    end
end)
