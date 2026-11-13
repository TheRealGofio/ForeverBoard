--[[
    ForeverBoard - UI
    Interfaz moderna estilo Discord Soundboard:
    - Rejilla adaptativa multi-columna (Dynamic Grid)
    - Botones tipo tarjeta (Tiles) con icono de WoW y estrella integrada
    - Cabecera estilizada con búsqueda y pestañas
    - Panel de Eventos organizado en tarjetas limpias
    - Menú desplegable flotante con scroll
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

local mainFrame = nil
local searchBox = nil
local soundTiles = {}
local contentFrame = nil
local scrollFrame = nil
local triggerContent = nil
local muteBtn = nil
local channelBtn = nil
local countLabel = nil
local currentTab = "ALL" -- "ALL", "FAV", o "TRIGGERS"
local tabAllBtn = nil
local tabFavBtn = nil
local tabTrigBtn = nil

-- Canales de audio soportados por WoW
local SOUND_CHANNELS = { "Master", "SFX", "Ambience" }

-- ==========================================================
-- Función para estilizar botones planos modernos
-- ==========================================================
local function SkinAsModernButton(btn)
    if not btn then return end

    -- Ocultar texturas nativas del UIPanelButtonTemplate de Blizzard
    local nt = btn:GetNormalTexture()
    if nt then nt:SetAlpha(0) end
    local pt = btn:GetPushedTexture()
    if pt then pt:SetAlpha(0) end
    local dt = btn:GetDisabledTexture()
    if dt then dt:SetAlpha(0) end
    local ht = btn:GetHighlightTexture()
    if ht then ht:SetAlpha(0) end

    -- Fondo plano grafito satinado
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0.14, 0.15, 0.20, 0.90)
    btn.customBg = bg

    -- Borde fino sutil de 1px
    local bTop = btn:CreateTexture(nil, "BORDER")
    bTop:SetHeight(1)
    bTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    bTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    bTop:SetColorTexture(0.28, 0.30, 0.40, 0.7)
    btn.bTop = bTop

    local bBottom = btn:CreateTexture(nil, "BORDER")
    bBottom:SetHeight(1)
    bBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bBottom:SetColorTexture(0.08, 0.08, 0.12, 0.9)
    btn.bBottom = bBottom

    local bLeft = btn:CreateTexture(nil, "BORDER")
    bLeft:SetWidth(1)
    bLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    bLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    bLeft:SetColorTexture(0.28, 0.30, 0.40, 0.7)
    btn.bLeft = bLeft

    local bRight = btn:CreateTexture(nil, "BORDER")
    bRight:SetWidth(1)
    bRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    bRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bRight:SetColorTexture(0.08, 0.08, 0.12, 0.9)
    btn.bRight = bRight

    function btn:SetBorderColor(r, g, b, a)
        self.bTop:SetColorTexture(r, g, b, a or 0.8)
        self.bBottom:SetColorTexture(r, g, b, a or 0.8)
        self.bLeft:SetColorTexture(r, g, b, a or 0.8)
        self.bRight:SetColorTexture(r, g, b, a or 0.8)
    end

    btn:HookScript("OnEnter", function(self)
        if not self.isActiveTab then
            self.customBg:SetColorTexture(0.22, 0.25, 0.34, 0.95)
            self:SetBorderColor(0.0, 0.8, 1.0, 0.6)
        end
    end)

    btn:HookScript("OnLeave", function(self)
        if not self.isActiveTab then
            self.customBg:SetColorTexture(0.14, 0.15, 0.20, 0.90)
            self:SetBorderColor(0.28, 0.30, 0.40, 0.7)
        end
    end)
end

local function L(key)
    return (FB.L and FB.L[key]) or key
end

-- Función auxiliar para trim compatible con todas las versiones de WoW
local function strTrim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$") or ""
end

-- Paleta de colores armónica Discord para tarjetas de sonido
local SOUND_PALETTES = {
    { r = 0.35, g = 0.55, b = 0.95 }, -- Azul eléctrico
    { r = 0.18, g = 0.78, b = 0.55 }, -- Esmeralda
    { r = 0.95, g = 0.45, b = 0.35 }, -- Coral / Frambuesa
    { r = 0.95, g = 0.75, b = 0.20 }, -- Ámbar dorado
    { r = 0.65, g = 0.45, b = 0.92 }, -- Púrpura / Violeta
    { r = 0.15, g = 0.75, b = 0.88 }, -- Cian brillante
    { r = 0.95, g = 0.35, b = 0.60 }, -- Rosa magenta
    { r = 0.45, g = 0.85, b = 0.30 }, -- Lima
}

-- Devuelve una paleta de color fija y determinista para un clip
local function GetSoundColor(soundId)
    local hash = 0
    local str = tostring(soundId or "sound")
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 1000000
    end
    local idx = (hash % #SOUND_PALETTES) + 1
    return SOUND_PALETTES[idx]
end

-- Devuelve 1 o 2 iniciales limpias en mayúsculas a partir del nombre
local function GetSoundInitials(name)
    if not name or name == "" then return "SB" end
    local words = {}
    for w in name:gmatch("%S+") do
        table.insert(words, w)
    end
    if #words >= 2 then
        local first = words[1]:sub(1, 1):upper()
        local second = words[2]:sub(1, 1):upper()
        return first .. second
    elseif #words == 1 then
        return words[1]:sub(1, math.min(2, #words[1])):upper()
    else
        return "SB"
    end
end

-- Actualiza el aspecto visual del botón de Mute
function FB:UpdateMuteVisuals()
    local isMuted = ForeverBoardDB and ForeverBoardDB.isMuted
    if muteBtn then
        if isMuted then
            muteBtn:SetText("|cffff5555Muted|r")
            if muteBtn.customBg then
                muteBtn.customBg:SetColorTexture(0.35, 0.10, 0.12, 0.90)
            end
            if muteBtn.SetBorderColor then
                muteBtn:SetBorderColor(0.85, 0.2, 0.2, 0.8)
            end
        else
            muteBtn:SetText("|cff55ff55Audio ON|r")
            if muteBtn.customBg then
                muteBtn.customBg:SetColorTexture(0.10, 0.25, 0.14, 0.90)
            end
            if muteBtn.SetBorderColor then
                muteBtn:SetBorderColor(0.2, 0.8, 0.4, 0.8)
            end
        end
    end
end

-- Actualiza el aspecto visual del botón de canal de audio
function FB:UpdateChannelVisuals()
    if channelBtn and ForeverBoardDB then
        local ch = ForeverBoardDB.soundChannel or "Master"
        channelBtn:SetText(string.format(L("CHANNEL_BTN"), ch))
    end
end

-- Cicla al siguiente canal de audio
function FB:CycleSoundChannel()
    if not ForeverBoardDB then return end
    local current = ForeverBoardDB.soundChannel or "Master"
    local nextCh = "Master"
    for i, ch in ipairs(SOUND_CHANNELS) do
        if ch == current then
            nextCh = SOUND_CHANNELS[(i % #SOUND_CHANNELS) + 1]
            break
        end
    end
    ForeverBoardDB.soundChannel = nextCh
    self:UpdateChannelVisuals()
    print(string.format(L("CHANNEL_CHANGED"), nextCh))
end

-- Comprueba si un sonido está en favoritos
function FB:IsFavorite(soundId)
    if not ForeverBoardDB or not ForeverBoardDB.favorites then
        return false
    end
    return ForeverBoardDB.favorites[soundId] == true
end

-- Alterna el estado de favorito de un sonido
function FB:ToggleFavorite(soundId)
    if not ForeverBoardDB then return end
    ForeverBoardDB.favorites = ForeverBoardDB.favorites or {}
    ForeverBoardDB.favorites[soundId] = not ForeverBoardDB.favorites[soundId]
    self:RefreshSoundList()
end

-- Obtiene el nombre visual de un sonido dado su ID
function FB:GetSoundDisplayName(soundId, triggerType)
    if not soundId or soundId == "" then
        local defId = self:GetDefaultTriggerSound(triggerType)
        local defName = (defId and self.soundMap and self.soundMap[defId] and self.soundMap[defId].name)
        if defName then
            return string.format(L("DEFAULT_FIRST"), defName)
        else
            return L("NONE_SELECTED")
        end
    end
    local sound = self.soundMap and self.soundMap[soundId]
    return sound and sound.name or soundId
end

-- ==========================================================
-- Menú desplegable flotante con scroll
-- ==========================================================
local dropDownMenu = nil
local activeDropKey = nil
local activeDropOwner = nil

function FB:CreateDropDownMenu()
    if dropDownMenu then return dropDownMenu end

    dropDownMenu = CreateFrame("Frame", "ForeverBoardDropDown", UIParent)
    dropDownMenu:SetSize(180, 190)
    dropDownMenu:SetFrameStrata("DIALOG")
    dropDownMenu:SetClampedToScreen(true)
    dropDownMenu:EnableMouse(true)

    if dropDownMenu.SetBackdrop then
        dropDownMenu:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
    else
        local bg = dropDownMenu:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0.05, 0.05, 0.08, 0.98)
    end

    local dScroll = CreateFrame("ScrollFrame", "ForeverBoardDropScroll", dropDownMenu, "UIPanelScrollFrameTemplate")
    dScroll:SetPoint("TOPLEFT", dropDownMenu, "TOPLEFT", 6, -6)
    dScroll:SetPoint("BOTTOMRIGHT", dropDownMenu, "BOTTOMRIGHT", -22, 6)

    local dContent = CreateFrame("Frame", nil, dScroll)
    dContent:SetSize(150, 1)
    dScroll:SetScrollChild(dContent)

    dropDownMenu.content = dContent
    dropDownMenu.buttons = {}
    dropDownMenu:Hide()

    return dropDownMenu
end

function FB:OpenSoundDropDown(ownerButton, dbKey, triggerType)
    local menu = self:CreateDropDownMenu()
    if menu:IsShown() and activeDropKey == dbKey then
        menu:Hide()
        return
    end

    activeDropKey = dbKey
    activeDropOwner = ownerButton

    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", ownerButton, "BOTTOMLEFT", 0, -2)

    local sounds = ForeverBoard_Sounds or {}
    local dContent = menu.content

    local options = {}
    local defaultLabel = FB:GetSoundDisplayName("", triggerType)
    table.insert(options, { id = "", name = defaultLabel })
    for _, s in ipairs(sounds) do
        table.insert(options, { id = s.id, name = s.name })
    end

    local itemHeight = 20
    local yPos = -2

    for i, opt in ipairs(options) do
        local btn = menu.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dContent)
            btn:SetHeight(itemHeight)
            btn:SetNormalFontObject("GameFontHighlightSmall")
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            txt:SetPoint("LEFT", btn, "LEFT", 4, 0)
            txt:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
            txt:SetJustifyH("LEFT")
            btn.label = txt

            menu.buttons[i] = btn
        end

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", dContent, "TOPLEFT", 2, yPos)
        btn:SetPoint("TOPRIGHT", dContent, "TOPRIGHT", -2, yPos)
        btn.label:SetText(opt.name)

        local currentVal = ForeverBoardDB and ForeverBoardDB[activeDropKey] or ""
        if currentVal == opt.id then
            btn.label:SetTextColor(1, 0.85, 0.2)
        else
            btn.label:SetTextColor(0.9, 0.9, 0.9)
        end

        btn:SetScript("OnClick", function()
            if ForeverBoardDB and activeDropKey then
                ForeverBoardDB[activeDropKey] = opt.id
                if FB.UpdateTriggerButtons then
                    FB:UpdateTriggerButtons()
                end
            end
            menu:Hide()
        end)

        btn:Show()
        yPos = yPos - itemHeight
    end

    for j = #options + 1, #menu.buttons do
        menu.buttons[j]:Hide()
    end

    local totalH = math.min(math.abs(yPos) + 8, 220)
    dContent:SetHeight(math.abs(yPos) + 8)
    menu:SetHeight(totalH)
    menu:Show()
end

-- Cambia la pestaña activa (Todos / Favoritos / Eventos)
function FB:SetTab(tab)
    currentTab = tab
    if dropDownMenu then dropDownMenu:Hide() end

    if tabAllBtn and tabFavBtn and tabTrigBtn then
        local function ApplyPillStyle(btn, isActive)
            btn.isActiveTab = isActive
            if isActive then
                if btn.customBg then
                    btn.customBg:SetColorTexture(0.00, 0.45, 0.65, 0.95)
                end
                if btn.SetBorderColor then
                    btn:SetBorderColor(0.00, 0.85, 1.00, 1.0)
                end
                local fs = btn:GetFontString()
                if fs then fs:SetTextColor(1, 1, 1, 1) end
            else
                if btn.customBg then
                    btn.customBg:SetColorTexture(0.12, 0.13, 0.18, 0.85)
                end
                if btn.SetBorderColor then
                    btn:SetBorderColor(0.25, 0.28, 0.38, 0.6)
                end
                local fs = btn:GetFontString()
                if fs then fs:SetTextColor(0.70, 0.70, 0.75, 1) end
            end
        end

        ApplyPillStyle(tabAllBtn, currentTab == "ALL")
        ApplyPillStyle(tabFavBtn, currentTab == "FAV")
        ApplyPillStyle(tabTrigBtn, currentTab == "TRIGGERS")
    end

    if currentTab == "TRIGGERS" then
        if scrollFrame then scrollFrame:Hide() end
        if searchBox then searchBox:Hide() end
        if triggerContent then triggerContent:Show() end
        if self.UpdateTriggerButtons then
            self:UpdateTriggerButtons()
        end
    else
        if triggerContent then triggerContent:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if searchBox then searchBox:Show() end
        self:RefreshSoundList()
    end
end

-- ==========================================================
-- Rejilla Dinámica (Grid) Adaptativa para los sonidos
-- ==========================================================
function FB:RefreshSoundList()
    if not contentFrame or currentTab == "TRIGGERS" then return end

    local filter = ""
    if searchBox and searchBox.GetText then
        filter = strTrim(searchBox:GetText()):lower()
    end

    local sounds = ForeverBoard_Sounds or {}
    local availWidth = (scrollFrame and scrollFrame.GetWidth and scrollFrame:GetWidth()) or 340
    availWidth = math.max(availWidth - 26, 200)
    contentFrame:SetWidth(availWidth)

    -- Calcular número de columnas dinámico según el ancho de la ventana
    local colMin = 145
    local cols = math.floor(availWidth / colMin)
    if cols < 1 then cols = 1 end
    if cols > 5 then cols = 5 end

    local spacing = 6
    local tileWidth = math.floor((availWidth - ((cols - 1) * spacing)) / cols)
    local tileHeight = 36

    local visibleIdx = 0
    local favCount = 0

    for i, item in ipairs(sounds) do
        local tile = soundTiles[i]
        if tile then
            local isFav = self:IsFavorite(item.id)
            if isFav then favCount = favCount + 1 end

            local matchesTab = (currentTab == "ALL") or (currentTab == "FAV" and isFav)

            local matchesFilter = true
            if filter ~= "" then
                local nameMatch = item.name and item.name:lower():find(filter, 1, true)
                local idMatch = item.id and item.id:lower():find(filter, 1, true)
                local descMatch = item.desc and item.desc:lower():find(filter, 1, true)
                matchesFilter = (nameMatch or idMatch or descMatch) ~= nil
            end

            if matchesTab and matchesFilter then
                local col = visibleIdx % cols
                local row = math.floor(visibleIdx / cols)

                local posX = col * (tileWidth + spacing)
                local posY = - (row * (tileHeight + spacing)) - 4

                tile:ClearAllPoints()
                tile:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", posX, posY)
                tile:SetSize(tileWidth, tileHeight)

                -- Actualizar estrella de favorito
                if isFav then
                    tile.star.icon:SetVertexColor(1, 0.85, 0.1, 1)
                else
                    tile.star.icon:SetVertexColor(0.28, 0.28, 0.32, 0.6)
                end

                tile:Show()
                visibleIdx = visibleIdx + 1
            else
                tile:Hide()
            end
        end
    end

    local totalRows = math.ceil(visibleIdx / cols)
    local totalHeight = (totalRows * (tileHeight + spacing)) + 12
    contentFrame:SetHeight(math.max(totalHeight, 50))

    -- Actualizar contador inferior y pestañas
    if countLabel then
        countLabel:SetText(string.format("%d clips", visibleIdx))
    end
    if tabAllBtn then
        tabAllBtn:SetText(string.format("%s (%d)", L("TAB_ALL"), #sounds))
    end
    if tabFavBtn then
        tabFavBtn:SetText(string.format("%s (%d)", L("TAB_FAV"), favCount))
    end
end

function FB:CreateUI()
    if mainFrame then return mainFrame end

    -- Dimensiones iniciales estilo Discord Soundboard (más ancho y proporcionado)
    local defaultWidth = (ForeverBoardDB and ForeverBoardDB.width) or 370
    local defaultHeight = (ForeverBoardDB and ForeverBoardDB.height) or 440

    mainFrame = CreateFrame("Frame", "ForeverBoardFrame", UIParent)
    mainFrame:SetSize(defaultWidth, defaultHeight)
    if mainFrame.SetMinResize then
        mainFrame:SetMinResize(290, 320)
        mainFrame:SetMaxResize(850, 900)
    elseif mainFrame.SetResizeBounds then
        mainFrame:SetResizeBounds(290, 320, 850, 900)
    end
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)

    -- Arrastrar ventana
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if dropDownMenu then dropDownMenu:Hide() end
        self:StartMoving()
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left = self:GetLeft()
        local top = self:GetTop()
        if left and top then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
            if ForeverBoardDB then
                ForeverBoardDB.point = "TOPLEFT"
                ForeverBoardDB.posX = left
                ForeverBoardDB.posY = top
            end
        end
    end)

    -- Fondo estilizado con bordes finos de diálogo
    if mainFrame.SetBackdrop then
        mainFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
    else
        local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0.08, 0.08, 0.1, 0.94)
    end

    -- ==========================================
    -- Cabecera
    -- ==========================================
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -12)
    title:SetText("|cff00ccffForeverBoard|r")

    -- Botón de cerrar
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        if dropDownMenu then dropDownMenu:Hide() end
        mainFrame:Hide()
    end)

    -- Botón de Mute rápido en la cabecera (derecha, junto a cerrar)
    muteBtn = CreateFrame("Button", "ForeverBoardMuteBtn", mainFrame, "UIPanelButtonTemplate")
    muteBtn:SetSize(82, 20)
    muteBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -2, -4)
    SkinAsModernButton(muteBtn)
    muteBtn:SetScript("OnClick", function()
        ForeverBoardDB.isMuted = not ForeverBoardDB.isMuted
        FB:UpdateMuteVisuals()
        local status = ForeverBoardDB.isMuted and L("SOUND_STATUS_MUTED") or L("SOUND_STATUS_ON")
        print(string.format(L("SOUND_MUTED_MSG"), status))
    end)
    muteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("MUTE_TOOLTIP_TITLE"), 1, 1, 1)
        GameTooltip:AddLine(L("MUTE_TOOLTIP_DESC"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    muteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Pestañas como píldoras de navegación
    tabAllBtn = CreateFrame("Button", "ForeverBoardTabAll", mainFrame, "UIPanelButtonTemplate")
    tabAllBtn:SetSize(84, 22)
    tabAllBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -38)
    tabAllBtn:SetText(L("TAB_ALL"))
    SkinAsModernButton(tabAllBtn)
    tabAllBtn:SetScript("OnClick", function()
        FB:SetTab("ALL")
    end)

    tabFavBtn = CreateFrame("Button", "ForeverBoardTabFav", mainFrame, "UIPanelButtonTemplate")
    tabFavBtn:SetSize(90, 22)
    tabFavBtn:SetPoint("LEFT", tabAllBtn, "RIGHT", 4, 0)
    tabFavBtn:SetText(L("TAB_FAV"))
    SkinAsModernButton(tabFavBtn)
    tabFavBtn:SetScript("OnClick", function()
        FB:SetTab("FAV")
    end)

    tabTrigBtn = CreateFrame("Button", "ForeverBoardTabTrig", mainFrame, "UIPanelButtonTemplate")
    tabTrigBtn:SetSize(76, 22)
    tabTrigBtn:SetPoint("LEFT", tabFavBtn, "RIGHT", 4, 0)
    tabTrigBtn:SetText(L("TAB_TRIGGERS"))
    SkinAsModernButton(tabTrigBtn)
    tabTrigBtn:SetScript("OnClick", function()
        FB:SetTab("TRIGGERS")
    end)

    -- Caja de búsqueda debajo de las pestañas
    searchBox = CreateFrame("EditBox", "ForeverBoardSearchBox", mainFrame, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 22, -64)
    searchBox:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -22, -64)
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        FB:RefreshSoundList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- ==========================================
    -- Panel de Triggers Automáticos en Tarjetas
    -- ==========================================
    triggerContent = CreateFrame("Frame", "ForeverBoardTriggerContent", mainFrame)
    triggerContent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -64)
    triggerContent:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 34)
    triggerContent:Hide()

    local trigTitle = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trigTitle:SetPoint("TOPLEFT", triggerContent, "TOPLEFT", 6, -2)
    trigTitle:SetText(L("TRIGGERS_TITLE"))

    -- Función auxiliar para crear tarjetas limpias de trigger
    local function CreateTriggerCard(parent, titleText, iconTexture, prevFrame, dbCheckKey, dbSoundKey, triggerType)
        local card = CreateFrame("Frame", nil, parent)
        card:SetHeight(46)
        card:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -6)
        card:SetPoint("RIGHT", parent, "RIGHT", -6, 0)

        -- Fondo de tarjeta
        local cbg = card:CreateTexture(nil, "BACKGROUND")
        cbg:SetAllPoints(true)
        cbg:SetColorTexture(0.12, 0.12, 0.16, 0.75)

        -- Icono del evento
        local cIcon = card:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(28, 28)
        cIcon:SetPoint("LEFT", card, "LEFT", 8, 0)
        cIcon:SetTexture(iconTexture)

        -- Checkbox
        local chk = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
        chk:SetSize(20, 20)
        chk:SetPoint("LEFT", cIcon, "RIGHT", 6, 0)
        chk:SetChecked(ForeverBoardDB and ForeverBoardDB[dbCheckKey])
        chk:SetScript("OnClick", function(self)
            ForeverBoardDB[dbCheckKey] = self:GetChecked()
        end)

        -- Botón desplegable de sonido
        local btn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
        btn:SetSize(145, 22)
        btn:SetPoint("RIGHT", card, "RIGHT", -8, 0)
        SkinAsModernButton(btn)
        btn:SetScript("OnClick", function(self)
            FB:OpenSoundDropDown(self, dbSoundKey, triggerType)
        end)

        -- Título del evento (limitado a la derecha por el botón desplegable)
        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", chk, "RIGHT", 4, 0)
        lbl:SetPoint("RIGHT", btn, "LEFT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetText(titleText)

        return card, chk, btn
    end

    local cardLevel, chkLevel, btnSoundLevel = CreateTriggerCard(
        triggerContent,
        L("TRIG_LEVEL_TITLE"),
        "Interface\\Icons\\Spell_Holy_PrayerOfFortitude",
        trigTitle,
        "triggerLevelUp",
        "triggerLevelUpSound",
        "levelUp"
    )

    local cardBoss, chkBoss, btnSoundBoss = CreateTriggerCard(
        triggerContent,
        L("TRIG_BOSS_TITLE"),
        "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        cardLevel,
        "triggerBossKill",
        "triggerBossKillSound",
        "bossKill"
    )

    local cardDead, chkDead, btnSoundDead = CreateTriggerCard(
        triggerContent,
        L("TRIG_DEAD_TITLE"),
        "Interface\\Icons\\Ability_Creature_Cursed_02",
        cardBoss,
        "triggerDeath",
        "triggerDeathSound",
        "death"
    )

    local cardLoot, chkLoot, btnSoundLoot = CreateTriggerCard(
        triggerContent,
        L("TRIG_LOOT_TITLE"),
        "Interface\\Icons\\INV_Box_01",
        cardDead,
        "triggerLoot",
        "triggerLootSound",
        "loot"
    )

    -- Checkbox extra para incluir verdes dentro de la tarjeta de botín
    local chkGreens = CreateFrame("CheckButton", "ForeverBoardChkGreens", cardLoot, "UICheckButtonTemplate")
    chkGreens:SetSize(16, 16)
    chkGreens:SetPoint("TOPLEFT", chkLoot, "BOTTOMLEFT", 0, -2)
    chkGreens:SetChecked(ForeverBoardDB and ForeverBoardDB.triggerLootIncludeGreens)
    chkGreens:SetScript("OnClick", function(self)
        ForeverBoardDB.triggerLootIncludeGreens = self:GetChecked()
    end)
    local lblGreens = cardLoot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblGreens:SetPoint("LEFT", chkGreens, "RIGHT", 2, 0)
    lblGreens:SetText("|cff1eff00" .. L("TRIG_LOOT_GREENS") .. "|r")

    -- Ajustar la altura de la tarjeta de botín para albergar la opción de verdes
    cardLoot:SetHeight(58)

    function FB:UpdateTriggerButtons()
        if btnSoundLevel and ForeverBoardDB then
            btnSoundLevel:SetText(FB:GetSoundDisplayName(ForeverBoardDB.triggerLevelUpSound, "levelUp") .. " >")
        end
        if btnSoundBoss and ForeverBoardDB then
            btnSoundBoss:SetText(FB:GetSoundDisplayName(ForeverBoardDB.triggerBossKillSound, "bossKill") .. " >")
        end
        if btnSoundDead and ForeverBoardDB then
            btnSoundDead:SetText(FB:GetSoundDisplayName(ForeverBoardDB.triggerDeathSound, "death") .. " >")
        end
        if btnSoundLoot and ForeverBoardDB then
            btnSoundLoot:SetText(FB:GetSoundDisplayName(ForeverBoardDB.triggerLootSound, "loot") .. " >")
        end
    end

    -- Nota explicativa
    local note = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", cardLoot, "BOTTOMLEFT", 4, -12)
    note:SetPoint("RIGHT", triggerContent, "RIGHT", -6, 0)
    note:SetJustifyH("LEFT")
    note:SetText(L("TRIGGERS_NOTE"))

    -- ==========================================
    -- Contenedor con Scroll para la Rejilla de Botones
    -- ==========================================
    scrollFrame = CreateFrame("ScrollFrame", "ForeverBoardScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -6, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -28, 32)

    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(280, 1)
    scrollFrame:SetScrollChild(contentFrame)

    -- Manejar redimensionamiento dinámico de la rejilla
    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        if contentFrame and width and width > 50 then
            FB:RefreshSoundList()
        end
    end)

    -- Generar Tarjetas / Tiles de sonido estilo Discord
    local sounds = ForeverBoard_Sounds or {}

    for i, item in ipairs(sounds) do
        -- Contenedor Tile del botón
        local tile = CreateFrame("Button", "ForeverBoardTile_" .. item.id, contentFrame)
        tile:SetNormalFontObject("GameFontHighlightSmall")

        -- Fondo del Tile
        local tbg = tile:CreateTexture(nil, "BACKGROUND")
        tbg:SetAllPoints(true)
        tbg:SetColorTexture(0.14, 0.14, 0.19, 0.85)
        tile.bg = tbg

        -- Borde resaltado al pasar el ratón (Hover)
        local hl = tile:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(true)
        hl:SetColorTexture(0.25, 0.45, 0.85, 0.3)

        -- Banda / Insignia decorativa izquierda estilo Discord Soundboard
        local color = GetSoundColor(item.id)
        local accentBar = tile:CreateTexture(nil, "BORDER")
        accentBar:SetWidth(4)
        accentBar:SetPoint("TOPLEFT", tile, "TOPLEFT", 0, 0)
        accentBar:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 0, 0)
        accentBar:SetColorTexture(color.r, color.g, color.b, 0.95)
        tile.accentBar = accentBar

        -- Badge de Iniciales
        local badge = tile:CreateTexture(nil, "ARTWORK")
        badge:SetSize(24, 24)
        badge:SetPoint("LEFT", tile, "LEFT", 8, 0)
        badge:SetColorTexture(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.9)
        tile.badge = badge

        -- Texto de iniciales dentro del badge
        local badgeText = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgeText:SetPoint("CENTER", badge, "CENTER", 0, 0)
        badgeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        badgeText:SetTextColor(color.r, color.g, color.b, 1)
        badgeText:SetText(GetSoundInitials(item.name))
        tile.badgeText = badgeText

        -- Botón estrella de favoritos en la esquina superior derecha
        local star = CreateFrame("Button", nil, tile)
        star:SetSize(18, 18)
        star:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -2, -2)

        local starIcon = star:CreateTexture(nil, "OVERLAY")
        starIcon:SetSize(14, 14)
        starIcon:SetPoint("CENTER", star, "CENTER", 0, 0)
        starIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
        star.icon = starIcon

        star:SetScript("OnClick", function()
            FB:ToggleFavorite(item.id)
        end)
        star:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if FB:IsFavorite(item.id) then
                GameTooltip:AddLine(L("FAV_REMOVE_TOOLTIP"), 1, 0.3, 0.3)
            else
                GameTooltip:AddLine(L("FAV_ADD_TOOLTIP"), 1, 0.85, 0.2)
            end
            GameTooltip:Show()
        end)
        star:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tile.star = star

        -- Nombre completo del sonido
        local label = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", badge, "RIGHT", 7, 0)
        label:SetPoint("RIGHT", star, "LEFT", -4, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        label:SetText(item.name)
        tile.label = label

        -- Click: disparar sonido local y en red
        tile:SetScript("OnClick", function()
            FB:TriggerSound(item.id)
        end)

        -- Tooltip completo
        tile:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(0.20, 0.22, 0.28, 0.95)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(item.name, 1, 0.85, 0.2)
            if item.desc and item.desc ~= "" then
                GameTooltip:AddLine(item.desc, 0.8, 0.8, 0.8, true)
            end
            local favHint = FB:IsFavorite(item.id) and L("FAV_IN") or L("FAV_ADD_HINT")
            GameTooltip:AddLine(favHint, 0.8, 0.8, 0.8)
            GameTooltip:AddLine(string.format(L("CMD_HINT"), item.id), 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)

        tile:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0.14, 0.14, 0.19, 0.85)
            GameTooltip:Hide()
        end)

        soundTiles[i] = tile
    end

    -- ==========================================
    -- Barra Inferior de Control
    -- ==========================================
    -- Contador de clips en la parte izquierda inferior
    countLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countLabel:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 14, 10)
    countLabel:SetText(string.format("%d clips", #sounds))

    -- Selector de canal de audio a la derecha
    channelBtn = CreateFrame("Button", "ForeverBoardChannelBtn", mainFrame, "UIPanelButtonTemplate")
    channelBtn:SetSize(115, 20)
    channelBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -22, 6)
    SkinAsModernButton(channelBtn)
    channelBtn:SetScript("OnClick", function()
        FB:CycleSoundChannel()
    end)
    channelBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("CHANNEL_TOOLTIP_TITLE"), 1, 1, 1)
        GameTooltip:AddLine(L("CHANNEL_TOOLTIP_DESC"), 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(L("CHANNEL_TOOLTIP_MASTER"), 0.5, 0.8, 1, true)
        GameTooltip:Show()
    end)
    channelBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Pestaña de redimensionamiento (Resize Grip)
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

    resizeGrip:SetScript("OnMouseDown", function()
        if dropDownMenu then dropDownMenu:Hide() end
        -- Fijar el anclaje a TOPLEFT antes de StartSizing para evitar saltos o que cambie de tamaño al hacer solo clic
        local left = mainFrame:GetLeft()
        local top = mainFrame:GetTop()
        if left and top then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
        mainFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        mainFrame:StopMovingOrSizing()
        local left = mainFrame:GetLeft()
        local top = mainFrame:GetTop()
        local w, h = mainFrame:GetSize()
        if ForeverBoardDB then
            ForeverBoardDB.point = "TOPLEFT"
            ForeverBoardDB.posX = left
            ForeverBoardDB.posY = top
            ForeverBoardDB.width = w
            ForeverBoardDB.height = h
        end
        FB:RefreshSoundList()
    end)

    mainFrame:SetScript("OnSizeChanged", function(self, w, h)
        if scrollFrame and contentFrame then
            FB:RefreshSoundList()
        end
    end)

    -- Restaurar posición guardada
    if ForeverBoardDB and ForeverBoardDB.posX and ForeverBoardDB.posY then
        mainFrame:ClearAllPoints()
        if ForeverBoardDB.point == "TOPLEFT" then
            mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ForeverBoardDB.posX, ForeverBoardDB.posY)
        else
            mainFrame:SetPoint(ForeverBoardDB.point or "CENTER", UIParent, ForeverBoardDB.point or "CENTER", ForeverBoardDB.posX, ForeverBoardDB.posY)
            -- Normalizar inmediatamente a TOPLEFT
            local left = mainFrame:GetLeft()
            local top = mainFrame:GetTop()
            if left and top then
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
                ForeverBoardDB.point = "TOPLEFT"
                ForeverBoardDB.posX = left
                ForeverBoardDB.posY = top
            end
        end
    end

    FB:UpdateMuteVisuals()
    FB:UpdateChannelVisuals()
    FB:UpdateTriggerButtons()
    FB:SetTab("ALL")

    mainFrame:Hide()
    return mainFrame
end

function FB:ToggleUI()
    local ok, err = pcall(function()
        local frame = self:CreateUI()
        if frame:IsShown() then
            if dropDownMenu then dropDownMenu:Hide() end
            frame:Hide()
        else
            frame:Show()
            if searchBox then
                searchBox:SetText("")
            end
            FB:UpdateMuteVisuals()
            FB:UpdateChannelVisuals()
            FB:RefreshSoundList()

            -- Mostrar la guía de bienvenida la primera vez que se abre
            if ForeverBoardDB and not ForeverBoardDB.hasSeenWelcome then
                FB:ShowWelcomeGuide()
            end
        end
    end)

    if not ok then
        print("|cff00ccff[ForeverBoard ERROR]|r " .. tostring(err))
    end
end

-- ==========================================================
-- Ventana de Guía de Bienvenida (Primer Uso)
-- ==========================================================
local welcomeFrame = nil
function FB:ShowWelcomeGuide()
    if welcomeFrame then
        welcomeFrame:Show()
        return welcomeFrame
    end

    welcomeFrame = CreateFrame("Frame", "ForeverBoardWelcomeFrame", UIParent)
    welcomeFrame:SetSize(420, 360)
    welcomeFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    welcomeFrame:SetFrameStrata("DIALOG")
    welcomeFrame:SetClampedToScreen(true)
    welcomeFrame:EnableMouse(true)
    welcomeFrame:SetMovable(true)
    welcomeFrame:RegisterForDrag("LeftButton")
    welcomeFrame:SetScript("OnDragStart", welcomeFrame.StartMoving)
    welcomeFrame:SetScript("OnDragStop", welcomeFrame.StopMovingOrSizing)

    if welcomeFrame.SetBackdrop then
        welcomeFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
    else
        local bg = welcomeFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0.08, 0.08, 0.12, 0.98)
    end

    -- Icono superior decorativo
    local topIcon = welcomeFrame:CreateTexture(nil, "ARTWORK")
    topIcon:SetSize(36, 36)
    topIcon:SetPoint("TOPLEFT", welcomeFrame, "TOPLEFT", 18, -16)
    topIcon:SetTexture("Interface\\Icons\\INV_Misc_Horn_01")

    -- Título y subtítulo
    local wTitle = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wTitle:SetPoint("TOPLEFT", topIcon, "TOPRIGHT", 10, -2)
    wTitle:SetText(L("WELCOME_TITLE"))

    local wSub = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    wSub:SetPoint("TOPLEFT", wTitle, "BOTTOMLEFT", 0, -3)
    wSub:SetText(L("WELCOME_SUBTITLE"))

    -- Separador horizontal
    local line = welcomeFrame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", topIcon, "BOTTOMLEFT", 0, -10)
    line:SetPoint("RIGHT", welcomeFrame, "RIGHT", -18, 0)
    line:SetColorTexture(0.3, 0.3, 0.35, 0.7)

    -- Pasos explicativos rápidos
    local steps = {
        { title = L("WELCOME_STEP1_TITLE"), desc = L("WELCOME_STEP1_DESC"), color = "ffffd100" },
        { title = L("WELCOME_STEP2_TITLE"), desc = L("WELCOME_STEP2_DESC"), color = "ff55ff55" },
        { title = L("WELCOME_STEP3_TITLE"), desc = L("WELCOME_STEP3_DESC"), color = "ff00ccff" },
        { title = L("WELCOME_STEP4_TITLE"), desc = L("WELCOME_STEP4_DESC"), color = "ffa335ee" },
    }

    local prevAnchor = line
    for i, s in ipairs(steps) do
        local stTitle = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        stTitle:SetPoint("TOPLEFT", prevAnchor, "BOTTOMLEFT", 0, -10)
        stTitle:SetPoint("RIGHT", welcomeFrame, "RIGHT", -18, 0)
        stTitle:SetJustifyH("LEFT")
        stTitle:SetText("|c" .. s.color .. s.title .. "|r")

        local stDesc = welcomeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        stDesc:SetPoint("TOPLEFT", stTitle, "BOTTOMLEFT", 0, -2)
        stDesc:SetPoint("RIGHT", welcomeFrame, "RIGHT", -18, 0)
        stDesc:SetJustifyH("LEFT")
        stDesc:SetTextColor(0.82, 0.82, 0.82)
        stDesc:SetText(s.desc)

        prevAnchor = stDesc
    end

    -- Botón de Entendido / Cerrar
    local closeBtn = CreateFrame("Button", nil, welcomeFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(180, 26)
    closeBtn:SetPoint("BOTTOM", welcomeFrame, "BOTTOM", 0, 16)
    closeBtn:SetText(L("WELCOME_CLOSE_BTN"))
    SkinAsModernButton(closeBtn)
    closeBtn:SetScript("OnClick", function()
        welcomeFrame:Hide()
        if ForeverBoardDB then
            ForeverBoardDB.hasSeenWelcome = true
        end
    end)

    return welcomeFrame
end

-- ==========================================================
-- Botón circular en el Minimapa
-- ==========================================================
local minimapBtn = nil

function FB:UpdateMinimapPosition()
    if not minimapBtn then return end
    local angle = (ForeverBoardDB and ForeverBoardDB.minimapPos) or 45
    local rad = math.rad(angle)
    local radius = 103
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function FB:CreateMinimapButton()
    if minimapBtn then return minimapBtn end

    minimapBtn = CreateFrame("Button", "ForeverBoardMinimapButton", Minimap)
    minimapBtn:SetSize(33, 33)
    minimapBtn:SetFrameStrata("MEDIUM")
    minimapBtn:SetFrameLevel((Minimap:GetFrameLevel() or 5) + 5)
    minimapBtn:EnableMouse(true)
    minimapBtn:SetMovable(true)
    minimapBtn:RegisterForClicks("AnyUp")

    -- Icono interior (altavoz/cuerno de sonido)
    local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Horn_01")

    -- Borde circular estándar de Blizzard
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Arrastrar con Clic Izquierdo (o Derecho) alrededor del minimapa
    minimapBtn:RegisterForDrag("LeftButton", "RightButton")
    minimapBtn:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then angle = angle + 360 end
            if ForeverBoardDB then
                ForeverBoardDB.minimapPos = angle
            end
            FB:UpdateMinimapPosition()
        end)
    end)

    minimapBtn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    -- Clic: Abrir/Cerrar SoundBoard (solo si no se estaba arrastrando)
    minimapBtn:SetScript("OnClick", function(self, button)
        if not self.isDragging then
            FB:ToggleUI()
        end
    end)

    -- Tooltip
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffForeverBoard|r", 1, 1, 1)
        GameTooltip:AddLine(L("MINIMAP_CLICK_HINT"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L("MINIMAP_DRAG_HINT"), 0.5, 0.8, 1)
        local status = (ForeverBoardDB and ForeverBoardDB.isMuted) and L("SOUND_STATUS_MUTED") or L("SOUND_STATUS_ON")
        local ch = (ForeverBoardDB and ForeverBoardDB.soundChannel) or "Master"
        GameTooltip:AddLine(string.format(L("MINIMAP_AUDIO_STATE"), status), 0.7, 0.7, 0.7)
        GameTooltip:AddLine(string.format(L("MINIMAP_CHANNEL"), ch), 0.6, 0.8, 1)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    FB:UpdateMinimapPosition()
    return minimapBtn
end
