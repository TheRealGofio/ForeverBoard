--[[
    ForeverBoard - Localization (i18n)
    Soporte bilingüe: Español (esES/esMX) e Inglés (enUS/enGB y resto de clientes).
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

local locale = GetLocale and GetLocale() or "enUS"
local isSpanish = (locale == "esES" or locale == "esMX")

local L = {}

if isSpanish then
    L["ADDON_LOADED"] = "|cff00ccff[ForeverBoard]|r Addon cargado. Escribe |cffffffff/fb|r o |cffffffff/foreverboard|r para abrir el SoundBoard."
    L["SOUND_PLAYED"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r ha reproducido: |cffffe066%s|r"
    L["MISSING_SOUND"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r ha lanzado |cffffe066%s|r (|cffff9900No tienes este archivo en tu carpeta sounds|r)"
    L["NOT_IN_GROUP"] = "|cff00ccff[ForeverBoard]|r No estás en un grupo ni en banda."
    L["CHECKING_VERSIONS"] = "|cff00ccff[ForeverBoard]|r Comprobando versiones de ForeverBoard en el grupo/raid..."
    L["VERSION_REPLY"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r tiene la versión: |cff00ff00v%s|r"
    L["SOUND_NOT_FOUND"] = "|cff00ccff[ForeverBoard]|r Sonido no encontrado: "
    L["SOUND_STATUS_MUTED"] = "|cffff3333SILENCIADO|r"
    L["SOUND_STATUS_ON"] = "|cff00ff00ACTIVADO|r"
    L["SOUND_MUTED_MSG"] = "|cff00ccff[ForeverBoard]|r Sonido %s"
    L["CHANNEL_CHANGED"] = "|cff00ccff[ForeverBoard]|r Canal de audio cambiado a: |cffffe066%s|r"
    
    -- UI
    L["TAB_ALL"] = "Todos"
    L["TAB_FAV"] = "Favoritos"
    L["TAB_TRIGGERS"] = "Eventos"
    L["SEARCH_PLACEHOLDER"] = "Buscar sonido..."
    L["MUTE_BTN_ON"] = "|cff88ff88Audio ON|r"
    L["MUTE_BTN_MUTED"] = "|cffff4444Muted|r"
    L["MUTE_TOOLTIP_TITLE"] = "Silenciar / Activar sonido"
    L["MUTE_TOOLTIP_DESC"] = "Pulsa para silenciar temporalmente los sonidos entrantes."
    L["MUTE_IN_COMBAT"] = "Mute en combate"
    L["CHANNEL_BTN"] = "Canal: %s"
    L["CHANNEL_TOOLTIP_TITLE"] = "Canal de Audio de WoW"
    L["CHANNEL_TOOLTIP_DESC"] = "Haz clic para alternar entre Master, SFX y Ambience."
    L["CHANNEL_TOOLTIP_MASTER"] = "Master se escucha incluso si la música/efectos están bajos."
    L["DEFAULT_FIRST"] = "Por defecto (1º)"
    
    -- Triggers UI
    L["TRIGGERS_TITLE"] = "|cffffe066Disparadores Automáticos:|r"
    L["TRIG_LEVEL_TITLE"] = "Subida de nivel (Ding!)"
    L["TRIG_BOSS_TITLE"] = "Victoria en Boss (Raid / Mazmorra)"
    L["TRIG_DEAD_TITLE"] = "Muerte del personaje (Wipe)"
    L["TRIGGERS_NOTE"] = "Selecciona en el desplegable qué sonido sonará para ti y tu grupo en cada evento."
    
    -- Triggers Chat Alerts
    L["TRIG_ALERT_LEVEL"] = "¡Subida al nivel %s!"
    L["TRIG_ALERT_BOSS"] = "¡Jefe de mazmorra o banda derrotado!"
    L["TRIG_ALERT_DEAD"] = "¡Has muerto!"

    -- Minimap Tooltip
    L["MINIMAP_CLICK_HINT"] = "Clic izquierdo: Abrir / Cerrar SoundBoard"
    L["MINIMAP_DRAG_HINT"] = "Clic derecho + Arrastrar: Mover icono"
    L["MINIMAP_AUDIO_STATE"] = "Estado del audio: %s"
    L["MINIMAP_CHANNEL"] = "Canal: %s"

    -- Sound Tooltip
    L["FAV_IN"] = "|cffffd700★ En favoritos|r"
    L["FAV_ADD_HINT"] = "|cff888888☆ Pulsa la estrella para añadir a favoritos|r"
    L["FAV_REMOVE_TOOLTIP"] = "Quitar de Favoritos"
    L["FAV_ADD_TOOLTIP"] = "Añadir a Favoritos"
    L["CMD_HINT"] = "Comando: /fb play %s"
else
    L["ADDON_LOADED"] = "|cff00ccff[ForeverBoard]|r Addon loaded. Type |cffffffff/fb|r or |cffffffff/foreverboard|r to open the SoundBoard."
    L["SOUND_PLAYED"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r played: |cffffe066%s|r"
    L["MISSING_SOUND"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r triggered |cffffe066%s|r (|cffff9900You are missing this sound file|r)"
    L["NOT_IN_GROUP"] = "|cff00ccff[ForeverBoard]|r You are not in a group or raid."
    L["CHECKING_VERSIONS"] = "|cff00ccff[ForeverBoard]|r Checking ForeverBoard versions in party/raid..."
    L["VERSION_REPLY"] = "|cff00ccff[ForeverBoard]|r |cffffffff%s|r has version: |cff00ff00v%s|r"
    L["SOUND_NOT_FOUND"] = "|cff00ccff[ForeverBoard]|r Sound not found: "
    L["SOUND_STATUS_MUTED"] = "|cffff3333MUTED|r"
    L["SOUND_STATUS_ON"] = "|cff00ff00ENABLED|r"
    L["SOUND_MUTED_MSG"] = "|cff00ccff[ForeverBoard]|r Sound %s"
    L["CHANNEL_CHANGED"] = "|cff00ccff[ForeverBoard]|r Audio channel changed to: |cffffe066%s|r"
    
    -- UI
    L["TAB_ALL"] = "All"
    L["TAB_FAV"] = "Favorites"
    L["TAB_TRIGGERS"] = "Events"
    L["SEARCH_PLACEHOLDER"] = "Search sound..."
    L["MUTE_BTN_ON"] = "|cff88ff88Audio ON|r"
    L["MUTE_BTN_MUTED"] = "|cffff4444Muted|r"
    L["MUTE_TOOLTIP_TITLE"] = "Mute / Unmute audio"
    L["MUTE_TOOLTIP_DESC"] = "Click to temporarily mute all incoming sounds."
    L["MUTE_IN_COMBAT"] = "Mute in combat"
    L["CHANNEL_BTN"] = "Channel: %s"
    L["CHANNEL_TOOLTIP_TITLE"] = "WoW Audio Channel"
    L["CHANNEL_TOOLTIP_DESC"] = "Click to cycle between Master, SFX and Ambience."
    L["CHANNEL_TOOLTIP_MASTER"] = "Master can be heard even if game sound effects are low."
    L["DEFAULT_FIRST"] = "Default (1st)"
    
    -- Triggers UI
    L["TRIGGERS_TITLE"] = "|cffffe066Automatic Triggers:|r"
    L["TRIG_LEVEL_TITLE"] = "Level Up (Ding!)"
    L["TRIG_BOSS_TITLE"] = "Boss Kill (Raid / Dungeon)"
    L["TRIG_DEAD_TITLE"] = "Player Death (Wipe)"
    L["TRIGGERS_NOTE"] = "Use the dropdowns to pick which sound plays for you and your group on each event."
    
    -- Triggers Chat Alerts
    L["TRIG_ALERT_LEVEL"] = "Level up to %s!"
    L["TRIG_ALERT_BOSS"] = "Dungeon or Raid Boss defeated!"
    L["TRIG_ALERT_DEAD"] = "You died!"

    -- Minimap Tooltip
    L["MINIMAP_CLICK_HINT"] = "Left click: Open / Close SoundBoard"
    L["MINIMAP_DRAG_HINT"] = "Right click + Drag: Move icon"
    L["MINIMAP_AUDIO_STATE"] = "Audio status: %s"
    L["MINIMAP_CHANNEL"] = "Channel: %s"

    -- Sound Tooltip
    L["FAV_IN"] = "|cffffd700★ In favorites|r"
    L["FAV_ADD_HINT"] = "|cff888888☆ Click star to add to favorites|r"
    L["FAV_REMOVE_TOOLTIP"] = "Remove from Favorites"
    L["FAV_ADD_TOOLTIP"] = "Add to Favorites"
    L["CMD_HINT"] = "Command: /fb play %s"
end

FB.L = L
