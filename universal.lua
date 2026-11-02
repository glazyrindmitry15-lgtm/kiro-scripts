-- KIRO MODULE LOADER
print("[KIRO LOADER] Запуск модульной системы...")

local GITHUB_BASE = "https://raw.githubusercontent.com/glazyrindmitry15-lgtm/kiro-scripts/main/"

local Modules = {
    "config.lua",
    "modules/security.lua", -- Античит грузится первым
    "modules/ui.lua",
    "modules/aimbot.lua",
    "modules/esp.lua",
    "modules/misc.lua"
}

for _, mod in ipairs(Modules) do
    local url = GITHUB_BASE .. mod
    print("[KIRO LOADER] Скачивание модуля: " .. mod)
    
    local ok, code = pcall(game.HttpGet, game, url)
    if not ok or not code or code == "" then
        warn("[KIRO LOADER] ОШИБКА: Не удалось скачать " .. mod)
    else
        local fn, err = loadstring(code)
        if not fn then
            warn("[KIRO LOADER] ОШИБКА КОМПИЛЯЦИИ в " .. mod .. ": " .. tostring(err))
        else
            local success, runErr = pcall(fn)
            if not success then
                warn("[KIRO LOADER] ОШИБКА ВЫПОЛНЕНИЯ в " .. mod .. ": " .. tostring(runErr))
                -- Тут нет 'return'! Если модуль сломается, лоадер пойдет дальше
            end
        end
    end
end

print("[KIRO HACK] Загрузка завершена!")
