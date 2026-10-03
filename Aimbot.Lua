local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- State variables to keep the target consistent while active
local lockedPlayer = nil
local lockedPartName = nil -- "Head" or "HumanoidRootPart"
local lockedOffset = Vector3.new(0, 0, 0)

-- Toggle state for the F key
local isLockedOn = false

-- Listen for the F key press to toggle the lock on/off
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        isLockedOn = not isLockedOn
        if not isLockedOn then
            lockedPlayer = nil
            lockedPartName = nil
        end
    end
end)

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Visibility / Line of sight check using Raycasting
local function isVisible(targetPart, targetCharacter)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    -- Exclude local player from raycast collision checking
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        -- If the ray hits a part belonging to the target character, they are visible
        if result.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        return false
    end
    
    -- If nothing was hit between camera and target, it's clear
    return true
end

local function getClosestTargetPosition()
    local targetPosition = nil
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
                local character = player.Character
                local head = character:FindFirstChild("Head")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if head and rootPart and humanoid and humanoid.Health > 0 then
                    -- If we are already locked onto this player, maintain their part choice
                    local testPart = head
                    if lockedPlayer == player and lockedPartName then
                        testPart = character:FindFirstChild(lockedPartName) or head
                    end
                    
                    -- WALL / VISIBILITY CHECK: Ensure target has a clear line of sight
                    if isVisible(testPart, character) then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (localChar.HumanoidRootPart.Position - testPart.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                
                                -- If switching or locking onto a new player, assign 50/50 head vs body and random offset
                                if lockedPlayer ~= player then
                                    lockedPlayer = player
                                    lockedPartName = (math.random() < 0.5) and "Head" or "HumanoidRootPart"
                                    
                                    -- Minor random variance around the part so it doesn't pixel-lock dead center
                                    lockedOffset = Vector3.new(
                                        math.random(-30, 30) / 100,
                                        math.random(-30, 30) / 100,
                                        math.random(-30, 30) / 100
                                    )
                                end
                                
                                local finalPart = character:FindFirstChild(lockedPartName)
                                if finalPart then
                                    targetPosition = finalPart.Position + lockedOffset
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Clear target state if no valid player is found
    if not targetPosition then
        lockedPlayer = nil
        lockedPartName = nil
    end
    
    return targetPosition
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function(dt)
    -- Only run if the toggle is active (F has been pressed)
    if isLockedOn then
        if LocalPlayer.Character then
            local targetPos = getClosestTargetPosition()
            
            if targetPos then
                -- Smoothly turn toward the target using CFrame.lerp (change '15' to speed up or slow down turning)
                local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(15 * dt, 0, 1))
            end
        end
    else
        -- Reset lock state when toggled off
        lockedPlayer = nil
        lockedPartName = nil
    end
end)
