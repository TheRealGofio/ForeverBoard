--[[
    ForeverBoard - UI
    Ventana flotante con soporte bilingüe (i18n), pestañas (Todos / Favoritos / Eventos),
    gestión de favoritos, triggers automáticos con menú desplegable (Dropdown),
    selector de canal de audio (Master / SFX / Ambience) y minimapa.
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

local mainFrame = nil
local searchBox = nil
local soundRows = {}
local contentFrame = nil
local scrollFrame = nil
local triggerContent = nil
local muteBtn = nil
local channelBtn = nil
local combatCheck = nil
local currentTab = "ALL" -- "ALL", "FAV", o "TRIGGERS"
local tabAllBtn = nil
local tabFavBtn = nil
local tabTrigBtn = nil

-- Canales de audio soportados por WoW
local SOUND_CHANNELS = { "Master", "SFX", "Ambience" }

local function L(key)
    return (FB.L and FB.L[key]) or key
end

-- Función auxiliar para trim compatible con todas las versiones de Lua en WoW
local function strTrim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$") or ""
end

-- Actualiza el aspecto visual del botón de Mute
function FB:UpdateMuteVisuals()
    local isMuted = ForeverBoardDB and ForeverBoardDB.isMuted
    if muteBtn then
        if isMuted then
            muteBtn:SetText(L("MUTE_BTN_MUTED"))
        else
            muteBtn:SetText(L("MUTE_BTN_ON"))
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
-- Menú desplegable flotante para seleccionar sonido de eventos
-- ==========================================================
local dropDownMenu = nil
local activeDropKey = nil
local activeDropOwner = nil

function FB:CreateDropDownMenu()
    if dropDownMenu then return dropDownMenu end

    dropDownMenu = CreateFrame("Frame", "ForeverBoardDropDown", UIParent)
    dropDownMenu:SetSize(170, 180)
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
    dContent:SetSize(140, 1)
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

    -- Opciones: 1ª opción "Por defecto", y luego cada sonido disponible
    local options = {}
    local defaultLabel = FB:GetSoundDisplayName("", triggerType)
    table.insert(options, { id = "", name = defaultLabel })
    for _, s in ipairs(sounds) do
        table.insert(options, { id = s.id, name = s.name })
    end

    local itemHeight = 18
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

        -- Resaltar si es la opción activa
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

    -- Ocultar sobrantes
    for j = #options + 1, #menu.buttons do
        menu.buttons[j]:Hide()
    end

    local totalH = math.min(math.abs(yPos) + 8, 200)
    dContent:SetHeight(math.abs(yPos) + 8)
    menu:SetHeight(totalH)
    menu:Show()
end

-- Cambia la pestaña activa (Todos / Favoritos / Eventos)
function FB:SetTab(tab)
    currentTab = tab
    if dropDownMenu then dropDownMenu:Hide() end

    if tabAllBtn and tabFavBtn and tabTrigBtn then
        tabAllBtn:UnlockHighlight()
        tabFavBtn:UnlockHighlight()
        tabTrigBtn:UnlockHighlight()

        if currentTab == "ALL" then
            tabAllBtn:LockHighlight()
        elseif currentTab == "FAV" then
            tabFavBtn:LockHighlight()
        elseif currentTab == "TRIGGERS" then
            tabTrigBtn:LockHighlight()
        end
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

-- Actualiza la visibilidad y posición de los botones según el filtro de búsqueda y favoritos
function FB:RefreshSoundList()
    if not contentFrame or currentTab == "TRIGGERS" then return end

    local filter = ""
    if searchBox and searchBox.GetText then
        filter = strTrim(searchBox:GetText()):lower()
    end

    local sounds = ForeverBoard_Sounds or {}
    local rowHeight = 28
    local spacing = 4
    local currentY = -4

    local parentWidth = (scrollFrame and scrollFrame.GetWidth and scrollFrame:GetWidth()) or 220
    local totalWidth = math.max(parentWidth - 28, 160)
    contentFrame:SetWidth(totalWidth)

    local starWidth = 24
    local btnWidth = totalWidth - starWidth - 2

    for i, item in ipairs(sounds) do
        local row = soundRows[i]
        if row then
            local isFav = self:IsFavorite(item.id)
            local matchesTab = (currentTab == "ALL") or (currentTab == "FAV" and isFav)

            local matchesFilter = true
            if filter ~= "" then
                local nameMatch = item.name and item.name:lower():find(filter, 1, true)
                local idMatch = item.id and item.id:lower():find(filter, 1, true)
                local descMatch = item.desc and item.desc:lower():find(filter, 1, true)
                matchesFilter = (nameMatch or idMatch or descMatch) ~= nil
            end

            if matchesTab and matchesFilter then
                row.btn:ClearAllPoints()
                row.btn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
                row.btn:SetWidth(btnWidth)
                row.btn:Show()

                row.star:ClearAllPoints()
                row.star:SetPoint("LEFT", row.btn, "RIGHT", 2, 0)
                row.star:SetWidth(starWidth)
                if isFav then
                    row.star.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                    row.star.icon:SetVertexColor(1, 1, 1, 1)
                else
                    row.star.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
                    row.star.icon:SetVertexColor(0.25, 0.25, 0.25, 0.5)
                end
                row.star:Show()

                currentY = currentY - (rowHeight + spacing)
            else
                row.btn:Hide()
                row.star:Hide()
            end
        end
    end

    local totalHeight = math.abs(currentY) + 10
    contentFrame:SetHeight(math.max(totalHeight, 50))
end

function FB:CreateUI()
    if mainFrame then return mainFrame end

    local defaultWidth = (ForeverBoardDB and ForeverBoardDB.width) or 290
    local defaultHeight = (ForeverBoardDB and ForeverBoardDB.height) or 430

    -- Ventana principal
    mainFrame = CreateFrame("Frame", "ForeverBoardFrame", UIParent)
    mainFrame:SetSize(defaultWidth, defaultHeight)
    if mainFrame.SetMinResize then
        mainFrame:SetMinResize(260, 320)
        mainFrame:SetMaxResize(600, 800)
    elseif mainFrame.SetResizeBounds then
        mainFrame:SetResizeBounds(260, 320, 600, 800)
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
        local point, _, _, x, y = self:GetPoint()
        if ForeverBoardDB then
            ForeverBoardDB.point = point
            ForeverBoardDB.posX = x
            ForeverBoardDB.posY = y
        end
    end)

    -- Fondo y bordes
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

    -- Cabecera
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    title:SetText("|cff00ccffForeverBoard|r")

    -- Botón de cerrar
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        if dropDownMenu then dropDownMenu:Hide() end
        mainFrame:Hide()
    end)

    -- Botón de Mute rápido en la cabecera
    muteBtn = CreateFrame("Button", "ForeverBoardMuteBtn", mainFrame, "UIPanelButtonTemplate")
    muteBtn:SetSize(75, 20)
    muteBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -8)
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

    -- Pestañas "Todos", "Favoritos" y "Eventos"
    tabAllBtn = CreateFrame("Button", "ForeverBoardTabAll", mainFrame, "UIPanelButtonTemplate")
    tabAllBtn:SetSize(62, 20)
    tabAllBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -32)
    tabAllBtn:SetText(L("TAB_ALL"))
    tabAllBtn:SetScript("OnClick", function()
        FB:SetTab("ALL")
    end)

    tabFavBtn = CreateFrame("Button", "ForeverBoardTabFav", mainFrame, "UIPanelButtonTemplate")
    tabFavBtn:SetSize(72, 20)
    tabFavBtn:SetPoint("LEFT", tabAllBtn, "RIGHT", 4, 0)
    tabFavBtn:SetText(L("TAB_FAV"))
    tabFavBtn:SetScript("OnClick", function()
        FB:SetTab("FAV")
    end)

    tabTrigBtn = CreateFrame("Button", "ForeverBoardTabTrig", mainFrame, "UIPanelButtonTemplate")
    tabTrigBtn:SetSize(68, 20)
    tabTrigBtn:SetPoint("LEFT", tabFavBtn, "RIGHT", 4, 0)
    tabTrigBtn:SetText(L("TAB_TRIGGERS"))
    tabTrigBtn:SetScript("OnClick", function()
        FB:SetTab("TRIGGERS")
    end)

    -- Caja de búsqueda debajo de las pestañas
    searchBox = CreateFrame("EditBox", "ForeverBoardSearchBox", mainFrame, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18, -58)
    searchBox:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -18, -58)
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
    -- Panel de Triggers Automáticos
    -- ==========================================
    triggerContent = CreateFrame("Frame", "ForeverBoardTriggerContent", mainFrame)
    triggerContent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -60)
    triggerContent:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 34)
    triggerContent:Hide()

    local trigTitle = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trigTitle:SetPoint("TOPLEFT", triggerContent, "TOPLEFT", 4, -4)
    trigTitle:SetText(L("TRIGGERS_TITLE"))

    -- Trigger 1: Subida de Nivel
    local chkLevel = CreateFrame("CheckButton", "ForeverBoardChkLevel", triggerContent, "UICheckButtonTemplate")
    chkLevel:SetSize(22, 22)
    chkLevel:SetPoint("TOPLEFT", trigTitle, "BOTTOMLEFT", 0, -8)
    chkLevel:SetChecked(ForeverBoardDB and ForeverBoardDB.triggerLevelUp)
    chkLevel:SetScript("OnClick", function(self)
        ForeverBoardDB.triggerLevelUp = self:GetChecked()
    end)
    local lblLevel = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblLevel:SetPoint("LEFT", chkLevel, "RIGHT", 4, 0)
    lblLevel:SetText(L("TRIG_LEVEL_TITLE"))

    local btnSoundLevel = CreateFrame("Button", "ForeverBoardBtnSoundLevel", triggerContent, "UIPanelButtonTemplate")
    btnSoundLevel:SetSize(150, 20)
    btnSoundLevel:SetPoint("TOPLEFT", chkLevel, "BOTTOMLEFT", 22, -2)
    btnSoundLevel:SetScript("OnClick", function(self)
        FB:OpenSoundDropDown(self, "triggerLevelUpSound", "levelUp")
    end)

    -- Trigger 2: Victoria de Boss
    local chkBoss = CreateFrame("CheckButton", "ForeverBoardChkBoss", triggerContent, "UICheckButtonTemplate")
    chkBoss:SetSize(22, 22)
    chkBoss:SetPoint("TOPLEFT", btnSoundLevel, "BOTTOMLEFT", -22, -10)
    chkBoss:SetChecked(ForeverBoardDB and ForeverBoardDB.triggerBossKill)
    chkBoss:SetScript("OnClick", function(self)
        ForeverBoardDB.triggerBossKill = self:GetChecked()
    end)
    local lblBoss = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblBoss:SetPoint("LEFT", chkBoss, "RIGHT", 4, 0)
    lblBoss:SetText(L("TRIG_BOSS_TITLE"))

    local btnSoundBoss = CreateFrame("Button", "ForeverBoardBtnSoundBoss", triggerContent, "UIPanelButtonTemplate")
    btnSoundBoss:SetSize(150, 20)
    btnSoundBoss:SetPoint("TOPLEFT", chkBoss, "BOTTOMLEFT", 22, -2)
    btnSoundBoss:SetScript("OnClick", function(self)
        FB:OpenSoundDropDown(self, "triggerBossKillSound", "bossKill")
    end)

    -- Trigger 3: Muerte propia
    local chkDead = CreateFrame("CheckButton", "ForeverBoardChkDead", triggerContent, "UICheckButtonTemplate")
    chkDead:SetSize(22, 22)
    chkDead:SetPoint("TOPLEFT", btnSoundBoss, "BOTTOMLEFT", -22, -10)
    chkDead:SetChecked(ForeverBoardDB and ForeverBoardDB.triggerDeath)
    chkDead:SetScript("OnClick", function(self)
        ForeverBoardDB.triggerDeath = self:GetChecked()
    end)
    local lblDead = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblDead:SetPoint("LEFT", chkDead, "RIGHT", 4, 0)
    lblDead:SetText(L("TRIG_DEAD_TITLE"))

    local btnSoundDead = CreateFrame("Button", "ForeverBoardBtnSoundDead", triggerContent, "UIPanelButtonTemplate")
    btnSoundDead:SetSize(150, 20)
    btnSoundDead:SetPoint("TOPLEFT", chkDead, "BOTTOMLEFT", 22, -2)
    btnSoundDead:SetScript("OnClick", function(self)
        FB:OpenSoundDropDown(self, "triggerDeathSound", "death")
    end)

    function FB:UpdateTriggerButtons()
        if btnSoundLevel and ForeverBoardDB then
            btnSoundLevel:SetText("> " .. FB:GetSoundDisplayName(ForeverBoardDB.triggerLevelUpSound, "levelUp"))
        end
        if btnSoundBoss and ForeverBoardDB then
            btnSoundBoss:SetText("> " .. FB:GetSoundDisplayName(ForeverBoardDB.triggerBossKillSound, "bossKill"))
        end
        if btnSoundDead and ForeverBoardDB then
            btnSoundDead:SetText("> " .. FB:GetSoundDisplayName(ForeverBoardDB.triggerDeathSound, "death"))
        end
    end

    -- Nota explicativa
    local note = triggerContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", btnSoundDead, "BOTTOMLEFT", -18, -14)
    note:SetPoint("RIGHT", triggerContent, "RIGHT", -4, 0)
    note:SetJustifyH("LEFT")
    note:SetText(L("TRIGGERS_NOTE"))

    -- ==========================================
    -- Barra inferior
    -- ==========================================
    combatCheck = CreateFrame("CheckButton", "ForeverBoardCombatCheck", mainFrame, "UICheckButtonTemplate")
    combatCheck:SetSize(20, 20)
    combatCheck:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, 6)
    combatCheck:SetChecked(ForeverBoardDB and ForeverBoardDB.muteInCombat)
    combatCheck:SetScript("OnClick", function(self)
        ForeverBoardDB.muteInCombat = self:GetChecked()
    end)

    local combatLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    combatLabel:SetPoint("LEFT", combatCheck, "RIGHT", 2, 0)
    combatLabel:SetText(L("MUTE_IN_COMBAT"))

    -- Selector de canal de audio
    channelBtn = CreateFrame("Button", "ForeverBoardChannelBtn", mainFrame, "UIPanelButtonTemplate")
    channelBtn:SetSize(105, 18)
    channelBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -22, 7)
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

    -- Contenedor con scroll para los botones
    scrollFrame = CreateFrame("ScrollFrame", "ForeverBoardScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -6, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -28, 30)

    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(220, 1)
    scrollFrame:SetScrollChild(contentFrame)

    -- Generar filas (botón de audio + estrella) para cada sonido
    local sounds = ForeverBoard_Sounds or {}
    local buttonHeight = 28

    for i, item in ipairs(sounds) do
        local btn = CreateFrame("Button", "ForeverBoardBtn_" .. item.id, contentFrame, "UIPanelButtonTemplate")
        btn:SetHeight(buttonHeight)
        btn:SetText(item.name)

        btn:SetScript("OnEnter", function(self)
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
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            FB:TriggerSound(item.id)
        end)

        local star = CreateFrame("Button", "ForeverBoardStar_" .. item.id, contentFrame, "UIPanelButtonTemplate")
        star:SetHeight(buttonHeight)

        local starIcon = star:CreateTexture(nil, "ARTWORK")
        starIcon:SetSize(16, 16)
        starIcon:SetPoint("CENTER", star, "CENTER", 0, 0)
        star.icon = starIcon

        star:SetScript("OnClick", function()
            FB:ToggleFavorite(item.id)
        end)
        star:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local isFav = FB:IsFavorite(item.id)
            if isFav then
                GameTooltip:AddLine(L("FAV_REMOVE_TOOLTIP"), 1, 0.3, 0.3)
            else
                GameTooltip:AddLine(L("FAV_ADD_TOOLTIP"), 1, 0.85, 0.2)
            end
            GameTooltip:Show()
        end)
        star:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        soundRows[i] = { btn = btn, star = star, item = item }
    end

    -- Pestaña de redimensionamiento (Resize Grip)
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

    resizeGrip:SetScript("OnMouseDown", function()
        if dropDownMenu then dropDownMenu:Hide() end
        mainFrame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        mainFrame:StopMovingOrSizing()
        local w, h = mainFrame:GetSize()
        if ForeverBoardDB then
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
        mainFrame:SetPoint(ForeverBoardDB.point or "CENTER", UIParent, ForeverBoardDB.point or "CENTER", ForeverBoardDB.posX, ForeverBoardDB.posY)
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
        end
    end)

    if not ok then
        print("|cff00ccff[ForeverBoard ERROR]|r " .. tostring(err))
    end
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

    -- Icono interior
    local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\Spell_ChargePositive")

    -- Borde circular estándar de Blizzard
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Mover alrededor del minimapa con Clic Derecho
    minimapBtn:RegisterForDrag("RightButton")
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

    -- Clic: Abrir/Cerrar SoundBoard
    minimapBtn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
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
