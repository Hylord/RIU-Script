-- [[ PROJECT: HYLORD RIU SCRIPT ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- [[ AYARLAR & LİSTELER ]]
local TargetItems = {"Requiem Arrow", "Rokakaka", "Diary", "Lucky Arrow", "Pure Arrow", "Steel Ball", "Stone Mask", "Cash", "Money", "Arrow"}
local MeteorNames = {"Meteorite", "Meteor"}

-- Stamina İçin Bilinen Parçalar
local KnownSaintParts = {
    "Rib Cage of the Saint's Corpse", "Heart of the Saint's Corpse",
    "Pelvis of the Saint's Corpse", "Skull of the Saint's Corpse",
    "Left Arm of the Saint's Corpse", "Right Arm of the Saint's Corpse",
    "Left Eye of the Saint's Corpse", "Right Eye of the Saint's Corpse"
}

-- Kara Liste (SaintsCorpse eklendi)
local Blacklist = {
    "CashBundle", "FakeChest", "ChestSpawn", "SpawnedChests",
    "Chests", "ChestGenerate", "ChestSkulls", "ChestNotification", 
    "One-Eyed Man's Chestplate", "SaintsCorpse", "Terrain", "Baseplate", "Camera"
}

-- Geçici Takılma Listesi
local IgnoreList = {} 

local ChestColors = {
    ["Common Chest"] = Color3.fromRGB(220, 220, 220),
    ["Uncommon Chest"] = Color3.fromRGB(50, 205, 50),
    ["Rare Chest"] = Color3.fromRGB(220, 60, 60),
    ["Epic Chest"] = Color3.fromRGB(170, 80, 230),
    ["Legendary Chest"] = Color3.fromRGB(255, 215, 0),
    ["Mythical Chest"] = Color3.fromRGB(0, 255, 255)
}

-------------------------------------------------------------------------
-- 1. SOLARA UI FIX
-------------------------------------------------------------------------
local function GetSafeParent()
    if LocalPlayer:FindFirstChild("PlayerGui") then return LocalPlayer.PlayerGui end
    return game:GetService("CoreGui")
end

local SafeParent = GetSafeParent()
if SafeParent:FindFirstChild("HylordRIUScript") then SafeParent.HylordRIUScript:Destroy() end

-------------------------------------------------------------------------
-- 2. YARDIMCI FONKSİYONLAR
-------------------------------------------------------------------------

local function Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = duration or 3})
end

local function SafeTeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = targetCFrame + Vector3.new(0, 6, 0)
        task.spawn(function()
            for i = 1, 5 do 
                if root then root.Velocity = Vector3.new(0, 0, 0) end
                RunService.Heartbeat:Wait()
            end
        end)
    end
end

-- [AKILLI VALIDATION]
local function IsValidTarget(obj)
    if not obj or not obj.Parent then return false end
    if IgnoreList[obj] and os.time() < IgnoreList[obj] then return false end
    if obj:IsA("Folder") then return false end
    for _, bad in pairs(Blacklist) do 
        if obj.Name == bad or obj.Name:find(bad) then return false end 
    end
    
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then return true, prompt end
    return false
end

-------------------------------------------------------------------------
-- 3. ÖZELLİKLER (LOGIC)
-------------------------------------------------------------------------

-- [A. Check Staff]
local function CheckStaff()
    local found = false; local names = ""
    local GroupID = 16924699 
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local role = p:GetRoleInGroup(GroupID)
            if role == "Owner" or role == "Developer" or role == "Administrator" or role == "Moderator" or p:GetRankInGroup(GroupID) >= 50 then
                found = true; names = names .. p.Name .. ", "
            end
        end
    end
    if found then Notify("⚠️ DİKKAT", "Yetkili Var:\n" .. names, 10) else Notify("✅ GÜVENLİ", "Sunucuda yetkili yok.", 5) end
end

-- [B. Speed Hack]
local function ToggleNaturalSpeed(state, value)
    _G.SpeedHack = state; _G.SpeedVal = value
    if state then
        task.spawn(function()
            while _G.SpeedHack do
                local char = LocalPlayer.Character
                local stats = char and char:FindFirstChild("PlayerStatistics")
                if stats then
                    stats:SetAttribute("WalkSpeed", _G.SpeedVal)
                    stats:SetAttribute("SprintSpeed", _G.SpeedVal)
                    stats:SetAttribute("Speed", _G.SpeedVal) 
                end
                task.wait()
            end
            local char = LocalPlayer.Character; local stats = char and char:FindFirstChild("PlayerStatistics")
            if stats then stats:SetAttribute("WalkSpeed", 16); stats:SetAttribute("SprintSpeed", 25) end
        end)
    end
end

-- [C. Item Farm]
local function ToggleItemFarm(state)
    _G.ItemFarm = state
    if state then
        task.spawn(function()
            while _G.ItemFarm do
                local nearest = nil
                local minDist = math.huge
                local myPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position

                if myPos then
                    local allObjects = Workspace:GetDescendants()
                    local processed = 0
                    for _, v in pairs(allObjects) do
                        if not _G.ItemFarm then break end
                        processed = processed + 1
                        if processed % 300 == 0 then RunService.Heartbeat:Wait() end
                        
                        -- İsim kontrolü
                        local isTarget = false
                        if (v:IsA("Model") or v:IsA("BasePart")) then
                            for _, t in pairs(TargetItems) do 
                                if v.Name:find(t) then isTarget = true; break end 
                            end
                        end
                        
                        if isTarget then
                            local valid, prompt = IsValidTarget(v)
                            if valid then
                                -- Root belirleme (Model ise Pivot veya Handle, Part ise kendisi)
                                local root = v
                                if v:IsA("Model") then
                                    root = v.PrimaryPart or v:FindFirstChild("Handle") or v:FindFirstChild("Part") or v
                                end

                                -- Mesafe kontrolü ve Pozisyon Alma
                                if root then
                                    local pos = nil
                                    if root:IsA("BasePart") then
                                        pos = root.Position
                                    elseif root:IsA("Model") then
                                        pos = root:GetPivot().Position
                                    end
                                    
                                    if pos then
                                        local dist = (myPos - pos).Magnitude
                                        if dist < minDist then 
                                            minDist = dist
                                            nearest = {Obj = v, Part = root, Prompt = prompt} 
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if nearest then
                    -- Işınlanma Hedefi (CFrame veya Pivot)
                    local targetCF = nil
                    if nearest.Part:IsA("Model") then
                        targetCF = nearest.Part:GetPivot()
                    elseif nearest.Part:IsA("BasePart") then
                        targetCF = nearest.Part.CFrame
                    end

                    if targetCF then
                        -- [[ DÜZELTME BURADA ]] --
                        -- SafeTeleportTo zaten +6 ekliyor, biz buna ekstra +3 daha ekliyoruz.
                        -- Toplamda eşyanın 9 birim üzerine ışınlanırsın, böylece asla yere gömülmezsin.
                        -- Havadan eşyanın üzerine düşerek alırsın.
                        SafeTeleportTo(targetCF + Vector3.new(0, 3, 0)) 
                        
                        task.wait(0.3)
                        local attempts = 0
                        while attempts < 3 and nearest.Prompt.Enabled and nearest.Prompt.Parent do
                            nearest.Prompt.HoldDuration = 0
                            fireproximityprompt(nearest.Prompt)
                            task.wait(0.2)
                            attempts = attempts + 1
                        end
                        if nearest.Prompt.Parent and nearest.Prompt.Enabled then IgnoreList[nearest.Obj] = os.time() + 60 end
                    end
                else
                    task.wait(2)
                end
            end
        end)
    end
end

-- [D. Chest Farm]
local function ToggleChestFarm(state)
    _G.ChestFarm = state
    if state then
        task.spawn(function()
            while _G.ChestFarm do
                local nearest = nil
                local minDist = math.huge
                local myPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position

                if myPos then
                    local targets = Workspace:FindFirstChild("Chests") and Workspace.Chests:GetDescendants() or Workspace:GetDescendants()
                    for _, v in pairs(targets) do
                        if not _G.ChestFarm then break end
                        if v:IsA("Model") and v.Name:find("Chest") and not v.Name:find("Spawn") then
                            local valid, prompt = IsValidTarget(v)
                            if valid then
                                local root = v:FindFirstChild("WoodTop") or v.PrimaryPart
                                if root then
                                    local dist = (myPos - root.Position).Magnitude
                                    if dist < minDist then minDist = dist; nearest = {Obj = v, Part = root, Prompt = prompt} end
                                end
                            end
                        end
                    end
                end

                if nearest then
                    SafeTeleportTo(nearest.Part.CFrame)
                    task.wait(0.4)
                    if nearest.Prompt.Enabled then
                        nearest.Prompt.HoldDuration = 0
                        fireproximityprompt(nearest.Prompt)
                        task.wait(1.2)
                    end
                    if nearest.Prompt.Parent and nearest.Prompt.Enabled then IgnoreList[nearest.Obj] = os.time() + 60 end
                else
                    task.wait(1)
                end
            end
        end)
    end
end

-- [E. Meteor Farm]
local function ToggleMeteorFarm(state)
    _G.MeteorFarm = state
    if state then
        task.spawn(function()
            while _G.MeteorFarm do
                local target = nil
                local searchTable = Workspace:FindFirstChild("MeteoriteSpawner") and Workspace.MeteoriteSpawner:GetDescendants() or Workspace:GetDescendants()

                for _, v in pairs(searchTable) do
                    for _, mName in pairs(MeteorNames) do
                        if v.Name:find(mName) and not v.Name:find("Shard") then
                            local valid, prompt = IsValidTarget(v)
                            if valid then
                                local root = v:FindFirstChild("Meteorite") or v.PrimaryPart or v
                                if root then target = {Obj = v, Part = root, Prompt = prompt} break end
                            end
                        end
                    end
                    if target then break end
                end

                if target then
                    SafeTeleportTo(target.Part.CFrame)
                    task.wait(0.5)
                    for i=1, 5 do
                        if target.Prompt.Enabled and target.Prompt.Parent then
                            target.Prompt.HoldDuration = 0
                            fireproximityprompt(target.Prompt)
                            task.wait(0.1)
                        end
                    end
                    if target.Prompt.Parent and target.Prompt.Enabled then IgnoreList[target.Obj] = os.time() + 30 end
                else
                    task.wait(2)
                end
            end
        end)
    end
end

-- [F. SBR Stamina]
local CachedPartName = nil
local function FindBestPart()
    if CachedPartName then return CachedPartName end
    local stats = LocalPlayer:FindFirstChild("PlayerStatistics")
    local inventory = stats and stats:FindFirstChild("Inventory")
    if inventory then
        for itemName, quantity in pairs(inventory:GetAttributes()) do
            if quantity > 0 and string.find(itemName:lower(), "saint") and string.find(itemName:lower(), "corpse") then
                CachedPartName = itemName
                return itemName
            end
        end
    end
    return KnownSaintParts[math.random(1, #KnownSaintParts)]
end

local function ToggleInfiniteStamina(state)
    _G.InfStamina = state
    if state then
        task.spawn(function()
            local remote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ItemUseEvent")
            while _G.InfStamina do
                local char = LocalPlayer.Character
                if char and remote then
                    local partName = FindBestPart()
                    if partName then
                        remote:FireServer(char, partName, partName, false)
                    end
                end
                task.wait(0.08)
            end
        end)
    else
        CachedPartName = nil
    end
end

-- [G. Corpse ESP]
local ActiveESP = {}
local ESPConnection = nil

local function AddESPToPart(obj)
    if not _G.CorpseESP then return end
    if not obj or not obj.Parent then return end
    
    if obj:IsA("Model") or obj:IsA("BasePart") then
        local name = obj.Name:lower()
        if name:find("saint") and name:find("corpse") and not name:find("spawn") then
            local target = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("Handle"))) or obj
            if target and not target:FindFirstChild("HylordESP") then
                local hl = Instance.new("Highlight"); hl.Name = "HylordESP"; hl.FillColor = Color3.fromRGB(255, 170, 0); hl.FillTransparency = 0.5; hl.OutlineColor = Color3.new(1,1,1); hl.Parent = target
                local bg = Instance.new("BillboardGui"); bg.Name = "HylordTag"; bg.Adornee = target; bg.Size = UDim2.new(0, 200, 0, 50); bg.StudsOffset = Vector3.new(0, 3, 0); bg.AlwaysOnTop = true; bg.MaxDistance = 1000; bg.Parent = target
                local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Text = "💀 " .. obj.Name; txt.TextColor3 = Color3.fromRGB(255, 215, 0); txt.Font = Enum.Font.GothamBold; txt.TextSize = 14; Instance.new("UIStroke", txt).Thickness = 1.5
                table.insert(ActiveESP, hl); table.insert(ActiveESP, bg)
            end
        end
    end
end

local function ToggleCorpseESP(state)
    _G.CorpseESP = state
    if state then
        for _, v in pairs(Workspace:GetDescendants()) do AddESPToPart(v) end
        ESPConnection = Workspace.DescendantAdded:Connect(AddESPToPart)
    else
        if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
        for _, v in pairs(ActiveESP) do if v then v:Destroy() end end; ActiveESP = {}
    end
end

-- [H. Player ESP]
local function TogglePlayerESP(state)
    _G.PlayerESP = state
    if state then
        task.spawn(function()
            while _G.PlayerESP do
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                        local head = plr.Character.Head
                        if not head:FindFirstChild("HylordPlayerESP") then
                            local bg = Instance.new("BillboardGui", head); bg.Name = "HylordPlayerESP"; bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,3,0); bg.AlwaysOnTop = true
                            local txt = Instance.new("TextLabel", bg); txt.Name = "Info"; txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.TextColor3 = Color3.new(1,1,1); txt.Font = Enum.Font.GothamBold; txt.TextSize = 14; Instance.new("UIStroke", txt).Thickness = 1.5
                        end
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude
                        head.HylordPlayerESP.Info.Text = string.format("%s\n[%d m]", plr.Name, math.floor(dist))
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("HylordPlayerESP") then p.Character.Head.HylordPlayerESP:Destroy() end end
    end
end

-------------------------------------------------------------------------
-- 4. UI: SIDEBAR HUB
-------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui", SafeParent)
ScreenGui.Name = "HylordRIUScript"; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 580, 0, 400)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SFix = Instance.new("Frame", Sidebar); SFix.Size = UDim2.new(0,10,1,0); SFix.Position = UDim2.new(1,-10,0,0); SFix.BackgroundColor3 = Sidebar.BackgroundColor3; SFix.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Sidebar)
Title.Text = "Hylord RIU Script"; Title.Size = UDim2.new(1,0,0,60); Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(170, 100, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 18

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -150, 1, -20); PageContainer.Position = UDim2.new(0, 150, 0, 10); PageContainer.BackgroundTransparency = 1

local function CreatePage(visible)
    local p = Instance.new("ScrollingFrame", PageContainer)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = visible; p.ScrollBarThickness = 3
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.CanvasSize = UDim2.new(0,0,0,0)
    local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder
    return p
end

local P_Home, P_SBR, P_Item, P_Chest = CreatePage(true), CreatePage(false), CreatePage(false), CreatePage(false)

local TabCon = Instance.new("Frame", Sidebar); TabCon.Size = UDim2.new(1,0,1,-70); TabCon.Position = UDim2.new(0,0,0,70); TabCon.BackgroundTransparency = 1
Instance.new("UIListLayout", TabCon).Padding = UDim.new(0, 5)

local function AddTab(text, page)
    local b = Instance.new("TextButton", TabCon); b.Size = UDim2.new(1,-10,0,35); b.Position = UDim2.new(0,5,0,0); b.BackgroundColor3 = Color3.fromRGB(30,30,35)
    b.Text = text; b.TextColor3 = Color3.new(0.8,0.8,0.8); b.Font = Enum.Font.GothamSemibold; b.TextSize = 13; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() P_Home.Visible=false; P_SBR.Visible=false; P_Item.Visible=false; P_Chest.Visible=false; page.Visible=true end)
end
AddTab("🏠 Home", P_Home); AddTab("🐎 SBR", P_SBR); AddTab("📦 Item Farm", P_Item); AddTab("💰 Chest Farm", P_Chest)

local function AddToggle(parent, text, func)
    local on = false; local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1,0,0,40); b.BackgroundColor3 = Color3.fromRGB(35,35,40); b.Text = text.." [KAPALI]"; b.TextColor3 = Color3.fromRGB(180,180,180); b.Font = Enum.Font.GothamMedium; b.TextSize = 14; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    local ind = Instance.new("Frame", b); ind.Size = UDim2.new(0,4,1,0); ind.BackgroundColor3 = Color3.fromRGB(80,80,80); Instance.new("UICorner", ind).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() on = not on; b.Text = text .. (on and " [AÇIK]" or " [KAPALI]"); b.TextColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(180,180,180); ind.BackgroundColor3 = on and Color3.fromRGB(0,255,100) or Color3.fromRGB(80,80,80); func(on) end)
end
local function AddButton(parent, text, func, color)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(1,0,0,40); b.BackgroundColor3 = color or Color3.fromRGB(35,35,40); b.Text = text; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamMedium; b.TextSize = 14; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() local o=b.BackgroundColor3; b.BackgroundColor3=Color3.fromRGB(60,60,65); task.wait(0.1); b.BackgroundColor3=o; func() end)
end

local function AddDropdown(parent, title, type)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1,0,0,40); f.BackgroundColor3 = Color3.fromRGB(30,30,35); f.ClipsDescendants = true; Instance.new("UICorner", f).CornerRadius = UDim.new(0,6)
    local l = Instance.new("UIListLayout", f); l.Padding = UDim.new(0,2); l.SortOrder = Enum.SortOrder.LayoutOrder
    local h = Instance.new("TextButton", f); h.Name="H"; h.Size=UDim2.new(1,0,0,40); h.BackgroundColor3=Color3.fromRGB(40,40,45); h.Text=title.." 🔽"; h.TextColor3=Color3.new(1,1,1); h.Font=Enum.Font.GothamBold; h.TextSize=14; Instance.new("UICorner", h).CornerRadius=UDim.new(0,6)
    local r = Instance.new("TextButton", f); r.Size=UDim2.new(1,0,0,30); r.BackgroundColor3=Color3.fromRGB(0,120,215); r.Text="♻️ LİSTEYİ YENİLE"; r.TextColor3=Color3.new(1,1,1); r.Font=Enum.Font.GothamBold
    local open = false
    h.MouseButton1Click:Connect(function() open = not open; if open then local c = #f:GetChildren()-2; local hT = 40+32+(c*27); if c==0 then hT=72 end; f.Size=UDim2.new(1,0,0,hT); h.Text=title.." 🔼" else f.Size=UDim2.new(1,0,0,40); h.Text=title.." 🔽" end end)
    r.MouseButton1Click:Connect(function()
        for _,c in pairs(f:GetChildren()) do if c.Name=="IB" then c:Destroy() end end
        local count=0
        
        -- SBR Listesi Fix (Corpse için IsValidTarget kullanmıyoruz)
        local isSBRCorpse = (type == "Corpse")
        local targets = Workspace:GetDescendants()
        if type == "Chest" and Workspace:FindFirstChild("Chests") then targets = Workspace.Chests:GetDescendants() end
        
        for _,v in pairs(targets) do
            local match, color = false, Color3.fromRGB(200,200,200)
            
            if type == "Item" then
                if (v:IsA("Model") or v:IsA("BasePart")) then for _,t in pairs(TargetItems) do if v.Name:find(t) then match=true break end end end
            elseif type == "Chest" then
                if v:IsA("Model") and v.Name:find("Chest") then match=true; for cn,cc in pairs(ChestColors) do if v.Name:find(cn) then color=cc break end end end
            elseif type == "Corpse" then
                if v.Name:lower():find("saint") and v.Name:lower():find("corpse") and not v.Name:lower():find("spawn") then match=true; color=Color3.fromRGB(255,160,50) end
            end
            
            if match and not v.Name:find("Meteor") then
                local valid = false
                local root = nil
                
                if isSBRCorpse then
                    -- Corpse için özel kontrol (Blacklist + Prompt Yok)
                    local isBad = false
                    for _, bad in pairs(Blacklist) do if v.Name == bad or v.Name:find(bad) then isBad = true; break end end
                    
                    if not isBad then
                        valid = true
                        root = (v:IsA("Model") and (v.PrimaryPart or v:FindFirstChild("Handle"))) or v
                    end
                else
                    -- Diğerleri için Prompt kontrolü
                    local isValidTarget, _ = IsValidTarget(v)
                    if isValidTarget then
                        valid = true
                        root = (v:IsA("Model") and (v.PrimaryPart or v:FindFirstChild("Handle") or v:FindFirstChild("WoodTop") or v:FindFirstChild("Part"))) or v
                    end
                end

                if valid and root then
                    count=count+1
                    local b = Instance.new("TextButton", f); b.Name="IB"; b.Size=UDim2.new(1,-10,0,25); b.BackgroundColor3=Color3.fromRGB(35,35,40); b.Text="  📍 "..v.Name; b.TextColor3=color; b.Font=Enum.Font.GothamMedium; b.TextXAlignment="Left"; b.TextSize=12; Instance.new("UICorner", b).CornerRadius=UDim.new(0,4)
                    b.MouseButton1Click:Connect(function() 
    if root:IsA("Model") then
        SafeTeleportTo(root:GetPivot()) -- Model ise Pivot noktasını al
    else
        SafeTeleportTo(root.CFrame) -- Part ise direkt CFrame al
    end
end)
                end
            end
        end
        if open then local hT = 40+32+(count*27); f.Size=UDim2.new(1,0,0,hT) end
        r.Text="Bulundu: "..count; task.wait(1); r.Text="♻️ LİSTEYİ YENİLE"
    end)
end

-- [HOME]
AddButton(P_Home, "👮 Check Staff (Yetkili Kontrol)", CheckStaff, Color3.fromRGB(200,50,50))
AddToggle(P_Home, "👤 Player ESP (Mesafe)", TogglePlayerESP)
local sv=50; local function ASlider(p,t,min,max,d,f) local v=d; local fr=Instance.new("Frame",p); fr.Size=UDim2.new(1,0,0,50); fr.BackgroundColor3=Color3.fromRGB(35,35,40); Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6); local l=Instance.new("TextLabel",fr); l.Size=UDim2.new(1,0,0,25); l.BackgroundTransparency=1; l.Text=t..": "..v; l.TextColor3=Color3.new(1,1,1); l.Font=Enum.Font.GothamMedium; l.TextSize=14; local sb=Instance.new("TextButton",fr); sb.Size=UDim2.new(0.9,0,0,6); sb.Position=UDim2.new(0.05,0,0.7,0); sb.BackgroundColor3=Color3.fromRGB(20,20,20); sb.Text=""; Instance.new("UICorner",sb).CornerRadius=UDim.new(0,3); local fl=Instance.new("Frame",sb); fl.Size=UDim2.new((v-min)/(max-min),0,1,0); fl.BackgroundColor3=Color3.fromRGB(170,100,255); Instance.new("UICorner",fl).CornerRadius=UDim.new(0,3); local dr=false; sb.MouseButton1Down:Connect(function() dr=true end); UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end); UserInputService.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local pct=math.clamp((i.Position.X-sb.AbsolutePosition.X)/sb.AbsoluteSize.X,0,1); v=math.floor(min+(max-min)*pct); fl.Size=UDim2.new(pct,0,1,0); l.Text=t..": "..v; f(v) end end); f(v) end
ASlider(P_Home, "Hız Ayarı", 16, 200, 50, function(v) sv=v; _G.SpeedVal=v end)
AddToggle(P_Home, "⚡ Natural Speed (Legit)", function(v) ToggleNaturalSpeed(v, sv) end)

-- [SBR]
AddToggle(P_SBR, "🐎 Sınırsız Stamina (Universal)", ToggleInfiniteStamina)
AddButton(P_SBR, "🏁 SBR Bitiş Çizgisine Işınlan", function() SafeTeleportTo(CFrame.new(14250,33,791)) end)
AddToggle(P_SBR, "💀 Saint's Corpse ESP", ToggleCorpseESP)
AddDropdown(P_SBR, "📂 Corpse Işınlanma Listesi", "Corpse")

-- [ITEM]
AddToggle(P_Item, "🛠️ Item Farm (Otomatik)", ToggleItemFarm)
AddToggle(P_Item, "☄️ Meteor Farm (Otomatik)", ToggleMeteorFarm)
AddDropdown(P_Item, "📂 Item Işınlanma Listesi", "Item")

-- [CHEST]
AddToggle(P_Chest, "💰 Chest Farm (Otomatik)", ToggleChestFarm)
AddDropdown(P_Chest, "📂 Chest Işınlanma Listesi", "Chest")

-- [CORE]
local Close=Instance.new("TextButton",MainFrame); Close.Size=UDim2.new(0,30,0,30); Close.Position=UDim2.new(1,-35,0,5); Close.Text="X"; Close.TextColor3=Color3.fromRGB(255,80,80); Close.BackgroundColor3=Color3.fromRGB(35,35,40); Instance.new("UICorner",Close).CornerRadius=UDim.new(0,6)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy(); _G.InfStamina=false; _G.SpeedHack=false; _G.ItemFarm=false; _G.ChestFarm=false; _G.MeteorFarm=false; _G.PlayerESP=false; _G.CorpseESP=false end)
local dr,dS,sP; MainFrame.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; dS=i.Position; sP=MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dS; MainFrame.Position=UDim2.new(sP.X.Scale,sP.X.Offset+d.X,sP.Y.Scale,sP.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
UserInputService.InputBegan:Connect(function(i,g) if i.KeyCode==Enum.KeyCode.L and not UserInputService:GetFocusedTextBox() then MainFrame.Visible=not MainFrame.Visible end end)

Notify("Hylord RIU Script", "Özellikler Aktifleştirildi", 5)
