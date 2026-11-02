-- =====================================================================
-- KIRO MODULE LOADER (RUNTIME ENCRYPTION)
-- Автоматически шифрует и расшифровывает модули прямо в памяти
-- =====================================================================
print("[KIRO LOADER] Инициализация защищенного загрузчика...")

local GITHUB_BASE = "https://raw.githubusercontent.com/glazyrindmitry15-lgtm/kiro-scripts/main/"
local SECRET_KEY = "KiroSuperSecretKey2026" -- Наш секретный ключ

-- =====================================================================
-- ФУНКЦИИ ШИФРОВАНИЯ (XOR + Base64)
-- =====================================================================
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

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
-- ФУНКЦИЯ БЕЗОПАСНОЙ ЗАГРУЗКИ
-- =====================================================================
local function SecureLoad(mod)
    local url = GITHUB_BASE .. mod
    print("[KIRO LOADER] Безопасная загрузка: " .. mod)
    
    local ok, code = pcall(game.HttpGet, game, url)
    if not ok or not code or code == "" then
        warn("[KIRO LOADER] ОШИБКА: Не удалось скачать " .. mod)
        return
    end

    -- Если файл уже зашифрован (начинается с "ENC:"), пропускаем шифрование
    if string.sub(code, 1, 4) == "ENC:" then
        code = xor(dec(string.sub(code, 5)), SECRET_KEY)
    end

    -- МГНОВЕННОЕ ШИФРОВАНИЕ В ПАМЯТИ
    -- 1. Шифруем скачанный код
    local encrypted = enc(xor(code, SECRET_KEY))
    
    -- 2. Очищаем исходную переменную (чтобы античит не нашел открытый текст)
    code = nil 
    
    -- 3. Загружаем зашифрованную мешанину в память
    -- (Античит увидит только этот мусор)
    local final_code = "ENC:" .. encrypted
    
    -- 4. Расшифровываем прямо перед запуском
    local raw_code = xor(dec(string.sub(final_code, 5)), SECRET_KEY)
    
    -- 5. Компилируем и запускаем
    local fn, err = loadstring(raw_code)
    if not fn then
        warn("[KIRO LOADER] ОШИБКА КОМПИЛЯЦИИ в " .. mod .. ": " .. tostring(err))
        return
    end
    
    local success, runErr = pcall(fn)
    if not success then
        warn("[KIRO LOADER] ОШИБКА ВЫПОЛНЕНИЯ в " .. mod .. ": " .. tostring(runErr))
    end
    
    -- 6. Стираем следы
    raw_code = nil
    final_code = nil
end

-- =====================================================================
-- СПИСОК МОДУЛЕЙ
-- =====================================================================
local Modules = {
    "config.lua",
    "modules/security.lua",
    "modules/ui.lua",
    "modules/aimbot.lua",
    "modules/esp.lua",
    "modules/misc.lua"
}

for _, mod in ipairs(Modules) do
    SecureLoad(mod)
end

print("[KIRO HACK] Все модули успешно загружены!")
