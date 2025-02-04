-- LaZHealer_Paladin.lua
-- Holy Paladin module for LaZHealer

_G.LaZHealer_Paladin = _G.LaZHealer_Paladin or {}
local PaladinModule = _G.LaZHealer_Paladin

print("LaZHealer_Paladin module loaded.")

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
-- Example spell IDs (adjust as needed)
PaladinModule.SPELL_HOLY_SHOCK         = 20473       -- Instant heal/damage
PaladinModule.SPELL_WORD_OF_GLORY      = 85673       -- Heals using Holy Power
PaladinModule.SPELL_BEACON_OF_LIGHT    = 53563       -- Beacon buff to be maintained on a target
PaladinModule.SPELL_AVENGING_CRUSADER  = 31884       -- Buff (for PowerBoomFrame)

-------------------------------------------------
-- Configuration: Which spells to watch?
-------------------------------------------------
-- The stackFrame will display Holy Power.
PaladinModule.StackType = "HOLY_POWER"
-- The powerBoomFrame will show Avenging Crusader.
PaladinModule.PowerBoomSpell = PaladinModule.SPELL_AVENGING_CRUSADER

-------------------------------------------------
-- Icon Setup for StackFrame
-------------------------------------------------
-- Use the "AfterImage" icon for the stackFrame.
-- (Adjust the texture path if needed; this is a placeholder.)
PaladinModule.ICON_AFTERIMAGE = "Interface\\Icons\\Spell_Holy_AfterImage"

-------------------------------------------------
-- Safe Spell Functions
-------------------------------------------------
local function SafeGetSpellName(spellID)
    return C_Spell.GetSpellName(spellID) or "UnknownSpell"
end

local function SafeGetSpellTexture(spellID)
    local texture = C_Spell.GetSpellTexture(spellID)
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function UnitHasBuffBySpellID(unit, spellID)
    local spellName = SafeGetSpellName(spellID)
    if not spellName or spellName == "UnknownSpell" then return false end
    return C_UnitAuras.GetAuraDataBySpellName(unit, spellName, "HELPFUL") ~= nil
end

-------------------------------------------------
-- Core Evaluation Logic (for spell suggestions)
-------------------------------------------------
function PaladinModule.EvaluateSpellSuggestions()
    local suggestions = {}
    local holyPower = UnitPower("player", 9)  -- Holy Power (resource type 9)
    
    -- Example suggestion logic:
    -- If you have 3 or more Holy Power, suggest Word of Glory (a burst heal);
    -- otherwise, suggest Holy Shock.
    if holyPower >= 3 then
        table.insert(suggestions, PaladinModule.SPELL_WORD_OF_GLORY)
    else
        table.insert(suggestions, PaladinModule.SPELL_HOLY_SHOCK)
    end

    -- Always include Beacon of Light.
    table.insert(suggestions, PaladinModule.SPELL_BEACON_OF_LIGHT)
    
    -- Fill remaining slots with Holy Shock if fewer than 3 suggestions.
    while #suggestions < 3 do
        table.insert(suggestions, PaladinModule.SPELL_HOLY_SHOCK)
    end

    return suggestions, "Holy Paladin Suggestions"
end

-------------------------------------------------
-- UI Update Functions for Class-Specific Elements
-------------------------------------------------
-- Update the stackFrame to display Holy Power using the AfterImage icon.
function PaladinModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end

    -- Retrieve Holy Power (resource type 9)
    local holyPower = UnitPower("player", 9)
    
    -- Set the icon to the AfterImage texture.
    UI.stackFrame.icon:SetTexture(PaladinModule.ICON_AFTERIMAGE)
    
    -- Display the Holy Power count.
    UI.stackFrame.stackText:SetText(tostring(holyPower))
    
    -- Display the "percentage" as Holy Power * 10.
    local percentage = holyPower * 10
    UI.stackFrame.percentText:SetText(percentage .. "%")
    
    -- Set fonts: 30pt for percentage, 18pt for Holy Power count.
    UI.stackFrame.percentText:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
    UI.stackFrame.stackText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    
    -- Force the frame to be visible.
    UI.stackFrame:Show()
end

-- Update the powerBoomFrame to display Avenging Crusader if active.
function PaladinModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end

    local spellName = SafeGetSpellName(PaladinModule.PowerBoomSpell)
    local aura = C_UnitAuras.GetAuraDataBySpellName("player", spellName, "HELPFUL")
    if aura and aura.expirationTime then
        UI.powerBoomFrame:Show()
        local remaining = math.floor(aura.expirationTime - GetTime())
        UI.powerBoomFrame.timerText:SetText(tostring(remaining))
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(PaladinModule.PowerBoomSpell))
    else
        UI.powerBoomFrame:Hide()
    end
end

function PaladinModule.UpdateClassUI()
    PaladinModule.UpdateStackFrameUI()
    PaladinModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function PaladinModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        PaladinModule.UpdateClassUI()
    end)
    
    PaladinModule.UpdateStackFrameUI()
    PaladinModule.EvaluateSpellSuggestions()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Paladin = PaladinModule
