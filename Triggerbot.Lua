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

-- Helper function to find and programmatically fire the currently equipped weapon tool
local function fireEquippedTool()
    local character = LocalPlayer.Character
    if character then
        -- Roblox weapons are "Tool" classes equipped inside the character model
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            -- Bypass mouse simulation and directly force the tool to activate in engine
            tool:Activate() 
        end
    end
end

-- Pre-allocated raycast parameters for maximum performance (native wallcheck)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    -- Dynamic screen centering calculation
    local viewportSize = Camera.ViewportSize
    local unitRay = Camera:ScreenPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
    
    -- Update character to ignore dynamically
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
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
                
                -- DIRECT ENGINE ACTIVATION (No delay, skips mouse emulation)
                if shouldFire then
                    fireEquippedTool()
                end
            end
        end
    end
end)
