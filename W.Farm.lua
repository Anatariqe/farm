--[[
    ARA ULTIMATE LOADER v2.3 (ANTI-SPIN + PHYSICS FREEZE)
    Architect: Ара
    Status: PRODUCTION / AUTOEXEC READY
    
    Changelog:
    - [FIX] Donate: Полная блокировка вращения (Anti-Spin). Персонаж всегда лежит.
    - [FIX] Donate: Добавлен BodyAngularVelocity для фиксации углов.
    - [FIX] Donate: Принудительный PlatformStand в каждом кадре.
]]

-- ==============================================================================
-- [BLOCK 0] AUTOEXEC SAFETY CHECK (ПРОВЕРКА ИГРЫ)
-- ==============================================================================
local TargetGames = {
    [15698518307] = true,      -- Rate My Avatar / Booth Game
    [87177901578723] = true    -- Pls Donate (Fake/Modded ID)
}

if not TargetGames[game.PlaceId] then
    print("Ара Loader: Not a target game ("..game.PlaceId.."). Sleeping...")
    return -- СКРИПТ ОСТАНАВЛИВАЕТСЯ ЗДЕСЬ, ЕСЛИ ИГРА НЕ В СПИСКЕ
end

-- ==============================================================================
-- [BLOCK 1] IRON GUARD & ANTI-AFK (ЗАЩИТА ОТ ОШИБОК И ВЫЛЕТОВ)
-- ==============================================================================
task.spawn(function()
    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    local VirtualUser = game:GetService("VirtualUser")
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")

    -- 1. Anti-AFK
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)

    -- 2. Error Handling
    local function EmergencyRejoin()
        warn("Ара Guard: Critical Connection Error! Rejoining...")
        local sfUrl = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
        local s, r = pcall(function() return game:HttpGet(sfUrl) end)
        if s then
            local d = game:GetService("HttpService"):JSONDecode(r)
            if d and d.data then
                local srv = d.data[math.random(1, #d.data)]
                if srv and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, Players.LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end

    GuiService.ErrorMessageChanged:Connect(function()
        local msg = GuiService:GetErrorMessage()
        if msg and msg ~= "" then
            local lowerMsg = msg:lower()
            if lowerMsg:find("disconnect") or lowerMsg:find("kick") or lowerMsg:find("check your internet") then
                EmergencyRejoin()
            end
        end
    end)

    TeleportService.TeleportInitFailed:Connect(function()
        task.wait(2)
        EmergencyRejoin()
    end)
    
    task.spawn(function()
        while true do
            task.wait(5)
            local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
            if prompt then
                local overlay = prompt:FindFirstChild("promptOverlay")
                if overlay and #overlay:GetChildren() > 0 then
                    if overlay:FindFirstChild("ErrorPrompt") then
                        EmergencyRejoin()
                    end
                end
            end
        end
    end)
end)

-- ==============================================================================
-- [BLOCK 2] WATCHDOG (8 SECONDS FAILSAFE)
-- ==============================================================================
_G.LoadedSuccess = false
local GlobalTeleportService = game:GetService("TeleportService")
local GlobalPlaceId = game.PlaceId

task.spawn(function()
    local startTime = tick()
    while tick() - startTime < 8 do 
        if _G.LoadedSuccess then return end
        task.wait(0.5)
    end
    if not _G.LoadedSuccess then
        warn("Ара: !!! EMERGENCY !!! Script logic froze. Force Reloading...")
        GlobalTeleportService:Teleport(GlobalPlaceId, game.Players.LocalPlayer)
    end
end)

-- ==============================================================================
-- [BLOCK 3] MAIN LOGIC
-- ==============================================================================

local PlaceId = game.PlaceId
local HttpService = game:GetService("HttpService")
print("Ара: Environment Safe. Initializing Logic for PlaceID: " .. PlaceId)

-- === GAME 1: RATE (ID: 15698518307) ===
if PlaceId == 15698518307 then
    task.spawn(function()
        _G.LoadedSuccess = true
        print("Ара: Rate Logic Started.")
        
        local nextGameId = 87177901578723 
        
        if not game:IsLoaded() then game.Loaded:Wait() end
        local Player = game.Players.LocalPlayer
        Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

        local Character = Player.Character or Player.CharacterAdded:Wait()
        local Humanoid = Character:WaitForChild("Humanoid")
        local Root = Character:WaitForChild("HumanoidRootPart")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TeleportService = game:GetService("TeleportService")
        local CoreGui = game:GetService("CoreGui")
        local RunService = game:GetService("RunService")

        local running = false
        local usedPositions = {}
        local lastAction = tick()

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(0, 0, 0)
        bv.Parent = Root

        local function setLaying(state)
            if state then
                Humanoid.PlatformStand = true
                Root.CFrame = Root.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
            else
                Humanoid.PlatformStand = false
            end
        end

        local noclipLoop
        local function toggleNoclip(state)
            if state then
                noclipLoop = RunService.Stepped:Connect(function()
                    if Character then
                        for _, part in pairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            else
                if noclipLoop then noclipLoop:Disconnect() end
            end
        end

        local function fireAllRemotes()
            local rems = ReplicatedStorage:FindFirstChild("Remotes")
            if rems then
                for _, r in pairs(rems:GetChildren()) do
                    if r:IsA("RemoteEvent") then
                        task.spawn(function() r:FireServer() end)
                    end
                end
            end
        end

        local folderName = "MegaFarm_Data"
        local dataFile = folderName.."/ServerStats.json"
        if not isfolder(folderName) then makefolder(folderName) end

        local function getData()
            if isfile(dataFile) then
                local s, res = pcall(function() return HttpService:JSONDecode(readfile(dataFile)) end)
                if s then return res end
            end
            return {visits = {}, cycleCount = 1}
        end

        local function saveData(data)
            pcall(function() writefile(dataFile, HttpService:JSONEncode(data)) end)
        end

        local function serverHop()
            running = false
            if StatusLabel then StatusLabel.Text = "Hiding in Sky..." end
            toggleNoclip(true)
            setLaying(false)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            if Root then Root.CFrame = CFrame.new(Root.Position.X, 3500, Root.Position.Z) end
            task.wait(1)
            
            local data = getData()
            local foundServer = false
            local sfUrl = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
            local success, result = pcall(function() return game:HttpGet(sfUrl) end)
            
            if success then
                local decoded = HttpService:JSONDecode(result)
                if decoded and decoded.data then
                    local servers = decoded.data
                    for i = #servers, 2, -1 do
                        local j = math.random(i)
                        servers[i], servers[j] = servers[j], servers[i]
                    end
                    for _, server in pairs(servers) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers and server.playing >= 16 then
                            if not data.visits[server.id] then
                                data.visits[server.id] = true
                                saveData(data)
                                if StatusLabel then StatusLabel.Text = "Joining 16+ Server..." end
                                foundServer = true
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
                                return 
                            end
                        end
                    end
                end
            end
            
            if not foundServer then
                if (data.cycleCount or 1) < 3 then
                    data.visits = {}
                    data.cycleCount = (data.cycleCount or 1) + 1
                    saveData(data)
                    task.wait(1)
                    serverHop()
                else
                    data.visits = {}
                    data.cycleCount = 1
                    saveData(data)
                    TeleportService:Teleport(nextGameId)
                end
            end
        end

        if CoreGui:FindFirstChild("BruteFarmMega") then CoreGui.BruteFarmMega:Destroy() end
        local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "BruteFarmMega"
        local Main = Instance.new("Frame", ScreenGui)
        Main.Name = "Main"; Main.Size = UDim2.new(0, 300, 0, 250); Main.Position = UDim2.new(1, -310, 0.5, -125)
        Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.Active = true; Main.Draggable = true
        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)

        local CounterLabel = Instance.new("TextLabel", Main);
        CounterLabel.Size = UDim2.new(1, 0, 0, 30)
        CounterLabel.Position = UDim2.new(0,0,0,10); CounterLabel.TextSize = 18; CounterLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
        CounterLabel.BackgroundTransparency = 1; CounterLabel.Font = "GothamBold";
        CounterLabel.Text = "BOOTHS: [0 / 0]"

        StatusLabel = Instance.new("TextLabel", Main); StatusLabel.Name = "StatusLabel"; StatusLabel.Size = UDim2.new(1, 0, 0, 40)
        StatusLabel.Position = UDim2.new(0,0,0,40);
        StatusLabel.TextSize = 25; StatusLabel.TextColor3 = Color3.new(1,1,1)
        StatusLabel.BackgroundTransparency = 1; StatusLabel.Font = "GothamBold";
        StatusLabel.Text = "Farming"

        local function createBtn(txt, yPos, color, func)
            local b = Instance.new("TextButton", Main);
            b.Size = UDim2.new(0.8, 0, 0, 45); b.Position = UDim2.new(0.1, 0, 0, yPos)
            b.Text = txt;
            b.BackgroundColor3 = color; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 20
            Instance.new("UICorner", b);
            b.MouseButton1Click:Connect(func)
        end

        createBtn("START", 100, Color3.fromRGB(0, 160, 70), function() running = true; toggleNoclip(true); setLaying(true); StatusLabel.Text = "Farming"; lastAction = tick() end)
        createBtn("STOP", 160, Color3.fromRGB(180, 0, 0), function() running = false; toggleNoclip(false); setLaying(false); bv.MaxForce = Vector3.new(0,0,0); StatusLabel.Text = "Stopped" end)

        task.spawn(function()
            task.wait(2)
            running = true
            toggleNoclip(true)
            setLaying(true)
            lastAction = tick()
            while true do
                if running then
                    if tick() - lastAction > 15 then serverHop() break end
                    local availableTargets = {}
                    local allBooths = 0
                    pcall(function()
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("TextLabel") and v.Text:lower():find("no one") then
                                local model = v:FindFirstAncestorOfClass("Model")
                                if model and model:FindFirstChildWhichIsA("ProximityPrompt", true) then
                                    allBooths = allBooths + 1
                                    local pos = model:GetModelCFrame().Position
                                    local alreadyUsed = false
                                    for _, up in pairs(usedPositions) do
                                        if (up - pos).Magnitude < 7 then alreadyUsed = true; break end
                                    end
                                    if not alreadyUsed then table.insert(availableTargets, model) end
                                end
                            end
                        end
                    end)

                    CounterLabel.Text = "BOOTHS: ["..#usedPositions.." / "..allBooths.."]"

                    if #availableTargets > 0 then
                        local target = availableTargets[math.random(1, #availableTargets)]
                        table.insert(usedPositions, target:GetModelCFrame().Position)
                        if Character and Root then
                            bv.MaxForce = Vector3.new(4500, 4500, 4500)
                            Root.CFrame = (target:GetModelCFrame() * CFrame.new(0,-8,0)) * CFrame.Angles(math.rad(-90), 0, 0)
                            task.wait(0.25)
                            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                fireproximityprompt(prompt)
                                task.wait(0.2)
                                fireAllRemotes()
                                lastAction = tick()
                            end
                        end
                        task.wait(0.3)
                    else
                        serverHop()
                        break
                    end
                end
                task.wait(0.2)
            end
        end)
    end)

-- === GAME 2: DONATE (ID: 87177901578723) ===
elseif PlaceId == 87177901578723 then
    task.spawn(function()
        print("Ара: Donate Logic Started (Anti-Spin + Deep Search).")
        
        local s, err = pcall(function()
            local nextGameId = 15698518307        
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local TeleportService = game:GetService("TeleportService")
            local CoreGui = game:GetService("CoreGui")
            local RunService = game:GetService("RunService")

            if not game:IsLoaded() then game.Loaded:Wait() end
            
            local Player = Players.LocalPlayer
            Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam

            local Character = Player.Character or Player.CharacterAdded:Wait()
            local Root = Character:WaitForChild("HumanoidRootPart")
            local Humanoid = Character:WaitForChild("Humanoid")
            
            _G.LoadedSuccess = true 

            local running = true
            local usedPositions = {} 
            local lastAction = tick() 
            local boothsClaimed = 0 
            local totalBoothsFound = 0 
            
            local UnclaimRemote = ReplicatedStorage:WaitForChild("Events", 10)
            if UnclaimRemote then UnclaimRemote = UnclaimRemote:WaitForChild("Unclaim", 5) end

            local function toggleNoclip(state)
                if _G.NoclipLink then _G.NoclipLink:Disconnect() end
                if state then
                    _G.NoclipLink = RunService.Stepped:Connect(function()
                        if not Character then return end
                        for _, part in ipairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end 
                        end
                    end)
                end
            end
            
            -- === PHYSICS LOCK ===
            local function lockPhysics()
                if Root then
                    -- Linear Lock
                    local bv = Root:FindFirstChild("LockVelocity") or Instance.new("BodyVelocity", Root)
                    bv.Name = "LockVelocity"
                    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bv.Velocity = Vector3.new(0,0,0) -- Freeze Position
                    
                    -- Angular Lock (NO SPIN)
                    local bav = Root:FindFirstChild("LockSpin") or Instance.new("BodyAngularVelocity", Root)
                    bav.Name = "LockSpin"
                    bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9) -- Infinite torque
                    bav.AngularVelocity = Vector3.new(0,0,0) -- Freeze Rotation
                    
                    -- Reset Physics
                    Root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    Root.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end
                if Humanoid then
                    Humanoid.PlatformStand = true -- Force Ragdoll/Laying
                end
            end
            
            local function serverHop()
                running = false
                if StatusLabel then StatusLabel.Text = "Initiating Skybox..." end
                
                toggleNoclip(true)
                lockPhysics() -- Freeze in place first
                if Root then
                    Root.CFrame = CFrame.new(Root.Position.X, 3500, Root.Position.Z)
                end
                task.wait(1)

                local cursor = ""
                local found = false
                
                -- Deep Search 5 Pages
                for i = 1, 5 do
                    if StatusLabel then StatusLabel.Text = "Scanning Page " .. i .. "..." end
                    local sfUrl = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
                    if cursor ~= "" then sfUrl = sfUrl .. "&cursor=" .. cursor end

                    local success, result = pcall(function() return game:HttpGet(sfUrl) end)
                    if success then
                        local decoded = HttpService:JSONDecode(result)
                        if decoded then
                            if decoded.data then
                                local servers = decoded.data
                                math.randomseed(tick())
                                for k = #servers, 2, -1 do
                                    local j = math.random(k)
                                    servers[k], servers[j] = servers[j], servers[k]
                                end
                                for _, v in ipairs(servers) do 
                                    if v.id ~= game.JobId and v.playing < v.maxPlayers - 1 and v.playing >= 10 then 
                                        found = true
                                        if StatusLabel then StatusLabel.Text = "Target Found! Joining..." end
                                        TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, Player) 
                                        return 
                                    end
                                end
                            end
                            if decoded.nextPageCursor and decoded.nextPageCursor ~= "null" then
                                cursor = decoded.nextPageCursor
                            else
                                break
                            end
                        end
                    end
                    task.wait(0.5)
                end
                
                if not found then
                    if StatusLabel then StatusLabel.Text = "All Full -> Next Game" end
                    task.wait(1)
                    TeleportService:Teleport(nextGameId, Player)
                end
            end

            if CoreGui:FindFirstChild("FarmGui") then CoreGui.FarmGui:Destroy() end 
            local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "FarmGui" 
            local MainFrame = Instance.new("Frame", ScreenGui)
            MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); MainFrame.Position = UDim2.new(1, -210, 0.5, -70) 
            MainFrame.Size = UDim2.new(0, 200, 0, 140); MainFrame.Active = true; MainFrame.Draggable = true 
            Instance.new("UICorner", MainFrame) 

            local CounterLabel = Instance.new("TextLabel", MainFrame)
            CounterLabel.Size = UDim2.new(1, 0, 0, 35); CounterLabel.BackgroundTransparency = 1; CounterLabel.TextColor3 = Color3.new(1, 1, 1) 
            CounterLabel.TextSize = 18; CounterLabel.Text = "booth : 0/0"; CounterLabel.Font = Enum.Font.GothamBold

            StatusLabel = Instance.new("TextLabel", MainFrame); StatusLabel.Position = UDim2.new(0, 0, 0, 30) 
            StatusLabel.Size = UDim2.new(1, 0, 0, 20); StatusLabel.BackgroundTransparency = 1
            StatusLabel.Text = "Status: Active"; StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            StatusLabel.TextSize = 13; StatusLabel.Font = Enum.Font.Gotham

            local function countAvailableBooths()
                local count = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Text:upper():find("UNCLAIMED") then count = count + 1 end
                end
                return count
            end

            -- Init Physics Lock
            lockPhysics()

            task.spawn(function()
                while true do
                    if running then
                        if not Character or not Character.Parent then
                             Character = Player.Character or Player.CharacterAdded:Wait()
                             Root = Character:WaitForChild("HumanoidRootPart")
                             Humanoid = Character:WaitForChild("Humanoid")
                        end

                        -- RE-APPLY LOCKS EVERY FRAME
                        lockPhysics()
                        toggleNoclip(true)

                        totalBoothsFound = countAvailableBooths() 
                        CounterLabel.Text = "booth : " .. boothsClaimed .. "/" .. totalBoothsFound 
                        
                        if (totalBoothsFound > 0 and boothsClaimed >= totalBoothsFound) or (tick() - lastAction > 15) then 
                            serverHop() 
                            return
                        end
                        
                        local target = nil
                        for _, v in ipairs(workspace:GetDescendants()) do 
                            if v:IsA("TextLabel") and v.Text:upper():find("UNCLAIMED") then 
                                local model = v:FindFirstAncestorOfClass("Model")
                                if model then
                                    local pos = model:GetModelCFrame().Position
                                    local used = false
                                    for _, p in ipairs(usedPositions) do 
                                        if (p - pos).Magnitude < 5 then used = true break end 
                                    end
                                    if not used then target = model break end 
                                end
                            end
                        end

                        if target and Root then
                            local targetPos = target:GetModelCFrame()
                            table.insert(usedPositions, targetPos.Position) 
                            -- Force horizontal orientation
                            Root.CFrame = (targetPos * CFrame.new(0, -8, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                            
                            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true) 
                            if prompt then
                                task.wait(0.1)
                                fireproximityprompt(prompt) 
                                task.wait(0.1)
                                if UnclaimRemote then UnclaimRemote:FireServer() end
                                boothsClaimed = boothsClaimed + 1 
                                lastAction = tick() 
                            end
                        else
                            if tick() - lastAction > 5 then serverHop() end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end)
        
        if not s then
            warn("Donate Logic Crashed: " .. tostring(err))
            task.wait(1)
            game:GetService("TeleportService"):Teleport(15698518307)
        end
    end)
end