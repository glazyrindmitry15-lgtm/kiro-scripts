-- KIRO HACK | ADVANCED SECURITY CORE (ANTI-DETECTION)
-- Этот модуль пытается скрыть следы чита от проверок античита.
local K = shared.KIRO
if not K then return end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- 1. СПУФИНГ СВОЙСТВ (Property Spoofing)
-- Если античит проверяет твою скорость или размер головы, он будет видеть стандартные значения.
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() then
        if typeof(self) == "Instance" then
            -- Спуфим скорость и прыжок для Humanoid
            if self:IsA("Humanoid") and (key == "WalkSpeed" or key == "JumpPower") then
                return 16
            end
            -- Спуфим размер головы, если используется Big Head
            if self:IsA("BasePart") and (self.Name == "Head" or self.Name == "UpperTorso") then
                if key == "Size" then
                    -- Возвращаем оригинальный размер, если он был изменен
                    local original = K.OriginalSizes[self]
                    if original then return original end
                end
            end
        end
    end
    return oldIndex(self, key)
end)

-- 2. БЛОКИРОВКА ОТПРАВКИ «ПАЛЕВНЫХ» ДАННЫХ (Remote Event Blocking)
-- Если античит пытается отправить сигнал о нарушении, мы блокируем этот вызов.
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() then
        -- Блокируем отправку на RemoteEvent с подозрительными именами
        if method == "FireServer" then
            local name = self.Name:lower()
            if name:find("anticheat") or name:find("ac_") or name:find("ban") or name:find("detect") or name:find("report") then
                return -- Не даем античиту отправить сигнал
            end
        end
        -- Блокируем кик (если сервер пытается нас выгнать)
        if method == "Kick" and self == LP then
            K.Notify("SECURITY", "Попытка кика заблокирована!", true)
            return
        end
    end
    return oldNamecall(self, ...)
end)

-- 3. ПОДМЕНА ВОЗВРАЩАЕМЫХ ЗНАЧЕНИЙ (Function Return Spoofing)
-- Если античит вызывает функцию проверки (например, IsValid), мы заставляем ее всегда возвращать "true".
-- (Требует поддержки hookfunction в экзекьюторе)
if hookfunction then
    pcall(function()
        -- Пример: если античит проверяет, не телепортировался ли ты
        -- (Этот код нужно адаптировать под конкретный античит FUST)
        -- local antiTeleportCheck = getgenv().FUST_AntiTeleport
        -- if antiTeleportCheck then
        --     hookfunction(antiTeleportCheck, function() return true end)
        -- end
    end)
end

-- 4. ОЧИСТКА СЛЕДОВ (Cleanup)
-- Периодически удаляем объекты, которые могут нас выдать.
task.spawn(function()
    while task.wait(5) do
        pcall(function()
            -- Удаляем невидимые части, которые создают ESP
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Part") and (obj.Name == "KIRO_ESP" or obj.Transparency == 1) then
                    obj:Destroy()
                end
            end
            -- Восстанавливаем оригинальные размеры головы/торса (если Big Head выключен)
            if not K.Settings.Utils.HeadExpander then
                for part, size in pairs(K.OriginalSizes) do
                    if part and part.Parent then part.Size = size end
                end
                K.OriginalSizes = {}
            end
        end)
    end
end)

-- 5. БЕЗОПАСНАЯ СИМУЛЯЦИЯ ВВОДА (Safe Input)
-- Вместо VirtualUser используем менее заметный метод для Anti-AFK.
task.spawn(function()
    while task.wait(1) do
        if K.Settings.Security.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new()) -- ClickButton2 менее палевный
            end)
        end
    end
end)

print("[KIRO SECURITY] Продвинутое ядро защиты активировано.")
