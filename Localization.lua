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
    L["CHANNEL_BTN"] = "Canal: %s"
    L["CHANNEL_TOOLTIP_TITLE"] = "Canal de Audio de WoW"
    L["CHANNEL_TOOLTIP_DESC"] = "Haz clic para alternar entre Master, SFX y Ambience."
    L["CHANNEL_TOOLTIP_MASTER"] = "Master se escucha incluso si la música/efectos están bajos."
    L["DEFAULT_FIRST"] = "[Por defecto: %s]"
    L["NONE_SELECTED"] = "[Ninguno]"
    
    -- Triggers UI
    L["TRIGGERS_TITLE"] = "|cffffe066Disparadores Automáticos:|r"
    L["TRIG_LEVEL_TITLE"] = "Subida de nivel (Ding!)"
    L["TRIG_BOSS_TITLE"] = "Victoria en Boss (Raid / Mazmorra)"
    L["TRIG_DEAD_TITLE"] = "Muerte del personaje (Wipe)"
    L["TRIG_LOOT_TITLE"] = "Sonido cuando se despoja botin especial"
    L["TRIG_LOOT_GREENS"] = "Incluir también verdes"
    L["TRIGGERS_NOTE"] = "Selecciona en el desplegable qué sonido sonará para ti y tu grupo en cada evento."
    
    -- Triggers Chat Alerts
    L["TRIG_ALERT_LEVEL"] = "¡Subida al nivel %s!"
    L["TRIG_ALERT_BOSS"] = "¡Jefe de mazmorra o banda derrotado!"
    L["TRIG_ALERT_DEAD"] = "¡Has muerto!"
    L["TRIG_ALERT_LOOT"] = "¡Botín disponible: %s!"

    -- Guia inicial de bienvenida
    L["WELCOME_TITLE"] = "|cff00ccffBienvenido a ForeverBoard|r"
    L["WELCOME_SUBTITLE"] = "SoundBoard sincronizado para grupo y banda"
    L["WELCOME_STEP1_TITLE"] = "1. Reproducir clips con tu grupo"
    L["WELCOME_STEP1_DESC"] = "Haz clic en cualquier sonido para reproducirlo para ti y todos los miembros de tu grupo/raid que tengan el addon."
    L["WELCOME_STEP2_TITLE"] = "2. Favoritos y Busqueda"
    L["WELCOME_STEP2_DESC"] = "Pulsa en la estrella de cualquier sonido para guardarlo en la pestana 'Favoritos' o usa la barra superior para buscar al instante."
    L["WELCOME_STEP3_TITLE"] = "3. Eventos automaticos"
    L["WELCOME_STEP3_DESC"] = "En la pestana 'Eventos' puedes configurar audios para Ding! (subida de nivel), victoria en bosses, wipes o tiradas de dados (botin raro/epico)."
    L["WELCOME_STEP4_TITLE"] = "4. Icono del minimapa"
    L["WELCOME_STEP4_DESC"] = "Arrastra el altavoz del minimapa con clic izquierdo para moverlo libremente alrededor del minimapa."
    L["WELCOME_CLOSE_BTN"] = "Entendido, vamos alla"

    -- Minimap Tooltip
    L["MINIMAP_CLICK_HINT"] = "Clic: Abrir / Cerrar SoundBoard"
    L["MINIMAP_DRAG_HINT"] = "Clic izquierdo + Arrastrar: Mover icono"
    L["MINIMAP_AUDIO_STATE"] = "Estado del audio: %s"
    L["MINIMAP_CHANNEL"] = "Canal: %s"

    -- Sound Tooltip
    L["FAV_IN"] = "|cffffd700[Favorito]|r"
    L["FAV_ADD_HINT"] = "|cff888888Pulsa la estrella para anadir a favoritos|r"
    L["FAV_REMOVE_TOOLTIP"] = "Quitar de Favoritos"
    L["FAV_ADD_TOOLTIP"] = "Anadir a Favoritos"
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
    L["CHANNEL_BTN"] = "Channel: %s"
    L["CHANNEL_TOOLTIP_TITLE"] = "WoW Audio Channel"
    L["CHANNEL_TOOLTIP_DESC"] = "Click to cycle between Master, SFX and Ambience."
    L["CHANNEL_TOOLTIP_MASTER"] = "Master can be heard even if game sound effects are low."
    L["DEFAULT_FIRST"] = "[Default: %s]"
    L["NONE_SELECTED"] = "[None]"
    
    -- Triggers UI
    L["TRIGGERS_TITLE"] = "|cffffe066Automatic Triggers:|r"
    L["TRIG_LEVEL_TITLE"] = "Level Up (Ding!)"
    L["TRIG_BOSS_TITLE"] = "Boss Kill (Raid / Dungeon)"
    L["TRIG_DEAD_TITLE"] = "Player Death (Wipe)"
    L["TRIG_LOOT_TITLE"] = "Sound when special loot is dropped"
    L["TRIG_LOOT_GREENS"] = "Include uncommon (greens)"
    L["TRIGGERS_NOTE"] = "Use the dropdowns to pick which sound plays for you and your group on each event."
    
    -- Triggers Chat Alerts
    L["TRIG_ALERT_LEVEL"] = "Level up to %s!"
    L["TRIG_ALERT_BOSS"] = "Dungeon or Raid Boss defeated!"
    L["TRIG_ALERT_DEAD"] = "You died!"
    L["TRIG_ALERT_LOOT"] = "Loot available: %s!"

    -- Welcome initial guide
    L["WELCOME_TITLE"] = "|cff00ccffWelcome to ForeverBoard|r"
    L["WELCOME_SUBTITLE"] = "Synchronized SoundBoard for group and raid"
    L["WELCOME_STEP1_TITLE"] = "1. Play clips with your group"
    L["WELCOME_STEP1_DESC"] = "Click any sound to play it for yourself and all group/raid members who have the addon."
    L["WELCOME_STEP2_TITLE"] = "2. Favorites & Search"
    L["WELCOME_STEP2_DESC"] = "Click the star on any sound to save it to 'Favorites' or use the top search bar to find clips quickly."
    L["WELCOME_STEP3_TITLE"] = "3. Automatic triggers"
    L["WELCOME_STEP3_DESC"] = "In the 'Events' tab you can set up audio triggers for Level up, Boss kills, wipes or loot roll popups (rare/epic)."
    L["WELCOME_STEP4_TITLE"] = "4. Minimap icon"
    L["WELCOME_STEP4_DESC"] = "Drag the speaker icon with left click to freely reposition it around the minimap."
    L["WELCOME_CLOSE_BTN"] = "Got it, let's go!"

    -- Minimap Tooltip
    L["MINIMAP_CLICK_HINT"] = "Click: Open / Close SoundBoard"
    L["MINIMAP_DRAG_HINT"] = "Left-click + Drag: Move icon"
    L["MINIMAP_AUDIO_STATE"] = "Audio status: %s"
    L["MINIMAP_CHANNEL"] = "Channel: %s"

    -- Sound Tooltip
    L["FAV_IN"] = "|cffffd700[Favorite]|r"
    L["FAV_ADD_HINT"] = "|cff888888Click star to add to favorites|r"
    L["FAV_REMOVE_TOOLTIP"] = "Remove from Favorites"
    L["FAV_ADD_TOOLTIP"] = "Add to Favorites"
    L["CMD_HINT"] = "Command: /fb play %s"
end

FB.L = L
