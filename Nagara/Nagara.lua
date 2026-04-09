-- Namespace shared across all addon files loaded by the .toc
local addonName, ns = ...

-- Expose namespace for the NagaraDM addon (loaded after Nagara via ## Dependencies)
NagaraNS = ns

-- SavedVariables table (persisted between sessions)
NagaraDB = NagaraDB or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- First-run defaults
        if not NagaraDB.initialized then
            NagaraDB.initialized = true
        end

        ns:OnLogin()
        print("|cff00ccff[Nagara]|r Loaded v0.1.0")
    end
end)

SLASH_NAGARA1 = "/nagara"
SlashCmdList["NAGARA"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "" then
        print("|cff00ccff[Nagara]|r Use /nagara help for commands.")
    elseif msg == "help" then
        print("|cff00ccff[Nagara]|r Commands:")
        print("  /nagara help  – show this list")
    else
        print("|cff00ccff[Nagara]|r Unknown command: " .. msg)
    end
end
