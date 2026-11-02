-- =====================================================================
-- KIRO MODULE LOADER (ENCRYPTED EDITION)
-- =====================================================================
print("[KIRO LOADER] Инициализация секретного загрузчика...")

local GITHUB_BASE = "https://raw.githubusercontent.com/glazyrindmitry15-lgtm/kiro-scripts/main/"
local SECRET_KEY = "KiroSecretKey2026" -- Твой секретный ключ (должен совпадать с ключом в шифраторе)

-- =====================================================================
-- ФУНКЦИИ РАСШИФРОВКИ (Base64 + XOR)
-- =====================================================================
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function xor(str, key)
    local res = ""
    for i = 1, #str do
        res = res .. string.char(bit32.bxor(string.byte(str, i), string.byte(key, (i - 1) % #key + 1)))
    end
    return res
end

-- =====================================================================
-- СПИСОК МОДУЛЕЙ
-- =====================================================================
local Modules = {
    "config.lua",
    "modules/protector.lua", -- Наш протектор грузится первым
    "modules/security.lua",
    "modules/ui.lua",
    "modules/aimbot.lua",
    "modules/esp.lua",
    "modules/misc.lua"
}

-- =====================================================================
-- ПРОЦЕСС ЗАГРУЗКИ
-- =====================================================================
for _, mod in ipairs(Modules) do
    local url = GITHUB_BASE .. mod
    print("[KIRO LOADER] Скачивание зашифрованного модуля: " .. mod)
    
    local ok, code = pcall(game.HttpGet, game, url)
    if not ok or not code or code == "" then
        warn("[KIRO LOADER] ОШИБКА: Не удалось скачать " .. mod)
    else
        -- Проверяем, зашифрован ли файл (начинается с "ENC:")
        if string.sub(code, 1, 4) == "ENC:" then
            -- Если зашифрован, отрезаем приставку "ENC:" и расшифровываем
            local encrypted_payload = string.sub(code, 5)
            local decoded = dec(encrypted_payload)
            code = xor(decoded, SECRET_KEY)
        end
        
        -- Компилируем и запускаем
        local fn, err = loadstring(code)
        if not fn then
            warn("[KIRO LOADER] ОШИБКА КОМПИЛЯЦИИ в " .. mod .. ": " .. tostring(err))
        else
            local success, runErr = pcall(fn)
            if not success then
                warn("[KIRO LOADER] ОШИБКА ВЫПОЛНЕНИЯ в " .. mod .. ": " .. tostring(runErr))
            end
        end
    end
end

print("[KIRO HACK] Все модули успешно загружены в память!")
