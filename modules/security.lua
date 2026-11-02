-- =====================================================================
-- KIRO HACK | ULTIMATE BYPASS CORE (COMBINED METHODS)
-- Внимание: используйте только на свой страх и риск.
-- =====================================================================
local K = shared.KIRO
if not K then return end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- 1. СПУФИНГ СВОЙСТВ (Property Spoofing)
-- Античит видит стандартные WalkSpeed/JumpPower, даже если чит изменил их.
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        if typeof(self) == "Instance" then
            if self:IsA("Humanoid") and (key == "WalkSpeed" or key == "JumpPower") then
                return 16
            end
            if self:IsA("BasePart") and key == "Size" and K.OriginalSizes[self] then
                return K.OriginalSizes[self]
            end
        end
    end
    return oldIndex(self, key)
end))

-- 2. БЛОКИРОВКА REMOTE-СОБЫТИЙ АНТИЧИТА (Remote Blocking)
-- Блокируем отправку логов о нарушениях на сервер.
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and method == "FireServer" then
        local name = self.Name:lower()
        if name:find("anticheat") or name:find("ac_") or name:find("detect") or name:find("ban") or name:find("report") then
            return -- Сигнал не уходит
        end
    end
    return oldNamecall(self, ...)
end))

-- 3. ХУК ФУНКЦИЙ АНТИЧИТА (Function Hooking)
-- Делаем проверки античита всегда "успешными".
if hookfunction and getgc then
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "function" then
                local info = debug.getinfo(obj)
                if info and info.name and info.name:lower():find("anticheat") then
                    hookfunction(obj, function() return true end)
                end
            end
        end
    end)
end

-- 4. ДЕСИНК (Desync) – Phantom Positioning
-- Создаём рассинхрон между реальной позицией и той, что видят другие.
-- (Используем технику с setfflag, если экзекьютор поддерживает)
pcall(function()
    if setfflag then
        setfflag("WorldStepMax", "-9999999999")
        task.wait(1)
        setfflag("WorldStepMax", "-1")
    end
end)

-- 5. ОГРАНИЧЕНИЕ ДЕЛЬТЫ ДВИЖЕНИЯ (Movement Delta Clamp)
-- Не даём серверу увидеть рывки скорости. Плавно "размазываем" движение.
local lastPos = {}
RunService.Heartbeat:Connect(function(dt)
    pcall(function()
        local char = LP.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local last = lastPos[hrp]
                if last then
                    local delta = (currentPos - last).Magnitude
                    local maxAllowed = 50 * dt -- Порог, можно настроить
                    if delta > maxAllowed then
                        hrp.CFrame = CFrame.new(last + (currentPos - last).Unit * maxAllowed)
                    end
                end
                lastPos[hrp] = hrp.Position
            end
        end
    end)
end)

-- 6. БЕЗОПАСНЫЙ ANTI-AFK
task.spawn(function()
    while task.wait(1) do
        if K.Settings.Security.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

print("[KIRO SECURITY] ULTIMATE BYPASS CORE активирован.")
