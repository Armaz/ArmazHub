local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- State variables to keep the target consistent while holding RMB
local lockedPlayer = nil
local lockedPartName = nil
local lockedOffset = Vector3.new(0, 0, 0)
local isAccurateTarget = true -- Controls the 93% hit accuracy chance

-- Helper function to determine if teams are active
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Line of sight check using Raycasting
local function isVisible(targetPart, targetCharacter)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        if result.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        return false
    end
    
    return true
end

local function getClosestTargetPosition()
    local targetPosition = nil
    local shortestDistance = math.huge
    local teamsExist = areTeamsActive()
    
    -- If we already have a locked player, prioritize checking them first
    if lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild("Humanoid") and lockedPlayer.Character.Humanoid.Health > 0 then
        -- If this target failed the 93% accuracy roll, don't provide aim assist for them
        if not isAccurateTarget then
            return nil
        end
        
        local character = lockedPlayer.Character
        local testPart = character:FindFirstChild(lockedPartName) or character:FindFirstChild("Head")
        
        if testPart and isVisible(testPart, character) then
            local localChar = LocalPlayer.Character
            if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                local finalPart = character:FindFirstChild(lockedPartName)
                if finalPart then
                    return finalPart.Position + lockedOffset
                end
            end
        end
    end
    
    -- Otherwise, find the closest valid target
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local shouldTarget = true
            if teamsExist then
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
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
                    if isVisible(head, character) then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (localChar.HumanoidRootPart.Position - head.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                
                                if lockedPlayer ~= player then
                                    lockedPlayer = player
                                    lockedPartName = (math.random() < 0.5) and "Head" or "HumanoidRootPart"
                                    
                                    -- 93% chance (93 out of 100 shots) to enable tracking for this target lock
                                    isAccurateTarget = (math.random() < 0.93)
                                    
                                    lockedOffset = Vector3.new(
                                        math.random(-30, 30) / 100,
                                        math.random(-30, 30) / 100,
                                        math.random(-30, 30) / 100
                                    )
                                end
                                
                                -- Only assign target position if it passed the 93% accuracy check
                                if isAccurateTarget then
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
    end
    
    if not targetPosition then
        lockedPlayer = nil
        lockedPartName = nil
    end
    
    return targetPosition
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function(dt)
    -- Only run the aimbot while holding down the Right Mouse Button (RMB)
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if LocalPlayer.Character then
            local targetPos = getClosestTargetPosition()
            
            if targetPos then
                local currentPos = Camera.CFrame.Position
                local goalCFrame = CFrame.new(currentPos, targetPos)
                
                -- Smooth turning glide using a slower Lerp speed (7)
                Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, math.clamp(7 * dt, 0, 1))
            end
        end
    else
        -- Reset lock state immediately when RMB is released
        lockedPlayer = nil
        lockedPartName = nil
    end
end)
