-- LaZHealer_Mistweaver.lua
_G.LaZHealer_Mistweaver = _G.LaZHealer_Mistweaver or {}
local MistweaverModule = _G.LaZHealer_Mistweaver

MistweaverModule.vitalitySoundPlayed = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
MistweaverModule.SPELL_SOOTHING_MIST   = 115175
MistweaverModule.SPELL_VIVIFY          = 116670
MistweaverModule.SPELL_ENVELOPING_MIST = 124682
MistweaverModule.SPELL_RENEWING_MIST   = 115151
MistweaverModule.SPELL_ESSENCE_FONT    = 191837
MistweaverModule.SPELL_MANA_TEA        = 197908
MistweaverModule.SPELL_VITALITY        = 116670
MistweaverModule.TALENT_MANA_TEA       = 197908

-------------------------------------------------
-- Configuration
-------------------------------------------------
MistweaverModule.StackSpell = MistweaverModule.SPELL_RENEWING_MIST
MistweaverModule.PowerBoomSpell = MistweaverModule.SPELL_MANA_TEA

-------------------------------------------------
-- Sound Constants
-------------------------------------------------
local VITALITY_SOUND = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407

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
    local hasVitality = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(MistweaverModule.SPELL_VITALITY), "HELPFUL")
    if hasVitality and not MistweaverModule.vitalitySoundPlayed then
        PlaySound(VITALITY_SOUND, "Master")
        MistweaverModule.vitalitySoundPlayed = true
    else
        MistweaverModule.vitalitySoundPlayed = false
    end
end

-------------------------------------------------
-- UI Update Functions
-------------------------------------------------
function MistweaverModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    local count = 0
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        if UnitExists(unit) and C_UnitAuras.GetAuraDataBySpellName(unit, SafeGetSpellName(MistweaverModule.SPELL_RENEWING_MIST), "HELPFUL") then
            count = count + 1
        end
    end
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(MistweaverModule.StackSpell))
    UI.stackFrame.stackText:SetText(tostring(count))
    UI.stackFrame.percentText:SetText("Renew")
    UI.stackFrame:Show()
end

function MistweaverModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end
    local spellName = SafeGetSpellName(MistweaverModule.PowerBoomSpell)
    if IsUsableSpell(spellName) and IsPlayerSpell(MistweaverModule.TALENT_MANA_TEA) then
        UI.powerBoomFrame:Show()
        UI.powerBoomFrame.timerText:SetText("Ready")
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(MistweaverModule.PowerBoomSpell))
    else
        UI.powerBoomFrame:Hide()
    end
end

function MistweaverModule.UpdateClassUI()
    MistweaverModule.UpdateStackFrameUI()
    MistweaverModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function MistweaverModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        UpdateSounds()
        MistweaverModule.UpdateClassUI()
    end)
    MistweaverModule.UpdateClassUI()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Mistweaver = MistweaverModule