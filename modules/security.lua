-- KIRO HACK | SECURITY MODULE (ANTI-DETECTION)
local K = shared.KIRO
if not K then return end

local function ProtectGUI(gui)
    if syn and syn.protect_gui then syn.protect_gui(gui)
    elseif gethui then gui.Parent = gethui() end
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() then
        if method == "FindFirstChild" or method == "FindFirstChildWhichIsA" then
            if args[1] == "KIRO_UI" or (args[1] == "ScreenGui" and self == game:GetService("CoreGui")) then
                return nil
            end
        end
        if method == "FireServer" and self.Name == "AnticheatRemote" then
            return
        end
    end
    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        if key == "WalkSpeed" or key == "JumpPower" then
            return 16
        end
    end
    return oldIndex(self, key)
end))

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

print("[KIRO SECURITY] Анти-детект модуль активирован.")
