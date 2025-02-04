-- LaZHealer_Druid.lua
-- Druid module for LaZHealer

_G.LaZHealer_Druid = _G.LaZHealer_Druid or {}
local DruidModule = _G.LaZHealer_Druid

-- Flags to track recent casts for forced suggestions.
DruidModule.lastSwiftMendCast = false
DruidModule.lastWildGrowthCast = false

-- State flags to ensure that Clearcast, Lifebloom, and Efflorescence sounds
-- play only once per suggestion cycle.
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
DruidModule.SPELL_IRONBARK                 = 102342
DruidModule.SPELL_LIFEBLOOM                = 33763
DruidModule.SPELL_INNERVATE                = 29166
DruidModule.SPELL_TRANQUILITY              = 740
DruidModule.SPELL_SOUL_OF_THE_FOREST       = 114108
DruidModule.SPELL_NOURISH                  = 50464
DruidModule.SPELL_RENEWAL                  = 108238
DruidModule.SPELL_NATURES_SWIFTNESS        = 132158
DruidModule.SPELL_INCARNATION_TREE_OF_LIFE = 33891

-- Abundance: Talent and Buff
DruidModule.TALENT_ABUNDANCE = 207383
DruidModule.BUFF_ABUNDANCE   = 207640

-------------------------------------------------
-- Configuration: Which spells to watch?
-------------------------------------------------
DruidModule.StackSpell = DruidModule.BUFF_ABUNDANCE      -- For stackFrame (Abundance)
DruidModule.PowerBoomSpell = DruidModule.SPELL_INNERVATE   -- For powerBoomFrame (Innervate)

-------------------------------------------------
-- Sound Constants for Beep Triggers
-------------------------------------------------
local JACKPOT_SOUND1 = SOUNDKIT.UI_EPICLOOT_TOAST or 567406
local JACKPOT_SOUND2 = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 567407
-- Use an alternate sound constant for Clearcasting.
local CLEARCAST_SOUND = JACKPOT_SOUND2
local EFFLORESCENCE_SOUND = SOUNDKIT.UI_RaidBossWhisperWarning or 41913

local SPELL_BEEP_INFO = {
    [DruidModule.SPELL_LIFEBLOOM] = {
        onBeep = function()
            PlaySound(JACKPOT_SOUND1, "Master")
            C_Timer.After(1.5, function() PlaySound(JACKPOT_SOUND2, "Master") end)
        end,
    },
    [DruidModule.SPELL_REGROWTH] = {
        onBeep = function() PlaySound(8959, "Master") end,  -- "Ready Check Ding"
    },
}

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
    if not spellName or spellName == "UnknownSpell" then
        return false
    end
    return C_UnitAuras.GetAuraDataBySpellName(unit, spellName, "HELPFUL") ~= nil
end

-------------------------------------------------
-- Helper for Clearcasting Detection
-------------------------------------------------
local function HasClearcast()
    local name = SafeGetSpellName(DruidModule.SPELL_CLEARCASTING)
    if name == "UnknownSpell" then
        return false
    end
    local aura = AuraUtil.FindAuraByName(name, "player", "HELPFUL")
    return aura ~= nil
end

-------------------------------------------------
-- Helper Functions for Spell Suggestions
-------------------------------------------------
-- Returns true if any group member (raid or party) has Lifebloom.
local function GroupHasLifebloom()
    local numGroup = GetNumGroupMembers()
    for i = 1, numGroup do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            unit = (i == 1) and "player" or ("party" .. (i - 1))
        end
        if UnitExists(unit) and UnitHasBuffBySpellID(unit, DruidModule.SPELL_LIFEBLOOM) then
            return true
        end
    end
    return false
end

-- Returns the minimum remaining time on Lifebloom among group members.
local function GetLifebloomRemainingOnGroup()
    local minRemain = 999
    local found = false
    local numGroup = GetNumGroupMembers()
    for i = 1, numGroup do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            unit = (i == 1) and "player" or ("party" .. (i - 1))
        end
        if UnitExists(unit) then
            local aura = AuraUtil.FindAuraByName(SafeGetSpellName(DruidModule.SPELL_LIFEBLOOM), unit, "HELPFUL")
            if aura and aura.expirationTime then
                found = true
                local remain = aura.expirationTime - GetTime()
                if remain < minRemain then
                    minRemain = remain
                end
            else
                found = true
                minRemain = 0
                break
            end
        end
    end
    if not found then
        return nil
    end
    return minRemain
end

local function GetLowestTankHP()
    local lowest = 100
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            local hp = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
            if hp < lowest then
                lowest = hp
            end
        end
    end
    return lowest
end

-------------------------------------------------
-- Core Evaluation Logic (for spell suggestions)
-------------------------------------------------
function DruidModule.EvaluateSpellSuggestions()
    -- Special override: if Incarnation: Tree of Life is active, use a dedicated sequence.
    if UnitHasBuffBySpellID("player", DruidModule.SPELL_INCARNATION_TREE_OF_LIFE) then
        local treeSequence = {
            DruidModule.SPELL_WILD_GROWTH,
            DruidModule.SPELL_REJUVENATION,
            DruidModule.SPELL_INNERVATE
        }
        return treeSequence, "Tree of Life Active"
    end

    -- New override: if Soul of the Forest buff is active, force Wild Growth.
    if UnitHasBuffBySpellID("player", DruidModule.SPELL_SOUL_OF_THE_FOREST) then
        return { DruidModule.SPELL_WILD_GROWTH }, "Soul of the Forest Active: Cast Wild Growth"
    end

    -- Forced override: if Swiftmend was cast last, force Wild Growth then Regrowth.
    if DruidModule.lastSwiftMendCast then
        DruidModule.lastSwiftMendCast = false
        return { DruidModule.SPELL_WILD_GROWTH, DruidModule.SPELL_REGROWTH }, "Post Swiftmend: Wild Growth then Regrowth"
    end

    -- Forced override: if Wild Growth was cast last, force Regrowth next.
    if DruidModule.lastWildGrowthCast then
        DruidModule.lastWildGrowthCast = false
        return { DruidModule.SPELL_REGROWTH }, "Post Wild Growth: Regrowth"
    end

    local ctx = {
        manaPercent       = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100,
        hasMark           = UnitHasBuffBySpellID("player", DruidModule.SPELL_MARK_OF_THE_WILD),
        hasClearcast      = HasClearcast(),
        lowestTankHP      = GetLowestTankHP(),
        hasEfflorescence = UnitHasBuffBySpellID("player", DruidModule.SPELL_EFFLORESCENCE)
    }
    
    -- SOUND TRIGGERS:
    -- Clearcasting: play the sound once per suggestion cycle when the buff is active.
    if ctx.hasClearcast then
        if not DruidModule.clearcastSoundPlayed then
            PlaySound(CLEARCAST_SOUND, "Master")
            DruidModule.clearcastSoundPlayed = true
        end
    else
        DruidModule.clearcastSoundPlayed = false
    end

    -- Lifebloom: play the sound once per suggestion cycle if remaining time <= 4 seconds.
    local lifebloomRemaining = GetLifebloomRemainingOnGroup()
    if lifebloomRemaining and lifebloomRemaining <= 4 then
        if not DruidModule.lifebloomSoundPlayed then
            SPELL_BEEP_INFO[DruidModule.SPELL_LIFEBLOOM].onBeep()
            DruidModule.lifebloomSoundPlayed = true
        end
    else
        DruidModule.lifebloomSoundPlayed = false
    end

    -- Efflorescence: play the sound once per suggestion cycle if missing.
    if not ctx.hasEfflorescence then
        if not DruidModule.efflorescenceSoundPlayed then
            PlaySound(EFFLORESCENCE_SOUND, "Master")
            DruidModule.efflorescenceSoundPlayed = true
        end
    else
        DruidModule.efflorescenceSoundPlayed = false
    end

    local suggestions = {}
    if not ctx.hasMark then
        table.insert(suggestions, DruidModule.SPELL_MARK_OF_THE_WILD)
    end
    if not ctx.hasEfflorescence then
        table.insert(suggestions, DruidModule.SPELL_EFFLORESCENCE)
    end
    -- Instead of requiring every group member to have Lifebloom,
    -- we suggest it only if no one has it.
    if not GroupHasLifebloom() then
        table.insert(suggestions, DruidModule.SPELL_LIFEBLOOM)
    end
    if ctx.lowestTankHP < 30 then
        table.insert(suggestions, DruidModule.SPELL_SWIFTMEND)
    end
    if ctx.hasClearcast then
        table.insert(suggestions, DruidModule.SPELL_REGROWTH)
    end

    local abundanceName, _, abundanceCount = AuraUtil.FindAuraByName(SafeGetSpellName(DruidModule.BUFF_ABUNDANCE), "player", "HELPFUL")
    local bonusPct = (abundanceCount or 0) * 8

    local alternatives = { DruidModule.SPELL_REJUVENATION }
    local ggName, _, ggCount = AuraUtil.FindAuraByName(SafeGetSpellName(DruidModule.SPELL_GROVE_GUARDIANS), "player", "HELPFUL")
    if ggName and ggCount and ggCount > 0 then
        table.insert(alternatives, DruidModule.SPELL_GROVE_GUARDIANS)
    end

    local altIndex = 1
    while #suggestions < 3 do
        if bonusPct < 16 then
            table.insert(suggestions, DruidModule.SPELL_REJUVENATION)
        else
            table.insert(suggestions, alternatives[altIndex])
            altIndex = altIndex + 1
            if altIndex > #alternatives then altIndex = 1 end
        end
    end

    if DruidModule.lastSwiftMendCast then
        for i = #suggestions, 1, -1 do
            if suggestions[i] == DruidModule.SPELL_SWIFTMEND then
                table.remove(suggestions, i)
            end
        end
        table.insert(suggestions, 1, DruidModule.SPELL_WILD_GROWTH)
        while #suggestions > 3 do table.remove(suggestions) end
        DruidModule.lastSwiftMendCast = false
    end

    local wildIndex = nil
    for i, spell in ipairs(suggestions) do
        if spell == DruidModule.SPELL_WILD_GROWTH then
            wildIndex = i
            break
        end
    end
    if wildIndex then
        local alreadyHasRegrowth = false
        for _, spell in ipairs(suggestions) do
            if spell == DruidModule.SPELL_REGROWTH then
                alreadyHasRegrowth = true
                break
            end
        end
        if not alreadyHasRegrowth then
            table.insert(suggestions, wildIndex + 1, DruidModule.SPELL_REGROWTH)
            while #suggestions > 3 do table.remove(suggestions) end
        end
    end

    return suggestions, "LaZHealer Active"
end

-------------------------------------------------
-- UI Update Functions for Class-Specific Elements
-------------------------------------------------
function DruidModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    if not IsPlayerSpell(DruidModule.TALENT_ABUNDANCE) then
        UI.stackFrame:Hide()
        return
    end
    UI.stackFrame:Show()
    local targetSpellID = DruidModule.StackSpell
    local buffName = SafeGetSpellName(targetSpellID)
    if buffName then
        local name, icon, count = AuraUtil.FindAuraByName(buffName, "player", "HELPFUL")
        local stacks = (name and count) and count or 0
        local maxStacks = 12
        local cappedStacks = math.min(stacks, maxStacks)
        local bonusPct = cappedStacks * 8
        UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(targetSpellID))
        UI.stackFrame.stackText:SetText(tostring(stacks))
        UI.stackFrame.percentText:SetText(bonusPct .. "%")
        UI.stackFrame.percentText:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
        UI.stackFrame.stackText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        UI.stackFrame:Show()
    else
        UI.stackFrame:Hide()
    end
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
-- OnUpdate Timer for Frequent UI Updates
-------------------------------------------------
local updateFrame = CreateFrame("Frame", "LaZHealer_Druid_UpdateFrame", UIParent)
local updateInterval = 0.5
local timeSinceLastUpdate = 0
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        DruidModule.UpdateClassUI()
        timeSinceLastUpdate = 0
    end
end)

-------------------------------------------------
-- Event Handling (for spell suggestion updates)
-------------------------------------------------
local function UpdateLaZHealer()
    local spells, message = DruidModule.EvaluateSpellSuggestions()
    return spells, message
end

local function OnEvent(self, event, arg1, ...)
    if event == "UNIT_AURA" and arg1 == "player" then
        UpdateLaZHealer()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local castSpellName = select(2, ...)
        if castSpellName == SafeGetSpellName(DruidModule.SPELL_SWIFTMEND) then
            DruidModule.lastSwiftMendCast = true
        elseif castSpellName == SafeGetSpellName(DruidModule.SPELL_WILD_GROWTH) then
            DruidModule.lastWildGrowthCast = true
        end
        UpdateLaZHealer()
    else
        UpdateLaZHealer()
    end
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function DruidModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:SetScript("OnEvent", OnEvent)
    
    DruidModule.UpdateStackFrameUI()
    UpdateLaZHealer()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Druid = DruidModule
