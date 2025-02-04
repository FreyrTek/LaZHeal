-- LaZHealer_UI.lua
-- Generic UI elements for LaZHealer

-- Make sure the main addon table exists.
local LaZHealer = _G.LaZHealer
if not LaZHealer then
    print("LaZHealer_UI: LaZHealer not found! Ensure the core file is loaded first.")
    return
end

-- Create (or reuse) a subtable for UI elements.
LaZHealer.UI = LaZHealer.UI or {}
local UI = LaZHealer.UI

-------------------------------------------------
-- UI Creation
-------------------------------------------------
local function CreateUIFrames()
    print("LaZHealer_UI: Creating generic UI Frames...")

    -- Main Frame (movable)
    UI.mainFrame = CreateFrame("Frame", "LaZHealerMainFrame", UIParent)
    UI.mainFrame:SetSize(160, 120)
    UI.mainFrame:SetPoint("CENTER")
    UI.mainFrame:SetMovable(true)
    UI.mainFrame:EnableMouse(true)
    UI.mainFrame:RegisterForDrag("LeftButton")
    UI.mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
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
    -- Suggestion Icons (container for up to 3 icons)
    -------------------------------------------------
    UI.iconFrames = {}
    local iconSize = 50
    local spacing  = 55
    for i = 1, 3 do
        local frame = CreateFrame("Frame", "LaZHealerIcon" .. i, UI.mainFrame)
        frame:SetSize(iconSize, iconSize)
        frame:SetPoint("TOP", UI.manaBar, "BOTTOM", (i - 2) * spacing, -5)
        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        frame.texture = tex
        frame:Hide()
        UI.iconFrames[i] = frame
    end

    -------------------------------------------------
    -- Message Text (for generic status messages)
    -------------------------------------------------
    UI.messageText = UI.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.messageText:SetPoint("BOTTOM", UI.mainFrame, "BOTTOM", 0, 5)
    UI.messageText:SetText("LaZHealer Active")

    -------------------------------------------------
    -- Stack Frame (for Abundance buff tracking)
    --
    -- This frame displays:
    --   - The buff icon (on the left),
    --   - A large number for stacks (stackText) over the icon,
    --   - A smaller bonus percentage (percentText) to the right.
    -------------------------------------------------
    UI.stackFrame = CreateFrame("Frame", "LaZHealerStackFrame", UI.mainFrame)
    UI.stackFrame:SetSize(120, 40)
    UI.stackFrame:SetPoint("BOTTOM", UI.manaBar, "TOP", 0, 5)
    
    -- Icon for Abundance (placeholder texture; the class file will update it if needed)
    UI.stackFrame.icon = UI.stackFrame:CreateTexture(nil, "ARTWORK")
    UI.stackFrame.icon:SetSize(40, 40)
    UI.stackFrame.icon:SetPoint("LEFT", UI.stackFrame, "LEFT", 0, 0)
    UI.stackFrame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    
    -- Stack count text (displayed over the icon); set to a large font (e.g., 18pt)
    UI.stackFrame.stackText = UI.stackFrame:CreateFontString(nil, "OVERLAY")
    UI.stackFrame.stackText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    UI.stackFrame.stackText:SetPoint("CENTER", UI.stackFrame.icon, "CENTER", 0, 0)
    UI.stackFrame.stackText:SetText("0")
    
    -- Bonus percentage text (displayed to the right of the icon); set to a larger font (e.g., 30pt)
    UI.stackFrame.percentText = UI.stackFrame:CreateFontString(nil, "OVERLAY")
    UI.stackFrame.percentText:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
    UI.stackFrame.percentText:SetPoint("LEFT", UI.stackFrame.icon, "RIGHT", 5, 0)
    UI.stackFrame.percentText:SetText("0%")
    
    --UI.stackFrame:Hide()  -- Hide by default; the class module will show it when appropriate.

    -------------------------------------------------
    -- (Optional) PowerBoom Frame (for other class-specific tracking)
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

-- Create the UI frames when the player logs in.
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event, ...)
    CreateUIFrames()
    print("LaZHealer_UI: UI frames created.")
    self:UnregisterEvent("PLAYER_LOGIN")
end)

-------------------------------------------------
-- Generic UI Update Function
--
-- This function updates elements that are generic to the UI.
-- (It updates the mana bar, suggestion icons, and message text.)
-- Class modules are responsible for updating class-specific elements.
-------------------------------------------------
local function UpdateUI()
    if not UI or not UI.mainFrame then return end

    -- Update mana bar
    local currentMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (currentMana / maxMana) * 100 or 0
    UI.manaBar:SetValue(manaPercent)
    UI.manaText:SetText(string.format("%d%%", manaPercent))

    -- Update suggestion icons based on the healing evaluation.
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

    -- Note: Updates for UI.stackFrame and UI.powerBoomFrame are handled by class modules.
end

-- Periodically update the generic UI.
local uiUpdateFrame = CreateFrame("Frame")
local updateInterval = 0.5
local timeSinceLast = 0
uiUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLast = timeSinceLast + elapsed
    if timeSinceLast >= updateInterval then
        if UI and UI.mainFrame and UI.mainFrame:IsShown() then
            UpdateUI()
        end
        timeSinceLast = 0
    end
end)

-------------------------------------------------
-- Tank Frames UI
-------------------------------------------------
local function CreateTankFramesUI()
    print("LaZHealer_UI: Creating Tank Frames UI...")
    -- Create a container for tank frames
    UI.tankContainer = CreateFrame("Frame", "LaZHealerTankContainer", UIParent)
    UI.tankContainer:SetSize(200, 100)  -- Adjust as needed
    UI.tankContainer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
    UI.tankFrames = {}
end

local function UpdateTankFramesUI()
    if not UI or not UI.tankContainer then return end

    local tankIndex = 1
    local numGroup = GetNumGroupMembers()
    for i = 1, numGroup do
        local unit = IsInRaid() and "raid"..i or "party"..i
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            local name, class = UnitName(unit), select(2, UnitClass(unit))
            local healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100

            local tankFrame = UI.tankFrames[tankIndex]
            if not tankFrame then
                tankFrame = CreateFrame("Button", "LaZHealerTankFrame"..tankIndex, UI.tankContainer, "UIPanelButtonTemplate")
                tankFrame:SetSize(180, 20)  -- Adjust size as needed
                tankFrame:SetScript("OnClick", function(self)
                    if UnitExists(self.unit) then
                        TargetUnit(self.unit)
                    end
                end)
                UI.tankFrames[tankIndex] = tankFrame
            end

            tankFrame.unit = unit
            tankFrame:SetText(name)
            -- Set button color based on class using RAID_CLASS_COLORS
            local classColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
            tankFrame:SetNormalFontObject("GameFontNormalSmall")
            local normTex = tankFrame:GetNormalTexture() or tankFrame:CreateTexture(nil, "BACKGROUND")
            normTex:SetAllPoints()
            normTex:SetColorTexture(classColor.r, classColor.g, classColor.b, 1)
            tankFrame:SetNormalTexture(normTex)

            -- Flash if the tank's health is below 40%
            if healthPercent < 40 then
                local alpha = 0.5 + 0.5 * math.abs(math.sin(GetTime() * 2))
                tankFrame:SetAlpha(alpha)
            else
                tankFrame:SetAlpha(1)
            end

            -- Position the frame within the container
            tankFrame:SetPoint("TOPLEFT", UI.tankContainer, "TOPLEFT", 0, -((tankIndex - 1) * 22))
            tankFrame:Show()
            --print("Tank Frame " .. tankIndex .. ": " .. name .. " (" .. math.floor(healthPercent) .. "% HP)")
            tankIndex = tankIndex + 1
        end
    end

    -- Hide any unused tank frames.
    for j = tankIndex, #UI.tankFrames do
        UI.tankFrames[j]:Hide()
    end
end

-- Create an updater frame for the tank UI.
local tankUpdater = CreateFrame("Frame")
tankUpdater:RegisterEvent("GROUP_ROSTER_UPDATE")
tankUpdater:RegisterEvent("UNIT_HEALTH")
tankUpdater:SetScript("OnEvent", function(self, event, unit)
    UpdateTankFramesUI()
end)

-- Expose these functions in the UI table.
UI.CreateTankFrames = CreateTankFramesUI
UI.UpdateTankFrames = UpdateTankFramesUI

-- Initialize the tank UI when the player logs in.
local tankLoginFrame = CreateFrame("Frame")
tankLoginFrame:RegisterEvent("PLAYER_LOGIN")
tankLoginFrame:SetScript("OnEvent", function(self, event, ...)
    UI.CreateTankFrames()
    UI.UpdateTankFrames()
    print("LaZHealer_UI: Tank frames created and updated.")
    self:UnregisterEvent("PLAYER_LOGIN")
end)
