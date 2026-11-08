--[[
    ForeverBoard - UI
    Ventana flotante con buscador, control de silencio (Mute), silenciar en combate y botón en minimapa.
]]

ForeverBoard = ForeverBoard or {}
local FB = ForeverBoard

local mainFrame = nil
local searchBox = nil
local soundButtons = {}
local contentFrame = nil
local scrollFrame = nil
local muteBtn = nil
local combatCheck = nil

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
            muteBtn:SetText("|cffff4444Muted|r")
        else
            muteBtn:SetText("|cff88ff88Audio ON|r")
        end
    end
end

-- Actualiza la visibilidad y posición de los botones según el filtro de búsqueda
function FB:RefreshSoundList()
    if not contentFrame then return end

    local filter = ""
    if searchBox and searchBox.GetText then
        filter = strTrim(searchBox:GetText()):lower()
    end

    local sounds = ForeverBoard_Sounds or {}
    local buttonHeight = 28
    local spacing = 4
    local currentY = -4

    local parentWidth = (scrollFrame and scrollFrame.GetWidth and scrollFrame:GetWidth()) or 220
    local btnWidth = math.max(parentWidth - 28, 160)
    contentFrame:SetWidth(btnWidth)

    for i, item in ipairs(sounds) do
        local btn = soundButtons[i]
        if btn then
            local matches = true
            if filter ~= "" then
                local nameMatch = item.name and item.name:lower():find(filter, 1, true)
                local idMatch = item.id and item.id:lower():find(filter, 1, true)
                local descMatch = item.desc and item.desc:lower():find(filter, 1, true)
                matches = (nameMatch or idMatch or descMatch) ~= nil
            end

            if matches then
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, currentY)
                btn:SetWidth(btnWidth)
                btn:Show()
                currentY = currentY - (buttonHeight + spacing)
            else
                btn:Hide()
            end
        end
    end

    local totalHeight = math.abs(currentY) + 10
    contentFrame:SetHeight(math.max(totalHeight, 50))
end

function FB:CreateUI()
    if mainFrame then return mainFrame end

    local defaultWidth = (ForeverBoardDB and ForeverBoardDB.width) or 280
    local defaultHeight = (ForeverBoardDB and ForeverBoardDB.height) or 400

    -- Ventana principal
    mainFrame = CreateFrame("Frame", "ForeverBoardFrame", UIParent)
    mainFrame:SetSize(defaultWidth, defaultHeight)
    if mainFrame.SetMinResize then
        mainFrame:SetMinResize(240, 280)
        mainFrame:SetMaxResize(600, 800)
    elseif mainFrame.SetResizeBounds then
        mainFrame:SetResizeBounds(240, 280, 600, 800)
    end
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)

    -- Arrastrar ventana
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
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

    -- Fondo y bordes (Compatible Classic / Era / BackdropTemplate)
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
        mainFrame:Hide()
    end)

    -- Botón de Mute rápido en la cabecera
    muteBtn = CreateFrame("Button", "ForeverBoardMuteBtn", mainFrame, "UIPanelButtonTemplate")
    muteBtn:SetSize(72, 20)
    muteBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -8)
    muteBtn:SetScript("OnClick", function()
        ForeverBoardDB.isMuted = not ForeverBoardDB.isMuted
        FB:UpdateMuteVisuals()
        local status = ForeverBoardDB.isMuted and "|cffff4444Silenciado|r" or "|cff00ff00Activado|r"
        print("|cff00ccff[ForeverBoard]|r Sonido " .. status)
    end)
    muteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Silenciar / Activar sonido", 1, 1, 1)
        GameTooltip:AddLine("Pulsa para silenciar temporalmente los sonidos entrantes.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    muteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Caja de búsqueda
    searchBox = CreateFrame("EditBox", "ForeverBoardSearchBox", mainFrame, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18, -34)
    searchBox:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -18, -34)
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        FB:RefreshSoundList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- Barra inferior: Checkbox "Silenciar en combate"
    combatCheck = CreateFrame("CheckButton", "ForeverBoardCombatCheck", mainFrame, "UICheckButtonTemplate")
    combatCheck:SetSize(22, 22)
    combatCheck:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 12, 6)
    combatCheck:SetChecked(ForeverBoardDB and ForeverBoardDB.muteInCombat)
    combatCheck:SetScript("OnClick", function(self)
        ForeverBoardDB.muteInCombat = self:GetChecked()
    end)

    local combatLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    combatLabel:SetPoint("LEFT", combatCheck, "RIGHT", 4, 0)
    combatLabel:SetText("Silenciar en combate")

    -- Contenedor con scroll para los botones
    scrollFrame = CreateFrame("ScrollFrame", "ForeverBoardScrollFrame", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -6, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -28, 32)

    contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(220, 1)
    scrollFrame:SetScrollChild(contentFrame)

    -- Generar botones para cada sonido
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
            GameTooltip:AddLine("Comando: /fb play " .. item.id, 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            FB:TriggerSound(item.id)
        end)

        soundButtons[i] = btn
    end

    -- Pestaña de redimensionamiento (Resize Grip)
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

    resizeGrip:SetScript("OnMouseDown", function()
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

    -- Redimensionamiento en tiempo real mientras se arrastra
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
    FB:RefreshSoundList()

    mainFrame:Hide()
    return mainFrame
end

function FB:ToggleUI()
    local ok, err = pcall(function()
        local frame = self:CreateUI()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            if searchBox then
                searchBox:SetText("")
            end
            FB:UpdateMuteVisuals()
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
        GameTooltip:AddLine("Clic izquierdo: Abrir / Cerrar SoundBoard", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Clic derecho + Arrastrar: Mover icono", 0.5, 0.8, 1)
        local status = (ForeverBoardDB and ForeverBoardDB.isMuted) and "|cffff4444Silenciado|r" or "|cff00ff00Activo|r"
        GameTooltip:AddLine("Estado del audio: " .. status, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    FB:UpdateMinimapPosition()
    return minimapBtn
end
