local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Helper function to find a player from a hit character part
local function getPlayerFromTarget(targetPart)
    if not targetPart or not targetPart.Parent then return nil end
    
    -- Check if the part is directly inside a character model
    local player = Players:GetPlayerFromCharacter(targetPart.Parent)
    if player then return player end
    
    -- Check if the part is inside a deeper sub-model (like accessories)
    if targetPart.Parent.Parent then
        player = Players:GetPlayerFromCharacter(targetPart.Parent.Parent)
        if player then return player end
    end
    
    return nil
end

-- This runs every frame automatically
RunService.RenderStepped:Connect(function()
    -- Ensure your own character is alive
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
        
        -- Get whatever object is directly under the cursor
        local targetPart = Mouse.Target
        if targetPart then
            local targetPlayer = getPlayerFromTarget(targetPart)
            
            -- If the cursor is touching a player, and it's not you
            if targetPlayer and targetPlayer ~= LocalPlayer then
                local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
                
                -- Ensure the target is actually alive
                if humanoid and humanoid.Health > 0 then
                    
                    -- DYNAMIC TEAM CHECK
                    local shouldFire = true
                    if areTeamsActive() then
                        -- If teams exist, only fire if they are on a different team
                        if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
                            shouldFire = false
                        end
                    end
                    
                    -- If they passed the team/neutral check, simulate a mouse click
                    if shouldFire then
                        -- ClickButton1 simulates a primary mouse press down at screen position (0,0)
                        VirtualUser:Button1Down(Vector2.new(0, 0))
                        
                        -- Optional short delay can be placed here if needed, 
                        -- but releasing right away allows rapid automatic fire.
                        VirtualUser:Button1Up(Vector2.new(0, 0))
                    end
                end
            end
        end
    end
end)
