-- LaZHealer_Shaman.lua
-- Totemic Restoration Shaman module for LaZHealer

_G.LaZHealer_Shaman = _G.LaZHealer_Shaman or {}
local ShamanModule = _G.LaZHealer_Shaman

-------------------------------------------------
-- Flags for tracking recent casts.
-------------------------------------------------
ShamanModule.lastHealingSurgeCast = false
ShamanModule.lastRiptideCast = false

-------------------------------------------------
-- Spell/Talent/Buff IDs
-- (Replace placeholder IDs as needed.)
-------------------------------------------------
ShamanModule.SPELL_TIDAL_WAVES           = 308827  -- Tidal Waves (max 2 stacks)
ShamanModule.SPELL_RIPTIDE                = 61295   -- Riptide (builds Tidal Waves)
ShamanModule.SPELL_HEALING_SURGE          = 8004    -- Healing Surge (consumes Tidal Waves)
ShamanModule.SPELL_CHAIN_HEAL            = 1064    -- Chain Heal (group heal)
ShamanModule.SPELL_HEALING_WAVE           = 77472   -- Healing Wave (cheaper single-target heal)
ShamanModule.SPELL_HEALING_RAIN           = 73920   -- Healing Rain (if available)
ShamanModule.SPELL_SURGING_TOTEM          = 280615  -- Surging Totem (if available instead of Healing Rain)
ShamanModule.SPELL_SPIRIT_LINK_TOTEM      = 98008   -- Spirit Link Totem (emergency override)
ShamanModule.SPELL_WIND_BARRIER           = 192081  -- Wind Barrier (defensive)
ShamanModule.SPELL_EARTH_SHIELD           = 974     -- Earth Shield
ShamanModule.SPELL_WATER_SHIELD           = 52127   -- Water Shield
ShamanModule.SPELL_UNLEASH_LIFE           = 73685   -- Unleash Life
ShamanModule.SPELL_CLOUDBURST_TOTEM       = 157153  -- Cloudburst Totem
ShamanModule.SPELL_HEALING_STREAM_TOTEM   = 52042   -- Healing Stream Totem (if Cloudburst isn’t known)
ShamanModule.SPELL_SKYFURY                = 123456  -- Skyfury (placeholder)
ShamanModule.SPELL_ASCENDANCE             = 114049  -- Ascendance (placeholder for Restoration Ascendance)

-------------------------------------------------
-- Configuration: StackSpell and PowerBoomSpell.
-------------------------------------------------
ShamanModule.StackSpell = ShamanModule.SPELL_TIDAL_WAVES      -- Display Tidal Waves stacks.
ShamanModule.PowerBoomSpell = ShamanModule.SPELL_ASCENDANCE    -- Track Ascendance.

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
-- Helper: Check if Earth Shield is missing on the player or any tank.
-------------------------------------------------
local function EarthShieldMissing()
    if not UnitHasBuffBySpellID("player", ShamanModule.SPELL_EARTH_SHIELD) then
        return true
    end
    local numGroup = GetNumGroupMembers()
    for i = 1, numGroup do
        local unit = IsInRaid() and "raid" .. i or ((i == 1) and "player" or ("party" .. (i - 1)))
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            if not UnitHasBuffBySpellID(unit, ShamanModule.SPELL_EARTH_SHIELD) then
                return true
            end
        end
    end
    return false
end

-------------------------------------------------
-- Helper: Check if any group member has the Skyfury buff.
-------------------------------------------------
local function GroupHasSkyfury()
    local numGroup = GetNumGroupMembers()
    for i = 1, numGroup do
        local unit = IsInRaid() and "raid" .. i or ((i == 1) and "player" or ("party" .. (i - 1)))
        if UnitExists(unit) and UnitHasBuffBySpellID(unit, ShamanModule.SPELL_SKYFURY) then
            return true
        end
    end
    return false
end

-------------------------------------------------
-- Helper: Returns the number of Tidal Waves stacks.
-------------------------------------------------
local function GetTidalWavesStacks()
    local buffName = SafeGetSpellName(ShamanModule.SPELL_TIDAL_WAVES)
    if not buffName or buffName == "UnknownSpell" then return 0 end
    local aura = AuraUtil.FindAuraByName(buffName, "player", "HELPFUL")
    if aura and aura.stackCount then
        return aura.stackCount
    end
    return 0
end

-------------------------------------------------
-- Helper: Returns the lowest health percentage among tanks.
-------------------------------------------------
local function GetLowestTankHP()
    local lowest = 100
    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or ((i == 1) and "player" or ("party" .. (i - 1)))
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
function ShamanModule.EvaluateSpellSuggestions()
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    local tidalStacks = GetTidalWavesStacks()
    local lowestTankHP = GetLowestTankHP()
    local groupSize = GetNumGroupMembers()
    local suggestions = {}

    -- SPECIAL OVERRIDES:
    if UnitHasBuffBySpellID("player", ShamanModule.SPELL_SPIRIT_LINK_TOTEM) then
        local seq = {
            ShamanModule.SPELL_SPIRIT_LINK_TOTEM,
            ShamanModule.SPELL_CHAIN_HEAL,
            ShamanModule.SPELL_HEALING_SURGE
        }
        return seq, "Spirit Link Totem Active"
    end

    if UnitHasBuffBySpellID("player", ShamanModule.SPELL_SURGING_TOTEM) then
        local seq = {
            ShamanModule.SPELL_CHAIN_HEAL,
            ShamanModule.SPELL_HEALING_SURGE
        }
        return seq, "Surging Totem Active: Prioritize Chain Heal"
    end

    -- FORCED OVERRIDES (after a cast)
    if ShamanModule.lastHealingSurgeCast then
        ShamanModule.lastHealingSurgeCast = false
        tidalStacks = 0  -- Assume Healing Surge consumed Tidal Waves.
        return { ShamanModule.SPELL_RIPTIDE, ShamanModule.SPELL_CHAIN_HEAL },
               "Post Healing Surge: Build Tidal Waves with Riptide"
    end

    if ShamanModule.lastRiptideCast then
        ShamanModule.lastRiptideCast = false
        if tidalStacks < 2 then
            return { ShamanModule.SPELL_RIPTIDE, ShamanModule.SPELL_CHAIN_HEAL },
                   "Post Riptide: Build Tidal Waves"
        else
            if manaPercent >= 60 then
                return { ShamanModule.SPELL_HEALING_SURGE, ShamanModule.SPELL_CHAIN_HEAL },
                       "Post Riptide: Use Healing Surge (High Mana)"
            else
                return { ShamanModule.SPELL_HEALING_WAVE, ShamanModule.SPELL_CHAIN_HEAL },
                       "Post Riptide: Use Healing Wave (Conserve Mana)"
            end
        end
    end

    -- Build the base suggestions list.
    if groupSize > 5 then
        table.insert(suggestions, ShamanModule.SPELL_CHAIN_HEAL)
    end

    if tidalStacks < 2 then
        table.insert(suggestions, ShamanModule.SPELL_RIPTIDE)
    else
        if manaPercent >= 60 then
            table.insert(suggestions, ShamanModule.SPELL_HEALING_SURGE)
        else
            table.insert(suggestions, ShamanModule.SPELL_HEALING_WAVE)
        end
    end

    if lowestTankHP < 30 then
        table.insert(suggestions, ShamanModule.SPELL_HEALING_SURGE)
    end

    if (UnitHealth("player") / UnitHealthMax("player")) * 100 < 50 then
        table.insert(suggestions, ShamanModule.SPELL_WIND_BARRIER)
    end

    -- Fallback: Ensure at least 3 suggestions.
    local alternatives = {
        ShamanModule.SPELL_CHAIN_HEAL,
        ShamanModule.SPELL_HEALING_WAVE,
        ShamanModule.SPELL_RIPTIDE
    }
    local altIndex = 1
    while #suggestions < 3 do
        table.insert(suggestions, alternatives[altIndex])
        altIndex = altIndex + 1
        if altIndex > #alternatives then altIndex = 1 end
    end

    -- Emergency: Add Spirit Link Totem if off cooldown and player's HP is low.
    local playerHP = (UnitHealth("player") / UnitHealthMax("player")) * 100
    local start, duration, enabled = GetSpellCooldown(ShamanModule.SPELL_SPIRIT_LINK_TOTEM)
    if enabled == 1 and start == 0 and playerHP < 50 then
        local alreadySuggested = false
        for _, spell in ipairs(suggestions) do
            if spell == ShamanModule.SPELL_SPIRIT_LINK_TOTEM then
                alreadySuggested = true
                break
            end
        end
        if not alreadySuggested then
            table.insert(suggestions, 1, ShamanModule.SPELL_SPIRIT_LINK_TOTEM)
        end
    end

    -- Emergency: Ensure Earth Shield is active on player or any tank.
    if EarthShieldMissing() then
        local alreadySuggested = false
        for _, spell in ipairs(suggestions) do
            if spell == ShamanModule.SPELL_EARTH_SHIELD then
                alreadySuggested = true
                break
            end
        end
        if not alreadySuggested then
            table.insert(suggestions, 1, ShamanModule.SPELL_EARTH_SHIELD)
        end
    end

    -- Emergency: Ensure Water Shield is active on the player.
    if not UnitHasBuffBySpellID("player", ShamanModule.SPELL_WATER_SHIELD) then
        local alreadySuggested = false
        for _, spell in ipairs(suggestions) do
            if spell == ShamanModule.SPELL_WATER_SHIELD then
                alreadySuggested = true
                break
            end
        end
        if not alreadySuggested then
            table.insert(suggestions, 1, ShamanModule.SPELL_WATER_SHIELD)
        end
    end

    -- If either Healing Rain or Surging Totem is available, suggest it.
    if IsPlayerSpell(ShamanModule.SPELL_HEALING_RAIN) or IsPlayerSpell(ShamanModule.SPELL_SURGING_TOTEM) then
        local alreadySuggested = false
        for _, spell in ipairs(suggestions) do
            if spell == ShamanModule.SPELL_HEALING_RAIN or spell == ShamanModule.SPELL_SURGING_TOTEM then
                alreadySuggested = true
                break
            end
        end
        if not alreadySuggested then
            if IsPlayerSpell(ShamanModule.SPELL_HEALING_RAIN) then
                table.insert(suggestions, 1, ShamanModule.SPELL_HEALING_RAIN)
            elseif IsPlayerSpell(ShamanModule.SPELL_SURGING_TOTEM) then
                table.insert(suggestions, 1, ShamanModule.SPELL_SURGING_TOTEM)
            end
        end
    end

    -- KEEP SHORT-COOLDOWN ABILITIES ON COOLDOWN:
    local shortCooldownAbilities = {}
    if IsPlayerSpell(ShamanModule.SPELL_RIPTIDE) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_RIPTIDE)
    end
    if IsPlayerSpell(ShamanModule.SPELL_HEALING_RAIN) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_HEALING_RAIN)
    elseif IsPlayerSpell(ShamanModule.SPELL_SURGING_TOTEM) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_SURGING_TOTEM)
    end
    if IsPlayerSpell(ShamanModule.SPELL_UNLEASH_LIFE) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_UNLEASH_LIFE)
    end
    if IsPlayerSpell(ShamanModule.SPELL_CLOUDBURST_TOTEM) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_CLOUDBURST_TOTEM)
    elseif IsPlayerSpell(ShamanModule.SPELL_HEALING_STREAM_TOTEM) then
        table.insert(shortCooldownAbilities, ShamanModule.SPELL_HEALING_STREAM_TOTEM)
    end

    for _, spellID in ipairs(shortCooldownAbilities) do
        local start, duration, enabled = GetSpellCooldown(spellID)
        if enabled == 1 and start == 0 then
            local found = false
            for _, suggestedSpell in ipairs(suggestions) do
                if suggestedSpell == spellID then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(suggestions, 1, spellID)
            end
        end
    end

    -- SPECIAL PRIORITY: Ensure Healing Stream Totem is suggested often.
    if IsPlayerSpell(ShamanModule.SPELL_HEALING_STREAM_TOTEM) then
        local start, duration, enabled = GetSpellCooldown(ShamanModule.SPELL_HEALING_STREAM_TOTEM)
        if enabled == 1 and start == 0 then
            local alreadySuggested = false
            for _, spell in ipairs(suggestions) do
                if spell == ShamanModule.SPELL_HEALING_STREAM_TOTEM then
                    alreadySuggested = true
                    break
                end
            end
            if not alreadySuggested then
                table.insert(suggestions, 1, ShamanModule.SPELL_HEALING_STREAM_TOTEM)
            end
        end
    end

    -- If the group doesn't have Skyfury, suggest it.
    if not GroupHasSkyfury() then
        local alreadySuggested = false
        for _, spell in ipairs(suggestions) do
            if spell == ShamanModule.SPELL_SKYFURY then
                alreadySuggested = true
                break
            end
        end
        if not alreadySuggested then
            table.insert(suggestions, 1, ShamanModule.SPELL_SKYFURY)
        end
    end

    return suggestions, "LaZHealer Totemic Shaman Active"
end

-------------------------------------------------
-- UI Update Functions for Class-Specific Elements
-------------------------------------------------
function ShamanModule.UpdateStackFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.stackFrame then return end
    local buffName = SafeGetSpellName(ShamanModule.SPELL_TIDAL_WAVES)
    local aura = AuraUtil.FindAuraByName(buffName, "player", "HELPFUL")
    local stacks = (aura and aura.stackCount) or 0
    UI.stackFrame.icon:SetTexture(SafeGetSpellTexture(ShamanModule.SPELL_TIDAL_WAVES))
    UI.stackFrame.stackText:SetText(tostring(stacks))
    UI.stackFrame:Show()
end

function ShamanModule.UpdatePowerBoomFrameUI()
    local UI = _G.LaZHealer and _G.LaZHealer.UI
    if not UI or not UI.powerBoomFrame then return end
    local spellName = SafeGetSpellName(ShamanModule.SPELL_ASCENDANCE)  -- Ascendance as PowerBoomSpell.
    local aura = C_UnitAuras.GetAuraDataBySpellName("player", spellName, "HELPFUL")
    if aura and aura.expirationTime then
        UI.powerBoomFrame:Show()
        local remaining = math.floor(aura.expirationTime - GetTime())
        UI.powerBoomFrame.timerText:SetText(tostring(remaining))
        UI.powerBoomFrame.icon:SetTexture(SafeGetSpellTexture(ShamanModule.SPELL_ASCENDANCE))
    else
        UI.powerBoomFrame:Hide()
    end
end

function ShamanModule.UpdateClassUI()
    ShamanModule.UpdateStackFrameUI()
    ShamanModule.UpdatePowerBoomFrameUI()
end

-------------------------------------------------
-- OnUpdate Timer for Frequent UI Updates
-------------------------------------------------
local updateFrame = CreateFrame("Frame", "LaZHealer_Shaman_UpdateFrame", UIParent)
local updateInterval = 0.5
local timeSinceLastUpdate = 0
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        ShamanModule.UpdateClassUI()
        timeSinceLastUpdate = 0
    end
end)

-------------------------------------------------
-- Event Handling (for spell suggestion updates)
-------------------------------------------------
local function UpdateLaZHealer()
    local spells, message = ShamanModule.EvaluateSpellSuggestions()
    return spells, message
end

local function OnEvent(self, event, arg1, ...)
    if event == "UNIT_AURA" and arg1 == "player" then
        UpdateLaZHealer()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local castSpellName = select(2, ...)
        if castSpellName == SafeGetSpellName(ShamanModule.SPELL_HEALING_SURGE) then
            ShamanModule.lastHealingSurgeCast = true
        elseif castSpellName == SafeGetSpellName(ShamanModule.SPELL_RIPTIDE) then
            ShamanModule.lastRiptideCast = true
        end
        UpdateLaZHealer()
    else
        UpdateLaZHealer()
    end
end

-------------------------------------------------
-- Initialize Module
-------------------------------------------------
function ShamanModule.Initialize()
    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    f:SetScript("OnEvent", OnEvent)
    
    ShamanModule.UpdateStackFrameUI()
    UpdateLaZHealer()
end

-------------------------------------------------
-- Expose Module
-------------------------------------------------
_G.LaZHealer_Shaman = ShamanModule
