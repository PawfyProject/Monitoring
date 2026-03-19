local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Http = HttpService

-- CONFIG FILE
local SERVER_CONFIG = "/storage/emulated/0/Download/WinterHub/auto_rejoin.conf"
local HOST_CONFIG = "/storage/emulated/0/Download/WinterHub/host_config.conf"

-- VARIABLES
local DEVICE_ID = "UNKNOWN"
local HOST = "http://127.0.0.1:5000/update"
local SERVER_LIST = {}
local SERVER_INDEX = 1

-- READ SERVER CONFIG
do
    local file = io.open(SERVER_CONFIG,"r")
    if file then
        local config = {}
        for line in file:lines() do
            if line:find("=") then
                local k,v = line:match("([^=]+)=(.*)")
                if k and v then config[k] = v end
            end
        end
        file:close()

        if config["device_label"] then DEVICE_ID = config["device_label"] end
        local count = tonumber(config["shared_links_count"]) or 0
        for i=1,count do
            local name = config["shared_link_"..i.."_name"]
            if name then table.insert(SERVER_LIST, name) end
        end
        if #SERVER_LIST > 0 then SERVER_INDEX = 1 end
    end
end

-- READ HOST CONFIG
do
    local file = io.open(HOST_CONFIG,"r")
    if file then
        for line in file:lines() do
            if line:find("host_url=") then
                HOST = line:match("host_url=(.*)")
            end
        end
        file:close()
    end
end

-- GET CURRENT SERVER
local function current_server()
    if #SERVER_LIST == 0 then return "UNKNOWN" end
    return SERVER_LIST[SERVER_INDEX]
end

-- SEND STATUS
local function send(status)
    local data = {
        account = Players.LocalPlayer.Name,
        server = current_server(),
        status = status,
        device = DEVICE_ID
    }
    local json = Http:JSONEncode(data)
    pcall(function() Http:PostAsync(HOST,json,Enum.HttpContentType.ApplicationJson) end)
end

-- JOIN SERVER
send("active")

-- HEARTBEAT LOOP
spawn(function()
    while true do
        send("active")
        wait(20)
    end
end)

-- OFFLINE DETECT
Players.LocalPlayer.OnDestroy:Connect(function()
    send("offline")
end)
