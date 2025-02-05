-- LaZHealer_UI.lua
-- Generic UI elements for LaZHealer

-- Ensure the main addon table exists.
local LaZHealer = _G.LaZHealer
if not LaZHealer then
    print("LaZHealer_UI: LaZHealer not found! Ensure the core file is loaded first.")
    return
end

-- Create (or reuse) a subtable for UI elements.
LaZHealer.UI = LaZHealer.UI or {}
local UI = LaZHealer.UI

-------------------------------------------------
-- UI Creation (General Frames)
-------------------------------------------------
local function CreateUIFrames()
    print("LaZHealer_UI: Creating generic UI frames...")

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
    print("LaZHealer_UI: UI frames created.")
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
    print("LaZHealer_UI: Creating Tank Frames...")
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
    print("UpdateTankFramesUI: Group count =", groupCount)
    if groupCount == 0 then
        UI.tankContainer:Hide()
        return
    else
        UI.tankContainer:Show()
    end

    local frameWidth = 75    -- 75 pixels wide
    local frameHeight = 50   -- 50 pixels tall
    local spacing = 5        -- Horizontal spacing between frames
    local tanks = {}         -- Temporary table for visible tank frames
    local count = 0

    for i = 1, groupCount do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            count = count + 1
            local name = UnitName(unit)
            local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100

            local tankFrame = UI.tankFrames[count]
            if not tankFrame then
                tankFrame = CreateFrame("Frame", "LaZHealerTankFrame" .. count, UI.tankContainer, "BackdropTemplate")
                tankFrame:SetSize(frameWidth, frameHeight)
                -- Apply a custom candy-like border using a custom texture.
                tankFrame:SetBackdrop({
                    bgFile = nil,  -- No default background.
                    edgeFile = "Interface\\AddOns\\LaZHealer\\Textures\\CandyBorder.tga", -- Replace with your custom border texture
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                -- Default border color white (candy look).
                tankFrame:SetBackdropBorderColor(1, 1, 1, 1)
                -- Create a background texture for health-based color.
                tankFrame.bg = tankFrame:CreateTexture(nil, "BACKGROUND")
                tankFrame.bg:SetAllPoints(tankFrame)
                tankFrame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                -- Create a gradient overlay using a texture.
                tankFrame.gradient = tankFrame:CreateTexture(nil, "ARTWORK")
                tankFrame.gradient:SetPoint("TOP", tankFrame, "TOP", 0, -3)  -- 3 pixels from the top.
                tankFrame.gradient:SetPoint("LEFT", tankFrame, "LEFT")
                tankFrame.gradient:SetPoint("RIGHT", tankFrame, "RIGHT")
                tankFrame.gradient:SetHeight(frameHeight * 0.5)  -- Cover top 50% of the frame.
                tankFrame.gradient:SetTexture("Interface\\AddOns\\LaZHealer\\Textures\\WhiteGradient.tga")
                -- Create a font string for the tank's name.
                tankFrame.nameText = tankFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                tankFrame.nameText:SetPoint("CENTER", tankFrame, "CENTER", 0, 10)
                tankFrame.nameText:SetJustifyH("CENTER")
                tankFrame.nameText:SetTextColor(1, 1, 1)
                -- Create a font string for the health percentage.
                tankFrame.hpText = tankFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                tankFrame.hpText:SetPoint("BOTTOM", tankFrame, "BOTTOM", 0, 2)
                tankFrame.hpText:SetJustifyH("CENTER")
                UI.tankFrames[count] = tankFrame
            end

            tankFrame.unit = unit
            tankFrame.nameText:SetText(name)
            tankFrame.hpText:SetText(string.format("%.0f%%", healthPercent))
            
            -- Update the background color based on health.
            if healthPercent > 50 then
                tankFrame.bg:SetColorTexture(0, 0.3, 0, 0.8)  -- Dark green.
            else
                local flash = math.abs(math.sin(GetTime() * 2))
                if flash > 0.5 then
                    tankFrame.bg:SetColorTexture(1, 0, 0, 0.8)  -- Red.
                else
                    tankFrame.bg:SetColorTexture(1, 0.4, 0, 0.8)  -- Orange.
                end
            end

            -- Check for aggro: if UnitThreatSituation >= 2, change border to red.
            local threat = UnitThreatSituation(unit)
            if threat and threat >= 2 then
                tankFrame:SetBackdropBorderColor(1, 0, 0, 1)
            else
                tankFrame:SetBackdropBorderColor(1, 1, 1, 1)
            end

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
end

local tankUpdater = CreateFrame("Frame")
tankUpdater:RegisterEvent("GROUP_ROSTER_UPDATE")
tankUpdater:RegisterEvent("UNIT_HEALTH")
tankUpdater:RegisterEvent("PLAYER_ENTERING_WORLD")
tankUpdater:SetScript("OnEvent", function(self, event, unit)
    print("Tank updater event:", event, unit or "")
    UpdateTankFramesUI()
end)

UI.CreateTankFrames = CreateTankFramesUI
UI.UpdateTankFrames = UpdateTankFramesUI

local tankLoginFrame = CreateFrame("Frame")
tankLoginFrame:RegisterEvent("PLAYER_LOGIN")
tankLoginFrame:SetScript("OnEvent", function(self, event, ...)
    UI.CreateTankFrames()
    UI.UpdateTankFrames()
    print("LaZHealer_UI: Tank Frames created and updated.")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
