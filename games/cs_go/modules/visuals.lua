-- =====================================================================
-- VISUALS | Advanced ESP (3D Box, Skeleton, Chams)
-- =====================================================================
local K = shared.KIRO
if not K then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local gameId = K.GameId or "unknown"

-- Chams (Highlight) storage
K.Highlights = K.Highlights or {}

local function getModels()
    local models = {}
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            table.insert(models, {model = plr.Character, player = plr})
            seen[plr.Character] = true
        end
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") then
            local m = d.Parent
            if m and m:IsA("Model") and m ~= LP.Character and not seen[m] then
                if LP.Character and m:IsDescendantOf(LP.Character) then continue end
                table.insert(models, {model = m, player = nil})
                seen[m] = true
            end
        end
    end
    return models
end

local function isEnemy(entry)
    if not K.GetSetting("ESP.TeamCheck") then return true end
    local plr = entry.player
    if plr then
        if plr.Team and LP.Team then return plr.Team ~= LP.Team end
        local pTeam = plr:GetAttribute("Team") or plr:GetAttribute("team")
        local lTeam = LP:GetAttribute("Team") or LP:GetAttribute("team")
        if pTeam and lTeam then return pTeam ~= lTeam end
    end
    local mTeam = entry.model:GetAttribute("Team") or entry.model:GetAttribute("team")
    local lTeam = LP:GetAttribute("Team") or LP:GetAttribute("team")
    if mTeam and lTeam then return mTeam ~= lTeam end
    return true
end

local function getParts(model)
    local head = model:FindFirstChild("Head") or model:FindFirstChild("head") or model:FindFirstChild("UpperTorso")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("LowerTorso") or head
    local hum = model:FindFirstChildOfClass("Humanoid")
    if head and hrp and hum and hum.Health > 0 then
        return head, hrp, hum
    end
    return nil
end

-- 3D Box: compute 8 corners
local function getBoxCorners(hrp, head)
    local size = hrp.Size
    local cf = hrp.CFrame
    local height = (head.Position - hrp.Position).Magnitude * 2
    local width = size.X
    local depth = size.Z
    local corners = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = cf * CFrame.new(x * width/2, y * height/2, z * depth/2)
                table.insert(corners, corner.Position)
            end
        end
    end
    return corners
end

-- Drawing storage
K.ESPObjects = K.ESPObjects or {}

local function newObj(t)
    local o = Drawing.new(t)
    o.Visible = false
    o.Thickness = 1
    o.Transparency = 1
    return o
end

local function getData(key)
    if not K.ESPObjects[key] then
        K.ESPObjects[key] = {
            -- 3D box lines (12 edges)
            lines = {},
            -- name
            name = newObj("Text"),
            -- distance
            dist = newObj("Text"),
            -- health bar
            hpBg = newObj("Square"),
            hpFg = newObj("Square"),
            -- skeleton lines
            skeleton = {},
        }
        K.ESPObjects[key].name.Size = 13
        K.ESPObjects[key].name.Center = true
        K.ESPObjects[key].name.Outline = true
        K.ESPObjects[key].dist.Size = 11
        K.ESPObjects[key].dist.Center = true
        K.ESPObjects[key].dist.Outline = true
        -- create 12 lines for 3D box
        for i = 1, 12 do
            local l = newObj("Line")
            l.Thickness = 1
            K.ESPObjects[key].lines[i] = l
        end
        -- create skeleton lines (head-torso, torso-arms, torso-legs)
        for i = 1, 8 do
            local l = newObj("Line")
            l.Thickness = 1
            K.ESPObjects[key].skeleton[i] = l
        end
    end
    return K.ESPObjects[key]
end

-- 3D box edges (indices into corners array)
local boxEdges = {
    {1,2},{1,3},{1,5},{2,4},{2,6},{3,4},{3,7},{4,8},{5,6},{5,7},{6,8},{7,8}
}

local function hideAll(o)
    for _, l in ipairs(o.lines) do l.Visible = false end
    for _, l in ipairs(o.skeleton) do l.Visible = false end
    o.name.Visible = false
    o.dist.Visible = false
    o.hpBg.Visible = false
    o.hpFg.Visible = false
end

-- Chams management
local function updateChams(entry, enabled)
    local model = entry.model
    if not K.GetSetting("ESP.Highlight") then
        -- remove highlight if exists
        if K.Highlights[model] then
            pcall(function() K.Highlights[model]:Destroy() end)
            K.Highlights[model] = nil
        end
        return
    end
    if not enabled then
        if K.Highlights[model] then
            pcall(function() K.Highlights[model]:Destroy() end)
            K.Highlights[model] = nil
        end
        return
    end
    if not K.Highlights[model] then
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(255, 60, 60)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = K.GetSetting("ESP.ChamsTransparency") or 0.7
        hl.OutlineTransparency = 0.3
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        K.Highlights[model] = hl
    end
end

RunService.RenderStepped:Connect(function()
    if not K.GetSetting("ESP.Enabled") then
        for _, o in pairs(K.ESPObjects) do hideAll(o) end
        -- hide all chams
        for model, hl in pairs(K.Highlights) do
            pcall(function() hl.Enabled = false end)
        end
        return
    end

    local models = getModels()
    local seen = {}

    for _, entry in ipairs(models) do
        local model = entry.model
        seen[model] = true
        local o = getData(model)

        if not isEnemy(entry) then
            hideAll(o)
            updateChams(entry, false)
            continue
        end

        local head, hrp, hum = getParts(model)
        if not head then
            hideAll(o)
            updateChams(entry, false)
            continue
        end

        updateChams(entry, true)

        local col = K.GetSetting("ESP.Color")
        if typeof(col) == "table" then col = Color3.fromRGB(col[1], col[2], col[3]) end
        if typeof(col) ~= "Color3" then col = Color3.fromRGB(255, 60, 60) end

        local label = (entry.player and entry.player.Name) or model.Name
        local dist = 0
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            dist = (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
        end

        local maxDist = K.GetSetting("ESP.MaxDist") or 500
        if dist > maxDist and dist > 0 then
            hideAll(o)
            continue
        end

        -- 3D Box
        if K.GetSetting("ESP.Box") then
            local corners = getBoxCorners(hrp, head)
            local screenCorners = {}
            local allOnScreen = true
            for _, c in ipairs(corners) do
                local sp, on = Camera:WorldToViewportPoint(c)
                if not on or sp.Z <= 0 then allOnScreen = false break end
                table.insert(screenCorners, sp)
            end
            if allOnScreen and #screenCorners == 8 then
                for i, edge in ipairs(boxEdges) do
                    local l = o.lines[i]
                    l.Visible = true
                    l.From = Vector2.new(screenCorners[edge[1]].X, screenCorners[edge[1]].Y)
                    l.To = Vector2.new(screenCorners[edge[2]].X, screenCorners[edge[2]].Y)
                    l.Color = col
                end
            else
                for _, l in ipairs(o.lines) do l.Visible = false end
            end
        else
            for _, l in ipairs(o.lines) do l.Visible = false end
        end

        -- Skeleton
        if K.GetSetting("ESP.Skeleton") then
            -- find body parts
            local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            local leftArm = model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("Left Arm")
            local rightArm = model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm")
            local leftLeg = model:FindFirstChild("LeftUpperLeg") or model:FindFirstChild("Left Leg")
            local rightLeg = model:FindFirstChild("RightUpperLeg") or model:FindFirstChild("Right Leg")

            local points = {head, torso, leftArm, rightArm, leftLeg, rightLeg}
            local idx = 1
            -- head to torso
            if torso then
                local sp1, on1 = Camera:WorldToViewportPoint(head.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(torso.Position)
                if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                    o.skeleton[idx].Visible = true
                    o.skeleton[idx].From = Vector2.new(sp1.X, sp1.Y)
                    o.skeleton[idx].To = Vector2.new(sp2.X, sp2.Y)
                    o.skeleton[idx].Color = col
                    idx = idx + 1
                end
            end
            -- torso to arms
            if torso and leftArm then
                local sp1, on1 = Camera:WorldToViewportPoint(torso.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(leftArm.Position)
                if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                    o.skeleton[idx].Visible = true
                    o.skeleton[idx].From = Vector2.new(sp1.X, sp1.Y)
                    o.skeleton[idx].To = Vector2.new(sp2.X, sp2.Y)
                    o.skeleton[idx].Color = col
                    idx = idx + 1
                end
            end
            if torso and rightArm then
                local sp1, on1 = Camera:WorldToViewportPoint(torso.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(rightArm.Position)
                if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                    o.skeleton[idx].Visible = true
                    o.skeleton[idx].From = Vector2.new(sp1.X, sp1.Y)
                    o.skeleton[idx].To = Vector2.new(sp2.X, sp2.Y)
                    o.skeleton[idx].Color = col
                    idx = idx + 1
                end
            end
            -- torso to legs
            if torso and leftLeg then
                local sp1, on1 = Camera:WorldToViewportPoint(torso.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(leftLeg.Position)
                if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                    o.skeleton[idx].Visible = true
                    o.skeleton[idx].From = Vector2.new(sp1.X, sp1.Y)
                    o.skeleton[idx].To = Vector2.new(sp2.X, sp2.Y)
                    o.skeleton[idx].Color = col
                    idx = idx + 1
                end
            end
            if torso and rightLeg then
                local sp1, on1 = Camera:WorldToViewportPoint(torso.Position)
                local sp2, on2 = Camera:WorldToViewportPoint(rightLeg.Position)
                if on1 and on2 and sp1.Z > 0 and sp2.Z > 0 then
                    o.skeleton[idx].Visible = true
                    o.skeleton[idx].From = Vector2.new(sp1.X, sp1.Y)
                    o.skeleton[idx].To = Vector2.new(sp2.X, sp2.Y)
                    o.skeleton[idx].Color = col
                    idx = idx + 1
                end
            end
            -- hide remaining
            for i = idx, #o.skeleton do o.skeleton[i].Visible = false end
        else
            for _, l in ipairs(o.skeleton) do l.Visible = false end
        end

        -- Name + HP
        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if K.GetSetting("ESP.Name") then
            o.name.Visible = true
            o.name.Text = label .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
            o.name.Color = col
            o.name.Position = Vector2.new(headPos.X, headPos.Y - 20)
        else
            o.name.Visible = false
        end

        -- Distance
        if K.GetSetting("ESP.Distance") then
            o.dist.Visible = true
            o.dist.Text = string.format("%d m", math.floor(dist))
            o.dist.Color = col
            o.dist.Position = Vector2.new(headPos.X, headPos.Y + 20)
        else
            o.dist.Visible = false
        end

        -- Health bar
        if K.GetSetting("ESP.Health") then
            local hrpPos = Camera:WorldToViewportPoint(hrp.Position)
            local height = math.abs(hrpPos.Y - headPos.Y) * 2
            local frac = hum.Health / hum.MaxHealth
            o.hpBg.Visible = true
            o.hpBg.Color = Color3.fromRGB(30, 30, 30)
            o.hpBg.Size = Vector2.new(4, height)
            o.hpBg.Position = Vector2.new(headPos.X - width/2 - 8, headPos.Y)
            o.hpBg.Filled = true
            o.hpFg.Visible = true
            o.hpFg.Color = Color3.fromRGB(60, 255, 120):Lerp(Color3.fromRGB(255, 60, 60), 1 - frac)
            o.hpFg.Size = Vector2.new(4, height * frac)
            o.hpFg.Position = Vector2.new(headPos.X - width/2 - 8, headPos.Y + height * (1 - frac))
            o.hpFg.Filled = true
        else
            o.hpBg.Visible = false
            o.hpFg.Visible = false
        end

        -- Loot ESP for Fust (chests/resources)
        if gameId == "fust" and K.GetSetting("ESP.ShowWPCs") then
            -- scan for chests in workspace
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("chest") or obj.Name:lower():find("loot") or obj.Name:lower():find("barrel") then
                    -- draw simple marker
                    -- (simplified: just log)
                end
            end
        end
    end

    -- cleanup
    for key, o in pairs(K.ESPObjects) do
        if not seen[key] then
            hideAll(o)
            if K.Highlights[key] then
                pcall(function() K.Highlights[key]:Destroy() end)
                K.Highlights[key] = nil
            end
        end
    end
end)

-- Bomb Timer (cs_go)
if gameId == "cs_go" then
    task.spawn(function()
        while task.wait(0.5) do
            if not K.GetSetting("ESP.Enabled") then continue end
            for _, obj in ipairs(workspace:GetDescendants()) do
                local name = obj.Name:lower()
                if name:find("bomb") or name:find("c4") then
                    if obj:IsA("BasePart") then
                        -- marker drawn (simplified)
                    end
                end
            end
        end
    end)
end

-- Viewmodel Changer (cs_go)
if gameId == "cs_go" then
    task.spawn(function()
        while task.wait(1) do
            if not K.GetSetting("VisualExtras.ViewmodelChams") then continue end
            local cam = workspace.CurrentCamera
            if cam then
                for _, v in ipairs(cam:GetChildren()) do
                    if v:IsA("Model") or v:IsA("BasePart") then
                        for _, d in ipairs(v:GetDescendants()) do
                            if d:IsA("BasePart") then
                                pcall(function()
                                    d.Color = Color3.fromRGB(100, 160, 240)
                                    d.Material = Enum.Material.Neon
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end
Players.PlayerRemoving:Connect(function(plr)
    local o = K.ESPObjects[plr]
    if o then
        for _, v in pairs(o) do
            if type(v) == "table" then
                for _, l in ipairs(v) do pcall(function() l:Remove() end) end
            else pcall(function() v:Remove() end) end
        end
        K.ESPObjects[plr] = nil
    end
    if K.Highlights[plr.Character] then
        pcall(function() K.Highlights[plr.Character]:Destroy() end)
        K.Highlights[plr.Character] = nil
    end
end)

print("[KIRO VISUALS] Advanced ESP loaded. Game: " .. gameId)
