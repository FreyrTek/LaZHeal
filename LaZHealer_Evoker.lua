-- LaZHealer_Evoker.lua
_G.LaZHealer_Evoker = _G.LaZHealer_Evoker or {}
local EvokerModule = _G.LaZHealer_Evoker

EvokerModule.reversionSoundPlayed = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
EvokerModule.SPELL_LIVING_FLAME    = 361469
EvokerModule.SPELL_VERDANT_EMBRACE = 360995
EvokerModule.SPELL_ECHO            = 364343
EvokerModule.SPELL_REVERSION       = 366155
EvokerModule.SPELL_DREAM_BREATH    = 355936
EvokerModule.SPELL_SPIRITBLOOM     = 367226
EvokerModule.SPELL_REWIND         = 363534
EvokerModule.TALENT_ECHO           = 364343
EvokerModule.TALENT_REWIND         = 363534

-------------------------------------------------
-- Configuration
-------------------------------------------------
EvokerModule.StackSpell = EvokerModule.SPELL_ECHO
EvokerModule.PowerBoomSpell = EvokerModule.SPELL_REWIND

-------------------------------------------------
-- Sound Constants
-------------------------------------------------
local REVERSION_SOUND = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407

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
    local hasReversion = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(EvokerModule.SPELL_REVERSION), "HELPFUL")
    if hasReversion and not EvokerModule.reversionSoundPlayed then
        PlaySound(REVERSION_SOUND, "Master")
        EvokerModule.reversionSoundPlayed = true
    else
        EvokerModule.reversionSoundPlayed = false
    end
end

-------------------------------------------------
-- UI Update Functions
-------------------------------------------------
function EvokerModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    local essence = UnitPower("player", 7)
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(EvokerModule.StackSpell))
    UI.stackFrame.stackText:SetText(tostring(essence))
    UI.stackFrame.percentText:SetText("Essence")
    UI.stackFrame:Show()
end

function EvokerModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end
    local spellName = SafeGetSpellName(EvokerModule.PowerBoomSpell)
    if IsUsableSpell(spellName) and IsPlayerSpell(EvokerModule.TALENT_REWIND) then
        UI.powerBoomFrame:Show()
        UI.powerBoomFrame.timerText:SetText("Ready")
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(EvokerModule.PowerBoomSpell))
    else
        UI.powerBoomFrame:Hide()
    end
end

function EvokerModule.UpdateClassUI()
    EvokerModule.UpdateStackFrameUI()
    EvokerModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function EvokerModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_POWER_UPDATE")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        UpdateSounds()
        EvokerModule.UpdateClassUI()
    end)
    EvokerModule.UpdateClassUI()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Evoker = EvokerModule