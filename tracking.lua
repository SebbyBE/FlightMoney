function HandleFlightMasterOpen(type)
    if type == Enum.PlayerInteractionType.TaxiNode then
        goldBeforeFlight = GetMoney()

        for i = 1, NumTaxiNodes() do
            if TaxiNodeGetType(i) == "CURRENT" then
                departureNodeName = TaxiNodeName(i)
                break
            end
        end

        print("|" ..
            PURPLE_PRINT_COLOR .. "[FlightMoney]|r Opened flight master at: " .. (departureNodeName or "Unknown"))

        -- Hook taxi node click (only once)
        if not FlightMoney_TaxiHooked then
            hooksecurefunc("TakeTaxiNode", function(nodeIndex)
                local destination = TaxiNodeName(nodeIndex)
                local cost = TaxiNodeCost(nodeIndex)

                currentFlight = {
                    date = date("%Y-%m-%d %H:%M:%S"),
                    playerLevel = UnitLevel("player"),
                    from = departureNodeName or "Unknown",
                    to = destination or "Unknown",
                    cost = cost,
                    duration = nil,
                }

                FlightMoneyDB.totalGoldSpent = FlightMoneyDB.totalGoldSpent + cost
                flightStartTime = GetTime()
                isFlying = true

                print(string.format("|" .. PURPLE_PRINT_COLOR .. "[FlightMoney]|r Took off from %s to %s. Cost: %s",
                    currentFlight.from, currentFlight.to, FormatMoney(cost)))
            end)

            FlightMoney_TaxiHooked = true
        end
    end
end

-- This is only here to satisfy the original event registration — it's no longer needed
function HandleFlightMasterClose()
    -- No longer needed, left here to avoid errors
end

-- Flight monitor runs every frame to check when the player lands
function StartFlightMonitor()
    local monitor = CreateFrame("Frame")
    monitor:RegisterEvent("PLAYER_CONTROL_GAINED")
    monitor:SetScript("OnEvent", function(self, event)
        if isFlying and currentFlight then
            local duration = GetTime() - flightStartTime
            isFlying = false

            currentFlight.duration = duration
            FlightMoneyDB.totalFlightTime = FlightMoneyDB.totalFlightTime + duration
            table.insert(FlightMoneyDB.flights, currentFlight)

            print(string.format("|" .. PURPLE_PRINT_COLOR .. "[FlightMoney]|r Landed! Flight time: %s",
                FormatTime(duration)))
            print(string.format("|" .. PURPLE_PRINT_COLOR .. "[FlightMoney]|r Total gold spent: %s",
                FormatMoney(FlightMoneyDB.totalGoldSpent)))
            print(string.format("|" .. PURPLE_PRINT_COLOR .. "[FlightMoney]|r Total flight time: %s",
                FormatTime(FlightMoneyDB.totalFlightTime)))

            currentFlight = nil
        end
    end)
end
