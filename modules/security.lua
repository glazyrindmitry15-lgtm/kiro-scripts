-- KIRO HACK | ADVANCED SECURITY MODULE
local K = shared.KIRO
if not K then return end
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- 1. СПУФИНГ СВОЙСТВ (Обманываем античит, если он проверяет скорость или размер)
-- Античит видит стандартные значения, даже если ты изменил их в чите.
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() then
        if typeof(self) == "Instance" then
            -- Если античит проверяет скорость (WalkSpeed)
            if self:IsA("Humanoid") and (key == "WalkSpeed" or key == "JumpPower") then
                return 16 -- Возвращаем стандартную скорость
            end
            -- Если античит ищет наши Drawing (ESP линии)
            if key == "Parent" and self:IsA("Drawing") then
                return nil 
            end
        end
    end
    return oldIndex(self, key)
end)

-- 2. БЛОКИРОВКА КИКА (Если сервер пытается нас кикнуть, мы просто игнорируем это)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() then
        -- Блокируем вызов Kick для нашего игрока
        if method == "Kick" and self == LP then
            K.Notify("SECURITY", "Античит пытался кикнуть, действие заблокировано!", true)
            return 
        end
    end
    return oldNamecall(self, ...)
end)

-- 3. ЗАЩИТА ОТ ПАЛЕВА ПРИ ТЕЛЕПОРТЕ
-- Если ты используешь телепорт, античит может это заметить. Мы дробим движение на микрошаги.
function SafeTeleport(targetCFrame)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local oldPos = hrp.Position
    local newPos = targetCFrame.Position
    local distance = (newPos - oldPos).Magnitude
    
    -- Если расстояние большое, движемся рывками (античит не заметит)
    if distance > 50 then
        local steps = math.floor(distance / 20)
        for i = 1, steps do
            hrp.CFrame = CFrame.new(oldPos:Lerp(newPos, i / steps))
            task.wait(0.05)
        end
        hrp.CFrame = targetCFrame
    else
        hrp.CFrame = targetCFrame
    end
end

-- 4. ОЧИСТКА МУСОРА (Удаляем следы читов из памяти)
task.spawn(function()
    while task.wait(5) do
        -- Удаляем невидимые объекты, которые создает ESP
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Part") and obj.Name == "KIRO_ESP_TRACER" then
                obj:Destroy()
            end
        end
    end
end)

print("[KIRO SECURITY] Продвинутый модуль защиты активирован.")
