-- LaZHealer_Paladin.lua
_G.LaZHealer_Paladin = _G.LaZHealer_Paladin or {}
local PaladinModule = _G.LaZHealer_Paladin

PaladinModule.beaconSoundPlayed = false
PaladinModule.infusionSoundPlayed = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
PaladinModule.SPELL_HOLY_SHOCK         = 20473
PaladinModule.SPELL_WORD_OF_GLORY      = 85673
PaladinModule.SPELL_BEACON_OF_LIGHT    = 53563
PaladinModule.SPELL_HOLY_LIGHT         = 82326
PaladinModule.SPELL_FLASH_OF_LIGHT     = 19750
PaladinModule.SPELL_INFUSION_OF_LIGHT  = 54149
PaladinModule.SPELL_AVENGING_WRATH     = 31884

-------------------------------------------------
-- Configuration
-------------------------------------------------
PaladinModule.StackSpell = PaladinModule.SPELL_INFUSION_OF_LIGHT
PaladinModule.PowerBoomSpell = PaladinModule.SPELL_AVENGING_WRATH

-------------------------------------------------
-- Sound Constants
-------------------------------------------------
local JACKPOT_SOUND1 = SOUNDKIT.UI_EPICLOOT_TOAST or 567406
local INFUSION_SOUND = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407

-------------------------------------------------
-- Safe Spell Functions
-------------------------------------------------
local function SafeGetSpellName(spellID)
    return C_Spell.GetSpellName(spellID) or "UnknownSpell"
end

local function SafeGetSpellTexture(spellID)
    return C_Spell.GetSpellTexture(spellID) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-------------------------------------------------
-- Sound Triggers
-------------------------------------------------
local function UpdateSounds()
    local hasInfusion = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(PaladinModule.SPELL_INFUSION_OF_LIGHT), "HELPFUL")
    if hasInfusion and not PaladinModule.infusionSoundPlayed then
        PlaySound(INFUSION_SOUND, "Master")
        PaladinModule.infusionSoundPlayed = true
    else
        PaladinModule.infusionSoundPlayed = false
    end

    local beaconMissing = false
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" and not C_UnitAuras.GetAuraDataBySpellName(unit, SafeGetSpellName(PaladinModule.SPELL_BEACON_OF_LIGHT), "HELPFUL") then
            beaconMissing = true
            break
        end
    end
    if beaconMissing and not PaladinModule.beaconSoundPlayed then
        PlaySound(JACKPOT_SOUND1, "Master")
        PaladinModule.beaconSoundPlayed = true
    else
        PaladinModule.beaconSoundPlayed = false
    end
end

-------------------------------------------------
-- UI Update Functions
-------------------------------------------------
function PaladinModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    local holyPower = UnitPower("player", 9)
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(PaladinModule.StackSpell))
    UI.stackFrame.stackText:SetText(tostring(holyPower))
    UI.stackFrame.percentText:SetText("Holy")
    UI.stackFrame:Show()
end

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
    f:RegisterEvent("UNIT_POWER_UPDATE")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        UpdateSounds()
        PaladinModule.UpdateClassUI()
    end)
    PaladinModule.UpdateClassUI()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Paladin = PaladinModule