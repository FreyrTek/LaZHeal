-- LaZHealer_Druid.lua
_G.LaZHealer_Druid = _G.LaZHealer_Druid or {}
local DruidModule = _G.LaZHealer_Druid

DruidModule.clearcastSoundPlayed = false
DruidModule.lifebloomSoundPlayed = false
DruidModule.efflorescenceSoundPlayed = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
DruidModule.SPELL_MARK_OF_THE_WILD         = 1126
DruidModule.SPELL_CLEARCASTING             = 16870
DruidModule.SPELL_EFFLORESCENCE            = 81262
DruidModule.SPELL_GROVE_GUARDIANS          = 102693
DruidModule.SPELL_REJUVENATION             = 774
DruidModule.SPELL_WILD_GROWTH              = 48438
DruidModule.SPELL_SWIFTMEND                = 18562
DruidModule.SPELL_REGROWTH                 = 8936
DruidModule.SPELL_LIFEBLOOM                = 33763
DruidModule.SPELL_INNERVATE                = 29166
DruidModule.SPELL_INCARNATION_TREE_OF_LIFE = 33891
DruidModule.TALENT_ABUNDANCE               = 207383
DruidModule.TALENT_GROVE_GUARDIANS         = 102693
DruidModule.TALENT_INCARNATION_TREE_OF_LIFE = 33891
DruidModule.BUFF_ABUNDANCE                 = 207640

-------------------------------------------------
-- Configuration
-------------------------------------------------
DruidModule.StackSpell = DruidModule.BUFF_ABUNDANCE
DruidModule.PowerBoomSpell = DruidModule.SPELL_INNERVATE

-------------------------------------------------
-- Sound Constants
-------------------------------------------------
local JACKPOT_SOUND1 = SOUNDKIT.UI_EPICLOOT_TOAST or 567406
local JACKPOT_SOUND2 = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407
local CLEARCAST_SOUND = JACKPOT_SOUND2
local EFFLORESCENCE_SOUND = SOUNDKIT.UI_RaidBossWhisperWarning or 41913

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
    local hasClearcast = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(DruidModule.SPELL_CLEARCASTING), "HELPFUL")
    if hasClearcast and not DruidModule.clearcastSoundPlayed then
        PlaySound(CLEARCAST_SOUND, "Master")
        DruidModule.clearcastSoundPlayed = true
    elseif not hasClearcast then
        DruidModule.clearcastSoundPlayed = false
    end

    local lifebloom = AuraUtil.FindAuraByName(SafeGetSpellName(DruidModule.SPELL_LIFEBLOOM), "player", "HELPFUL")
    if lifebloom and (lifebloom.expirationTime - GetTime()) <= 4 and not DruidModule.lifebloomSoundPlayed then
        PlaySound(JACKPOT_SOUND1, "Master")
        C_Timer.After(1.5, function() PlaySound(JACKPOT_SOUND2, "Master") end)
        DruidModule.lifebloomSoundPlayed = true
    else
        DruidModule.lifebloomSoundPlayed = false
    end

    if not C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(DruidModule.SPELL_EFFLORESCENCE), "HELPFUL") and not DruidModule.efflorescenceSoundPlayed then
        PlaySound(EFFLORESCENCE_SOUND, "Master")
        DruidModule.efflorescenceSoundPlayed = true
    else
        DruidModule.efflorescenceSoundPlayed = false
    end
end

-------------------------------------------------
-- UI Update Functions
-------------------------------------------------
function DruidModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    if not IsPlayerSpell(DruidModule.TALENT_ABUNDANCE) then
        UI.stackFrame:Hide()
        return
    end
    local buffName = SafeGetSpellName(DruidModule.StackSpell)
    local _, _, count = AuraUtil.FindAuraByName(buffName, "player", "HELPFUL")
    local stacks = count or 0
    local bonusPct = stacks * 8
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(DruidModule.StackSpell))
    UI.stackFrame.stackText:SetText(tostring(stacks))
    UI.stackFrame.percentText:SetText(bonusPct .. "%")
    UI.stackFrame:Show()
end

function DruidModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end
    local spellName = SafeGetSpellName(DruidModule.PowerBoomSpell)
    local aura = C_UnitAuras.GetAuraDataBySpellName("player", spellName, "HELPFUL")
    if aura and aura.expirationTime then
        UI.powerBoomFrame:Show()
        local remaining = math.floor(aura.expirationTime - GetTime())
        UI.powerBoomFrame.timerText:SetText(tostring(remaining))
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(DruidModule.PowerBoomSpell))
    else
        UI.powerBoomFrame:Hide()
    end
end

function DruidModule.UpdateClassUI()
    DruidModule.UpdateStackFrameUI()
    DruidModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function DruidModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        UpdateSounds()
        DruidModule.UpdateClassUI()
    end)
    DruidModule.UpdateClassUI()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Druid = DruidModule