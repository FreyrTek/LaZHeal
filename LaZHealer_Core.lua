-- LaZHealer_Core.lua
local addonName, LaZHealer = ...
-- Expose the LaZHealer table globally so other files can access it
_G.LaZHealer = LaZHealer
LaZHealer.Modules = {}

print("LaZHealer: Healing addon initialized.")

-------------------------------------------------
-- Function to Detect Player Class and Load the Correct Module
-------------------------------------------------
local function LoadHealingModule()
    local _, playerClass = UnitClass("player")
    
    -- Clear any previously loaded modules
    LaZHealer.Modules = {}
    
    if playerClass == "DRUID" then
        if _G.LaZHealer_Druid and _G.LaZHealer_Druid.Initialize then
            print("LaZHealer: Loading Druid module...")
            _G.LaZHealer_Druid.Initialize()
            LaZHealer.Modules["DRUID"] = _G.LaZHealer_Druid
        else
            print("LaZHealer: ERROR - Druid module not loaded correctly!")
        end
    elseif playerClass == "PALADIN" then
        if _G.LaZHealer_Paladin and _G.LaZHealer_Paladin.Initialize then
            print("LaZHealer: Loading Paladin module...")
            _G.LaZHealer_Paladin.Initialize()
            LaZHealer.Modules["PALADIN"] = _G.LaZHealer_Paladin
        else
            print("LaZHealer: ERROR - Paladin module not loaded correctly!")
        end
    else
        print("LaZHealer: Your class (" .. playerClass .. ") is not yet supported.")
    end
end

-------------------------------------------------
-- Event Handling for Player Login
-------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        LoadHealingModule()
        -- If your UI file has tank UI functions, initialize them here.
        if LaZHealer.UI and LaZHealer.UI.CreateTankFrames then
            LaZHealer.UI.CreateTankFrames()
            print("LaZHealer: Tank frames UI initialized.")
        end
    end
end)

-------------------------------------------------
-- Global Healing Evaluation Functions (for other parts of the addon)
-------------------------------------------------
function LaZHealer.EvaluateHealing()
    local _, playerClass = UnitClass("player")
    local module = LaZHealer.Modules[playerClass]
    if module and module.EvaluateSpellSuggestions then
        local spellList, reason = module.EvaluateSpellSuggestions()
        return spellList, reason
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
