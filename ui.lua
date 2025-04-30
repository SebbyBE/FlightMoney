function FlightMoney_ShowWindow()
    if FlightMoneyStatsFrame then
        FlightMoneyStatsFrame:Hide() -- Hide to force refresh on reopen
    end

    FlightMoneyStatsFrame = CreateFrame("Frame", "FlightMoneyStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    tinsert(UISpecialFrames, "FlightMoneyStatsFrame")
    local f = FlightMoneyStatsFrame

    f:SetSize(720, 600)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetToplevel(true)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -5)
    f.title:SetText("Flight Money History")

    local name = UnitName("player")
    local realm = GetRealmName()
    f.charText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.charText:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.charText:SetText(name .. " - " .. realm)

    local totalGold = FormatMoney(FlightMoneyDB.totalGoldSpent or 0)
    f.goldText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.goldText:SetPoint("TOPLEFT", 20, -40)
    f.goldText:SetText("Total Gold Spent: " .. totalGold)

    local totalTime = FormatTime(FlightMoneyDB.totalFlightTime or 0)
    f.timeText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.timeText:SetPoint("TOPLEFT", f.goldText, "BOTTOMLEFT", 0, -5)
    f.timeText:SetText("Total Flight Time: " .. totalTime)

    sortBy = sortBy or "date"
    sortDescending = sortDescending == nil and true or sortDescending

    local flights = FlightMoneyDB.flights or {}
    local scrollFrame, content

    local function UpdateSortButtonText()
        local downArrow = "v"
        local upArrow = "^"
        f.sortDateBtn:SetText("Date" ..
            (sortBy == "date" and (sortDescending and " " .. downArrow or " " .. upArrow) or ""))
        f.sortPriceBtn:SetText("Price" ..
            (sortBy == "cost" and (sortDescending and " " .. downArrow or " " .. upArrow) or ""))
        f.sortTimeBtn:SetText("Time" ..
            (sortBy == "duration" and (sortDescending and " " .. downArrow or " " .. upArrow) or ""))
    end

    local function RefreshFlightList()
        if not content then return end

        -- Clean up invalid entries before sorting
        local cleanedFlights = {}
        for _, flight in ipairs(flights) do
            if flight and flight[sortBy] ~= nil then
                table.insert(cleanedFlights, flight)
            end
        end
        flights = cleanedFlights


        table.sort(flights, function(a, b)
            if type(a) ~= "table" or type(b) ~= "table" then return false end

            local aVal = a[sortBy]
            local bVal = b[sortBy]

            -- Handle missing values explicitly
            if aVal == nil and bVal == nil then return false end
            if aVal == nil then return not sortDescending end
            if bVal == nil then return sortDescending end

            -- Normalize based on expected type
            if sortBy == "cost" or sortBy == "duration" or sortBy == "playerLevel" then
                aVal = tonumber(aVal) or 0
                bVal = tonumber(bVal) or 0
            else
                aVal = tostring(aVal or "")
                bVal = tostring(bVal or "")
            end

            if sortDescending then
                return aVal > bVal
            else
                return aVal < bVal
            end
        end)


        if content then
            content:Hide()
            content:SetParent(nil)
        end

        content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(1, 1)
        scrollFrame:SetScrollChild(content)
        content.lines = {}

        local mostExpensive, longestFlight, mostRecent = nil, nil, nil
        for _, flight in ipairs(flights) do
            if not mostExpensive or (flight.cost or 0) > (mostExpensive.cost or 0) then
                mostExpensive = flight
            end
            if not longestFlight or (flight.duration or 0) > (longestFlight.duration or 0) then
                longestFlight = flight
            end
            if not mostRecent or (flight.date or "") > (mostRecent.date or "") then
                mostRecent = flight
            end
        end

        local lineHeight = 18
        for i, flight in ipairs(flights) do
            local yOffset = -((i - 1) * (lineHeight + 4))

            local color = "|cffffffff"
            if flight == mostExpensive then
                color = "|cffff5555"
            elseif flight == longestFlight then
                color = "|cffa335ee"
            elseif flight == mostRecent then
                color = "|cff00ff00"
            end

            local fontTemplate = "GameFontHighlightSmall"

            local date = content:CreateFontString(nil, "OVERLAY", fontTemplate)
            date:SetPoint("TOPLEFT", 0, yOffset)
            date:SetWidth(150)
            date:SetJustifyH("LEFT")
            date:SetText(color .. (flight.date or "Unknown"))

            local level = content:CreateFontString(nil, "OVERLAY", fontTemplate)
            level:SetPoint("TOPLEFT", date, "TOPRIGHT", 5, 0)
            level:SetWidth(50)
            level:SetJustifyH("LEFT")
            level:SetText(color .. "Lv" .. (flight.playerLevel or 0))

            local fromTo = content:CreateFontString(nil, "OVERLAY", fontTemplate)
            fromTo:SetPoint("TOPLEFT", level, "TOPRIGHT", 5, 0)
            fromTo:SetWidth(320)
            fromTo:SetJustifyH("LEFT")
            fromTo:SetText(color .. (flight.from or "?") .. " > " .. (flight.to or "?"))

            local cost = content:CreateFontString(nil, "OVERLAY", fontTemplate)
            cost:SetPoint("TOPLEFT", fromTo, "TOPRIGHT", 5, 0)
            cost:SetWidth(80)
            cost:SetJustifyH("LEFT")
            cost:SetText(color .. FormatMoney(flight.cost or 0))

            local duration = content:CreateFontString(nil, "OVERLAY", fontTemplate)
            duration:SetPoint("TOPLEFT", cost, "TOPRIGHT", 5, 0)
            duration:SetWidth(80)
            duration:SetJustifyH("LEFT")
            duration:SetText(color .. FormatTime(flight.duration or 0))
        end

        local totalHeight = #flights * (lineHeight + 4)
        content:SetHeight(math.max(totalHeight, 400))
    end

    local function RefreshWindowWithSort(newSort)
        if sortBy == newSort then
            sortDescending = not sortDescending
        else
            sortBy = newSort
            sortDescending = true
        end
        UpdateSortButtonText()
        RefreshFlightList()
    end

    -- Sort Buttons
    f.sortDateBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.sortDateBtn:SetSize(80, 20)
    f.sortDateBtn:SetPoint("TOPLEFT", f.timeText, "BOTTOMLEFT", 0, -15)
    f.sortDateBtn:SetScript("OnClick", function() RefreshWindowWithSort("date") end)

    f.sortPriceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.sortPriceBtn:SetSize(80, 20)
    f.sortPriceBtn:SetPoint("LEFT", f.sortDateBtn, "RIGHT", 5, 0)
    f.sortPriceBtn:SetScript("OnClick", function() RefreshWindowWithSort("cost") end)

    f.sortTimeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.sortTimeBtn:SetSize(80, 20)
    f.sortTimeBtn:SetPoint("LEFT", f.sortPriceBtn, "RIGHT", 5, 0)
    f.sortTimeBtn:SetScript("OnClick", function() RefreshWindowWithSort("duration") end)

    f.sortResetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.sortResetBtn:SetSize(120, 20)
    f.sortResetBtn:SetPoint("LEFT", f.sortTimeBtn, "RIGHT", 5, 0)
    f.sortResetBtn:SetText("Reset Filter")
    f.sortResetBtn:SetScript("OnClick", function()
        sortBy = "date"
        sortDescending = true
        UpdateSortButtonText()
        RefreshFlightList()
    end)

    UpdateSortButtonText()

    -- Column Headers
    local headerY = -115
    local headers = {
        { text = "Date",      width = 150 },
        { text = "Level",     width = 50 },
        { text = "From > To", width = 320 },
        { text = "Cost",      width = 80 },
        { text = "Time",      width = 80 },
    }

    local prevAnchor = nil
    for _, col in ipairs(headers) do
        local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if prevAnchor then
            header:SetPoint("TOPLEFT", prevAnchor, "TOPRIGHT", 5, 0)
        else
            header:SetPoint("TOPLEFT", 20, headerY)
        end
        header:SetWidth(col.width)
        header:SetJustifyH("LEFT")
        header:SetText(col.text)
        prevAnchor = header
    end

    scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -130)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    content.lines = {}

    local legend = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    legend:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 20)
    legend:SetText("|cffff5555Red|r = Most Expensive   |cffa335eePurple|r = Longest   |cff00ff00Green|r = Most Recent")

    RefreshFlightList()

    -- Export Button
    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(80, 22)
    exportBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -190, 20)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        local exportData = EncodeFlightMoneyData(FlightMoneyDB)
        if not FlightMoneyExportFrame then
            FlightMoneyExportFrame = CreateFrame("Frame", "FlightMoneyExportFrame", UIParent,
                "BasicFrameTemplateWithInset")
            tinsert(UISpecialFrames, "FlightMoneyExportFrame")
            FlightMoneyExportFrame:SetSize(520, 150)
            FlightMoneyExportFrame:SetPoint("CENTER")
            FlightMoneyExportFrame:SetMovable(true)
            FlightMoneyExportFrame:EnableMouse(true)
            FlightMoneyExportFrame:RegisterForDrag("LeftButton")
            FlightMoneyExportFrame:SetScript("OnDragStart", FlightMoneyExportFrame.StartMoving)
            FlightMoneyExportFrame:SetScript("OnDragStop", FlightMoneyExportFrame.StopMovingOrSizing)
            FlightMoneyExportFrame:SetFrameStrata("TOOLTIP")
            FlightMoneyExportFrame:SetFrameLevel(9999)
            FlightMoneyExportFrame:SetToplevel(true)
            FlightMoneyExportFrame:SetClampedToScreen(true)
            FlightMoneyExportFrame:Hide()

            FlightMoneyExportFrame.title = FlightMoneyExportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            FlightMoneyExportFrame.title:SetPoint("TOP", 0, -5)
            FlightMoneyExportFrame.title:SetText("Export Flight Data")

            FlightMoneyExportFrame.editBox = CreateFrame("EditBox", nil, FlightMoneyExportFrame, "InputBoxTemplate")
            FlightMoneyExportFrame.editBox:SetMultiLine(true)
            FlightMoneyExportFrame.editBox:SetSize(480, 90)
            FlightMoneyExportFrame.editBox:SetPoint("CENTER")
            FlightMoneyExportFrame.editBox:SetAutoFocus(false)
            FlightMoneyExportFrame.editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        end

        FlightMoneyExportFrame.editBox:SetText(exportData)
        FlightMoneyExportFrame:Show()
        FlightMoneyExportFrame.editBox:HighlightText()
        FlightMoneyExportFrame.editBox:SetFocus()
    end)

    -- Import Button
    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(80, 22)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        if not FlightMoneyImportFrame then
            FlightMoneyImportFrame = CreateFrame("Frame", "FlightMoneyImportFrame", UIParent,
                "BasicFrameTemplateWithInset")
            tinsert(UISpecialFrames, "FlightMoneyImportFrame")
            FlightMoneyImportFrame:SetSize(520, 220)
            FlightMoneyImportFrame:SetPoint("CENTER")
            FlightMoneyImportFrame:SetMovable(true)
            FlightMoneyImportFrame:EnableMouse(true)
            FlightMoneyImportFrame:RegisterForDrag("LeftButton")
            FlightMoneyImportFrame:SetScript("OnDragStart", FlightMoneyImportFrame.StartMoving)
            FlightMoneyImportFrame:SetScript("OnDragStop", FlightMoneyImportFrame.StopMovingOrSizing)
            FlightMoneyImportFrame:SetFrameStrata("TOOLTIP")
            FlightMoneyImportFrame:SetFrameLevel(9999)
            FlightMoneyImportFrame:SetToplevel(true)
            FlightMoneyImportFrame:SetClampedToScreen(true)
            FlightMoneyImportFrame:Hide()

            FlightMoneyImportFrame.title = FlightMoneyImportFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            FlightMoneyImportFrame.title:SetPoint("TOP", 0, -5)
            FlightMoneyImportFrame.title:SetText("Import Flight Data")

            -- Create ScrollFrame
            local scrollFrame = CreateFrame("ScrollFrame", nil, FlightMoneyImportFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 10, -30)
            scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

            -- Create EditBox inside ScrollFrame
            local editBox = CreateFrame("EditBox", nil, scrollFrame)
            editBox:SetMultiLine(true)
            editBox:SetFontObject(ChatFontNormal)
            editBox:SetWidth(460)
            editBox:SetAutoFocus(false)
            editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            editBox:SetScript("OnTextChanged", function(self)
                scrollFrame:UpdateScrollChildRect()
            end)

            scrollFrame:SetScrollChild(editBox)

            FlightMoneyImportFrame.editBox = editBox

            -- Load Button
            local importButton = CreateFrame("Button", nil, FlightMoneyImportFrame, "UIPanelButtonTemplate")
            importButton:SetSize(80, 22)
            importButton:SetPoint("BOTTOM", 0, 10)
            importButton:SetText("Load")
            importButton:SetScript("OnClick", function()
                local text = FlightMoneyImportFrame.editBox:GetText()
                local data, err = DecodeFlightMoneyData(text)
                if data then
                    FlightMoneyDB = data
                    print("|" ..
                        PURPLE_PRINT_COLOR .. "[FlightMoney]|r Data imported successfully! Reopen to see the import")
                    FlightMoneyImportFrame:Hide()
                    FlightMoneyStatsFrame:Hide()
                else
                    print("|cffff0000[FlightMoney]|r Import failed: " .. tostring(err))
                end
            end)
        end

        FlightMoneyImportFrame.editBox:SetText("")
        FlightMoneyImportFrame:Show()
        FlightMoneyImportFrame.editBox:SetFocus()
    end)

    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(80, 22)
    resetBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["FLIGHTMONEY_RESET_CONFIRM"] = {
            text = "Are you sure you want to reset all flight tracking data for this character?",
            button1 = "Yes",
            button2 = "Cancel",
            OnAccept = function()
                FlightMoneyDB = {
                    totalGoldSpent = 0,
                    totalFlightTime = 0,
                    flights = {},
                }
                print("|cffff0000[FlightMoney]|r All flight data has been reset.")
                FlightMoneyStatsFrame:Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("FLIGHTMONEY_RESET_CONFIRM")
    end)
end
