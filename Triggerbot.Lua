local Players = game:GetService("Players")
local RunService = service or game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Safely fires or releases the equipped tool
local function setToolActive(state)
    local character = LocalPlayer.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            if state then
                tool:Activate()
            else
                -- Tools automatically handle release or stop firing on deactivation hooks, 
                -- but we can let go or stop interacting depending on the custom tool implementation.
            end
        end
    end
end

-- Checks if the mouse is hovering over a valid target's body part
local function isCursorOverValidTarget()
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Target
    
    if not target or not target.Parent then
        return false
    end
    
    local characterHit = target.Parent
    -- Handle models where body parts might be nested deeper (e.g., accessories or custom characters)
    local playerHit = Players:GetPlayerFromCharacter(characterHit) or Players:GetPlayerFromCharacter(characterHit.Parent)
    
    if not playerHit or playerHit == LocalPlayer then
        return false
    end
    
    local humanoid = characterHit:FindFirstChildOfClass("Humanoid") or characterHit.Parent:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    -- DYNAMIC TEAM CHECK
    local teamsExist = areTeamsActive()
    if teamsExist then
        -- Check if target is on your team
        if LocalPlayer.Team and playerHit.Team and LocalPlayer.Team == playerHit.Team then
            return false
        end
        
        -- EXCLUSION CHECK: Ignore players on teams named "Lobby" or "Neutral"
        if playerHit.Team then
            local teamName = playerHit.Team.Name
            if teamName == "Lobby" or teamName == "Neutral" then
                return false
            end
        end
    end
    
    return true
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        if isCursorOverValidTarget() then
            -- Cursor is on a valid enemy body part; trigger the weapon
            setToolActive(true)
        else
            -- Cursor is not on a valid target; release/stop firing action
            setToolActive(false)
        end
    end
end)
