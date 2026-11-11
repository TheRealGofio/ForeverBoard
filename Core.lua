--[[
    ForeverBoard - Core
    Lógica de comunicación y sincronización de red entre miembros del grupo/raid.
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

FB.ADDON_PREFIX = "ForeverBoard"
FB.VERSION = "1.2.0"
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
        local sound = self.soundMap[soundId]
        local soundName = sound and sound.name or soundId
        local payload = string.format("PLAY:%s:%s", soundId, soundName)
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
        elseif SendAddonMessage then
            SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
        end
    end
end

-- Envío de petición de versión
function FB:CheckVersions()
    local L = self.L or {}
    local chatType = nil
    if IsInRaid and IsInRaid() then
        chatType = "RAID"
    elseif IsInGroup and IsInGroup() then
        chatType = "PARTY"
    end

    if not chatType then
        print(L["NOT_IN_GROUP"] or "|cff00ccff[ForeverBoard]|r No estás en un grupo ni en banda.")
        return
    end

    print(L["CHECKING_VERSIONS"] or "|cff00ccff[ForeverBoard]|r Comprobando versiones de ForeverBoard en el grupo/raid...")
    local payload = "VER_REQ"
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
    elseif SendAddonMessage then
        SendAddonMessage(self.ADDON_PREFIX, payload, chatType)
    end
end

-- Reproduce un sonido localmente
function FB:PlaySound(soundId, sender, fallbackName)
    local db = ForeverBoardDB or {}
    local L = self.L or {}

    -- Comprobar si está silenciado
    if db.isMuted then
        return false
    end

    -- Comprobar silenciar en combate
    if db.muteInCombat and InCombatLockdown and InCombatLockdown() then
        return false
    end

    local sound = self.soundMap[soundId]
    if not sound then
        local displayName = sender or "Alguien"
        local clipName = fallbackName or soundId
        local tpl = L["MISSING_SOUND"] or "|cff00ccff[ForeverBoard]|r |cffffffff%s|r ha lanzado |cffffe066%s|r (|cffff9900No tienes este archivo en tu carpeta sounds|r)"
        print(string.format(tpl, displayName, clipName))
        return false
    end

    local now = GetTime()
    if now - self.lastPlayed < self.COOLDOWN then
        return false
    end
    self.lastPlayed = now

    local channel = db.soundChannel or "Master"
    local fullPath = self.SOUND_PATH .. sound.file
    local played = PlaySoundFile(fullPath, channel)
    if not played and channel ~= "Master" then
        PlaySoundFile(fullPath, "Master")
    end

    local displayName = sender or UnitName("player") or "Tú"
    local tplPlayed = L["SOUND_PLAYED"] or "|cff00ccff[ForeverBoard]|r |cffffffff%s|r ha reproducido: |cffffe066%s|r"
    print(string.format(tplPlayed, displayName, sound.name))

    return true
end

-- Gatillo manual (local + emitir a grupo/raid)
function FB:TriggerSound(soundId)
    local L = self.L or {}
    if not self.soundMap[soundId] then
        print((L["SOUND_NOT_FOUND"] or "|cff00ccff[ForeverBoard]|r Sonido no encontrado: ") .. tostring(soundId))
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
        ForeverBoardDB = ForeverBoardDB or {}
        local defaults = {
            posX = 200,
            posY = -200,
            point = "TOPLEFT",
            width = 280,
            height = 420,
            scale = 1.0,
            minimapPos = 45,
            isMuted = false,
            muteInCombat = false,
            soundChannel = "Master",
            favorites = {},
            -- Triggers automáticos
            triggerLevelUp = true,
            triggerLevelUpSound = "",
            triggerDeath = false,
            triggerDeathSound = "",
            triggerBossKill = true,
            triggerBossKillSound = "",
            triggerLoot = true,
            triggerLootSound = "",
            triggerLootIncludeGreens = false,
        }
        for k, v in pairs(defaults) do
            if ForeverBoardDB[k] == nil then
                ForeverBoardDB[k] = v
            end
        end

        if FB.CreateMinimapButton then
            FB:CreateMinimapButton()
        end
        if FB.RegisterAutoTriggers then
            FB:RegisterAutoTriggers()
        end

        print("|cff00ccff[ForeverBoard]|r Addon cargado. Escribe |cffffffff/fb|r o |cffffffff/foreverboard|r para abrir el SoundBoard.")

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == FB.ADDON_PREFIX then
            local senderName = sender and strsplit("-", sender)
            local myName = UnitName("player")

            -- Mensaje de petición de versión
            if message == "VER_REQ" then
                local reply = string.format("VER_RESP:%s", FB.VERSION or "1.0.0")
                if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                    C_ChatInfo.SendAddonMessage(FB.ADDON_PREFIX, reply, channel or "PARTY")
                elseif SendAddonMessage then
                    SendAddonMessage(FB.ADDON_PREFIX, reply, channel or "PARTY")
                end
                return
            end

            -- Respuesta de versión recibida
            if message and message:find("^VER_RESP:") then
                local version = message:sub(10)
                local senderDisplay = senderName or sender or "Desconocido"
                print(string.format("|cff00ccff[ForeverBoard]|r |cffffffff%s|r tiene la versión: |cff00ff00v%s|r", senderDisplay, version))
                return
            end

            -- Ignorar nuestro propio eco si el cliente lo reenvía
            if senderName and myName and senderName ~= myName then
                if message and message:find("^PLAY:") then
                    -- Formato: PLAY:<soundId>[:<soundName>]
                    local payload = message:sub(6)
                    local sId, sName = strsplit(":", payload)
                    FB:PlaySound(sId, senderName, sName)
                end
            end
        end
    end
end)

-- ==========================================================
-- Triggers automáticos por eventos del juego
-- ==========================================================
function FB:GetFirstValidSound()
    local sounds = ForeverBoard_Sounds or {}
    if #sounds > 0 then
        return sounds[1].id
    end
    return nil
end

function FB:GetDefaultTriggerSound(triggerType)
    if ForeverBoard_DefaultTriggers and ForeverBoard_DefaultTriggers[triggerType] then
        local defId = ForeverBoard_DefaultTriggers[triggerType]
        if self.soundMap and self.soundMap[defId] then
            return defId
        end
    end
    return self:GetFirstValidSound()
end

function FB:FireAutoTrigger(soundId, reason, triggerType)
    if not soundId or soundId == "" then
        soundId = self:GetDefaultTriggerSound(triggerType)
    end

    if soundId and self.soundMap[soundId] then
        print(string.format("|cff00ccff[ForeverBoard Trigger]|r %s", reason))
        self:TriggerSound(soundId)
    end
end

local triggerFrame = CreateFrame("Frame")
function FB:RegisterAutoTriggers()
    triggerFrame:RegisterEvent("PLAYER_LEVEL_UP")
    triggerFrame:RegisterEvent("PLAYER_DEAD")
    triggerFrame:RegisterEvent("BOSS_KILL")
    triggerFrame:RegisterEvent("ENCOUNTER_END")
    triggerFrame:RegisterEvent("START_LOOT_ROLL")
    triggerFrame:RegisterEvent("CHAT_MSG_LOOT")
    triggerFrame:RegisterEvent("CHAT_MSG_SYSTEM")

    local lastDeadTime = 0
    local lastBossKillTime = 0
    local lastLootTime = 0

    local function CheckAndFireLoot(itemLink, rawMsg)
        if not itemLink then return end
        local itemName, _, itemRarity = GetItemInfo(itemLink)

        -- Si no hay itemRarity por GetItemInfo (no en cache), extraer por color hex
        if not itemRarity then
            local hexColor = (itemLink and itemLink:match("|c(%x%x%x%x%x%x%x%x)"))
                          or (rawMsg and rawMsg:match("|c(%x%x%x%x%x%x%x%x)"))
            if hexColor then
                hexColor = hexColor:lower()
                if hexColor == "ffa335ee" then -- Épico
                    itemRarity = 4
                elseif hexColor == "ff0070dd" then -- Raro (Azul)
                    itemRarity = 3
                elseif hexColor == "ff1eff00" then -- Poco común (Verde)
                    itemRarity = 2
                elseif hexColor == "ffff8000" then -- Legendario
                    itemRarity = 5
                elseif hexColor == "ffe6cc80" then -- Reliquia
                    itemRarity = 7
                end
            end
        end

        local db = ForeverBoardDB or {}
        local minRarity = db.triggerLootIncludeGreens and 2 or 3
        if itemRarity and itemRarity >= minRarity then
            local now = GetTime()
            if now - lastLootTime > 4 then
                lastLootTime = now
                local nameStr = itemName or itemLink
                local msg = string.format(FB.L["TRIG_ALERT_LOOT"] or "¡Botín disponible: %s!", nameStr)
                FB:FireAutoTrigger(db.triggerLootSound, msg, "loot")
            end
        end
    end

    triggerFrame:SetScript("OnEvent", function(self, event, ...)
        local db = ForeverBoardDB or {}

        if event == "PLAYER_LEVEL_UP" then
            if db.triggerLevelUp then
                local newLevel = ...
                local msg = string.format(FB.L["TRIG_ALERT_LEVEL"] or "¡Subida al nivel %s!", tostring(newLevel))
                FB:FireAutoTrigger(db.triggerLevelUpSound, msg, "levelUp")
            end

        elseif event == "PLAYER_DEAD" then
            local now = GetTime()
            if db.triggerDeath and (now - lastDeadTime > 10) then
                lastDeadTime = now
                local msg = FB.L["TRIG_ALERT_DEAD"] or "¡Has muerto!"
                FB:FireAutoTrigger(db.triggerDeathSound, msg, "death")
            end

        elseif event == "BOSS_KILL" or event == "ENCOUNTER_END" then
            local now = GetTime()
            if db.triggerBossKill and (now - lastBossKillTime > 15) then
                local success = true
                if event == "ENCOUNTER_END" then
                    local encounterID, encounterName, difficultyID, groupSize, successFlag = ...
                    success = (successFlag == 1)
                end

                if success then
                    lastBossKillTime = now
                    local msg = FB.L["TRIG_ALERT_BOSS"] or "¡Jefe de mazmorra o banda derrotado!"
                    FB:FireAutoTrigger(db.triggerBossKillSound, msg, "bossKill")
                end
            end

        elseif event == "START_LOOT_ROLL" then
            -- Salta cuando la ventana de dados (Necesidad / Codicia) aparece en pantalla
            if db.triggerLoot then
                local rollID = ...
                if rollID and GetLootRollItemLink then
                    local rollLink = GetLootRollItemLink(rollID)
                    if rollLink then
                        CheckAndFireLoot(rollLink, rollLink)
                    end
                end
            end

        elseif event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_SYSTEM" then
            if db.triggerLoot then
                local message = ...
                if message and type(message) == "string" and message:find("|Hitem:") then
                    local itemLink = message:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]h|r)")
                                  or message:match("(|c%x+|Hitem:[^|]+|h.-|h|r)")
                                  or message:match("(|Hitem:[^|]+|h%[[^%]]+%]h)")
                                  or message:match("(|Hitem:[^|]+|h.-|h)")

                    if itemLink then
                        CheckAndFireLoot(itemLink, message)
                    end
                end
            end
        end
    end)
end
SLASH_FOREVERBOARD1 = "/fb"
SLASH_FOREVERBOARD2 = "/foreverboard"
SlashCmdList["FOREVERBOARD"] = function(msg)
    msg = msg and msg:trim() or ""
    if msg == "" then
        FB:ToggleUI()
    elseif msg:find("^play ") then
        local soundId = msg:sub(6):trim()
        FB:TriggerSound(soundId)
    elseif msg == "mute" then
        ForeverBoardDB.isMuted = not ForeverBoardDB.isMuted
        local status = ForeverBoardDB.isMuted and "|cffff3333SILENCIADO|r" or "|cff00ff00ACTIVADO|r"
        print("|cff00ccff[ForeverBoard]|r Sonido " .. status)
        if FB.UpdateMuteVisuals then
            FB:UpdateMuteVisuals()
        end
    elseif msg == "version" or msg == "ver" then
        FB:CheckVersions()
    elseif msg == "list" then
        print("|cff00ccff[ForeverBoard]|r Lista de sonidos disponibles:")
        for _, s in ipairs(ForeverBoard_Sounds or {}) do
            print(string.format(" - |cffffffff%s|r (|cffffe066%s|r): %s", s.id, s.name, s.desc or ""))
        end
    elseif msg == "testloot" then
        local testBlueLink = "|cff0070dd|Hitem:19019:0:0:0|h[Objeto de Prueba Azul]|h|r"
        local db = ForeverBoardDB or {}
        local sound = db.triggerLootSound
        if not sound or sound == "" then
            sound = FB:GetDefaultTriggerSound("loot")
        end
        print(string.format("|cff00ccff[ForeverBoard]|r Probando trigger de botin con %s (Sonido: |cffffcc00%s|r)", testBlueLink, tostring(sound)))
        local alert = string.format(FB.L["TRIG_ALERT_LOOT"] or "¡Botín conseguido: %s!", testBlueLink)
        FB:FireAutoTrigger(sound, alert, "loot")
    else
        print("|cff00ccff[ForeverBoard]|r Uso:")
        print(" /fb - Abre/cierra la ventana del SoundBoard")
        print(" /fb play <id> - Reproduce un sonido directamente por ID")
        print(" /fb mute - Activa/desactiva el silencio de ForeverBoard")
        print(" /fb version - Comprueba quién tiene el addon y su versión en grupo/raid")
        print(" /fb list - Lista los IDs de sonido configurados")
        print(" /fb testloot - Simula un drop de objeto azul para verificar que el sonido funciona")
    end
end
