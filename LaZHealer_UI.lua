-- LaZHealer_UI.lua
-- Generic UI elements for LaZHealer

-- Set _debug = 1 to enable dummy tank frames for testing.
_debug = _debug or 0

-- Debug variables for dummy tank frames (only used if _debug == 1)
if _debug == 1 then
    _debugTank1Class   = _debugTank1Class or "DRUID"       -- First dummy tank is a Druid
    _debugTank2Class   = _debugTank2Class or "DEATHKNIGHT" -- Second dummy tank is a Deathknight
    _debugTank1Aggro   = (_debugTank1Aggro ~= nil) and _debugTank1Aggro or true
    _debugTank2Aggro   = (_debugTank2Aggro ~= nil) and _debugTank2Aggro or false
    _debugTank1Health  = _debugTank1Health or 49  -- Health percentage for dummy tank 1
    _debugTank2Health  = _debugTank2Health or 100 -- Health percentage for dummy tank 2
end

-------------------------------------------------
-- Ensure the main addon table exists.
-------------------------------------------------
local LaZHealer = _G.LaZHealer
if not LaZHealer then
    return
end

-- Create (or reuse) a subtable for UI elements.
LaZHealer.UI = LaZHealer.UI or {}
local UI = LaZHealer.UI

-------------------------------------------------
-- UI Creation (General Frames)
-------------------------------------------------
local function CreateUIFrames()
    -- Main Frame (movable)
    UI.mainFrame = CreateFrame("Frame", "LaZHealerMainFrame", UIParent)
    UI.mainFrame:SetSize(160, 120)
    UI.mainFrame:SetPoint("CENTER")
    UI.mainFrame:SetMovable(true)
    UI.mainFrame:EnableMouse(true)
    UI.mainFrame:RegisterForDrag("LeftButton")
    UI.mainFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    UI.mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, xOfs, yOfs = self:GetPoint()
        LaZHealerDB = LaZHealerDB or {}
        LaZHealerDB.point    = point
        LaZHealerDB.relPoint = relPoint
        LaZHealerDB.xOfs     = xOfs
        LaZHealerDB.yOfs     = yOfs
    end)
    if LaZHealerDB and LaZHealerDB.point then
        UI.mainFrame:ClearAllPoints()
        UI.mainFrame:SetPoint(LaZHealerDB.point, UIParent, LaZHealerDB.relPoint or "CENTER", LaZHealerDB.xOfs or 0, LaZHealerDB.yOfs or 0)
    end

    -------------------------------------------------
    -- Mana Bar (generic display)
    -------------------------------------------------
    UI.manaBar = CreateFrame("StatusBar", "LaZHealerManaBar", UI.mainFrame)
    UI.manaBar:SetSize(160, 16)
    UI.manaBar:SetPoint("TOP", UI.mainFrame, "TOP", 0, -5)
    UI.manaBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    UI.manaBar:SetStatusBarColor(0, 0.4, 1, 1)
    UI.manaBar.bg = UI.manaBar:CreateTexture(nil, "BACKGROUND")
    UI.manaBar.bg:SetAllPoints(true)
    UI.manaBar.bg:SetColorTexture(0, 0, 0, 0.5)
    UI.manaText = UI.manaBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.manaText:SetPoint("CENTER", UI.manaBar, "CENTER", 0, 0)
    UI.manaText:SetText("100%")

    -------------------------------------------------
    -- Suggestion Icons (for up to 3 icons)
    -------------------------------------------------
    UI.iconFrames = {}
    local iconSize = 50
    local spacing  = 55
    for i = 1, 3 do
        local iconFrame = CreateFrame("Frame", "LaZHealerIcon" .. i, UI.mainFrame)
        iconFrame:SetSize(iconSize, iconSize)
        iconFrame:SetPoint("TOP", UI.manaBar, "BOTTOM", (i - 2) * spacing, -5)
        local tex = iconFrame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        iconFrame.texture = tex
        iconFrame:Hide()
        UI.iconFrames[i] = iconFrame
    end

    -------------------------------------------------
    -- Message Text (for generic status messages)
    -------------------------------------------------
    UI.messageText = UI.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.messageText:SetPoint("BOTTOM", UI.mainFrame, "BOTTOM", 0, 5)
    UI.messageText:SetText("LaZHealer Active")

    -------------------------------------------------
    -- Stack Frame (for buff tracking)
    -------------------------------------------------
    UI.stackFrame = CreateFrame("Frame", "LaZHealerStackFrame", UI.mainFrame)
    UI.stackFrame:SetSize(120, 40)
    UI.stackFrame:SetPoint("BOTTOM", UI.manaBar, "TOP", 0, 5)
    UI.stackFrame.icon = UI.stackFrame:CreateTexture(nil, "ARTWORK")
    UI.stackFrame.icon:SetSize(40, 40)
    UI.stackFrame.icon:SetPoint("LEFT", UI.stackFrame, "LEFT", 0, 0)
    UI.stackFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    UI.stackFrame.stackText = UI.stackFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    UI.stackFrame.stackText:SetPoint("CENTER", UI.stackFrame.icon, "CENTER", 0, 0)
    UI.stackFrame.stackText:SetText("0")
    UI.stackFrame.percentText = UI.stackFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    UI.stackFrame.percentText:SetPoint("LEFT", UI.stackFrame.icon, "RIGHT", 5, 0)
    UI.stackFrame.percentText:SetText("0%")

    -------------------------------------------------
    -- (Optional) PowerBoom Frame (for class-specific tracking)
    -------------------------------------------------
    UI.powerBoomFrame = CreateFrame("Frame", "LaZHealerPowerBoomFrame", UI.mainFrame)
    UI.powerBoomFrame:SetSize(120, 120)
    UI.powerBoomFrame:SetPoint("BOTTOM", UI.stackFrame, "TOP", 0, 5)
    UI.powerBoomFrame.icon = UI.powerBoomFrame:CreateTexture(nil, "ARTWORK")
    UI.powerBoomFrame.icon:SetAllPoints(true)
    UI.powerBoomFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    UI.powerBoomFrame:SetScript("OnUpdate", function(self, elapsed)
        local pulseSpeed = 2
        local alpha = 0.5 + 0.5 * math.abs(math.sin(GetTime() * pulseSpeed))
        self.icon:SetAlpha(alpha)
    end)
    UI.powerBoomFrame.timerText = UI.powerBoomFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.powerBoomFrame.timerText:SetPoint("CENTER", UI.powerBoomFrame, "CENTER", 0, 20)
    UI.powerBoomFrame.timerText:SetText("0")
    UI.powerBoomFrame.rotatingText = UI.powerBoomFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.powerBoomFrame.rotatingText:SetPoint("CENTER", UI.powerBoomFrame, "CENTER", 0, -20)
    UI.powerBoomFrame.rotatingText:SetText("")
    UI.powerBoomFrame:Hide()
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event, ...)
    CreateUIFrames()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

-------------------------------------------------
-- Generic UI Update Function
-------------------------------------------------
local function UpdateUI()
    if not UI or not UI.mainFrame then return end
    local currentMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (currentMana / maxMana) * 100 or 0
    UI.manaBar:SetValue(manaPercent)
    UI.manaText:SetText(string.format("%d%%", manaPercent))
    local spells, reason = LaZHealer.EvaluateHealing()
    if spells and #spells > 0 then
        for i = 1, 3 do
            if spells[i] then
                local texture = C_Spell.GetSpellTexture(spells[i]) or "Interface\\Icons\\INV_Misc_QuestionMark"
                UI.iconFrames[i].texture:SetTexture(texture)
                UI.iconFrames[i]:Show()
            else
                UI.iconFrames[i]:Hide()
            end
        end
        UI.messageText:SetText("Suggesting Spells")
    else
        for i = 1, 3 do
            UI.iconFrames[i]:Hide()
        end
        UI.messageText:SetText(reason or "No Suggestions")
    end
end

local uiUpdateFrame = CreateFrame("Frame")
local updateInterval = 0.5
local elapsedTime = 0
uiUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedTime = elapsedTime + elapsed
    if elapsedTime >= updateInterval then
        if UI and UI.mainFrame and UI.mainFrame:IsShown() then
            UpdateUI()
        end
        elapsedTime = 0
    end
end)

-------------------------------------------------
-- Tank Frames UI (Modern Candy-Like Look)
-------------------------------------------------
local function CreateTankFramesUI()
    -- Use LaZHealerSuggestionsFrame if available; otherwise, use mainFrame as anchor.
    local anchorFrame = (LaZHealerSuggestionsFrame and LaZHealerSuggestionsFrame:IsShown()) and LaZHealerSuggestionsFrame or UI.mainFrame
    UI.tankContainer = CreateFrame("Frame", "LaZHealerTankContainer", UIParent)
    UI.tankContainer:SetSize(300, 70)  -- Container size; adjust as needed.
    UI.tankContainer:SetPoint("TOP", anchorFrame, "BOTTOM", 0, -10)
    UI.tankFrames = {}
end

local function UpdateTankFramesUI()
    if not UI or not UI.tankContainer then return end

    local groupCount = GetNumGroupMembers()
    if groupCount == 0 then
        UI.tankContainer:Hide()
    else
        UI.tankContainer:Show()
    end

    local frameWidth = 75    -- width for each tank frame
    local frameHeight = 50   -- height for each tank frame
    local spacing = 5        -- horizontal spacing between frames
    local tanks = {}         -- temporary table for visible tank frames
    local count = 0

    -- Normal (non-dummy) tank frames update (if in a group)
    for i = 1, groupCount do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            count = count + 1
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            local hpPercent = (maxHealth > 0) and (health / maxHealth) * 100 or 0

            local tankFrame = UI.tankFrames[count]
            if not tankFrame then
                -- Create as a secure unit button so system keybindings and context menus work.
                tankFrame = CreateFrame("Button", "LaZHealerTankFrame" .. count, UI.tankContainer, "SecureUnitButtonTemplate")
                tankFrame:RegisterForClicks("AnyUp")
                tankFrame:SetAttribute("type1", "target")
                
                tankFrame:SetSize(frameWidth, frameHeight)
                -- Create border textures (1px top/left/right, 2px bottom)
                tankFrame.topBorder = tankFrame:CreateTexture(nil, "OVERLAY")
                tankFrame.topBorder:SetPoint("TOPLEFT", tankFrame, "TOPLEFT", 0, 0)
                tankFrame.topBorder:SetPoint("TOPRIGHT", tankFrame, "TOPRIGHT", 0, 0)
                tankFrame.topBorder:SetHeight(1)
                tankFrame.topBorder:SetColorTexture(0, 0, 0, 1)
                
                tankFrame.leftBorder = tankFrame:CreateTexture(nil, "OVERLAY")
                tankFrame.leftBorder:SetPoint("TOPLEFT", tankFrame, "TOPLEFT", 0, 0)
                tankFrame.leftBorder:SetPoint("BOTTOMLEFT", tankFrame, "BOTTOMLEFT", 0, 0)
                tankFrame.leftBorder:SetWidth(1)
                tankFrame.leftBorder:SetColorTexture(0, 0, 0, 1)
                
                tankFrame.rightBorder = tankFrame:CreateTexture(nil, "OVERLAY")
                tankFrame.rightBorder:SetPoint("TOPRIGHT", tankFrame, "TOPRIGHT", 0, 0)
                tankFrame.rightBorder:SetPoint("BOTTOMRIGHT", tankFrame, "BOTTOMRIGHT", 0, 0)
                tankFrame.rightBorder:SetWidth(1)
                tankFrame.rightBorder:SetColorTexture(0, 0, 0, 1)
                
                tankFrame.bottomBorder = tankFrame:CreateTexture(nil, "OVERLAY")
                tankFrame.bottomBorder:SetPoint("BOTTOMLEFT", tankFrame, "BOTTOMLEFT", 0, 0)
                tankFrame.bottomBorder:SetPoint("BOTTOMRIGHT", tankFrame, "BOTTOMRIGHT", 0, 0)
                tankFrame.bottomBorder:SetHeight(2)
                tankFrame.bottomBorder:SetColorTexture(0, 0, 0, 1)
                
                -- Create inner box (inset by 1 px top/left/right and 2 px bottom)
                tankFrame.innerBox = CreateFrame("Frame", nil, tankFrame)
                tankFrame.innerBox:SetPoint("TOPLEFT", tankFrame, "TOPLEFT", 1, -1)
                tankFrame.innerBox:SetPoint("BOTTOMRIGHT", tankFrame, "BOTTOMRIGHT", -1, 2)
                tankFrame.innerBox.bg = tankFrame.innerBox:CreateTexture(nil, "BACKGROUND")
                tankFrame.innerBox.bg:SetAllPoints()
                tankFrame.innerBox.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                
                -- Combined text: Name and Health Percentage (centered, white, no outline)
                tankFrame.innerBox.text = tankFrame.innerBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                tankFrame.innerBox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
                tankFrame.innerBox.text:SetJustifyH("CENTER")
                tankFrame.innerBox.text:SetJustifyV("MIDDLE")
                tankFrame.innerBox.text:SetPoint("CENTER", tankFrame.innerBox, "CENTER", 0, 0)
                
                UI.tankFrames[count] = tankFrame
                
                tankFrame:SetScript("OnUpdate", function(self, elapsed)
                    local currentTime = GetTime()
                    if not UnitExists(self.unit) then return end
                    
                    local curHealth = UnitHealth(self.unit)
                    local maxHealth = UnitHealthMax(self.unit)
                    local hpPercent = (maxHealth > 0) and (curHealth / maxHealth) * 100 or 0
                    hpPercent = math.floor(hpPercent + 0.5)
                    
                    local r, g, b, a
                    if hpPercent < 50 then
                        local t = math.abs(math.sin(currentTime * 8))
                        r = 0.5 + 0.5 * t    -- rapidly pulsing from dark red to yellow
                        g = 0 + 1 * t
                        b = 0
                        a = 0.8
                    else
                        local _, class = UnitClass(self.unit)
                        local classColor = RAID_CLASS_COLORS[class] or { r = 0.5, g = 0.5, b = 0.5 }
                        if UnitInRange(self.unit) then
                            r, g, b, a = classColor.r, classColor.g, classColor.b, 0.8
                        else
                            r, g, b, a = 0.3, 0.3, 0.3, 0.8
                        end
                    end
                    local topColor = CreateColor(math.min(1, r + 0.1), math.min(1, g + 0.1), math.min(1, b + 0.1), a)
                    local bottomColor = CreateColor(r * 0.9, g * 0.9, b * 0.9, a)
                    self.innerBox.bg:SetGradient("VERTICAL", topColor, bottomColor)
                    
                    -- If unit has aggro, set border to dark red; otherwise, black.
                    local threat = UnitThreatSituation(self.unit)
                    if threat and threat >= 2 then
                        self.topBorder:SetColorTexture(0.5, 0, 0, 1)
                        self.leftBorder:SetColorTexture(0.5, 0, 0, 1)
                        self.rightBorder:SetColorTexture(0.5, 0, 0, 1)
                        self.bottomBorder:SetColorTexture(0.5, 0, 0, 1)
                    else
                        self.topBorder:SetColorTexture(0, 0, 0, 1)
                        self.leftBorder:SetColorTexture(0, 0, 0, 1)
                        self.rightBorder:SetColorTexture(0, 0, 0, 1)
                        self.bottomBorder:SetColorTexture(0, 0, 0, 1)
                    end
                    
                    local name = UnitName(self.unit)
                    self.innerBox.text:SetText(name .. "\n" .. hpPercent .. "%")
                    self.innerBox.text:SetTextColor(1, 1, 1, 1)
                    
                    self:SetAttribute("unit", self.unit)
                end)
            else
                tankFrame.unit = unit
                tankFrame:SetAttribute("unit", unit)
            end

            tankFrame.unit = unit
            tankFrame:Show()
            tanks[count] = tankFrame
        end
    end

    local totalWidth = count * frameWidth + (count - 1) * spacing
    for i = 1, count do
        local offset = -totalWidth / 2 + (i - 1) * (frameWidth + spacing) + frameWidth / 2
        tanks[i]:ClearAllPoints()
        tanks[i]:SetPoint("CENTER", UI.tankContainer, "CENTER", offset, 0)
    end

    for j = count + 1, #UI.tankFrames do
        UI.tankFrames[j]:Hide()
    end

    -- Debug condition: override with two dummy frames if _debug == 1.
    if _debug == 1 then
        UI.tankContainer:Show()
        UI.tankFrames = {}

        local frameWidth = 75
        local frameHeight = 50
        local spacing = 5

        for i = 1, 2 do
            local dummyFrame = CreateFrame("Button", "LaZHealerDummyTankFrame" .. i, UI.tankContainer, "SecureUnitButtonTemplate")
            dummyFrame:RegisterForClicks("AnyUp")
            dummyFrame:SetAttribute("type1", "target")
            dummyFrame:SetAttribute("unit", "player")  -- Dummy unit; adjust as needed.
            dummyFrame:SetSize(frameWidth, frameHeight)
            
            -- Border textures for dummy
            dummyFrame.topBorder = dummyFrame:CreateTexture(nil, "OVERLAY")
            dummyFrame.topBorder:SetPoint("TOPLEFT", dummyFrame, "TOPLEFT", 0, 0)
            dummyFrame.topBorder:SetPoint("TOPRIGHT", dummyFrame, "TOPRIGHT", 0, 0)
            dummyFrame.topBorder:SetHeight(1)
            dummyFrame.topBorder:SetColorTexture(0, 0, 0, 1)
            
            dummyFrame.leftBorder = dummyFrame:CreateTexture(nil, "OVERLAY")
            dummyFrame.leftBorder:SetPoint("TOPLEFT", dummyFrame, "TOPLEFT", 0, 0)
            dummyFrame.leftBorder:SetPoint("BOTTOMLEFT", dummyFrame, "BOTTOMLEFT", 0, 0)
            dummyFrame.leftBorder:SetWidth(1)
            dummyFrame.leftBorder:SetColorTexture(0, 0, 0, 1)
            
            dummyFrame.rightBorder = dummyFrame:CreateTexture(nil, "OVERLAY")
            dummyFrame.rightBorder:SetPoint("TOPRIGHT", dummyFrame, "TOPRIGHT", 0, 0)
            dummyFrame.rightBorder:SetPoint("BOTTOMRIGHT", dummyFrame, "BOTTOMRIGHT", 0, 0)
            dummyFrame.rightBorder:SetWidth(1)
            dummyFrame.rightBorder:SetColorTexture(0, 0, 0, 1)
            
            dummyFrame.bottomBorder = dummyFrame:CreateTexture(nil, "OVERLAY")
            dummyFrame.bottomBorder:SetPoint("BOTTOMLEFT", dummyFrame, "BOTTOMLEFT", 0, 0)
            dummyFrame.bottomBorder:SetPoint("BOTTOMRIGHT", dummyFrame, "BOTTOMRIGHT", 0, 0)
            dummyFrame.bottomBorder:SetHeight(2)
            dummyFrame.bottomBorder:SetColorTexture(0, 0, 0, 1)
            
            -- Inner box for dummy
            dummyFrame.innerBox = CreateFrame("Frame", nil, dummyFrame)
            dummyFrame.innerBox:SetPoint("TOPLEFT", dummyFrame, "TOPLEFT", 1, -1)
            dummyFrame.innerBox:SetPoint("BOTTOMRIGHT", dummyFrame, "BOTTOMRIGHT", -1, 2)
            dummyFrame.innerBox.bg = dummyFrame.innerBox:CreateTexture(nil, "BACKGROUND")
            dummyFrame.innerBox.bg:SetAllPoints()
            dummyFrame.innerBox.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
            
            dummyFrame.innerBox.text = dummyFrame.innerBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dummyFrame.innerBox.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
            dummyFrame.innerBox.text:SetJustifyH("CENTER")
            dummyFrame.innerBox.text:SetJustifyV("MIDDLE")
            dummyFrame.innerBox.text:SetPoint("CENTER", dummyFrame.innerBox, "CENTER", 0, 0)
            
            if i == 1 then
                dummyFrame.unitClass = _debugTank1Class or "DRUID"
                dummyFrame.debugAggro = (_debugTank1Aggro ~= nil) and _debugTank1Aggro or true
                dummyFrame.debugHealth = _debugTank1Health or 49
                dummyFrame.dummyName = "Meat Shield"
            else
                dummyFrame.unitClass = _debugTank2Class or "DEATHKNIGHT"
                dummyFrame.debugAggro = (_debugTank2Aggro ~= nil) and _debugTank2Aggro or false
                dummyFrame.debugHealth = _debugTank2Health or 100
                dummyFrame.dummyName = "Crash Test"
            end

            dummyFrame:SetScript("OnUpdate", function(self, elapsed)
                local currentTime = GetTime()
                local hpPercent = self.debugHealth
                local r, g, b, a
                if hpPercent < 50 then
                    local t = math.abs(math.sin(currentTime * 8))
                    r = 0.5 + 0.5 * t
                    g = 0 + 1 * t
                    b = 0
                    a = 0.8
                else
                    local classColor = RAID_CLASS_COLORS[self.unitClass] or { r = 0.5, g = 0.5, b = 0.5 }
                    r, g, b, a = classColor.r, classColor.g, classColor.b, 0.8
                end
                local topColor = CreateColor(math.min(1, r + 0.1), math.min(1, g + 0.1), math.min(1, b + 0.1), a)
                local bottomColor = CreateColor(r * 0.9, g * 0.9, b * 0.9, a)
                self.innerBox.bg:SetGradient("VERTICAL", topColor, bottomColor)
                
                if self.debugAggro then
                    self.topBorder:SetColorTexture(0.5, 0, 0, 1)
                    self.leftBorder:SetColorTexture(0.5, 0, 0, 1)
                    self.rightBorder:SetColorTexture(0.5, 0, 0, 1)
                    self.bottomBorder:SetColorTexture(0.5, 0, 0, 1)
                else
                    self.topBorder:SetColorTexture(0, 0, 0, 1)
                    self.leftBorder:SetColorTexture(0, 0, 0, 1)
                    self.rightBorder:SetColorTexture(0, 0, 0, 1)
                    self.bottomBorder:SetColorTexture(0, 0, 0, 1)
                end

                self.innerBox.text:SetText(self.dummyName .. "\n" .. tostring(hpPercent) .. "%")
                self.innerBox.text:SetTextColor(1, 1, 1, 1)
            end)

            dummyFrame:Show()
            UI.tankFrames[i] = dummyFrame
        end

        local totalWidth = 2 * frameWidth + spacing
        for i = 1, 2 do
            local offset = -totalWidth / 2 + (i - 1) * (frameWidth + spacing) + frameWidth / 2
            UI.tankFrames[i]:ClearAllPoints()
            UI.tankFrames[i]:SetPoint("CENTER", UI.tankContainer, "CENTER", offset, 0)
        end
    end
end

local tankUpdater = CreateFrame("Frame")
tankUpdater:RegisterEvent("GROUP_ROSTER_UPDATE")
tankUpdater:RegisterEvent("UNIT_HEALTH")
tankUpdater:RegisterEvent("PLAYER_ENTERING_WORLD")
tankUpdater:SetScript("OnEvent", function(self, event, unit)
    UpdateTankFramesUI()
end)

UI.CreateTankFrames = CreateTankFramesUI
UI.UpdateTankFrames = UpdateTankFramesUI

local tankLoginFrame = CreateFrame("Frame")
tankLoginFrame:RegisterEvent("PLAYER_LOGIN")
tankLoginFrame:SetScript("OnEvent", function(self, event, ...)
    UI.CreateTankFrames()
    UI.UpdateTankFrames()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
