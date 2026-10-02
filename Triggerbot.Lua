local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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

-- Pre-allocated raycast parameters for maximum performance (no delay frame allocations)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    -- Dynamic screen centering calculation
    local viewportSize = Camera.ViewportSize
    local unitRay = Camera:ScreenPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Update characters to ignore dynamically
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
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
                
                -- INSTANT MAXIMUM CLICK SPAM (Zero delays)
                if shouldFire and mouse1click then
                    mouse1click()
                end
            end
        end
    end
end)
