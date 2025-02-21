-- LaZHealer_Shaman.lua
_G.LaZHealer_Shaman = _G.LaZHealer_Shaman or {}
local ShamanModule = _G.LaZHealer_Shaman

ShamanModule.tidalWavesSoundPlayed = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-------------------------------------------------
ShamanModule.SPELL_HEALING_WAVE        = 77472
ShamanModule.SPELL_HEALING_SURGE       = 8004
ShamanModule.SPELL_RIPTIDE             = 61295
ShamanModule.SPELL_HEALING_RAIN        = 73920
ShamanModule.SPELL_CLOUDBURST_TOTEM    = 157153
ShamanModule.SPELL_TIDAL_WAVES         = 53390
ShamanModule.SPELL_ASCENDANCE          = 114052
ShamanModule.TALENT_CLOUDBURST_TOTEM   = 157153
ShamanModule.TALENT_ASCENDANCE         = 114052

-------------------------------------------------
-- Configuration
-------------------------------------------------
ShamanModule.StackSpell = ShamanModule.SPELL_TIDAL_WAVES
ShamanModule.PowerBoomSpell = ShamanModule.SPELL_CLOUDBURST_TOTEM

-------------------------------------------------
-- Sound Constants
-------------------------------------------------
local TIDAL_WAVES_SOUND = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407

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
    local hasTidalWaves = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(ShamanModule.SPELL_TIDAL_WAVES), "HELPFUL")
    if hasTidalWaves and not ShamanModule.tidalWavesSoundPlayed then
        PlaySound(TIDAL_WAVES_SOUND, "Master")
        ShamanModule.tidalWavesSoundPlayed = true
    elseif not hasTidalWaves then
        ShamanModule.tidalWavesSoundPlayed = false
    end
end

-------------------------------------------------
-- UI Update Functions
-------------------------------------------------
function ShamanModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    local aura = C_UnitAuras.GetAuraDataBySpellName("player", SafeGetSpellName(ShamanModule.StackSpell), "HELPFUL")
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(ShamanModule.StackSpell))
    UI.stackFrame.stackText:SetText(tostring(aura and aura.points and aura.points[1] or 0))
    UI.stackFrame.percentText:SetText("Tidal")
    UI.stackFrame:Show()
end

function ShamanModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end
    local spellName = SafeGetSpellName(ShamanModule.PowerBoomSpell)
    if IsUsableSpell(spellName) and IsPlayerSpell(ShamanModule.TALENT_CLOUDBURST_TOTEM) then
        UI.powerBoomFrame:Show()
        UI.powerBoomFrame.timerText:SetText("Ready")
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(ShamanModule.PowerBoomSpell))
    else
        UI.powerBoomFrame:Hide()
    end
end

function ShamanModule.UpdateClassUI()
    ShamanModule.UpdateStackFrameUI()
    ShamanModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function ShamanModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:SetScript("OnEvent", function(self, event, arg1, ...)
        UpdateSounds()
        ShamanModule.UpdateClassUI()
    end)
    ShamanModule.UpdateClassUI()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Shaman = ShamanModule