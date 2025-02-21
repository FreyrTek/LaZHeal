-- LaZHealer_Core.lua
local addonName, LaZHealer = ...
_G.LaZHealer = LaZHealer
LaZHealer.Modules = {}

print("LaZHealer: Healing addon initialized.")

-------------------------------------------------
-- SimC Parser
-------------------------------------------------
local function ParseSimC(fileName)
    local priorityList = {}
    local file = assert(loadfile(fileName), "Could not load SimC file: " .. fileName)
    local content = file()
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^actions%+=/") then
            local action, condition = line:match("^actions%+=/([^,]+),?(.*)$")
            if action then
                local spellName = action:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
                local spellInfo = C_Spell.GetSpellInfo(spellName)
                local spellID = spellInfo and spellInfo.spellID
                if spellID then
                    local entry = { spell = spellID }
                    if condition and condition:match("^if=(.+)$") then
                        local condStr = condition:match("^if=(.+)$")
                        entry.condition = function()
                            return LaZHealer.EvaluateSimCCondition(condStr, spellID)
                        end
                    else
                        entry.condition = function() return true end
                    end
                    table.insert(priorityList, entry)
                end
            end
        end
    end
    return priorityList
end

-------------------------------------------------
-- SimC Condition Evaluator
-------------------------------------------------
function LaZHealer.EvaluateSimCCondition(condition, spellID)
    local function eval(expr)
        if expr:match("target%.health%.pct<(%d+)") then
            local threshold = tonumber(expr:match("target%.health%.pct<(%d+)"))
            local lowestHP = 100
            for i = 1, GetNumGroupMembers() do
                local unit = IsInRaid() and "raid" .. i or "party" .. i
                if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                    local hp = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
                    if hp < lowestHP then lowestHP = hp end
                end
            end
            return lowestHP < threshold
        elseif expr:match("!buff%.(.+)%.up") then
            local buffName = expr:match("!buff%.(.+)%.up"):gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
            local buffID = C_Spell.GetSpellInfo(buffName) and C_Spell.GetSpellInfo(buffName).spellID
            return not (buffID and C_UnitAuras.GetAuraDataBySpellName("player", buffName, "HELPFUL"))
        elseif expr:match("buff%.(.+)%.up") then
            local buffName = expr:match("buff%.(.+)%.up"):gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
            local buffID = C_Spell.GetSpellInfo(buffName) and C_Spell.GetSpellInfo(buffName).spellID
            return buffID and C_UnitAuras.GetAuraDataBySpellName("player", buffName, "HELPFUL") ~= nil
        elseif expr:match("holy_power>=(%d+)") then
            local threshold = tonumber(expr:match("holy_power>=(%d+)"))
            return UnitPower("player", 9) >= threshold
        elseif expr:match("mana%.pct<(%d+)") then
            local threshold = tonumber(expr:match("mana%.pct<(%d+)"))
            return (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100 < threshold
        elseif expr:match("essence>=(%d+)") then
            local threshold = tonumber(expr:match("essence>=(%d+)"))
            return UnitPower("player", 7) >= threshold
        elseif expr:match("active_dot%.(.+)<(%d+)") then
            local dotName, threshold = expr:match("active_dot%.(.+)<(%d+)")
            dotName = dotName:gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
            local dotID = C_Spell.GetSpellInfo(dotName) and C_Spell.GetSpellInfo(dotName).spellID
            local count = 0
            for i = 1, GetNumGroupMembers() do
                local unit = IsInRaid() and "raid" .. i or "party" .. i
                if UnitExists(unit) and C_UnitAuras.GetAuraDataBySpellName(unit, dotName, "HELPFUL") then
                    count = count + 1
                end
            end
            return count < tonumber(threshold)
        elseif expr:match("prev_gcd%.1%.(.+)") then
            local prevSpell = expr:match("prev_gcd%.1%.(.+)"):gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
            local prevID = C_Spell.GetSpellInfo(prevSpell) and C_Spell.GetSpellInfo(prevSpell).spellID
            return prevID and prevID == LaZHealer.lastCastSpellID
        elseif expr:match("talent%.(.+)%.enabled") then
            local talentName = expr:match("talent%.(.+)%.enabled"):gsub("_", " "):gsub("(%l)(%u)", "%1 %2"):lower()
            local talentID = C_Spell.GetSpellInfo(talentName) and C_Talent.GetTalentInfoByName(talentName)
            return talentID and IsPlayerSpell(talentID) -- Check if talent is selected
        end
        return true -- Default to true if condition not recognized
    end

    local parts = {}
    for part in condition:gmatch("[^&|]+") do
        table.insert(parts, part)
    end
    local result = true
    local operator = "and"
    for _, part in ipairs(parts) do
        if part:match("^&") then operator = "and" elseif part:match("^|") then operator = "or" end
        local cleanPart = part:gsub("^&|", "")
        if operator == "and" then
            result = result and eval(cleanPart)
        elseif operator == "or" then
            result = result or eval(cleanPart)
        end
    end
    return result
end

-------------------------------------------------
-- Evaluate Priority List with Talent Check
-------------------------------------------------
function LaZHealer.EvaluatePriorityList(priorityList)
    local suggestions = {}
    for _, entry in ipairs(priorityList) do
        -- Check if the spell is a talent and if it's selected
        local spellInfo = C_Spell.GetSpellInfo(entry.spell)
        local isTalentSpell = spellInfo and C_Talent.GetTalentInfoBySpellID(entry.spell)
        if (not isTalentSpell or IsPlayerSpell(entry.spell)) and IsUsableSpell(entry.spell) and entry.condition() then
            table.insert(suggestions, entry.spell)
            if #suggestions >= 3 then break end
        end
    end
    return suggestions, #suggestions > 0 and "Spell Suggestions" or "No Suggestions Available"
end

-------------------------------------------------
-- Load Healing Module
-------------------------------------------------
local function LoadHealingModule()
    local _, playerClass = UnitClass("player")
    LaZHealer.Modules = {}
    local classMap = {
        ["DRUID"] = "LaZHealer_Druid",
        ["PALADIN"] = "LaZHealer_Paladin",
        ["SHAMAN"] = "LaZHealer_Shaman",
        ["MONK"] = "LaZHealer_Mistweaver",
        ["EVOKER"] = "LaZHealer_Evoker"
    }
    local moduleName = classMap[playerClass]
    if moduleName and _G[moduleName] and _G[moduleName].Initialize then
        print("LaZHealer: Loading " .. playerClass:lower() .. " module...")
        _G[moduleName].priorityList = ParseSimC(moduleName .. ".simc")
        _G[moduleName].Initialize()
        LaZHealer.Modules[playerClass] = _G[moduleName]
    else
        print("LaZHealer: ERROR - " .. playerClass:lower() .. " module not loaded correctly!")
    end
end

-------------------------------------------------
-- Event Handling
-------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED") -- Update on talent changes
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "TRAIT_CONFIG_UPDATED" then
        LoadHealingModule()
        if LaZHealer.UI and LaZHealer.UI.CreateTankFrames then
            LaZHealer.UI.CreateTankFrames()
            print("LaZHealer: Tank frames UI initialized.")
        end
    end
end)

-------------------------------------------------
-- Track Last Cast Spell
-------------------------------------------------
LaZHealer.lastCastSpellID = nil
local castTracker = CreateFrame("Frame")
castTracker:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
castTracker:SetScript("OnEvent", function(self, event, unit, _, spellID)
    if unit == "player" then
        LaZHealer.lastCastSpellID = spellID
    end
end)

-------------------------------------------------
-- Global Healing Functions
-------------------------------------------------
function LaZHealer.EvaluateHealing()
    local _, playerClass = UnitClass("player")
    local module = LaZHealer.Modules[playerClass]
    if module and module.priorityList then
        return LaZHealer.EvaluatePriorityList(module.priorityList)
    end
    return {}, "No available healing actions."
end

function LaZHealer.UseCooldowns()
    local _, playerClass = UnitClass("player")
    local module = LaZHealer.Modules[playerClass]
    if module and module.UseCooldowns then
        return module.UseCooldowns()
    end
    return nil, "No cooldowns available."
end