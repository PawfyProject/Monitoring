local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Http = HttpService

-- CONFIG FILE
local CONFIG_PATH = "/storage/emulated/0/Download/WinterHub/auto_rejoin.conf"

-- READ CONFIG
local SERVER_NAME = "UNKNOWN"
local DEVICE_ID = "UNKNOWN"
local HOST = "http://127.0.0.1:5000/update"

local function read_config()
    local file = io.open(CONFIG_PATH,"r")
    if not file then return end
    for line in file:lines() do
        if line:find("device_label=") then
            DEVICE_ID = line:match("device_label=(.*)")
        elseif line:find("shared_link_1_name=") then
            SERVER_NAME = line:match("shared_link_1_name=(.*)")
        elseif line:find("host_url=") then
            HOST = line:match("host_url=(.*)")
        end
    end
    file:close()
end

read_config()

-- SEND STATUS
local function send(status)
    local data = {
        account = Players.LocalPlayer.Name,
        server = SERVER_NAME,
        status = status,
        device = DEVICE_ID
    }
    local json = Http:JSONEncode(data)
    pcall(function()
        Http:PostAsync(HOST,json,Enum.HttpContentType.ApplicationJson)
    end)
end

-- JOIN SERVER
send("active")

-- HEARTBEAT LOOP
spawn(function()
    while true do
        send("active")
        wait(20) -- heartbeat setiap 20 detik
    end
end)

-- DETECT OFFLINE / LEAVE
Players.LocalPlayer.OnDestroy:Connect(function()
    send("offline")
end)
