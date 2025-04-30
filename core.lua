local frame = CreateFrame("Frame")

FlightMoneyDB = FlightMoneyDB or {
    totalGoldSpent = 0,
    totalFlightTime = 0,
    flights = {},
}

goldBeforeFlight = 0
departureNodeName = ""
currentFlight = nil
flightStartTime = 0
isFlying = false

frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        HandleFlightMasterOpen(...)
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        HandleFlightMasterClose()
    end
end)

StartFlightMonitor()

SLASH_FLIGHTMONEY1 = "/flightmoney"
SLASH_FLIGHTMONEY2 = "/fm"

SlashCmdList["FLIGHTMONEY"] = function(msg)
    msg = msg:lower()
    if msg == "stats" then
        FlightMoney_ShowWindow()
    elseif msg == "help" then
        print("|" ..
            PURPLE_PRINT_COLOR .. "[FlightMoney]|r type /fm stats for the UI")
    else
        print("|" ..
            PURPLE_PRINT_COLOR .. "[FlightMoney]|r Use /fm stats to show flight stats.")
    end
end

print("|" ..
    PURPLE_PRINT_COLOR .. "[FlightMoney]|r Loaded")
print("|" ..
    PURPLE_PRINT_COLOR .. "[FlightMoney]|r type /fm stats for the UI")
