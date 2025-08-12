-- Converted Rayfield script (yeah.txt) -> WindUI
-- File: yeah_windui.lua

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Basic UI setup
WindUI:Localization({ Enabled = true, Prefix = "loc:", DefaultLanguage = "en", Translations = { ["en"] = {} } })
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Load string helper (kept from original)
local function safeNotify(opts)
    WindUI:Notify({
        Title = opts.Title or "",
        Content = opts.Content or "",
        Icon = opts.Icon or nil,
        Duration = opts.Duration or 3
    })
end

-- ========== Original script logic preserved (functions, variables, services) ==========
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local originalProperties = {}
local originalSizes = {}
local originalLighting = {}
local ClientBirds = workspace:FindFirstChild("Regions") and workspace.Regions:FindFirstChild("Beakwoods") and workspace.Regions.Beakwoods:FindFirstChild("ClientBirds")

-- Settings
local Settings = {
    AutoFarm = {
        Beakwoods = false,
        Deadlands = false,
        MountBeaks = false,
        QuillLake = false,
        Enabled = false,
        AutoShoot = false,
        BirdDuration = 10,
        MovementSpeed = 25,
        MinDistanceForNewTween = 15,
        YOffset = 3,
        OrbitRadius = 5,
        OrbitSpeed = 0.7,
        ApproachSpeed = 0.9,
        MinDistance = 10,
        CameraSmoothness = 1.5,
        ShootVariance = 0.2,
        ZOffset = 8,
        TweenDuration = 1.5,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
        SmoothAimbot = false,
        FreezeBirds = false
    },
    AutoSell = false,
    SellThreshold = 50,
    AutoDart = false,
    HitboxExpander = false,
    HitboxSize = 15,
    WalkSpeed = 16,
    InfiniteJump = false
}

-- ESP state
local ESPColors = {
    ["Beakwoods"] = Color3.fromRGB(0, 255, 0),
    ["Deadlands"] = Color3.fromRGB(255, 0, 0),
    ["Mount Beaks"] = Color3.fromRGB(0, 0, 255),
    ["Quill Lake"] = Color3.fromRGB(255, 255, 0)
}
local ESPEnabled = false
local ESPObjects = {}

-- CreateESP / RemoveESP
local function RemoveESP(bird)
    local data = ESPObjects[bird]
    if not data then return end
    for _, obj in pairs(data) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    ESPObjects[bird] = nil
end

local function CreateESP(bird, regionName)
    if not bird then return end
    RemoveESP(bird)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = bird
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = ESPColors[regionName] or Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0
    highlight.Parent = bird

    local primary = bird.PrimaryPart or bird:FindFirstChildWhichIsA("BasePart")
    if primary then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = primary
        billboard.Size = UDim2.new(0,200,0,50)
        billboard.StudsOffset = Vector3.new(0,3,0)
        billboard.AlwaysOnTop = true
        billboard.Parent = primary

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "ESP_Text"
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = regionName .. " - " .. bird.Name
        textLabel.TextColor3 = Color3.fromRGB(255,255,255)
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = billboard

        ESPObjects[bird] = {highlight, billboard}
    else
        ESPObjects[bird] = {highlight}
    end
end

-- ToggleESP
local function ToggleESP(state)
    ESPEnabled = state
    if ESPEnabled then
        for _, regionName in pairs({"Beakwoods","Deadlands","Mount Beaks","Quill Lake"}) do
            local region = workspace.Regions:FindFirstChild(regionName)
            if region then
                local clientBirds = region:FindFirstChild("ClientBirds")
                if clientBirds then
                    for _, bird in pairs(clientBirds:GetChildren()) do
                        if bird:IsA("Model") then
                            CreateESP(bird, regionName)
                        end
                    end
                    clientBirds.ChildAdded:Connect(function(bird)
                        if ESPEnabled and bird:IsA("Model") then
                            CreateESP(bird, regionName)
                        end
                    end)
                end
            end
        end
    else
        for bird, _ in pairs(ESPObjects) do
            RemoveESP(bird)
        end
    end
end

-- ExpandHitboxes
local function ExpandHitboxes(enable)
    for _, regionName in pairs({"Beakwoods","Deadlands","Mount Beaks","Quill Lake"}) do
        local region = workspace.Regions:FindFirstChild(regionName)
        if region then
            local clientBirds = region:FindFirstChild("ClientBirds")
            if clientBirds then
                for _, bird in pairs(clientBirds:GetChildren()) do
                    if bird:IsA("Model") then
                        for _, part in pairs(bird:GetDescendants()) do
                            if part:IsA("BasePart") then
                                if enable then
                                    if not originalSizes[part] then
                                        originalSizes[part] = part.Size
                                    end
                                    part.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                                    part.CanCollide = false
                                else
                                    if originalSizes[part] then
                                        part.Size = originalSizes[part]
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- GetRandomBird (region)
local function GetRandomBird(region)
    local clientBirds = workspace.Regions:FindFirstChild(region) and workspace.Regions[region]:FindFirstChild("ClientBirds")
    if not clientBirds then return nil end
    local validBirds = {}
    for _, bird in pairs(clientBirds:GetChildren()) do
        if bird:IsA("Model") then
            local primaryPart = bird.PrimaryPart or bird:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                table.insert(validBirds, bird)
            end
        end
    end
    if #validBirds > 0 then return validBirds[math.random(1,#validBirds)] end
    return nil
end

-- StartAutoFarm
local function StartAutoFarm(region)
    local player = game.Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local tweenService = game:GetService("TweenService")
    local VirtualInputManager = game:GetService("VirtualInputManager")

    local CurrentBird, CurrentTween, LastBirdSwitch = nil, nil, 0
    local originalGravity = workspace.Gravity
    workspace.Gravity = 10

    local clientBirds = workspace.Regions:FindFirstChild(region) and workspace.Regions[region]:FindFirstChild("ClientBirds")
    if not clientBirds then return end

    while Settings.AutoFarm[region:gsub(" ","")] do
        task.wait(0.05)
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local now = os.clock()

            if not CurrentBird or (now - LastBirdSwitch) > Settings.AutoFarm.BirdDuration then
                CurrentBird = GetRandomBird(region)
                LastBirdSwitch = now
                if CurrentTween then CurrentTween:Cancel() end
            end

            if CurrentBird then
                local success, pivot = pcall(function() return CurrentBird:GetPivot() end)
                if success and pivot then
                    local offset = Vector3.new(0,3,8)
                    local targetPos = pivot.Position + offset
                    local targetCFrame = CFrame.new(targetPos, pivot.Position)

                    CurrentTween = tweenService:Create(hrp, TweenInfo.new(Settings.AutoFarm.TweenDuration, Settings.AutoFarm.EasingStyle, Settings.AutoFarm.EasingDirection), {CFrame = targetCFrame})
                    CurrentTween:Play()

                    local followStart = os.clock()
                    while os.clock() - followStart < Settings.AutoFarm.BirdDuration and Settings.AutoFarm[region:gsub(" ","")] do
                        local pivotSuccess, pivotUpdate = pcall(function() return CurrentBird:GetPivot() end)
                        if pivotSuccess then
                            local aimPos = pivotUpdate.Position
                            Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)

                            if Settings.AutoFarm.AutoShoot then
                                local screenPoint = Camera:WorldToViewportPoint(aimPos)
                                local shootX = screenPoint.X + ((math.random() - 0.5) * Settings.AutoFarm.ShootVariance * 50)
                                local shootY = screenPoint.Y + ((math.random() - 0.5) * Settings.AutoFarm.ShootVariance * 30)

                                VirtualInputManager:SendMouseButtonEvent(shootX, shootY, 0, true, game, 1)
                                task.wait(0.02 + math.random() * 0.03)
                                VirtualInputManager:SendMouseButtonEvent(shootX, shootY, 0, false, game, 1)
                            end
                        end
                        task.wait(0.1)
                    end
                end
            end
        end
    end

    if CurrentTween then CurrentTween:Cancel() end
    workspace.Gravity = originalGravity
end

-- Additional utility used later (StartAutoFarmLoop placeholder if referenced)
local function StartAutoFarmLoop()
    -- Kept for compatibility with previous script where RunService.Heartbeat used this
end

-- Teleport birds improved function
local teleportBirdsEnabled = false
local function teleportBirds()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local targetPos = hrp.Position + hrp.CFrame.RightVector * 6 + Vector3.new(0,5,0)
    local regions = workspace:FindFirstChild("Regions")
    if not regions then return end
    for _, map in ipairs(regions:GetChildren()) do
        local clientBirds = map:FindFirstChild("ClientBirds")
        if clientBirds then
            for _, bird in ipairs(clientBirds:GetChildren()) do
                if bird:IsA("Model") then
                    for _, part in ipairs(bird:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                            part.CanCollide = false
                        end
                    end
                    local root = bird.PrimaryPart or bird:FindFirstChildWhichIsA("BasePart")
                    if root then
                        bird:PivotTo(CFrame.new(targetPos))
                    end
                end
            end
        end
    end
end

-- Locations
local Locations = {
    ["Beakwoods"] = CFrame.new(520,160,68),
    ["Deadlands"] = CFrame.new(-712,25,-1486),
    ["Mount Beaks"] = CFrame.new(84,240,383),
    ["Quill Lake"] = CFrame.new(-303,160,-488)
}

-- Fly system variables and functions
local FLYING = false
local flyKeyDown, flyKeyUp
local IYMouse = Players.LocalPlayer:GetMouse()
local QEfly = true
local iyflyspeed = 200

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function sFLY()
    local player = Players.LocalPlayer
    local character = player.Character
    local root = getRoot(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    FLYING = true
    humanoid.PlatformStand = true

    local BG = Instance.new("BodyGyro", root)
    local BV = Instance.new("BodyVelocity", root)
    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9,9e9,9e9)
    BG.cframe = root.CFrame
    BV.velocity = Vector3.new(0,0,0)
    BV.maxForce = Vector3.new(9e9,9e9,9e9)

    local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local lCONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local SPEED = 0

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end

    flyKeyDown = IYMouse.KeyDown:Connect(function(KEY)
        local key = KEY:lower()
        local speed = iyflyspeed or 200
        if key == "w" then CONTROL.F = speed
        elseif key == "s" then CONTROL.B = -speed
        elseif key == "a" then CONTROL.L = -speed
        elseif key == "d" then CONTROL.R = speed
        elseif QEfly and key == "e" then CONTROL.Q = speed * 2
        elseif QEfly and key == "q" then CONTROL.E = -speed * 2 end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Track
    end)

    flyKeyUp = IYMouse.KeyUp:Connect(function(KEY)
        local key = KEY:lower()
        if key == "w" then CONTROL.F = 0
        elseif key == "s" then CONTROL.B = 0
        elseif key == "a" then CONTROL.L = 0
        elseif key == "d" then CONTROL.R = 0
        elseif key == "e" then CONTROL.Q = 0
        elseif key == "q" then CONTROL.E = 0 end
    end)

    RunService.Heartbeat:Connect(function()
        if FLYING and root then
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                SPEED = 50
                BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p - workspace.CurrentCamera.CoordinateFrame.p) * SPEED))
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            else
                BV.velocity = Vector3.new(0,0,0)
            end
            BG.cframe = workspace.CurrentCamera.CoordinateFrame
        end
    end)
end

local function NOFLY()
    FLYING = false
    local player = Players.LocalPlayer
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        local root = getRoot(player.Character)
        if root then
            for _, v in pairs(root:GetChildren()) do
                if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
            end
        end
    end
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- ========== WindUI: Window and Sections (mapping Rayfield -> WindUI) ==========
local Window = WindUI:CreateWindow({
    Title = "DexHub | Beaks",
    Icon = "rbxassetid://85038777882275",
    Author = "Welcome to DexHub",
    Folder = "DexHubV1",
    Size = UDim2.fromOffset(580, 460),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
    KeySystem = {
        Note = "Get Key to Continue using DexHub",
        API = {
            { -- PlatoBoost
                Title = "Platoboost",
                Desc = "Click to copy",

                Type = "platoboost",
                ServiceId = 5565,
                Secret = "e4acd04d-3894-4b0b-b0da-8b9dd695f74d",
            }
        },
    }
})

Window:Tag({ Title = "v1.0.0", Color = Color3.fromHex("#30ff6a") })

-- Create Sections (one per original Rayfield tab)
local SectionMain = Window:Section({ Title = "Main" })
local SectionAuto = Window:Section({ Title = "Auto" })
local SectionESP = Window:Section({ Title = "ESP" })
local SectionOP = Window:Section({ Title = "OP ( adding and fixing stuff )" })
local SectionTeleport = Window:Section({ Title = "Teleports" })
local SectionMisc = Window:Section({ Title = "Misc" })

-- Create Tabs inside each section (single tab per section to match grouping)
local TabMain = SectionMain:Tab({ Title = "Main", Icon = "play" })
local TabAuto = SectionAuto:Tab({ Title = "Auto", Icon = "refresh-cw" })
local TabESP = SectionESP:Tab({ Title = "ESP", Icon = "eye" })
local TabOP = SectionOP:Tab({ Title = "OP", Icon = "tool" })
local TabTeleport = SectionTeleport:Tab({ Title = "Teleports", Icon = "map" })
local TabMisc = SectionMisc:Tab({ Title = "Misc", Icon = "settings" })

-- ========== Main Tab Elements (converted toggles/buttons/sliders) ==========
for _, name in ipairs({"Beakwoods", "Deadlands", "Mount Beaks", "Quill Lake"}) do
    local cleanName = name:gsub(" ", "")
    TabMain:Toggle({
        Title = "AutoFarm: " .. name,
        Value = false,
        Callback = function(v)
            Settings.AutoFarm[cleanName] = v
            if v then
                task.spawn(function() StartAutoFarm(name) end)
            end
        end
    })
end

TabMain:Toggle({
    Title = "Auto Shoot",
    Value = Settings.AutoFarm.AutoShoot,
    Callback = function(value)
        Settings.AutoFarm.AutoShoot = value
        safeNotify({ Title = "Auto Shoot", Content = value and "Auto Shoot enabled!" or "Auto Shoot disabled!", Duration = 3 })
    end
})

TabMain:Button({
    Title = "Aimbot",
    Icon = "target",
    Callback = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/VJpfksLY", true))()
        end)
        if not ok then safeNotify({ Title = "Error", Content = tostring(err), Duration = 5 }) end
    end
})

TabMain:Toggle({
    Title = "Hitbox Expander",
    Value = false,
    Callback = function(val)
        Settings.HitboxExpander = val
        ExpandHitboxes(val)
    end
})

TabMain:Slider({
    Title = "Hitbox Size",
    Value = { Min = 5, Max = 80, Default = Settings.HitboxSize },
    Step = 1,
    Callback = function(val)
        Settings.HitboxSize = val
        if Settings.HitboxExpander then ExpandHitboxes(true) end
    end
})

TabMain:Toggle({
    Title = "Freeze Birds in Place",
    Value = Settings.AutoFarm.FreezeBirds,
    Callback = function(value)
        Settings.AutoFarm.FreezeBirds = value
        if value then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                Settings.AutoFarm.FreezePosition = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 10
            end
            for _, regionName in pairs({"Beakwoods","Deadlands","Mount Beaks","Quill Lake"}) do
                local region = workspace.Regions:FindFirstChild(regionName)
                if region then
                    local clientBirds = region:FindFirstChild("ClientBirds")
                    if clientBirds then
                        for _, bird in pairs(clientBirds:GetChildren()) do
                            if bird:IsA("Model") then
                                for _, part in pairs(bird:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.Anchored = true
                                        part.CanCollide = false
                                        if not originalProperties[part] then
                                            originalProperties[part] = { Anchored = part.Anchored, CanCollide = part.CanCollide, CFrame = part.CFrame }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            safeNotify({ Title = "Bird Freeze", Content = "Birds will be frozen in place", Duration = 3 })
        else
            for part, props in pairs(originalProperties) do
                if part and part.Parent then
                    pcall(function()
                        part.Anchored = props.Anchored
                        part.CanCollide = props.CanCollide
                    end)
                end
            end
            originalProperties = {}
            safeNotify({ Title = "Bird Freeze", Content = "Birds are no longer frozen", Duration = 3 })
        end
    end
})

-- ========== Auto Tab ==========
TabAuto:Toggle({
    Title = "Auto Sell",
    Value = Settings.AutoSell,
    Callback = function(value)
        Settings.AutoSell = value
        if value then
            safeNotify({ Title = "Auto Sell", Content = "Auto Sell enabled! Will sell when inventory reaches "..Settings.SellThreshold, Duration = 3 })
        end
    end
})

TabAuto:Slider({
    Title = "Sell Threshold",
    Value = { Min = 5, Max = 200, Default = Settings.SellThreshold },
    Step = 5,
    Callback = function(value) Settings.SellThreshold = value end
})

TabAuto:Button({
    Title = "Sell All Items",
    Callback = function()
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        local Seller = Workspace:FindFirstChild("Regions") and Workspace.Regions:FindFirstChild("Beakwoods") and Workspace.Regions.Beakwoods:FindFirstChild("Useable") and Workspace.Regions.Beakwoods.Useable:FindFirstChild("NeilBirdCollector")
        local Net = ReplicatedStorage:FindFirstChild("Util") and ReplicatedStorage.Util:FindFirstChild("Net")
        if not Seller or not Net then
            safeNotify({ Title = "Error", Content = "Could not find seller or network components", Duration = 6.5 })
            return
        end
        local SellInventory = Net:FindFirstChild("RF/SellInventory")
        if not SellInventory then safeNotify({ Title = "Error", Content = "SellInventory remote function not found", Duration = 6.5 }) return end

        local sellerCFrame = CFrame.new(515.973022, 154.072998, 45.8440018, -1,0,0,0,1,0,0,0,-1)
        local originalCFrame = hrp.CFrame
        hrp.CFrame = sellerCFrame + Vector3.new(0,5,0)
        safeNotify({ Title = "Auto-Sell Started", Content = "Selling all items 5 times...", Duration = 3 })
        for _ = 1,5 do
            pcall(function() SellInventory:InvokeServer("All") end)
            task.wait(0.1)
        end
        hrp.CFrame = originalCFrame
        safeNotify({ Title = "Auto-Sell Complete", Content = "Successfully sold all items!", Duration = 5 })
    end
})

TabAuto:Toggle({
    Title = "Auto Buy Darts",
    Value = Settings.AutoDart,
    Callback = function(value)
        Settings.AutoDart = value
        if value then
            safeNotify({ Title = "Auto Darts", Content = "Auto buying darts enabled!", Duration = 3 })
            task.spawn(function()
                while Settings.AutoDart do
                    pcall(function()
                        ReplicatedStorage:WaitForChild("Util"):WaitForChild("Net"):WaitForChild("RF/DartRoll"):InvokeServer("Beakwoods")
                    end)
                    task.wait(1)
                end
            end)
        else
            safeNotify({ Title = "Auto Darts", Content = "Auto buying darts disabled!", Duration = 3 })
        end
    end
})

-- ========== ESP Tab ==========
TabESP:Toggle({
    Title = "Enable Bird ESP",
    Value = false,
    Callback = function(Value) ToggleESP(Value) end
})

for regionName, defaultColor in pairs(ESPColors) do
    TabESP:Colorpicker({
        Title = regionName .. " Color",
        Default = defaultColor,
        Callback = function(Value)
            ESPColors[regionName] = Value
            if ESPEnabled then
                for bird, espData in pairs(ESPObjects) do
                    for _, obj in pairs(espData) do
                        if obj:IsA("Highlight") then
                            obj.FillColor = Value
                        end
                    end
                end
            end
        end
    })
end

TabESP:Divider()
TabESP:Toggle({
    Title = "Show Names",
    Value = true,
    Callback = function(Value)
        for bird, espData in pairs(ESPObjects) do
            for _, obj in pairs(espData) do
                if obj:IsA("BillboardGui") then obj.Enabled = Value end
            end
        end
    end
})

TabESP:Slider({
    Title = "ESP Transparency",
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Step = 0.1,
    Callback = function(Value)
        for bird, espData in pairs(ESPObjects) do
            for _, obj in pairs(espData) do
                if obj:IsA("Highlight") then obj.FillTransparency = Value end
            end
        end
    end
})

-- ========== OP Tab (Teleporting birds and misc OP stuff) ==========
TabOP:Toggle({
    Title = "Teleport All Birds to You",
    Value = false,
    Callback = function(Value)
        teleportBirdsEnabled = Value
        if Value then
            safeNotify({ Title = "Teleport Birds", Content = "Birds will be teleported to you every second and frozen in place", Duration = 3 })
            task.spawn(function()
                while teleportBirdsEnabled do teleportBirds() task.wait(1) end
            end)
        else
            for part, props in pairs(originalProperties) do
                if part and part.Parent then pcall(function() part.Anchored = props.Anchored; part.CanCollide = props.CanCollide; part.CFrame = props.CFrame end) end
            end
            originalProperties = {}
            safeNotify({ Title = "Teleport Birds", Content = "Stopped teleporting birds and restored original properties", Duration = 3 })
        end
    end
})

-- ========== Teleport Tab ==========
-- Create separate teleport buttons
TabTeleport:Button({ Title = "Teleport to Beakswood", Callback = function()
    local destination = Locations["Beakwoods"]
    if destination then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        task.wait(0.1)
        hrp.CFrame = destination + Vector3.new(0,5,0)
        task.wait()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        safeNotify({ Title = "Teleport Success", Content = "Teleported to Beakswood!", Duration = 5 })
    end
end })

TabTeleport:Button({ Title = "Teleport to Deadlands", Callback = function()
    local destination = Locations["Deadlands"]
    if destination then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        task.wait(0.1)
        hrp.CFrame = destination + Vector3.new(0,5,0)
        task.wait()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        safeNotify({ Title = "Teleport Success", Content = "Teleported to Deadlands!", Duration = 5 })
    end
end })

TabTeleport:Button({ Title = "Teleport to Mount Beaks", Callback = function()
    local destination = Locations["Mount Beaks"]
    if destination then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        task.wait(0.1)
        hrp.CFrame = destination + Vector3.new(0,5,0)
        task.wait()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        safeNotify({ Title = "Teleport Success", Content = "Teleported to Mount Beaks!", Duration = 5 })
    end
end })

TabTeleport:Button({ Title = "Teleport to Quill Lake", Callback = function()
    local destination = Locations["Quill Lake"]
    if destination then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        task.wait(0.1)
        hrp.CFrame = destination + Vector3.new(0,5,0)
        task.wait()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        safeNotify({ Title = "Teleport Success", Content = "Teleported to Quill Lake!", Duration = 5 })
    end
end })

TabTeleport:Button({ Title = "Teleport to Random Bird", Callback = function()
    if not ClientBirds then safeNotify({ Title = "Error", Content = "ClientBirds not found!", Duration = 3 }) return end
    local birds = {}
    for _, bird in ipairs(ClientBirds:GetChildren()) do
        if bird:IsA("Model") then
            local primaryPart = bird.PrimaryPart or bird:FindFirstChildWhichIsA("BasePart")
            if primaryPart then table.insert(birds, bird) end
        end
    end
    if #birds > 0 then
        local randomBird = birds[math.random(1,#birds)]
        local primaryPart = randomBird.PrimaryPart or randomBird:FindFirstChildWhichIsA("BasePart")
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        if hrp and primaryPart then
            hrp.CFrame = CFrame.new(primaryPart.Position + Vector3.new(0,5,0))
            safeNotify({ Title = "Teleport Success", Content = "Teleported to random bird", Duration = 3 })
        end
    else
        safeNotify({ Title = "Error", Content = "No birds found in ClientBirds!", Duration = 3 })
    end
end })

-- ========== Misc Tab ==========
TabMisc:Toggle({
    Title = "FullBright",
    Value = false,
    Callback = function(Value)
        FullbrightEnabled = Value
        local Lighting = game:GetService("Lighting")
        if Value then
            originalLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient }
            task.spawn(function()
                while FullbrightEnabled do
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.FogEnd = 100000
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
                    task.wait(0.1)
                end
            end)
            safeNotify({ Title = "FullBright", Content = "FullBright enabled!", Duration = 3 })
        else
            if originalLighting.Brightness then
                Lighting.Brightness = originalLighting.Brightness
                Lighting.ClockTime = originalLighting.ClockTime
                Lighting.FogEnd = originalLighting.FogEnd
                Lighting.GlobalShadows = originalLighting.GlobalShadows
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            else
                Lighting.Brightness = 1
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = true
                Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
            end
            safeNotify({ Title = "FullBright", Content = "FullBright disabled!", Duration = 3 })
        end
    end
})

TabMisc:Toggle({
    Title = "NoFog",
    Value = false,
    Callback = function(Value)
        local Lighting = game:GetService("Lighting")
        if originalLighting.FogEnd == nil then originalLighting.FogEnd = Lighting.FogEnd end
        if Value then Lighting.FogEnd = 100000; safeNotify({ Title = "NoFog", Content = "Fog removed!", Duration = 3 })
        else Lighting.FogEnd = originalLighting.FogEnd or 1000; safeNotify({ Title = "NoFog", Content = "Fog restored!", Duration = 3 }) end
    end
})

TabMisc:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(Value)
        Settings.InfiniteJump = Value
        if Value then
            UserInputService.JumpRequest:Connect(function()
                if Settings.InfiniteJump then
                    local character = LocalPlayer.Character
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then humanoid:ChangeState("Jumping") end
                    end
                end
            end)
        end
    end
})

TabMisc:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 200, Default = Settings.WalkSpeed },
    Step = 5,
    Callback = function(Value)
        Settings.WalkSpeed = Value
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = Value end
        end
    end
})

TabMisc:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(Value)
        if Value then sFLY(); safeNotify({ Title = "Fly", Content = "Fly enabled! (WASD + Q/E)", Duration = 3 })
        else NOFLY(); safeNotify({ Title = "Fly", Content = "Fly disabled!", Duration = 3 }) end
    end
})

TabMisc:Slider({
    Title = "Fly Speed",
    Value = { Min = 50, Max = 500, Default = iyflyspeed },
    Step = 10,
    Callback = function(Value) iyflyspeed = Value end
})

-- ========== Config manager integration (if available) ==========
local configName = "default"
local configFile = nil
local MyPlayerData = { name = "Player1", level = 1, inventory = { "sword","shield","potion" } }

local ConfigManager = Window.ConfigManager
if ConfigManager then
    ConfigManager:Init(Window)
    TabOP:Input({
        Title = "Config Name",
        Value = configName,
        Callback = function(value) configName = value end
    })

    TabOP:Button({ Title = "Save Config", Icon = "save", Variant = "Primary", Callback = function()
        configFile = ConfigManager:CreateConfig(configName)
        configFile:Register("Settings", Settings)
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        if configFile:Save() then safeNotify({ Title = "Save Config", Content = "Saved as: "..configName, Duration = 3 })
        else safeNotify({ Title = "Error", Content = "Failed to save config", Duration = 3 }) end
    end })

    TabOP:Button({ Title = "Load Config", Icon = "folder", Callback = function()
        configFile = ConfigManager:CreateConfig(configName)
        local loadedData = configFile:Load()
        if loadedData then
            if loadedData.playerData then MyPlayerData = loadedData.playerData end
            local lastSave = loadedData.lastSave or "Unknown"
            safeNotify({ Title = "Load Config", Content = "Loaded: "..configName.."\nLast save: "..lastSave, Duration = 5 })
            TabOP:Paragraph({ Title = "Player Data", Desc = string.format("Name: %s\nLevel: %d\nInventory: %s", MyPlayerData.name, MyPlayerData.level, table.concat(MyPlayerData.inventory, ", ")) })
        else
            safeNotify({ Title = "Error", Content = "Failed to load config", Duration = 3 })
        end
    end })
else
    TabOP:Paragraph({ Title = "Config Manager Not Available", Desc = "This feature requires ConfigManager", Image = "alert-triangle", ImageSize = 20, Color = "White" })
end

-- Footer/credits
local footerSection = Window:Section({ Title = "Beaks | DexHub" })
TabOP:Paragraph({ Title = "Created with ❤️", Desc = "github.com/Footagesus/WindUI", Image = "github", ImageSize = 20, Color = "Grey", Buttons = {
    { Title = "Copy Link", Icon = "copy", Variant = "Tertiary", Callback = function()
        setclipboard("https://github.com/Footagesus/WindUI")
        WindUI:Notify({ Title = "Copied!", Content = "GitHub link copied to clipboard", Duration = 2 })
    end }
} })

-- Window events
Window:OnClose(function()
    print("Window closed")
    if ConfigManager and configFile then
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
        print("Config auto-saved on close")
    end
end)

Window:OnDestroy(function()
    print("Window destroyed")
end)

-- End of converted file
