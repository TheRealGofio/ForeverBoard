--[[
    ForeverBoard - Core
    Lógica de comunicación y sincronización de red entre miembros del grupo/raid.
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

FB.ADDON_PREFIX = "ForeverBoard"
FB.SOUND_PATH = "Interface\\AddOns\\ForeverBoard\\sounds\\"
FB.COOLDOWN = 1.5 -- Segundos de margen entre sonidos para evitar saturación
FB.lastPlayed = 0

-- Mapa rápido id -> sonido
FB.soundMap = {}
function FB:InitSoundMap()
    for _, sound in ipairs(ForeverBoard_Sounds or {}) do
        self.soundMap[sound.id] = sound
    end
end

-- Registro de prefijo para comunicación interna de addons
function FB:RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(self.ADDON_PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(self.ADDON_PREFIX)
    end
end

-- Envío de mensaje invisible al grupo/banda
function FB:Broadcast(soundId)
    local chatType = nil
    if IsInRaid and IsInRaid() then
        chatType = "RAID"
    elseif IsInGroup and IsInGroup() then
        chatType = "PARTY"
    end

    if chatType then
        local payload = "PLAY:" .. soundId
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
        elseif SendAddonMessage then
            SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
        end
    end
end

-- Reproduce un sonido localmente
function FB:PlaySound(soundId, sender)
    local sound = self.soundMap[soundId]
    if not sound then
        return false
    end

    local now = GetTime()
    if now - self.lastPlayed < self.COOLDOWN then
        return false
    end
    self.lastPlayed = now

    local fullPath = self.SOUND_PATH .. sound.file
    local played = PlaySoundFile(fullPath, "Master")
    if not played then
        PlaySoundFile(fullPath)
    end

    local displayName = sender or UnitName("player") or "Tú"
    print(string.format("|cff00ccff[ForeverBoard]|r |cffffffff%s|r ha reproducido: |cffffe066%s|r", displayName, sound.name))

    return true
end

-- Gatillo manual (local + emitir a grupo/raid)
function FB:TriggerSound(soundId)
    if not self.soundMap[soundId] then
        print("|cff00ccff[ForeverBoard]|r Sonido no encontrado: " .. tostring(soundId))
        return
    end

    local ok = self:PlaySound(soundId, nil)
    if ok then
        self:Broadcast(soundId)
    end
end

-- Frame principal de eventos
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        FB:InitSoundMap()
        FB:RegisterPrefix()

        -- Base de datos guardada
        ForeverBoardDB = ForeverBoardDB or {
            posX = 200,
            posY = -200,
            point = "TOPLEFT",
            width = 280,
            height = 380,
            scale = 1.0,
            minimapPos = 45,
        }
        if ForeverBoardDB.minimapPos == nil then
            ForeverBoardDB.minimapPos = 45
        end

        if FB.CreateMinimapButton then
            FB:CreateMinimapButton()
        end

        print("|cff00ccff[ForeverBoard]|r Addon cargado. Escribe |cffffffff/fb|r o |cffffffff/foreverboard|r para abrir el SoundBoard.")

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == FB.ADDON_PREFIX then
            local senderName = sender and strsplit("-", sender)
            local myName = UnitName("player")

            -- Ignorar nuestro propio eco si el cliente lo reenvía
            if senderName and myName and senderName ~= myName then
                if message and message:find("^PLAY:") then
                    local soundId = message:sub(6)
                    FB:PlaySound(soundId, senderName)
                end
            end
        end
    end
end)

-- Comandos de chat (/fb o /foreverboard)
SLASH_FOREVERBOARD1 = "/fb"
SLASH_FOREVERBOARD2 = "/foreverboard"
SlashCmdList["FOREVERBOARD"] = function(msg)
    msg = msg and msg:trim() or ""
    if msg == "" then
        FB:ToggleUI()
    elseif msg:find("^play ") then
        local soundId = msg:sub(6):trim()
        FB:TriggerSound(soundId)
    elseif msg == "list" then
        print("|cff00ccff[ForeverBoard]|r Lista de sonidos disponibles:")
        for _, s in ipairs(ForeverBoard_Sounds or {}) do
            print(string.format(" - |cffffffff%s|r (|cffffe066%s|r): %s", s.id, s.name, s.desc or ""))
        end
    else
        print("|cff00ccff[ForeverBoard]|r Uso:")
        print(" /fb - Abre/cierra la ventana del SoundBoard")
        print(" /fb play <id> - Reproduce un sonido directamente por ID")
        print(" /fb list - Lista los IDs de sonido configurados")
    end
end
