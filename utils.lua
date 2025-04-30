PURPLE_PRINT_COLOR = "cffa335ee"

-- Setup global fallback for Retail (if needed)
_G.LibDeflate = _G.LibDeflate or LibDeflate
_G.LibSerialize = _G.LibSerialize or LibSerialize

local deflate, serializer

if _G.LibStub then
    deflate = LibStub("LibDeflate", true)
    serializer = LibStub("LibSerialize", true)
end

-- Fallback for Retail if LibStub returns nil
deflate = deflate or _G.LibDeflate
serializer = serializer or _G.LibSerialize

if not deflate or not serializer then
    error("FlightMoney requires LibDeflate and LibSerialize libraries.")
end

-- Format gold/silver/copper with icons and 2-digit padding
function FormatMoney(money)
    local GOLD_ICON   = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t"
    local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t"
    local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"

    local gold        = floor(money / (100 * 100))
    local silver      = floor((money / 100) % 100)
    local copper      = money % 100

    local result      = ""
    if gold > 0 then
        result = result .. string.format("%02d", gold) .. GOLD_ICON .. " "
    end
    if silver > 0 or gold > 0 then
        result = result .. string.format("%02d", silver) .. SILVER_ICON .. " "
    end
    result = result .. string.format("%02d", copper) .. COPPER_ICON

    return result
end

-- Format seconds into human-readable time string
function FormatTime(seconds)
    local days    = math.floor(seconds / 86400)
    local hours   = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs    = math.floor(seconds % 60)

    local result  = ""
    if days > 0 then result = result .. days .. "d " end
    if hours > 0 then result = result .. hours .. "h " end
    if minutes > 0 then result = result .. minutes .. "m " end
    result = result .. secs .. "s"

    return result
end

-- Encode the DB for exporting
function EncodeFlightMoneyData(tbl)
    local serialized = serializer:Serialize(tbl)
    local compressed = deflate:CompressDeflate(serialized)
    return "!FLM:" .. deflate:EncodeForPrint(compressed)
end

-- Decode an export string
function DecodeFlightMoneyData(encoded)
    if not encoded:find("^!FLM:") then return nil, "Not a FlightMoney string" end
    encoded = encoded:gsub("^!FLM:", "")
    local compressed = deflate:DecodeForPrint(encoded)
    if not compressed then return nil, "Failed to decode" end

    local serialized = deflate:DecompressDeflate(compressed)
    if not serialized then return nil, "Failed to decompress" end

    local success, result = serializer:Deserialize(serialized)
    if not success then return nil, "Failed to deserialize" end

    -- Filter invalid flight entries
    if type(result.flights) == "table" then
        local cleanFlights = {}
        for _, flight in ipairs(result.flights) do
            if ValidateFlightEntry(flight) then
                table.insert(cleanFlights, flight)
            end
        end
        result.flights = cleanFlights
    else
        result.flights = {}
    end

    return result
end

function ValidateFlightEntry(entry)
    if type(entry) ~= "table" then return false end

    if type(entry.date) ~= "string" then return false end
    if type(entry.from) ~= "string" then return false end
    if type(entry.to) ~= "string" then return false end
    if type(entry.cost) ~= "number" then return false end
    if type(entry.duration) ~= "number" then return false end
    if type(entry.playerLevel) ~= "number" then return false end

    return true
end
